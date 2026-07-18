-- Migration e-learning v9 (création tables + données initiales)
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
ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS chapitre_id UUID REFERENCES public.chapitres(id) ON DELETE SET NULL;
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
INSERT INTO public.chapitres (matiere_id, titre, description, ordre) VALUES
('9497ca2c-dc1b-43dd-8b7a-af11dde7039d','Chapitre 1 : Introduction au Droit','Notions fondamentales du droit burkinabè',1),
('9497ca2c-dc1b-43dd-8b7a-af11dde7039d','Chapitre 2 : Droit Constitutionnel','Constitution du Burkina Faso, institutions',2),
('9497ca2c-dc1b-43dd-8b7a-af11dde7039d','Chapitre 3 : Droit Administratif','Actes administratifs et contentieux',3),
('d1560595-b4d9-45d2-af70-8bdf7016af72','Chapitre 1 : Grammaire et Orthographe','Règles grammaticales et conjugaison',1),
('d1560595-b4d9-45d2-af70-8bdf7016af72','Chapitre 2 : Expression Écrite','Rédaction, résumé et synthèse',2),
('d1560595-b4d9-45d2-af70-8bdf7016af72','Chapitre 3 : Littérature Francophone','Auteurs africains au programme',3),
('54f53d06-2d5d-4d82-91bc-4bfff904c12b','Chapitre 1 : Logique et Raisonnement','Séries numériques et suites logiques',1),
('54f53d06-2d5d-4d82-91bc-4bfff904c12b','Chapitre 2 : Figures et Matrices','Tests visuels et rotations',2),
('54f53d06-2d5d-4d82-91bc-4bfff904c12b','Chapitre 3 : Calcul Mental','Rapidité et résolution de problèmes',3)
ON CONFLICT DO NOTHING;
