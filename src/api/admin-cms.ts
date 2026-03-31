import { Hono } from 'hono';
import { getDB, Env } from '../lib/db';
import { verifyJWT } from '../lib/auth';

const adminCms = new Hono<{ Bindings: Env }>();

// ═══════════════════════════════════════════════════════════════
// MIDDLEWARE ADMIN
// ═══════════════════════════════════════════════════════════════
async function requireAdmin(c: any, next: any) {
  const h = c.req.header('Authorization');
  if (!h?.startsWith('Bearer ')) return c.json({ error: 'Auth requise.' }, 401);
  const p = await verifyJWT(h.slice(7));
  if (!p || !p['is_admin']) return c.json({ error: 'Accès admin requis.' }, 403);
  c.set('adminId', p['id'] as string);
  await next();
}

// ── Log une action admin ────────────────────────────────────────
async function logAdminAction(
  db: any, adminId: string, action: string,
  resourceType: string, resourceId: string, 
  oldContent?: any, newContent?: any, description?: string
) {
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
  } catch (_) {
    // Ne pas bloquer si le log échoue
  }
}

// ═══════════════════════════════════════════════════════════════
// MIGRATION — Créer tables CMS si inexistantes
// ═══════════════════════════════════════════════════════════════
adminCms.post('/migrate-cms', async (c) => {
  const body = await c.req.json().catch(() => ({})) as Record<string, unknown>;
  if (body['secret'] !== 'EfFortCMS2026!Migration') {
    return c.json({ error: 'Secret invalide.' }, 403);
  }

  const db = getDB(c.env);
  const results: Record<string, string> = {};

  // Vérifier chaque table
  const tablesToCheck = [
    'admin_audit_log', 'question_versions', 'question_flags',
    'bulk_import_logs', 'simulations_examens', 'simulation_results'
  ];

  for (const table of tablesToCheck) {
    const { error } = await db.from(table).select('id').limit(1);
    if (error?.code === '42P01' || error?.message?.includes('does not exist')) {
      results[table] = 'MISSING';
    } else {
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
  question_ids JSONB DEFAULT '[]', created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT now(), updated_at TIMESTAMPTZ DEFAULT now(),
  published BOOLEAN DEFAULT false, ordre_questions VARCHAR(50) DEFAULT 'sequential',
  show_corrections BOOLEAN DEFAULT true, show_score_after BOOLEAN DEFAULT true,
  type VARCHAR(50) DEFAULT 'simulation'
);
-- Ajouter colonne type si elle n'existe pas
ALTER TABLE simulations_examens ADD COLUMN IF NOT EXISTS type VARCHAR(50) DEFAULT 'simulation';
ALTER TABLE simulations_examens ADD COLUMN IF NOT EXISTS questions JSONB DEFAULT '[]';

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

// POST /api/admin-cms/migrate-type-column — Ajouter colonne type dans simulations_examens
// Utilise l'API Supabase pour ALTER TABLE via une RPC ou un INSERT factice
adminCms.post('/migrate-type-column', async (c) => {
  const body = await c.req.json().catch(() => ({})) as Record<string, unknown>;
  if (body['secret'] !== 'EfFortCMS2026!Migration') {
    return c.json({ error: 'Secret invalide.' }, 403);
  }

  const db = getDB(c.env);
  
  // Tester si la colonne type existe
  const { error: testError } = await db.from('simulations_examens')
    .select('id, type')
    .limit(1);
  
  if (!testError) {
    return c.json({
      success: true,
      message: '✅ La colonne "type" existe déjà dans simulations_examens.',
      status: 'already_exists'
    });
  }
  
  if (testError.message?.includes('type does not exist')) {
    // La colonne n'existe pas - retourner le SQL à exécuter manuellement
    return c.json({
      success: false,
      status: 'column_missing',
      message: '❌ La colonne "type" n\'existe pas. Exécutez ce SQL dans Supabase SQL Editor.',
      sql: `ALTER TABLE simulations_examens ADD COLUMN IF NOT EXISTS type VARCHAR(50) DEFAULT 'simulation';
CREATE INDEX IF NOT EXISTS idx_simulations_type ON simulations_examens(type);
UPDATE simulations_examens SET type = 'simulation' WHERE type IS NULL;`,
      url: 'https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new'
    }, 422);
  }

  return c.json({ success: false, error: testError.message }, 500);
});

// ═══════════════════════════════════════════════════════════════
// GESTION QUESTIONS — CRUD COMPLET
// ═══════════════════════════════════════════════════════════════

// GET /api/admin-cms/questions — Lister avec filtres
adminCms.get('/questions', requireAdmin, async (c) => {
  const db = getDB(c.env);
  const matiereCode = c.req.query('matiere');
  const matiereIdDirect = c.req.query('matiere_id');  // Filtre direct par ID
  const serieId = c.req.query('serie_id');
  const difficulte = c.req.query('difficulte');
  const search = c.req.query('search');
  const page = Math.max(1, parseInt(c.req.query('page') ?? '1'));
  const limit = Math.min(parseInt(c.req.query('limit') ?? '20'), 500);
  const offset = (page - 1) * limit;

  let query = db.from('questions')
    .select('id, enonce, option_a, option_b, option_c, option_d, option_e, bonne_reponse, explication, difficulte, matiere_id, serie_id, numero, numero_serie, pieges, sources, published, version, created_at, updated_at');

  // Résoudre l'ID de matière (par code OU directement par ID)
  let resolvedMatiereId: string | undefined = matiereIdDirect;
  if (!resolvedMatiereId && matiereCode) {
    const { data: mat } = await db.from('matieres').select('id').ilike('code', matiereCode).maybeSingle();
    resolvedMatiereId = mat?.id;
  }

  if (resolvedMatiereId) {
    query = query.eq('matiere_id', resolvedMatiereId) as typeof query;
  }

  // Filtre par série
  if (serieId) {
    query = query.eq('serie_id', serieId) as typeof query;
  }

  // Filtre par difficulté
  if (difficulte && difficulte !== 'TOUS') {
    query = query.eq('difficulte', difficulte) as typeof query;
  }

  // Recherche full-text
  if (search) {
    query = query.ilike('enonce', `%${search}%`) as typeof query;
  }

  // Compter le total
  let total = 0;
  try {
    let countQ = db.from('questions').select('*', { count: 'exact', head: true });
    if (resolvedMatiereId) countQ = countQ.eq('matiere_id', resolvedMatiereId) as typeof countQ;
    if (serieId) countQ = countQ.eq('serie_id', serieId) as typeof countQ;
    if (difficulte && difficulte !== 'TOUS') countQ = countQ.eq('difficulte', difficulte) as typeof countQ;
    if (search) countQ = countQ.ilike('enonce', `%${search}%`) as typeof countQ;
    const { count } = await countQ;
    total = count ?? 0;
  } catch (_) {}

  const { data, error } = await query
    .range(offset, offset + limit - 1)
    .order('created_at', { ascending: false });

  if (error) return c.json({ error: error.message }, 500);

  return c.json({ success: true, questions: data ?? [], total, page, limit, pages: Math.ceil(total / limit) });
});

// POST /api/admin-cms/questions — Créer une question
adminCms.post('/questions', requireAdmin, async (c) => {
  const adminId = (c as any).get('adminId') as string;
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps invalide.' }, 400);

  // Validation
  const enonce = (body['enonce'] ?? body['question']) as string;
  if (!enonce?.trim()) return c.json({ error: 'L\'énoncé est requis.' }, 400);

  const bonne_reponse = body['bonne_reponse'] as string;
  if (!bonne_reponse) return c.json({ error: 'La bonne réponse est requise.' }, 400);

  const matiere_id = body['matiere_id'] as string;
  if (!matiere_id) return c.json({ error: 'La matière est requise.' }, 400);

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

  // ── AUTO-ASSIGNATION DE SÉRIE ─────────────────────────────
  // Si pas de serie_id fourni, trouver ou créer une série pour cette matière
  let serieId = body['serie_id'] as string ?? null;
  if (!serieId) {
    // Chercher la dernière série active de cette matière avec des places disponibles
    const { data: existingSeries } = await db.from('series_qcm')
      .select('id, titre, nb_questions, numero')
      .eq('matiere_id', matiere_id)
      .eq('actif', true)
      .order('numero', { ascending: false })
      .limit(1);

    if (existingSeries && existingSeries.length > 0) {
      const lastSerie = existingSeries[0];
      // Compter les vraies questions de cette série
      const { count: vraiNbQ } = await db.from('questions')
        .select('*', { count: 'exact', head: true })
        .eq('serie_id', lastSerie.id);
      
      if ((vraiNbQ ?? 0) < 20) {
        // Il y a de la place dans cette série
        serieId = lastSerie.id;
      } else {
        // Créer une nouvelle série auto
        const { data: matInfo } = await db.from('matieres').select('nom').eq('id', matiere_id).single();
        const newNum = (lastSerie.numero ?? 0) + 1;
        const { data: newSerie } = await db.from('series_qcm').insert({
          titre: `Série ${String(newNum).padStart(2, '0')} — ${matInfo?.nom ?? 'Matière'}`,
          matiere_id,
          numero: newNum,
          nb_questions: 0,
          niveau: 'INTERMEDIAIRE',
          duree_minutes: 20,
          actif: true,
          published: true,
          est_demo: false,
          created_by: adminId,
          created_at: new Date().toISOString(),
        }).select().single();
        if (newSerie) serieId = newSerie.id;
      }
    } else {
      // Aucune série pour cette matière — en créer une première
      const { data: matInfo } = await db.from('matieres').select('nom').eq('id', matiere_id).single();
      const { data: newSerie } = await db.from('series_qcm').insert({
        titre: `Série 01 — ${matInfo?.nom ?? 'Matière'}`,
        matiere_id,
        numero: 1,
        nb_questions: 0,
        niveau: 'INTERMEDIAIRE',
        duree_minutes: 20,
        actif: true,
        published: true,
        est_demo: false,
        created_by: adminId,
        created_at: new Date().toISOString(),
      }).select().single();
      if (newSerie) serieId = newSerie.id;
    }
  }

  const questionData = {
    enonce: enonce.trim(),
    option_a: body['option_a'] as string ?? '',
    option_b: body['option_b'] as string ?? '',
    option_c: body['option_c'] as string,
    option_d: body['option_d'] as string,
    option_e: body['option_e'] as string ?? null,
    bonne_reponse,
    explication: body['explication'] as string ?? '',
    difficulte: (body['difficulte'] as string) ?? 'MOYEN',
    matiere_id,
    serie_id: serieId,
    pieges: body['pieges'] as string ?? null,
    sources: body['sources'] as string ?? null,
    numero,
    numero_serie,
    published: true,
    version: 1,
    type: 'QCM',
    created_by: adminId,
  };

  const { data, error } = await db.from('questions').insert(questionData).select().single();
  if (error) return c.json({ error: error.message }, 500);

  // ── Mettre à jour nb_questions sur la série ─────────────
  if (serieId) {
    try {
      const { count: newNb } = await db.from('questions')
        .select('*', { count: 'exact', head: true })
        .eq('serie_id', serieId);
      await db.from('series_qcm').update({ nb_questions: newNb ?? 1 }).eq('id', serieId);
    } catch (_) {}
  }

  // Log audit
  await logAdminAction(db, adminId, 'create', 'question', data.id, null, questionData, `Création question: "${enonce.substring(0, 50)}..."`);

  return c.json({ success: true, question: data, question_id: data.id, serie_id: serieId });
});

// GET /api/admin-cms/questions/:id — Détail d'une question
adminCms.get('/questions/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const db = getDB(c.env);
  const { data, error } = await db.from('questions')
    .select('*, matieres(nom, code)')
    .eq('id', id).single();
  if (error) return c.json({ error: error.message }, 404);
  return c.json({ success: true, question: data });
});

// PUT /api/admin-cms/questions/:id — Modifier une question
adminCms.put('/questions/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const adminId = (c as any).get('adminId') as string;
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps invalide.' }, 400);

  const db = getDB(c.env);

  // Récupérer ancienne version
  const { data: oldQ } = await db.from('questions').select('*').eq('id', id).single();
  if (!oldQ) return c.json({ error: 'Question introuvable.' }, 404);

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
  } catch (_) {}

  const updateData: Record<string, unknown> = {
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
    if (field in body) updateData[field] = body[field];
  }

  const { data, error } = await db.from('questions').update(updateData).eq('id', id).select().single();
  if (error) return c.json({ error: error.message }, 500);

  await logAdminAction(db, adminId, 'edit', 'question', id, oldQ, updateData, `Modification question #${id}`);

  return c.json({ success: true, question: data, updated_at: updateData['updated_at'] });
});

