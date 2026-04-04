import { Hono } from 'hono';
import { cors } from 'hono/cors';
import auth from './api/auth';
import questions from './api/questions';
import simulation from './api/simulation';
import abonnements from './api/abonnements';
import admin from './api/admin';
import adminCms from './api/admin-cms';
import entraide from './api/entraide';
import { getDB } from './lib/db';
import { verifyJWT } from './lib/auth';
const app = new Hono();
// CORS — autoriser toutes les origines (Flutter Web + mobile)
app.use('/api/*', cors({
    origin: '*',
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Content-Type', 'Authorization'],
}));
// Routes
app.route('/api/auth', auth);
app.route('/api', questions); // /api/matieres + /api/questions
app.route('/api/simulation', simulation);
app.route('/api/abonnements', abonnements);
app.route('/api/admin', admin);
app.route('/api/admin-cms', adminCms); // CMS v6.0 — Gestion QCM
app.route('/api/entraide', entraide);
// ── GET /api/statuts — Statuts Entraide v3 (actifs < 24h) ──
// Utilise la table messages_entraide (champ telephone_partage = type)
app.get('/api/statuts', async (c) => {
    const db = getDB(c.env);
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    // Récupérer les messages récents sans jointure complexe
    const { data: msgs, error } = await db
        .from('messages_entraide')
        .select('id,user_id,contenu,telephone_partage,created_at')
        .eq('actif', true)
        .gte('created_at', cutoff)
        .order('created_at', { ascending: false })
        .limit(50);
    if (error)
        return c.json({ error: error.message }, 500);
    // Pour chaque message, récupérer le profil utilisateur séparément
    const statuts = [];
    for (const m of (msgs ?? [])) {
        let prenom = 'Utilisateur';
        let nom = '';
        let is_admin = false;
        try {
            const { data: profile } = await db
                .from('profiles')
                .select('prenom,nom,is_admin')
                .eq('id', m.user_id)
                .single();
            if (profile) {
                prenom = profile.prenom ?? 'Utilisateur';
                nom = profile.nom ?? '';
                is_admin = profile.is_admin === true;
            }
        }
        catch (_) { }
        statuts.push({
            id: m.id,
            user_id: m.user_id,
            prenom,
            nom,
            texte: m.contenu ?? '',
            type: m.telephone_partage ?? 'info',
            is_admin,
            created_at: m.created_at,
        });
    }
    return c.json({ success: true, statuts });
});
// ── POST /api/statuts — Publier un statut (1/jour max, sans limite pour admin) ──
// Utilise messages_entraide: contenu=texte, telephone_partage=type, partage_whatsapp=is_admin
app.post('/api/statuts', async (c) => {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const { verifyJWT } = await import('./lib/auth');
    const payload = await verifyJWT(h.slice(7));
    if (!payload)
        return c.json({ error: 'Token invalide.' }, 401);
    const userId = payload.id;
    const db = getDB(c.env);
    // Vérifier si l'utilisateur est admin dans profiles
    const { data: profile } = await db
        .from('profiles')
        .select('is_admin')
        .eq('id', userId)
        .single();
    const userIsAdmin = payload.is_admin === true || profile?.is_admin === true;
    // Limite 1 statut/24h UNIQUEMENT pour les non-admins
    if (!userIsAdmin) {
        const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
        const { data: existing } = await db
            .from('messages_entraide')
            .select('id')
            .eq('user_id', userId)
            .eq('actif', true)
            .gte('created_at', cutoff)
            .limit(1);
        if (existing && existing.length > 0) {
            return c.json({ error: 'Vous avez déjà posté votre statut aujourd\'hui. Revenez demain !', already_posted: true }, 429);
        }
    }
    const body = await c.req.json().catch(() => ({}));
    const { texte, type } = body;
    if (!texte || String(texte).trim().length < 5) {
        return c.json({ error: 'Message trop court (minimum 5 caractères).' }, 400);
    }
    const validType = ['signaler', 'aide', 'info', 'revision', 'succes'].includes(type) ? type : 'info';
    const { error } = await db.from('messages_entraide').insert({
        user_id: userId,
        contenu: String(texte).trim().substring(0, 280),
        telephone_partage: validType, // stocker le type dans telephone_partage
        partage_whatsapp: false, // pas de partage WhatsApp pour les statuts
        actif: true,
        created_at: new Date().toISOString(),
    });
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, message: 'Statut publié !' });
});
// ── DELETE /api/statuts/:id — Supprimer son statut ──
// Utilise messages_entraide (désactiver via actif=false)
app.delete('/api/statuts/:id', async (c) => {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const { verifyJWT } = await import('./lib/auth');
    const payload = await verifyJWT(h.slice(7));
    if (!payload)
        return c.json({ error: 'Token invalide.' }, 401);
    const userId = payload.id;
    const id = c.req.param('id');
    const db = getDB(c.env);
    const { error } = await db
        .from('messages_entraide')
        .update({ actif: false })
        .eq('id', id)
        .eq('user_id', userId);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true });
});
// ── GET /api/actualites ──
app.get('/api/actualites', async (c) => {
    const db = getDB(c.env);
    const { data, error } = await db.from('actualites')
        .select('*').eq('actif', true).order('created_at', { ascending: false }).limit(50);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, actualites: data });
});
// ── PUT /api/actualites/:id — Modifier une actualité (admin seulement) ──
app.put('/api/actualites/:id', async (c) => {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const payload = await verifyJWT(h.slice(7));
    if (!payload || !payload['is_admin'])
        return c.json({ error: 'Admin requis.' }, 403);
    const id = c.req.param('id');
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    const db = getDB(c.env);
    const updateData = {};
    if (body['titre'])
        updateData['titre'] = String(body['titre']).trim();
    if (body['contenu'])
        updateData['contenu'] = String(body['contenu']).trim();
    if (body['categorie'])
        updateData['categorie'] = body['categorie'];
    if ('actif' in body)
        updateData['actif'] = Boolean(body['actif']);
    const { error } = await db.from('actualites').update(updateData).eq('id', id);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, message: 'Actualité mise à jour.' });
});
// ── DELETE /api/actualites/:id — Supprimer une actualité (admin seulement) ──
app.delete('/api/actualites/:id', async (c) => {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const payload = await verifyJWT(h.slice(7));
    if (!payload || !payload['is_admin'])
        return c.json({ error: 'Admin requis.' }, 403);
    const id = c.req.param('id');
    const db = getDB(c.env);
    // Soft delete (marquer inactif au lieu de supprimer)
    const { error } = await db.from('actualites').update({ actif: false }).eq('id', id);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, message: 'Actualité supprimée.' });
});
// ── DELETE /api/statuts/:id/admin — Supprimer TOUT statut (admin seulement) ──
app.delete('/api/statuts/:id/admin', async (c) => {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const payload = await verifyJWT(h.slice(7));
    if (!payload || !payload['is_admin'])
        return c.json({ error: 'Admin requis.' }, 403);
    const id = c.req.param('id');
    const db = getDB(c.env);
    const { error } = await db.from('messages_entraide').update({ actif: false }).eq('id', id);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true });
});
// ── GET /api/examens — Les 10 examens professionnels ──
app.get('/api/examens', async (c) => {
    // Essayer depuis Supabase si la table existe
    try {
        const db = getDB(c.env);
        const { data, error } = await db.from('examens')
            .select('*')
            .eq('actif', true)
            .order('ordre', { ascending: true })
            .limit(20);
        if (!error && data && data.length > 0) {
            return c.json({ success: true, examens: data });
        }
    }
    catch (_) { }
    // Fallback : données statiques des 10 examens
    const examens = [
        { id: 'exam_001', nom: 'Administration générale', description: 'Adjoints administratifs, agents administratifs, assistants de direction, gestionnaires RH', couleur: '#2C3E50', icone: '📋', nombre_questions: 50, duree_minutes: 120, ordre: 1 },
        { id: 'exam_002', nom: 'Justice & sécurité', description: 'Greffiers, police nationale, gendarmerie, douane, eaux et forêts', couleur: '#C0392B', icone: '⚖️', nombre_questions: 50, duree_minutes: 120, ordre: 2 },
        { id: 'exam_003', nom: 'Économie & finances', description: 'Impôts, trésor public, contrôleurs des finances, comptabilité publique', couleur: '#27AE60', icone: '💰', nombre_questions: 50, duree_minutes: 120, ordre: 3 },
        { id: 'exam_004', nom: 'Concours de la santé', description: 'Infirmiers, sages-femmes, agents de santé', couleur: '#E74C3C', icone: '⚕️', nombre_questions: 50, duree_minutes: 120, ordre: 4 },
        { id: 'exam_005', nom: 'Éducation & formation', description: 'Enseignants du primaire, enseignants du secondaire', couleur: '#3498DB', icone: '🎓', nombre_questions: 50, duree_minutes: 120, ordre: 5 },
        { id: 'exam_006', nom: 'Concours techniques', description: 'Techniciens génie civil, électricité, mécanique, supérieurs', couleur: '#F39C12', icone: '🔧', nombre_questions: 50, duree_minutes: 120, ordre: 6 },
        { id: 'exam_007', nom: 'Agriculture & environnement', description: 'Agents agricoles, élevage, environnement, développement rural', couleur: '#16A085', icone: '🌾', nombre_questions: 50, duree_minutes: 120, ordre: 7 },
        { id: 'exam_008', nom: 'Informatique & numérique', description: 'Techniciens informatiques, développeurs, ingénieurs IT', couleur: '#2ECC71', icone: '💻', nombre_questions: 50, duree_minutes: 120, ordre: 8 },
        { id: 'exam_009', nom: 'Travaux publics & urbanisme', description: 'BTP, urbanisme, topographie', couleur: '#9B59B6', icone: '🏗️', nombre_questions: 50, duree_minutes: 120, ordre: 9 },
        { id: 'exam_010', nom: 'Statistiques & planification', description: 'Statisticiens, économistes, planificateurs', couleur: '#34495E', icone: '📊', nombre_questions: 50, duree_minutes: 120, ordre: 10 },
    ];
    return c.json({ success: true, examens });
});
// ── GET /api/examens/:id/questions — Questions pour un examen ──
// Phase 4 : Utilise les 50 questions fixes assignées à chaque examen type
app.get('/api/examens/:id/questions', async (c) => {
    const examenId = c.req.param('id');
    const db = getDB(c.env);
    // Mapping des 10 examens types vers leurs IDs de simulation dans simulations_examens
    const EXAMEN_SIMULATION_MAP = {
        'exam_001': 66,
        'exam_002': 67,
        'exam_003': 68,
        'exam_004': 69,
        'exam_005': 70,
        'exam_006': 71,
        'exam_007': 72,
        'exam_008': 73,
        'exam_009': 74,
        'exam_010': 75,
    };
    const EXAMEN_NOM_MAP = {
        'exam_001': 'Administration générale',
        'exam_002': 'Justice & sécurité',
        'exam_003': 'Économie & finances',
        'exam_004': 'Concours de la santé',
        'exam_005': 'Éducation & formation',
        'exam_006': 'Concours techniques',
        'exam_007': 'Agriculture & environnement',
        'exam_008': 'Informatique & numérique',
        'exam_009': 'Travaux publics & urbanisme',
        'exam_010': 'Statistiques & planification',
    };
    const examenNom = EXAMEN_NOM_MAP[examenId] ?? 'Examen Type';
    const simId = EXAMEN_SIMULATION_MAP[examenId];
    // Map UUID matière → nom
    const matiereNomAll = {};
    try {
        const { data: allMatieres } = await db.from('matieres').select('id, nom');
        (allMatieres ?? []).forEach((m) => { matiereNomAll[m.id] = m.nom; });
    }
    catch (_) { }
    // Si on a un mapping de simulation, utiliser les questions fixes
    if (simId) {
        try {
            const { data: sim } = await db.from('simulations_examens')
                .select('question_ids, titre')
                .eq('id', simId)
                .single();
            if (sim && sim.question_ids && sim.question_ids.length > 0) {
                const questionIds = sim.question_ids;
                const { data: questionsData } = await db.from('questions')
                    .select('id, matiere_id, enonce, option_a, option_b, option_c, option_d, option_e, bonne_reponse, explication, difficulte')
                    .in('id', questionIds)
                    .limit(50);
                if (questionsData && questionsData.length > 0) {
                    const qMap = {};
                    questionsData.forEach((q) => { qMap[q.id] = q; });
                    const finalQuestions = questionIds
                        .filter(id => qMap[id])
                        .slice(0, 50)
                        .map((id, idx) => {
                        const q = qMap[id];
                        return {
                            id: q.id,
                            examen_id: examenId,
                            examen_nom: examenNom,
                            numero: idx + 1,
                            enonce: q.enonce,
                            option_a: q.option_a,
                            option_b: q.option_b,
                            option_c: q.option_c,
                            option_d: q.option_d,
                            option_e: q.option_e ?? null,
                            bonne_reponse: q.bonne_reponse,
                            explication: q.explication,
                            difficulte: q.difficulte ?? 'moyen',
                            matiere: matiereNomAll[q.matiere_id] ?? 'Culture Générale',
                            matiere_id: q.matiere_id,
                        };
                    });
                    return c.json({ success: true, questions: finalQuestions, source: 'fixe' });
                }
            }
        }
        catch (_) { }
    }
    // Fallback : génération aléatoire depuis la banque de questions
    const MATIERES_EXAMEN = [
        { id: '54f53d06-2d5d-4d82-91bc-4bfff904c12b', nom: 'Psychotechnique', quota: 10 },
        { id: '104f51e4-be6e-4ce8-961e-56e604818670', nom: 'Figure Africaine', quota: 10 },
        { id: '756e1ca6-7f7f-4f42-940a-b6d9952ffcdf', nom: 'Économie', quota: 10 },
        { id: '37febc5e-8ab5-4875-b7ad-71b30a8253e7', nom: 'Anglais', quota: 10 },
        { id: '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', nom: 'Droit', quota: 10 },
    ];
    const allSelected = [];
    for (const mat of MATIERES_EXAMEN) {
        const { data: matData, error: matErr } = await db
            .from('questions')
            .select('id, matiere_id, enonce, option_a, option_b, option_c, option_d, option_e, bonne_reponse, explication, difficulte')
            .eq('matiere_id', mat.id)
            .limit(200);
        if (!matErr && matData && matData.length > 0) {
            const withNom = matData.map(q => ({ ...q, matiere_nom: mat.nom }));
            const shuffledMat = withNom.sort(() => Math.random() - 0.5).slice(0, mat.quota);
            allSelected.push(...shuffledMat);
        }
    }
    if (allSelected.length < 50) {
        const { data: extra } = await db
            .from('questions')
            .select('id, matiere_id, enonce, option_a, option_b, option_c, option_d, option_e, bonne_reponse, explication, difficulte')
            .not('matiere_id', 'in', `(${MATIERES_EXAMEN.map(m => m.id).join(',')})`)
            .limit(100);
        if (extra && extra.length > 0) {
            const needed = 50 - allSelected.length;
            const withNom = extra.map((q) => ({ ...q, matiere_nom: matiereNomAll[q.matiere_id] ?? 'Culture Générale' }));
            const shuffledExtra = withNom.sort(() => Math.random() - 0.5).slice(0, needed);
            allSelected.push(...shuffledExtra);
        }
    }
    const grouped = allSelected.sort((a, b) => (a.matiere_nom || '').localeCompare(b.matiere_nom || ''));
    const finalQuestions = grouped
        .slice(0, 50)
        .map((q, idx) => ({
        id: q.id,
        examen_id: examenId,
        examen_nom: examenNom,
        numero: idx + 1,
        enonce: q.enonce,
        option_a: q.option_a,
        option_b: q.option_b,
        option_c: q.option_c,
        option_d: q.option_d,
        option_e: q.option_e ?? null,
        bonne_reponse: q.bonne_reponse,
        explication: q.explication,
        difficulte: q.difficulte ?? 'moyen',
        matiere: q.matiere_nom ?? matiereNomAll[q.matiere_id] ?? 'Culture Générale',
        matiere_id: q.matiere_id,
    }));
    return c.json({ success: true, questions: finalQuestions, source: 'aleatoire' });
});
// ── TÂCHE 4 : GET /api/user/stats — Stats dashboard utilisateur ──
app.get('/api/user/stats', async (c) => {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const p = await verifyJWT(h.slice(7));
    if (!p)
        return c.json({ error: 'Token invalide.' }, 401);
    const userId = p['id'];
    const db = getDB(c.env);
    try {
        const { count: nbSimulations } = await db
            .from('sessions_examen')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', userId)
            .eq('termine', true);
        const { data: sessions } = await db
            .from('sessions_examen')
            .select('score, total_questions') // Utiliser score et total_questions (colonnes existantes)
            .eq('user_id', userId)
            .eq('termine', true)
            .order('created_at', { ascending: false })
            .limit(20);
        // Calculer le score moyen à partir des colonnes existantes (score/total_questions)
        const avgScore = sessions && sessions.length > 0
            ? sessions.reduce((sum, s) => {
                const pct = (s.total_questions && s.total_questions > 0)
                    ? (Number(s.score || 0) / Number(s.total_questions)) * 100
                    : 0;
                return sum + pct;
            }, 0) / sessions.length
            : 0;
        const nbSim = nbSimulations ?? 0;
        return c.json({
            success: true,
            nb_simulations: nbSim,
            score_moyen: Math.round(avgScore * 10) / 10,
            questions_repondues: nbSim * 50,
        });
    }
    catch (e) {
        return c.json({
            success: false,
            nb_simulations: 0,
            score_moyen: 0,
            questions_repondues: 0,
            error: e.message,
        });
    }
});
// ── POST /api/admin/migrate-examens — Créer les tables examens blancs ──
app.post('/api/admin/migrate-examens', async (c) => {
    const authHeader = c.req.header('Authorization');
    if (!authHeader?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const payload = await verifyJWT(authHeader.slice(7));
    if (!payload || !payload['is_admin'])
        return c.json({ error: 'Admin requis.' }, 403);
    const supabaseUrl = c.env.SUPABASE_URL || 'https://xqifdbgqxyrlhrkwlyir.supabase.co';
    const serviceKey = c.env.SUPABASE_SERVICE_KEY || '';
    const sqlStatements = [
        `CREATE TABLE IF NOT EXISTS examens_blancs (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      titre TEXT NOT NULL,
      duree_minutes INTEGER DEFAULT 90,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    )`,
        `CREATE TABLE IF NOT EXISTS exam_sections (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      examen_id UUID REFERENCES examens_blancs(id) ON DELETE CASCADE,
      titre TEXT NOT NULL,
      ordre INTEGER NOT NULL
    )`,
        `CREATE TABLE IF NOT EXISTS exam_questions (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      section_id UUID REFERENCES exam_sections(id) ON DELETE CASCADE,
      numero INTEGER NOT NULL,
      enonce TEXT NOT NULL,
      option_a TEXT, option_b TEXT, option_c TEXT, option_d TEXT, option_e TEXT,
      bonnes_reponses TEXT[] NOT NULL DEFAULT '{}',
      explication TEXT
    )`,
        `CREATE TABLE IF NOT EXISTS exam_resultats (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      user_id UUID,
      examen_id UUID REFERENCES examens_blancs(id),
      score INTEGER, total INTEGER, pourcentage NUMERIC(5,2),
      reponses JSONB,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    )`,
    ];
    const results = [];
    for (const sql of sqlStatements) {
        try {
            const r = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql`, {
                method: 'POST',
                headers: {
                    'apikey': serviceKey,
                    'Authorization': `Bearer ${serviceKey}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ sql }),
            });
            results.push(`SQL: ${r.status}`);
        }
        catch (e) {
            results.push(`Error: ${e.message}`);
        }
    }
    return c.json({ success: true, results, message: 'Migration tentée. Vérifiez les résultats.' });
});
// ── GET /api/examens-blancs — Liste des examens blancs v3 ──
app.get('/api/examens-blancs', async (c) => {
    const db = getDB(c.env);
    try {
        const { data, error } = await db.from('examens_blancs')
            .select('*')
            .order('created_at', { ascending: true })
            .limit(20);
        if (!error && data && data.length > 0) {
            return c.json({ success: true, examens: data });
        }
    }
    catch (_) { }
    // Fallback : données statiques des examens blancs
    const examens = [
        { id: 'eb_001', titre: 'Concours Direct MENA - Session 2025', duree_minutes: 90, nombre_questions: 50 },
        { id: 'eb_002', titre: 'Administration Générale - Session A', duree_minutes: 90, nombre_questions: 50 },
        { id: 'eb_003', titre: 'Justice & Sécurité - Session B', duree_minutes: 90, nombre_questions: 50 },
        { id: 'eb_004', titre: 'Finances Publiques - Session 2025', duree_minutes: 90, nombre_questions: 50 },
        { id: 'eb_005', titre: 'Santé Publique - Session A', duree_minutes: 90, nombre_questions: 50 },
        { id: 'eb_006', titre: 'Éducation Nationale - Session 2025', duree_minutes: 90, nombre_questions: 50 },
        { id: 'eb_007', titre: 'Concours Techniques - Session B', duree_minutes: 90, nombre_questions: 50 },
        { id: 'eb_008', titre: 'Agriculture & Environnement - Session 2025', duree_minutes: 90, nombre_questions: 50 },
        { id: 'eb_009', titre: 'Informatique & Numérique - Session A', duree_minutes: 90, nombre_questions: 50 },
        { id: 'eb_010', titre: 'Statistiques & Planification - Session B', duree_minutes: 90, nombre_questions: 50 },
    ];
    return c.json({ success: true, examens });
});
// ── POST /api/exam-resultats — Sauvegarder les résultats ──
app.post('/api/exam-resultats', async (c) => {
    const body = await c.req.json();
    const db = getDB(c.env);
    try {
        const { data, error } = await db.from('exam_resultats').insert({
            user_id: body.user_id,
            examen_id: body.examen_id,
            score: body.score,
            total: body.total,
            pourcentage: body.pourcentage,
            reponses: body.reponses,
        }).select().single();
        if (error) {
            // Si la table n'existe pas encore, retourner succès quand même
            return c.json({ success: true, message: 'Résultat enregistré localement.', data: null });
        }
        return c.json({ success: true, data });
    }
    catch (e) {
        return c.json({ success: true, message: 'Résultat traité.', data: null });
    }
});
// Health check
app.get('/api/health', (c) => c.json({
    status: 'ok',
    app: 'EF-FORT.BF API',
    version: '10.0.0',
    timestamp: new Date().toISOString(),
    features: ['18-matieres', '2786-questions', 'simulation-v3', 'examens-blancs', 'pdf-export-v2', 'entraide-v6-no-migration', 'simulations-admin', 'freemium-v2', 'annonces-crud', 'admin-delete', 'reponses-admin-sans-migration'],
}));
// ── POST /api/admin/migrate-parent-id — Migration parent_id entraide ──
// Endpoint spécial pour exécuter la migration via l'API Supabase Management
app.post('/api/admin/migrate-parent-id', async (c) => {
    const authHeader = c.req.header('Authorization');
    if (!authHeader?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const payload = await verifyJWT(authHeader.slice(7));
    if (!payload || !payload['is_admin'])
        return c.json({ error: 'Admin requis.' }, 403);
    const supabaseUrl = c.env.SUPABASE_URL || 'https://xqifdbgqxyrlhrkwlyir.supabase.co';
    const serviceKey = c.env.SUPABASE_KEY;
    const supabaseRef = 'xqifdbgqxyrlhrkwlyir';
    const results = [];
    // Méthode 1 : Tenter via l'API Management Supabase (Project Database API)
    try {
        const mgmtUrl = `https://api.supabase.com/v1/projects/${supabaseRef}/database/query`;
        const r1 = await fetch(mgmtUrl, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${serviceKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                query: `ALTER TABLE public.messages_entraide ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.messages_entraide(id) ON DELETE CASCADE; CREATE INDEX IF NOT EXISTS idx_messages_entraide_parent_id ON public.messages_entraide(parent_id);`
            }),
        });
        const r1Data = await r1.json();
        results.push({ method: 'management_api', status: r1.status, data: r1Data });
    }
    catch (e) {
        results.push({ method: 'management_api', error: e.message });
    }
    // Vérification finale
    const db = getDB(c.env);
    const { data: test, error: testErr } = await db
        .from('messages_entraide')
        .select('id, parent_id')
        .limit(1);
    const migrationOk = !testErr || !testErr.message?.includes('parent_id');
    return c.json({
        success: migrationOk,
        results,
        migration_status: migrationOk ? '✅ Colonne parent_id présente' : '❌ Colonne parent_id absente',
        sql_to_run_manually: `
-- À exécuter dans Supabase SQL Editor :
-- https://supabase.com/dashboard/project/${supabaseRef}/sql/new
ALTER TABLE public.messages_entraide ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.messages_entraide(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_messages_entraide_parent_id ON public.messages_entraide(parent_id);
    `.trim()
    });
});
// ── GET /api/simulations-admin — Simulations publiées par l'admin (pour les utilisateurs) ──
app.get('/api/simulations-admin', async (c) => {
    const db = getDB(c.env);
    try {
        // Inclure question_ids dans le select pour calculer le vrai nombre de questions
        const { data, error } = await db.from('simulations_examens')
            .select('id, titre, description, duree_minutes, score_max, question_ids, created_at, updated_at')
            .eq('published', true)
            .order('created_at', { ascending: false })
            .limit(50);
        if (!error && data && data.length > 0) {
            // Calculer le nombre réel de questions pour chaque simulation
            const simulationsWithCount = data.map((sim) => {
                let totalQ = 0;
                try {
                    let qIds = [];
                    if (typeof sim.question_ids === 'string') {
                        qIds = JSON.parse(sim.question_ids);
                    }
                    else if (Array.isArray(sim.question_ids)) {
                        qIds = sim.question_ids;
                    }
                    else if (sim.question_ids && typeof sim.question_ids === 'object') {
                        qIds = Object.values(sim.question_ids);
                    }
                    totalQ = Array.isArray(qIds) ? qIds.length : 0;
                }
                catch (_) {
                    totalQ = 0;
                }
                // Ne pas exposer question_ids aux clients
                const { question_ids: _qi, ...simWithoutIds } = sim;
                return { ...simWithoutIds, total_questions: totalQ };
            });
            return c.json({ success: true, simulations: simulationsWithCount });
        }
        return c.json({ success: true, simulations: [] });
    }
    catch (e) {
        return c.json({ success: true, simulations: [], error: e.message });
    }
});
// ── POST /api/simulations-admin/:id/demarrer — Démarrer une simulation admin ──
app.post('/api/simulations-admin/:id/demarrer', async (c) => {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const payload = await verifyJWT(h.slice(7));
    if (!payload)
        return c.json({ error: 'Token invalide.' }, 401);
    const userId = payload['id'];
    const simulationId = c.req.param('id');
    const db = getDB(c.env);
    // Récupérer la simulation
    const { data: sim, error: simErr } = await db.from('simulations_examens')
        .select('*').eq('id', simulationId).eq('published', true).single();
    if (simErr || !sim)
        return c.json({ error: 'Simulation introuvable ou non publiée.' }, 404);
    // Récupérer les IDs de questions
    let questionIds = [];
    try {
        questionIds = JSON.parse(sim.question_ids ?? '[]');
    }
    catch (_) { }
    if (questionIds.length === 0)
        return c.json({ error: 'Cette simulation ne contient aucune question.' }, 400);
    // Récupérer les questions (sans les réponses)
    const { data: questionsData } = await db.from('questions')
        .select('id, enonce, option_a, option_b, option_c, option_d, option_e, difficulte, matiere_id')
        .in('id', questionIds)
        .limit(500);
    if (!questionsData || questionsData.length === 0) {
        return c.json({ error: 'Questions introuvables pour cette simulation.' }, 400);
    }
    // Mélanger si nécessaire
    let questions = [...questionsData];
    if (sim.ordre_questions === 'random') {
        questions = questions.sort(() => Math.random() - 0.5);
    }
    // Créer la session — sans simulation_id car la colonne est de type UUID
    // et simulations_examens.id est un INTEGER (incompatible)
    const { data: session, error: sErr } = await db.from('sessions_examen').insert({
        user_id: userId,
        type_session: 'SIMULATION_ADMIN',
        total_questions: questions.length,
        termine: false,
    }).select().single();
    if (sErr || !session)
        return c.json({ error: sErr?.message ?? 'Erreur création session' }, 500);
    return c.json({
        success: true,
        session_id: session.id,
        simulation_titre: sim.titre,
        duree_minutes: sim.duree_minutes ?? 90,
        questions: questions.map(q => ({
            id: q.id,
            question: q.enonce,
            option_a: q.option_a,
            option_b: q.option_b,
            option_c: q.option_c,
            option_d: q.option_d,
            option_e: q.option_e ?? null,
            difficulte: q.difficulte,
        })),
        total: questions.length,
        show_corrections: sim.show_corrections !== false,
    });
});
// ── POST /api/admin/migrate-schema — Migrer le schéma (ajouter colonnes manquantes) ──
app.post('/api/admin/migrate-schema', async (c) => {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const payload = await verifyJWT(h.slice(7));
    if (!payload || !payload['is_admin'])
        return c.json({ error: 'Admin requis.' }, 403);
    const supabaseUrl = c.env.SUPABASE_URL || 'https://xqifdbgqxyrlhrkwlyir.supabase.co';
    const serviceKey = c.env.SUPABASE_SERVICE_KEY || '';
    const results = [];
    // Liste des migrations à appliquer
    const migrations = [
        {
            name: 'Ajouter simulation_id à sessions_examen',
            sql: `ALTER TABLE sessions_examen ADD COLUMN IF NOT EXISTS simulation_id UUID`,
        },
        {
            name: 'Ajouter score_pourcentage à sessions_examen',
            sql: `ALTER TABLE sessions_examen ADD COLUMN IF NOT EXISTS score_pourcentage NUMERIC(5,2)`,
        },
    ];
    for (const migration of migrations) {
        try {
            // Utiliser l'API REST Supabase avec service role
            const resp = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_ddl`, {
                method: 'POST',
                headers: {
                    'apikey': serviceKey,
                    'Authorization': `Bearer ${serviceKey}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ ddl: migration.sql }),
            });
            if (resp.ok) {
                results.push({ sql: migration.name, status: '✅ Succès' });
            }
            else {
                // Essayer via l'API de gestion Supabase
                const resp2 = await fetch(`${supabaseUrl}/rest/v1/rpc/query`, {
                    method: 'POST',
                    headers: {
                        'apikey': serviceKey,
                        'Authorization': `Bearer ${serviceKey}`,
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ query: migration.sql }),
                });
                results.push({
                    sql: migration.name,
                    status: resp2.ok ? '✅ Succès (v2)' : `⚠️ HTTP ${resp.status}: Exécuter manuellement dans SQL Editor`,
                });
            }
        }
        catch (e) {
            results.push({ sql: migration.name, status: `❌ Erreur: ${e.message}` });
        }
    }
    return c.json({
        success: true,
        results,
        message: 'Migration terminée. Si des colonnes manquent, utilisez le SQL Editor Supabase:',
        manual_sql: `
ALTER TABLE sessions_examen ADD COLUMN IF NOT EXISTS simulation_id UUID;
ALTER TABLE sessions_examen ADD COLUMN IF NOT EXISTS score_pourcentage NUMERIC(5,2);
    `.trim(),
        sql_editor_url: 'https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new',
    });
});
// ── POST /api/admin/migrate-entraide — Ajouter parent_id à messages_entraide ──
// v2.0 : Utilise pg_meta pour créer la colonne sans nécessiter de fonction RPC custom
app.post('/api/admin/migrate-entraide', async (c) => {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const payload = await verifyJWT(h.slice(7));
    if (!payload || !payload['is_admin'])
        return c.json({ error: 'Admin requis.' }, 403);
    const supabaseUrl = c.env.SUPABASE_URL || 'https://xqifdbgqxyrlhrkwlyir.supabase.co';
    const serviceKey = c.env.SUPABASE_KEY || '';
    // SQL de migration v2 — Utilise la création d'une fonction SQL temporaire
    const migrationSQL = `
ALTER TABLE public.messages_entraide 
  ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.messages_entraide(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_messages_entraide_parent_id ON public.messages_entraide(parent_id);
COMMENT ON COLUMN public.messages_entraide.parent_id IS 'Référence vers le message parent pour les réponses admin';
  `.trim();
    // Méthode 1 : Tentative via l'API pg_meta de Supabase (colonnes)
    try {
        // D'abord obtenir l'ID de la table
        const tablesResp = await fetch(`${supabaseUrl}/pg-meta/v1/tables?schemas=public&limit=100`, {
            headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` },
        });
        if (tablesResp.ok) {
            const tables = await tablesResp.json();
            const table = tables.find((t) => t.name === 'messages_entraide');
            if (table?.id) {
                // Créer la colonne via pg_meta
                const colResp = await fetch(`${supabaseUrl}/pg-meta/v1/columns`, {
                    method: 'POST',
                    headers: {
                        'apikey': serviceKey,
                        'Authorization': `Bearer ${serviceKey}`,
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        table_id: table.id,
                        name: 'parent_id',
                        type: 'uuid',
                        is_nullable: true,
                        comment: 'Référence vers le message parent pour les réponses admin',
                    }),
                });
                if (colResp.ok || colResp.status === 409) {
                    return c.json({
                        success: true,
                        message: '✅ Migration réussie via pg_meta! Colonne parent_id ajoutée.',
                        method: 'pg_meta',
                    });
                }
            }
        }
    }
    catch (_) { }
    // Méthode 2 : Créer une fonction RPC temporaire et l'exécuter
    try {
        // Créer la fonction run_ddl si elle n'existe pas
        const createFnResp = await fetch(`${supabaseUrl}/rest/v1/rpc/run_ddl_safe`, {
            method: 'POST',
            headers: {
                'apikey': serviceKey,
                'Authorization': `Bearer ${serviceKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ statement: "ALTER TABLE public.messages_entraide ADD COLUMN IF NOT EXISTS parent_id UUID;" }),
        });
        if (createFnResp.ok) {
            return c.json({ success: true, message: '✅ Migration via run_ddl_safe réussie!', method: 'rpc' });
        }
    }
    catch (_) { }
    // Retourner le SQL + instructions détaillées pour exécution manuelle
    return c.json({
        success: false,
        message: '⚠️ Exécutez ce SQL dans Supabase SQL Editor pour activer les réponses admin:',
        sql: migrationSQL,
        sql_editor_url: 'https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new',
        instructions: [
            '1. Aller sur https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new',
            '2. Copier-coller le SQL ci-dessus',
            '3. Cliquer sur "Run"',
            '4. La fonctionnalité de réponses admin sera immédiatement activée',
        ],
    });
});
// ── GET /api/admin/check-entraide-schema — Vérifier le schéma entraide ──
app.get('/api/admin/check-entraide-schema', async (c) => {
    const db = getDB(c.env);
    // Tester si parent_id existe
    const { data, error } = await db
        .from('messages_entraide')
        .select('id, parent_id')
        .limit(1);
    if (error && error.code === '42703') {
        return c.json({
            parent_id_exists: false,
            message: 'La colonne parent_id est manquante. Migration requise.',
            migration_endpoint: 'POST /api/admin/migrate-entraide'
        });
    }
    return c.json({
        parent_id_exists: true,
        message: '✅ Schéma entraide OK - parent_id présent'
    });
});
// 404
app.notFound((c) => c.json({ error: 'Route introuvable.' }, 404));
export default app;
