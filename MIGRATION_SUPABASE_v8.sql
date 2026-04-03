-- ================================================================
-- MIGRATION EF-FORT.BF v8.0 — Table Entraide : Réponses Admin
-- À EXÉCUTER dans Supabase SQL Editor UNE SEULE FOIS
-- URL : https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new
-- ================================================================

-- 1. Ajouter la colonne parent_id pour les réponses admin
ALTER TABLE public.messages_entraide 
  ADD COLUMN IF NOT EXISTS parent_id UUID 
  REFERENCES public.messages_entraide(id) ON DELETE CASCADE;

-- 2. Créer l'index de performance
CREATE INDEX IF NOT EXISTS idx_messages_entraide_parent_id 
  ON public.messages_entraide(parent_id);

-- 3. Commenter la colonne pour documentation
COMMENT ON COLUMN public.messages_entraide.parent_id IS 
  'Référence vers le message parent — NULL pour les questions, non-NULL pour les réponses admin';

-- 4. Politique RLS : permettre à l'admin d'insérer des réponses
DROP POLICY IF EXISTS "Admin peut repondre aux messages" ON public.messages_entraide;
CREATE POLICY "Admin peut repondre aux messages" ON public.messages_entraide
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Lire messages actifs" ON public.messages_entraide;
CREATE POLICY "Lire messages actifs" ON public.messages_entraide
  FOR SELECT USING (actif = true);

-- 5. Vérification finale
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'messages_entraide' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- ================================================================
-- RÉSULTAT ATTENDU : La colonne parent_id doit apparaître dans la liste
-- Après cette migration, les réponses admin seront activées
-- ================================================================