// DELETE /api/admin-cms/questions/:id — Supprimer (soft delete via published=false ou hard delete)
adminCms.delete('/questions/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const adminId = (c as any).get('adminId') as string;
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
  if (error) return c.json({ error: error.message }, 500);

  await logAdminAction(db, adminId, 'delete', 'question', id, oldQ, null, `Question supprimée: ${id}`);
  return c.json({ success: true, message: 'Question supprimée définitivement.' });
});

// POST /api/admin-cms/questions/:id/duplicate — Dupliquer
adminCms.post('/questions/:id/duplicate', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const adminId = (c as any).get('adminId') as string;
  const db = getDB(c.env);

  const { data: original } = await db.from('questions').select('*').eq('id', id).single();
  if (!original) return c.json({ error: 'Question introuvable.' }, 404);

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
  if (error) return c.json({ error: error.message }, 500);

  await logAdminAction(db, adminId, 'duplicate', 'question', data.id, { original_id: id }, null, `Duplication de question #${id}`);

  return c.json({ success: true, new_question_id: data.id, question: data });
});

// ═══════════════════════════════════════════════════════════════
// IMPORT EN MASSE (CSV/JSON)
// ═══════════════════════════════════════════════════════════════

// POST /api/admin-cms/questions/validate-bulk — Valider avant import
adminCms.post('/questions/validate-bulk', requireAdmin, async (c) => {
  const adminId = (c as any).get('adminId') as string;
  const db = getDB(c.env);

  let questions: any[] = [];
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
    } else if (contentType.includes('multipart/form-data')) {
      // Fichier uploadé
      const formData = await c.req.formData();
      const file = formData.get('file') as File | null;
      if (!file) return c.json({ error: 'Fichier requis.' }, 400);

      filename = file.name;
      const text = await file.text();

      if (file.name.endsWith('.json') || contentType.includes('json')) {
        fileFormat = 'json';
        const parsed = JSON.parse(text);
        questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
      } else if (file.name.endsWith('.md') || file.name.endsWith('.txt') || file.name.endsWith('.markdown')) {
        fileFormat = 'md';
        questions = parseMdOrTxt(text);
      } else {
        // CSV parsing
        fileFormat = 'csv';
        questions = parseCSV(text);
      }
    } else {
      // Texte brut
      const text = await c.req.text();
      try {
        const parsed = JSON.parse(text);
        questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
        fileFormat = 'json';
      } catch {
        // Essayer MD/TXT puis CSV
        const mdResult = parseMdOrTxt(text);
        if (mdResult.length > 0) {
          questions = mdResult;
          fileFormat = 'md';
        } else {
          questions = parseCSV(text);
          fileFormat = 'csv';
        }
      }
    }
  } catch (e: any) {
    return c.json({ error: `Erreur parsing: ${e.message}` }, 400);
  }

  if (!questions.length) return c.json({ error: 'Aucune question trouvée dans le fichier.' }, 400);

  // Validation
  const preview: any[] = [];
  const errors: any[] = [];
  let validCount = 0;

  for (let i = 0; i < questions.length; i++) {
    const q = questions[i];
    const lineErrors: string[] = [];

    const enonce = q.enonce ?? q.question ?? q.Question ?? '';
    const optA = q.option_a ?? q.A ?? q.a ?? '';
    const optB = q.option_b ?? q.B ?? q.b ?? '';
    const bonneRep = q.bonne_reponse ?? q.reponse ?? q.correct ?? '';

    if (!enonce?.trim()) lineErrors.push('Énoncé vide');
    if (!optA?.trim()) lineErrors.push('Option A vide');
    if (!optB?.trim()) lineErrors.push('Option B vide');
    if (!bonneRep?.trim()) lineErrors.push('Bonne réponse manquante');
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
    } else {
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
  const adminId = (c as any).get('adminId') as string;
  const db = getDB(c.env);
  const startTime = Date.now();

  let questions: any[] = [];
  let filename = 'upload';
  let fileFormat = 'json';
  let matiereId: string | null = null;

  try {
    const contentType = c.req.header('content-type') ?? '';

    if (contentType.includes('application/json')) {
      const body = await c.req.json();
      questions = Array.isArray(body) ? body : body.questions ?? [];
      matiereId = !Array.isArray(body) ? body.matiere_id : null;
      filename = 'data.json';
      fileFormat = 'json';
    } else if (contentType.includes('multipart/form-data')) {
      const formData = await c.req.formData();
      const file = formData.get('file') as File | null;
      matiereId = formData.get('matiere_id') as string | null;
      if (!file) return c.json({ error: 'Fichier requis.' }, 400);
      filename = file.name;
      const text = await file.text();
      if (file.name.endsWith('.json')) {
        fileFormat = 'json';
        const parsed = JSON.parse(text);
        questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
      } else if (file.name.endsWith('.md') || file.name.endsWith('.txt') || file.name.endsWith('.markdown')) {
        fileFormat = 'md';
        questions = parseMdOrTxt(text);
      } else {
        fileFormat = 'csv';
        questions = parseCSV(text);
      }
    } else {
      const text = await c.req.text();
      try {
        const parsed = JSON.parse(text);
        questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
        fileFormat = 'json';
      } catch {
        const mdResult = parseMdOrTxt(text);
        if (mdResult.length > 0) {
          questions = mdResult;
          fileFormat = 'md';
        } else {
          questions = parseCSV(text);
          fileFormat = 'csv';
        }
      }
    }
  } catch (e: any) {
    return c.json({ error: `Erreur parsing: ${e.message}` }, 400);
  }

  if (!questions.length) return c.json({ error: 'Aucune question à importer.' }, 400);

  // Récupérer numéro max actuel
  const { data: lastQ } = await db.from('questions').select('numero').order('numero', { ascending: false }).limit(1);
  let currentNumero = lastQ?.[0]?.numero ?? 0;

  // Import par batch de 50
  const BATCH_SIZE = 50;
  const importedIds: string[] = [];
  const errors: any[] = [];
  let importedCount = 0;
  let failedCount = 0;

  // ── Cache des séries par matière (pour éviter trop de requêtes) ──────────
  const seriesCacheByMatiere: Record<string, { id: string; numero: number; count: number }> = {};

  async function getOrCreateSerieForBulk(qMatiereId: string): Promise<string | null> {
    if (!qMatiereId) return null;

    // Initialiser le cache pour cette matière si nécessaire
    if (!seriesCacheByMatiere[qMatiereId]) {
      const { data: lastSerie } = await db.from('series_qcm')
        .select('id, numero, nb_questions')
        .eq('matiere_id', qMatiereId)
        .eq('actif', true)
        .order('numero', { ascending: false })
        .limit(1);

      if (lastSerie && lastSerie.length > 0) {
        // Compter les vraies questions de cette série
        const { count: vraiCount } = await db.from('questions')
          .select('*', { count: 'exact', head: true })
          .eq('serie_id', lastSerie[0].id);
        seriesCacheByMatiere[qMatiereId] = {
          id: lastSerie[0].id,
          numero: lastSerie[0].numero ?? 1,
          count: vraiCount ?? 0,
        };
      } else {
        seriesCacheByMatiere[qMatiereId] = { id: '', numero: 0, count: 0 };
      }
    }

    const cache = seriesCacheByMatiere[qMatiereId];

    // Si la série actuelle est pleine (>= 20 questions), en créer une nouvelle
    if (!cache.id || cache.count >= 20) {
      const newNum = cache.numero + 1;
      const { data: matInfo } = await db.from('matieres').select('nom').eq('id', qMatiereId).single();
      const nomSerie = `Série ${String(newNum).padStart(2, '0')} — ${matInfo?.nom ?? 'Matière'}`;

      const { data: newSerie } = await db.from('series_qcm').insert({
        titre: nomSerie,
        matiere_id: qMatiereId,
        numero: newNum,
        nb_questions: 0,
        niveau: 'INTERMEDIAIRE',
        duree_minutes: 20,
        actif: true,
        published: true,
        est_demo: false,
        created_by: adminId,
        created_at: new Date().toISOString(),
      }).select('id, numero').single();

      if (newSerie) {
        seriesCacheByMatiere[qMatiereId] = { id: newSerie.id, numero: newSerie.numero, count: 0 };
      } else {
        return null;
      }
    }

    // Incrémenter le compteur local
    seriesCacheByMatiere[qMatiereId].count++;
    return seriesCacheByMatiere[qMatiereId].id;
  }

  // Log import en cours
  let importLogId: any = null;
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
  } catch (_) {}

  for (let i = 0; i < questions.length; i += BATCH_SIZE) {
    const batch = questions.slice(i, i + BATCH_SIZE);
    const batchData: any[] = [];

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

      // ── Auto-assignation de série (20 questions max par série) ──
      const serieId = qMatiereId ? await getOrCreateSerieForBulk(qMatiereId) : null;
      const numero_serie = seriesCacheByMatiere[qMatiereId]?.numero ?? Math.ceil(currentNumero / 20);

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
        serie_id: serieId,
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
      } else {
        importedCount += inserted?.length ?? 0;
        importedIds.push(...(inserted?.map((q: any) => q.id) ?? []));
      }
    }
  }

  // ── Mettre à jour nb_questions pour toutes les séries touchées ──
  for (const [qMatiereId, serieCache] of Object.entries(seriesCacheByMatiere)) {
    if (serieCache.id) {
      try {
        const { count: newNb } = await db.from('questions')
          .select('*', { count: 'exact', head: true })
          .eq('serie_id', serieCache.id);
        await db.from('series_qcm').update({ nb_questions: newNb ?? 0 }).eq('id', serieCache.id);
      } catch (_) {}
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

  await logAdminAction(
    db, adminId, 'bulk_import', 'question', importLogId?.toString() ?? '0',
    null, { imported: importedCount, failed: failedCount },
    `Import en masse: ${importedCount}/${questions.length} questions importées`
  );

  return c.json({
    success: importedCount > 0,
    imported: importedCount,
    failed: failedCount,
    total: questions.length,
    import_id: importLogId,
    duration_seconds: duration,
    created_questions: importedIds.slice(0, 50),
    errors: errors.slice(0, 10),
    series_created: Object.keys(seriesCacheByMatiere).length,
  });
});

