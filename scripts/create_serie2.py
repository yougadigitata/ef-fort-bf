#!/usr/bin/env python3
"""
Script de création des 10 nouvelles Séries 2 dans les Examens Types
- Copie des questions depuis les matières sources
- Vérification des doublons avec la Série 1
- Mise à jour des question_ids dans simulations_examens
"""

import uuid
import json
from datetime import datetime, timezone
from supabase import create_client

SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# ============================================================
# MAP DES MATIÈRES (nom -> id)
# ============================================================
MATIERES = {
    "Actualité Internationale":  "5f7ef458-9fd3-4f70-b498-d3391b5d5677",
    "Alliance des États du Sahel": "c7681b66-91af-423b-9ef6-becbe8f5bd85",
    "Anglais":                   "37febc5e-8ab5-4875-b7ad-71b30a8253e7",
    "Burkina Faso":              "7c2b0599-4971-4d31-87ce-aeeb5c5cb394",
    "Communication":             "cc979206-e60d-4224-940d-943b8c68c8fa",
    "Culture Générale":          "70795d8a-0691-407e-abce-59202590f4f3",
    "Droit":                     "9497ca2c-dc1b-43dd-8b7a-af11dde7039d",
    "Figure Africaine":          "104f51e4-be6e-4ce8-961e-56e604818670",
    "Force Armée Nationale":     "b8df7f6e-587d-4871-856c-30dbaa6a52c3",
    "Français":                  "d1560595-b4d9-45d2-af70-8bdf7016af72",
    "Guide Panafricain":         "a0b2c3c5-8dbf-4c7f-ab73-356530962c48",
    "Histoire-Géographie":       "0a88b3ac-33b7-4d8c-bc19-fe68bb514aef",
    "Informatique":              "a72cc6f9-1282-4c2a-ae19-298933047694",
    "Mathématiques":             "9005951c-331e-4ce7-90e4-887bd26d0b3e",
    "Psychotechnique":           "54f53d06-2d5d-4d82-91bc-4bfff904c12b",
    "SVT":                       "7dd7029c-76cf-4d36-9912-7d60fbac7bba",
    "Sciences Physiques":        "12e5b05a-6410-4b55-97b7-b8a838dcfb9a",
    "Économie":                  "756e1ca6-7f7f-4f42-940a-b6d9952ffcdf",
}

# ============================================================
# IDs DES SÉRIES 1 (à NE PAS dupliquer)
# ============================================================
SERIE1_IDS = {
    "Admin":       66,
    "Justice":     67,
    "Eco":         68,
    "Sante":       69,
    "Education":   70,
    "Technique":   71,
    "Agriculture": 72,
    "Info":        73,
    "Travaux":     74,
    "Stats":       75,
}

