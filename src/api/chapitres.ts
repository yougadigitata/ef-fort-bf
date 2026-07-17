import { Hono } from 'hono';
import { Env, getDB } from '../lib/db';

// ══════════════════════════════════════════════════════════════
// API CHAPITRES & LEÇONS — EF-FORT.BF e-learning v2.0
// Routes:
//   GET  /api/cours/chapitres?matiere_id=xxx
//   GET  /api/cours/chapitres/:id
//   GET  /api/cours/lecons/:id
//   POST /api/cours/lecons/:id/terminer
//   GET  /api/cours/progression?matiere_id=xxx
// ══════════════════════════════════════════════════════════════

const cours = new Hono<{ Bindings: Env }>();

// GET /api/cours/chapitres — Liste des chapitres d'une matière
cours.get('/chapitres', async (c) => {
  const matiereId = c.req.query('matiere_id');
  if (!matiereId) return c.json({ error: 'matiere_id requis' }, 400);

  const db = getDB(c.env);
  const { data, error } = await db
    .from('chapitres')
    .select('id, matiere_id, titre, description, ordre, created_at')
    .eq('matiere_id', matiereId)
    .order('ordre', { ascending: true });

  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, chapitres: data ?? [] });
});

// GET /api/cours/chapitres/:id — Détail d'un chapitre avec ses leçons
cours.get('/chapitres/:id', async (c) => {
  const id = c.req.param('id');
  const db = getDB(c.env);

  const { data: chapitre, error: chapErr } = await db
    .from('chapitres')
    .select('id, matiere_id, titre, description, ordre')
    .eq('id', id)
    .single();

  if (chapErr) return c.json({ error: chapErr.message }, 500);
  if (!chapitre) return c.json({ error: 'Chapitre non trouvé' }, 404);

  const { data: lecons, error: lecErr } = await db
    .from('lecons')
    .select('id, titre, contenu, video_url, ordre, duree_minutes')
    .eq('chapitre_id', id)
    .order('ordre', { ascending: true });

  if (lecErr) return c.json({ error: lecErr.message }, 500);

  return c.json({
    success: true,
    chapitre: {
      ...chapitre,
      lecons: lecons ?? [],
    },
  });
});

// GET /api/cours/lecons/:id — Contenu d'une leçon
cours.get('/lecons/:id', async (c) => {
  const id = c.req.param('id');
  const db = getDB(c.env);

  const { data, error } = await db
    .from('lecons')
    .select('id, chapitre_id, titre, contenu, video_url, ordre, duree_minutes')
    .eq('id', id)
    .single();

  if (error) return c.json({ error: error.message }, 500);
  if (!data) return c.json({ error: 'Leçon non trouvée' }, 404);

  return c.json({ success: true, lecon: data });
});

// POST /api/cours/lecons/:id/terminer — Marquer une leçon comme terminée
cours.post('/lecons/:id/terminer', async (c) => {
  const leconId = c.req.param('id');
  const authH = c.req.header('Authorization');
  if (!authH?.startsWith('Bearer ')) return c.json({ error: 'Auth requise' }, 401);

  const { verifyJWT } = await import('../lib/auth');
  const payload = await verifyJWT(authH.slice(7));
  if (!payload) return c.json({ error: 'Token invalide' }, 401);
  const userId = (payload as any).id as string;

  const db = getDB(c.env);

  // Vérifier si la progression existe déjà
  const { data: existing } = await db
    .from('user_progress_lecon')
    .select('id, termine')
    .eq('user_id', userId)
    .eq('lecon_id', leconId)
    .single();

  if (existing) {
    // Mettre à jour
    const { error } = await db
      .from('user_progress_lecon')
      .update({ termine: true, date_termine: new Date().toISOString() })
      .eq('id', existing.id);
    if (error) return c.json({ error: error.message }, 500);
  } else {
    // Créer nouvelle entrée
    const { error } = await db
      .from('user_progress_lecon')
      .insert({
        user_id: userId,
        lecon_id: leconId,
        termine: true,
        date_termine: new Date().toISOString(),
      });
    if (error) return c.json({ error: error.message }, 500);
  }

  return c.json({ success: true, message: 'Leçon marquée comme terminée' });
});

