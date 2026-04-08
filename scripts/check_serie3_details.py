#!/usr/bin/env python3
"""
Vérifier le nombre de questions dans chaque Série 3
"""

import sys
from supabase import create_client, Client

# Configuration Supabase
SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def check_serie3_questions():
    """Vérifier le contenu de chaque Série 3"""
    print("📊 Vérification du contenu de chaque Série 3 (IDs 107-116)")
    print("=" * 80)
    
    try:
        response = supabase.table('simulations_examens').select('*').gte('id', 107).lte('id', 116).order('id').execute()
        
        for item in response.data:
            id_sim = item['id']
            titre = item.get('titre', 'Sans titre')
            q_ids = item.get('question_ids', [])
            nb_questions = len(q_ids) if q_ids else 0
            
            status = "✅" if nb_questions == 50 else "⚠️"
            print(f"{status} ID {id_sim:3d}: {nb_questions:2d} questions - {titre}")
        
        print("=" * 80)
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        sys.exit(1)

if __name__ == "__main__":
    check_serie3_questions()
