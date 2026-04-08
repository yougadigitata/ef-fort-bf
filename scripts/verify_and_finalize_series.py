#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de vérification et finalisation des 3 séries par examen type
"""

import os
import sys
from supabase import create_client, Client
from collections import defaultdict

# Configuration Supabase
SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

# Tableau de composition intelligente
EXAM_COMPOSITION = {
    "Administration générale": {
        "materials": ["Droit", "Français", "Communication", "Culture Générale"],
        "distribution": [15, 15, 10, 10]
    },
    "Justice & sécurité": {
        "materials": ["Droit", "Force Armée Nationale", "Actualité Internationale", "Culture Générale"],
        "distribution": [20, 15, 10, 5]
    },
    "Économie & finances": {
        "materials": ["Économie", "Mathématiques", "Actualité Internationale", "Anglais"],
        "distribution": [20, 15, 10, 5]
    },
    "Concours de la santé": {
        "materials": ["SVT", "Sciences Physiques", "Anglais", "Culture Générale"],
        "distribution": [20, 15, 10, 5]
    },
    "Éducation & formation": {
        "materials": ["Français", "Anglais", "Histoire-Géographie", "Culture Générale"],
        "distribution": [20, 10, 10, 10]
    },
    "Concours techniques": {
        "materials": ["Psychotechnique", "Mathématiques", "Sciences Physiques", "Anglais"],
        "distribution": [20, 15, 10, 5]
    },
    "Agriculture & environnement": {
        "materials": ["Burkina Faso", "Histoire-Géographie", "SVT", "Culture Générale"],
        "distribution": [20, 15, 10, 5]
    },
    "Informatique & numérique": {
        "materials": ["Informatique", "Mathématiques", "Anglais", "Culture Générale"],
        "distribution": [25, 10, 10, 5]
    },
    "Travaux publics & urbanisme": {
        "materials": ["Mathématiques", "Sciences Physiques", "Droit", "Culture Générale"],
        "distribution": [20, 15, 10, 5]
    },
    "Statistiques & planification": {
        "materials": ["Mathématiques", "Économie", "Psychotechnique", "Culture Générale"],
        "distribution": [25, 15, 10, 0]
    }
}

def init_supabase() -> Client:
    """Initialize Supabase client"""
    return create_client(SUPABASE_URL, SUPABASE_KEY)

def get_exam_types(supabase: Client):
    """Récupérer les examens types (IDs 66-85 pour S1/S2)"""
    response = supabase.table('simulations_examens').select('*').gte('id', 66).lte('id', 85).execute()
    return response.data

def get_series_for_exam(supabase: Client, exam_type_name: str):
    """Récupérer toutes les séries d'un examen type"""
    response = supabase.table('simulations_examens').select('*').eq('name', exam_type_name).order('id').execute()
    return response.data

def get_questions_for_series(supabase: Client, series_id: int):
    """Récupérer les questions d'une série"""
    response = supabase.table('simulation_questions').select('question_id').eq('simulation_id', series_id).execute()
    return [q['question_id'] for q in response.data]

def get_available_questions_by_matiere(supabase: Client, matiere_name: str):
    """Récupérer toutes les questions disponibles pour une matière"""
    # D'abord récupérer l'ID de la matière
    matiere_response = supabase.table('matieres').select('id').eq('name', matiere_name).execute()
    if not matiere_response.data:
        print(f"⚠️ Matière '{matiere_name}' non trouvée")
        return []
    
    matiere_id = matiere_response.data[0]['id']
    
    # Récupérer toutes les questions de cette matière
    questions_response = supabase.table('questions').select('id').eq('matiere_id', matiere_id).execute()
    return [q['id'] for q in questions_response.data]

