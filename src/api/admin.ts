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
    } catch (_) {
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
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

admin.get('/demandes', requireAdmin, async (c) => {
  const db = getDB(c.env);
  const { data, error } = await db.from('demandes_abonnement')
    .select('*, profiles(nom, prenom, telephone)')
    .order('created_at', { ascending: false });
  if (error) return c.json({ error: error.message }, 500);

  // Transformer les données pour l'affichage
  const demandes = (data || []).map((d: any) => ({
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

  const questionData: Record<string, unknown> = {
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
  } else {
    // Auto-incrément numéro
    const { data: last } = await db.from('questions').select('numero').order('numero', { ascending: false }).limit(1);
    questionData['numero'] = last && last[0] ? (last[0].numero + 1) : 1;
  }

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
