#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour comprendre la structure complète et créer/compléter les séries 3
"""

from supabase import create_client, Client
import json

# Configuration Supabase
SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

def init_supabase() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_KEY)

def analyze_exam_series():
    """Analyser les séries d'examens types"""
    supabase = init_supabase()
    
    print("="*80)
    print("ANALYSE DES EXAMENS TYPES (IDs 66-116)")
    print("="*80)
    
    # Récupérer tous les examens types
    response = supabase.table('simulations_examens').select('*').gte('id', 66).lte('id', 116).order('id').execute()
    
    print(f"\n✓ {len(response.data)} enregistrements trouvés\n")
    
    # Analyser les titres pour identifier les types d'examens et séries
    exam_analysis = {}
    
    for exam in response.data:
        exam_id = exam['id']
        titre = exam['titre']
        question_ids = exam.get('question_ids', [])
        num_questions = len(question_ids) if question_ids else 0
        
        # Extraire le type d'examen et le numéro de série depuis le titre
        exam_type = None
        serie_num = None
        
        # Identifier le type d'examen
        if "Administration générale" in titre:
            exam_type = "Administration générale"
        elif "Justice" in titre or "sécurité" in titre:
            exam_type = "Justice & sécurité"
        elif "Économie" in titre or "finances" in titre:
            exam_type = "Économie & finances"
        elif "santé" in titre:
            exam_type = "Concours de la santé"
        elif "Éducation" in titre or "formation" in titre:
            exam_type = "Éducation & formation"
        elif "techniques" in titre:
            exam_type = "Concours techniques"
        elif "Agriculture" in titre or "environnement" in titre:
            exam_type = "Agriculture & environnement"
        elif "Informatique" in titre or "numérique" in titre:
            exam_type = "Informatique & numérique"
        elif "Travaux publics" in titre or "urbanisme" in titre:
            exam_type = "Travaux publics & urbanisme"
        elif "Statistiques" in titre or "planification" in titre:
            exam_type = "Statistiques & planification"
        elif "Examen blanc" in titre:
            exam_type = "Examen Blanc"
        
        # Identifier le numéro de série
        if "Série 1" in titre or "— 1" in titre:
            serie_num = 1
        elif "Série 2" in titre or "— 2" in titre:
            serie_num = 2
        elif "Série 3" in titre or "— 3" in titre:
            serie_num = 3
        
        # Stocker l'analyse
        if exam_type:
            if exam_type not in exam_analysis:
                exam_analysis[exam_type] = {}
            if serie_num:
                exam_analysis[exam_type][serie_num] = {
                    'id': exam_id,
                    'titre': titre,
                    'num_questions': num_questions,
                    'question_ids': question_ids
                }
        
        print(f"ID {exam_id:3d} | {serie_num if serie_num else '?'} | {num_questions:2d} Q | {exam_type or 'Unknown'}")
        if num_questions != 50 and exam_type != "Examen Blanc":
            print(f"         ⚠️  ATTENTION: {num_questions} questions (attendu: 50)")
    
    print("\n" + "="*80)
    print("RÉSUMÉ PAR TYPE D'EXAMEN")
    print("="*80)
    
    exam_types_to_process = [
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
    
    for exam_type in exam_types_to_process:
        print(f"\n📋 {exam_type}:")
        if exam_type in exam_analysis:
            series = exam_analysis[exam_type]
            for serie_num in [1, 2, 3]:
                if serie_num in series:
                    s = series[serie_num]
                    status = "✓" if s['num_questions'] == 50 else f"⚠️ {s['num_questions']} Q"
                    print(f"  Série {serie_num} (ID {s['id']:3d}): {status}")
                else:
                    print(f"  Série {serie_num}: ❌ MANQUANTE")
        else:
            print(f"  ❌ Aucune série trouvée")
    
    # Sauvegarder l'analyse pour utilisation ultérieure
    with open('/home/user/ef-fort-bf/scripts/exam_analysis.json', 'w', encoding='utf-8') as f:
        json.dump(exam_analysis, f, indent=2, ensure_ascii=False)
    
    print("\n✅ Analyse sauvegardée dans exam_analysis.json")
    return exam_analysis

if __name__ == "__main__":
    analyze_exam_series()