// GET /api/admin-cms/questions/import-history — Historique des imports
adminCms.get('/questions/import-history', requireAdmin, async (c) => {
  const db = getDB(c.env);
  const { data, error } = await db.from('bulk_import_logs')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(20);
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, imports: data ?? [] });
});

// DELETE /api/admin-cms/questions/import/:importId — Annuler un import
adminCms.delete('/questions/import/:importId', requireAdmin, async (c) => {
  const importId = c.req.param('importId');
  const adminId = (c as any).get('adminId') as string;
  const db = getDB(c.env);

  const { data: log } = await db.from('bulk_import_logs').select('*').eq('id', importId).single();
  if (!log) return c.json({ error: 'Import introuvable.' }, 404);

  let deleted = 0;
  if (log.imported_question_ids) {
    try {
      const ids = JSON.parse(log.imported_question_ids as string);
      if (Array.isArray(ids) && ids.length > 0) {
        for (let i = 0; i < ids.length; i += 100) {
          const batch = ids.slice(i, i + 100);
          const { error } = await db.from('questions').delete().in('id', batch);
          if (!error) deleted += batch.length;
        }
      }
    } catch (_) {}
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

  if (qMatiereId) query = query.eq('matiere_id', qMatiereId) as typeof query;

  const { data, error } = await query.order('numero', { ascending: true }).limit(500);
  if (error) return c.json({ error: error.message }, 500);

  return c.json({ success: true, series: data ?? [] });
});

// POST /api/admin-cms/series — Créer une série
adminCms.post('/series', requireAdmin, async (c) => {
  const adminId = (c as any).get('adminId') as string;
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps invalide.' }, 400);

  const { titre, matiere_id, numero, question_ids, niveau, duree_minutes } = body as any;
  if (!titre || !matiere_id) return c.json({ error: 'Titre et matière requis.' }, 400);

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

  if (error) return c.json({ error: error.message }, 500);

  // Assigner les questions à la série créée
  if (Array.isArray(question_ids) && question_ids.length > 0) {
    await db.from('questions').update({ serie_id: data.id }).in('id', question_ids);
  }

  await logAdminAction(db, adminId, 'create', 'serie', data.id, null, data, `Série créée: "${titre}"`);
  return c.json({ success: true, serie: data, series_id: data.id });
});

// POST /api/admin-cms/series/auto-generate — Créer série automatique
adminCms.post('/series/auto-generate', requireAdmin, async (c) => {
  const adminId = (c as any).get('adminId') as string;
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps invalide.' }, 400);

  const { matiere_id, count = 20 } = body as any;
  if (!matiere_id) return c.json({ error: 'matiere_id requis.' }, 400);

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
    if (!all?.length) return c.json({ error: 'Aucune question disponible pour cette matière.' }, 400);
    available?.push(...(all ?? []));
  }

  const questionIds = (available ?? []).map((q: any) => q.id);

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

  if (error) return c.json({ error: error.message }, 500);

  // Assigner les questions
  await db.from('questions').update({ serie_id: data.id }).in('id', questionIds);

  return c.json({ success: true, serie: data, series_id: data.id, questions_used: questionIds.length });
});


