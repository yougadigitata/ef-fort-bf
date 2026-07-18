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

// ── GET /api/admin/demandes-abonnement (alias compatible panel) ──
admin.get('/demandes-abonnement', requireAdmin, async (c) => {
  const db = getDB(c.env);
  const { data, error } = await db.from('demandes_abonnement')
    .select('*, profiles(nom, prenom, telephone)')
    .order('created_at', { ascending: false });
  if (error) return c.json({ error: error.message }, 500);
  const demandes = (data || []).map((d: any) => ({
    ...d,
    nom_complet: d.profiles ? `${d.profiles.prenom} ${d.profiles.nom}` : 'Inconnu',
    telephone: d.profiles?.telephone || '',
  }));
  return c.json({ success: true, demandes });
});

// ── POST /api/admin/valider-abonnement/:id ────────────────────
admin.post('/valider-abonnement/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  const db = getDB(c.env);
  const body = await c.req.json().catch(() => ({})) as Record<string, unknown>;
  const statut = (body['statut'] as string) || 'VALIDE';

  if (statut === 'REJETE') {
    await db.from('demandes_abonnement').update({ statut: 'REJETE' }).eq('id', id);
    return c.json({ success: true, message: 'Demande rejetée.' });
  }

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

// ── POST /api/admin/change-password ───────────────────────────
// CORRECTION: Utilise verifyPassword() au lieu de SHA-256 simple
admin.post('/change-password', requireAdmin, async (c) => {
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps invalide.' }, 400);

  const currentPassword = body['current_password'] as string;
  const newPassword = body['new_password'] as string;

  if (!currentPassword || !newPassword) {
    return c.json({ error: 'Mot de passe actuel et nouveau requis.' }, 400);
  }
  if (newPassword.length < 8) {
    return c.json({ error: 'Le nouveau mot de passe doit faire au moins 8 caractères.' }, 400);
  }
  if (!/[A-Z]/.test(newPassword)) {
    return c.json({ error: 'Le nouveau mot de passe doit contenir au moins une majuscule.' }, 400);
  }
  if (!/[0-9]/.test(newPassword)) {
    return c.json({ error: 'Le nouveau mot de passe doit contenir au moins un chiffre.' }, 400);
  }

  const db = getDB(c.env);
  const h = c.req.header('Authorization')!;
  const payload = await verifyJWT(h.slice(7)) as any;
  const adminId = payload?.id;

  // Vérifier le mot de passe actuel
  const { data: profile } = await db.from('profiles')
    .select('id, telephone, password_hash')
    .eq('id', adminId)
    .single();

  if (!profile) return c.json({ error: 'Utilisateur introuvable.' }, 404);

  // CORRECTION CRITIQUE: Utiliser verifyPassword() qui gère le format sel:hash
  // L'ancien code utilisait SHA-256 simple ce qui ne correspond pas au format stocké
  const { verifyPassword, makePasswordHash } = await import('../lib/auth');
  const isValid = await verifyPassword(String(currentPassword), profile.password_hash);
  
  if (!isValid) {
    return c.json({ error: 'Mot de passe actuel incorrect.' }, 401);
  }

  // Hash du nouveau mot de passe avec le bon format sel:hash
  const newHash = await makePasswordHash(String(newPassword));

  const { error: updateErr } = await db.from('profiles')
    .update({ password_hash: newHash })
    .eq('id', adminId);

  if (updateErr) return c.json({ error: updateErr.message }, 500);
  return c.json({ success: true, message: 'Mot de passe modifié avec succès.' });
});

// ── POST /api/admin/reset-password — Réinitialiser le mot de passe admin (URGENCE) ──
admin.post('/reset-password', async (c) => {
  const body = await c.req.json().catch(() => ({})) as Record<string, unknown>;
  // Vérification par secret d'urgence
  if (body['secret'] !== 'EfFortAdmin2026!BF') {
    return c.json({ error: 'Secret invalide.' }, 403);
  }
  
  const newPassword = body['new_password'] as string;
  if (!newPassword || newPassword.length < 8) {
    return c.json({ error: 'Nouveau mot de passe invalide (8 char min).' }, 400);
  }

  const db = getDB(c.env);
  const { makePasswordHash } = await import('../lib/auth');
  const newHash = await makePasswordHash(String(newPassword));

  const { error } = await db.from('profiles')
    .update({ password_hash: newHash })
    .eq('is_admin', true);

  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, message: `Mot de passe admin réinitialisé.` });
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

  // Valider les champs requis
  if (!body['titre'] || !body['contenu']) {
    return c.json({ error: 'Titre et contenu requis.' }, 400);
  }

  const db = getDB(c.env);

  // Construire l'objet avec uniquement les colonnes existantes de la table actualites
  // (id, titre, contenu, categorie, actif, created_at)
  const actualiteData: Record<string, unknown> = {
    titre: String(body['titre']).trim(),
    contenu: String(body['contenu']).trim(),
    categorie: (body['categorie'] as string) || 'ACTUALITE',
    actif: true,
  };

  // Si la colonne couleur_fond existe, l'ajouter (migration future)
  // Pour l'instant on l'ignore pour éviter l'erreur 42703

  const { error } = await db.from('actualites').insert(actualiteData);
  if (error) {
    // Log l'erreur pour debug
    console.error('Erreur insert actualite:', error.message);
    return c.json({ error: `Erreur base de données: ${error.message}` }, 500);
  }
  return c.json({ success: true, message: 'Actualité publiée avec succès.' });
});

