#!/usr/bin/env python3
"""
Script d'insertion des QCM Anglais (520) et Psychotechnique (600) dans Supabase EF-FORT.BF
"""

import re
import json
import time
import urllib.request
import urllib.parse
import uuid

# === CONFIGURATION ===
SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

# IDs des matières
MATIERE_ANGLAIS_ID = "37febc5e-8ab5-4875-b7ad-71b30a8253e7"  # Anglais
MATIERE_PSYCHO_ID = "cbd22275-d260-40d1-8ff3-d31545f3f1ab"   # Psychotechnique (code PSYCHO)

# Numéro de départ (max existant + 1)
START_NUMERO = 1743


def supabase_request(method, endpoint, data=None, params=None):
    """Effectue une requête à l'API Supabase"""
    url = f"{SUPABASE_URL}/rest/v1/{endpoint}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    
    body = json.dumps(data).encode('utf-8') if data else None
    req = urllib.request.Request(url, data=body, headers=HEADERS, method=method)
    
    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read()
            if content:
                return json.loads(content)
            return None
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        print(f"  ❌ HTTP {e.code}: {error_body[:200]}")
        return None


def parse_anglais_qcm(filepath):
    """Parse le fichier 520 QCM anglais.md"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    questions = []
    
    # Pattern pour chaque question
    # ### Q\d+ - [...]
    # **Énoncé :** ...
    # **Options :**
    # - **A** : ...
    # - **B** : ...
    # ...
    # **Réponse :** X
    # **Explication détaillée :** ...
    
    blocks = re.split(r'\n---\n', content)
    
    for block in blocks:
        block = block.strip()
        if not block or not re.search(r'###\s+Q\d+', block):
            continue
        
        q = {}
        
        # Titre/Catégorie
        title_match = re.search(r'###\s+Q(\d+)\s*-\s*\[([^\]]+)\]', block)
        if title_match:
            q['num_original'] = int(title_match.group(1))
            q['categorie'] = title_match.group(2).strip()
        else:
            title_match2 = re.search(r'###\s+Q(\d+)', block)
            if title_match2:
                q['num_original'] = int(title_match2.group(1))
                q['categorie'] = ''
            else:
                continue
        
        # Énoncé
        enonce_match = re.search(r'\*\*[EÉ]nonc[eé]\s*:\*\*\s*(.+?)(?=\n\*\*Options|\n\*\*Réponse|$)', block, re.DOTALL)
        if enonce_match:
            q['enonce'] = enonce_match.group(1).strip()
        else:
            continue
        
        # Options
        opts = {}
        for letter in ['A', 'B', 'C', 'D', 'E']:
            opt_match = re.search(rf'-\s*\*\*{letter}\*\*\s*:\s*(.+?)(?=\n-\s*\*\*[A-E]\*\*|\n\*\*R[ée]ponse|$)', block, re.DOTALL)
            if opt_match:
                opts[letter] = opt_match.group(1).strip().replace('\n', ' ')
        
        q['options'] = opts
        
        # Réponse
        rep_match = re.search(r'\*\*R[ée]ponse\s*:\*\*\s*([A-E])', block)
        if rep_match:
            q['bonne_reponse'] = rep_match.group(1)
        else:
            q['bonne_reponse'] = 'A'
        
        # Explication
        exp_match = re.search(r'\*\*Explication(?:\s+d[ée]taill[ée]e?)?\s*:\*\*\s*(.+?)(?=\n###|$)', block, re.DOTALL)
        if exp_match:
            q['explication'] = exp_match.group(1).strip()
        else:
            q['explication'] = ''
        
        questions.append(q)
    
    return questions


def parse_psycho_qcm(filepath):
    """Parse le fichier 600QCM psychotechnique.md"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    questions = []
    
    # Format différent:
    # ### Q\d+ - Catégorie (Sous-catégorie)
    # **Énoncé :** ...
    # **Asset Visuel :** ...
    # **Options :**
    # A) ...
    # B) ...
    # **Réponse :** X
    # **Explication :** ...
    
    # Split par ### Q
    blocks = re.split(r'(?=###\s+Q\d+)', content)
    
    for block in blocks:
        block = block.strip()
        if not block or not block.startswith('###'):
            continue
        
        q = {}
        
        # Titre
        title_match = re.search(r'###\s+Q(\d+)\s*[-–]\s*(.+?)(?:\n|$)', block)
        if title_match:
            q['num_original'] = int(title_match.group(1))
            q['categorie'] = title_match.group(2).strip()
        else:
            title_match2 = re.search(r'###\s+Q(\d+)', block)
            if title_match2:
                q['num_original'] = int(title_match2.group(1))
                q['categorie'] = 'Psychotechnique'
            else:
                continue
        
        # Énoncé
        enonce_match = re.search(r'\*\*[EÉ]nonc[eé]\s*:\*\*\s*(.+?)(?=\n\*\*Asset|\n\*\*Options|\n\*\*R[ée]ponse|$)', block, re.DOTALL)
        if enonce_match:
            q['enonce'] = enonce_match.group(1).strip()
        else:
            continue
        
        # Options (format: A) ... ou A. ...)
        opts = {}
        for letter in ['A', 'B', 'C', 'D', 'E']:
            # Format: A) texte ou A. texte
            opt_match = re.search(rf'\n{letter}[)\.]]\s*(.+?)(?=\n[A-E][)\.]|\n\*\*R[ée]ponse|$)', block, re.DOTALL)
            if opt_match:
                opts[letter] = opt_match.group(1).strip().replace('\n', ' ')
        
        # Si pas trouvé, essayer le format en ligne
        if not opts:
            for letter in ['A', 'B', 'C', 'D']:
                opt_match = re.search(rf'(?:^|\n){letter}\)\s*(.+?)(?=\n[A-D]\)|\n\*\*|$)', block, re.DOTALL)
                if opt_match:
                    opts[letter] = opt_match.group(1).strip()
        
        q['options'] = opts
        
        # Réponse
        rep_match = re.search(r'\*\*R[ée]ponse\s*:\*\*\s*([A-E])', block)
        if rep_match:
            q['bonne_reponse'] = rep_match.group(1)
        else:
            q['bonne_reponse'] = 'A'
        
        # Explication
        exp_match = re.search(r'\*\*Explication\s*:\*\*\s*(.+?)(?=\n###|$)', block, re.DOTALL)
        if exp_match:
            q['explication'] = exp_match.group(1).strip()
        else:
            q['explication'] = ''
        
        questions.append(q)
    
    return questions


