#!/usr/bin/env python3
"""
Script d'insertion des séries Communication (12 séries) et Guide Panafricain (3 séries)
dans Supabase EF-FORT.BF
"""

import re
import json
import time
import uuid
import urllib.request
import urllib.parse
import os
from docx import Document
from collections import Counter

# === CONFIGURATION ===
SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

HEADERS_MINIMAL = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

# IDs des matières
COMM_ID = "cc979206-e60d-4224-940d-943b8c68c8fa"
GUIDE_ID = "a0b2c3c5-8dbf-4c7f-ab73-356530962c48"

# Chemins des fichiers
COMM_DOCX = "/home/user/uploaded_files/extracted/QCM COMmunication.docx"
GUIDE_DIR = "/home/user/uploaded_files/extracted/guide_panafricain/"


# ============================================================
# FONCTIONS SUPABASE
# ============================================================

def supabase_request(method, endpoint, data=None, params=None, headers=None):
    url = f"{SUPABASE_URL}/rest/v1/{endpoint}"
    if params:
        url += "?" + "&".join(f"{k}={urllib.parse.quote(str(v))}" for k, v in params.items())
    
    body = json.dumps(data).encode('utf-8') if data else None
    h = headers or HEADERS
    req = urllib.request.Request(url, data=body, headers=h, method=method)
    
    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read()
            if content:
                return json.loads(content), None
            return None, None
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        return None, f"HTTP {e.code}: {error_body[:300]}"


def supabase_get(endpoint, params=None):
    result, err = supabase_request("GET", endpoint, params=params)
    if err:
        print(f"  ❌ GET {endpoint}: {err}")
        return []
    return result or []


def get_max_numero():
    """Obtenir le numéro max actuel dans questions"""
    url = f"{SUPABASE_URL}/rest/v1/questions?select=numero&order=numero.desc&limit=1"
    req = urllib.request.Request(url, headers=HEADERS, method="GET")
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
    if data:
        return data[0]['numero']
    return 3598


# ============================================================
# PARSEUR DOCX COMMUNICATION
# ============================================================

def parse_communication_docx(filepath):
    """
    Parse le fichier DOCX Communication.
    Format:
      SÉRIE N - [Titre]
      Q1 - Énoncé : ...
      Options :
      A : ...
      B : ...
      Réponse : X
      Explication détaillée :
      ...
    """
    doc = Document(filepath)
    paragraphs = [p.text.strip() for p in doc.paragraphs if p.text.strip()]
    
    series_dict = {}  # serie_num -> {titre, questions: [...]}
    
    current_serie = None
    current_serie_title = None
    current_q = None
    state = None  # 'enonce', 'options', 'reponse', 'explication'
    
    i = 0
    while i < len(paragraphs):
        line = paragraphs[i]
        
        # Détecter nouvelle série
        m = re.match(r'^SÉRIE\s+(\d+)\s*[-–]\s*\[(.+?)\]', line)
        if m:
            current_serie = int(m.group(1))
            current_serie_title = m.group(2).strip()
            if current_serie not in series_dict:
                series_dict[current_serie] = {
                    'titre': current_serie_title,
                    'questions': []
                }
            current_q = None
            state = None
            i += 1
            continue
        
        if current_serie is None:
            i += 1
            continue
        
        # Détecter nouvelle question
        m_q = re.match(r'^Q(\d+)\s*[-–]\s*[EÉ]nonc[eé]\s*:\s*(.+)?$', line)
        if m_q:
            # Sauvegarder question précédente si complète
            if current_q and current_q.get('enonce') and current_q.get('options'):
                series_dict[current_serie]['questions'].append(current_q)
            
            current_q = {
                'num': int(m_q.group(1)),
                'enonce': m_q.group(2).strip() if m_q.group(2) else '',
                'options': {},
                'bonne_reponse': 'A',
                'explication': '',
                'categorie': current_serie_title
            }
            state = 'enonce'
            i += 1
            continue
        
        if current_q is None:
            i += 1
            continue
        
        # Suite de l'énoncé
        if state == 'enonce' and line == 'Options :':
            state = 'options'
            i += 1
            continue
        
        if state == 'enonce' and not re.match(r'^[A-E]\s*:', line) and not re.match(r'^Réponse\s*:', line):
            if current_q['enonce']:
                current_q['enonce'] += ' ' + line
            else:
                current_q['enonce'] = line
            i += 1
            continue
        
        # Options: A : texte
        m_opt = re.match(r'^([A-E])\s*:\s*(.+)$', line)
        if m_opt and state in ('options', 'enonce'):
            state = 'options'
            current_q['options'][m_opt.group(1)] = m_opt.group(2).strip()
            i += 1
            continue
        
        # Réponse
        m_rep = re.match(r'^Réponse\s*:\s*([A-E])$', line)
        if m_rep:
            current_q['bonne_reponse'] = m_rep.group(1)
            state = 'reponse'
            i += 1
            continue
        
        # Explication détaillée (titre)
        if re.match(r'^Explication\s+d[eé]taill[eé]e?\s*:', line, re.IGNORECASE):
            state = 'explication'
            # Reste après le ":"
            rest = re.sub(r'^Explication\s+d[eé]taill[eé]e?\s*:\s*', '', line, flags=re.IGNORECASE)
            if rest:
                current_q['explication'] = rest
            i += 1
            continue
        
        if state == 'explication':
            # Arrêter si nouvelle question ou série
            if re.match(r'^Q\d+\s*[-–]\s*[EÉ]nonc', line) or re.match(r'^SÉRIE\s+\d+', line):
                # Ne pas incrémenter, laisser boucle gérer
                if current_q and current_q.get('enonce') and current_q.get('options'):
                    series_dict[current_serie]['questions'].append(current_q)
                    current_q = None
                continue
            
            # Accumuler explication
            sub_sections = ['Démonstration :', 'Analyse du Piège :', 'Lien Contextuel :']
            for sub in sub_sections:
                if line.startswith(sub):
                    current_q['explication'] += ' | ' + line
                    break
            else:
                if line and not line.startswith('---'):
                    current_q['explication'] += ' ' + line
        
        i += 1
    
    # Sauvegarder dernière question
    if current_q and current_q.get('enonce') and current_q.get('options') and current_serie:
        series_dict[current_serie]['questions'].append(current_q)
    
    return series_dict