// ── POST /api/admin/migrate — Créer les tables manquantes ────
// Endpoint de migration sécurisé — NE PAS SUPPRIMER (utilisé par setup)
admin.post('/migrate', async (c) => {
  const body = await c.req.json().catch(() => ({})) as Record<string, unknown>;
  if (body['secret'] !== 'EfFortAdmin2026!BF') {
    return c.json({ error: 'Secret invalide.' }, 403);
  }

  const db = getDB(c.env);
  const results: Record<string, string> = {};

  // ── 1. Créer table messages_entraide (via insertions conditionnelles) ──
  // On utilise l'API Supabase pour tester et créer la table
  try {
    const { error: testError } = await db
      .from('messages_entraide')
      .select('id')
      .limit(1);

    if (testError && (testError.code === '42P01' || testError.message.includes('does not exist'))) {
      // La table n'existe pas — on ne peut pas la créer via REST API
      // Retourner les SQLs à exécuter manuellement
      results['messages_entraide'] = 'TABLE_MISSING_NEEDS_MANUAL_SQL';
    } else if (testError) {
      results['messages_entraide'] = `error: ${testError.message}`;
    } else {
      results['messages_entraide'] = 'exists';
    }
  } catch (e: any) {
    results['messages_entraide'] = `exception: ${e.message}`;
  }

  // ── 2. Vérifier table resultats ──
  try {
    const { error: testError2 } = await db
      .from('resultats')
      .select('id')
      .limit(1);

    if (testError2 && (testError2.code === '42P01' || testError2.message.includes('does not exist'))) {
      results['resultats'] = 'TABLE_MISSING_NEEDS_MANUAL_SQL';
    } else if (testError2) {
      results['resultats'] = `error: ${testError2.message}`;
    } else {
      results['resultats'] = 'exists';
    }
  } catch (e: any) {
    results['resultats'] = `exception: ${e.message}`;
  }

  // ── 3. Retourner les SQLs nécessaires si tables manquantes ──
  const sqlsNeeded: string[] = [];

  if (results['messages_entraide'] === 'TABLE_MISSING_NEEDS_MANUAL_SQL') {
    sqlsNeeded.push(`
CREATE TABLE IF NOT EXISTS public.messages_entraide (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  contenu TEXT NOT NULL,
  partage_whatsapp BOOLEAN DEFAULT false,
  telephone_partage VARCHAR(20),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  actif BOOLEAN DEFAULT true
);
ALTER TABLE public.messages_entraide ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lire messages actifs" ON public.messages_entraide FOR SELECT USING (actif = true);
CREATE POLICY "Inserer message" ON public.messages_entraide FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Supprimer message" ON public.messages_entraide FOR DELETE USING (auth.uid() = user_id);
    `.trim());
  }

  if (results['resultats'] === 'TABLE_MISSING_NEEDS_MANUAL_SQL') {
    sqlsNeeded.push(`
CREATE TABLE IF NOT EXISTS public.resultats (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id UUID DEFAULT gen_random_uuid(),
  matiere VARCHAR(100),
  type_session VARCHAR(50) DEFAULT 'serie',
  nb_questions INTEGER DEFAULT 0,
  nb_correctes INTEGER DEFAULT 0,
  nb_incorrectes INTEGER DEFAULT 0,
  nb_sautees INTEGER DEFAULT 0,
  score_pourcentage DECIMAL(5,2) DEFAULT 0,
  duree_secondes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.resultats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Voir ses resultats" ON public.resultats FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Inserer ses resultats" ON public.resultats FOR INSERT WITH CHECK (auth.uid() = user_id);
    `.trim());
  }

  return c.json({
    success: true,
    tables_status: results,
    sqls_to_run: sqlsNeeded,
    message: sqlsNeeded.length > 0
      ? 'Tables manquantes détectées. Exécutez les SQLs fournis dans Supabase Dashboard > SQL Editor.'
      : 'Toutes les tables sont en place.',
  });
});

