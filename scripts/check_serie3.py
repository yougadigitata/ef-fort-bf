#!/usr/bin/env python3
"""
Script pour vérifier et créer la Série 3 des Examens Types
Vérification des IDs 107-116 dans simulations_examens
"""

import os
import sys
from supabase import create_client, Client

# Configuration Supabase
SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def check_serie3():
    """Vérifier si les IDs 107-116 existent dans simulations_examens"""
    print("🔍 Vérification de la Série 3 (IDs 107-116)...")
    
    try:
        # Récupérer les simulations avec IDs entre 107 et 116
        response = supabase.table('simulations_examens').select('*').gte('id', 107).lte('id', 116).execute()
        
        existing_ids = {item['id'] for item in response.data}
        expected_ids = set(range(107, 117))  # 107 à 116 inclus
        missing_ids = expected_ids - existing_ids
        
        print(f"\n✅ IDs existants: {sorted(existing_ids)}")
        print(f"❌ IDs manquants: {sorted(missing_ids)}")
        
        if missing_ids:
            print(f"\n⚠️  {len(missing_ids)} entrées manquantes pour la Série 3")
            return False, missing_ids
        else:
            print("\n✅ Tous les IDs de la Série 3 existent !")
            
            # Vérifier si les question_ids sont vides
            empty_questions = []
            for item in response.data:
                q_ids = item.get('question_ids', [])
                if not q_ids or len(q_ids) == 0:
                    empty_questions.append(item['id'])
            
            if empty_questions:
                print(f"\n⚠️  {len(empty_questions)} séries ont des question_ids vides: {empty_questions}")
                return False, empty_questions
            else:
                print("✅ Toutes les séries ont des questions !")
                return True, []
                
    except Exception as e:
        print(f"❌ Erreur lors de la vérification: {e}")
        return False, []

def get_table_structure():
    """Afficher la structure de la table simulations_examens"""
    print("\n📊 Structure de la table simulations_examens:")
    try:
        response = supabase.table('simulations_examens').select('*').limit(1).execute()
        if response.data:
            print(f"Colonnes: {list(response.data[0].keys())}")
            print(f"Exemple: {response.data[0]}")
    except Exception as e:
        print(f"❌ Erreur: {e}")

if __name__ == "__main__":
    print("=" * 60)
    print("    VÉRIFICATION SÉRIE 3 - EF-FORT.BF")
    print("=" * 60)
    
    get_table_structure()
    success, missing = check_serie3()
    
    print("\n" + "=" * 60)
    if success:
        print("✅ RÉSULTAT: Série 3 complète et prête !")
    else:
        print("⚠️  RÉSULTAT: Actions nécessaires")
        print(f"   - Créer les entrées manquantes")
        print(f"   - Remplir les question_ids")
    print("=" * 60)
    
    sys.exit(0 if success else 1)
