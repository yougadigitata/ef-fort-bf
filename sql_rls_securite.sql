-- ════════════════════════════════════════════════════════════════════════
-- SQL RLS — Sécurisation complète EF-FORT.BF
-- À exécuter dans : https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new
-- Date : 2025
-- IMPORTANT : La service_role key contourne ces règles (accès total conservé)
-- Seuls les utilisateurs anonymes (clé anon) seront restreints
-- ════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────
-- 1. TABLE : questions (lecture publique, écriture service_role seulement)
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture publique questions" ON public.questions;
CREATE POLICY "Lecture publique questions"
  ON public.questions
  FOR SELECT
  USING (published = true);

DROP POLICY IF EXISTS "Ecriture admin questions" ON public.questions;
CREATE POLICY "Ecriture admin questions"
  ON public.questions
  FOR ALL
  USING (auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────
-- 2. TABLE : series_qcm (lecture publique, écriture service_role)
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.series_qcm ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture publique series" ON public.series_qcm;
CREATE POLICY "Lecture publique series"
  ON public.series_qcm
  FOR SELECT
  USING (published = true AND actif = true);

DROP POLICY IF EXISTS "Ecriture admin series" ON public.series_qcm;
CREATE POLICY "Ecriture admin series"
  ON public.series_qcm
  FOR ALL
  USING (auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────
-- 3. TABLE : matieres (lecture publique)
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.matieres ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture publique matieres" ON public.matieres;
CREATE POLICY "Lecture publique matieres"
  ON public.matieres
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Ecriture admin matieres" ON public.matieres;
CREATE POLICY "Ecriture admin matieres"
  ON public.matieres
  FOR ALL
  USING (auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────
-- 4. TABLE : profiles (lecture/écriture propre profil uniquement)
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Voir son profil" ON public.profiles;
CREATE POLICY "Voir son profil"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Modifier son profil" ON public.profiles;
CREATE POLICY "Modifier son profil"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Inserer profil" ON public.profiles;
CREATE POLICY "Inserer profil"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Ecriture admin profiles" ON public.profiles;
CREATE POLICY "Ecriture admin profiles"
  ON public.profiles
  FOR ALL
  USING (auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────
-- 5. TABLE : sessions_examen (voir ses propres sessions)
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.sessions_examen ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Voir ses sessions" ON public.sessions_examen;
CREATE POLICY "Voir ses sessions"
  ON public.sessions_examen
  FOR SELECT
  USING (auth.uid()::text = user_id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Inserer session" ON public.sessions_examen;
CREATE POLICY "Inserer session"
  ON public.sessions_examen
  FOR INSERT
  WITH CHECK (auth.uid()::text = user_id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Modifier session" ON public.sessions_examen;
CREATE POLICY "Modifier session"
  ON public.sessions_examen
  FOR UPDATE
  USING (auth.uid()::text = user_id OR auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────
-- 6. TABLE : messages (entraide) - déjà configuré, renforcement
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lire messages entraide" ON public.messages;
CREATE POLICY "Lire messages entraide"
  ON public.messages
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Inserer message entraide" ON public.messages;
CREATE POLICY "Inserer message entraide"
  ON public.messages
  FOR INSERT
  WITH CHECK (auth.uid()::text = user_id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Supprimer son message" ON public.messages;
CREATE POLICY "Supprimer son message"
  ON public.messages
  FOR DELETE
  USING (auth.uid()::text = user_id OR auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────
-- 7. TABLE : messages_entraide (si elle existe)
-- ─────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'messages_entraide'
  ) THEN
    EXECUTE 'ALTER TABLE public.messages_entraide ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "Lire messages actifs" ON public.messages_entraide';
    EXECUTE 'CREATE POLICY "Lire messages actifs" ON public.messages_entraide FOR SELECT USING (actif = true)';
    EXECUTE 'DROP POLICY IF EXISTS "Inserer message" ON public.messages_entraide';
    EXECUTE 'CREATE POLICY "Inserer message" ON public.messages_entraide FOR INSERT WITH CHECK (auth.uid()::text = user_id OR auth.role() = ''service_role'')';
    EXECUTE 'DROP POLICY IF EXISTS "Supprimer message" ON public.messages_entraide';
    EXECUTE 'CREATE POLICY "Supprimer message" ON public.messages_entraide FOR DELETE USING (auth.uid()::text = user_id OR auth.role() = ''service_role'')';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────
-- 8. TABLE : demandes_abonnement
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.demandes_abonnement ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Voir ses demandes" ON public.demandes_abonnement;
CREATE POLICY "Voir ses demandes"
  ON public.demandes_abonnement
  FOR SELECT
  USING (auth.uid()::text = user_id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Inserer demande" ON public.demandes_abonnement;
CREATE POLICY "Inserer demande"
  ON public.demandes_abonnement
  FOR INSERT
  WITH CHECK (auth.uid()::text = user_id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Admin gere demandes" ON public.demandes_abonnement;
CREATE POLICY "Admin gere demandes"
  ON public.demandes_abonnement
  FOR ALL
  USING (auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────
-- 9. TABLE : actualites (lecture publique)
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.actualites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture publique actualites" ON public.actualites;
CREATE POLICY "Lecture publique actualites"
  ON public.actualites
  FOR SELECT
  USING (actif = true);

DROP POLICY IF EXISTS "Admin gere actualites" ON public.actualites;
CREATE POLICY "Admin gere actualites"
  ON public.actualites
  FOR ALL
  USING (auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────
-- 10. TABLE : resultats
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.resultats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Voir ses resultats" ON public.resultats;
CREATE POLICY "Voir ses resultats"
  ON public.resultats
  FOR SELECT
  USING (auth.uid()::text = user_id OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Inserer ses resultats" ON public.resultats;
CREATE POLICY "Inserer ses resultats"
  ON public.resultats
  FOR INSERT
  WITH CHECK (auth.uid()::text = user_id OR auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────
-- RÉSUMÉ : RLS activé sur toutes les tables principales
-- La service_role key (utilisée par le Worker Cloudflare) contourne tout
-- ─────────────────────────────────────────────────────────────────────
SELECT 
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN (
    'questions', 'series_qcm', 'matieres', 'profiles',
    'sessions_examen', 'messages', 'messages_entraide',
    'demandes_abonnement', 'actualites', 'resultats'
  )
ORDER BY tablename;
