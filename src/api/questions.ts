import { Hono } from 'hono';
import { getDB, Env } from '../lib/db';

const questions = new Hono<{ Bindings: Env }>();

// ── GET /api/matieres ────────────────────────────────────────
questions.get('/matieres', async (c) => {
  const db = getDB(c.env);

  // Récupérer les matières existantes
  const { data: matieres, error: mErr } = await db
    .from('matieres')
    .select('id, nom, code, icone, couleur');

  if (mErr) return c.json({ error: mErr.message }, 500);

  // Compter les questions par matière
  const { data: questionsData } = await db
    .from('questions')
    .select('matiere_id');

  const countMap: Record<string, number> = {};
  for (const q of questionsData ?? []) {
    if (q.matiere_id) {
      countMap[q.matiere_id] = (countMap[q.matiere_id] ?? 0) + 1;
    }
  }

  const result = (matieres ?? []).map(m => ({
    id: m.code?.toLowerCase() || m.id,
    nom: m.nom,
    icone: m.icone ?? '📚',
    couleur: m.couleur ?? '#1A5C38',
    nb_questions: countMap[m.id] ?? 0,
    abonne_only: false,
    matiere_id: m.id,
  }));

  return c.json({ success: true, matieres: result });
});

// ── GET /api/questions ───────────────────────────────────────
questions.get('/questions', async (c) => {
  const matiereCode = c.req.query('matiere');
  const limit = Math.min(parseInt(c.req.query('limit') ?? '30'), 100);

  const db = getDB(c.env);

  let query = db.from('questions')
    .select('id, matiere_id, enonce, option_a, option_b, option_c, option_d, bonne_reponse, explication, difficulte');

  // Si on filtre par matière (code), résoudre l'id
  if (matiereCode) {
    // Chercher l'id de la matière par code
    const { data: mat } = await db
      .from('matieres')
      .select('id')
      .ilike('code', matiereCode)
      .maybeSingle();

    if (mat) {
      query = query.eq('matiere_id', mat.id) as typeof query;
    }
  }

  const { data, error } = await query.limit(limit);
  if (error) return c.json({ error: error.message }, 500);

  // Mapper vers la structure attendue par le frontend
  const shuffled = (data ?? [])
    .sort(() => Math.random() - 0.5)
    .map(q => ({
      id: q.id,
      matiere: q.matiere_id,
      question: q.enonce,     // Adapter le champ
      option_a: q.option_a,
      option_b: q.option_b,
      option_c: q.option_c,
      option_d: q.option_d,
      bonne_reponse: q.bonne_reponse,
      explication: q.explication,
      difficulte: q.difficulte,
    }));

  return c.json({ success: true, questions: shuffled });
});

export default questions;
