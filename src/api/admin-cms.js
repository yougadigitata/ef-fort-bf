import { Hono } from 'hono';
import { getDB } from '../lib/db';
import { verifyJWT } from '../lib/auth';
const adminCms = new Hono();
// ═══════════════════════════════════════════════════════════════
// MIDDLEWARE ADMIN
// ═══════════════════════════════════════════════════════════════
async function requireAdmin(c, next) {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const p = await verifyJWT(h.slice(7));
    if (!p || !p['is_admin'])
        return c.json({ error: 'Accès admin requis.' }, 403);
    c.set('adminId', p['id']);
    await next();
}
// ── Log une action admin ────────────────────────────────────────
async function logAdminAction(db, adminId, action, resourceType, resourceId, oldContent, newContent, description) {
    try {
        await db.from('admin_audit_log').insert({
            admin_id: adminId,
            action,
            resource_type: resourceType,
            resource_id: resourceId,
            old_content: oldContent ? JSON.stringify(oldContent) : null,
            new_content: newContent ? JSON.stringify(newContent) : null,
            description,
            created_at: new Date().toISOString(),
        });
    }
    catch (_) {
        // Ne pas bloquer si le log échoue
    }
}
// ═══════════════════════════════════════════════════════════════
// MIGRATION — Créer tables CMS si inexistantes
// ═══════════════════════════════════════════════════════════════
adminCms.post('/migrate-cms', async (c) => {
    const body = await c.req.json().catch(() => ({}));
    if (body['secret'] !== 'EfFortCMS2026!Migration') {
        return c.json({ error: 'Secret invalide.' }, 403);
    }
    const db = getDB(c.env);
    const results = {};
    // Vérifier chaque table
    const tablesToCheck = [
        'admin_audit_log', 'question_versions', 'question_flags',
        'bulk_import_logs', 'simulations_examens', 'simulation_results'
    ];
    for (const table of tablesToCheck) {
        const { error } = await db.from(table).select('id').limit(1);
        if (error?.code === '42P01' || error?.message?.includes('does not exist')) {
            results[table] = 'MISSING';
        }
        else {
            results[table] = 'OK';
        }
    }
    // SQL à exécuter dans Supabase Dashboard > SQL Editor
    const migrationSQL = `
-- ═══════════════════════════════════════ CMS MIGRATION v6.0 ═══
-- Copier-coller dans : https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new

-- 1. Colonnes supplémentaires sur 'questions'
ALTER TABLE questions ADD COLUMN IF NOT EXISTS created_by TEXT;
ALTER TABLE questions ADD COLUMN IF NOT EXISTS updated_by TEXT;
ALTER TABLE questions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE questions ADD COLUMN IF NOT EXISTS published BOOLEAN DEFAULT true;
ALTER TABLE questions ADD COLUMN IF NOT EXISTS numero_serie INTEGER DEFAULT 1;
ALTER TABLE questions ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;
ALTER TABLE questions ADD COLUMN IF NOT EXISTS pieges TEXT;
ALTER TABLE questions ADD COLUMN IF NOT EXISTS sources TEXT;

-- 2. Colonnes sur series_qcm
ALTER TABLE series_qcm ADD COLUMN IF NOT EXISTS created_by TEXT;
ALTER TABLE series_qcm ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE series_qcm ADD COLUMN IF NOT EXISTS published BOOLEAN DEFAULT true;

-- 3. Couleur fond actualites
ALTER TABLE actualites ADD COLUMN IF NOT EXISTS couleur_fond TEXT DEFAULT '#1A5C38';

-- 4. Table audit log
CREATE TABLE IF NOT EXISTS admin_audit_log (
  id BIGSERIAL PRIMARY KEY, admin_id TEXT NOT NULL, action VARCHAR(50) NOT NULL,
  resource_type VARCHAR(50) NOT NULL, resource_id TEXT, old_content JSONB,
  new_content JSONB, description TEXT, created_at TIMESTAMPTZ DEFAULT now(), ip_address TEXT
);

-- 5. Versions questions
CREATE TABLE IF NOT EXISTS question_versions (
  id BIGSERIAL PRIMARY KEY, question_id TEXT NOT NULL, version_number INTEGER,
  question_text TEXT, propositions JSONB, explication TEXT, difficulte VARCHAR(50),
  created_by TEXT, created_at TIMESTAMPTZ DEFAULT now(), change_summary TEXT
);

-- 6. Signalements
CREATE TABLE IF NOT EXISTS question_flags (
  id BIGSERIAL PRIMARY KEY, question_id TEXT NOT NULL, user_id TEXT NOT NULL,
  reason TEXT NOT NULL, details TEXT, status VARCHAR(50) DEFAULT 'new',
  admin_response TEXT, resolved_by TEXT, created_at TIMESTAMPTZ DEFAULT now(), resolved_at TIMESTAMPTZ
);

-- 7. Imports en masse
CREATE TABLE IF NOT EXISTS bulk_import_logs (
  id BIGSERIAL PRIMARY KEY, admin_id TEXT NOT NULL, filename VARCHAR(255),
  file_format VARCHAR(10), total_lines INTEGER DEFAULT 0, imported_count INTEGER DEFAULT 0,
  failed_count INTEGER DEFAULT 0, errors JSONB DEFAULT '[]', preview_data JSONB DEFAULT '[]',
  imported_question_ids JSONB DEFAULT '[]', status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now(), completed_at TIMESTAMPTZ, import_duration_seconds INTEGER
);

-- 8. Simulations personnalisées
CREATE TABLE IF NOT EXISTS simulations_examens (
  id BIGSERIAL PRIMARY KEY, titre VARCHAR(255) NOT NULL, description TEXT,
  duree_minutes INTEGER DEFAULT 90, score_max INTEGER DEFAULT 50,
  question_ids JSONB DEFAULT '[]', created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(), updated_at TIMESTAMPTZ DEFAULT now(),
  published BOOLEAN DEFAULT true, ordre_questions VARCHAR(50) DEFAULT 'random',
  show_corrections BOOLEAN DEFAULT true, show_score_after BOOLEAN DEFAULT true
);

-- 9. Résultats simulations
CREATE TABLE IF NOT EXISTS simulation_results (
  id BIGSERIAL PRIMARY KEY, simulation_id BIGINT, user_id TEXT NOT NULL,
  started_at TIMESTAMPTZ DEFAULT now(), completed_at TIMESTAMPTZ, duration_seconds INTEGER,
  score NUMERIC(5,2), responses JSONB DEFAULT '{}', total_correct INTEGER DEFAULT 0,
  total_incorrect INTEGER DEFAULT 0, total_skipped INTEGER DEFAULT 0
);

-- 10. Indexes
CREATE INDEX IF NOT EXISTS idx_questions_published ON questions(published);
CREATE INDEX IF NOT EXISTS idx_admin_audit_cms ON admin_audit_log(admin_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_question_flags_status ON question_flags(status);
CREATE INDEX IF NOT EXISTS idx_simulations_published ON simulations_examens(published);
  `;
    return c.json({
        success: true,
        tables_status: results,
        migration_sql: migrationSQL,
        instructions: 'Exécutez le SQL ci-dessus dans Supabase SQL Editor si des tables sont MISSING'
    });
});
// ═══════════════════════════════════════════════════════════════
// GESTION QUESTIONS — CRUD COMPLET
// ═══════════════════════════════════════════════════════════════
// GET /api/admin-cms/questions — Lister avec filtres
adminCms.get('/questions', requireAdmin, async (c) => {
    const db = getDB(c.env);
    const matiereCode = c.req.query('matiere');
    const matiereIdDirect = c.req.query('matiere_id'); // Filtre direct par ID
    const serieId = c.req.query('serie_id');
    const difficulte = c.req.query('difficulte');
    const search = c.req.query('search');
    const page = Math.max(1, parseInt(c.req.query('page') ?? '1'));
    const limit = Math.min(parseInt(c.req.query('limit') ?? '20'), 500);
    const offset = (page - 1) * limit;
    let query = db.from('questions')
        .select('id, enonce, option_a, option_b, option_c, option_d, option_e, bonne_reponse, explication, difficulte, matiere_id, serie_id, numero, numero_serie, pieges, sources, published, version, created_at, updated_at');
    // Résoudre l'ID de matière (par code OU directement par ID)
    let resolvedMatiereId = matiereIdDirect;
    if (!resolvedMatiereId && matiereCode) {
        const { data: mat } = await db.from('matieres').select('id').ilike('code', matiereCode).maybeSingle();
        resolvedMatiereId = mat?.id;
    }
    if (resolvedMatiereId) {
        query = query.eq('matiere_id', resolvedMatiereId);
    }
    // Filtre par série
    if (serieId) {
        query = query.eq('serie_id', serieId);
    }
    // Filtre par difficulté
    if (difficulte && difficulte !== 'TOUS') {
        query = query.eq('difficulte', difficulte);
    }
    // Recherche full-text
    if (search) {
        query = query.ilike('enonce', `%${search}%`);
    }
    // Compter le total
    let total = 0;
    try {
        let countQ = db.from('questions').select('*', { count: 'exact', head: true });
        if (resolvedMatiereId)
            countQ = countQ.eq('matiere_id', resolvedMatiereId);
        if (serieId)
            countQ = countQ.eq('serie_id', serieId);
        if (difficulte && difficulte !== 'TOUS')
            countQ = countQ.eq('difficulte', difficulte);
        if (search)
            countQ = countQ.ilike('enonce', `%${search}%`);
        const { count } = await countQ;
        total = count ?? 0;
    }
    catch (_) { }
    const { data, error } = await query
        .range(offset, offset + limit - 1)
        .order('created_at', { ascending: false });
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, questions: data ?? [], total, page, limit, pages: Math.ceil(total / limit) });
});
// POST /api/admin-cms/questions — Créer une question
adminCms.post('/questions', requireAdmin, async (c) => {
    const adminId = c.get('adminId');
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    // Validation
    const enonce = (body['enonce'] ?? body['question']);
    if (!enonce?.trim())
        return c.json({ error: 'L\'énoncé est requis.' }, 400);
    const bonne_reponse = body['bonne_reponse'];
    if (!bonne_reponse)
        return c.json({ error: 'La bonne réponse est requise.' }, 400);
    const matiere_id = body['matiere_id'];
    if (!matiere_id)
        return c.json({ error: 'La matière est requise.' }, 400);
    const db = getDB(c.env);
    // Anti-doublon
    const { data: existing } = await db.from('questions')
        .select('id')
        .eq('matiere_id', matiere_id)
        .ilike('enonce', enonce.trim())
        .limit(1);
    if (existing && existing.length > 0) {
        return c.json({ error: 'Cette question existe déjà dans cette matière.', duplicate: true }, 409);
    }
    // Auto-numéro
    const { data: last } = await db.from('questions')
        .select('numero').order('numero', { ascending: false }).limit(1);
    const numero = last && last[0]?.numero ? last[0].numero + 1 : 1;
    // Calcul numero_serie automatique
    const { count: totalInMatiere } = await db.from('questions')
        .select('*', { count: 'exact', head: true })
        .eq('matiere_id', matiere_id);
    const numero_serie = Math.ceil(((totalInMatiere ?? 0) + 1) / 20);
    const questionData = {
        enonce: enonce.trim(),
        option_a: body['option_a'] ?? '',
        option_b: body['option_b'] ?? '',
        option_c: body['option_c'],
        option_d: body['option_d'],
        option_e: body['option_e'] ?? null,
        bonne_reponse,
        explication: body['explication'] ?? '',
        difficulte: body['difficulte'] ?? 'MOYEN',
        matiere_id,
        serie_id: body['serie_id'] ?? null,
        pieges: body['pieges'] ?? null,
        sources: body['sources'] ?? null,
        numero,
        numero_serie,
        published: true,
        version: 1,
        type: 'QCM',
        created_by: adminId,
    };
    const { data, error } = await db.from('questions').insert(questionData).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    // Log audit
    await logAdminAction(db, adminId, 'create', 'question', data.id, null, questionData, `Création question: "${enonce.substring(0, 50)}..."`);
    return c.json({ success: true, question: data, question_id: data.id });
});
// GET /api/admin-cms/questions/:id — Détail d'une question
adminCms.get('/questions/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const db = getDB(c.env);
    const { data, error } = await db.from('questions')
        .select('*, matieres(nom, code)')
        .eq('id', id).single();
    if (error)
        return c.json({ error: error.message }, 404);
    return c.json({ success: true, question: data });
});
// PUT /api/admin-cms/questions/:id — Modifier une question
adminCms.put('/questions/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const adminId = c.get('adminId');
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    const db = getDB(c.env);
    // Récupérer ancienne version
    const { data: oldQ } = await db.from('questions').select('*').eq('id', id).single();
    if (!oldQ)
        return c.json({ error: 'Question introuvable.' }, 404);
    // Sauvegarder version historique
    try {
        await db.from('question_versions').insert({
            question_id: id,
            version_number: oldQ.version ?? 1,
            question_text: oldQ.enonce,
            propositions: JSON.stringify({
                a: oldQ.option_a, b: oldQ.option_b,
                c: oldQ.option_c, d: oldQ.option_d,
                bonne_reponse: oldQ.bonne_reponse
            }),
            explication: oldQ.explication,
            difficulte: oldQ.difficulte,
            created_by: adminId,
            change_summary: `Modification par admin ${adminId}`,
        });
    }
    catch (_) { }
    const updateData = {
        updated_at: new Date().toISOString(),
        updated_by: adminId,
        version: (oldQ.version ?? 1) + 1,
    };
    const allowedFields = [
        'enonce', 'option_a', 'option_b', 'option_c', 'option_d', 'option_e',
        'bonne_reponse', 'explication', 'difficulte', 'pieges', 'sources',
        'matiere_id', 'serie_id', 'published', 'numero_serie'
    ];
    for (const field of allowedFields) {
        if (field in body)
            updateData[field] = body[field];
    }
    const { data, error } = await db.from('questions').update(updateData).eq('id', id).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    await logAdminAction(db, adminId, 'edit', 'question', id, oldQ, updateData, `Modification question #${id}`);
    return c.json({ success: true, question: data, updated_at: updateData['updated_at'] });
});
// DELETE /api/admin-cms/questions/:id — Supprimer (soft delete via published=false ou hard delete)
adminCms.delete('/questions/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const adminId = c.get('adminId');
    const soft = c.req.query('soft') === 'true';
    const db = getDB(c.env);
    const { data: oldQ } = await db.from('questions').select('enonce').eq('id', id).single();
    if (soft) {
        // Soft delete : marquer comme non publié
        await db.from('questions').update({ published: false, updated_at: new Date().toISOString() }).eq('id', id);
        await logAdminAction(db, adminId, 'soft_delete', 'question', id, oldQ, null, `Question masquée: ${id}`);
        return c.json({ success: true, message: 'Question masquée (soft delete).' });
    }
    // Hard delete
    const { error } = await db.from('questions').delete().eq('id', id);
    if (error)
        return c.json({ error: error.message }, 500);
    await logAdminAction(db, adminId, 'delete', 'question', id, oldQ, null, `Question supprimée: ${id}`);
    return c.json({ success: true, message: 'Question supprimée définitivement.' });
});
// POST /api/admin-cms/questions/:id/duplicate — Dupliquer
adminCms.post('/questions/:id/duplicate', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const adminId = c.get('adminId');
    const db = getDB(c.env);
    const { data: original } = await db.from('questions').select('*').eq('id', id).single();
    if (!original)
        return c.json({ error: 'Question introuvable.' }, 404);
    const { data: last } = await db.from('questions').select('numero').order('numero', { ascending: false }).limit(1);
    const numero = last && last[0]?.numero ? last[0].numero + 1 : 1;
    const { id: _id, created_at: _ca, ...rest } = original;
    const newQ = {
        ...rest,
        enonce: `[COPIE] ${original.enonce}`,
        numero,
        version: 1,
        created_by: adminId,
        created_at: undefined,
    };
    const { data, error } = await db.from('questions').insert(newQ).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    await logAdminAction(db, adminId, 'duplicate', 'question', data.id, { original_id: id }, null, `Duplication de question #${id}`);
    return c.json({ success: true, new_question_id: data.id, question: data });
});
// ═══════════════════════════════════════════════════════════════
// IMPORT EN MASSE (CSV/JSON)
// ═══════════════════════════════════════════════════════════════
// POST /api/admin-cms/questions/validate-bulk — Valider avant import
adminCms.post('/questions/validate-bulk', requireAdmin, async (c) => {
    const adminId = c.get('adminId');
    const db = getDB(c.env);
    let questions = [];
    let filename = 'upload';
    let fileFormat = 'json';
    try {
        const contentType = c.req.header('content-type') ?? '';
        if (contentType.includes('application/json')) {
            // JSON direct
            const body = await c.req.json();
            questions = Array.isArray(body) ? body : body.questions ?? [];
            filename = 'data.json';
            fileFormat = 'json';
        }
        else if (contentType.includes('multipart/form-data')) {
            // Fichier uploadé
            const formData = await c.req.formData();
            const file = formData.get('file');
            if (!file)
                return c.json({ error: 'Fichier requis.' }, 400);
            filename = file.name;
            const text = await file.text();
            if (file.name.endsWith('.json') || contentType.includes('json')) {
                fileFormat = 'json';
                const parsed = JSON.parse(text);
                questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
            }
            else {
                // CSV parsing
                fileFormat = 'csv';
                questions = parseCSV(text);
            }
        }
        else {
            // Texte brut
            const text = await c.req.text();
            try {
                const parsed = JSON.parse(text);
                questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
                fileFormat = 'json';
            }
            catch {
                questions = parseCSV(text);
                fileFormat = 'csv';
            }
        }
    }
    catch (e) {
        return c.json({ error: `Erreur parsing: ${e.message}` }, 400);
    }
    if (!questions.length)
        return c.json({ error: 'Aucune question trouvée dans le fichier.' }, 400);
    // Validation
    const preview = [];
    const errors = [];
    let validCount = 0;
    for (let i = 0; i < questions.length; i++) {
        const q = questions[i];
        const lineErrors = [];
        const enonce = q.enonce ?? q.question ?? q.Question ?? '';
        const optA = q.option_a ?? q.A ?? q.a ?? '';
        const optB = q.option_b ?? q.B ?? q.b ?? '';
        const bonneRep = q.bonne_reponse ?? q.reponse ?? q.correct ?? '';
        if (!enonce?.trim())
            lineErrors.push('Énoncé vide');
        if (!optA?.trim())
            lineErrors.push('Option A vide');
        if (!optB?.trim())
            lineErrors.push('Option B vide');
        if (!bonneRep?.trim())
            lineErrors.push('Bonne réponse manquante');
        if (!['A', 'B', 'C', 'D', 'E'].includes((bonneRep ?? '').toUpperCase())) {
            lineErrors.push(`Bonne réponse invalide: "${bonneRep}" (doit être A/B/C/D/E)`);
        }
        const status = lineErrors.length === 0 ? '✅ valide' : `⚠️ ${lineErrors.join(', ')}`;
        if (i < 10) {
            preview.push({
                line: i + 1,
                question: enonce?.substring(0, 80),
                option_a: optA?.substring(0, 40),
                option_b: optB?.substring(0, 40),
                bonne_reponse: bonneRep,
                status,
            });
        }
        if (lineErrors.length === 0) {
            validCount++;
        }
        else {
            errors.push({ line: i + 1, errors: lineErrors });
        }
    }
    return c.json({
        success: true,
        filename,
        file_format: fileFormat,
        total: questions.length,
        total_valid: validCount,
        total_invalid: questions.length - validCount,
        preview,
        errors: errors.slice(0, 50),
        ready_to_import: validCount > 0,
    });
});
// POST /api/admin-cms/questions/bulk-import — Importer en masse
adminCms.post('/questions/bulk-import', requireAdmin, async (c) => {
    const adminId = c.get('adminId');
    const db = getDB(c.env);
    const startTime = Date.now();
    let questions = [];
    let filename = 'upload';
    let fileFormat = 'json';
    let matiereId = null;
    try {
        const contentType = c.req.header('content-type') ?? '';
        if (contentType.includes('application/json')) {
            const body = await c.req.json();
            questions = Array.isArray(body) ? body : body.questions ?? [];
            matiereId = !Array.isArray(body) ? body.matiere_id : null;
            filename = 'data.json';
            fileFormat = 'json';
        }
        else if (contentType.includes('multipart/form-data')) {
            const formData = await c.req.formData();
            const file = formData.get('file');
            matiereId = formData.get('matiere_id');
            if (!file)
                return c.json({ error: 'Fichier requis.' }, 400);
            filename = file.name;
            const text = await file.text();
            if (file.name.endsWith('.json')) {
                fileFormat = 'json';
                const parsed = JSON.parse(text);
                questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
            }
            else {
                fileFormat = 'csv';
                questions = parseCSV(text);
            }
        }
        else {
            const text = await c.req.text();
            try {
                const parsed = JSON.parse(text);
                questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
                fileFormat = 'json';
            }
            catch {
                questions = parseCSV(text);
                fileFormat = 'csv';
            }
        }
    }
    catch (e) {
        return c.json({ error: `Erreur parsing: ${e.message}` }, 400);
    }
    if (!questions.length)
        return c.json({ error: 'Aucune question à importer.' }, 400);
    // Récupérer numéro max actuel
    const { data: lastQ } = await db.from('questions').select('numero').order('numero', { ascending: false }).limit(1);
    let currentNumero = lastQ?.[0]?.numero ?? 0;
    // Import par batch de 50
    const BATCH_SIZE = 50;
    const importedIds = [];
    const errors = [];
    let importedCount = 0;
    let failedCount = 0;
    // Log import en cours
    let importLogId = null;
    try {
        const { data: importLog } = await db.from('bulk_import_logs').insert({
            admin_id: adminId,
            filename,
            file_format: fileFormat,
            total_lines: questions.length,
            status: 'pending',
            created_at: new Date().toISOString(),
        }).select().single();
        importLogId = importLog?.id;
    }
    catch (_) { }
    for (let i = 0; i < questions.length; i += BATCH_SIZE) {
        const batch = questions.slice(i, i + BATCH_SIZE);
        const batchData = [];
        for (const q of batch) {
            const enonce = q.enonce ?? q.question ?? q.Question ?? '';
            const optA = q.option_a ?? q.A ?? q.a ?? '';
            const optB = q.option_b ?? q.B ?? q.b ?? '';
            const optC = q.option_c ?? q.C ?? q.c ?? null;
            const optD = q.option_d ?? q.D ?? q.d ?? null;
            const optE = q.option_e ?? q.E ?? q.e ?? null;
            const bonneRep = (q.bonne_reponse ?? q.reponse ?? q.correct ?? 'A').toUpperCase();
            const explication = q.explication ?? q.explanation ?? '';
            const difficulte = (q.difficulte ?? q.difficulty ?? 'MOYEN').toUpperCase();
            const qMatiereId = q.matiere_id ?? matiereId;
            const pieges = q.pieges ?? q.traps ?? null;
            const sources = q.sources ?? q.source ?? null;
            if (!enonce?.trim() || !optA?.trim() || !optB?.trim()) {
                errors.push({ line: i + batch.indexOf(q) + 1, error: 'Champs requis manquants' });
                failedCount++;
                continue;
            }
            currentNumero++;
            // Calcul numero_serie
            const totalInMatiere = importedCount + (qMatiereId ? 0 : 0);
            const numero_serie = Math.ceil(currentNumero / 20);
            batchData.push({
                enonce: enonce.trim(),
                option_a: optA.trim(),
                option_b: optB.trim(),
                option_c: optC?.trim() ?? null,
                option_d: optD?.trim() ?? null,
                option_e: optE?.trim() ?? null,
                bonne_reponse: bonneRep,
                explication: explication.trim(),
                difficulte: ['FACILE', 'MOYEN', 'DIFFICILE'].includes(difficulte) ? difficulte : 'MOYEN',
                matiere_id: qMatiereId,
                numero: currentNumero,
                numero_serie,
                published: true,
                version: 1,
                type: 'QCM',
                created_by: adminId,
                pieges: pieges?.trim() ?? null,
                sources: sources?.trim() ?? null,
            });
        }
        if (batchData.length > 0) {
            const { data: inserted, error } = await db.from('questions').insert(batchData).select('id');
            if (error) {
                errors.push({ batch: `${i}-${i + BATCH_SIZE}`, error: error.message });
                failedCount += batchData.length;
            }
            else {
                importedCount += inserted?.length ?? 0;
                importedIds.push(...(inserted?.map((q) => q.id) ?? []));
            }
        }
    }
    const duration = Math.round((Date.now() - startTime) / 1000);
    // Mettre à jour le log d'import
    if (importLogId) {
        await db.from('bulk_import_logs').update({
            imported_count: importedCount,
            failed_count: failedCount,
            errors: errors.length > 0 ? JSON.stringify(errors.slice(0, 20)) : null,
            imported_question_ids: JSON.stringify(importedIds.slice(0, 100)),
            status: failedCount === 0 ? 'success' : (importedCount > 0 ? 'partial_error' : 'failed'),
            completed_at: new Date().toISOString(),
            import_duration_seconds: duration,
        }).eq('id', importLogId);
    }
    await logAdminAction(db, adminId, 'bulk_import', 'question', importLogId?.toString() ?? '0', null, { imported: importedCount, failed: failedCount }, `Import en masse: ${importedCount}/${questions.length} questions importées`);
    return c.json({
        success: importedCount > 0,
        imported: importedCount,
        failed: failedCount,
        total: questions.length,
        import_id: importLogId,
        duration_seconds: duration,
        created_questions: importedIds.slice(0, 50),
        errors: errors.slice(0, 10),
    });
});
// GET /api/admin-cms/questions/import-history — Historique des imports
adminCms.get('/questions/import-history', requireAdmin, async (c) => {
    const db = getDB(c.env);
    const { data, error } = await db.from('bulk_import_logs')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(20);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, imports: data ?? [] });
});
// DELETE /api/admin-cms/questions/import/:importId — Annuler un import
adminCms.delete('/questions/import/:importId', requireAdmin, async (c) => {
    const importId = c.req.param('importId');
    const adminId = c.get('adminId');
    const db = getDB(c.env);
    const { data: log } = await db.from('bulk_import_logs').select('*').eq('id', importId).single();
    if (!log)
        return c.json({ error: 'Import introuvable.' }, 404);
    let deleted = 0;
    if (log.imported_question_ids) {
        try {
            const ids = JSON.parse(log.imported_question_ids);
            if (Array.isArray(ids) && ids.length > 0) {
                for (let i = 0; i < ids.length; i += 100) {
                    const batch = ids.slice(i, i + 100);
                    const { error } = await db.from('questions').delete().in('id', batch);
                    if (!error)
                        deleted += batch.length;
                }
            }
        }
        catch (_) { }
    }
    await db.from('bulk_import_logs').update({ status: 'cancelled' }).eq('id', importId);
    await logAdminAction(db, adminId, 'cancel_import', 'bulk_import', importId, null, null, `Import annulé: ${deleted} questions supprimées`);
    return c.json({ success: true, deleted, message: `${deleted} questions supprimées.` });
});
// ═══════════════════════════════════════════════════════════════
// GESTION SÉRIES
// ═══════════════════════════════════════════════════════════════
// GET /api/admin-cms/series — Lister les séries
adminCms.get('/series', requireAdmin, async (c) => {
    const db = getDB(c.env);
    const matiereId = c.req.query('matiere_id');
    const matiereCode = c.req.query('matiere');
    let qMatiereId = matiereId;
    if (!qMatiereId && matiereCode) {
        const { data: mat } = await db.from('matieres').select('id').ilike('code', matiereCode).maybeSingle();
        qMatiereId = mat?.id;
    }
    let query = db.from('series_qcm')
        .select('id, titre, numero, matiere_id, niveau, nb_questions, actif, published, created_at, updated_at, matieres(nom, code)');
    if (qMatiereId)
        query = query.eq('matiere_id', qMatiereId);
    const { data, error } = await query.order('numero', { ascending: true }).limit(500);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, series: data ?? [] });
});
// POST /api/admin-cms/series — Créer une série
adminCms.post('/series', requireAdmin, async (c) => {
    const adminId = c.get('adminId');
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    const { titre, matiere_id, numero, question_ids, niveau, duree_minutes } = body;
    if (!titre || !matiere_id)
        return c.json({ error: 'Titre et matière requis.' }, 400);
    const db = getDB(c.env);
    // Calculer nb_questions
    let nb_questions = 0;
    if (Array.isArray(question_ids) && question_ids.length > 0) {
        nb_questions = question_ids.length;
        // Assigner les questions à cette série
        await db.from('questions').update({ serie_id: null }).in('id', question_ids);
    }
    // Auto-numéro si pas fourni
    let serieNumero = numero;
    if (!serieNumero) {
        const { data: last } = await db.from('series_qcm')
            .select('numero').eq('matiere_id', matiere_id)
            .order('numero', { ascending: false }).limit(1);
        serieNumero = (last?.[0]?.numero ?? 0) + 1;
    }
    const { data, error } = await db.from('series_qcm').insert({
        titre: titre.trim(),
        matiere_id,
        numero: serieNumero,
        nb_questions,
        niveau: niveau ?? 'INTERMEDIAIRE',
        duree_minutes: duree_minutes ?? 15,
        actif: true,
        published: true,
        est_demo: false,
        created_by: adminId,
        created_at: new Date().toISOString(),
    }).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    // Assigner les questions à la série créée
    if (Array.isArray(question_ids) && question_ids.length > 0) {
        await db.from('questions').update({ serie_id: data.id }).in('id', question_ids);
    }
    await logAdminAction(db, adminId, 'create', 'serie', data.id, null, data, `Série créée: "${titre}"`);
    return c.json({ success: true, serie: data, series_id: data.id });
});
// POST /api/admin-cms/series/auto-generate — Créer série automatique
adminCms.post('/series/auto-generate', requireAdmin, async (c) => {
    const adminId = c.get('adminId');
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    const { matiere_id, count = 20 } = body;
    if (!matiere_id)
        return c.json({ error: 'matiere_id requis.' }, 400);
    const db = getDB(c.env);
    // Récupérer questions non assignées pour cette matière
    const { data: available } = await db.from('questions')
        .select('id').eq('matiere_id', matiere_id)
        .is('serie_id', null).eq('published', true)
        .limit(count);
    if (!available || available.length === 0) {
        // Si pas de questions sans série, prendre les dernières créées
        const { data: all } = await db.from('questions')
            .select('id').eq('matiere_id', matiere_id).eq('published', true)
            .order('created_at', { ascending: false }).limit(count);
        if (!all?.length)
            return c.json({ error: 'Aucune question disponible pour cette matière.' }, 400);
        available?.push(...(all ?? []));
    }
    const questionIds = (available ?? []).map((q) => q.id);
    // Auto-numéro
    const { data: last } = await db.from('series_qcm')
        .select('numero, titre').eq('matiere_id', matiere_id)
        .order('numero', { ascending: false }).limit(1);
    const serieNumero = (last?.[0]?.numero ?? 0) + 1;
    const { data: mat } = await db.from('matieres').select('nom').eq('id', matiere_id).single();
    const { data, error } = await db.from('series_qcm').insert({
        titre: `Série ${serieNumero} — ${mat?.nom ?? 'Matière'}`,
        matiere_id,
        numero: serieNumero,
        nb_questions: questionIds.length,
        niveau: 'INTERMEDIAIRE',
        duree_minutes: 15,
        actif: true,
        published: true,
        est_demo: false,
        created_by: adminId,
        created_at: new Date().toISOString(),
    }).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    // Assigner les questions
    await db.from('questions').update({ serie_id: data.id }).in('id', questionIds);
    return c.json({ success: true, serie: data, series_id: data.id, questions_used: questionIds.length });
});
// PUT /api/admin-cms/series/:id — Modifier une série
adminCms.put('/series/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const adminId = c.get('adminId');
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    const db = getDB(c.env);
    const { data: old } = await db.from('series_qcm').select('*').eq('id', id).single();
    const updateData = {
        updated_at: new Date().toISOString(),
        updated_by: adminId,
    };
    if ('titre' in body)
        updateData['titre'] = body['titre'];
    if ('numero' in body)
        updateData['numero'] = body['numero'];
    if ('niveau' in body)
        updateData['niveau'] = body['niveau'];
    if ('actif' in body)
        updateData['actif'] = body['actif'];
    if ('published' in body)
        updateData['published'] = body['published'];
    // Mise à jour des questions incluses
    const question_ids = body.question_ids;
    if (Array.isArray(question_ids)) {
        // Retirer l'ancienne assignation
        await db.from('questions').update({ serie_id: null }).eq('serie_id', id);
        // Assigner les nouvelles questions
        if (question_ids.length > 0) {
            await db.from('questions').update({ serie_id: id }).in('id', question_ids);
        }
        updateData['nb_questions'] = question_ids.length;
    }
    const { data, error } = await db.from('series_qcm').update(updateData).eq('id', id).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    await logAdminAction(db, adminId, 'edit', 'serie', id, old, updateData, `Série modifiée: ${id}`);
    return c.json({ success: true, serie: data });
});
// DELETE /api/admin-cms/series/:id — Supprimer une série
adminCms.delete('/series/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const adminId = c.get('adminId');
    const orphan_action = c.req.query('orphan') ?? 'keep'; // 'keep' ou 'delete'
    const db = getDB(c.env);
    // Gérer les questions orphelines
    if (orphan_action === 'delete') {
        await db.from('questions').delete().eq('serie_id', id);
    }
    else {
        await db.from('questions').update({ serie_id: null }).eq('serie_id', id);
    }
    const { error } = await db.from('series_qcm').delete().eq('id', id);
    if (error)
        return c.json({ error: error.message }, 500);
    await logAdminAction(db, adminId, 'delete', 'serie', id, null, null, `Série supprimée: ${id}`);
    return c.json({ success: true, message: 'Série supprimée.' });
});
// POST /api/admin-cms/series/:id/duplicate — Dupliquer une série
adminCms.post('/series/:id/duplicate', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const adminId = c.get('adminId');
    const db = getDB(c.env);
    const { data: original } = await db.from('series_qcm').select('*').eq('id', id).single();
    if (!original)
        return c.json({ error: 'Série introuvable.' }, 404);
    const { data: last } = await db.from('series_qcm')
        .select('numero').eq('matiere_id', original.matiere_id)
        .order('numero', { ascending: false }).limit(1);
    const numero = (last?.[0]?.numero ?? 0) + 1;
    const { id: _id, created_at: _ca, ...rest } = original;
    const { data, error } = await db.from('series_qcm').insert({
        ...rest,
        titre: `[COPIE] ${original.titre}`,
        numero,
        created_by: adminId,
        created_at: new Date().toISOString(),
    }).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, new_series_id: data.id, serie: data });
});
// ═══════════════════════════════════════════════════════════════
// GESTION SIMULATIONS D'EXAMEN
// ═══════════════════════════════════════════════════════════════
// GET /api/admin-cms/simulations — Lister
adminCms.get('/simulations', requireAdmin, async (c) => {
    const db = getDB(c.env);
    const { data, error } = await db.from('simulations_examens')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, simulations: data ?? [] });
});
// POST /api/admin-cms/simulations — Créer une simulation
adminCms.post('/simulations', requireAdmin, async (c) => {
    const adminId = c.get('adminId');
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    const { titre, description, duree_minutes, score_max, questions: questionConfig, ordre_questions, show_corrections, show_score_after } = body;
    if (!titre)
        return c.json({ error: 'Titre requis.' }, 400);
    const db = getDB(c.env);
    let questionIds = [];
    // Si config par matière fournie : sélectionner les questions
    if (Array.isArray(questionConfig)) {
        for (const config of questionConfig) {
            if (config.matiere_id && config.count > 0) {
                const { data: qs } = await db.from('questions')
                    .select('id').eq('matiere_id', config.matiere_id)
                    .eq('published', true).limit(config.count * 3); // Prendre 3x pour shuffle
                const available = qs ?? [];
                const shuffled = available.sort(() => Math.random() - 0.5).slice(0, config.count);
                questionIds.push(...shuffled.map((q) => q.id));
            }
            else if (Array.isArray(config.question_ids)) {
                questionIds.push(...config.question_ids);
            }
        }
    }
    else if (Array.isArray(body.question_ids)) {
        questionIds = body.question_ids;
    }
    const { data, error } = await db.from('simulations_examens').insert({
        titre: titre.trim(),
        description: description?.trim() ?? null,
        duree_minutes: duree_minutes ?? 90,
        score_max: score_max ?? 50,
        question_ids: JSON.stringify(questionIds),
        created_by: adminId,
        published: true,
        ordre_questions: ordre_questions ?? 'random',
        show_corrections: show_corrections !== false,
        show_score_after: show_score_after !== false,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
    }).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    await logAdminAction(db, adminId, 'create', 'simulation', data.id.toString(), null, { titre, total_questions: questionIds.length }, `Simulation créée: "${titre}"`);
    return c.json({
        success: true, simulation: data, simulation_id: data.id,
        total_questions: questionIds.length, question_ids: questionIds,
    });
});
// PUT /api/admin-cms/simulations/:id — Modifier
adminCms.put('/simulations/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const adminId = c.get('adminId');
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    const db = getDB(c.env);
    const updateData = {
        updated_at: new Date().toISOString(),
    };
    const allowedFields = ['titre', 'description', 'duree_minutes', 'score_max', 'published', 'ordre_questions', 'show_corrections', 'show_score_after'];
    for (const field of allowedFields) {
        if (field in body)
            updateData[field] = body[field];
    }
    if (body.question_ids) {
        updateData['question_ids'] = JSON.stringify(body.question_ids);
    }
    const { data, error } = await db.from('simulations_examens').update(updateData).eq('id', id).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, simulation: data });
});
// DELETE /api/admin-cms/simulations/:id — Supprimer
adminCms.delete('/simulations/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const adminId = c.get('adminId');
    const db = getDB(c.env);
    const { error } = await db.from('simulations_examens').delete().eq('id', id);
    if (error)
        return c.json({ error: error.message }, 500);
    await logAdminAction(db, adminId, 'delete', 'simulation', id, null, null, `Simulation supprimée: ${id}`);
    return c.json({ success: true, message: 'Simulation supprimée.' });
});
// GET /api/admin-cms/simulations/:id — Détail
adminCms.get('/simulations/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const db = getDB(c.env);
    const { data, error } = await db.from('simulations_examens').select('*').eq('id', id).single();
    if (error)
        return c.json({ error: error.message }, 404);
    // Récupérer les questions incluses
    let questions = [];
    try {
        const qIds = JSON.parse(data.question_ids ?? '[]');
        if (qIds.length > 0) {
            const { data: qs } = await db.from('questions')
                .select('id, enonce, difficulte, matiere_id, matieres(nom)')
                .in('id', qIds).limit(200);
            questions = qs ?? [];
        }
    }
    catch (_) { }
    return c.json({ success: true, simulation: data, questions });
});
// ═══════════════════════════════════════════════════════════════
// ANALYTICS & SIGNALEMENTS
// ═══════════════════════════════════════════════════════════════
// GET /api/admin-cms/analytics/dashboard — Stats globales
adminCms.get('/analytics/dashboard', requireAdmin, async (c) => {
    const db = getDB(c.env);
    const [{ count: totalUsers }, { count: totalQuestions }, { count: totalSimulationsPlayed }, { count: totalFlags }, { count: pendingFlags }, { count: totalSimulationsExamens },] = await Promise.all([
        db.from('profiles').select('*', { count: 'exact', head: true }),
        db.from('questions').select('*', { count: 'exact', head: true }).eq('published', true),
        db.from('sessions_examen').select('*', { count: 'exact', head: true }).eq('termine', true),
        db.from('question_flags').select('*', { count: 'exact', head: true }),
        db.from('question_flags').select('*', { count: 'exact', head: true }).eq('status', 'new'),
        db.from('simulations_examens').select('*', { count: 'exact', head: true }).eq('published', true),
    ]);
    // Score moyen
    let avgScore = 0;
    try {
        const { data: sessions } = await db.from('sessions_examen')
            .select('score_pourcentage').eq('termine', true).limit(100);
        if (sessions?.length) {
            avgScore = Math.round(sessions.reduce((sum, s) => sum + (s.score_pourcentage ?? 0), 0) / sessions.length);
        }
    }
    catch (_) { }
    // Matières populaires
    let matiereStats = [];
    try {
        const { data: mats } = await db.from('matieres').select('id, nom, code').limit(20);
        for (const mat of (mats ?? []).slice(0, 5)) {
            const { count: nb } = await db.from('questions')
                .select('*', { count: 'exact', head: true })
                .eq('matiere_id', mat.id).eq('published', true);
            matiereStats.push({ ...mat, nb_questions: nb ?? 0 });
        }
        matiereStats.sort((a, b) => b.nb_questions - a.nb_questions);
    }
    catch (_) { }
    // Signalements récents
    let recentFlags = [];
    try {
        const { data: flags } = await db.from('question_flags')
            .select('id, question_id, reason, created_at, status')
            .eq('status', 'new').order('created_at', { ascending: false }).limit(5);
        recentFlags = flags ?? [];
    }
    catch (_) { }
    // Imports récents
    let recentImports = [];
    try {
        const { data: imports } = await db.from('bulk_import_logs')
            .select('id, filename, imported_count, status, created_at')
            .order('created_at', { ascending: false }).limit(5);
        recentImports = imports ?? [];
    }
    catch (_) { }
    return c.json({
        success: true,
        stats: {
            total_users: totalUsers ?? 0,
            total_questions: totalQuestions ?? 0,
            total_simulations_played: totalSimulationsPlayed ?? 0,
            total_simulations_examens: totalSimulationsExamens ?? 0,
            avg_score: avgScore,
            total_flags: totalFlags ?? 0,
            pending_flags: pendingFlags ?? 0,
            matiere_stats: matiereStats,
            recent_flags: recentFlags,
            recent_imports: recentImports,
        }
    });
});
// GET /api/admin-cms/flags — Signalements
adminCms.get('/flags', requireAdmin, async (c) => {
    const db = getDB(c.env);
    const status = c.req.query('status') ?? 'new';
    const page = parseInt(c.req.query('page') ?? '1');
    const limit = 20;
    const offset = (page - 1) * limit;
    // Requête sans join (pas de FK déclarée) — on enrichit manuellement
    let query = db.from('question_flags').select('*');
    if (status !== 'all') {
        query = query.eq('status', status);
    }
    const { data, error } = await query
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);
    if (error)
        return c.json({ error: error.message }, 500);
    // Enrichir avec les données de questions (si question_id présent)
    const flags = data ?? [];
    const enriched = await Promise.all(flags.map(async (flag) => {
        if (!flag.question_id)
            return flag;
        try {
            const { data: q } = await db.from('questions')
                .select('enonce, matiere_id')
                .eq('id', flag.question_id)
                .single();
            return { ...flag, question: q ?? null };
        }
        catch (_) {
            return { ...flag, question: null };
        }
    }));
    return c.json({ success: true, flags: enriched });
});
// PUT /api/admin-cms/flags/:id — Résoudre un signalement
adminCms.put('/flags/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const adminId = c.get('adminId');
    const body = await c.req.json().catch(() => ({}));
    const db = getDB(c.env);
    const { data, error } = await db.from('question_flags').update({
        status: body['status'] ?? 'resolved',
        admin_response: body['admin_note'] ?? body['admin_response'],
        resolved_by: adminId,
        resolved_at: new Date().toISOString(),
    }).eq('id', id).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, flag: data });
});
// POST /api/admin-cms/flags — Créer un signalement (depuis l'app user)
adminCms.post('/flags', async (c) => {
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    const { question_id, user_id, reason, details } = body;
    if (!question_id || !user_id || !reason) {
        return c.json({ error: 'question_id, user_id et reason requis.' }, 400);
    }
    const db = getDB(c.env);
    const { data, error } = await db.from('question_flags').insert({
        question_id, user_id, reason, details: details ?? null,
        status: 'new', created_at: new Date().toISOString(),
    }).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, flag: data, message: 'Signalement enregistré.' });
});
// GET /api/admin-cms/audit-log — Historique des modifications
adminCms.get('/audit-log', requireAdmin, async (c) => {
    const db = getDB(c.env);
    const page = parseInt(c.req.query('page') ?? '1');
    const limit = 20;
    const offset = (page - 1) * limit;
    const action = c.req.query('action');
    const resourceType = c.req.query('resource_type');
    let query = db.from('admin_audit_log').select('*');
    if (action)
        query = query.eq('action', action);
    if (resourceType)
        query = query.eq('resource_type', resourceType);
    const { data, error } = await query
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, logs: data ?? [] });
});
// GET /api/admin-cms/questions/:id/analytics — Stats d'une question
adminCms.get('/questions/:id/analytics', requireAdmin, async (c) => {
    const questionId = c.req.param('id');
    const db = getDB(c.env);
    const { data: q } = await db.from('questions')
        .select('*, matieres(nom)').eq('id', questionId).single();
    if (!q)
        return c.json({ error: 'Question introuvable.' }, 404);
    // Signalements
    let flagCount = 0;
    let flags = [];
    try {
        const { count } = await db.from('question_flags')
            .select('*', { count: 'exact', head: true }).eq('question_id', questionId);
        flagCount = count ?? 0;
        const { data: fData } = await db.from('question_flags')
            .select('user_id, reason, created_at, status')
            .eq('question_id', questionId).limit(10);
        flags = fData ?? [];
    }
    catch (_) { }
    return c.json({
        success: true,
        question_id: questionId,
        question: q.enonce,
        matiere: q.matieres?.nom,
        difficulte: q.difficulte,
        flagged_count: flagCount,
        version: q.version ?? 1,
        flags,
    });
});
// GET /api/admin-cms/matieres — Liste des matières pour le CMS
adminCms.get('/matieres', requireAdmin, async (c) => {
    const db = getDB(c.env);
    const { data, error } = await db.from('matieres')
        .select('id, nom, code, icone, couleur, ordre')
        .order('ordre', { ascending: true }).limit(50);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, matieres: data ?? [] });
});
// ═══════════════════════════════════════════════════════════════
// FONCTION UTILITAIRE : Parser CSV
// ═══════════════════════════════════════════════════════════════
function parseCSV(text) {
    const lines = text.split('\n').filter(l => l.trim());
    if (lines.length < 2)
        return [];
    // Première ligne = en-têtes
    const headers = lines[0].split(';').map(h => h.trim().toLowerCase().replace(/['"]/g, '')
        .replace('question', 'enonce')
        .replace('réponse correcte', 'bonne_reponse')
        .replace('reponse correcte', 'bonne_reponse')
        .replace('correct', 'bonne_reponse')
        .replace('proposition a', 'option_a')
        .replace('proposition b', 'option_b')
        .replace('proposition c', 'option_c')
        .replace('proposition d', 'option_d')
        .replace('proposition e', 'option_e'));
    const results = [];
    for (let i = 1; i < lines.length; i++) {
        const values = lines[i].split(';').map(v => v.trim().replace(/^["']|["']$/g, ''));
        const obj = {};
        headers.forEach((h, idx) => {
            obj[h] = values[idx] ?? '';
        });
        // Mapping alternatif : colonnes A, B, C, D, E
        if (!obj['option_a'] && obj['a'])
            obj['option_a'] = obj['a'];
        if (!obj['option_b'] && obj['b'])
            obj['option_b'] = obj['b'];
        if (!obj['option_c'] && obj['c'])
            obj['option_c'] = obj['c'];
        if (!obj['option_d'] && obj['d'])
            obj['option_d'] = obj['d'];
        if (!obj['option_e'] && obj['e'])
            obj['option_e'] = obj['e'];
        results.push(obj);
    }
    return results;
}
export default adminCms;
