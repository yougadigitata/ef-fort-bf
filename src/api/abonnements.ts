import { Hono } from 'hono';
import { getDB, Env } from '../lib/db';
import { verifyJWT } from '../lib/auth';

const abonnements = new Hono<{ Bindings: Env }>();

async function requireAuth(c: any, next: any) {
  const h = c.req.header('Authorization');
  if (!h?.startsWith('Bearer ')) return c.json({ error: 'Auth requise.' }, 401);
  const p = await verifyJWT(h.slice(7));
  if (!p) return c.json({ error: 'Token invalide.' }, 401);
  c.set('userId', p['id']);
  await next();
}

// ── POST /api/abonnements/demande ────────────────────────────
abonnements.post('/demande', requireAuth, async (c) => {
  const userId = c.get('userId') as string;
  const body = await c.req.json().catch(() => ({})) as Record<string, unknown>;
  const moyen_paiement = body['moyen_paiement'] as string ?? 'Orange Money';

  const db = getDB(c.env);
  const { data: user } = await db
    .from('profiles').select('nom, prenom, telephone').eq('id', userId).single();
  if (!user) return c.json({ error: 'Utilisateur introuvable.' }, 404);

  const { error } = await db.from('demandes_abonnement').insert({
    user_id: userId,
    nom_complet: `${user.prenom} ${user.nom}`,
    telephone: user.telephone,
    moyen_paiement: moyen_paiement,
    statut: 'EN_ATTENTE',
  });
  if (error) return c.json({ error: error.message }, 500);

  return c.json({
    success: true,
    message: 'Demande enregistrée. Marc va valider votre paiement sous peu. WhatsApp : 65 46 70 70',
  });
});

// ── GET /api/abonnements/statut ──────────────────────────────
abonnements.get('/statut', requireAuth, async (c) => {
  const userId = c.get('userId') as string;
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
