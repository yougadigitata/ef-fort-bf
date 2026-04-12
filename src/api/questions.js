import { Hono } from 'hono';
import { getDB } from '../lib/db';
const questions = new Hono();
// ── GET /api/matieres — 20 matières optimisé v7.0 (2 requêtes globales) ──
questions.get('/matieres', async (c) => {
    const db = getDB(c.env);
    // Récupérer toutes les matières officielles (triées par ordre)
    const { data: matieres, error: mErr } = await db
        .from('matieres')
        .select('id, nom, code, icone, couleur, ordre')
        .order('ordre', { ascending: true })
        .limit(50);
    if (mErr)
        return c.json({ error: mErr.message }, 500);
    // Les 20 codes officiels v7.0 (PSY + HAUT inclus)
    const CODES_OFFICIELS = [
        'DROIT2', 'ECO2', 'MATHS', 'SP', 'SVT', 'CG', 'ACTU', 'PANA',
        'HISTO', 'ARMEE', 'PSYCHO', 'PSY', 'FR', 'ANG', 'INFO', 'COMM', 'HG',
        'AES', 'BF', 'HAUT'
    ];
    // Filtrer uniquement les matières officielles
    const matieresFiltrees = (matieres ?? []).filter(m => CODES_OFFICIELS.includes(m.code));
    const matiereIds = matieresFiltrees.map(m => m.id);
    // ── OPTIMISATION v7.0 : 2 requêtes globales au lieu de 40 séquentielles ──
    // Requête 1 : tous les matiere_id des questions (pour comptage)
    const countMap = {};
    const seriesMap = {};
    try {
        // Récupérer les matiere_id de toutes les questions en une seule requête
        const { data: allQ } = await db
            .from('questions')
            .select('matiere_id')
            .in('matiere_id', matiereIds)
            .limit(10000);
        for (const q of (allQ ?? [])) {
            const mid = q.matiere_id;
            countMap[mid] = (countMap[mid] ?? 0) + 1;
        }
    }
    catch (_) { }
    try {
        // Récupérer les matiere_id de toutes les séries actives en une seule requête
        const { data: allS } = await db
            .from('series_qcm')
            .select('matiere_id')
            .in('matiere_id', matiereIds)
            .eq('actif', true)
            .limit(2000);
        for (const s of (allS ?? [])) {
            const mid = s.matiere_id;
            seriesMap[mid] = (seriesMap[mid] ?? 0) + 1;
        }
    }
    catch (_) { }
    const result = matieresFiltrees.map(m => ({
        id: m.code?.toLowerCase() || m.id,
        nom: m.nom,
        icone: m.icone ?? '📚',
        couleur: m.couleur ?? '#1A5C38',
        nb_questions: countMap[m.id] ?? 0,
        nb_series: seriesMap[m.id] ?? 0,
        abonne_only: false,
        matiere_id: m.id,
        ordre: m.ordre ?? 99,
    })).sort((a, b) => a.ordre - b.ordre);
    // Headers de cache (5 minutes)
    c.header('Cache-Control', 'public, max-age=300');
    return c.json({ success: true, matieres: result });
});
// ── GET /api/questions — Avec pagination et support 20 000+ QCM ─
questions.get('/questions', async (c) => {
    const matiereCode = c.req.query('matiere');
    const serieId = c.req.query('serie_id');
    const page = Math.max(1, parseInt(c.req.query('page') ?? '1'));
    // Support jusqu'à 20 000 QCM — limite max portée à 1000
    const limit = Math.min(parseInt(c.req.query('limit') ?? '20'), 1000);
    const offset = (page - 1) * limit;
    const db = getDB(c.env);
    // ── MISSION 7 : ANTI-FRAUDE — Vérification abonnement si serie_id fourni ──
    if (serieId) {
        let isAbonne = false;
        let isAdmin = false;
        const authHeader = c.req.header('Authorization');
        if (authHeader?.startsWith('Bearer ')) {
            try {
                const { verifyJWT } = await import('../lib/auth');
                const payload = await verifyJWT(authHeader.slice(7));
                if (payload) {
                    const { data: profile } = await db.from('profiles')
                        .select('abonnement_actif, is_admin')
                        .eq('id', payload['id'])
                        .single();
                    isAbonne = profile?.abonnement_actif === true;
                    isAdmin = profile?.is_admin === true || payload['is_admin'] === true;
                }
            }
            catch (_) { }
        }
        // ── ANTI-FRAUDE RENFORCÉ : Vérifier si la série est la première de SA matière ──
        // Règle absolue : seule la série ayant le plus petit numéro dans sa matière est gratuite
        if (!isAbonne && !isAdmin) {
            try {
                // Récupérer la série demandée avec sa matière
                const { data: serieInfo } = await db.from('series_qcm')
                    .select('est_demo, numero, matiere_id, actif')
                    .eq('id', serieId)
                    .single();
                if (serieInfo) {
                    // Vérifier si c'est la première série active de CETTE matière (numéro min)
                    let isPremiereDeLaMatiere = serieInfo.est_demo === true;
                    if (!isPremiereDeLaMatiere && serieInfo.matiere_id) {
                        // Chercher la série avec le plus petit numéro pour cette matière
                        const { data: premiereSerieData } = await db.from('series_qcm')
                            .select('id, numero')
                            .eq('matiere_id', serieInfo.matiere_id)
                            .eq('actif', true)
                            .order('numero', { ascending: true })
                            .limit(1);
                        const premiereSerieId = premiereSerieData?.[0]?.id;
                        isPremiereDeLaMatiere = (premiereSerieId === serieId);
                    }
                    // Bloquer si ce n'est ni demo ni la première série de la matière
                    if (!isPremiereDeLaMatiere) {
                        return c.json({
                            error: 'Accès réservé aux abonnés Premium.',
                            code: 'PREMIUM_REQUIRED',
                            message: 'Seule la première série est gratuite. Abonnez-vous pour accéder aux autres séries.',
                        }, 403);
                    }
                }
            }
            catch (_) { }
        }
    }
    // Charger la map ID → nom des matières pour éviter d'afficher des UUIDs
    const matiereNomMap = {};
    try {
        const { data: mats } = await db.from('matieres').select('id, nom');
        (mats ?? []).forEach((m) => { matiereNomMap[m.id] = m.nom; });
    }
    catch (_) { }
    let query = db.from('questions')
        .select('id, serie_id, matiere_id, numero, enonce, option_a, option_b, option_c, option_d, option_e, bonne_reponse, explication, difficulte');
    // Filtrer par série si fourni (priorité sur matière)
    if (serieId) {
        query = query.eq('serie_id', serieId);
        // Récupérer TOUTES les questions de la série (pas de limite artificielle)
        const { data, error } = await query.order('numero', { ascending: true }).limit(1000);
        if (error)
            return c.json({ error: error.message }, 500);
        // Récupérer le nom de la série pour affichage
        let serieNom = '';
        try {
            const { data: serie } = await db.from('series_qcm').select('titre, matiere_id').eq('id', serieId).single();
            if (serie) {
                serieNom = serie.titre ?? '';
                if (!matiereNomMap[serie.matiere_id]) {
                    const { data: mat } = await db.from('matieres').select('nom').eq('id', serie.matiere_id).single();
                    if (mat)
                        matiereNomMap[serie.matiere_id] = mat.nom;
                }
            }
        }
        catch (_) { }
        const mapped = (data ?? []).map(q => ({
            id: q.id,
            serie_id: q.serie_id,
            matiere: matiereNomMap[q.matiere_id] ?? q.matiere_id, // Nom réel, jamais UUID
            matiere_id: q.matiere_id,
            question: q.enonce,
            enonce: q.enonce,
            option_a: q.option_a,
            option_b: q.option_b,
            option_c: q.option_c,
            option_d: q.option_d,
            option_e: q.option_e ?? null,
            bonne_reponse: q.bonne_reponse,
            explication: q.explication,
            difficulte: q.difficulte,
        }));
        return c.json({ success: true, questions: mapped, page: 1, limit: mapped.length, total: mapped.length });
    }
    // Filtrer par matière si spécifié
    if (matiereCode) {
        const { data: mat } = await db
            .from('matieres')
            .select('id, nom')
            .ilike('code', matiereCode)
            .maybeSingle();
        if (mat) {
            query = query.eq('matiere_id', mat.id);
            // Enrichir la map avec cette matière
            matiereNomMap[mat.id] = mat.nom;
        }
    }
    // Compter le total pour la pagination
    let totalCount = 0;
    try {
        let countQuery = db.from('questions').select('*', { count: 'exact', head: true });
        if (matiereCode) {
            const { data: mat } = await db.from('matieres').select('id').ilike('code', matiereCode).maybeSingle();
            if (mat)
                countQuery = countQuery.eq('matiere_id', mat.id);
        }
        const { count } = await countQuery;
        totalCount = count ?? 0;
    }
    catch (_) { }
    // Pagination optimisée avec range
    const { data, error } = await query
        .range(offset, offset + limit - 1)
        .order('numero', { ascending: true });
    if (error)
        return c.json({ error: error.message }, 500);
    const mapped = (data ?? []).map(q => ({
        id: q.id,
        serie_id: q.serie_id,
        matiere: matiereNomMap[q.matiere_id] ?? q.matiere_id, // Nom réel, jamais UUID
        matiere_id: q.matiere_id,
        question: q.enonce,
        enonce: q.enonce,
        option_a: q.option_a,
        option_b: q.option_b,
        option_c: q.option_c,
        option_d: q.option_d,
        option_e: q.option_e ?? null,
        bonne_reponse: q.bonne_reponse,
        explication: q.explication,
        difficulte: q.difficulte,
    }));
    return c.json({ success: true, questions: mapped, page, limit, total: totalCount });
});
// ── GET /api/series — Séries par matière ───────────────────────
questions.get('/series', async (c) => {
    const matiereId = c.req.query('matiere_id');
    const db = getDB(c.env);
    // Vérification abonnement pour restreindre côté serveur (anti-bypass)
    let isAbonne = false;
    let isAdmin = false;
    const authHeader = c.req.header('Authorization');
    if (authHeader?.startsWith('Bearer ')) {
        try {
            const { verifyJWT } = await import('../lib/auth');
            const payload = await verifyJWT(authHeader.slice(7));
            if (payload) {
                const { data: profile } = await db.from('profiles')
                    .select('abonnement_actif, is_admin')
                    .eq('id', payload['id'])
                    .single();
                isAbonne = profile?.abonnement_actif === true;
                isAdmin = profile?.is_admin === true || payload['is_admin'] === true;
            }
        }
        catch (_) { }
    }
    let query = db.from('series_qcm')
        .select('id, matiere_id, titre, numero, niveau, duree_minutes, nb_questions, est_demo, actif')
        .eq('actif', true)
        .order('numero', { ascending: true });
    if (matiereId) {
        query = query.eq('matiere_id', matiereId);
    }
    // Support 20 000+ QCM : toutes les séries sans limite artificielle
    const { data, error } = await query.limit(2000);
    if (error)
        return c.json({ error: error.message }, 500);
    // Marquer les séries verrouillées pour les non-abonnés (la 1ère est toujours gratuite)
    const series = (data ?? []).map((s, index) => ({
        ...s,
        locked: !isAbonne && !isAdmin && !s.est_demo && index > 0,
        is_free: index === 0 || s.est_demo,
    }));
    // Pas de cache sur les séries
    c.header('Cache-Control', 'no-store, no-cache, must-revalidate');
    return c.json({ success: true, series });
});
// ── GET /api/questions/count — Compter les questions par matière ─
questions.get('/questions/count', async (c) => {
    const matiereId = c.req.query('matiere_id');
    const db = getDB(c.env);
    try {
        let countQuery = db.from('questions').select('*', { count: 'exact', head: true });
        if (matiereId) {
            countQuery = countQuery.eq('matiere_id', matiereId);
        }
        const { count, error } = await countQuery;
        if (error)
            return c.json({ error: error.message }, 500);
        return c.json({ success: true, count: count ?? 0 });
    }
    catch (e) {
        return c.json({ error: e.message }, 500);
    }
});
// ── POST /api/questions — Ajouter question avec anti-doublon ───────────
questions.post('/questions', async (c) => {
    const body = await c.req.json();
    const { enonce, serie_id, matiere_id } = body;
    if (!enonce || !matiere_id) {
        return c.json({ error: 'enonce et matiere_id requis' }, 400);
    }
    const db = getDB(c.env);
    // Vérification anti-doublon (même énoncé dans la même série)
    if (serie_id) {
        const { data: existing } = await db
            .from('questions')
            .select('id')
            .eq('serie_id', serie_id)
            .ilike('enonce', enonce.trim())
            .limit(1);
        if (existing && existing.length > 0) {
            return c.json({ error: 'Question en double: cet énoncé existe déjà dans cette série', duplicate: true }, 409);
        }
    }
    // Anti-doublon global dans la même matière
    const { data: globalExisting } = await db
        .from('questions')
        .select('id, serie_id')
        .eq('matiere_id', matiere_id)
        .ilike('enonce', enonce.trim())
        .limit(1);
    if (globalExisting && globalExisting.length > 0) {
        return c.json({ error: 'Question en double: cet énoncé existe déjà dans cette matière', duplicate: true }, 409);
    }
    const { data, error } = await db.from('questions').insert(body).select().single();
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, question: data });
});
// ── DELETE /api/questions/:id — Supprimer une question ─────────
questions.delete('/questions/:id', async (c) => {
    const id = c.req.param('id');
    const db = getDB(c.env);
    const { error } = await db.from('questions').delete().eq('id', id);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, message: 'Question supprimée.' });
});
// ── POST /api/questions/purge-doublons — Supprimer les doublons ──
questions.post('/questions/purge-doublons', async (c) => {
    const db = getDB(c.env);
    try {
        // Récupérer toutes les questions groupées par énoncé + matiere_id
        const { data: allQ, error } = await db
            .from('questions')
            .select('id, enonce, matiere_id, serie_id, created_at')
            .order('created_at', { ascending: true });
        if (error)
            return c.json({ error: error.message }, 500);
        const seen = new Map(); // clé -> premier id
        const toDelete = [];
        for (const q of (allQ ?? [])) {
            const key = `${q.matiere_id}::${q.enonce?.trim().toLowerCase()}`;
            if (seen.has(key)) {
                toDelete.push(q.id);
            }
            else {
                seen.set(key, q.id);
            }
        }
        // Supprimer les doublons par batch
        let deleted = 0;
        for (let i = 0; i < toDelete.length; i += 100) {
            const batch = toDelete.slice(i, i + 100);
            const { error: delErr } = await db.from('questions').delete().in('id', batch);
            if (!delErr)
                deleted += batch.length;
        }
        return c.json({ success: true, doublons_supprimes: deleted, total_analyses: allQ?.length ?? 0 });
    }
    catch (e) {
        return c.json({ error: e.message }, 500);
    }
});
export default questions;
