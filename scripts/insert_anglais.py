#!/usr/bin/env python3
"""
Script FINAL d'insertion des QCM Anglais (520) et Psychotechnique (600) dans Supabase EF-FORT.BF
- Anglais: toutes les 520 variantes (options permutées = questions différentes)
- Psycho: déduplication déjà faite lors du 1er passage (410 insérées)
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

# Numéro de départ (max actuel + 1)
START_NUMERO = 2161


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
            return "ok"
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        print(f"  ❌ HTTP {e.code}: {error_body[:300]}")
        return None


def parse_anglais_qcm(filepath):
    """
    Parse toutes les 520 questions d'anglais.
    IMPORTANT: Les 520 questions contiennent des variantes légitimes 
    (mêmes énoncés mais options permutées → bonne réponse différente = question différente).
    On déduplique uniquement sur (énoncé + options_triées + bonne_réponse) pour vraies dupes.
    """
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    questions = []
    seen_signatures = set()
    
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
        
        # Options - format: - **A** : texte
        opts = {}
        for letter in ['A', 'B', 'C', 'D', 'E']:
            # Pattern: - **A** : texte (jusqu'à la prochaine option ou réponse)
            opt_match = re.search(
                rf'-\s*\*\*{letter}\*\*\s*:\s*(.+?)(?=\n-\s*\*\*[B-E]\*\*\s*:|\n\*\*R[ée]ponse|$)',
                block, re.DOTALL
            )
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
        
        # Signature unique: énoncé normalisé + options triées par valeur + bonne réponse
        opts_vals = sorted([v.lower().strip() for v in opts.values()])
        sig = (
            ' '.join(q['enonce'].lower().split())[:150],
            '|'.join(opts_vals)[:200],
            q['bonne_reponse']
        )
        sig_key = '##'.join(sig)
        
        if sig_key not in seen_signatures:
            seen_signatures.add(sig_key)
            questions.append(q)
    
    return questions


def insert_batch(questions_db, batch_size=50):
    """Insère les questions en lots"""
    total = len(questions_db)
    inserted = 0
    errors = 0
    
    for i in range(0, total, batch_size):
        batch = questions_db[i:i+batch_size]
        result = supabase_request("POST", "questions", data=batch)
        if result is not None:
            inserted += len(batch)
        else:
            errors += len(batch)
            print(f"  ⚠️  Erreur sur le lot {i//batch_size + 1}, tentative individuelle...")
            # Tentative individuelle
            for q_item in batch:
                r = supabase_request("POST", "questions", data=[q_item])
                if r is not None:
                    inserted += 1
                else:
                    errors += 1
                    errors -= 1  # on a déjà compté l'erreur
        
        progress = min(i + batch_size, total)
        print(f"  📤 Lot {i//batch_size + 1}/{(total + batch_size - 1)//batch_size}: {progress}/{total} questions")
        time.sleep(0.3)
    
    return inserted, errors


def build_db_question(q, matiere_id, numero):
    """Construit un objet question pour Supabase"""
    opts = q.get('options', {})
    
    tags = []
    if q.get('categorie'):
        # Extraire le tag principal (avant le /)
        cat = q['categorie'].split('/')[0].strip() if '/' in q['categorie'] else q['categorie']
        tags = [cat]
    
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
        "option_e": opts.get('E') if opts.get('E') and opts.get('E', '').lower() not in ['aucune de ces réponses', ''] else None,
        "bonne_reponse": q['bonne_reponse'],
        "explication": q.get('explication', ''),
        "difficulte": "MOYEN",
        "published": True,
        "version": 1,
        "tags": tags if tags else None,
        "numero_serie": 1,
    }


def main():
    print("=" * 65)
    print("🚀 INSERTION QCM ANGLAIS (520 variantes) - EF-FORT.BF")
    print("=" * 65)
    
    current_numero = START_NUMERO
    
    # ===== ANGLAIS =====
    print("\n📖 ANGLAIS - Parsing des 520 variantes de questions...")
    anglais_all = parse_anglais_qcm("/home/user/uploaded_files/520 QCM anglais.md")
    print(f"  ✅ Variantes uniques extraites: {len(anglais_all)}")
    
    # Construire les questions DB
    anglais_db = []
    for q in anglais_all:
        db_q = build_db_question(q, MATIERE_ANGLAIS_ID, current_numero)
        anglais_db.append(db_q)
        current_numero += 1
    
    print(f"\n📤 Insertion de {len(anglais_db)} questions ANGLAIS...")
    inserted_ang, errors_ang = insert_batch(anglais_db)
    
    print("\n" + "=" * 65)
    print(f"📊 RÉSULTAT ANGLAIS:")
    print(f"   Insérées:  {inserted_ang} questions")
    print(f"   Erreurs:   {errors_ang}")
    print(f"   Prochain numéro: {current_numero}")
    print("=" * 65)
    
    # Vérification finale
    print("\n🔍 Vérification dans Supabase...")
    import urllib.request
    url = f"{SUPABASE_URL}/rest/v1/questions?matiere_id=eq.{MATIERE_ANGLAIS_ID}"
    req = urllib.request.Request(url, headers={
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Prefer": "count=exact"
    })
    try:
        with urllib.request.urlopen(req) as resp:
            cr = resp.headers.get('Content-Range', 'N/A')
            print(f"  Questions Anglais en base: {cr}")
    except Exception as e:
        print(f"  Erreur vérification: {e}")
    
    return inserted_ang


if __name__ == "__main__":
    main()