// PUT /api/admin-cms/series/:id — Modifier une série
adminCms.put('/series/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const adminId = (c as any).get('adminId') as string;
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps invalide.' }, 400);

  const db = getDB(c.env);
  const { data: old } = await db.from('series_qcm').select('*').eq('id', id).single();

  const updateData: Record<string, unknown> = {
    updated_at: new Date().toISOString(),
    updated_by: adminId,
  };

  if ('titre' in body) updateData['titre'] = body['titre'];
  if ('numero' in body) updateData['numero'] = body['numero'];
  if ('niveau' in body) updateData['niveau'] = body['niveau'];
  if ('actif' in body) updateData['actif'] = body['actif'];
  if ('published' in body) updateData['published'] = body['published'];

  // Mise à jour des questions incluses
  const question_ids = (body as any).question_ids as string[] | undefined;
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
  if (error) return c.json({ error: error.message }, 500);

  await logAdminAction(db, adminId, 'edit', 'serie', id, old, updateData, `Série modifiée: ${id}`);
  return c.json({ success: true, serie: data });
});

// DELETE /api/admin-cms/series/:id — Supprimer une série
adminCms.delete('/series/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const adminId = (c as any).get('adminId') as string;
  const orphan_action = c.req.query('orphan') ?? 'keep'; // 'keep' ou 'delete'
  const db = getDB(c.env);

  // Gérer les questions orphelines
  if (orphan_action === 'delete') {
    await db.from('questions').delete().eq('serie_id', id);
  } else {
    await db.from('questions').update({ serie_id: null }).eq('serie_id', id);
  }

  const { error } = await db.from('series_qcm').delete().eq('id', id);
  if (error) return c.json({ error: error.message }, 500);

  await logAdminAction(db, adminId, 'delete', 'serie', id, null, null, `Série supprimée: ${id}`);
  return c.json({ success: true, message: 'Série supprimée.' });
});

// POST /api/admin-cms/series/:id/duplicate — Dupliquer une série
adminCms.post('/series/:id/duplicate', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const adminId = (c as any).get('adminId') as string;
  const db = getDB(c.env);

  const { data: original } = await db.from('series_qcm').select('*').eq('id', id).single();
  if (!original) return c.json({ error: 'Série introuvable.' }, 404);

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

  if (error) return c.json({ error: error.message }, 500);

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
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, simulations: data ?? [] });
});

