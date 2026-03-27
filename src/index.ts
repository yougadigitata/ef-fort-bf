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

// ── GET /api/actualites ──
app.get('/api/actualites', async (c) => {
  const db = getDB(c.env);
  const { data, error } = await db.from('actualites')
    .select('*').eq('actif', true).order('created_at', { ascending: false }).limit(20);
  if (error) return c.json({ error: error.message }, 500);
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
  } catch (_) {}

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
app.get('/api/examens/:id/questions', async (c) => {
  const examenId = c.req.param('id');
  const db = getDB(c.env);

  // Récupérer 50 questions aléatoires toutes matières confondues
  const { data, error } = await db
    .from('questions')
    .select('id, matiere_id, enonce, option_a, option_b, option_c, option_d, option_e, bonne_reponse, explication, difficulte')
    .limit(200);

  if (error) return c.json({ error: error.message }, 500);

  const shuffled = (data ?? [])
    .sort(() => Math.random() - 0.5)
    .slice(0, 50)
    .map(q => ({
      id: q.id,
      examen_id: examenId,
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

  return c.json({ success: true, questions: shuffled });
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
  version: '4.0.0',
  timestamp: new Date().toISOString(),
  features: ['16-matieres', '10-examens', 'simulation', 'entraide'],
}));

// 404
app.notFound((c) => c.json({ error: 'Route introuvable.' }, 404));

export default app;
