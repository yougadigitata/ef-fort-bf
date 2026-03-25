import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { Env } from './lib/db';
import auth        from './api/auth';
import questions   from './api/questions';
import simulation  from './api/simulation';
import abonnements from './api/abonnements';
import admin       from './api/admin';
import { getDB }   from './lib/db';

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

// GET /api/actualites
app.get('/api/actualites', async (c) => {
  const db = getDB(c.env);
  const { data, error } = await db.from('actualites')
    .select('*').eq('actif', true).order('created_at', { ascending: false });
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, actualites: data });
});

// Health check
app.get('/api/health', (c) => c.json({
  status: 'ok',
  app: 'EF-FORT.BF API',
  version: '2.0.0',
  timestamp: new Date().toISOString(),
}));

// 404
app.notFound((c) => c.json({ error: 'Route introuvable.' }, 404));

export default app;
