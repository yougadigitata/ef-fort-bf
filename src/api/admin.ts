import { Hono } from 'hono';
import { getDB, Env } from '../lib/db';
import { verifyJWT } from '../lib/auth';

const admin = new Hono<{ Bindings: Env }>();

async function requireAdmin(c: any, next: any) {
  const h = c.req.header('Authorization');
  if (!h?.startsWith('Bearer ')) return c.json({ error: 'Auth requise.' }, 401);
  const p = await verifyJWT(h.slice(7));
  if (!p || !p['is_admin']) return c.json({ error: 'Accès admin requis.' }, 403);
  c.set('adminId', p['id']);
  await next();
}

admin.get('/stats', requireAdmin, async (c) => {
  const db = getDB(c.env);
  const [{ count: totalUsers }, { count: abonnes }, { count: demandes }, { count: questionsCount }] =
    await Promise.all([
      db.from('profiles').select('*', { count: 'exact', head: true }),
      db.from('profiles').select('*', { count: 'exact', head: true }).eq('abonnement_actif', true),
      db.from('demandes_abonnement').select('*', { count: 'exact', head: true }).eq('statut', 'EN_ATTENTE'),
      db.from('questions').select('*', { count: 'exact', head: true }),
    ]);
  return c.json({ success: true, stats: { totalUsers, abonnes, demandesEnAttente: demandes, totalQuestions: questionsCount } });
});

admin.get('/demandes', requireAdmin, async (c) => {
  const db = getDB(c.env);
  const { data, error } = await db.from('demandes_abonnement')
    .select('*, profiles(nom, prenom, telephone)')
    .order('created_at', { ascending: false });
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, demandes: data });
});

admin.post('/valider/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const db = getDB(c.env);
  const { data: dem } = await db.from('demandes_abonnement').select('user_id').eq('id', id).single();
  if (!dem) return c.json({ error: 'Demande introuvable.' }, 404);
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

admin.get('/users', requireAdmin, async (c) => {
  const db = getDB(c.env);
  const { data, error } = await db.from('profiles')
    .select('id, nom, prenom, telephone, niveau, is_admin, abonnement_actif, created_at')
    .order('created_at', { ascending: false });
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, users: data });
});

admin.post('/questions', requireAdmin, async (c) => {
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps invalide.' }, 400);
  const db = getDB(c.env);

  // Adapter les champs si nécessaire
  const questionData: Record<string, unknown> = {};
  if (body['enonce'] || body['question']) {
    questionData['enonce'] = body['enonce'] ?? body['question'];
  }
  if (body['matiere_id']) questionData['matiere_id'] = body['matiere_id'];
  questionData['option_a'] = body['option_a'];
  questionData['option_b'] = body['option_b'];
  questionData['option_c'] = body['option_c'];
  questionData['option_d'] = body['option_d'];
  questionData['bonne_reponse'] = body['bonne_reponse'];
  questionData['explication'] = body['explication'];
  questionData['difficulte'] = body['difficulte'] ?? 'MOYEN';
  questionData['type'] = 'QCM';

  const { error } = await db.from('questions').insert(questionData);
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, message: 'Question ajoutée.' });
});

admin.post('/actualites', requireAdmin, async (c) => {
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps invalide.' }, 400);
  const db = getDB(c.env);
  const { error } = await db.from('actualites').insert({ ...body, actif: true });
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, message: 'Actualité publiée.' });
});

export default admin;