// POST /api/admin-cms/simulations — Créer une simulation ou examen type
adminCms.post('/simulations', requireAdmin, async (c) => {
  const adminId = (c as any).get('adminId') as string;
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps invalide.' }, 400);

  const {
    titre, description, duree_minutes, score_max,
    questions: questionConfig, ordre_questions, show_corrections, show_score_after,
    type: simType,
  } = body as any;

  if (!titre) return c.json({ error: 'Titre requis.' }, 400);

  const db = getDB(c.env);
  let questionIds: string[] = [];

  // Si config par matière fournie : sélectionner les questions
  if (Array.isArray(questionConfig)) {
    for (const config of questionConfig) {
      if (config.matiere_id && config.count > 0) {
        const { data: qs } = await db.from('questions')
          .select('id').eq('matiere_id', config.matiere_id)
          .eq('published', true).limit(config.count * 3);

        const available = qs ?? [];
        const shuffled = available.sort(() => Math.random() - 0.5).slice(0, config.count);
        questionIds.push(...shuffled.map((q: any) => q.id));
      } else if (Array.isArray(config.question_ids)) {
        questionIds.push(...config.question_ids);
      }
    }
  } else if (Array.isArray((body as any).question_ids)) {
    questionIds = (body as any).question_ids;
  }

  // Normaliser le type : 'simulation' (examen blanc) ou 'examen_type' (vrai sujet)
  const typeNorm = simType === 'examen_type' ? 'examen_type' : 'simulation';

  const { data, error } = await db.from('simulations_examens').insert({
    titre: titre.trim(),
    description: description?.trim() ?? null,
    duree_minutes: duree_minutes ?? 90,
    score_max: score_max ?? questionIds.length ?? 50,
    question_ids: JSON.stringify(questionIds),
    created_by: adminId,
    published: false, // Toujours créer en brouillon, l'admin publie manuellement
    ordre_questions: ordre_questions ?? (typeNorm === 'simulation' ? 'sequential' : 'sequential'),
    show_corrections: show_corrections !== false,
    show_score_after: show_score_after !== false,
    type: typeNorm,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  }).select().single();

  if (error) return c.json({ error: error.message }, 500);

  await logAdminAction(db, adminId, 'create', 'simulation', data.id.toString(), null,
    { titre, total_questions: questionIds.length, type: typeNorm },
    `${typeNorm === 'examen_type' ? 'Examen Type' : 'Simulation'} créé(e): "${titre}"`
  );

  return c.json({
    success: true, simulation: data, simulation_id: data.id,
    total_questions: questionIds.length, question_ids: questionIds,
    type: typeNorm,
  });
});

// PUT /api/admin-cms/simulations/:id — Modifier
adminCms.put('/simulations/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const adminId = (c as any).get('adminId') as string;
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps invalide.' }, 400);

  const db = getDB(c.env);
  const updateData: Record<string, unknown> = {
    updated_at: new Date().toISOString(),
  };

  const allowedFields = ['titre', 'description', 'duree_minutes', 'score_max', 'published', 'ordre_questions', 'show_corrections', 'show_score_after'];
  for (const field of allowedFields) {
    if (field in body) updateData[field] = body[field];
  }

  if ((body as any).question_ids) {
    updateData['question_ids'] = JSON.stringify((body as any).question_ids);
  }

  const { data, error } = await db.from('simulations_examens').update(updateData).eq('id', id).select().single();
  if (error) return c.json({ error: error.message }, 500);

  return c.json({ success: true, simulation: data });
});

// DELETE /api/admin-cms/simulations/:id — Supprimer
adminCms.delete('/simulations/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const adminId = (c as any).get('adminId') as string;
  const db = getDB(c.env);
  const { error } = await db.from('simulations_examens').delete().eq('id', id);
  if (error) return c.json({ error: error.message }, 500);
  await logAdminAction(db, adminId, 'delete', 'simulation', id, null, null, `Simulation supprimée: ${id}`);
  return c.json({ success: true, message: 'Simulation supprimée.' });
});

// GET /api/admin-cms/simulations/:id — Détail
adminCms.get('/simulations/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const db = getDB(c.env);
  const { data, error } = await db.from('simulations_examens').select('*').eq('id', id).single();
  if (error) return c.json({ error: error.message }, 404);

  // Récupérer les questions incluses
  let questions: any[] = [];
  try {
    const qIds = JSON.parse(data.question_ids as string ?? '[]');
    if (qIds.length > 0) {
      const { data: qs } = await db.from('questions')
        .select('id, enonce, difficulte, matiere_id, matieres(nom)')
        .in('id', qIds).limit(200);
      questions = qs ?? [];
    }
  } catch (_) {}

  return c.json({ success: true, simulation: data, questions });
});

// ═══════════════════════════════════════════════════════════════
// ANALYTICS & SIGNALEMENTS
// ═══════════════════════════════════════════════════════════════

// GET /api/admin-cms/analytics/dashboard — Stats globales
adminCms.get('/analytics/dashboard', requireAdmin, async (c) => {
  const db = getDB(c.env);

  const [
    { count: totalUsers },
    { count: totalQuestions },
    { count: totalSimulationsPlayed },
    { count: totalFlags },
    { count: pendingFlags },
    { count: totalSimulationsExamens },
  ] = await Promise.all([
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
      avgScore = Math.round(sessions.reduce((sum: number, s: any) => sum + (s.score_pourcentage ?? 0), 0) / sessions.length);
    }
  } catch (_) {}

  // Matières populaires
  let matiereStats: any[] = [];
  try {
    const { data: mats } = await db.from('matieres').select('id, nom, code').limit(20);
    for (const mat of (mats ?? []).slice(0, 5)) {
      const { count: nb } = await db.from('questions')
        .select('*', { count: 'exact', head: true })
        .eq('matiere_id', mat.id).eq('published', true);
      matiereStats.push({ ...mat, nb_questions: nb ?? 0 });
    }
    matiereStats.sort((a: any, b: any) => b.nb_questions - a.nb_questions);
  } catch (_) {}

  // Signalements récents
  let recentFlags: any[] = [];
  try {
    const { data: flags } = await db.from('question_flags')
      .select('id, question_id, reason, created_at, status')
      .eq('status', 'new').order('created_at', { ascending: false }).limit(5);
    recentFlags = flags ?? [];
  } catch (_) {}

  // Imports récents
  let recentImports: any[] = [];
  try {
    const { data: imports } = await db.from('bulk_import_logs')
      .select('id, filename, imported_count, status, created_at')
      .order('created_at', { ascending: false }).limit(5);
    recentImports = imports ?? [];
  } catch (_) {}

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
    query = query.eq('status', status) as typeof query;
  }

  const { data, error } = await query
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) return c.json({ error: error.message }, 500);

  // Enrichir avec les données de questions (si question_id présent)
  const flags = data ?? [];
  const enriched = await Promise.all(flags.map(async (flag: any) => {
    if (!flag.question_id) return flag;
    try {
      const { data: q } = await db.from('questions')
        .select('enonce, matiere_id')
        .eq('id', flag.question_id)
        .single();
      return { ...flag, question: q ?? null };
    } catch (_) {
      return { ...flag, question: null };
    }
  }));

  return c.json({ success: true, flags: enriched });
});

// PUT /api/admin-cms/flags/:id — Résoudre un signalement
adminCms.put('/flags/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const adminId = (c as any).get('adminId') as string;
  const body = await c.req.json().catch(() => ({})) as Record<string, unknown>;
  const db = getDB(c.env);

  const { data, error } = await db.from('question_flags').update({
    status: body['status'] ?? 'resolved',
    admin_response: body['admin_note'] ?? body['admin_response'],
    resolved_by: adminId,
    resolved_at: new Date().toISOString(),
  }).eq('id', id).select().single();

  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, flag: data });
});

