#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de validation finale complète
"""

from supabase import create_client, Client
import json

# Configuration Supabase
SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

def init_supabase() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_KEY)

def validate_series():
    """Validation finale des 3 séries par examen type"""
    supabase = init_supabase()
    
    print("="*80)
    print("VALIDATION FINALE - TÂCHE 1: 3 SÉRIES PAR EXAMEN TYPE")
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
    
    # Mapping des IDs
    series_1_ids = list(range(66, 76))  # 66-75
    series_2_ids = list(range(76, 86))  # 76-85
    series_3_ids = list(range(107, 117))  # 107-116
    
    all_valid = True
    
    for i, exam_type in enumerate(exam_types):
        series_1_id = series_1_ids[i]
        series_2_id = series_2_ids[i]
        series_3_id = series_3_ids[i]
        
        # Vérifier chaque série
        series_data = []
        for serie_num, serie_id in [(1, series_1_id), (2, series_2_id), (3, series_3_id)]:
            response = supabase.table('simulations_examens').select('question_ids, titre').eq('id', serie_id).execute()
            
            if not response.data:
                print(f"❌ {exam_type} - Série {serie_num} (ID {serie_id}): NON TROUVÉE")
                all_valid = False
                continue
            
            exam = response.data[0]
            num_questions = len(exam.get('question_ids', []))
            titre = exam.get('titre', '')
            
            series_data.append({
                'num': serie_num,
                'id': serie_id,
                'questions': num_questions,
                'titre': titre
            })
            
            if num_questions != 50:
                print(f"❌ {exam_type} - Série {serie_num} (ID {serie_id}): {num_questions} questions (attendu: 50)")
                all_valid = False
        
        # Vérifier que Série 1 a été mise à jour avec "Série 1" dans le titre
        if series_data and len(series_data) >= 1:
            if "Série 1" in series_data[0]['titre'] or "— 1" in series_data[0]['titre']:
                status = "✅"
            else:
                status = "✓"
            
            print(f"{status} {exam_type}: 3 séries × 50 questions")
            for s in series_data:
                print(f"    Série {s['num']} (ID {s['id']:3d}): {s['questions']} questions")
    
    print("\n" + "="*80)
    if all_valid:
        print("✅ TÂCHE 1 VALIDÉE: Tous les examens types ont 3 séries de 50 questions")
    else:
        print("⚠️  TÂCHE 1: Certaines séries nécessitent des ajustements")
    print("="*80)
    
    return all_valid

def validate_admin_panel():
    """Validation de la structure du panel administrateur"""
    print("\n" + "="*80)
    print("VALIDATION FINALE - TÂCHE 2: CMS COMPLET DANS PANEL ADMIN")
    print("="*80)
    
    # Vérifier que le fichier admin_screen.dart existe
    import os
    admin_file = '/home/user/ef-fort-bf/lib/screens/admin_screen.dart'
    
    if not os.path.exists(admin_file):
        print("❌ Fichier admin_screen.dart non trouvé")
        return False
    
    with open(admin_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Vérifier la présence des onglets requis
    required_tabs = [
        ('Tableau de bord', '_DashboardTab'),
        ('Paiements', '_PaiementsTab'),
        ('CMS QCM', 'CmsQcmTab'),
        ('Annonces', '_AnnoncesTab'),
        ('Modération', '_ModerationTab'),
        ('Logs', '_LogsTab'),
    ]
    
    all_present = True
    
    for tab_name, class_name in required_tabs:
        if class_name in content:
            print(f"✅ Onglet '{tab_name}': {class_name} présent")
        else:
            print(f"❌ Onglet '{tab_name}': {class_name} manquant")
            all_present = False
    
    # Vérifier les sections du CMS QCM
    cms_sections = [
        ('Stats', '_CmsDashboardSection'),
        ('Questions', '_CmsQuestionsSection'),
        ('Importer', '_CmsBulkImportSection'),
        ('Séries', '_CmsSeriesSection'),
        ('Examens', '_CmsSimulationsSection'),
        ('Générateur', '_CmsExamGeneratorSection'),
    ]
    
    print("\n📊 Sections du CMS QCM:")
    for section_name, class_name in cms_sections:
        if class_name in content:
            print(f"  ✅ {section_name}: {class_name}")
        else:
            print(f"  ❌ {section_name}: {class_name} manquant")
            all_present = False
    
    # Vérifier les tailles de police
    print("\n📐 Vérification des tailles de police:")
    large_fonts = []
    for line_num, line in enumerate(content.split('\n'), 1):
        if 'fontSize:' in line:
            # Extraire la taille
            try:
                size_str = line.split('fontSize:')[1].split(',')[0].strip()
                if size_str.replace('.', '').isdigit():
                    size = float(size_str)
                    if size > 20:
                        large_fonts.append((line_num, size, line.strip()[:80]))
            except:
                pass
    
    if large_fonts:
        print(f"  ⚠️  {len(large_fonts)} polices > 20px détectées:")
        for line_num, size, line_preview in large_fonts[:5]:
            print(f"    Ligne {line_num}: {size}px - {line_preview}")
    else:
        print("  ✅ Toutes les polices sont ≤ 20px")
    
    print("\n" + "="*80)
    if all_present:
        print("✅ TÂCHE 2 VALIDÉE: Panel Administration complet avec tous les onglets")
    else:
        print("⚠️  TÂCHE 2: Certains onglets ou sections manquent")
    print("="*80)
    
    return all_present

def main():
    """Validation complète"""
    print("\n" + "="*80)
    print("🔍 VALIDATION FINALE COMPLÈTE")
    print("="*80)
    
    # Valider les deux tâches
    task1_ok = validate_series()
    task2_ok = validate_admin_panel()
    
    # Résumé final
    print("\n" + "="*80)
    print("📊 RÉSUMÉ FINAL")
    print("="*80)
    
    if task1_ok:
        print("✅ TÂCHE 1: 3 séries par examen type - VALIDÉE")
    else:
        print("⚠️  TÂCHE 1: 3 séries par examen type - NÉCESSITE AJUSTEMENTS")
    
    if task2_ok:
        print("✅ TÂCHE 2: CMS complet dans Panel Admin - VALIDÉE")
    else:
        print("⚠️  TÂCHE 2: CMS complet dans Panel Admin - NÉCESSITE AJUSTEMENTS")
    
    if task1_ok and task2_ok:
        print("\n🎉 TOUTES LES TÂCHES SONT VALIDÉES!")
        print("✅ Prêt pour commit et déploiement")
    else:
        print("\n⚠️  Certaines tâches nécessitent des ajustements")
    
    print("="*80)

if __name__ == "__main__":
    main()