def check_duplicates(supabase: Client, exam_type_name: str):
    """Vérifier les doublons entre séries d'un même examen"""
    series = get_series_for_exam(supabase, exam_type_name)
    
    if len(series) < 2:
        return []
    
    all_questions = {}
    duplicates = []
    
    for serie in series:
        questions = get_questions_for_series(supabase, serie['id'])
        all_questions[serie['id']] = set(questions)
    
    # Vérifier les intersections
    series_ids = list(all_questions.keys())
    for i in range(len(series_ids)):
        for j in range(i + 1, len(series_ids)):
            intersection = all_questions[series_ids[i]] & all_questions[series_ids[j]]
            if intersection:
                duplicates.append({
                    'serie1': series_ids[i],
                    'serie2': series_ids[j],
                    'questions': list(intersection)
                })
    
    return duplicates

def create_serie3_if_missing(supabase: Client, exam_type_name: str, existing_series: list):
    """Créer une Série 3 si elle n'existe pas"""
    # Vérifier si on a déjà 3 séries
    if len(existing_series) >= 3:
        print(f"  ✓ {exam_type_name} a déjà 3 séries")
        return existing_series[2]['id']
    
    # Créer la Série 3
    print(f"  🔧 Création de Série 3 pour {exam_type_name}")
    
    new_series_data = {
        'name': exam_type_name,
        'type': 'examen_type',
        'is_blanc': False,
        'serie_number': 3,
        'published': True,
        'duration_minutes': 90
    }
    
    response = supabase.table('simulations_examens').insert(new_series_data).execute()
    new_serie_id = response.data[0]['id']
    print(f"    → Série 3 créée avec ID {new_serie_id}")
    
    return new_serie_id

def complete_series_questions(supabase: Client, exam_type_name: str, series_id: int, serie_number: int):
    """Compléter une série pour atteindre 50 questions"""
    current_questions = get_questions_for_series(supabase, series_id)
    current_count = len(current_questions)
    
    print(f"  📊 Série {serie_number} (ID {series_id}): {current_count} questions")
    
    if current_count == 50:
        print(f"    ✓ Déjà complète")
        return True
    
    if current_count > 50:
        print(f"    ⚠️ ATTENTION: {current_count} questions (> 50)")
        return False
    
    # Besoin d'ajouter des questions
    needed = 50 - current_count
    print(f"    🔧 Ajout de {needed} questions manquantes")
    
    # Récupérer la composition pour cet examen
    if exam_type_name not in EXAM_COMPOSITION:
        print(f"    ❌ Composition non trouvée pour {exam_type_name}")
        return False
    
    composition = EXAM_COMPOSITION[exam_type_name]
    
    # Récupérer toutes les questions déjà utilisées dans cet examen type (toutes séries)
    all_series = get_series_for_exam(supabase, exam_type_name)
    used_questions = set()
    for serie in all_series:
        used_questions.update(get_questions_for_series(supabase, serie['id']))
    
    # Collecter des questions disponibles par matière
    available_by_matiere = {}
    for matiere in composition['materials']:
        all_matiere_questions = get_available_questions_by_matiere(supabase, matiere)
        available = [q for q in all_matiere_questions if q not in used_questions]
        available_by_matiere[matiere] = available
        print(f"    📚 {matiere}: {len(available)} questions disponibles")
    
    # Sélectionner les questions selon la distribution
    selected_questions = []
    for i, matiere in enumerate(composition['materials']):
        count_needed = composition['distribution'][i]
        available = available_by_matiere[matiere]
        
        # Si on a besoin de compléter, prendre plus
        if len(selected_questions) < needed and available:
            to_take = min(count_needed, len(available), needed - len(selected_questions))
            selected_questions.extend(available[:to_take])
    
    # Si on n'a pas assez, prendre ce qu'on peut
    if len(selected_questions) < needed:
        print(f"    ⚠️ Seulement {len(selected_questions)} questions trouvées sur {needed} nécessaires")
        # Prendre toutes les questions disponibles
        for matiere in composition['materials']:
            if len(selected_questions) >= needed:
                break
            remaining = available_by_matiere[matiere]
            for q in remaining:
                if q not in selected_questions:
                    selected_questions.append(q)
                    if len(selected_questions) >= needed:
                        break
    
    # Insérer les questions
    if selected_questions:
        questions_data = [
            {
                'simulation_id': series_id,
                'question_id': q_id,
                'order_index': current_count + i
            }
            for i, q_id in enumerate(selected_questions[:needed])
        ]
        
        supabase.table('simulation_questions').insert(questions_data).execute()
        print(f"    ✓ {len(questions_data)} questions ajoutées")
        return True
    else:
        print(f"    ❌ Aucune question disponible")
        return False