# ============================================================
# PARSEUR MD GUIDE PANAFRICAIN
# ============================================================

def parse_guide_md_file(filepath, serie_num):
    """
    Parse un fichier MD Guide Panafricain.
    Format:
      # SÉRIE N : Titre
      1.  Énoncé ?
          A) ...
          B) ...
          **Réponse(s) correcte(s) : X, Y**
      
      ## Corrections détaillées
      1. **Réponse : X**
         * Explication : ...
    """
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extraire le titre
    title_m = re.search(r'^#\s+SÉRIE\s+\d+\s*:\s*(.+)$', content, re.MULTILINE)
    titre = title_m.group(1).strip() if title_m else f"Série {serie_num}"
    
    questions = []
    
    # Séparer la partie questions de la partie corrections
    parts = content.split('## Corrections détaillées')
    questions_part = parts[0]
    corrections_part = parts[1] if len(parts) > 1 else ''
    
    # Parser les questions
    # Pattern: N. Énoncé\n    A) ...\n    B) ...\n    **Réponse(s) correcte(s) : X**
    q_blocks = re.split(r'\n(?=\d+\.\s)', questions_part)
    
    for block in q_blocks:
        block = block.strip()
        if not block:
            continue
        
        # Numéro et énoncé
        m = re.match(r'^(\d+)\.\s+(.+?)(?=\n\s*[A-D]\)|\n\s+[A-D]\))', block, re.DOTALL)
        if not m:
            continue
        
        num = int(m.group(1))
        enonce = m.group(2).strip().replace('\n', ' ')
        enonce = re.sub(r'\s+', ' ', enonce)
        
        # Options
        opts = {}
        for letter in ['A', 'B', 'C', 'D']:
            opt_m = re.search(rf'\n\s+{letter}\)\s*(.+?)(?=\n\s+[A-D]\)|\n\s+\*\*R[ée]ponse|$)', block, re.DOTALL)
            if opt_m:
                txt = opt_m.group(1).strip().replace('\n', ' ')
                txt = re.sub(r'\s+', ' ', txt)
                opts[letter] = txt
        
        # Réponse correcte
        rep_m = re.search(r'\*\*R[ée]ponse\(s\) correcte\(s\)\s*:\s*([A-D,\s]+)\*\*', block)
        if rep_m:
            rep_raw = rep_m.group(1).strip()
            # Prendre la première réponse (format multi-réponses → stocker comme string)
            rep_letters = [r.strip() for r in rep_raw.split(',') if r.strip() in 'ABCD']
            bonne_reponse = rep_letters[0] if rep_letters else 'A'
            # Pour questions multi-réponses, on stocke la première lettre correcte
            # mais on indique les autres dans l'explication
        else:
            bonne_reponse = 'A'
            rep_raw = 'A'
        
        questions.append({
            'num': num,
            'enonce': enonce,
            'options': opts,
            'bonne_reponse': bonne_reponse,
            'bonne_reponse_full': rep_raw if rep_m else 'A',
            'explication': '',
            'categorie': titre
        })
    
    # Parser les corrections pour les explications
    if corrections_part:
        corr_blocks = re.split(r'\n(?=\d+\.\s+\*\*R[ée]ponse)', corrections_part)
        for block in corr_blocks:
            block = block.strip()
            m = re.match(r'^(\d+)\.\s+\*\*R[ée]ponse\(s\) correcte\(s\)\s*:\s*([A-D,\s]+)\*\*', block)
            if not m:
                continue
            num = int(m.group(1))
            
            # Explication
            exp_m = re.search(r'\*\s+\*\*Explication\s*:\*\*\s*(.+?)(?=\n\d+\.|$)', block, re.DOTALL)
            if exp_m:
                exp_txt = exp_m.group(1).strip().replace('\n', ' ')
                exp_txt = re.sub(r'\s+', ' ', exp_txt)
                # Ajouter l'explication à la question correspondante
                for q in questions:
                    if q['num'] == num:
                        # Inclure les réponses complètes dans l'explication
                        full_rep = m.group(2).strip()
                        if ',' in full_rep:
                            q['explication'] = f"Réponses correctes : {full_rep} | {exp_txt}"
                        else:
                            q['explication'] = exp_txt
                        break
    
    return {
        'titre': titre,
        'questions': questions
    }