// GET /api/cours/progression — Progression de l'utilisateur par matière
cours.get('/progression', async (c) => {
  const matiereId = c.req.query('matiere_id');
  const authH = c.req.header('Authorization');
  if (!authH?.startsWith('Bearer ')) return c.json({ lecons_terminees: [], pourcentage: 0 });

  const { verifyJWT } = await import('../lib/auth');
  const payload = await verifyJWT(authH.slice(7));
  if (!payload) return c.json({ lecons_terminees: [], pourcentage: 0 });
  const userId = (payload as any).id as string;

  const db = getDB(c.env);

  // Récupérer toutes les leçons terminées de l'utilisateur
  let query = db
    .from('user_progress_lecon')
    .select('lecon_id, termine, date_termine')
    .eq('user_id', userId)
    .eq('termine', true);

  const { data: progress, error } = await query;
  if (error) return c.json({ lecons_terminees: [], pourcentage: 0 });

  const leconsTerminees = (progress ?? []).map((p: any) => p.lecon_id);

  // Si matiere_id, calculer le pourcentage
  let pourcentage = 0;
  if (matiereId) {
    const { data: chapitres } = await db
      .from('chapitres')
      .select('id')
      .eq('matiere_id', matiereId);

    if (chapitres && chapitres.length > 0) {
      const chapitreIds = chapitres.map((ch: any) => ch.id);
      const { data: lecons } = await db
        .from('lecons')
        .select('id')
        .in('chapitre_id', chapitreIds);

      const totalLecons = lecons?.length ?? 0;
      if (totalLecons > 0) {
        const termineesCount = (lecons ?? []).filter((l: any) =>
          leconsTerminees.includes(l.id)
        ).length;
        pourcentage = Math.round((termineesCount / totalLecons) * 100);
      }
    }
  }

  return c.json({
    lecons_terminees: leconsTerminees,
    pourcentage,
  });
});

// ── POST /api/cours/migrate — Créer les tables e-learning (admin seulement)
cours.post('/migrate', async (c) => {
  const authH = c.req.header('Authorization');
  if (!authH?.startsWith('Bearer ')) return c.json({ error: 'Auth requise' }, 401);
  const { verifyJWT } = await import('../lib/auth');
  const payload = await verifyJWT(authH.slice(7));
  if (!payload || !payload['is_admin']) return c.json({ error: 'Admin requis' }, 403);

  const supabaseUrl = (c.env as any).SUPABASE_URL || 'https://xqifdbgqxyrlhrkwlyir.supabase.co';
  const serviceKey = (c.env as any).SUPABASE_KEY || '';
  const results: any[] = [];

  // Utiliser pg_meta pour créer les tables
  const tablesResp = await fetch(`${supabaseUrl}/pg-meta/v1/tables?schemas=public&limit=100`, {
    headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` },
  });

  let tablesData: any[] = [];
  if (tablesResp.ok) {
    tablesData = await tablesResp.json() as any[];
    results.push({ step: 'pg_meta_tables', status: '✅', count: tablesData.length });
  } else {
    results.push({ step: 'pg_meta_tables', status: '❌', error: tablesResp.status });
  }

  const existingTables = tablesData.map((t: any) => t.name);

  // Créer la table chapitres si elle n'existe pas
  if (!existingTables.includes('chapitres')) {
    const resp = await fetch(`${supabaseUrl}/pg-meta/v1/tables`, {
      method: 'POST',
      headers: {
        'apikey': serviceKey,
        'Authorization': `Bearer ${serviceKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: 'chapitres',
        schema: 'public',
        comment: 'Chapitres des cours e-learning',
        rls_enabled: true,
      }),
    });
    results.push({ step: 'create_chapitres', status: resp.ok ? '✅' : `⚠️ ${resp.status}` });
  } else {
    results.push({ step: 'create_chapitres', status: '✅ déjà existante' });
  }

  // Retourner le SQL pour exécution manuelle si pg_meta échoue
  const sqlManuel = `
-- À exécuter dans Supabase SQL Editor
-- https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new

CREATE TABLE IF NOT EXISTS public.chapitres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    matiere_id UUID NOT NULL REFERENCES public.matieres(id) ON DELETE CASCADE,
    titre TEXT NOT NULL,
    description TEXT,
    ordre INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.lecons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chapitre_id UUID NOT NULL REFERENCES public.chapitres(id) ON DELETE CASCADE,
    titre TEXT NOT NULL,
    contenu TEXT,
    video_url TEXT,
    ordre INTEGER NOT NULL DEFAULT 0,
    duree_minutes INTEGER DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS chapitre_id UUID REFERENCES public.chapitres(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS public.user_progress_lecon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    lecon_id UUID NOT NULL REFERENCES public.lecons(id) ON DELETE CASCADE,
    termine BOOLEAN DEFAULT FALSE,
    date_termine TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, lecon_id)
);

CREATE INDEX IF NOT EXISTS idx_chapitres_matiere ON public.chapitres(matiere_id);
CREATE INDEX IF NOT EXISTS idx_lecons_chapitre ON public.lecons(chapitre_id);
CREATE INDEX IF NOT EXISTS idx_questions_chapitre ON public.questions(chapitre_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_lecon_user ON public.user_progress_lecon(user_id);

ALTER TABLE public.chapitres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lecons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress_lecon ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS chapitres_select_all ON public.chapitres FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS lecons_select_all ON public.lecons FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS user_progress_lecon_all ON public.user_progress_lecon USING (true) WITH CHECK (true);
  `.trim();

  return c.json({
    success: true,
    results,
    sql_manuel: sqlManuel,
    sql_editor_url: 'https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new',
    message: 'Exécutez le SQL ci-dessus dans Supabase SQL Editor pour créer les tables e-learning',
  });
});

