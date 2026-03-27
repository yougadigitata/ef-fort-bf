import { Hono } from 'hono';
import { getDB } from '../lib/db';
import { verifyJWT } from '../lib/auth';
const abonnements = new Hono();
async function requireAuth(c, next) {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const p = await verifyJWT(h.slice(7));
    if (!p)
        return c.json({ error: 'Token invalide.' }, 401);
    const context = c;
    context.userId = p['id'];
    await next();
}
// ── POST /api/abonnements/demande ───────────────────────────
abonnements.post('/demande', requireAuth, async (c) => {
    const context = c;
    const userId = context.userId;
    const body = await c.req.json().catch(() => ({}));
    const moyen_paiement = body['moyen_paiement'] ?? 'Orange Money';
    const db = getDB(c.env);
    const { data: user } = await db
        .from('profiles').select('nom, prenom, telephone, abonnement_actif').eq('id', userId).single();
    if (!user)
        return c.json({ error: 'Utilisateur introuvable.' }, 404);
    // ── TÂCHE 5 : Vérifier si l'utilisateur est déjà abonné ──
    if (user.abonnement_actif === true) {
        return c.json({
            success: false,
            already_subscribed: true,
            error: 'Votre abonnement est déjà actif. Profitez de toutes les fonctionnalités premium !',
        }, 409);
    }
    // ── TÂCHE 5 : Bloquer les demandes en double ──
    const { count: existingCount } = await db
        .from('demandes_abonnement')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('statut', 'EN_ATTENTE');
    if (existingCount && existingCount > 0) {
        return c.json({
            success: false,
            pending: true,
            error: 'Votre demande est déjà en cours de traitement. Notre équipe va vous contacter très prochainement.',
        }, 409);
    }
    const { error } = await db.from('demandes_abonnement').insert({
        user_id: userId,
        nom_complet: `${user.prenom} ${user.nom}`,
        telephone: user.telephone,
        moyen_paiement: moyen_paiement,
        statut: 'EN_ATTENTE',
    });
    if (error)
        return c.json({ error: error.message }, 500);
    return c.json({
        success: true,
        message: 'Demande enregistrée. Notre équipe EF-FORT va valider votre paiement rapidement. WhatsApp : 65 46 70 70',
    });
});
// ── GET /api/abonnements/statut ───────────────────────────
abonnements.get('/statut', requireAuth, async (c) => {
    const context = c;
    const userId = context.userId;
    const db = getDB(c.env);
    const { data: user } = await db
        .from('profiles')
        .select('abonnement_actif, abonnement_fin')
        .eq('id', userId).single();
    return c.json({
        success: true,
        abonnement_actif: user?.abonnement_actif ?? false,
        abonnement_date: user?.abonnement_fin ?? null,
        expiration: '2028-12-31',
    });
});
export default abonnements;