// POST /api/admin-cms/flags — Créer un signalement (depuis l'app user)
adminCms.post('/flags', async (c) => {
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps invalide.' }, 400);

  const { question_id, user_id, reason, details } = body as any;
  if (!question_id || !user_id || !reason) {
    return c.json({ error: 'question_id, user_id et reason requis.' }, 400);
  }

  const db = getDB(c.env);
  const { data, error } = await db.from('question_flags').insert({
    question_id, user_id, reason, details: details ?? null,
    status: 'new', created_at: new Date().toISOString(),
  }).select().single();

  if (error) return c.json({ error: error.message }, 500);
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

  if (action) query = query.eq('action', action) as typeof query;
  if (resourceType) query = query.eq('resource_type', resourceType) as typeof query;

  const { data, error } = await query
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, logs: data ?? [] });
});

// GET /api/admin-cms/questions/:id/analytics — Stats d'une question
adminCms.get('/questions/:id/analytics', requireAdmin, async (c) => {
  const questionId = c.req.param('id');
  const db = getDB(c.env);

  const { data: q } = await db.from('questions')
    .select('*, matieres(nom)').eq('id', questionId).single();

  if (!q) return c.json({ error: 'Question introuvable.' }, 404);

  // Signalements
  let flagCount = 0;
  let flags: any[] = [];
  try {
    const { count } = await db.from('question_flags')
      .select('*', { count: 'exact', head: true }).eq('question_id', questionId);
    flagCount = count ?? 0;

    const { data: fData } = await db.from('question_flags')
      .select('user_id, reason, created_at, status')
      .eq('question_id', questionId).limit(10);
    flags = fData ?? [];
  } catch (_) {}

  return c.json({
    success: true,
    question_id: questionId,
    question: q.enonce,
    matiere: (q as any).matieres?.nom,
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
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, matieres: data ?? [] });
});

// ═══════════════════════════════════════════════════════════════
// FONCTION UTILITAIRE : Parser CSV
// ═══════════════════════════════════════════════════════════════
function parseCSV(text: string): any[] {
  const lines = text.split('\n').filter(l => l.trim());
  if (lines.length < 2) return [];

  // Première ligne = en-têtes
  const headers = lines[0].split(';').map(h =>
    h.trim().toLowerCase().replace(/['"]/g, '')
      .replace('question', 'enonce')
      .replace('réponse correcte', 'bonne_reponse')
      .replace('reponse correcte', 'bonne_reponse')
      .replace('correct', 'bonne_reponse')
      .replace('proposition a', 'option_a')
      .replace('proposition b', 'option_b')
      .replace('proposition c', 'option_c')
      .replace('proposition d', 'option_d')
      .replace('proposition e', 'option_e')
  );

  const results: any[] = [];
  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(';').map(v => v.trim().replace(/^["']|["']$/g, ''));
    const obj: Record<string, string> = {};
    headers.forEach((h, idx) => {
      obj[h] = values[idx] ?? '';
    });

    // Mapping alternatif : colonnes A, B, C, D, E
    if (!obj['option_a'] && obj['a']) obj['option_a'] = obj['a'];
    if (!obj['option_b'] && obj['b']) obj['option_b'] = obj['b'];
    if (!obj['option_c'] && obj['c']) obj['option_c'] = obj['c'];
    if (!obj['option_d'] && obj['d']) obj['option_d'] = obj['d'];
    if (!obj['option_e'] && obj['e']) obj['option_e'] = obj['e'];

    results.push(obj);
  }

  return results;
}

// ═══════════════════════════════════════════════════════════════
// FONCTION UTILITAIRE : Parser Markdown / TXT
// Formats supportés :
//   ## Question : Quelle est la capitale ?
//   A) Bobo-Dioulasso
//   B) Ouagadougou  ✓ ou * ou (bonne) ou (B)
//   C) Koudougou
//   D) Banfora
//   Explication: ...
// OU format numéroté:
//   1. Quelle est la capitale ?
//   a) Bobo   b) Ouaga*  c) Koudo  d) Banfora
// ═══════════════════════════════════════════════════════════════
function parseMdOrTxt(text: string): any[] {
  const results: any[] = [];
  // Normaliser les fins de ligne
  const normalized = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
  const lines = normalized.split('\n');

  let currentQ: any = null;
  let currentOptions: Record<string, string> = {};
  let currentBonne = '';
  let currentExplication = '';
  let optionLetters = ['A', 'B', 'C', 'D', 'E'];

  function saveQuestion() {
    if (currentQ && currentOptions['A'] && currentOptions['B'] && currentBonne) {
      results.push({
        enonce: currentQ.trim(),
        option_a: currentOptions['A'] || '',
        option_b: currentOptions['B'] || '',
        option_c: currentOptions['C'] || null,
        option_d: currentOptions['D'] || null,
        option_e: currentOptions['E'] || null,
        bonne_reponse: currentBonne.toUpperCase(),
        explication: currentExplication.trim(),
        difficulte: 'MOYEN',
      });
    }
    currentQ = null;
    currentOptions = {};
    currentBonne = '';
    currentExplication = '';
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    // Détection d'une nouvelle question (## ou Q1. ou 1. ou Question :)
    const questionMatch =
      line.match(/^#{1,3}\s*(?:Question\s*\d*\s*:?\s*)?(.+)$/) ||
      line.match(/^(?:Q|Question)\s*\d+[\.\:\)]\s*(.+)$/) ||
      line.match(/^\d+[\.\)]\s{1,4}(.{10,})$/) ||
      line.match(/^[A-Z].{15,}\?$/);

    if (questionMatch && !line.match(/^[A-Ea-e][\.\)\-]\s/)) {
      // Sauvegarder la question précédente
      if (currentQ) saveQuestion();

      const qText = questionMatch[1] || line;
      // Ne pas traiter comme question si c'est une option
      if (!qText.match(/^[A-Ea-e][\.\)\-\s]/)) {
        currentQ = qText.replace(/\?$/, '?').trim();
      }
      continue;
    }

    // Détection d'une option (A) texte, a) texte, A. texte, A- texte)
    // avec marqueur de bonne réponse : *, ✓, ✔, (bonne), (correct)
    const optionMatch = line.match(/^([A-Ea-e])[\.\)\-\s]\s*(.+)$/);
    if (optionMatch && currentQ) {
      const letter = optionMatch[1].toUpperCase();
      let optText = optionMatch[2].trim();

      // Vérifier si c'est la bonne réponse
      const isBonne =
        optText.endsWith('*') ||
        optText.endsWith('✓') ||
        optText.endsWith('✔') ||
        optText.toLowerCase().includes('(bonne)') ||
        optText.toLowerCase().includes('(correct)') ||
        optText.toLowerCase().includes('(réponse)') ||
        optText.toLowerCase().includes('(answer)');

      // Nettoyer les marqueurs
      optText = optText
        .replace(/\*$/, '')
        .replace(/✓$/, '')
        .replace(/✔$/, '')
        .replace(/\(bonne\)/i, '')
        .replace(/\(correct\)/i, '')
        .replace(/\(réponse\)/i, '')
        .replace(/\(answer\)/i, '')
        .trim();

      currentOptions[letter] = optText;
      if (isBonne) currentBonne = letter;
      continue;
    }

    // Détection de la bonne réponse explicite
    const bonneMatch = line.match(/^(?:Bonne\s*[Rr]éponse|[Rr]éponse\s*[Cc]orrecte|[Cc]orrect|[Rr]éponse|Answer)\s*:?\s*([A-Ea-e])/i);
    if (bonneMatch && currentQ) {
      currentBonne = bonneMatch[1].toUpperCase();
      continue;
    }

    // Détection de l'explication
    const explMatch = line.match(/^(?:Explication|Explanation|Note|Commentaire)\s*:?\s*(.+)$/i);
    if (explMatch && currentQ) {
      currentExplication = explMatch[1].trim();
      continue;
    }
  }

  // Sauvegarder la dernière question
  if (currentQ) saveQuestion();

  return results;
}

