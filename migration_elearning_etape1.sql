-- =====================================================
-- MIGRATION E-LEARNING ÉTAPE 1 — EF-FORT.BF
-- À exécuter dans Supabase Dashboard > SQL Editor
-- =====================================================

-- 1. Ajouter la colonne description aux matières
ALTER TABLE public.matieres 
ADD COLUMN IF NOT EXISTS description TEXT;

-- 2. Mettre à jour les descriptions des matières
UPDATE public.matieres SET description = 'Tests de logique, raisonnement abstrait et aptitudes mentales pour la Fonction Publique' WHERE nom = 'Psychotechnique';
UPDATE public.matieres SET description = 'Personnalités marquantes de l''Afrique — leaders, intellectuels, artistes' WHERE nom = 'Figure Africaine';
UPDATE public.matieres SET description = 'Microéconomie, macroéconomie, finances publiques et développement économique' WHERE nom = 'Économie';
UPDATE public.matieres SET description = 'Droit constitutionnel, administratif, civil et pénal — bases juridiques indispensables' WHERE nom = 'Droit';
UPDATE public.matieres SET description = 'Grammaire, orthographe, expression écrite et compréhension de textes' WHERE nom = 'Français';
UPDATE public.matieres SET description = 'Algèbre, géométrie, analyse et statistiques niveau lycée et concours' WHERE nom = 'Mathématiques';
UPDATE public.matieres SET description = 'Physique, Chimie et Sciences de la Vie et de la Terre pour les concours' WHERE nom = 'Sciences PC/SVT';
UPDATE public.matieres SET description = 'Mécanique, optique, électricité et thermodynamique' WHERE nom = 'Sciences Physiques';
UPDATE public.matieres SET description = 'Biologie, géologie et sciences de la vie — concours scientifiques' WHERE nom = 'SVT';
UPDATE public.matieres SET description = 'Histoire, géographie, institutions et culture africaine' WHERE nom = 'Culture Générale';
UPDATE public.matieres SET description = 'Événements mondiaux, géopolitique et actualités récentes' WHERE nom = 'Actualité Internationale';
UPDATE public.matieres SET description = 'Géographie africaine, institutions de l''UA et intégration régionale' WHERE nom = 'Guide Panafricain';
UPDATE public.matieres SET description = 'Structure des FAN, hiérarchie militaire et concours militaires' WHERE nom = 'Force Armée Nationale';
UPDATE public.matieres SET description = 'Compréhension orale et écrite, vocabulaire et expression en anglais' WHERE nom = 'Anglais';
UPDATE public.matieres SET description = 'Bureautique, réseaux, bases de données et notions fondamentales' WHERE nom = 'Informatique';
UPDATE public.matieres SET description = 'Communication administrative, rédaction professionnelle et relations publiques' WHERE nom = 'Communication';
UPDATE public.matieres SET description = 'Histoire du Burkina Faso, géographie nationale et régionale africaine' WHERE nom = 'Histoire-Géographie';
UPDATE public.matieres SET description = 'Institutions, culture, histoire et géographie du pays des Hommes Intègres' WHERE nom = 'Burkina Faso';
UPDATE public.matieres SET description = 'Histoire, missions et structure de l''AES — Burkina, Mali, Niger' WHERE nom = 'Alliance des États du Sahel';
UPDATE public.matieres SET description = 'Sessions complètes d''examens blancs toutes matières pour s''entraîner' WHERE nom = 'Examens Blancs';
UPDATE public.matieres SET description = 'Programme intensif pour les candidats visant les meilleures performances' WHERE nom = 'Préparation haut niveau';

-- 3. Créer la table user_progress (suivi détaillé par question)
CREATE TABLE IF NOT EXISTS public.user_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    question_id BIGINT NOT NULL,
    reponse_donnee TEXT,
    est_correct BOOLEAN NOT NULL DEFAULT FALSE,
    matiere_id UUID,
    serie_id UUID,
    date_reponse TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Index pour les performances
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON public.user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_matiere ON public.user_progress(user_id, matiere_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_date ON public.user_progress(user_id, date_reponse);

-- 5. Row Level Security
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "user_progress_self"
ON public.user_progress
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "user_progress_service"
ON public.user_progress
TO service_role
USING (true)
WITH CHECK (true);

-- Vérification
SELECT 'Migration e-learning étape 1 réussie!' as status;
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'matieres' AND column_name = 'description';
