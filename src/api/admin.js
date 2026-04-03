import { Hono } from 'hono';
import { getDB } from '../lib/db';
import { verifyJWT } from '../lib/auth';
const admin = new Hono();
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
// ═══════════════════════════════════════════════════════════════
// GET /api/admin/stats — VERSION CORRIGÉE (stats ne restent plus à 0)
// ═══════════════════════════════════════════════════════════════
admin.get('/stats', requireAdmin, async (c) => {
    const db = getDB(c.env);
    try {
        // Compter correctement avec Supabase (count exact)
        const { count: totalUsers } = await db
            .from('profiles')
            .select('*', { count: 'exact', head: true });
        const { count: abonnes } = await db
            .from('profiles')
            .select('*', { count: 'exact', head: true })
            .eq('abonnement_actif', true);
        const { count: demandesEnAttente } = await db
            .from('demandes_abonnement')
            .select('*', { count: 'exact', head: true })
            .eq('statut', 'EN_ATTENTE');
        const { count: totalQuestions } = await db
            .from('questions')
            .select('*', { count: 'exact', head: true });
        const { count: totalSimulations } = await db
            .from('sessions_examen')
            .select('*', { count: 'exact', head: true })
            .eq('termine', true);
        const { count: totalActualites } = await db
            .from('actualites')
            .select('*', { count: 'exact', head: true })
            .eq('actif', true);
        // Compter les messages d'entraide si la table existe
        let messagesEntraide = 0;
        try {
            const { count: msgCount } = await db
                .from('messages_entraide')
                .select('*', { count: 'exact', head: true })
                .eq('actif', true);
            messagesEntraide = msgCount ?? 0;
        }
        catch (_) {
            messagesEntraide = 0;
        }
        return c.json({
            success: true,
            stats: {
                totalUsers: totalUsers ?? 0,
                total_users: totalUsers ?? 0,
                abonnes: abonnes ?? 0,
                total_abonnes: abonnes ?? 0,
                demandesEnAttente: demandesEnAttente ?? 0,
                demandes_en_attente: demandesEnAttente ?? 0,
                totalQuestions: totalQuestions ?? 0,
                total_questions: totalQuestions ?? 0,
                totalSimulations: totalSimulations ?? 0,
                total_sessions: totalSimulations ?? 0,
                totalActualites: totalActualites ?? 0,
                total_actualites: totalActualites ?? 0,
                messagesEntraide: messagesEntraide,
            }
        });
    }
    catch (error) {
        return c.json({ error: error.message }, 500);
    }
});
admin.get('/demandes', requireAdmin, async (c) => {
    const db = getDB(c.env);
    const { data, error } = await db.from('demandes_abonnement')
        .select('*, profiles(nom, prenom, telephone)')
        .order('created_at', { ascending: false });
    if (error)
        return c.json({ error: error.message }, 500);
    // Transformer les données pour l'affichage
    const demandes = (data || []).map((d) => ({
        ...d,
        nom_complet: d.profiles ? `${d.profiles.prenom} ${d.profiles.nom}` : 'Inconnu',
        telephone: d.profiles?.telephone || '',
    }));
    return c.json({ success: true, demandes });
});
admin.post('/valider/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const db = getDB(c.env);
    const { data: dem } = await db.from('demandes_abonnement').select('user_id').eq('id', id).single();
    if (!dem)
        return c.json({ error: 'Demande introuvable.' }, 404);
    await db.from('demandes_abonnement').update({ statut: 'VALIDE' }).eq('id', id);
    await db.from('profiles').update({
        abonnement_actif: true,
        abonnement_fin: '2028-12-31',
        abonnement_debut: new Date().toISOString().split('T')[0],
        abonnement_type: 'premium',
    }).eq('id', dem.user_id);
    return c.json({ success: true, message: 'Abonnement activé.' });
});
admin.post('/rejeter/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const db = getDB(c.env);
    await db.from('demandes_abonnement').update({ statut: 'REJETE' }).eq('id', id);
    return c.json({ success: true, message: 'Demande rejetée.' });
});
// ── GET /api/admin/demandes-abonnement (alias compatible panel) ──
admin.get('/demandes-abonnement', requireAdmin, async (c) => {
    const db = getDB(c.env);
    const { data, error } = await db.from('demandes_abonnement')
        .select('*, profiles(nom, prenom, telephone)')
        .order('created_at', { ascending: false });
    if (error)
        return c.json({ error: error.message }, 500);
    const demandes = (data || []).map((d) => ({
        ...d,
        nom_complet: d.profiles ? `${d.profiles.prenom} ${d.profiles.nom}` : 'Inconnu',
        telephone: d.profiles?.telephone || '',
    }));
    return c.json({ success: true, demandes });
});
// ── POST /api/admin/valider-abonnement/:id ────────────────────
admin.post('/valider-abonnement/:id', requireAdmin, async (c) => {
    const id = c.req.param('id');
    const db = getDB(c.env);
    const body = await c.req.json().catch(() => ({}));
    const statut = body['statut'] || 'VALIDE';
    if (statut === 'REJETE') {
        await db.from('demandes_abonnement').update({ statut: 'REJETE' }).eq('id', id);
        return c.json({ success: true, message: 'Demande rejetée.' });
    }
    const { data: dem } = await db.from('demandes_abonnement').select('user_id').eq('id', id).single();
    if (!dem)
        return c.json({ error: 'Demande introuvable.' }, 404);
    await db.from('demandes_abonnement').update({ statut: 'VALIDE' }).eq('id', id);
    await db.from('profiles').update({
        abonnement_actif: true,
        abonnement_fin: '2028-12-31',
        abonnement_debut: new Date().toISOString().split('T')[0],
        abonnement_type: 'premium',
    }).eq('id', dem.user_id);
    return c.json({ success: true, message: 'Abonnement activé.' });
});
// ── POST /api/admin/change-password ───────────────────────────
admin.post('/change-password', requireAdmin, async (c) => {
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    const currentPassword = body['current_password'];
    const newPassword = body['new_password'];
    if (!currentPassword || !newPassword) {
        return c.json({ error: 'Mot de passe actuel et nouveau requis.' }, 400);
    }
    if (newPassword.length < 8) {
        return c.json({ error: 'Le nouveau mot de passe doit faire au moins 8 caractères.' }, 400);
    }
    if (!/[A-Z]/.test(newPassword)) {
        return c.json({ error: 'Le nouveau mot de passe doit contenir au moins une majuscule.' }, 400);
    }
    if (!/[0-9]/.test(newPassword)) {
        return c.json({ error: 'Le nouveau mot de passe doit contenir au moins un chiffre.' }, 400);
    }
    const db = getDB(c.env);
    const h = c.req.header('Authorization');
    const payload = await verifyJWT(h.slice(7));
    const adminId = payload?.id;
    // Vérifier le mot de passe actuel
    const { data: profile } = await db.from('profiles')
        .select('id, telephone, password_hash')
        .eq('id', adminId)
        .single();
    if (!profile)
        return c.json({ error: 'Utilisateur introuvable.' }, 404);
    // Hash le nouveau mot de passe (SHA-256 simple compatible avec auth.ts)
    const encoder = new TextEncoder();
    const hashBuf = await crypto.subtle.digest('SHA-256', encoder.encode(currentPassword));
    const currentHash = Array.from(new Uint8Array(hashBuf)).map(b => b.toString(16).padStart(2, '0')).join('');
    if (profile.password_hash !== currentHash) {
        return c.json({ error: 'Mot de passe actuel incorrect.' }, 401);
    }
    // Hash du nouveau mot de passe
    const newHashBuf = await crypto.subtle.digest('SHA-256', encoder.encode(newPassword));
    const newHash = Array.from(new Uint8Array(newHashBuf)).map(b => b.toString(16).padStart(2, '0')).join('');
    const { error: updateErr } = await db.from('profiles')
        .update({ password_hash: newHash })
        .eq('id', adminId);
    if (updateErr)
        return c.json({ error: updateErr.message }, 500);
    return c.json({ success: true, message: 'Mot de passe modifié avec succès.' });
});
admin.get('/users', requireAdmin, async (c) => {
    const db = getDB(c.env);
    const { data, error } = await db.from('profiles')
        .select('id, nom, prenom, telephone, niveau, is_admin, abonnement_actif, created_at')
        .order('created_at', { ascending: false });
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, users: data });
});
admin.post('/questions', requireAdmin, async (c) => {
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    const db = getDB(c.env);
    const questionData = {
        enonce: body['enonce'] ?? body['question'],
        option_a: body['option_a'],
        option_b: body['option_b'],
        option_c: body['option_c'],
        option_d: body['option_d'],
        bonne_reponse: body['bonne_reponse'],
        explication: body['explication'],
        difficulte: body['difficulte'] ?? 'MOYEN',
        type: 'QCM',
    };
    if (body['matiere_id']) {
        questionData['matiere_id'] = body['matiere_id'];
    }
    if (body['numero']) {
        questionData['numero'] = body['numero'];
    }
    else {
        // Auto-incrément numéro
        const { data: last } = await db.from('questions').select('numero').order('numero', { ascending: false }).limit(1);
        questionData['numero'] = last && last[0] ? (last[0].numero + 1) : 1;
    }
    const { error } = await db.from('questions').insert(questionData);
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({ success: true, message: 'Question ajoutée.' });
});
admin.post('/actualites', requireAdmin, async (c) => {
    const body = await c.req.json().catch(() => null);
    if (!body)
        return c.json({ error: 'Corps invalide.' }, 400);
    // Valider les champs requis
    if (!body['titre'] || !body['contenu']) {
        return c.json({ error: 'Titre et contenu requis.' }, 400);
    }
    const db = getDB(c.env);
    // Construire l'objet avec uniquement les colonnes existantes de la table actualites
    // (id, titre, contenu, categorie, actif, created_at)
    const actualiteData = {
        titre: String(body['titre']).trim(),
        contenu: String(body['contenu']).trim(),
        categorie: body['categorie'] || 'ACTUALITE',
        actif: true,
    };
    // Si la colonne couleur_fond existe, l'ajouter (migration future)
    // Pour l'instant on l'ignore pour éviter l'erreur 42703
    const { error } = await db.from('actualites').insert(actualiteData);
    if (error) {
        // Log l'erreur pour debug
        console.error('Erreur insert actualite:', error.message);
        return c.json({ error: `Erreur base de données: ${error.message}` }, 500);
    }
    return c.json({ success: true, message: 'Actualité publiée avec succès.' });
});
// ── POST /api/admin/migrate — Créer les tables manquantes ────
// Endpoint de migration sécurisé — NE PAS SUPPRIMER (utilisé par setup)
admin.post('/migrate', async (c) => {
    const body = await c.req.json().catch(() => ({}));
    if (body['secret'] !== 'EfFortAdmin2026!BF') {
        return c.json({ error: 'Secret invalide.' }, 403);
    }
    const db = getDB(c.env);
    const results = {};
    // ── 1. Créer table messages_entraide (via insertions conditionnelles) ──
    // On utilise l'API Supabase pour tester et créer la table
    try {
        const { error: testError } = await db
            .from('messages_entraide')
            .select('id')
            .limit(1);
        if (testError && (testError.code === '42P01' || testError.message.includes('does not exist'))) {
            // La table n'existe pas — on ne peut pas la créer via REST API
            // Retourner les SQLs à exécuter manuellement
            results['messages_entraide'] = 'TABLE_MISSING_NEEDS_MANUAL_SQL';
        }
        else if (testError) {
            results['messages_entraide'] = `error: ${testError.message}`;
        }
        else {
            results['messages_entraide'] = 'exists';
        }
    }
    catch (e) {
        results['messages_entraide'] = `exception: ${e.message}`;
    }
    // ── 2. Vérifier table resultats ──
    try {
        const { error: testError2 } = await db
            .from('resultats')
            .select('id')
            .limit(1);
        if (testError2 && (testError2.code === '42P01' || testError2.message.includes('does not exist'))) {
            results['resultats'] = 'TABLE_MISSING_NEEDS_MANUAL_SQL';
        }
        else if (testError2) {
            results['resultats'] = `error: ${testError2.message}`;
        }
        else {
            results['resultats'] = 'exists';
        }
    }
    catch (e) {
        results['resultats'] = `exception: ${e.message}`;
    }
    // ── 3. Retourner les SQLs nécessaires si tables manquantes ──
    const sqlsNeeded = [];
    if (results['messages_entraide'] === 'TABLE_MISSING_NEEDS_MANUAL_SQL') {
        sqlsNeeded.push(`
CREATE TABLE IF NOT EXISTS public.messages_entraide (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  contenu TEXT NOT NULL,
  partage_whatsapp BOOLEAN DEFAULT false,
  telephone_partage VARCHAR(20),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  actif BOOLEAN DEFAULT true
);
ALTER TABLE public.messages_entraide ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lire messages actifs" ON public.messages_entraide FOR SELECT USING (actif = true);
CREATE POLICY "Inserer message" ON public.messages_entraide FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Supprimer message" ON public.messages_entraide FOR DELETE USING (auth.uid() = user_id);
    `.trim());
    }
    if (results['resultats'] === 'TABLE_MISSING_NEEDS_MANUAL_SQL') {
        sqlsNeeded.push(`
CREATE TABLE IF NOT EXISTS public.resultats (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id UUID DEFAULT gen_random_uuid(),
  matiere VARCHAR(100),
  type_session VARCHAR(50) DEFAULT 'serie',
  nb_questions INTEGER DEFAULT 0,
  nb_correctes INTEGER DEFAULT 0,
  nb_incorrectes INTEGER DEFAULT 0,
  nb_sautees INTEGER DEFAULT 0,
  score_pourcentage DECIMAL(5,2) DEFAULT 0,
  duree_secondes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.resultats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Voir ses resultats" ON public.resultats FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Inserer ses resultats" ON public.resultats FOR INSERT WITH CHECK (auth.uid() = user_id);
    `.trim());
    }
    return c.json({
        success: true,
        tables_status: results,
        sqls_to_run: sqlsNeeded,
        message: sqlsNeeded.length > 0
            ? 'Tables manquantes détectées. Exécutez les SQLs fournis dans Supabase Dashboard > SQL Editor.'
            : 'Toutes les tables sont en place.',
    });
});
// ── GET /api/admin/user-stats/:userId — Stats dashboard utilisateur ──
admin.get('/user-stats/:userId', requireAdmin, async (c) => {
    const userId = c.req.param('userId');
    const db = getDB(c.env);
    try {
        // Sessions examen
        const { count: nbSimulations } = await db
            .from('sessions_examen')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', userId)
            .eq('termine', true);
        // Score moyen des simulations
        const { data: sessions } = await db
            .from('sessions_examen')
            .select('score_pourcentage')
            .eq('user_id', userId)
            .eq('termine', true);
        const avgScore = sessions && sessions.length > 0
            ? sessions.reduce((sum, s) => sum + (s.score_pourcentage || 0), 0) / sessions.length
            : 0;
        return c.json({
            success: true,
            stats: {
                nb_simulations: nbSimulations ?? 0,
                score_moyen: Math.round(avgScore * 10) / 10,
                questions_repondues: (nbSimulations ?? 0) * 50,
            }
        });
    }
    catch (e) {
        return c.json({ error: e.message }, 500);
    }
});
export default admin;