// ═══════════════════════════════════════════════════════════════
// IMPORT EXAMENS — Routes dédiées
// ═══════════════════════════════════════════════════════════════

// POST /api/admin-cms/examens/bulk-import — Importer des questions d'examen (simulation ou examen_type)
adminCms.post('/examens/bulk-import', requireAdmin, async (c) => {
  const adminId = (c as any).get('adminId') as string;
  const db = getDB(c.env);
  const startTime = Date.now();

  let questions: any[] = [];
  let simulationId: string | null = null;
  let titre = '';
  let filename = 'upload';
  let simType = 'simulation'; // 'simulation' ou 'examen_type'

  try {
    const contentType = c.req.header('content-type') ?? '';

    if (contentType.includes('application/json')) {
      const body = await c.req.json();
      // Support pour questions_text (MD/TXT envoyé en JSON)
      if (body.questions_text && typeof body.questions_text === 'string') {
        const fmt = body.format ?? 'md';
        if (fmt === 'md' || fmt === 'txt') {
          questions = parseMdOrTxt(body.questions_text);
        } else {
          try { questions = JSON.parse(body.questions_text); } catch { questions = parseCSV(body.questions_text); }
        }
      } else {
        questions = Array.isArray(body) ? body : body.questions ?? [];
      }
      simulationId = !Array.isArray(body) ? body.simulation_id ?? null : null;
      titre = !Array.isArray(body) ? body.titre ?? '' : '';
      simType = !Array.isArray(body) ? (body.type ?? 'simulation') : 'simulation';
      filename = 'data.json';
    } else if (contentType.includes('multipart/form-data')) {
      const formData = await c.req.formData();
      const file = formData.get('file') as File | null;
      simulationId = formData.get('simulation_id') as string | null;
      titre = formData.get('titre') as string ?? '';
      simType = formData.get('type') as string ?? 'simulation';
      if (!file) return c.json({ error: 'Fichier requis.' }, 400);
      filename = file.name;
      const text = await file.text();
      if (file.name.endsWith('.json')) {
        const parsed = JSON.parse(text);
        questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
      } else if (file.name.endsWith('.md') || file.name.endsWith('.txt') || file.name.endsWith('.markdown')) {
        questions = parseMdOrTxt(text);
      } else {
        questions = parseCSV(text);
      }
    } else {
      const text = await c.req.text();
      try {
        const parsed = JSON.parse(text);
        questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
      } catch {
        questions = parseMdOrTxt(text);
      }
    }
  } catch (e: any) {
    return c.json({ error: `Erreur parsing: ${e.message}` }, 400);
  }

  if (!questions.length) return c.json({ error: 'Aucune question trouvée.' }, 400);

  // Normaliser le type
  const typeNorm = simType === 'examen_type' ? 'examen_type' : 'simulation';
  const typeLabel = typeNorm === 'examen_type' ? 'Examen Type' : 'Simulation';

  // Créer ou récupérer la simulation/examen_type
  let simId = simulationId;
  if (!simId) {
    const simTitre = titre || `${typeLabel} — Import ${new Date().toLocaleDateString('fr-FR')} — ${questions.length} questions`;
    const { data: newSim } = await db.from('simulations_examens').insert({
      titre: simTitre,
      description: `Import automatique · ${typeLabel} · ${questions.length} questions`,
      duree_minutes: typeNorm === 'simulation' ? 90 : 90,
      score_max: questions.length,
      published: false, // Brouillon — publier manuellement
      ordre_questions: 'sequential', // Pour les examens : ordre original des questions
      show_corrections: true,
      show_score_after: true,
      type: typeNorm,
      created_by: adminId,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }).select('id').single();
    simId = newSim?.id?.toString() ?? null;
  }

  // Importer les questions liées à la simulation
  let importedCount = 0;
  let failedCount = 0;
  const BATCH_SIZE = 50;

  const { data: lastQ } = await db.from('questions').select('numero').order('numero', { ascending: false }).limit(1);
  let currentNumero = lastQ?.[0]?.numero ?? 0;

  for (let i = 0; i < questions.length; i += BATCH_SIZE) {
    const batch = questions.slice(i, i + BATCH_SIZE);
    const batchData: any[] = [];

    for (const q of batch) {
      const enonce = q.enonce ?? q.question ?? q.Question ?? '';
      const optA = q.option_a ?? q.A ?? q.a ?? '';
      const optB = q.option_b ?? q.B ?? q.b ?? '';
      const optC = q.option_c ?? q.C ?? q.c ?? null;
      const optD = q.option_d ?? q.D ?? q.d ?? null;
      const optE = q.option_e ?? q.E ?? q.e ?? null;
      const bonneRep = (q.bonne_reponse ?? q.reponse ?? q.correct ?? 'A').toUpperCase();
      const explication = q.explication ?? q.explanation ?? '';

      if (!enonce?.trim() || !optA?.trim() || !optB?.trim()) {
        failedCount++;
        continue;
      }

      currentNumero++;
      batchData.push({
        enonce: enonce.trim(),
        option_a: optA.trim(),
        option_b: optB.trim(),
        option_c: optC?.trim() ?? null,
        option_d: optD?.trim() ?? null,
        option_e: optE?.trim() ?? null,
        bonne_reponse: bonneRep,
        explication: explication.trim(),
        difficulte: 'MOYEN',
        type: 'EXAMEN',
        simulation_id: simId,
        published: true,
        version: 1,
        numero: currentNumero,
        created_by: adminId,
      });
    }

    if (batchData.length > 0) {
      const { data: inserted, error } = await db.from('questions').insert(batchData).select('id');
      if (error) {
        failedCount += batchData.length;
      } else {
        importedCount += inserted?.length ?? 0;
        // Lier les questions à la simulation
        if (simId && inserted && inserted.length > 0) {
          const questionIds = inserted.map((q: any) => q.id);
          // Mettre à jour la simulation avec les IDs des questions
          await db.from('simulations_examens')
            .update({ questions: JSON.stringify(questionIds), score_max: importedCount })
            .eq('id', simId);
        }
      }
    }
  }

  const duration = Math.round((Date.now() - startTime) / 1000);

  await logAdminAction(
    db, adminId, 'bulk_import_examen', 'simulation', simId ?? '0',
    null, { imported: importedCount, simulation_id: simId },
    `Import examen: ${importedCount} questions`
  );

  return c.json({
    success: importedCount > 0,
    imported: importedCount,
    failed: failedCount,
    total: questions.length,
    simulation_id: simId,
    duration_seconds: duration,
    message: `${importedCount} questions d'examen importées. Simulation ID: ${simId}`,
  });
});

