import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { Env } from './lib/db';
import auth        from './api/auth';
import questions   from './api/questions';
import simulation  from './api/simulation';
import abonnements from './api/abonnements';
import admin       from './api/admin';
import entraide    from './api/entraide';
import { getDB }   from './lib/db';
import { verifyJWT } from './lib/auth';

const app = new Hono<{ Bindings: Env }>();

// CORS — autoriser toutes les origines (Flutter Web + mobile)
app.use('/api/*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}));

// Routes
app.route('/api/auth',         auth);
app.route('/api',              questions);     // /api/matieres + /api/questions
app.route('/api/simulation',   simulation);
app.route('/api/abonnements',  abonnements);
app.route('/api/admin',        admin);
app.route('/api/entraide',     entraide);

// GET /api/actualites
app.get('/api/actualites', async (c) => {
  const db = getDB(c.env);
  const { data, error } = await db.from('actualites')
    .select('*').eq('actif', true).order('created_at', { ascending: false });
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, actualites: data });
});

// ── TÂCHE 4 : GET /api/user/stats — Stats dashboard utilisateur ──
app.get('/api/user/stats', async (c) => {
  const h = c.req.header('Authorization');
  if (!h?.startsWith('Bearer ')) return c.json({ error: 'Auth requise.' }, 401);
  const p = await verifyJWT(h.slice(7));
  if (!p) return c.json({ error: 'Token invalide.' }, 401);
  const userId = p['id'] as string;

  const db = getDB(c.env);

  try {
    // Compter les simulations terminées
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
      .eq('termine', true)
      .order('created_at', { ascending: false })
      .limit(20);

    const avgScore = sessions && sessions.length > 0
      ? sessions.reduce((sum: number, s: any) => sum + (Number(s.score_pourcentage) || 0), 0) / sessions.length
      : 0;

    const nbSim = nbSimulations ?? 0;

    return c.json({
      success: true,
      nb_simulations: nbSim,
      score_moyen: Math.round(avgScore * 10) / 10,
      questions_repondues: nbSim * 50,
    });
  } catch (e: any) {
    return c.json({
      success: false,
      nb_simulations: 0,
      score_moyen: 0,
      questions_repondues: 0,
      error: e.message,
    });
  }
});

// Health check
app.get('/api/health', (c) => c.json({
  status: 'ok',
  app: 'EF-FORT.BF API',
  version: '3.0.0',
  timestamp: new Date().toISOString(),
}));

// 404
app.notFound((c) => c.json({ error: 'Route introuvable.' }, 404));

export default app;
