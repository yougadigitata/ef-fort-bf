#!/usr/bin/env python3
"""
Script de nettoyage des étoiles (*) dans Supabase
- **texte** → texte (supprime le gras Markdown)
- *texte* → texte (supprime l'italique Markdown)
- * isolé → supprime
- Tables concernées : questions (enonce, explication, option_a/b/c/d/e)
"""

import re
from supabase import create_client

SUPABASE_URL = 'https://xqifdbgqxyrlhrkwlyir.supabase.co'
SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg'

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

CHAMPS_QUESTIONS = ['enonce', 'explication', 'option_a', 'option_b', 'option_c', 'option_d', 'option_e']

def clean_stars(text):
    """Nettoie les étoiles Markdown d'un texte."""
    if not text:
        return text
    
    original = text
    
    # 1. **texte** → texte (gras Markdown double étoile)
    text = re.sub(r'\*\*(.+?)\*\*', r'\1', text)
    
    # 2. *texte* → texte (italique Markdown simple étoile)
    text = re.sub(r'\*(.+?)\*', r'\1', text)
    
    # 3. Étoiles isolées au début de ligne (listes Markdown) → supprimer
    text = re.sub(r'^\* ', '', text, flags=re.MULTILINE)
    
    # 4. Étoiles triples ***texte*** → texte
    text = re.sub(r'\*\*\*(.+?)\*\*\*', r'\1', text)
    
    # 5. Étoiles restantes isolées → supprimer
    text = re.sub(r'\*+', '', text)
    
    # 6. Nettoyer espaces multiples
    text = re.sub(r'  +', ' ', text)
    text = text.strip()
    
    return text if text != original else None  # None si pas de changement


def process_questions():
    """Traite toutes les questions."""
    print("=== NETTOYAGE DES ÉTOILES - TABLE questions ===\n")
    
    total_modifie = 0
    total_traite = 0
    page = 0
    page_size = 500
    
    while True:
        print(f"  Traitement page {page + 1} (offset {page * page_size})...")
        resp = supabase.table('questions').select(
            'id,' + ','.join(CHAMPS_QUESTIONS)
        ).range(page * page_size, (page + 1) * page_size - 1).execute()
        
        data = resp.data
        if not data:
            break
        
        total_traite += len(data)
        
        for q in data:
            updates = {}
            for champ in CHAMPS_QUESTIONS:
                val = q.get(champ)
                if val and isinstance(val, str) and '*' in val:
                    cleaned = clean_stars(val)
                    if cleaned is not None and cleaned != val:
                        updates[champ] = cleaned
            
            if updates:
                try:
                    supabase.table('questions').update(updates).eq('id', q['id']).execute()
                    total_modifie += 1
                except Exception as e:
                    print(f"    ❌ Erreur mise à jour {q['id']}: {e}")
        
        if len(data) < page_size:
            break
        page += 1
    
    print(f"\n✅ Questions traitées : {total_traite}")
    print(f"✅ Questions modifiées : {total_modifie}")
    return total_modifie


def process_simulations():
    """Traite les descriptions dans simulations_examens."""
    print("\n=== NETTOYAGE DES ÉTOILES - TABLE simulations_examens ===\n")
    
    total_modifie = 0
    resp = supabase.table('simulations_examens').select('id,titre,description').execute()
    
    for item in resp.data:
        updates = {}
        for champ in ['titre', 'description']:
            val = item.get(champ)
            if val and isinstance(val, str) and '*' in val:
                cleaned = clean_stars(val)
                if cleaned is not None and cleaned != val:
                    updates[champ] = cleaned
        
        if updates:
            try:
                supabase.table('simulations_examens').update(updates).eq('id', item['id']).execute()
                total_modifie += 1
                print(f"  ✅ Simulation {item['id']} modifiée")
            except Exception as e:
                print(f"  ❌ Erreur {item['id']}: {e}")
    
    print(f"✅ Simulations modifiées : {total_modifie}")
    return total_modifie


def process_annonces():
    """Traite les annonces si la table existe."""
    print("\n=== NETTOYAGE DES ÉTOILES - TABLE annonces ===\n")
    
    try:
        resp = supabase.table('annonces').select('*').limit(1).execute()
        if not resp.data:
            print("  Table annonces vide ou inexistante.")
            return 0
        
        colonnes = list(resp.data[0].keys())
        champs_text = [c for c in colonnes if c not in ('id', 'created_at', 'updated_at', 'published')]
        
        total_modifie = 0
        resp_all = supabase.table('annonces').select('id,' + ','.join(champs_text)).execute()
        
        for item in resp_all.data:
            updates = {}
            for champ in champs_text:
                val = item.get(champ)
                if val and isinstance(val, str) and '*' in val:
                    cleaned = clean_stars(val)
                    if cleaned is not None and cleaned != val:
                        updates[champ] = cleaned
            
            if updates:
                try:
                    supabase.table('annonces').update(updates).eq('id', item['id']).execute()
                    total_modifie += 1
                    print(f"  ✅ Annonce {item['id']} modifiée")
                except Exception as e:
                    print(f"  ❌ Erreur {item['id']}: {e}")
        
        print(f"✅ Annonces modifiées : {total_modifie}")
        return total_modifie
        
    except Exception as e:
        print(f"  Table annonces : {e}")
        return 0


def test_clean():
    """Tester la fonction de nettoyage."""
    print("=== TEST DE NETTOYAGE ===\n")
    
    exemples = [
        "1. **Démonstration :** Le Général de Brigade",
        "**Analyse du Piège :** Confusion avec",
        "Texte *en italique* ici",
        "* Liste item 1",
        "Texte normal sans étoile",
        "***gras italique***",
    ]
    
    for ex in exemples:
        result = clean_stars(ex)
        print(f"  AVANT: {ex}")
        print(f"  APRÈS: {result if result else ex + ' (inchangé)'}")
        print()


if __name__ == '__main__':
    test_clean()
    
    print("\n" + "="*60)
    print("Démarrage du nettoyage en base de données...")
    print("="*60 + "\n")
    
    total = 0
    total += process_questions()
    total += process_simulations()
    total += process_annonces()
    
    print(f"\n{'='*60}")
    print(f"✅ NETTOYAGE TERMINÉ — Total modifié : {total} entrées")
    print(f"{'='*60}")
