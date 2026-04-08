#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour finaliser complètement les 3 séries par examen type
- Correction des titres des Séries 1 (IDs 66-75)
- Vérification des 50 questions par série
- Vérification des doublons
"""

from supabase import create_client, Client
import json

# Configuration Supabase
SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

def init_supabase() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_KEY)

# Mapping des IDs aux types d'examens
SERIES_1_MAPPING = {
    66: "Administration générale",
    67: "Justice & sécurité",
    68: "Économie & finances",
    69: "Concours de la santé",
    70: "Éducation & formation",
    71: "Concours techniques",
    72: "Agriculture & environnement",
    73: "Informatique & numérique",
    74: "Travaux publics & urbanisme",
    75: "Statistiques & planification"
}

def update_series_1_titles():
    """Mettre à jour les titres des Séries 1 pour inclure '— Série 1'"""
    supabase = init_supabase()
    
    print("="*80)
    print("MISE À JOUR DES TITRES DES SÉRIES 1")
    print("="*80)
    
    for exam_id, exam_type in SERIES_1_MAPPING.items():
        # Récupérer l'enregistrement actuel
        response = supabase.table('simulations_examens').select('*').eq('id', exam_id).execute()
        if not response.data:
            print(f"❌ ID {exam_id} non trouvé")
            continue
        
        exam = response.data[0]
        old_titre = exam['titre']
        
        # Créer le nouveau titre avec "— Série 1"
        if "Série 1" not in old_titre and "— 1" not in old_titre:
            new_titre = old_titre.replace("— Série", "— Série 1 —").replace(" — Concours", " — Série 1 — Concours")
            if "Série 1" not in new_titre:
                # Si le format ne correspond pas, ajouter simplement
                new_titre = old_titre.replace(" —", " — Série 1 —")
            
            # Mettre à jour
            update_data = {'titre': new_titre}
            supabase.table('simulations_examens').update(update_data).eq('id', exam_id).execute()
            
            print(f"✓ ID {exam_id}: {exam_type}")
            print(f"  Ancien: {old_titre[:80]}...")
            print(f"  Nouveau: {new_titre[:80]}...")
        else:
            print(f"✓ ID {exam_id}: {exam_type} - Déjà OK")

def verify_series_structure():
    """Vérifier la structure complète des séries"""
    supabase = init_supabase()
    
    print("\n" + "="*80)
    print("VÉRIFICATION DE LA STRUCTURE DES SÉRIES")
    print("="*80)
    
    exam_types = [
        "Administration générale",
        "Justice & sécurité",
        "Économie & finances",
        "Concours de la santé",
        "Éducation & formation",
        "Concours techniques",
        "Agriculture & environnement",
        "Informatique & numérique",
        "Travaux publics & urbanisme",
        "Statistiques & planification"
    ]
    
    results = {}
    
    for exam_type in exam_types:
        print(f"\n📋 {exam_type}")
        
        # Récupérer toutes les séries (IDs connus)
        series_ids = []
        
        # Série 1: IDs 66-75
        for exam_id, etype in SERIES_1_MAPPING.items():
            if etype == exam_type:
                series_ids.append((1, exam_id))
        
        # Série 2: IDs 76-85 (offset de +10)
        for exam_id, etype in SERIES_1_MAPPING.items():
            if etype == exam_type:
                series_ids.append((2, exam_id + 10))
        
        # Série 3: IDs 107-116 (offset de +41)
        for exam_id, etype in SERIES_1_MAPPING.items():
            if etype == exam_type:
                series_ids.append((3, exam_id + 41))
        
        # Vérifier chaque série
        all_questions_sets = []
        all_ok = True
        
        for serie_num, serie_id in series_ids:
            response = supabase.table('simulations_examens').select('*').eq('id', serie_id).execute()
            
            if not response.data:
                print(f"  ❌ Série {serie_num} (ID {serie_id}): NON TROUVÉE")
                all_ok = False
                continue
            
            exam = response.data[0]
            question_ids = exam.get('question_ids', [])
            num_questions = len(question_ids)
            
            status = "✓" if num_questions == 50 else f"⚠️ {num_questions} Q"
            print(f"  {status} Série {serie_num} (ID {serie_id}): {num_questions} questions")
            
            if num_questions != 50:
                all_ok = False
            
            all_questions_sets.append(set(question_ids))
        
        # Vérifier les doublons entre séries
        if len(all_questions_sets) >= 2:
            duplicates_found = False
            for i in range(len(all_questions_sets)):
                for j in range(i+1, len(all_questions_sets)):
                    intersection = all_questions_sets[i] & all_questions_sets[j]
                    if intersection:
                        print(f"  ⚠️  {len(intersection)} doublons entre Série {i+1} et Série {j+1}")
                        duplicates_found = True
                        all_ok = False
            
            if not duplicates_found:
                print(f"  ✓ Aucun doublon entre les séries")
        
        results[exam_type] = all_ok
    
    return results

def generate_final_report():
    """Générer le rapport final"""
    print("\n" + "="*80)
    print("RAPPORT FINAL")
    print("="*80)
    
    # Re-vérifier après les mises à jour
    results = verify_series_structure()
    
    print("\n📊 RÉCAPITULATIF:")
    success = sum(1 for v in results.values() if v)
    total = len(results)
    
    print(f"\n  Examens types finalisés: {success}/{total}")
    
    for exam_type, ok in results.items():
        status = "✅" if ok else "⚠️"
        print(f"  {status} {exam_type}")
    
    if success == total:
        print("\n🎉 TOUS LES EXAMENS TYPES SONT FINALISÉS!")
        print("   - Chaque examen a 3 séries")
        print("   - Chaque série a 50 questions")
        print("   - Aucun doublon détecté")
    else:
        print(f"\n⚠️  {total - success} examens nécessitent encore des ajustements")

def main():
    print("="*80)
    print("FINALISATION DES 3 SÉRIES PAR EXAMEN TYPE")
    print("="*80)
    
    # Étape 1: Corriger les titres des Séries 1
    update_series_1_titles()
    
    # Étape 2: Vérifier la structure complète
    verify_series_structure()
    
    # Étape 3: Générer le rapport final
    generate_final_report()
    
    print("\n✅ PROCESSUS TERMINÉ")

if __name__ == "__main__":
    main()