# ============================================================
# COMPOSITION DES 10 NOUVELLES SÉRIES (Série 2)
# ============================================================
SERIES_2_CONFIG = [
    {
        "titre": "Examen Type — Administration générale — Série 2",
        "serie1_id": 66,
        "description": "Deuxième série de l'examen type Administration générale — Droit, Français, Communication, Culture Générale",
        "composition": [
            ("Droit",            15),
            ("Français",         15),
            ("Communication",    10),
            ("Culture Générale", 10),
        ]
    },
    {
        "titre": "Examen Type — Justice & sécurité — Série 2",
        "serie1_id": 67,
        "description": "Deuxième série de l'examen type Justice & sécurité — Droit, Force Armée Nationale, Actualité Internationale, Culture Générale",
        "composition": [
            ("Droit",                    20),
            ("Force Armée Nationale",    15),
            ("Actualité Internationale", 10),
            ("Culture Générale",          5),
        ]
    },
    {
        "titre": "Examen Type — Économie & finances — Série 2",
        "serie1_id": 68,
        "description": "Deuxième série de l'examen type Économie & finances — Économie, Mathématiques, Actualité Internationale, Anglais",
        "composition": [
            ("Économie",                 20),
            ("Mathématiques",            15),
            ("Actualité Internationale", 10),
            ("Anglais",                   5),
        ]
    },
    {
        "titre": "Examen Type — Concours de la santé — Série 2",
        "serie1_id": 69,
        "description": "Deuxième série de l'examen type Concours de la santé — SVT, Sciences Physiques, Anglais, Culture Générale",
        "composition": [
            ("SVT",              20),
            ("Sciences Physiques", 15),
            ("Anglais",           10),
            ("Culture Générale",   5),
        ]
    },
    {
        "titre": "Examen Type — Éducation & formation — Série 2",
        "serie1_id": 70,
        "description": "Deuxième série de l'examen type Éducation & formation — Français, Anglais, Histoire-Géographie, Culture Générale",
        "composition": [
            ("Français",           20),
            ("Anglais",            10),
            ("Histoire-Géographie", 10),
            ("Culture Générale",   10),
        ]
    },
    {
        "titre": "Examen Type — Concours techniques — Série 2",
        "serie1_id": 71,
        "description": "Deuxième série de l'examen type Concours techniques — Psychotechnique, Mathématiques, Sciences Physiques, Anglais",
        "composition": [
            ("Psychotechnique",    20),
            ("Mathématiques",      15),
            ("Sciences Physiques", 10),
            ("Anglais",             5),
        ]
    },
    {
        "titre": "Examen Type — Agriculture & environnement — Série 2",
        "serie1_id": 72,
        "description": "Deuxième série de l'examen type Agriculture & environnement — Burkina Faso, Histoire-Géographie, SVT, Culture Générale",
        "composition": [
            ("Burkina Faso",        20),
            ("Histoire-Géographie", 15),
            ("SVT",                 10),
            ("Culture Générale",     5),
        ]
    },
    {
        "titre": "Examen Type — Informatique & numérique — Série 2",
        "serie1_id": 73,
        "description": "Deuxième série de l'examen type Informatique & numérique — Informatique, Mathématiques, Anglais, Culture Générale",
        "composition": [
            ("Informatique",       25),
            ("Mathématiques",      10),
            ("Anglais",            10),
            ("Culture Générale",    5),
        ]
    },
    {
        "titre": "Examen Type — Travaux publics & urbanisme — Série 2",
        "serie1_id": 74,
        "description": "Deuxième série de l'examen type Travaux publics & urbanisme — Mathématiques, Sciences Physiques, Droit, Culture Générale",
        "composition": [
            ("Mathématiques",      20),
            ("Sciences Physiques", 15),
            ("Droit",              10),
            ("Culture Générale",    5),
        ]
    },
    {
        "titre": "Examen Type — Statistiques & planification — Série 2",
        "serie1_id": 75,
        "description": "Deuxième série de l'examen type Statistiques & planification — Mathématiques, Économie, Psychotechnique",
        "composition": [
            ("Mathématiques",   25),
            ("Économie",        15),
            ("Psychotechnique", 10),
        ]
    },
]

def get_serie1_question_ids(serie1_sim_id):
    """Récupère les IDs de questions de la Série 1 d'un examen type."""
    result = supabase.table("simulations_examens").select("question_ids").eq("id", serie1_sim_id).execute()
    if result.data:
        return set(result.data[0].get('question_ids') or [])
    return set()

def get_questions_by_matiere(matiere_id, exclude_ids, limit):
    """
    Récupère les N premières questions d'une matière (les plus anciennes),
    en excluant les IDs déjà utilisés.
    Retourne une liste de dicts (questions complètes).
    """
    # On pagine pour s'assurer d'avoir assez de questions
    collected = []
    page = 0
    page_size = 200
    
    while len(collected) < limit:
        result = supabase.table("questions").select("*").eq("matiere_id", matiere_id).order("created_at", desc=False).range(page * page_size, (page + 1) * page_size - 1).execute()
        
        if not result.data:
            break
        
        for q in result.data:
            if q['id'] not in exclude_ids:
                collected.append(q)
                if len(collected) >= limit:
                    break
        
        if len(result.data) < page_size:
            break
        page += 1
    
    return collected[:limit]

def copy_question_for_simulation(q_source, new_simulation_id, numero):
    """
    Copie une question source en créant une nouvelle entrée dans la table questions
    avec le simulation_id fourni.
    Les questions dans les simulations_examens ont un serie_id NULL ou un serie_id spécial.
    On garde le même enonce, options, reponse, explication.
    """
    new_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    
    new_q = {
        "id": new_id,
        "serie_id": q_source.get("serie_id"),  # Garde la référence à la série source
        "matiere_id": q_source.get("matiere_id"),
        "numero": numero,
        "enonce": q_source.get("enonce"),
        "type": q_source.get("type", "QCM"),
        "option_a": q_source.get("option_a"),
        "option_b": q_source.get("option_b"),
        "option_c": q_source.get("option_c"),
        "option_d": q_source.get("option_d"),
        "option_e": q_source.get("option_e"),
        "mot_a": q_source.get("mot_a"),
        "mot_b": q_source.get("mot_b"),
        "indice": q_source.get("indice"),
        "bonne_reponse": q_source.get("bonne_reponse"),
        "explication": q_source.get("explication"),
        "difficulte": q_source.get("difficulte", "MOYEN"),
        "tags": q_source.get("tags"),
        "created_at": now,
        "created_by": "system-serie2",
        "updated_at": now,
        "published": True,
        "numero_serie": 2,
        "version": 1,
        "pieges": q_source.get("pieges"),
        "sources": q_source.get("sources"),
    }
    return new_id, new_q

