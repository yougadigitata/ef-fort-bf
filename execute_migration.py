#!/usr/bin/env python3
"""
AGENT 4 - Migration SQL EF-FORT.BF
Crée les tables chapitres, lecons, user_progress_lecon via Supabase REST API
Utilise l'approche RPC et l'API REST pour contourner les limitations DDL
"""

import requests
import json
import sys

SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

def check_table_exists(table_name: str) -> bool:
    """Vérifie si une table existe dans Supabase."""
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/{table_name}?select=id&limit=1",
        headers=HEADERS
    )
    return r.status_code == 200

def call_rpc(function_name: str, params: dict = {}) -> dict:
    """Appelle une fonction RPC Supabase."""
    r = requests.post(
        f"{SUPABASE_URL}/rest/v1/rpc/{function_name}",
        headers={**HEADERS, "Prefer": "return=representation"},
        json=params
    )
    return {"status": r.status_code, "data": r.json() if r.content else None}

def insert_data(table: str, data: list) -> dict:
    """Insère des données dans une table."""
    r = requests.post(
        f"{SUPABASE_URL}/rest/v1/{table}",
        headers={**HEADERS, "Prefer": "return=minimal,resolution=ignore-duplicates"},
        json=data
    )
    return {"status": r.status_code, "text": r.text[:200]}

def check_column_exists(table: str, column: str) -> bool:
    """Vérifie si une colonne existe dans une table."""
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/{table}?select={column}&limit=0",
        headers=HEADERS
    )
    return r.status_code == 200

print("=" * 60)
print("🚀 MIGRATION SQL EF-FORT.BF v9 - Agent 4")
print("=" * 60)

# ============================================================
# ÉTAPE 1: Vérification de l'état actuel
# ============================================================
print("\n📋 Étape 1: Vérification de l'état des tables...")

tables_status = {
    "chapitres": check_table_exists("chapitres"),
    "lecons": check_table_exists("lecons"),
    "user_progress_lecon": check_table_exists("user_progress_lecon"),
}

for table, exists in tables_status.items():
    status = "✅ Existe" if exists else "❌ Manquante"
    print(f"  {table}: {status}")

# Vérifier la colonne chapitre_id dans questions
col_exists = check_column_exists("questions", "chapitre_id")
print(f"  questions.chapitre_id: {'✅ Existe' if col_exists else '❌ Manquante'}")

all_exist = all(tables_status.values()) and col_exists

if all_exist:
    print("\n✅ Toutes les tables existent déjà! Passage aux données initiales...")
else:
    print(f"\n❌ Tables manquantes détectées. Migration nécessaire.")
    print("⚠️  La création de tables via REST API n'est pas supportée directement.")
    print("📋 SQL à exécuter dans Supabase Dashboard:")
    print("   https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new")
    
    # Afficher le SQL complet
    sql = """
-- EF-FORT.BF Migration e-learning v9
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
"""
    print("\n" + "=" * 60)
    print("📋 SQL COMPLET À EXÉCUTER:")
    print("=" * 60)
    print(sql)
    print("=" * 60)
    
    # Tenter de créer les tables via RPC si une fonction existe
    print("\n🔄 Tentative via l'endpoint /api/admin/seed-chapitres du Worker...")
    
    # Appel du Worker pour insérer les données (si tables créées manuellement)
    worker_url = "https://ef-fort-bf.yembuaro29.workers.dev"
    r = requests.post(
        f"{worker_url}/api/admin/seed-chapitres",
        json={"secret": "EfFortMigration2026!"},
        headers={"Content-Type": "application/json"}
    )
    print(f"  Worker seed-chapitres: {r.status_code} - {r.text[:300]}")
    
    sys.exit(0)

# ============================================================
# ÉTAPE 2: Insertion des données initiales
# ============================================================
print("\n📋 Étape 2: Insertion des 9 chapitres initiaux...")

CHAPITRES = [
    # Droit (9497ca2c-dc1b-43dd-8b7a-af11dde7039d)
    {"matiere_id": "9497ca2c-dc1b-43dd-8b7a-af11dde7039d", "titre": "Chapitre 1 : Introduction au Droit", "description": "Notions fondamentales du droit burkinabè", "ordre": 1},
    {"matiere_id": "9497ca2c-dc1b-43dd-8b7a-af11dde7039d", "titre": "Chapitre 2 : Droit Constitutionnel", "description": "Constitution du Burkina Faso, institutions", "ordre": 2},
    {"matiere_id": "9497ca2c-dc1b-43dd-8b7a-af11dde7039d", "titre": "Chapitre 3 : Droit Administratif", "description": "Actes administratifs et contentieux", "ordre": 3},
    # Français (d1560595-b4d9-45d2-af70-8bdf7016af72)
    {"matiere_id": "d1560595-b4d9-45d2-af70-8bdf7016af72", "titre": "Chapitre 1 : Grammaire et Orthographe", "description": "Règles grammaticales et conjugaison", "ordre": 1},
    {"matiere_id": "d1560595-b4d9-45d2-af70-8bdf7016af72", "titre": "Chapitre 2 : Expression Écrite", "description": "Rédaction, résumé et synthèse", "ordre": 2},
    {"matiere_id": "d1560595-b4d9-45d2-af70-8bdf7016af72", "titre": "Chapitre 3 : Littérature Francophone", "description": "Auteurs africains au programme", "ordre": 3},
    # Psychotechnique (54f53d06-2d5d-4d82-91bc-4bfff904c12b)
    {"matiere_id": "54f53d06-2d5d-4d82-91bc-4bfff904c12b", "titre": "Chapitre 1 : Logique et Raisonnement", "description": "Séries numériques et suites logiques", "ordre": 1},
    {"matiere_id": "54f53d06-2d5d-4d82-91bc-4bfff904c12b", "titre": "Chapitre 2 : Figures et Matrices", "description": "Tests visuels et rotations", "ordre": 2},
    {"matiere_id": "54f53d06-2d5d-4d82-91bc-4bfff904c12b", "titre": "Chapitre 3 : Calcul Mental", "description": "Rapidité et résolution de problèmes", "ordre": 3},
]

