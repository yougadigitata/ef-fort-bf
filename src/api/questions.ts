import { Hono } from 'hono';
import { getDB, Env } from '../lib/db';

const questions = new Hono<{ Bindings: Env }>();

// ── GET /api/matieres — 16 matières avec caching ──────────────
questions.get('/matieres', async (c) => {
  const db = getDB(c.env);

  // Récupérer uniquement les 16 matières officielles (triées par ordre)
  const { data: matieres, error: mErr } = await db
    .from('matieres')
    .select('id, nom, code, icone, couleur, ordre')
    .order('ordre', { ascending: true })
    .limit(30);

  if (mErr) return c.json({ error: mErr.message }, 500);

  // Les 16 codes officiels
  const CODES_OFFICIELS = ['DROIT2','ECO2','MATHS','SP','SVT','CG','ACTU','PANA','HISTO','ARMEE','PSYCHO','FR','ANG','INFO','COMM','HG'];

  // Filtrer uniquement les 16 matières officielles
  const matieresFiltrees = (matieres ?? []).filter(m => CODES_OFFICIELS.includes(m.code));

  // Compter les questions par matière (requête unique optimisée)
  const { data: questionsData } = await db
    .from('questions')
    .select('matiere_id')
    .limit(5000);

  const countMap: Record<string, number> = {};
  for (const q of questionsData ?? []) {
    if (q.matiere_id) {
      countMap[q.matiere_id] = (countMap[q.matiere_id] ?? 0) + 1;
    }
  }

  const result = matieresFiltrees.map(m => ({
    id: m.code?.toLowerCase() || m.id,
    nom: m.nom,
    icone: m.icone ?? '📚',
    couleur: m.couleur ?? '#1A5C38',
    nb_questions: countMap[m.id] ?? 0,
    abonne_only: false,
    matiere_id: m.id,
    ordre: m.ordre ?? 99,
  })).sort((a, b) => a.ordre - b.ordre);

  // Headers de cache (5 minutes)
  c.header('Cache-Control', 'public, max-age=300');

  return c.json({ success: true, matieres: result });
});

// ── GET /api/questions — Avec pagination et optimisation ───────
questions.get('/questions', async (c) => {
  const matiereCode = c.req.query('matiere');
  const page = Math.max(1, parseInt(c.req.query('page') ?? '1'));
  const limit = Math.min(parseInt(c.req.query('limit') ?? '20'), 100);
  const offset = (page - 1) * limit;

  const db = getDB(c.env);

  let query = db.from('questions')
    .select('id, matiere_id, enonce, option_a, option_b, option_c, option_d, option_e, bonne_reponse, explication, difficulte');

  // Filtrer par matière si spécifié
  if (matiereCode) {
    const { data: mat } = await db
      .from('matieres')
      .select('id')
      .ilike('code', matiereCode)
      .maybeSingle();

    if (mat) {
      query = query.eq('matiere_id', mat.id) as typeof query;
    }
  }

  // Pagination optimisée
  const { data, error } = await query
    .range(offset, offset + limit - 1)
    .limit(limit);

  if (error) return c.json({ error: error.message }, 500);

  const shuffled = (data ?? [])
    .sort(() => Math.random() - 0.5)
    .map(q => ({
      id: q.id,
      matiere: q.matiere_id,
      question: q.enonce,
      option_a: q.option_a,
      option_b: q.option_b,
      option_c: q.option_c,
      option_d: q.option_d,
      option_e: q.option_e ?? null,
      bonne_reponse: q.bonne_reponse,
      explication: q.explication,
      difficulte: q.difficulte,
    }));

  return c.json({ success: true, questions: shuffled, page, limit });
});

export default questions;