// GET /api/admin-cms/examens — Lister les examens/simulations avec stats questions
adminCms.get('/examens', requireAdmin, async (c) => {
  const db = getDB(c.env);
  const { data, error } = await db.from('simulations_examens')
    .select('*')
    .order('created_at', { ascending: false });
  if (error) return c.json({ error: error.message }, 500);

  // Compter les questions d'examen pour chaque simulation
  const enriched = await Promise.all((data ?? []).map(async (sim: any) => {
    const { count } = await db.from('questions')
      .select('*', { count: 'exact', head: true })
      .eq('simulation_id', sim.id)
      .eq('type', 'EXAMEN');
    return { ...sim, nb_questions_examen: count ?? 0 };
  }));

  return c.json({ success: true, examens: enriched });
});

// ═══════════════════════════════════════════════════════════════
// HARMONISATION DES SÉRIES
// Restructure les séries pour avoir exactement 20 questions
// (ou 50 pour les simulations). Évite les séries partielles.
// ═══════════════════════════════════════════════════════════════

// POST /api/admin-cms/series/harmonize — Harmoniser les séries d'une matière
adminCms.post('/series/harmonize', requireAdmin, async (c) => {
  const adminId = (c as any).get('adminId') as string;
  const body = await c.req.json().catch(() => ({})) as Record<string, unknown>;
  const { matiere_id, questions_per_serie = 20, dry_run = false } = body as any;

  const db = getDB(c.env);
  const results: any[] = [];

  // Récupérer les matières à traiter
  let matiereIds: string[] = [];
  if (matiere_id) {
    matiereIds = [matiere_id];
  } else {
    const { data: mats } = await db.from('matieres').select('id, nom').order('ordre');
    matiereIds = (mats ?? []).map((m: any) => m.id);
  }

  for (const mid of matiereIds) {
    // Récupérer toutes les questions de cette matière (dans l'ordre de création)
    const { data: allQuestions } = await db.from('questions')
      .select('id, serie_id, numero')
      .eq('matiere_id', mid)
      .eq('published', true)
      .order('numero', { ascending: true });

    if (!allQuestions || allQuestions.length === 0) continue;

    const { data: matInfo } = await db.from('matieres').select('nom').eq('id', mid).single();
    const matNom = matInfo?.nom ?? 'Matière';

    // Récupérer les séries existantes de cette matière
    const { data: existingSeries } = await db.from('series_qcm')
      .select('id, numero, nb_questions')
      .eq('matiere_id', mid)
      .eq('actif', true)
      .order('numero', { ascending: true });

    const totalQ = allQuestions.length;
    const nbSeriesNeeded = Math.ceil(totalQ / questions_per_serie);

    // Calculer combien de séries existent déjà et lesquelles sont complètes
    const seriesExist = existingSeries ?? [];
    const seriesCompletes = seriesExist.filter((s: any) => s.nb_questions >= questions_per_serie);
    const seriesIncompletes = seriesExist.filter((s: any) => s.nb_questions < questions_per_serie);

    results.push({
      matiere_id: mid,
      matiere: matNom,
      total_questions: totalQ,
      series_actuelles: seriesExist.length,
      series_completes: seriesCompletes.length,
      series_incompletes: seriesIncompletes.length,
      series_necessaires: nbSeriesNeeded,
    });

    if (dry_run) continue;

    // Réorganiser : assigner les questions aux séries dans l'ordre
    // Étape 1 : désassigner toutes les questions (series_id = null)
    const questionIds = allQuestions.map((q: any) => q.id);

    // Traiter par batch de 500
    for (let i = 0; i < questionIds.length; i += 500) {
      await db.from('questions')
        .update({ serie_id: null })
        .in('id', questionIds.slice(i, i + 500));
    }

    // Étape 2 : supprimer les séries incomplètes (on va les recréer proprement)
    if (seriesIncompletes.length > 0) {
      const incompleteIds = seriesIncompletes.map((s: any) => s.id);
      await db.from('series_qcm').delete().in('id', incompleteIds);
    }

    // Étape 3 : réassigner les questions aux séries en paquets de 20
    let serieIndex = 0;
    const seriesIds: string[] = seriesCompletes.map((s: any) => s.id);

    for (let i = 0; i < allQuestions.length; i += questions_per_serie) {
      const chunk = allQuestions.slice(i, i + questions_per_serie);
      let serieId: string;

      if (serieIndex < seriesIds.length) {
        // Réutiliser une série existante complète
        serieId = seriesIds[serieIndex];
      } else {
        // Créer une nouvelle série
        const newNum = (seriesCompletes[seriesCompletes.length - 1]?.numero ?? 0) + (serieIndex - seriesCompletes.length + 1);
        const { data: newSerie } = await db.from('series_qcm').insert({
          titre: `Série ${String(newNum).padStart(2, '0')} — ${matNom}`,
          matiere_id: mid,
          numero: newNum,
          nb_questions: 0,
          niveau: 'INTERMEDIAIRE',
          duree_minutes: 20,
          actif: true,
          published: true,
          est_demo: false,
          created_by: adminId,
          created_at: new Date().toISOString(),
        }).select('id').single();
        serieId = newSerie?.id ?? '';
        seriesIds.push(serieId);
      }

      if (!serieId) { serieIndex++; continue; }

      // Assigner les questions à cette série
      const chunkIds = chunk.map((q: any) => q.id);
      for (let j = 0; j < chunkIds.length; j += 200) {
        await db.from('questions')
          .update({ serie_id: serieId })
          .in('id', chunkIds.slice(j, j + 200));
      }

      // Mettre à jour nb_questions
      await db.from('series_qcm')
        .update({ nb_questions: chunk.length, updated_at: new Date().toISOString() })
        .eq('id', serieId);

      serieIndex++;
    }
  }

  await logAdminAction(
    db, adminId, 'harmonize_series', 'serie', 'all',
    null, { matieres_traitees: matiereIds.length, dry_run },
    `Harmonisation séries: ${matiereIds.length} matière(s) traitée(s)`
  );

  return c.json({
    success: true,
    dry_run,
    matieres_traitees: matiereIds.length,
    details: results,
    message: dry_run
      ? `Simulation : ${results.length} matières analysées`
      : `✅ Séries harmonisées pour ${matiereIds.length} matière(s)`,
  });
});

// POST /api/admin-cms/series/migrate-type — SQL migration pour ajouter colonne type
adminCms.post('/series/migrate-type', requireAdmin, async (c) => {
  const sql = `
-- Ajouter colonne type dans simulations_examens (si manquante)
ALTER TABLE simulations_examens
  ADD COLUMN IF NOT EXISTS type VARCHAR(50) DEFAULT 'simulation';

-- Indexer pour filtrage rapide
CREATE INDEX IF NOT EXISTS idx_simulations_type ON simulations_examens(type);

-- Mettre à jour les existantes (sans type = simulation par défaut)
UPDATE simulations_examens SET type = 'simulation' WHERE type IS NULL;
  `;

  return c.json({
    success: true,
    message: '📋 Exécutez ce SQL dans Supabase pour ajouter la colonne type :',
    sql,
    url: 'https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new',
  });
});


export default adminCms;