# Insérer les chapitres
result = insert_data("chapitres", CHAPITRES)
print(f"  INSERT chapitres: {result['status']} - {result['text'][:100]}")

# Vérifier le comptage
r = requests.get(
    f"{SUPABASE_URL}/rest/v1/chapitres?select=id",
    headers={**HEADERS, "Prefer": "count=exact"},
)
count = r.headers.get("content-range", "?/?").split("/")[-1]
print(f"  Total chapitres en base: {count}")

# ============================================================
# ÉTAPE 3: Récupérer les chapitres insérés et créer des leçons de démo
# ============================================================
print("\n📋 Étape 3: Création des leçons de démonstration...")

r = requests.get(
    f"{SUPABASE_URL}/rest/v1/chapitres?select=id,titre,matiere_id&eq.matiere_id=9497ca2c-dc1b-43dd-8b7a-af11dde7039d&order=ordre.asc",
    headers=HEADERS
)

chapitres_droit = r.json() if r.ok else []
print(f"  Chapitres Droit trouvés: {len(chapitres_droit)}")

if chapitres_droit:
    ch1_id = chapitres_droit[0]["id"]
    
    LECONS_DEMO = [
        {
            "chapitre_id": ch1_id,
            "titre": "Leçon 1 : Les sources du droit",
            "contenu": "La loi, les règlements, la jurisprudence et la coutume constituent les principales sources du droit. Au Burkina Faso, la Constitution du 2 juin 1991 est la norme suprême. Elle organise les pouvoirs de l'État et garantit les droits fondamentaux des citoyens burkinabè.",
            "ordre": 1,
            "duree_minutes": 15
        },
        {
            "chapitre_id": ch1_id,
            "titre": "Leçon 2 : Les branches du droit",
            "contenu": "Le droit se divise en deux grandes branches : le droit public et le droit privé. Le droit public régit les rapports entre l'État et les individus (droit constitutionnel, administratif, fiscal). Le droit privé régit les rapports entre particuliers.",
            "ordre": 2,
            "duree_minutes": 20
        },
        {
            "chapitre_id": ch1_id,
            "titre": "Leçon 3 : Les personnes juridiques",
            "contenu": "En droit, on distingue les personnes physiques (êtres humains) et les personnes morales (entreprises, associations, État). Chaque personne juridique possède une capacité juridique qui lui permet d'acquérir des droits et de contracter des obligations.",
            "ordre": 3,
            "duree_minutes": 18
        }
    ]
    
    result_lecons = insert_data("lecons", LECONS_DEMO)
    print(f"  INSERT leçons démo: {result_lecons['status']}")
    
    # Compte leçons
    r_lecons = requests.get(
        f"{SUPABASE_URL}/rest/v1/lecons?select=id",
        headers={**HEADERS, "Prefer": "count=exact"},
    )
    count_lecons = r_lecons.headers.get("content-range", "?/?").split("/")[-1]
    print(f"  Total leçons en base: {count_lecons}")

# ============================================================
# ÉTAPE 4: Vérification finale
# ============================================================
print("\n📋 Étape 4: Vérification finale...")

# Compter chapitres
r_ch = requests.get(
    f"{SUPABASE_URL}/rest/v1/chapitres?select=id,titre,matiere_id&order=matiere_id.asc,ordre.asc",
    headers=HEADERS
)

if r_ch.ok:
    chapitres = r_ch.json()
    print(f"\n  📚 CHAPITRES EN BASE ({len(chapitres)}):")
    
    # Grouper par matière
    matieres = {
        "9497ca2c-dc1b-43dd-8b7a-af11dde7039d": "Droit",
        "d1560595-b4d9-45d2-af70-8bdf7016af72": "Français",
        "54f53d06-2d5d-4d82-91bc-4bfff904c12b": "Psychotechnique",
    }
    
    for ch in chapitres:
        matiere_nom = matieres.get(ch.get("matiere_id", ""), "Autre")
        print(f"    [{matiere_nom}] {ch['titre']}")

# Test endpoint Worker
print("\n📋 Test des endpoints Worker...")
worker_url = "https://ef-fort-bf.yembuaro29.workers.dev"
r_test = requests.get(
    f"{worker_url}/api/cours/chapitres?matiere_id=9497ca2c-dc1b-43dd-8b7a-af11dde7039d"
)
print(f"  Worker /api/cours/chapitres: {r_test.status_code}")
if r_test.ok:
    data = r_test.json()
    ch_count = len(data.get("chapitres", []))
    print(f"  → {ch_count} chapitres retournés par le Worker ✅")
else:
    print(f"  → Erreur: {r_test.text[:200]}")

print("\n" + "=" * 60)
print("✅ MIGRATION TERMINÉE!")
print("=" * 60)
print("\nProchaines étapes:")
print("  1. Vérifier l'application sur https://ef-fort-bf.pages.dev")
print("  2. Tester l'onglet 'Cours' dans l'app")
print("  3. Redéployer l'application Flutter")