def verify_exam_type(supabase: Client, exam_type_name: str):
    """Vérifier et finaliser un examen type"""
    print(f"\n{'='*60}")
    print(f"🎯 {exam_type_name}")
    print(f"{'='*60}")
    
    # Récupérer toutes les séries de cet examen
    all_series = get_series_for_exam(supabase, exam_type_name)
    
    # Trier par numéro de série
    series_by_number = {}
    for serie in all_series:
        serie_num = serie.get('serie_number', 0)
        if serie_num == 0:
            # Déduire le numéro de série depuis le nom ou l'ordre
            if 'Série 1' in serie['name'] or serie['id'] in range(66, 76):
                serie_num = 1
            elif 'Série 2' in serie['name'] or serie['id'] in range(76, 86):
                serie_num = 2
            elif 'Série 3' in serie['name'] or serie['id'] >= 107:
                serie_num = 3
        series_by_number[serie_num] = serie
    
    print(f"📋 Séries trouvées: {len(all_series)}")
    
    # S'assurer d'avoir 3 séries
    for serie_num in [1, 2, 3]:
        if serie_num not in series_by_number:
            print(f"  ❌ Série {serie_num} manquante")
            if serie_num == 3:
                # Créer la Série 3
                new_id = create_serie3_if_missing(supabase, exam_type_name, all_series)
                # Re-récupérer les séries
                all_series = get_series_for_exam(supabase, exam_type_name)
                for serie in all_series:
                    if serie['id'] == new_id:
                        series_by_number[3] = serie
                        break
        else:
            serie = series_by_number[serie_num]
            complete_series_questions(supabase, exam_type_name, serie['id'], serie_num)
    
    # Vérifier les doublons
    print(f"\n  🔍 Vérification des doublons...")
    duplicates = check_duplicates(supabase, exam_type_name)
    if duplicates:
        print(f"    ⚠️ {len(duplicates)} doublons trouvés")
        for dup in duplicates:
            print(f"      - Entre séries {dup['serie1']} et {dup['serie2']}: {len(dup['questions'])} questions")
    else:
        print(f"    ✓ Aucun doublon")
    
    return True

def main():
    """Fonction principale"""
    print("="*60)
    print("VÉRIFICATION ET FINALISATION DES 3 SÉRIES PAR EXAMEN TYPE")
    print("="*60)
    
    # Initialiser Supabase
    supabase = init_supabase()
    
    # Liste des examens types
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
    
    # Vérifier chaque examen type
    results = {}
    for exam_type in exam_types:
        try:
            results[exam_type] = verify_exam_type(supabase, exam_type)
        except Exception as e:
            print(f"❌ Erreur pour {exam_type}: {str(e)}")
            results[exam_type] = False
    
    # Résumé final
    print("\n" + "="*60)
    print("📊 RÉSUMÉ FINAL")
    print("="*60)
    
    success_count = sum(1 for v in results.values() if v)
    print(f"✓ Examens finalisés: {success_count}/{len(exam_types)}")
    
    for exam_type, success in results.items():
        status = "✓" if success else "❌"
        print(f"  {status} {exam_type}")
    
    print("\n✅ VÉRIFICATION TERMINÉE")

if __name__ == "__main__":
    main()