def parse_all_guide_files(guide_dir):
    """Parse les 3 fichiers MD du Guide Panafricain"""
    files = sorted(os.listdir(guide_dir))
    md_files = [f for f in files if f.endswith('.md')]
    
    series = {}
    for idx, fn in enumerate(md_files, 1):
        path = os.path.join(guide_dir, fn)
        print(f"  Parsing fichier {idx}: {fn}")
        serie_data = parse_guide_md_file(path, idx)
        series[idx] = serie_data
        print(f"    → Titre: {serie_data['titre']}")
        print(f"    → Questions: {len(serie_data['questions'])}")
    
    return series


# ============================================================
# DÉDUPLICATION
# ============================================================

def deduplicate_questions(questions, existing_enonces=None):
    """Supprimer les doublons (même énoncé)"""
    seen = set()
    if existing_enonces:
        for e in existing_enonces:
            key = ' '.join(e.lower().split())[:150]
            seen.add(key)
    
    unique = []
    dup_count = 0
    
    for q in questions:
        key = ' '.join(q['enonce'].lower().split())[:150]
        if key not in seen:
            seen.add(key)
            unique.append(q)
        else:
            dup_count += 1
    
    if dup_count > 0:
        print(f"  ⚠️  {dup_count} doublon(s) supprimé(s)")
    
    return unique


# ============================================================
# INSERTION SERIES_QCM
# ============================================================

def create_serie_qcm(matiere_id, numero, titre, nb_questions=20):
    """Créer une série dans series_qcm"""
    data = {
        "id": str(uuid.uuid4()),
        "matiere_id": matiere_id,
        "titre": titre,
        "numero": numero,
        "niveau": "INTERMEDIAIRE",
        "duree_minutes": 20,
        "nb_questions": nb_questions,
        "est_demo": False,
        "actif": True,
        "published": True,
        "created_by": "system-import"
    }
    
    result, err = supabase_request("POST", "series_qcm", data=data, headers=HEADERS)
    if err:
        print(f"  ❌ Erreur création série '{titre}': {err}")
        return None
    
    # Récupérer l'ID créé
    if result and isinstance(result, list) and len(result) > 0:
        return result[0]['id']
    elif result and isinstance(result, dict):
        return result.get('id')
    else:
        # Si return=representation ne marche pas, recréer avec l'ID qu'on a générée
        return data['id']


def insert_questions_batch(questions_db, batch_size=30):
    """Insérer les questions en lots"""
    total = len(questions_db)
    inserted = 0
    errors = 0
    
    for i in range(0, total, batch_size):
        batch = questions_db[i:i+batch_size]
        result, err = supabase_request("POST", "questions", data=batch, headers=HEADERS_MINIMAL)
        
        if err and "duplicate" not in err.lower():
            print(f"  ❌ Erreur lot {i//batch_size + 1}: {err[:100]}")
            errors += len(batch)
        else:
            inserted += len(batch)
        
        print(f"    📤 Lot {i//batch_size + 1}/{(total + batch_size - 1)//batch_size}: {min(i+batch_size, total)}/{total}")
        time.sleep(0.4)
    
    return inserted, errors


