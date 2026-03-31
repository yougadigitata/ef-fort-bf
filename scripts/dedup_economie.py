#!/usr/bin/env python3
"""
Script de suppression des doublons dans la matière Économie de Supabase EF-FORT.BF
Stratégie: garder la question la plus ancienne (created_at le plus tôt) pour chaque doublon
"""

import json
import time
import urllib.request
import urllib.parse

# === CONFIGURATION ===
SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"
ECO_MATIERE_ID = "756e1ca6-7f7f-4f42-940a-b6d9952ffcdf"

HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
}


def fetch_all_eco_questions():
    """Récupère toutes les questions économique avec pagination"""
    all_questions = []
    offset = 0
    batch_size = 1000
    
    while True:
        params = f"matiere_id=eq.{ECO_MATIERE_ID}&select=id,enonce,option_a,option_b,option_c,option_d,bonne_reponse,created_at,numero&order=created_at.asc&offset={offset}&limit={batch_size}"
        url = f"{SUPABASE_URL}/rest/v1/questions?{params}"
        
        req = urllib.request.Request(url, headers={
            **HEADERS,
            "Prefer": "count=exact"
        })
        
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
            cr = resp.headers.get('Content-Range', '')
            
        all_questions.extend(data)
        print(f"  Récupéré: {len(all_questions)} questions (Content-Range: {cr})")
        
        if len(data) < batch_size:
            break
        offset += batch_size
        time.sleep(0.2)
    
    return all_questions


def find_duplicates(questions):
    """
    Identifie les doublons.
    Critère doublon: même énoncé normalisé (insensible à la casse, espaces normalisés)
    On garde la question avec le plus petit created_at (la plus ancienne)
    """
    seen = {}  # clé -> premier_id (à garder)
    to_delete = []
    
    for q in questions:
        # Normaliser l'énoncé
        enonce_key = ' '.join(q['enonce'].lower().split())
        
        if enonce_key not in seen:
            seen[enonce_key] = q['id']
        else:
            # Doublon -> à supprimer
            to_delete.append(q['id'])
    
    return to_delete


def delete_questions_batch(ids_to_delete, batch_size=50):
    """Supprime les questions par lots via leur ID"""
    total = len(ids_to_delete)
    deleted = 0
    errors = 0
    
    for i in range(0, total, batch_size):
        batch = ids_to_delete[i:i+batch_size]
        
        # Construire la liste d'IDs pour la requête
        ids_filter = "(" + ",".join(batch) + ")"
        url = f"{SUPABASE_URL}/rest/v1/questions?id=in.{ids_filter}"
        
        req = urllib.request.Request(
            url,
            headers=HEADERS,
            method="DELETE"
        )
        
        try:
            with urllib.request.urlopen(req) as resp:
                deleted += len(batch)
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8')
            print(f"  ❌ HTTP {e.code} sur lot {i//batch_size + 1}: {error_body[:200]}")
            errors += len(batch)
        
        progress = min(i + batch_size, total)
        print(f"  🗑️  Lot {i//batch_size + 1}/{(total + batch_size - 1)//batch_size}: {progress}/{total} supprimées")
        time.sleep(0.3)
    
    return deleted, errors


def main():
    print("=" * 65)
    print("🧹 SUPPRESSION DOUBLONS - MATIÈRE ÉCONOMIE - EF-FORT.BF")
    print("=" * 65)
    
    # 1. Récupérer toutes les questions économie
    print("\n📥 Récupération de toutes les questions Économie...")
    questions = fetch_all_eco_questions()
    print(f"  Total récupéré: {len(questions)} questions")
    
    # 2. Identifier les doublons
    print("\n🔍 Analyse des doublons...")
    to_delete = find_duplicates(questions)
    unique_count = len(questions) - len(to_delete)
    
    print(f"  Questions totales:  {len(questions)}")
    print(f"  Questions uniques:  {unique_count}")
    print(f"  Doublons à suppr.:  {len(to_delete)}")
    
    if not to_delete:
        print("\n✅ Aucun doublon trouvé!")
        return
    
    # 3. Supprimer les doublons
    print(f"\n🗑️  Suppression de {len(to_delete)} doublons...")
    deleted, errors = delete_questions_batch(to_delete)
    
    # 4. Vérification finale
    print("\n🔍 Vérification finale...")
    url = f"{SUPABASE_URL}/rest/v1/questions?matiere_id=eq.{ECO_MATIERE_ID}"
    req = urllib.request.Request(url, headers={
        **HEADERS,
        "Prefer": "count=exact"
    })
    with urllib.request.urlopen(req) as resp:
        cr = resp.headers.get('Content-Range', 'N/A')
        print(f"  Questions Économie restantes: {cr}")
    
    print("\n" + "=" * 65)
    print(f"📊 RÉSULTAT:")
    print(f"   Doublons supprimés: {deleted}")
    print(f"   Erreurs:            {errors}")
    print(f"   Questions restantes: ~{unique_count}")
    print("=" * 65)


if __name__ == "__main__":
    main()