// ── GET /api/admin/user-stats/:userId — Stats dashboard utilisateur ──
admin.get('/user-stats/:userId', requireAdmin, async (c) => {
  const userId = c.req.param('userId');
  const db = getDB(c.env);

  try {
    // Sessions examen
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
      .eq('termine', true);

    const avgScore = sessions && sessions.length > 0
      ? sessions.reduce((sum: number, s: any) => sum + (s.score_pourcentage || 0), 0) / sessions.length
      : 0;

    return c.json({
      success: true,
      stats: {
        nb_simulations: nbSimulations ?? 0,
        score_moyen: Math.round(avgScore * 10) / 10,
        questions_repondues: (nbSimulations ?? 0) * 50,
      }
    });
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

// ── POST /api/admin/migrate — Exécuter les migrations SQL nécessaires ──
// Endpoint sécurisé pour lancer les migrations de la base de données
admin.post('/migrate', requireAdmin, async (c) => {
  const db = getDB(c.env);
  const results: string[] = [];

  // Migration 1 : Ajouter parent_id dans messages_entraide
  try {
    // Tenter d'insérer un message test avec parent_id pour vérifier si la colonne existe
    const { error: checkError } = await db
      .from('messages_entraide')
      .select('parent_id')
      .limit(1);
    
    if (checkError && checkError.message.includes('parent_id')) {
      // La colonne n'existe pas, on doit la créer
      // Supabase ne supporte pas DDL via REST API directement
      // On retourne le SQL à exécuter manuellement
      results.push('⚠️ Migration parent_id requise - SQL à exécuter dans Supabase Dashboard');
    } else {
      results.push('✅ Colonne parent_id déjà présente dans messages_entraide');
    }
  } catch (e: any) {
    results.push(`Info: ${e.message}`);
  }

  // Migration 2 : Vérifier les tables importantes
  const tables = ['messages_entraide', 'profiles', 'matieres', 'series_qcm', 'questions'];
  for (const table of tables) {
    try {
      const { count, error } = await db.from(table).select('*', { count: 'exact', head: true });
      if (error) {
        results.push(`❌ Table ${table}: ${error.message}`);
      } else {
        results.push(`✅ Table ${table}: ${count} lignes`);
      }
    } catch (e: any) {
      results.push(`❌ Table ${table}: ${e.message}`);
    }
  }

  // SQL de migration à exécuter manuellement dans Supabase
  const migrationSQL = `
-- MIGRATION EF-FORT.BF v8 - À exécuter dans Supabase SQL Editor
ALTER TABLE public.messages_entraide 
  ADD COLUMN IF NOT EXISTS parent_id UUID 
  REFERENCES public.messages_entraide(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_messages_entraide_parent_id 
  ON public.messages_entraide(parent_id);
`;

  return c.json({ 
    success: true, 
    results,
    migration_sql: migrationSQL,
    message: 'Diagnostic terminé'
  });
});

// ── GET /api/admin/migrate/check — Vérifier l'état des migrations ──
admin.get('/migrate/check', requireAdmin, async (c) => {
  const db = getDB(c.env);
  
  // Vérifier si parent_id existe
  const { data, error } = await db
    .from('messages_entraide')
    .select('id, parent_id')
    .limit(1);
  
  const hasParentId = !error || !error.message.includes('parent_id');
  
  return c.json({
    success: true,
    migrations: {
      parent_id_exists: hasParentId,
      error: error?.message || null,
    }
  });
});

// ═══════════════════════════════════════════════════════════════
// POST /api/admin/run-elearning-migration — Migration e-learning v9
// Endpoint sécurisé par secret header
// Utilise l'API Supabase Management pour exécuter le DDL SQL
// ═══════════════════════════════════════════════════════════════
admin.post('/run-elearning-migration', async (c) => {
  const secret = c.req.header('X-Migration-Secret');
  if (secret !== 'ef-fort-migrate-2025') {
    return c.json({ error: 'Secret de migration invalide.' }, 403);
  }

  const supabaseUrl = c.env.SUPABASE_URL;
  const serviceKey = c.env.SUPABASE_KEY;
  const results: string[] = [];
  const errors: string[] = [];

  // Exécuter le SQL DDL via l'API Supabase Management
  // Endpoint: POST /v1/projects/{ref}/database/query
  // avec le SERVICE ROLE KEY comme Authorization
  const projectRef = supabaseUrl.replace('https://', '').replace('.supabase.co', '');
  
  const migrationSQL = `
-- Migration e-learning v9
CREATE TABLE IF NOT EXISTS public.chapitres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    matiere_id UUID NOT NULL REFERENCES public.matieres(id) ON DELETE CASCADE,
    titre TEXT NOT NULL, description TEXT,
    ordre INTEGER NOT NULL DEFAULT 0, created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.lecons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chapitre_id UUID NOT NULL REFERENCES public.chapitres(id) ON DELETE CASCADE,
    titre TEXT NOT NULL, contenu TEXT, video_url TEXT,
    ordre INTEGER NOT NULL DEFAULT 0, duree_minutes INTEGER DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.user_progress_lecon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    lecon_id UUID NOT NULL REFERENCES public.lecons(id) ON DELETE CASCADE,
    termine BOOLEAN DEFAULT FALSE, date_termine TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(), UNIQUE(user_id, lecon_id)
);
CREATE INDEX IF NOT EXISTS idx_chapitres_matiere ON public.chapitres(matiere_id);
CREATE INDEX IF NOT EXISTS idx_lecons_chapitre ON public.lecons(chapitre_id);
CREATE INDEX IF NOT EXISTS idx_upl_user ON public.user_progress_lecon(user_id);
ALTER TABLE public.chapitres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lecons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress_lecon ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='chapitres' AND policyname='chapitres_public_read') THEN
    CREATE POLICY chapitres_public_read ON public.chapitres FOR SELECT USING (true); END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='lecons' AND policyname='lecons_public_read') THEN
    CREATE POLICY lecons_public_read ON public.lecons FOR SELECT USING (true); END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_progress_lecon' AND policyname='upl_service_all') THEN
    CREATE POLICY upl_service_all ON public.user_progress_lecon USING (true) WITH CHECK (true); END IF;
END $$;
`;

  // Essai 1: Via l'API Management Supabase (nécessite PAT, mais essayons)
  try {
    const resp = await fetch(`https://api.supabase.com/v1/projects/${projectRef}/database/query`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${serviceKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query: migrationSQL }),
    });
    const data = await resp.json() as any;
    if (resp.ok) {
      results.push('✅ Migration exécutée via Management API');
    } else {
      results.push(`⚠️ Management API: ${data.message || JSON.stringify(data)}`);
    }
  } catch (e: any) {
    results.push(`⚠️ Management API erreur: ${e.message}`);
  }

  // Essai 2: Vérifier si les tables ont été créées
  const db = getDB(c.env);
  const tablesStatus: Record<string, boolean> = {};

  for (const table of ['chapitres', 'lecons', 'user_progress_lecon']) {
    try {
      const { data, error } = await db.from(table).select('id').limit(1);
      tablesStatus[table] = !error;
      if (!error) results.push(`✅ Table ${table}: accessible`);
      else errors.push(`❌ Table ${table}: ${error.message}`);
    } catch (e: any) {
      tablesStatus[table] = false;
      errors.push(`❌ Table ${table}: ${e.message}`);
    }
  }

  const allTablesExist = Object.values(tablesStatus).every(v => v);

  return c.json({
    success: allTablesExist,
    results,
    errors,
    tables_status: tablesStatus,
    message: allTablesExist 
      ? '✅ Toutes les tables e-learning sont en place!'
      : '⚠️ Certaines tables manquent - exécuter le SQL manuellement',
    sql_required: `
-- MIGRATION E-LEARNING v9 — À exécuter dans Supabase SQL Editor
-- URL: https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql

CREATE TABLE IF NOT EXISTS public.chapitres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    matiere_id UUID NOT NULL REFERENCES public.matieres(id) ON DELETE CASCADE,
    titre TEXT NOT NULL, description TEXT,
    ordre INTEGER NOT NULL DEFAULT 0, created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.lecons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chapitre_id UUID NOT NULL REFERENCES public.chapitres(id) ON DELETE CASCADE,
    titre TEXT NOT NULL, contenu TEXT, video_url TEXT,
    ordre INTEGER NOT NULL DEFAULT 0, duree_minutes INTEGER DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS public.user_progress_lecon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    lecon_id UUID NOT NULL REFERENCES public.lecons(id) ON DELETE CASCADE,
    termine BOOLEAN DEFAULT FALSE, date_termine TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(), UNIQUE(user_id, lecon_id)
);
ALTER TABLE public.chapitres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lecons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress_lecon ENABLE ROW LEVEL SECURITY;
CREATE POLICY chapitres_public_read ON public.chapitres FOR SELECT USING (true);
CREATE POLICY lecons_public_read ON public.lecons FOR SELECT USING (true);
CREATE POLICY upl_service_all ON public.user_progress_lecon USING (true) WITH CHECK (true);
`
  });
});

// ═══════════════════════════════════════════════════════════════
// POST /api/admin/seed-chapitres — Insérer les données initiales
// Utilise le service role via SUPABASE_SERVICE_KEY
// ═══════════════════════════════════════════════════════════════
admin.post('/seed-chapitres', async (c) => {
  const secret = c.req.header('X-Migration-Secret');
  if (secret !== 'ef-fort-migrate-2025') {
    return c.json({ error: 'Secret de migration invalide.' }, 403);
  }

  const db = getDB(c.env);
  const results: string[] = [];

  const chapitresData = [
    { matiere_id: '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', titre: 'Chapitre 1 : Introduction au Droit', description: 'Notions fondamentales du droit burkinabè', ordre: 1 },
    { matiere_id: '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', titre: 'Chapitre 2 : Droit Constitutionnel', description: 'Constitution du Burkina Faso, institutions', ordre: 2 },
    { matiere_id: '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', titre: 'Chapitre 3 : Droit Administratif', description: 'Actes administratifs et contentieux', ordre: 3 },
    { matiere_id: 'd1560595-b4d9-45d2-af70-8bdf7016af72', titre: 'Chapitre 1 : Grammaire et Orthographe', description: 'Règles grammaticales et conjugaison', ordre: 1 },
    { matiere_id: 'd1560595-b4d9-45d2-af70-8bdf7016af72', titre: 'Chapitre 2 : Expression Écrite', description: 'Rédaction, résumé et synthèse', ordre: 2 },
    { matiere_id: 'd1560595-b4d9-45d2-af70-8bdf7016af72', titre: 'Chapitre 3 : Littérature Francophone', description: 'Auteurs africains au programme', ordre: 3 },
    { matiere_id: '54f53d06-2d5d-4d82-91bc-4bfff904c12b', titre: 'Chapitre 1 : Logique et Raisonnement', description: 'Séries numériques et suites logiques', ordre: 1 },
    { matiere_id: '54f53d06-2d5d-4d82-91bc-4bfff904c12b', titre: 'Chapitre 2 : Figures et Matrices', description: 'Tests visuels et rotations', ordre: 2 },
    { matiere_id: '54f53d06-2d5d-4d82-91bc-4bfff904c12b', titre: 'Chapitre 3 : Calcul Mental', description: 'Rapidité et résolution de problèmes', ordre: 3 },
  ];

  // Insérer les chapitres un par un (pour éviter les doublons)
  let inserted = 0;
  let skipped = 0;
  for (const ch of chapitresData) {
    try {
      const { data: existing } = await db
        .from('chapitres')
        .select('id')
        .eq('matiere_id', ch.matiere_id)
        .eq('titre', ch.titre)
        .single();

      if (existing) {
        skipped++;
        continue;
      }

      const { error } = await db.from('chapitres').insert(ch);
      if (error) {
        results.push(`❌ Erreur insertion "${ch.titre}": ${error.message}`);
      } else {
        inserted++;
      }
    } catch (e: any) {
      results.push(`❌ Exception "${ch.titre}": ${e.message}`);
    }
  }

  // Compter total
  const { count } = await db.from('chapitres').select('*', { count: 'exact', head: true });

  return c.json({
    success: true,
    inserted,
    skipped,
    total_chapitres: count ?? 0,
    results,
    message: `${inserted} chapitres insérés, ${skipped} déjà existants`,
  });
});

export default admin;
