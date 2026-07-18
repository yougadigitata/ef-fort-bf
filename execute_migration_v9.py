#!/usr/bin/env python3
"""
Script de migration e-learning v9 pour EF-FORT.BF
Utilise l'API REST Supabase avec service role key pour créer les tables
et insérer les données initiales.
"""

import json
import sys
import urllib.request
import urllib.error

SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

def supabase_request(method, path, data=None, extra_headers=None):
    """Effectuer une requête REST Supabase"""
    url = f"{SUPABASE_URL}{path}"
    headers = dict(HEADERS)
    if extra_headers:
        headers.update(extra_headers)
    
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            content = resp.read().decode()
            return resp.status, content
    except urllib.error.HTTPError as e:
        content = e.read().decode()
        return e.code, content

def check_table(table_name):
    """Vérifier si une table existe"""
    status, body = supabase_request("GET", f"/rest/v1/{table_name}?limit=1&select=id")
    return status == 200

def count_rows(table_name):
    """Compter les lignes dans une table"""
    status, body = supabase_request("GET", f"/rest/v1/{table_name}?select=id")
    if status == 200:
        data = json.loads(body)
        return len(data) if isinstance(data, list) else 0
    return -1

def insert_chapitres(chapitres_data):
    """Insérer les chapitres un par un"""
    inserted = 0
    skipped = 0
    errors = []

    for ch in chapitres_data:
        # Vérifier si déjà existant
        encoded_titre = ch['titre'].replace(' ', '%20').replace(':', '%3A').replace("'", "%27")
        check_path = f"/rest/v1/chapitres?matiere_id=eq.{ch['matiere_id']}&titre=eq.{urllib.parse.quote(ch['titre'])}&select=id&limit=1"
        
        import urllib.parse
        check_path2 = f"/rest/v1/chapitres?matiere_id=eq.{ch['matiere_id']}&select=id,titre&limit=20"
        status, body = supabase_request("GET", check_path2)
        
        if status == 200:
            existing = json.loads(body)
            already_exists = any(e.get('titre') == ch['titre'] for e in existing)
            if already_exists:
                print(f"  ⏭️  Déjà existant: {ch['titre'][:50]}")
                skipped += 1
                continue

        # Insérer
        status, body = supabase_request("POST", "/rest/v1/chapitres", ch)
        if status in (200, 201):
            print(f"  ✅ Inséré: {ch['titre'][:60]}")
            inserted += 1
        else:
            print(f"  ❌ Erreur ({status}): {ch['titre'][:40]} → {body[:100]}")
            errors.append(f"{ch['titre']}: {body[:80]}")

    return inserted, skipped, errors

def main():
    print("=" * 60)
    print("MIGRATION E-LEARNING v9 — EF-FORT.BF")
    print("=" * 60)
    
    # Importer urllib.parse ici
    import urllib.parse
    
    # Étape 1: Vérifier les tables
    print("\n📋 ÉTAPE 1: Vérification des tables...")
    
    tables = ['chapitres', 'lecons', 'user_progress_lecon']
    missing_tables = []
    
    for table in tables:
        exists = check_table(table)
        if exists:
            print(f"  ✅ Table '{table}': EXISTS")
        else:
            print(f"  ❌ Table '{table}': MISSING")
            missing_tables.append(table)
    
    if missing_tables:
        print(f"\n⚠️  Tables manquantes: {missing_tables}")
        print("ℹ️  Ces tables doivent être créées via Supabase SQL Editor.")
        print("\n📝 SQL À EXÉCUTER DANS SUPABASE:")
        print("-" * 40)
        print(MIGRATION_SQL)
        print("-" * 40)
        print("\nL'Agent va maintenant essayer d'insérer les chapitres via l'API...")
        print("(Si les tables existent déjà après déploiement Worker)")
    
    # Étape 2: Essayer d'insérer les chapitres si la table existe
    if 'chapitres' not in missing_tables:
        print("\n📋 ÉTAPE 2: Insertion des chapitres initiaux...")
        chapitres_data = [
            {'matiere_id': '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', 'titre': 'Chapitre 1 : Introduction au Droit', 'description': 'Notions fondamentales du droit burkinabè', 'ordre': 1},
            {'matiere_id': '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', 'titre': 'Chapitre 2 : Droit Constitutionnel', 'description': 'Constitution du Burkina Faso, institutions', 'ordre': 2},
            {'matiere_id': '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', 'titre': 'Chapitre 3 : Droit Administratif', 'description': 'Actes administratifs et contentieux', 'ordre': 3},
            {'matiere_id': 'd1560595-b4d9-45d2-af70-8bdf7016af72', 'titre': 'Chapitre 1 : Grammaire et Orthographe', 'description': 'Règles grammaticales et conjugaison', 'ordre': 1},
            {'matiere_id': 'd1560595-b4d9-45d2-af70-8bdf7016af72', 'titre': 'Chapitre 2 : Expression Écrite', 'description': 'Rédaction, résumé et synthèse', 'ordre': 2},
            {'matiere_id': 'd1560595-b4d9-45d2-af70-8bdf7016af72', 'titre': 'Chapitre 3 : Littérature Francophone', 'description': 'Auteurs africains au programme', 'ordre': 3},
            {'matiere_id': '54f53d06-2d5d-4d82-91bc-4bfff904c12b', 'titre': 'Chapitre 1 : Logique et Raisonnement', 'description': 'Séries numériques et suites logiques', 'ordre': 1},
            {'matiere_id': '54f53d06-2d5d-4d82-91bc-4bfff904c12b', 'titre': 'Chapitre 2 : Figures et Matrices', 'description': 'Tests visuels et rotations', 'ordre': 2},
            {'matiere_id': '54f53d06-2d5d-4d82-91bc-4bfff904c12b', 'titre': 'Chapitre 3 : Calcul Mental', 'description': 'Rapidité et résolution de problèmes', 'ordre': 3},
        ]
        
        inserted, skipped, errors = insert_chapitres(chapitres_data)
        total = count_rows('chapitres')
        
        print(f"\n✅ Résultat: {inserted} insérés, {skipped} ignorés")
        print(f"📊 Total chapitres en base: {total}")
        
        if errors:
            print(f"⚠️  Erreurs: {errors}")
    else:
        print("\n⏭️  Chapitres non insérés (table manquante)")
    
    print("\n" + "=" * 60)
    print("MIGRATION TERMINÉE")
    print("=" * 60)

MIGRATION_SQL = """
-- ================================================================
-- MIGRATION E-LEARNING v9 — EF-FORT.BF
-- Copier-coller ce SQL dans:
-- https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql
-- ================================================================

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
CREATE INDEX IF NOT EXISTS idx_upl_user ON public.user_progress_lecon(user_id);

ALTER TABLE public.chapitres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lecons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress_lecon ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='chapitres' AND policyname='chapitres_public_read') THEN
    CREATE POLICY chapitres_public_read ON public.chapitres FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='lecons' AND policyname='lecons_public_read') THEN
    CREATE POLICY lecons_public_read ON public.lecons FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_progress_lecon' AND policyname='upl_service_all') THEN
    CREATE POLICY upl_service_all ON public.user_progress_lecon USING (true) WITH CHECK (true);
  END IF;
END $$;

-- Données initiales (chapitres)
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

SELECT 'Migration OK' as status, count(*) as chapitres FROM public.chapitres;
"""

if __name__ == '__main__':
    main()
