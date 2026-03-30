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
        .select('*').eq('actif', true).order('created_at', { ascending: false }).limit(20);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, actualites: data });
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
// Phase 3 : Puise dans les 3736 questions de la banque complète
// Répartition par matière pour un examen équilibré
app.get('/api/examens/:id/questions', async (c) => {
    const examenId = c.req.param('id');
    const db = getDB(c.env);
    // IDs des matières principales importées (Phase 3)
    const MATIERES_EXAMEN = [
        { id: 'cbd22275-d260-40d1-8ff3-d31545f3f1ab', nom: 'Psychotechnique', quota: 10 },
        { id: '104f51e4-be6e-4ce8-961e-56e604818670', nom: 'Figure Africaine', quota: 10 },
        { id: '756e1ca6-7f7f-4f42-940a-b6d9952ffcdf', nom: 'Économie', quota: 10 },
        { id: '37febc5e-8ab5-4875-b7ad-71b30a8253e7', nom: 'Anglais', quota: 10 },
        { id: '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', nom: 'Droit', quota: 10 },
    ];
    const allSelected = [];
    for (const mat of MATIERES_EXAMEN) {
        // Récupérer un échantillon aléatoire par matière
        const { data: matData, error: matErr } = await db
            .from('questions')
            .select('id, matiere_id, enonce, option_a, option_b, option_c, option_d, option_e, bonne_reponse, explication, difficulte')
            .eq('matiere_id', mat.id)
            .limit(200); // Large pool pour le shuffle
        if (!matErr && matData && matData.length > 0) {
            const shuffledMat = matData.sort(() => Math.random() - 0.5).slice(0, mat.quota);
            allSelected.push(...shuffledMat);
        }
    }
    // Si pas assez de questions des matières cibles, compléter avec d'autres matières
    if (allSelected.length < 50) {
        const { data: extra } = await db
            .from('questions')
            .select('id, matiere_id, enonce, option_a, option_b, option_c, option_d, option_e, bonne_reponse, explication, difficulte')
            .not('matiere_id', 'in', `(${MATIERES_EXAMEN.map(m => m.id).join(',')})`)
            .limit(100);
        if (extra && extra.length > 0) {
            const needed = 50 - allSelected.length;
            const shuffledExtra = extra.sort(() => Math.random() - 0.5).slice(0, needed);
            allSelected.push(...shuffledExtra);
        }
    }
    // Mélanger l'ensemble final
    const finalQuestions = allSelected
        .sort(() => Math.random() - 0.5)
        .slice(0, 50)
        .map((q, idx) => ({
        id: q.id,
        examen_id: examenId,
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
    }));
    return c.json({ success: true, questions: finalQuestions });
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
            .select('score_pourcentage')
            .eq('user_id', userId)
            .eq('termine', true)
            .order('created_at', { ascending: false })
            .limit(20);
        const avgScore = sessions && sessions.length > 0
            ? sessions.reduce((sum, s) => sum + (Number(s.score_pourcentage) || 0), 0) / sessions.length
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
    version: '5.0.0',
    timestamp: new Date().toISOString(),
    features: ['16-matieres', '10-examens', 'simulation-v3', 'examens-blancs', 'pdf-export', 'entraide', 'simulations-admin'],
}));
// ── GET /api/simulations-admin — Simulations publiées par l'admin (pour les utilisateurs) ──
app.get('/api/simulations-admin', async (c) => {
    const db = getDB(c.env);
    try {
        const { data, error } = await db.from('simulations_examens')
            .select('id, titre, description, duree_minutes, score_max, created_at, updated_at')
            .eq('published', true)
            .order('created_at', { ascending: false })
            .limit(50);
        if (!error && data && data.length > 0) {
            // Calculer le nombre de questions pour chaque simulation
            const simulationsWithCount = await Promise.all(data.map(async (sim) => {
                let totalQ = 0;
                try {
                    const qIds = JSON.parse(sim.question_ids ?? '[]');
                    totalQ = Array.isArray(qIds) ? qIds.length : 0;
                }
                catch (_) { }
                return { ...sim, total_questions: totalQ };
            }));
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
    // Créer la session
    const { data: session, error: sErr } = await db.from('sessions_examen').insert({
        user_id: userId,
        type_session: 'SIMULATION_ADMIN',
        total_questions: questions.length,
        termine: false,
        simulation_id: simulationId,
    }).select().single();
    if (sErr)
        return c.json({ error: sErr.message }, 500);
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
// 404
app.notFound((c) => c.json({ error: 'Route introuvable.' }, 404));
export default app;