def create_simulation_serie2(config):
    """Crée une nouvelle simulation (Série 2) pour un examen type."""
    titre = config["titre"]
    serie1_id = config["serie1_id"]
    description = config["description"]
    composition = config["composition"]
    
    print(f"\n{'='*60}")
    print(f"CRÉATION: {titre}")
    print(f"{'='*60}")
    
    # 1. Récupérer les IDs de la Série 1 pour éviter les doublons
    serie1_q_ids = get_serie1_question_ids(serie1_id)
    print(f"  Série 1 ({serie1_id}): {len(serie1_q_ids)} questions à exclure")
    
    # 2. Créer l'entrée dans simulations_examens (vide pour l'instant)
    now = datetime.now(timezone.utc).isoformat()
    sim_data = {
        "titre": titre,
        "description": description,
        "duree_minutes": 60,
        "score_max": 50,
        "question_ids": [],
        "created_by": "system-serie2",
        "published": True,
        "show_corrections": True,
        "show_score_after": True,
    }
    
    sim_result = supabase.table("simulations_examens").insert(sim_data).execute()
    if not sim_result.data:
        print(f"  ERREUR: Impossible de créer la simulation!")
        return None
    
    new_sim_id = sim_result.data[0]["id"]
    print(f"  Simulation créée avec id={new_sim_id}")
    
    # 3. Pour chaque matière, récupérer les questions
    all_excluded = set(serie1_q_ids)  # Commence par exclure la Série 1
    all_new_question_ids = []
    numero_counter = 1
    questions_to_insert = []
    
    for matiere_nom, nb_needed in composition:
        matiere_id = MATIERES.get(matiere_nom)
        if not matiere_id:
            print(f"  AVERTISSEMENT: Matière '{matiere_nom}' non trouvée!")
            continue
        
        print(f"\n  Matière: {matiere_nom} ({nb_needed} questions demandées)")
        
        # Récupérer les questions disponibles
        questions = get_questions_by_matiere(matiere_id, all_excluded, nb_needed)
        nb_found = len(questions)
        print(f"    -> {nb_found} questions récupérées (demandé: {nb_needed})")
        
        if nb_found < nb_needed:
            print(f"    AVERTISSEMENT: Manque {nb_needed - nb_found} questions dans '{matiere_nom}'!")
        
        for q in questions:
            new_id, new_q = copy_question_for_simulation(q, new_sim_id, numero_counter)
            questions_to_insert.append(new_q)
            all_new_question_ids.append(new_id)
            all_excluded.add(new_id)
            all_excluded.add(q['id'])  # Exclure aussi l'original des futurs tirages
            numero_counter += 1
    
    # 4. Insérer les nouvelles questions par batch
    print(f"\n  Insertion de {len(questions_to_insert)} questions...")
    batch_size = 50
    for i in range(0, len(questions_to_insert), batch_size):
        batch = questions_to_insert[i:i+batch_size]
        insert_result = supabase.table("questions").insert(batch).execute()
        if insert_result.data:
            print(f"    Batch {i//batch_size + 1}: {len(insert_result.data)} questions insérées")
        else:
            print(f"    ERREUR lors de l'insertion du batch {i//batch_size + 1}")
    
    # 5. Mettre à jour le champ question_ids de la simulation
    print(f"\n  Mise à jour question_ids ({len(all_new_question_ids)} IDs)...")
    update_result = supabase.table("simulations_examens").update(
        {"question_ids": all_new_question_ids}
    ).eq("id", new_sim_id).execute()
    
    if update_result.data:
        print(f"  OK: question_ids mis à jour - {len(all_new_question_ids)} questions")
    else:
        print(f"  ERREUR: Impossible de mettre à jour question_ids!")
    
    return {
        "sim_id": new_sim_id,
        "titre": titre,
        "nb_questions": len(all_new_question_ids),
    }

def main():
    print("="*60)
    print("CRÉATION DES 10 NOUVELLES SÉRIES (SÉRIE 2) — EXAMENS TYPES")
    print("="*60)
    
    results = []
    
    for config in SERIES_2_CONFIG:
        result = create_simulation_serie2(config)
        if result:
            results.append(result)
            print(f"\n  ✅ {result['titre']} — {result['nb_questions']} questions (id={result['sim_id']})")
        else:
            print(f"\n  ❌ ÉCHEC pour: {config['titre']}")
    
    print("\n" + "="*60)
    print("RÉSUMÉ FINAL")
    print("="*60)
    for r in results:
        print(f"  id={r['sim_id']}: {r['titre']} — {r['nb_questions']} questions")
    
    print(f"\nTotal: {len(results)}/10 séries créées")
    
    # Sauvegarde du résumé
    with open("/home/user/ef-fort-bf/scripts/serie2_results.json", "w") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print("\nRésultats sauvegardés dans scripts/serie2_results.json")

if __name__ == "__main__":
    main()