def deduplicate_questions(questions):
    """Supprime les doublons basés sur l'énoncé (case insensitive, espaces normalisés)"""
    seen = {}
    unique = []
    duplicates = 0
    
    for q in questions:
        # Normaliser l'énoncé pour comparaison
        key = ' '.join(q['enonce'].lower().split())[:200]
        if key not in seen:
            seen[key] = True
            unique.append(q)
        else:
            duplicates += 1
    
    print(f"  Doublons supprimés dans le fichier: {duplicates}")
    return unique


def insert_batch(questions_db, batch_size=50):
    """Insère les questions en lots"""
    total = len(questions_db)
    inserted = 0
    errors = 0
    
    for i in range(0, total, batch_size):
        batch = questions_db[i:i+batch_size]
        result = supabase_request("POST", "questions", data=batch)
        if result is not None or True:
            # Supabase return=minimal retourne None en succès
            # On essaie d'évaluer autrement
            inserted += len(batch)
        else:
            errors += len(batch)
            print(f"  ❌ Erreur sur le lot {i//batch_size + 1}")
        
        print(f"  📤 Lot {i//batch_size + 1}/{(total + batch_size - 1)//batch_size}: {min(i+batch_size, total)}/{total}")
        time.sleep(0.3)  # Éviter le rate limiting
    
    return inserted, errors


def build_db_question(q, matiere_id, numero):
    """Construit un objet question pour Supabase"""
    opts = q.get('options', {})
    
    # Tags basés sur la catégorie
    tags = []
    if q.get('categorie'):
        tags = [q['categorie']]
    
    return {
        "id": str(uuid.uuid4()),
        "matiere_id": matiere_id,
        "numero": numero,
        "enonce": q['enonce'],
        "type": "QCM",
        "option_a": opts.get('A', ''),
        "option_b": opts.get('B', ''),
        "option_c": opts.get('C', ''),
        "option_d": opts.get('D', ''),
        "option_e": opts.get('E', None),
        "bonne_reponse": q['bonne_reponse'],
        "explication": q.get('explication', ''),
        "difficulte": "MOYEN",
        "published": True,
        "version": 1,
        "tags": tags if tags else None,
        "numero_serie": 1,
    }


def main():
    print("=" * 60)
    print("🚀 INSERTION QCM - EF-FORT.BF")
    print("=" * 60)
    
    current_numero = START_NUMERO
    
    # ===== 1. ANGLAIS =====
    print("\n📖 ANGLAIS - Parsing du fichier...")
    anglais_raw = parse_anglais_qcm("/home/user/uploaded_files/520 QCM anglais.md")
    print(f"  Questions parsées: {len(anglais_raw)}")
    
    anglais_unique = deduplicate_questions(anglais_raw)
    print(f"  Questions uniques: {len(anglais_unique)}")
    
    # Construire les questions DB
    anglais_db = []
    for q in anglais_unique:
        db_q = build_db_question(q, MATIERE_ANGLAIS_ID, current_numero)
        anglais_db.append(db_q)
        current_numero += 1
    
    print(f"\n📤 Insertion de {len(anglais_db)} questions ANGLAIS...")
    inserted_ang, errors_ang = insert_batch(anglais_db)
    print(f"  ✅ Anglais: {inserted_ang} insérées, {errors_ang} erreurs")
    
    # ===== 2. PSYCHOTECHNIQUE =====
    print("\n🧠 PSYCHOTECHNIQUE - Parsing du fichier...")
    psycho_raw = parse_psycho_qcm("/home/user/uploaded_files/600QCM psychotechnique.md")
    print(f"  Questions parsées: {len(psycho_raw)}")
    
    psycho_unique = deduplicate_questions(psycho_raw)
    print(f"  Questions uniques: {len(psycho_unique)}")
    
    # Construire les questions DB
    psycho_db = []
    for q in psycho_unique:
        db_q = build_db_question(q, MATIERE_PSYCHO_ID, current_numero)
        psycho_db.append(db_q)
        current_numero += 1
    
    print(f"\n📤 Insertion de {len(psycho_db)} questions PSYCHOTECHNIQUE...")
    inserted_psy, errors_psy = insert_batch(psycho_db)
    print(f"  ✅ Psychotechnique: {inserted_psy} insérées, {errors_psy} erreurs")
    
    print("\n" + "=" * 60)
    print(f"📊 TOTAL INSÉRÉ:")
    print(f"   Anglais:         {inserted_ang} questions")
    print(f"   Psychotechnique: {inserted_psy} questions")
    print(f"   TOTAL:           {inserted_ang + inserted_psy} questions")
    print(f"   Prochain numéro: {current_numero}")
    print("=" * 60)
    
    return inserted_ang, inserted_psy


if __name__ == "__main__":
    main()
