#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour vérifier la structure de la base de données
"""

from supabase import create_client, Client

# Configuration Supabase
SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

def init_supabase() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_KEY)

def main():
    supabase = init_supabase()
    
    print("="*60)
    print("VÉRIFICATION DE LA STRUCTURE simulations_examens")
    print("="*60)
    
    # Récupérer quelques enregistrements pour voir la structure
    response = supabase.table('simulations_examens').select('*').limit(5).execute()
    
    if response.data:
        print(f"\n✓ {len(response.data)} enregistrements trouvés")
        print("\n📋 Structure d'un enregistrement:")
        first = response.data[0]
        for key, value in first.items():
            print(f"  - {key}: {type(value).__name__} = {value}")
    
    print("\n" + "="*60)
    print("VÉRIFICATION DES EXAMENS TYPES (IDs 66-116)")
    print("="*60)
    
    # Récupérer les examens types
    response = supabase.table('simulations_examens').select('*').gte('id', 66).lte('id', 116).order('id').execute()
    
    print(f"\n✓ {len(response.data)} séries trouvées")
    
    # Grouper par type d'examen
    exam_groups = {}
    for exam in response.data:
        exam_type = exam.get('exam_type_name', exam.get('type', 'Unknown'))
        if exam_type not in exam_groups:
            exam_groups[exam_type] = []
        exam_groups[exam_type].append(exam)
    
    print(f"\n📊 {len(exam_groups)} types d'examens trouvés:")
    for exam_type, exams in sorted(exam_groups.items()):
        print(f"\n  {exam_type}: {len(exams)} séries")
        for exam in exams:
            serie_num = exam.get('serie_number', '?')
            exam_id = exam.get('id', '?')
            print(f"    - ID {exam_id}, Série {serie_num}")
    
    print("\n" + "="*60)
    print("VÉRIFICATION DES QUESTIONS PAR SÉRIE")
    print("="*60)
    
    # Compter les questions pour chaque série
    for exam_id in range(66, 117):
        questions_response = supabase.table('simulation_questions').select('question_id').eq('simulation_id', exam_id).execute()
        count = len(questions_response.data)
        if count > 0:
            print(f"  Série ID {exam_id}: {count} questions")
    
    print("\n✅ VÉRIFICATION TERMINÉE")

if __name__ == "__main__":
    main()