def build_db_question(q, matiere_id, serie_id, numero, numero_serie):
    """Construire un objet question pour la DB"""
    opts = q.get('options', {})
    
    enonce = q['enonce']
    if len(enonce) > 1500:
        enonce = enonce[:1497] + '...'
    
    explication = q.get('explication', '')
    if len(explication) > 3000:
        explication = explication[:2997] + '...'
    
    tags = []
    if q.get('categorie'):
        tags.append(q['categorie'][:50])
    
    return {
        "id": str(uuid.uuid4()),
        "matiere_id": matiere_id,
        "serie_id": serie_id,
        "numero": numero,
        "enonce": enonce,
        "type": "QCM",
        "option_a": opts.get('A', ''),
        "option_b": opts.get('B', ''),
        "option_c": opts.get('C', ''),
        "option_d": opts.get('D', ''),
        "option_e": opts.get('E', None),
        "bonne_reponse": q.get('bonne_reponse', 'A'),
        "explication": explication if explication else None,
        "difficulte": "MOYEN",
        "published": True,
        "version": 1,
        "tags": tags if tags else None,
        "numero_serie": numero_serie,
        "created_by": "system-import"
    }


# ============================================================
# MAIN
# ============================================================

def main():
    print("=" * 65)
    print("🚀 INSERTION COMMUNICATION + GUIDE PANAFRICAIN - EF-FORT.BF")
    print("=" * 65)
    
    # Numéro de départ
    max_num = get_max_numero()
    print(f"\n📌 Numéro max actuel: {max_num}")
    current_numero = max_num + 1
    
    # =========================================================
    # 1. VÉRIFIER SÉRIES EXISTANTES (Communication)
    # =========================================================
    print("\n🔍 Vérification des séries existantes Communication...")
    existing_comm_series = supabase_get("series_qcm", {
        "select": "id,titre,numero",
        "matiere_id": f"eq.{COMM_ID}",
        "order": "numero"
    })
    
    # Nécessite un paramètre différent - utiliser filtre URL direct
    url = f"{SUPABASE_URL}/rest/v1/series_qcm?select=id,titre,numero&matiere_id=eq.{COMM_ID}&order=numero"
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req) as resp:
        existing_comm_series = json.loads(resp.read())
    
    print(f"  Séries Communication existantes: {len(existing_comm_series)}")
    existing_comm_nums = {s['numero'] for s in existing_comm_series}
    
    # Séries existantes Guide Panafricain
    url = f"{SUPABASE_URL}/rest/v1/series_qcm?select=id,titre,numero&matiere_id=eq.{GUIDE_ID}&order=numero"
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req) as resp:
        existing_guide_series = json.loads(resp.read())
    
    print(f"  Séries Guide Panafricain existantes: {len(existing_guide_series)}")
    existing_guide_nums = {s['numero'] for s in existing_guide_series}
    
    # =========================================================
    # 2. PARSER COMMUNICATION DOCX
    # =========================================================
    print("\n📖 COMMUNICATION - Parsing du DOCX (12 séries)...")
    comm_series_data = parse_communication_docx(COMM_DOCX)
    print(f"  Séries parsées: {len(comm_series_data)}")
    for num, sd in sorted(comm_series_data.items()):
        print(f"    Série {num}: '{sd['titre']}' → {len(sd['questions'])} questions")
    
    # =========================================================
    # 3. PARSER GUIDE PANAFRICAIN MD
    # =========================================================
    print("\n🌍 GUIDE PANAFRICAIN - Parsing des MD (3 séries)...")
    guide_series_data = parse_all_guide_files(GUIDE_DIR)
    
    # =========================================================
    # 4. INSERTION COMMUNICATION
    # =========================================================
    print("\n" + "=" * 65)
    print("📥 INSERTION COMMUNICATION")
    print("=" * 65)
    
    # Récupérer énoncés existants pour déduplication
    url = f"{SUPABASE_URL}/rest/v1/questions?select=enonce&matiere_id=eq.{COMM_ID}"
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req) as resp:
        existing_comm_q = json.loads(resp.read())
    existing_comm_enonces = [q['enonce'] for q in existing_comm_q if q.get('enonce')]
    print(f"  Questions Communication existantes: {len(existing_comm_enonces)}")
    
    total_comm_inserted = 0
    total_comm_series = 0
    
    for serie_num in sorted(comm_series_data.keys()):
        sd = comm_series_data[serie_num]
        titre = f"Communication – Série {serie_num:02d}"
        
        print(f"\n  📚 Série {serie_num}: '{sd['titre']}'")
        print(f"    Questions parsées: {len(sd['questions'])}")
        
        # Vérifier si la série existe déjà
        if serie_num in existing_comm_nums:
            print(f"    ⚠️  Série {serie_num} existe déjà → Skip")
            continue
        
        # Déduplication
        unique_qs = deduplicate_questions(sd['questions'], existing_comm_enonces)
        print(f"    Questions uniques: {len(unique_qs)}")
        
        if not unique_qs:
            print(f"    ⚠️  Aucune question valide → Skip")
            continue
        
        # Créer la série dans series_qcm
        serie_id = create_serie_qcm(COMM_ID, serie_num, titre, nb_questions=len(unique_qs))
        if not serie_id:
            print(f"    ❌ Échec création série → Skip")
            continue
        
        print(f"    ✅ Série créée: {serie_id}")
        
        # Construire les questions DB
        questions_db = []
        for q in unique_qs:
            if not q.get('enonce') or not q.get('options'):
                continue
            db_q = build_db_question(q, COMM_ID, serie_id, current_numero, serie_num)
            questions_db.append(db_q)
            current_numero += 1
            # Ajouter à la liste des énoncés existants pour dédup des séries suivantes
            existing_comm_enonces.append(q['enonce'])
        
        print(f"    Insertion de {len(questions_db)} questions...")
        ins, err = insert_questions_batch(questions_db)
        print(f"    ✅ Inséré: {ins} | ❌ Erreurs: {err}")
        
        total_comm_inserted += ins
        total_comm_series += 1
        
        time.sleep(0.5)
    
    # =========================================================
    # 5. INSERTION GUIDE PANAFRICAIN
    # =========================================================
    print("\n" + "=" * 65)
    print("🌍 INSERTION GUIDE PANAFRICAIN")
    print("=" * 65)
    
    # Récupérer énoncés existants pour déduplication
    url = f"{SUPABASE_URL}/rest/v1/questions?select=enonce&matiere_id=eq.{GUIDE_ID}"
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req) as resp:
        existing_guide_q = json.loads(resp.read())
    existing_guide_enonces = [q['enonce'] for q in existing_guide_q if q.get('enonce')]
    print(f"  Questions Guide Panafricain existantes: {len(existing_guide_enonces)}")
    
    total_guide_inserted = 0
    total_guide_series = 0
    
    for serie_num in sorted(guide_series_data.keys()):
        sd = guide_series_data[serie_num]
        titre = f"Guide panafricain – Série {serie_num:02d}"
        
        print(f"\n  📚 Série {serie_num}: '{sd['titre']}'")
        print(f"    Questions parsées: {len(sd['questions'])}")
        
        # Vérifier si la série existe déjà
        if serie_num in existing_guide_nums:
            print(f"    ⚠️  Série {serie_num} existe déjà → Skip")
            continue
        
        # Déduplication
        unique_qs = deduplicate_questions(sd['questions'], existing_guide_enonces)
        print(f"    Questions uniques: {len(unique_qs)}")
        
        if not unique_qs:
            print(f"    ⚠️  Aucune question valide → Skip")
            continue
        
        # Créer la série
        serie_id = create_serie_qcm(GUIDE_ID, serie_num, titre, nb_questions=len(unique_qs))
        if not serie_id:
            print(f"    ❌ Échec création série → Skip")
            continue
        
        print(f"    ✅ Série créée: {serie_id}")
        
        # Construire les questions DB
        questions_db = []
        for q in unique_qs:
            if not q.get('enonce') or not q.get('options'):
                continue
            db_q = build_db_question(q, GUIDE_ID, serie_id, current_numero, serie_num)
            questions_db.append(db_q)
            current_numero += 1
            existing_guide_enonces.append(q['enonce'])
        
        print(f"    Insertion de {len(questions_db)} questions...")
        ins, err = insert_questions_batch(questions_db)
        print(f"    ✅ Inséré: {ins} | ❌ Erreurs: {err}")
        
        total_guide_inserted += ins
        total_guide_series += 1
        
        time.sleep(0.5)
    
    # =========================================================
    # RÉSUMÉ
    # =========================================================
    print("\n" + "=" * 65)
    print("📊 RÉSUMÉ FINAL")
    print("=" * 65)
    print(f"  Communication:     {total_comm_series} séries | {total_comm_inserted} questions")
    print(f"  Guide Panafricain: {total_guide_series} séries | {total_guide_inserted} questions")
    print(f"  TOTAL:             {total_comm_series + total_guide_series} séries | {total_comm_inserted + total_guide_inserted} questions")
    print(f"  Prochain numéro:   {current_numero}")
    print("=" * 65)


if __name__ == "__main__":
    main()