export default cours;

// ── POST /api/cours/init-tables — Init tables via pg_meta depuis le Worker
cours.post('/init-tables', async (c) => {
  const authH = c.req.header('Authorization');
  if (!authH?.startsWith('Bearer ')) return c.json({ error: 'Auth requise' }, 401);
  const { verifyJWT } = await import('../lib/auth');
  const payload = await verifyJWT(authH.slice(7));
  if (!payload || !payload['is_admin']) return c.json({ error: 'Admin requis' }, 403);

  const supabaseUrl = (c.env as any).SUPABASE_URL || 'https://xqifdbgqxyrlhrkwlyir.supabase.co';
  const serviceKey = (c.env as any).SUPABASE_KEY || '';

  const results: any[] = [];

  // Essai 1: pg_meta via le worker (accessible depuis Cloudflare)
  const pgMetaEndpoints = [
    `${supabaseUrl}/pg-meta/v1/tables`,
    `${supabaseUrl}/pg/meta/v0/tables`,
  ];

  let pgMetaWorks = false;
  for (const ep of pgMetaEndpoints) {
    try {
      const r = await fetch(ep, {
        headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` },
      });
      if (r.ok) {
        const tables = await r.json() as any[];
        pgMetaWorks = true;
        results.push({ step: `pg_meta ${ep}`, status: '✅', tables: tables.map((t: any) => t.name).slice(0, 5) });
        break;
      } else {
        results.push({ step: `pg_meta ${ep}`, status: `❌ ${r.status}` });
      }
    } catch (e: any) {
      results.push({ step: `pg_meta ${ep}`, error: e.message });
    }
  }

  // Essai 2: Créer une table via l'API Supabase Management v1
  // (nécessite un token de management différent du service key)
  const projectRef = 'xqifdbgqxyrlhrkwlyir';
  try {
    const mgmtSql = `SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename IN ('chapitres','lecons','user_progress_lecon');`;
    const mgmtResp = await fetch(`https://api.supabase.com/v1/projects/${projectRef}/database/query`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${serviceKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ query: mgmtSql }),
    });
    if (mgmtResp.ok) {
      const mgmtData = await mgmtResp.json() as any;
      results.push({ step: 'management_api_check', status: '✅', data: mgmtData });
    } else {
      results.push({ step: 'management_api_check', status: `❌ ${mgmtResp.status}` });
    }
  } catch (e: any) {
    results.push({ step: 'management_api_check', error: e.message });
  }

  // Retourner le SQL complet pour exécution
  const sql = `
-- EXÉCUTER CE SQL DANS SUPABASE SQL EDITOR:
-- https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new

CREATE TABLE IF NOT EXISTS public.chapitres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    matiere_id UUID NOT NULL REFERENCES public.matieres(id) ON DELETE CASCADE,
    titre TEXT NOT NULL,
    description TEXT,
    ordre INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.lecons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chapitre_id UUID NOT NULL REFERENCES public.chapitres(id) ON DELETE CASCADE,
    titre TEXT NOT NULL,
    contenu TEXT,
    video_url TEXT,
    ordre INTEGER NOT NULL DEFAULT 0,
    duree_minutes INTEGER DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS chapitre_id UUID REFERENCES public.chapitres(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS public.user_progress_lecon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    lecon_id UUID NOT NULL REFERENCES public.lecons(id) ON DELETE CASCADE,
    termine BOOLEAN DEFAULT FALSE,
    date_termine TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, lecon_id)
);

CREATE INDEX IF NOT EXISTS idx_chapitres_matiere ON public.chapitres(matiere_id);
CREATE INDEX IF NOT EXISTS idx_lecons_chapitre ON public.lecons(chapitre_id);
CREATE INDEX IF NOT EXISTS idx_questions_chapitre ON public.questions(chapitre_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_lecon_user ON public.user_progress_lecon(user_id);

ALTER TABLE public.chapitres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lecons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress_lecon ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='chapitres' AND policyname='chapitres_public_read') THEN
    CREATE POLICY chapitres_public_read ON public.chapitres FOR SELECT USING (true);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='lecons' AND policyname='lecons_public_read') THEN
    CREATE POLICY lecons_public_read ON public.lecons FOR SELECT USING (true);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_progress_lecon' AND policyname='upl_service_all') THEN
    CREATE POLICY upl_service_all ON public.user_progress_lecon USING (true) WITH CHECK (true);
  END IF;
END $$;
  `.trim();

  return c.json({ success: true, results, sql, pg_meta_accessible: pgMetaWorks });
});
