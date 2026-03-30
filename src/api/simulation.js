import { Hono } from 'hono';
import { getDB } from '../lib/db';
import { verifyJWT } from '../lib/auth';
const simulation = new Hono();
// Middleware auth
async function requireAuth(c, next) {
    const authHeader = c.req.header('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
        return c.json({ error: 'Authentification requise.' }, 401);
    }
    const payload = await verifyJWT(authHeader.slice(7));
    if (!payload)
        return c.json({ error: 'Token invalide ou expiré.' }, 401);
    const context = c;
    context.userId = payload['id'];
    context.isAdmin = payload['is_admin'];
    await next();
}
// ── POST /api/simulation/demarrer ───────────────────────────
simulation.post('/demarrer', requireAuth, async (c) => {
    const context = c;
    const userId = context.userId;
    const db = getDB(c.env);
    // Vérifier abonnement et quota freemium
    const { data: userRow } = await db.from('profiles').select('abonnement_actif, is_admin').eq('id', userId).single();
    const isAbonne = userRow?.abonnement_actif === true;
    const isAdmin = userRow?.is_admin === true;
    if (!isAbonne && !isAdmin) {
        // Compter les simulations déjà faites
        const { count: nbSim } = await db
            .from('sessions_examen')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', userId)
            .eq('type_session', 'SIMULATION')
            .eq('termine', true);
        if ((nbSim ?? 0) >= 1) {
            return c.json({
                error: 'Accès limité. Abonnez-vous pour accéder à toutes les simulations illimitées.',
                quota_atteint: true,
            }, 403);
        }
    }
    // Récupérer des questions de toutes les matières (y compris AES et Burkina Faso v5.1)
    // Stratégie : tirer aléatoirement depuis toutes les matières disponibles
    const { data: allQ, error } = await db
        .from('questions')
        .select('id, matiere_id, enonce, option_a, option_b, option_c, option_d, bonne_reponse, explication, difficulte')
        .limit(500);
    if (error)
        return c.json({ error: error.message }, 500);
    const available = allQ ?? [];
    // Regrouper par matière pour assurer la diversité
    const byMatiere = {};
    for (const q of available) {
        const mid = q.matiere_id ?? 'unknown';
        if (!byMatiere[mid])
            byMatiere[mid] = [];
        byMatiere[mid].push(q);
    }
    // Prendre jusqu'à 3 questions par matière, puis compléter avec le reste
    const selected = [];
    for (const matQuestions of Object.values(byMatiere)) {
        const shuffledMat = matQuestions.sort(() => Math.random() - 0.5);
        selected.push(...shuffledMat.slice(0, 3));
    }
    // Mélanger et compléter jusqu'à 50
    const shuffled = selected.sort(() => Math.random() - 0.5).slice(0, Math.min(50, selected.length));
    // Créer la session
    const { data: session, error: sErr } = await db
        .from('sessions_examen')
        .insert({
        user_id: userId,
        type_session: 'SIMULATION',
        total_questions: shuffled.length,
        termine: false,
    })
        .select().single();
    if (sErr)
        return c.json({ error: sErr.message }, 500);
    // Masquer les bonnes réponses envoyées au client
    const questionsClean = shuffled.map(q => ({
        id: q.id,
        matiere: q.matiere_id,
        question: q.enonce, // Adapter le champ
        option_a: q.option_a,
        option_b: q.option_b,
        option_c: q.option_c,
        option_d: q.option_d,
    }));
    return c.json({
        success: true,
        session_id: session.id,
        questions: questionsClean,
        duree: 90, // minutes
        total: shuffled.length,
    });
});
// ── POST /api/simulation/terminer ───────────────────────────
simulation.post('/terminer', requireAuth, async (c) => {
    const context = c;
    const userId = context.userId;
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    const { session_id, reponses, temps_utilise } = body;
    if (!session_id || !Array.isArray(reponses)) {
        return c.json({ error: 'session_id et reponses requis.' }, 400);
    }
    const db = getDB(c.env);
    // Vérifier la session
    const { data: session, error: sErr } = await db
        .from('sessions_examen').select('*').eq('id', session_id)
        .eq('user_id', userId).single();
    if (sErr || !session)
        return c.json({ error: 'Session introuvable.' }, 404);
    if (session.termine)
        return c.json({ error: 'Session déjà terminée.' }, 400);
    // Récupérer les vraies réponses
    const questionIds = reponses.map((r) => r.question_id).filter(Boolean);
    const { data: questionsData } = await db
        .from('questions')
        .select('id, matiere_id, bonne_reponse, explication, enonce, option_a, option_b, option_c, option_d')
        .in('id', questionIds);
    const qMap = {};
    for (const q of questionsData ?? [])
        qMap[q.id] = q;
    // Calcul score — barème officiel
    let score = 0;
    const details = [];
    const scoreParMatiere = {};
    for (const rep of reponses) {
        const q = qMap[rep.question_id];
        if (!q)
            continue;
        const mat = q.matiere_id;
        if (!scoreParMatiere[mat])
            scoreParMatiere[mat] = { correct: 0, total: 0 };
        scoreParMatiere[mat].total++;
        let points = 0;
        let correct = false;
        if (!rep.reponse || rep.reponse === '') {
            points = 0;
        }
        else if (rep.reponse === q.bonne_reponse) {
            points = 1;
            correct = true;
            scoreParMatiere[mat].correct++;
        }
        else {
            points = -1;
        }
        score += points;
        details.push({
            question_id: q.id,
            question: q.enonce,
            option_a: q.option_a, option_b: q.option_b,
            option_c: q.option_c, option_d: q.option_d,
            reponse_user: rep.reponse || null,
            bonne_reponse: q.bonne_reponse,
            explication: q.explication,
            correct,
            points,
            matiere: mat,
        });
    }
    score = Math.max(0, score);
    const total = details.length;
    const pct = total > 0 ? Math.round((score / total) * 100) : 0;
    let mention = 'Insuffisant';
    if (score >= 40)
        mention = 'Excellent 🏆';
    else if (score >= 30)
        mention = 'Bien 👍';
    else if (score >= 20)
        mention = 'Passable';
    await db.from('sessions_examen').update({
        score,
        total_questions: total,
        temps_utilise: temps_utilise ?? 0,
        termine: true,
        details,
    }).eq('id', session_id);
    return c.json({
        success: true,
        score, total, pourcentage: pct,
        mention, scoreParMatiere, details,
    });
});
export default simulation;
