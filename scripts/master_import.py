#!/usr/bin/env python3
"""
EF-FORT.BF — Script Maître d'Import et Nettoyage
=================================================
1. Nettoyer la BDD (séries fantômes ECO2, doublon PSY/PSYCHO)
2. Insérer Force Armée Nationale (40 questions uniques) dans ARMEE
3. Insérer Actualité Internationale (160 questions uniques) dans ACTU
4. Insérer QCM Psychotechnique dans PSY (déduplication complète)
5. Mettre à jour compteurs des séries
"""

import re
import json
import time
import uuid
import urllib.request
import urllib.parse
from collections import Counter

# === CONFIGURATION ===
SUPABASE_URL = "https://xqifdbgqxyrlhrkwlyir.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg"

HEADERS_READ = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
}
HEADERS_WRITE = {
    **HEADERS_READ,
    "Prefer": "return=minimal",
}

# IDs des matières
MATIERE_ARMEE_ID = "b8df7f6e-587d-4871-856c-30dbaa6a52c3"   # Force Armée Nationale
MATIERE_ACTU_ID  = "5f7ef458-9fd3-4f70-b498-d3391b5d5677"   # Actualité Internationale
MATIERE_PSY_ID   = "54f53d06-2d5d-4d82-91bc-4bfff904c12b"   # Psychotechnique (PSY - canonique)
MATIERE_PSYCHO_ID = "cbd22275-d260-40d1-8ff3-d31545f3f1ab"  # Psychotechnique (PSYCHO - doublon à fusionner)

# ================================================================
# UTILITAIRES HTTP
# ================================================================

def api(method, endpoint, data=None, params=None, extra_headers=None):
    """Effectue une requête à l'API Supabase REST"""
    url = f"{SUPABASE_URL}/rest/v1/{endpoint}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    
    headers = {**HEADERS_WRITE}
    if extra_headers:
        headers.update(extra_headers)
    
    body = json.dumps(data).encode('utf-8') if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read()
            if content:
                return json.loads(content)
            return True
    except urllib.error.HTTPError as e:
        err_body = e.read().decode('utf-8')
        print(f"  ❌ HTTP {e.code} [{method} {endpoint}]: {err_body[:250]}")
        return None


def api_get(endpoint, qs=""):
    """GET simple"""
    url = f"{SUPABASE_URL}/rest/v1/{endpoint}{qs}"
    req = urllib.request.Request(url, headers=HEADERS_READ)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        print(f"  ❌ GET {endpoint}: {e.read().decode()[:200]}")
        return []


def delete_by_ids(table, ids, batch=50):
    """Supprime des enregistrements par liste d'IDs"""
    deleted = 0
    for i in range(0, len(ids), batch):
        chunk = ids[i:i+batch]
        ids_str = "(" + ",".join(f'"{x}"' for x in chunk) + ")"
        result = api("DELETE", table, params={"id": f"in.{ids_str}"})
        if result is not None:
            deleted += len(chunk)
        time.sleep(0.1)
    return deleted


# ================================================================
# STEP 1 : NETTOYAGE BDD
# ================================================================

def step1_cleanup():
    print("\n" + "="*60)
    print("🧹 STEP 1 : NETTOYAGE BASE DE DONNÉES")
    print("="*60)
    
    # 1a. Identifier les séries ECO2 fantômes (sans questions)
    print("\n📋 Identification des séries fantômes ECO2...")
    all_series = api_get("series_qcm", "?select=id,matiere_id,numero,titre&limit=500")
    all_questions = api_get("questions", "?select=id,serie_id&limit=10000")
    
    q_by_serie = Counter(q.get('serie_id') for q in all_questions if q.get('serie_id'))
    ECO2_MATIERE_ID = "756e1ca6-7f7f-4f42-940a-b6d9952ffcdf"
    
    ghost_series_ids = []
    for s in all_series:
        if s['matiere_id'] == ECO2_MATIERE_ID:
            if q_by_serie.get(s['id'], 0) == 0:
                ghost_series_ids.append(s['id'])
    
    print(f"  Séries ECO2 fantômes trouvées: {len(ghost_series_ids)}")
    
    if ghost_series_ids:
        print(f"  Suppression des {len(ghost_series_ids)} séries fantômes...")
        # Supprimer en chunks de 10 avec le bon format de filtre
        deleted_series = 0
        for i in range(0, len(ghost_series_ids), 10):
            chunk = ghost_series_ids[i:i+10]
            ids_csv = ",".join(chunk)
            result = api("DELETE", f"series_qcm?id=in.({ids_csv})")
            if result is not None:
                deleted_series += len(chunk)
            time.sleep(0.15)
        print(f"  ✅ {deleted_series} séries fantômes supprimées")
    
    # 1b. Fusionner PSY doublon → déplacer questions PSYCHO vers PSY
    print("\n🔀 Fusion PSYCHO → PSY (déduplication matière)...")
    q_psycho = api_get("questions", f"?select=id,enonce&matiere_id=eq.{MATIERE_PSYCHO_ID}&limit=500")
    q_psy = api_get("questions", f"?select=id,enonce&matiere_id=eq.{MATIERE_PSY_ID}&limit=500")
    
    print(f"  Questions PSYCHO (doublon): {len(q_psycho)}")
    print(f"  Questions PSY (canonique): {len(q_psy)}")
    
    # Identifier les énoncés déjà présents dans PSY
    psy_enonces = set()
    for q in q_psy:
        key = ' '.join(str(q.get('enonce', '')).lower().split())[:200]
        psy_enonces.add(key)
    
    # Parmi PSYCHO: ceux qui ne sont pas dans PSY → migrer vers PSY
    # Ceux qui sont dans PSY → supprimer
    to_migrate = []
    to_delete_psycho = []
    
    for q in q_psycho:
        key = ' '.join(str(q.get('enonce', '')).lower().split())[:200]
        if key in psy_enonces:
            to_delete_psycho.append(q['id'])
        else:
            to_migrate.append(q['id'])
    
    print(f"  À migrer vers PSY: {len(to_migrate)}")
    print(f"  À supprimer (doublons): {len(to_delete_psycho)}")
    
    # Migrer en batch PATCH
    migrated = 0
    for i in range(0, len(to_migrate), 20):
        chunk = to_migrate[i:i+20]
        ids_csv = ",".join(chunk)
        result = api("PATCH", f"questions?id=in.({ids_csv})", 
                     data={"matiere_id": MATIERE_PSY_ID})
        if result is not None:
            migrated += len(chunk)
        time.sleep(0.2)
    
    # Supprimer les vrais doublons
    if to_delete_psycho:
        for i in range(0, len(to_delete_psycho), 20):
            chunk = to_delete_psycho[i:i+20]
            ids_csv = ",".join(chunk)
            api("DELETE", f"questions?id=in.({ids_csv})")
            time.sleep(0.15)
    
    print(f"  ✅ Migrées: {migrated}, Supprimées doublons: {len(to_delete_psycho)}")
    
    # 1c. Nettoyer les séries PSY orphelines (série#1 PSY sans questions liées)
    s_psy = api_get("series_qcm", f"?select=id,numero&matiere_id=eq.{MATIERE_PSY_ID}")
    print(f"\n  Séries PSY existantes: {len(s_psy)}")
    
    # Recompter après migration
    q_psy_after = api_get("questions", f"?select=id,serie_id&matiere_id=eq.{MATIERE_PSY_ID}&limit=2000")
    q_by_serie_psy = Counter(q.get('serie_id') for q in q_psy_after if q.get('serie_id'))
    
    # Les questions PSY sans série_id
    q_psy_no_serie = [q for q in q_psy_after if not q.get('serie_id')]
    print(f"  Questions PSY sans serie_id: {len(q_psy_no_serie)}")
    print(f"  Questions PSY totales: {len(q_psy_after)}")
    
    return {
        'ghost_deleted': len(ghost_series_ids),
        'psy_migrated': migrated,
        'psy_total': len(q_psy_after),
        'psy_no_serie': len(q_psy_no_serie)
    }


# ================================================================
# STEP 2 : FORCE ARMÉE NATIONALE
# ================================================================

def parse_force_armee(filepath):
    """Parse le fichier Force Armée MD - format ### Q{n} - [{cat}]"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    blocks = re.split(r'\n---\n', content)
    q_blocks = [b.strip() for b in blocks if re.search(r'###\s+Q\d+', b)]
    
    questions = []
    seen_enonces = {}
    
    for block in q_blocks:
        # Catégorie
        cat_match = re.search(r'###\s+Q\d+\s*[-–]\s*\[([^\]]+)\]', block)
        cat = cat_match.group(1).strip() if cat_match else 'Force Armée'
        
        # Énoncé
        enonce_match = re.search(
            r'\*\*[EÉ]nonc[eé]\s*:\*\*\s*(.+?)(?=\n\*\*Options|\n-\s*\*\*A|\Z)',
            block, re.DOTALL
        )
        if not enonce_match:
            continue
        enonce = enonce_match.group(1).strip()
        
        # Déduplication
        key = ' '.join(enonce.lower().split())[:200]
        if key in seen_enonces:
            continue
        seen_enonces[key] = True
        
        # Options (format: - **A** : ...)
        opts = {}
        for letter in ['A', 'B', 'C', 'D', 'E']:
            opt_match = re.search(
                rf'-\s*\*\*{letter}\*\*\s*:\s*(.+?)(?=\n-\s*\*\*[A-E]\*\*|\n\n|\*\*R[ée]ponse|$)',
                block, re.DOTALL
            )
            if opt_match:
                opts[letter] = opt_match.group(1).strip().replace('\n', ' ')
        
        # Réponse
        rep_match = re.search(r'\*\*R[ée]ponse\s*:\*\*\s*([A-E])', block)
        bonne_rep = rep_match.group(1) if rep_match else 'A'
        
        # Explication
        exp_match = re.search(
            r'\*\*Explication(?:\s+d[ée]taill[ée]e?)?\s*:\*\*\s*(.+?)(?=\n###|$)',
            block, re.DOTALL
        )
        explication = exp_match.group(1).strip() if exp_match else ''
        # Nettoyer l'explication (garder le texte principal)
        explication = re.sub(r'\d+\.\s*\*\*[^*]+\*\*\s*:', '', explication)
        explication = explication.strip()[:500]
        
        questions.append({
            'categorie': cat,
            'enonce': enonce,
            'options': opts,
            'bonne_reponse': bonne_rep,
            'explication': explication,
        })
    
    return questions


def step2_force_armee(q_list, start_numero):
    print("\n" + "="*60)
    print("🪖 STEP 2 : FORCE ARMÉE NATIONALE")
    print("="*60)
    
    print(f"  Questions uniques parsées: {len(q_list)}")
    
    if not q_list:
        print("  ⚠️  Aucune question à insérer")
        return 0, 0, start_numero
    
    # Vérifier les questions déjà en BDD pour ARMEE
    existing = api_get("questions", f"?select=enonce&matiere_id=eq.{MATIERE_ARMEE_ID}&limit=500")
    existing_keys = set()
    for q in existing:
        key = ' '.join(str(q.get('enonce', '')).lower().split())[:200]
        existing_keys.add(key)
    
    print(f"  Questions ARMEE déjà en BDD: {len(existing_keys)}")
    
    # Filtrer les nouvelles
    new_q = []
    for q in q_list:
        key = ' '.join(q['enonce'].lower().split())[:200]
        if key not in existing_keys:
            new_q.append(q)
    
    print(f"  Nouvelles questions à insérer: {len(new_q)}")
    
    if not new_q:
        print("  ✅ Rien à insérer (déjà en BDD)")
        return 0, 0, start_numero
    
    # Créer les séries pour ARMEE (20 questions par série)
    # Catégories → séries
    series_created = {}
    cats = list(dict.fromkeys(q['categorie'] for q in new_q))  # Ordre conservé
    
    print(f"\n  Création de {len(cats)} séries thématiques...")
    
    # Chercher les séries ARMEE existantes pour numérotation
    existing_series_armee = api_get("series_qcm", f"?select=numero&matiere_id=eq.{MATIERE_ARMEE_ID}&order=numero.desc&limit=1")
    next_serie_num = 1
    if existing_series_armee:
        next_serie_num = existing_series_armee[0]['numero'] + 1
    
    for cat in cats:
        serie_data = {
            "id": str(uuid.uuid4()),
            "matiere_id": MATIERE_ARMEE_ID,
            "titre": f"Série {next_serie_num:02d} — {cat[:40]}",
            "numero": next_serie_num,
            "niveau": "INTERMEDIAIRE",
            "duree_minutes": 15,
            "nb_questions": sum(1 for q in new_q if q['categorie'] == cat),
            "est_demo": False,
            "actif": True,
            "published": True,
        }
        result = api("POST", "series_qcm", data=serie_data)
        if result is not None:
            series_created[cat] = serie_data['id']
            print(f"    ✅ Série {next_serie_num:02d}: {cat[:50]}")
            next_serie_num += 1
        else:
            print(f"    ❌ Échec création série: {cat}")
        time.sleep(0.2)
    
    # Construire et insérer les questions
    questions_db = []
    current_num = start_numero
    
    for q in new_q:
        opts = q.get('options', {})
        serie_id = series_created.get(q['categorie'])
        
        questions_db.append({
            "id": str(uuid.uuid4()),
            "matiere_id": MATIERE_ARMEE_ID,
            "serie_id": serie_id,
            "numero": current_num,
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
            "tags": [q['categorie']] if q.get('categorie') else None,
            "numero_serie": 1,
        })
        current_num += 1
    
    # Insérer en batch
    print(f"\n  Insertion de {len(questions_db)} questions ARMEE...")
    inserted = 0
    for i in range(0, len(questions_db), 20):
        batch = questions_db[i:i+20]
        result = api("POST", "questions", data=batch)
        if result is not None:
            inserted += len(batch)
            print(f"    📤 Lot {i//20+1}: {min(i+20, len(questions_db))}/{len(questions_db)}")
        else:
            print(f"    ❌ Erreur lot {i//20+1}")
        time.sleep(0.3)
    
    print(f"\n  ✅ ARMEE: {inserted} questions insérées, {len(series_created)} séries créées")
    return inserted, len(series_created), current_num


# ================================================================
# STEP 3 : ACTUALITÉ INTERNATIONALE
# ================================================================

def parse_actualite(filepath):
    """Parse le fichier Actualité Internationale MD"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    blocks = re.split(r'\n---\n', content)
    questions = []
    seen = set()
    
    for block in blocks:
        block = block.strip()
        if not re.search(r'QCM\s+\d+\s*:', block):
            continue
        
        # Énoncé (après QCM N :)
        enonce_match = re.search(r'QCM\s+\d+\s*:\s*(.+?)(?=\nA\.|\nA\)|\Z)', block, re.DOTALL)
        if not enonce_match:
            continue
        enonce = enonce_match.group(1).strip().replace('\n', ' ')
        enonce = re.sub(r'\s+', ' ', enonce).strip()
        
        # Déduplication
        key = ' '.join(enonce.lower().split())[:200]
        if key in seen:
            continue
        seen.add(key)
        
        # Options (format: A. texte ou A) texte)
        opts = {}
        for letter in ['A', 'B', 'C', 'D', 'E']:
            opt_match = re.search(
                rf'(?:^|\n){letter}[\.)][ \t]+(.+?)(?=\n[A-E][\.)]|\nRéponse|\nExplication|\Z)',
                block, re.DOTALL
            )
            if opt_match:
                opts[letter] = opt_match.group(1).strip().replace('\n', ' ')
        
        # Réponse
        rep_match = re.search(r'R[ée]ponse\s+correcte\s*:\s*([A-E])', block)
        if not rep_match:
            rep_match = re.search(r'R[ée]ponse\s*:\s*([A-E])', block)
        bonne_rep = rep_match.group(1) if rep_match else 'A'
        
        # Explication
        exp_match = re.search(r'Explication\s+d[ée]taill[ée]e?\s*:\s*(.+?)(?=\n---|\Z)', block, re.DOTALL)
        if not exp_match:
            exp_match = re.search(r'Explication\s*:\s*(.+?)(?=\n---|\Z)', block, re.DOTALL)
        explication = exp_match.group(1).strip() if exp_match else ''
        explication = explication[:500]
        
        if len(opts) >= 2:
            questions.append({
                'categorie': 'Actualité Internationale',
                'enonce': enonce,
                'options': opts,
                'bonne_reponse': bonne_rep,
                'explication': explication,
            })
    
    return questions


def step3_actualite(q_list, start_numero):
    print("\n" + "="*60)
    print("🌍 STEP 3 : ACTUALITÉ INTERNATIONALE")
    print("="*60)
    
    print(f"  Questions uniques parsées: {len(q_list)}")
    
    if not q_list:
        print("  ⚠️  Aucune question à insérer")
        return 0, 0, start_numero
    
    # Vérifier les questions déjà en BDD pour ACTU
    existing = api_get("questions", f"?select=enonce&matiere_id=eq.{MATIERE_ACTU_ID}&limit=1000")
    existing_keys = set()
    for q in existing:
        key = ' '.join(str(q.get('enonce', '')).lower().split())[:200]
        existing_keys.add(key)
    
    print(f"  Questions ACTU déjà en BDD: {len(existing_keys)}")
    
    new_q = []
    for q in q_list:
        key = ' '.join(q['enonce'].lower().split())[:200]
        if key not in existing_keys:
            new_q.append(q)
    
    print(f"  Nouvelles questions à insérer: {len(new_q)}")
    
    if not new_q:
        print("  ✅ Rien à insérer (déjà en BDD)")
        return 0, 0, start_numero
    
    # Créer les séries pour ACTU (20 questions par série)
    NB_PAR_SERIE = 20
    total = len(new_q)
    nb_series = (total + NB_PAR_SERIE - 1) // NB_PAR_SERIE
    
    # Chercher la dernière série ACTU
    existing_series = api_get("series_qcm", f"?select=numero&matiere_id=eq.{MATIERE_ACTU_ID}&order=numero.desc&limit=1")
    next_num = 1
    if existing_series:
        next_num = existing_series[0]['numero'] + 1
    
    print(f"\n  Création de {nb_series} séries (20 questions chacune)...")
    
    series_ids = []
    for s in range(nb_series):
        q_dans_serie = new_q[s*NB_PAR_SERIE:(s+1)*NB_PAR_SERIE]
        serie_data = {
            "id": str(uuid.uuid4()),
            "matiere_id": MATIERE_ACTU_ID,
            "titre": f"Série {next_num:02d} — Actualité Internationale",
            "numero": next_num,
            "niveau": "INTERMEDIAIRE",
            "duree_minutes": 20,
            "nb_questions": len(q_dans_serie),
            "est_demo": False,
            "actif": True,
            "published": True,
        }
        result = api("POST", "series_qcm", data=serie_data)
        if result is not None:
            series_ids.append(serie_data['id'])
            print(f"    ✅ Série {next_num:02d} ({len(q_dans_serie)} questions)")
            next_num += 1
        time.sleep(0.2)
    
    # Construire les questions avec serie_id
    questions_db = []
    current_num = start_numero
    
    for i, q in enumerate(new_q):
        serie_idx = i // NB_PAR_SERIE
        serie_id = series_ids[serie_idx] if serie_idx < len(series_ids) else None
        opts = q.get('options', {})
        
        questions_db.append({
            "id": str(uuid.uuid4()),
            "matiere_id": MATIERE_ACTU_ID,
            "serie_id": serie_id,
            "numero": current_num,
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
            "tags": ["Géopolitique", "Actualité 2026"],
            "numero_serie": (i % NB_PAR_SERIE) + 1,
        })
        current_num += 1
    
    # Insérer en batch
    print(f"\n  Insertion de {len(questions_db)} questions ACTU...")
    inserted = 0
    for i in range(0, len(questions_db), 20):
        batch = questions_db[i:i+20]
        result = api("POST", "questions", data=batch)
        if result is not None:
            inserted += len(batch)
            print(f"    📤 Lot {i//20+1}: {min(i+20, len(questions_db))}/{len(questions_db)}")
        time.sleep(0.3)
    
    print(f"\n  ✅ ACTU: {inserted} questions insérées, {len(series_ids)} séries créées")
    return inserted, len(series_ids), current_num


# ================================================================
# STEP 4 : PSYCHOTECHNIQUE (PDF + Génération)
# ================================================================

PSYCHO_QCM_BANK = [
    # === SÉRIES NUMÉRIQUES ===
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 2, 4, 8, 16, ?", "opts": {"A":"24","B":"32","C":"28","D":"30"}, "rep": "B", "exp": "Suite géométrique de raison 2. 16×2=32."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 3, 6, 12, 24, ?", "opts": {"A":"36","B":"42","C":"48","D":"60"}, "rep": "C", "exp": "Raison 2 : 24×2=48."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 1, 4, 9, 16, ?", "opts": {"A":"20","B":"25","C":"30","D":"36"}, "rep": "B", "exp": "Carrés parfaits : 1²,2²,3²,4²,5²=25."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 5, 10, 20, 40, ?", "opts": {"A":"60","B":"70","C":"80","D":"100"}, "rep": "C", "exp": "Raison 2 : 40×2=80."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 100, 50, 25, ?", "opts": {"A":"10","B":"12","C":"12.5","D":"15"}, "rep": "C", "exp": "Division par 2 : 25/2=12.5."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 1, 1, 2, 3, 5, 8, ?", "opts": {"A":"11","B":"13","C":"12","D":"10"}, "rep": "B", "exp": "Suite de Fibonacci : chaque terme = somme des deux précédents. 5+8=13."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 7, 14, 21, 28, ?", "opts": {"A":"32","B":"35","C":"36","D":"42"}, "rep": "B", "exp": "Multiples de 7 : 7×5=35."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 81, 27, 9, 3, ?", "opts": {"A":"1","B":"2","C":"0","D":"0.5"}, "rep": "A", "exp": "Division par 3 : 3/3=1."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 2, 5, 11, 23, ?", "opts": {"A":"45","B":"47","C":"46","D":"48"}, "rep": "B", "exp": "Règle : ×2+1. 23×2+1=47."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 10, 13, 17, 22, ?", "opts": {"A":"27","B":"28","C":"29","D":"30"}, "rep": "B", "exp": "Différences: +3,+4,+5,+6. Donc 22+6=28."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 0, 1, 3, 6, 10, ?", "opts": {"A":"13","B":"14","C":"15","D":"16"}, "rep": "C", "exp": "Nombres triangulaires : +1,+2,+3,+4,+5. 10+5=15."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 4, 9, 16, 25, 36, ?", "opts": {"A":"42","B":"48","C":"49","D":"50"}, "rep": "C", "exp": "Carrés : 2²,3²,4²,5²,6²,7²=49."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 1000, 500, 250, 125, ?", "opts": {"A":"60","B":"62.5","C":"65","D":"70"}, "rep": "B", "exp": "Division par 2: 125/2=62.5."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 3, 7, 15, 31, ?", "opts": {"A":"62","B":"63","C":"64","D":"65"}, "rep": "B", "exp": "Règle ×2+1: 31×2+1=63."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 6, 11, 21, 41, ?", "opts": {"A":"80","B":"81","C":"82","D":"83"}, "rep": "B", "exp": "Règle: ×2-1. 41×2-1=81."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 12, 10, 13, 11, 14, ?", "opts": {"A":"11","B":"12","C":"13","D":"15"}, "rep": "B", "exp": "Alternance: -2,+3,-2,+3,-2. 14-2=12."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 1, 8, 27, 64, ?", "opts": {"A":"100","B":"121","C":"125","D":"130"}, "rep": "C", "exp": "Cubes: 1³,2³,3³,4³,5³=125."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 45, 40, 35, 30, ?", "opts": {"A":"20","B":"25","C":"22","D":"28"}, "rep": "B", "exp": "Soustraction de 5: 30-5=25."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 2, 3, 5, 7, 11, ?", "opts": {"A":"12","B":"13","C":"14","D":"15"}, "rep": "B", "exp": "Suite des nombres premiers: 2,3,5,7,11,13."},
    {"cat": "Séries Numériques", "enonce": "Trouvez le nombre manquant : 72, 36, 18, 9, ?", "opts": {"A":"3","B":"4","C":"4.5","D":"5"}, "rep": "C", "exp": "Division par 2: 9/2=4.5."},
    # === SÉRIES ALPHABÉTIQUES ===
    {"cat": "Séries Alphabétiques", "enonce": "Trouvez la lettre manquante : A, C, E, G, ?", "opts": {"A":"H","B":"I","C":"J","D":"K"}, "rep": "B", "exp": "Lettres impaires: A(1),C(3),E(5),G(7),I(9)."},
    {"cat": "Séries Alphabétiques", "enonce": "Trouvez la lettre manquante : Z, X, V, T, ?", "opts": {"A":"Q","B":"R","C":"S","D":"P"}, "rep": "B", "exp": "Reculer de 2: Z,X,V,T,R."},
    {"cat": "Séries Alphabétiques", "enonce": "Trouvez la lettre manquante : A, B, D, G, K, ?", "opts": {"A":"N","B":"O","C":"P","D":"Q"}, "rep": "C", "exp": "Sauts: +1,+2,+3,+4,+5. K(11)+5=P(16)."},
    {"cat": "Séries Alphabétiques", "enonce": "Trouvez la lettre manquante : B, E, H, K, ?", "opts": {"A":"M","B":"N","C":"O","D":"P"}, "rep": "B", "exp": "Sauts de 3: B(2),E(5),H(8),K(11),N(14)."},
    {"cat": "Séries Alphabétiques", "enonce": "Trouvez la lettre manquante : M, K, I, G, ?", "opts": {"A":"E","B":"D","C":"F","D":"C"}, "rep": "A", "exp": "Reculer de 2: M,K,I,G,E."},
    {"cat": "Séries Alphabétiques", "enonce": "Trouvez la lettre manquante : A, E, I, ?, U", "opts": {"A":"N","B":"O","C":"M","D":"P"}, "rep": "B", "exp": "Voyelles dans l'ordre: A,E,I,O,U."},
    {"cat": "Séries Alphabétiques", "enonce": "Trouvez la lettre manquante : C, F, I, L, ?", "opts": {"A":"M","B":"N","C":"O","D":"P"}, "rep": "C", "exp": "Sauts de 3: C(3),F(6),I(9),L(12),O(15)."},
    {"cat": "Séries Alphabétiques", "enonce": "Trouvez la lettre manquante : D, H, L, P, ?", "opts": {"A":"R","B":"S","C":"T","D":"U"}, "rep": "C", "exp": "Sauts de 4: D(4),H(8),L(12),P(16),T(20)."},
    {"cat": "Séries Alphabétiques", "enonce": "Complétez: A1, B2, C3, D4, ?", "opts": {"A":"E4","B":"E5","C":"F5","D":"E6"}, "rep": "B", "exp": "Lettre suivante + chiffre suivant: E5."},
    {"cat": "Séries Alphabétiques", "enonce": "Trouvez la lettre manquante : Z, A, Y, B, X, ?", "opts": {"A":"C","B":"D","C":"W","D":"V"}, "rep": "A", "exp": "Alternance: fin (Z,Y,X) et début (A,B,C) de l'alphabet."},
    # === LOGIQUE GÉNÉRALE ===
    {"cat": "Logique Générale", "enonce": "Tous les oiseaux ont des plumes. Le canari est un oiseau. Donc...", "opts": {"A":"Le canari vole","B":"Le canari a des plumes","C":"Tous les oiseaux chantent","D":"Le canari est un mammifère"}, "rep": "B", "exp": "Syllogisme classique: si tout A est B et que C est A, alors C est B."},
    {"cat": "Logique Générale", "enonce": "Si P implique Q, et Q implique R, alors...", "opts": {"A":"R implique P","B":"P implique R","C":"Q implique P","D":"Aucune relation"}, "rep": "B", "exp": "Transitivité de l'implication: P→Q et Q→R ⟹ P→R."},
    {"cat": "Logique Générale", "enonce": "Aucun poisson n'est un mammifère. La baleine est un mammifère. Donc...", "opts": {"A":"La baleine est un poisson","B":"La baleine n'est pas un poisson","C":"Les poissons sont des mammifères","D":"La baleine vit dans l'eau"}, "rep": "B", "exp": "Par la contraposée: si aucun poisson n'est mammifère, la baleine (mammifère) ne peut être poisson."},
    {"cat": "Logique Générale", "enonce": "3 boîtes: rouge, verte, bleue. La verte est entre les deux autres. La bleue est à gauche de la rouge. Quelle est l'ordre?", "opts": {"A":"Rouge-Verte-Bleue","B":"Bleue-Verte-Rouge","C":"Verte-Bleue-Rouge","D":"Rouge-Bleue-Verte"}, "rep": "B", "exp": "Bleue à gauche de rouge, et verte entre les deux → Bleue-Verte-Rouge."},
    {"cat": "Logique Générale", "enonce": "Si tous les A sont des B, est-ce que tous les B sont des A ?", "opts": {"A":"Oui, toujours","B":"Non, pas nécessairement","C":"Seulement si B=A","D":"Oui si le nombre d'éléments est égal"}, "rep": "B", "exp": "Contre-exemple: tous les chiens sont des animaux, mais tous les animaux ne sont pas des chiens."},
    {"cat": "Logique Générale", "enonce": "Ahmed est plus grand que Bocar. Bocar est plus grand que Chaka. Qui est le plus petit?", "opts": {"A":"Ahmed","B":"Bocar","C":"Chaka","D":"Impossible à déterminer"}, "rep": "C", "exp": "Transitivité: Ahmed > Bocar > Chaka. Donc Chaka est le plus petit."},
    {"cat": "Logique Générale", "enonce": "Une déclaration est vraie ou fausse. Si elle est vraie, sa négation est...", "opts": {"A":"Vraie","B":"Fausse","C":"Indéterminée","D":"Vraie et fausse"}, "rep": "B", "exp": "Loi de non-contradiction: une proposition et sa négation ne peuvent être vraies simultanément."},
    {"cat": "Logique Générale", "enonce": "5 enfants jouent dans le jardin. 3 ont une casquette rouge. 2 ont une casquette bleue. Combien d'enfants ont-ils une casquette?", "opts": {"A":"2","B":"3","C":"5","D":"Impossible à dire"}, "rep": "C", "exp": "Si 3 ont rouge et 2 ont bleue, et 3+2=5 qui correspond au total, tous ont une casquette."},
    {"cat": "Logique Générale", "enonce": "Complétez l'analogie : Chien est à Aboyer comme Chat est à ...", "opts": {"A":"Sauter","B":"Miauler","C":"Courir","D":"Nager"}, "rep": "B", "exp": "Analogie son/animal: le chien aboie, le chat miaule."},
    {"cat": "Logique Générale", "enonce": "Dans une course, Paul arrive avant Pierre. Pierre arrive avant Sébastien. Qui est dernier?", "opts": {"A":"Paul","B":"Pierre","C":"Sébastien","D":"Impossible à déterminer"}, "rep": "C", "exp": "Paul > Pierre > Sébastien. Donc Sébastien est dernier."},
    {"cat": "Logique Générale", "enonce": "Si un nombre est divisible par 6, il est divisible par...", "opts": {"A":"3 seulement","B":"2 seulement","C":"2 et 3","D":"4 et 12"}, "rep": "C", "exp": "6=2×3. Tout multiple de 6 est aussi multiple de 2 et de 3."},
    {"cat": "Logique Générale", "enonce": "Quelle figure complète la suite : Cercle, Triangle, Carré, Pentagone, ?", "opts": {"A":"Octogone","B":"Hexagone","C":"Heptagone","D":"Ellipse"}, "rep": "B", "exp": "Figures à côtés croissants: 0,3,4,5,6. La suivante est l'hexagone (6 côtés)."},
    {"cat": "Logique Générale", "enonce": "Tous les médecins sont diplômés. Jean est diplômé. Donc Jean est...", "opts": {"A":"Certainement médecin","B":"Peut-être médecin","C":"Certainement pas médecin","D":"Forcément chirurgien"}, "rep": "B", "exp": "Erreur logique à éviter: tous les médecins sont diplômés, mais tous les diplômés ne sont pas médecins."},
    {"cat": "Logique Générale", "enonce": "Marie est la mère de Jean. Jean est le père de Sophie. Quelle est la relation entre Marie et Sophie?", "opts": {"A":"Mère","B":"Cousine","C":"Grand-mère","D":"Tante"}, "rep": "C", "exp": "Marie→Jean→Sophie: Marie est la grand-mère de Sophie."},
    {"cat": "Logique Générale", "enonce": "Dans un groupe de 30 élèves, 18 font du sport et 15 font de la musique. Combien font les deux au minimum?", "opts": {"A":"0","B":"3","C":"5","D":"8"}, "rep": "B", "exp": "Principe de Pigeonhole: 18+15-30=3. Au minimum 3 élèves font les deux."},
    {"cat": "Logique Générale", "enonce": "Un train part à 8h et arrive à 11h30. Durée du trajet?", "opts": {"A":"2h30","B":"3h","C":"3h30","D":"4h"}, "rep": "C", "exp": "11h30 - 8h00 = 3h30."},
    {"cat": "Logique Générale", "enonce": "Complétez: Livre est à Bibliothèque comme Tableau est à...", "opts": {"A":"Couleur","B":"Musée","C":"Peintre","D":"Cadre"}, "rep": "B", "exp": "Analogie lieu de conservation: livre→bibliothèque, tableau→musée."},
    {"cat": "Logique Générale", "enonce": "Si A=B et C>B, alors...", "opts": {"A":"C>A","B":"C=A","C":"C<A","D":"Impossible à déterminer"}, "rep": "A", "exp": "Si A=B et C>B, alors C>A (par substitution)."},
    {"cat": "Logique Générale", "enonce": "Un père a 3 fois l'âge de son fils. Dans 10 ans, il aura 2 fois l'âge de son fils. Quel est l'âge actuel du fils?", "opts": {"A":"8","B":"10","C":"12","D":"15"}, "rep": "B", "exp": "Équation: 3x+10=2(x+10) → 3x+10=2x+20 → x=10."},
    {"cat": "Logique Générale", "enonce": "Lequel est l'intrus dans : lune, soleil, étoile, planète, océan?", "opts": {"A":"lune","B":"soleil","C":"océan","D":"étoile"}, "rep": "C", "exp": "L'océan est terrestre; tous les autres sont des astres/corps célestes."},
    {"cat": "Logique Générale", "enonce": "Si aujourd'hui est mercredi, quel jour sera-t-il dans 10 jours?", "opts": {"A":"Jeudi","B":"Vendredi","C":"Samedi","D":"Dimanche"}, "rep": "C", "exp": "10 mod 7 = 3. Mercredi + 3 jours = Samedi."},
    # === INTRUS ===
    {"cat": "Intrus", "enonce": "Trouvez l'intrus : lion, tigre, chat, dauphin, guépard", "opts": {"A":"lion","B":"dauphin","C":"chat","D":"guépard"}, "rep": "B", "exp": "Tous sont des félins sauf le dauphin qui est un cétacé."},
    {"cat": "Intrus", "enonce": "Trouvez l'intrus : rose, tulipe, dahlia, carotte, lys", "opts": {"A":"rose","B":"carotte","C":"lys","D":"tulipe"}, "rep": "B", "exp": "La carotte est un légume-racine; les autres sont des fleurs."},
    {"cat": "Intrus", "enonce": "Trouvez l'intrus : Paris, Londres, Berlin, Tokyo, Sahara", "opts": {"A":"Paris","B":"Berlin","C":"Sahara","D":"Tokyo"}, "rep": "C", "exp": "Le Sahara est un désert; les autres sont des capitales."},
    {"cat": "Intrus", "enonce": "Trouvez l'intrus : piano, guitare, violon, flûte, marteau", "opts": {"A":"piano","B":"marteau","C":"flûte","D":"violon"}, "rep": "B", "exp": "Le marteau est un outil; les autres sont des instruments de musique."},
    {"cat": "Intrus", "enonce": "Trouvez l'intrus : bleu, rouge, vert, triangle, jaune", "opts": {"A":"bleu","B":"rouge","C":"triangle","D":"vert"}, "rep": "C", "exp": "Le triangle est une forme géométrique; les autres sont des couleurs."},
    {"cat": "Intrus", "enonce": "Trouvez l'intrus : Sénégal, Côte d'Ivoire, Burkina Faso, Seine, Mali", "opts": {"A":"Sénégal","B":"Seine","C":"Mali","D":"Burkina Faso"}, "rep": "B", "exp": "La Seine est un fleuve français; les autres sont des pays d'Afrique de l'Ouest."},
    {"cat": "Intrus", "enonce": "Trouvez l'intrus : addition, soustraction, dictée, multiplication, division", "opts": {"A":"addition","B":"dictée","C":"division","D":"soustraction"}, "rep": "B", "exp": "La dictée est un exercice de français; les autres sont des opérations mathématiques."},
    {"cat": "Intrus", "enonce": "Trouvez l'intrus : eau, vent, pluie, or, neige", "opts": {"A":"eau","B":"or","C":"vent","D":"pluie"}, "rep": "B", "exp": "L'or est un métal précieux; les autres sont des phénomènes météorologiques ou de l'eau."},
    {"cat": "Intrus", "enonce": "Trouvez l'intrus : lundi, mardi, avril, jeudi, vendredi", "opts": {"A":"lundi","B":"avril","C":"jeudi","D":"mardi"}, "rep": "B", "exp": "Avril est un mois; les autres sont des jours de la semaine."},
    {"cat": "Intrus", "enonce": "Trouvez l'intrus : tomate, aubergine, courgette, fraise, poivron", "opts": {"A":"tomate","B":"fraise","C":"courgette","D":"poivron"}, "rep": "B", "exp": "La fraise est un fruit de jardin sucré; les autres sont des légumes du potager."},
    # === MATRICES ET CARRÉS LOGIQUES ===
    {"cat": "Carrés Logiques", "enonce": "Dans un carré magique 3×3 de somme 15, si la case centrale vaut 5, que vaut la somme d'une diagonale?", "opts": {"A":"10","B":"12","C":"15","D":"20"}, "rep": "C", "exp": "Par définition d'un carré magique, toutes les lignes, colonnes et diagonales ont la même somme = 15."},
    {"cat": "Carrés Logiques", "enonce": "Un carré contient les chiffres 1 à 9 en 3×3. La somme de chaque ligne est 15. Que vaut la case centrale?", "opts": {"A":"4","B":"5","C":"6","D":"7"}, "rep": "B", "exp": "La case centrale d'un carré magique 3×3 est toujours la moyenne des nombres utilisés: (1+2+...+9)/9=5."},
    {"cat": "Carrés Logiques", "enonce": "Dans la suite matricielle: 2,4 / 6,8 / 10,? Que vaut ?", "opts": {"A":"11","B":"12","C":"13","D":"14"}, "rep": "B", "exp": "Progression de 2 en 2: 2,4,6,8,10,12."},
    {"cat": "Carrés Logiques", "enonce": "Ligne 1: 1,2,3. Ligne 2: 4,5,6. Ligne 3: 7,8,?", "opts": {"A":"8","B":"9","C":"10","D":"11"}, "rep": "B", "exp": "Suite naturelle des entiers: après 8 vient 9."},
    {"cat": "Carrés Logiques", "enonce": "Si la somme des deux premières colonnes vaut 20 et 22, et la matrice est 2×2, que vaut la 4ème case si les 3 premières sont 5,10,7?", "opts": {"A":"12","B":"13","C":"14","D":"15"}, "rep": "A", "exp": "Colonne 2: 10+?=22, donc ?=12."},
    {"cat": "Carrés Logiques", "enonce": "Dans le tableau: [2,4,6] [8,10,12] [14,16,?], que vaut ?", "opts": {"A":"17","B":"18","C":"19","D":"20"}, "rep": "B", "exp": "Suite arithmétique de raison 2: après 16 vient 18."},
    {"cat": "Carrés Logiques", "enonce": "Un carré de Sudoku 2×2 contient 1,2,3,4. La ligne 1 est 1,2 et la colonne 1 est 1,3. Que vaut la case (2,2)?", "opts": {"A":"2","B":"3","C":"4","D":"1"}, "rep": "C", "exp": "Par élimination: ligne 2 contient 3 et 4. Colonne 2 contient 2. Donc case (2,2)=4."},
    {"cat": "Carrés Logiques", "enonce": "Matrices: [3,6] [12,24]. Quel est le principe?", "opts": {"A":"Addition de 3","B":"Multiplication par 2","C":"Multiplication par 3","D":"Addition de 6"}, "rep": "B", "exp": "3×2=6, 6×2=12, 12×2=24. Chaque terme est le double du précédent."},
    {"cat": "Carrés Logiques", "enonce": "Tableau: [1,3,5] [7,9,?] [13,15,17]. Que vaut ?", "opts": {"A":"10","B":"11","C":"12","D":"13"}, "rep": "B", "exp": "Suite des nombres impairs: 1,3,5,7,9,11,13,15,17."},
    {"cat": "Carrés Logiques", "enonce": "Dans la grille: A=2, B=4, C=6, D=8. Que vaut A+C × B/D?", "opts": {"A":"4","B":"8","C":"16","D":"2"}, "rep": "A", "exp": "(A+C)×(B/D) = (2+6)×(4/8) = 8×0.5 = 4."},
    # === RAISONNEMENT SPATIAL ===
    {"cat": "Raisonnement Spatial", "enonce": "Un cube a combien de faces?", "opts": {"A":"4","B":"6","C":"8","D":"12"}, "rep": "B", "exp": "Un cube possède 6 faces carrées."},
    {"cat": "Raisonnement Spatial", "enonce": "Une pyramide à base carrée a combien de faces triangulaires?", "opts": {"A":"3","B":"4","C":"5","D":"6"}, "rep": "B", "exp": "Pyramide à base carrée = 4 faces triangulaires + 1 base carrée."},
    {"cat": "Raisonnement Spatial", "enonce": "Si on plie un carré en deux par la diagonale, on obtient:", "opts": {"A":"Un carré","B":"Un rectangle","C":"Un triangle isocèle rectangle","D":"Un losange"}, "rep": "C", "exp": "Le pli diagonal d'un carré donne deux triangles isocèles rectangles."},
    {"cat": "Raisonnement Spatial", "enonce": "Combien d'arêtes a un cube?", "opts": {"A":"8","B":"10","C":"12","D":"16"}, "rep": "C", "exp": "Un cube a 12 arêtes (4 en bas, 4 en haut, 4 verticales)."},
    {"cat": "Raisonnement Spatial", "enonce": "Un triangle équilatéral a tous ses angles égaux à:", "opts": {"A":"45°","B":"60°","C":"90°","D":"120°"}, "rep": "B", "exp": "Triangle équilatéral: 3 angles égaux, 180°/3=60° chacun."},
    {"cat": "Raisonnement Spatial", "enonce": "Combien de sommets a un octaèdre régulier?", "opts": {"A":"4","B":"6","C":"8","D":"12"}, "rep": "B", "exp": "Un octaèdre régulier a 6 sommets, 8 faces et 12 arêtes."},
    {"cat": "Raisonnement Spatial", "enonce": "Si on fait pivoter un L de 90° dans le sens horaire, quelle lettre obtient-on?", "opts": {"A":"J inversé","B":"Γ","C":"L","D":"F"}, "rep": "B", "exp": "La rotation de L de 90° horaire donne une forme ressemblant à Γ (lettre gamma)."},
    {"cat": "Raisonnement Spatial", "enonce": "Une sphère et un cercle : quelle est leur différence principale?", "opts": {"A":"La sphère est 3D, le cercle est 2D","B":"Le cercle est plus grand","C":"Ils sont identiques","D":"La sphère a des angles"}, "rep": "A", "exp": "Cercle = figure plane 2D; Sphère = solide 3D."},
    {"cat": "Raisonnement Spatial", "enonce": "Dans le miroir, si ma main droite est levée, quelle main l'image lève-t-elle?", "opts": {"A":"Droite","B":"Gauche","C":"Les deux","D":"Aucune"}, "rep": "B", "exp": "Un miroir inverse gauche/droite: si ma main droite est levée, l'image lève sa main gauche."},
    {"cat": "Raisonnement Spatial", "enonce": "Un cylindre a combien de faces circulaires?", "opts": {"A":"0","B":"1","C":"2","D":"3"}, "rep": "C", "exp": "Un cylindre a 2 faces circulaires (haut et bas) et une face latérale courbe."},
    {"cat": "Raisonnement Spatial", "enonce": "Si un carré de côté 4 est découpé en 4 carrés égaux, quel est le côté de chaque petit carré?", "opts": {"A":"1","B":"2","C":"3","D":"4"}, "rep": "B", "exp": "4/2=2 (on divise chaque côté en 2)."},
    # === CALCUL MENTAL ===
    {"cat": "Calcul Mental", "enonce": "15% de 200 = ?", "opts": {"A":"20","B":"25","C":"30","D":"35"}, "rep": "C", "exp": "15% de 200 = 200 × 0.15 = 30."},
    {"cat": "Calcul Mental", "enonce": "25 × 4 + 10 = ?", "opts": {"A":"100","B":"105","C":"110","D":"115"}, "rep": "C", "exp": "25×4=100, 100+10=110."},
    {"cat": "Calcul Mental", "enonce": "√144 = ?", "opts": {"A":"10","B":"11","C":"12","D":"14"}, "rep": "C", "exp": "12×12=144, donc √144=12."},
    {"cat": "Calcul Mental", "enonce": "3/4 de 120 = ?", "opts": {"A":"80","B":"90","C":"95","D":"100"}, "rep": "B", "exp": "120 × 3/4 = 90."},
    {"cat": "Calcul Mental", "enonce": "Si un article coûte 500 FCFA et est soldé à -20%, son nouveau prix est:", "opts": {"A":"350 FCFA","B":"400 FCFA","C":"420 FCFA","D":"450 FCFA"}, "rep": "B", "exp": "500 × 0.80 = 400 FCFA."},
    {"cat": "Calcul Mental", "enonce": "2³ + 3² = ?", "opts": {"A":"15","B":"17","C":"19","D":"21"}, "rep": "B", "exp": "2³=8, 3²=9, 8+9=17."},
    {"cat": "Calcul Mental", "enonce": "Si un travail prend 6h pour 2 personnes, combien de temps pour 3 personnes?", "opts": {"A":"3h","B":"4h","C":"5h","D":"9h"}, "rep": "B", "exp": "Travail total = 6×2=12 heures-homme. Pour 3 personnes: 12/3=4h."},
    {"cat": "Calcul Mental", "enonce": "PGCD de 12 et 18 = ?", "opts": {"A":"3","B":"4","C":"6","D":"9"}, "rep": "C", "exp": "Diviseurs de 12: 1,2,3,4,6,12. Diviseurs de 18: 1,2,3,6,9,18. PGCD=6."},
    {"cat": "Calcul Mental", "enonce": "1/3 + 1/6 = ?", "opts": {"A":"2/9","B":"1/2","C":"2/6","D":"1/4"}, "rep": "B", "exp": "1/3 = 2/6. 2/6 + 1/6 = 3/6 = 1/2."},
    {"cat": "Calcul Mental", "enonce": "Si le périmètre d'un carré est 28 cm, quelle est l'aire?", "opts": {"A":"42 cm²","B":"49 cm²","C":"56 cm²","D":"64 cm²"}, "rep": "B", "exp": "Côté = 28/4 = 7 cm. Aire = 7² = 49 cm²."},
    {"cat": "Calcul Mental", "enonce": "(-3)² = ?", "opts": {"A":"-9","B":"-6","C":"6","D":"9"}, "rep": "D", "exp": "(-3)² = (-3) × (-3) = 9 (produit de deux négatifs = positif)."},
    {"cat": "Calcul Mental", "enonce": "Si un train parcourt 300 km en 3h, sa vitesse moyenne est:", "opts": {"A":"90 km/h","B":"100 km/h","C":"110 km/h","D":"120 km/h"}, "rep": "B", "exp": "v = d/t = 300/3 = 100 km/h."},
    # === ANALOGIES ===
    {"cat": "Analogies", "enonce": "Oiseau est à Nid comme Abeille est à...", "opts": {"A":"Miel","B":"Ruche","C":"Fleur","D":"Piqûre"}, "rep": "B", "exp": "L'oiseau habite le nid, l'abeille habite la ruche."},
    {"cat": "Analogies", "enonce": "Stylo est à Écrire comme Couteau est à...", "opts": {"A":"Blesser","B":"Cuisine","C":"Couper","D":"Métal"}, "rep": "C", "exp": "Le stylo sert à écrire, le couteau sert à couper."},
    {"cat": "Analogies", "enonce": "Nuit est à Jour comme Froid est à...", "opts": {"A":"Hiver","B":"Chaud","C":"Glace","D":"Manteau"}, "rep": "B", "exp": "Antonymes: nuit↔jour, froid↔chaud."},
    {"cat": "Analogies", "enonce": "Médecin est à Hôpital comme Professeur est à...", "opts": {"A":"Livre","B":"Élève","C":"École","D":"Craie"}, "rep": "C", "exp": "Lieu de travail: médecin→hôpital, professeur→école."},
    {"cat": "Analogies", "enonce": "Eau est à Soif comme Nourriture est à...", "opts": {"A":"Gourmandise","B":"Faim","C":"Digestion","D":"Repas"}, "rep": "B", "exp": "L'eau étanche la soif, la nourriture apaise la faim."},
    {"cat": "Analogies", "enonce": "Kilomètre est à Distance comme Kilogramme est à...", "opts": {"A":"Volume","B":"Temps","C":"Masse","D":"Vitesse"}, "rep": "C", "exp": "Unités de mesure: km mesure la distance, kg mesure la masse."},
    {"cat": "Analogies", "enonce": "France est à Paris comme Sénégal est à...", "opts": {"A":"Abidjan","B":"Dakar","C":"Bamako","D":"Niamey"}, "rep": "B", "exp": "Pays→Capitale: France→Paris, Sénégal→Dakar."},
    {"cat": "Analogies", "enonce": "Arbre est à Forêt comme Grain est à...", "opts": {"A":"Silo","B":"Blé","C":"Champ","D":"Moisson"}, "rep": "C", "exp": "Collection: les arbres forment une forêt, les grains forment un champ."},
    {"cat": "Analogies", "enonce": "Lire est à Yeux comme Écouter est à...", "opts": {"A":"Radio","B":"Musique","C":"Oreilles","D":"Cerveau"}, "rep": "C", "exp": "Organe sensoriel: on lit avec les yeux, on écoute avec les oreilles."},
    {"cat": "Analogies", "enonce": "Cheval est à Écurie comme Voiture est à...", "opts": {"A":"Route","B":"Garage","C":"Station","D":"Essence"}, "rep": "B", "exp": "Lieu d'hébergement: cheval→écurie, voiture→garage."},
    # === DÉDUCTION ===
    {"cat": "Déduction", "enonce": "Tous les étudiants de cette école viennent à vélo. Moussa est étudiant dans cette école. Moussa vient donc...", "opts": {"A":"En voiture","B":"À pied","C":"À vélo","D":"En bus"}, "rep": "C", "exp": "Déduction directe: Moussa est dans l'école + tous viennent à vélo → Moussa vient à vélo."},
    {"cat": "Déduction", "enonce": "Il fait beau quand il n'y a pas de nuages. Aujourd'hui il y a des nuages. Donc...", "opts": {"A":"Il fait beau","B":"Il ne fait pas beau","C":"Il va pleuvoir","D":"On ne peut pas conclure"}, "rep": "B", "exp": "Modus tollens: pas beau → nuages. Nuages → pas beau (contraposée directe)."},
    {"cat": "Déduction", "enonce": "Si A>B et B>C, alors A et C ont quelle relation?", "opts": {"A":"A=C","B":"A<C","C":"A>C","D":"On ne sait pas"}, "rep": "C", "exp": "Transitivité: A>B>C implique A>C."},
    {"cat": "Déduction", "enonce": "On a 5 boites numérotées 1 à 5. Le lot est dans une boite impaire. Il n'est pas dans la boite 3. Il est dans une boite < 4. Où est le lot?", "opts": {"A":"Boite 1","B":"Boite 2","C":"Boite 3","D":"Boite 5"}, "rep": "A", "exp": "Impaires: 1,3,5. Pas 3. Moins de 4: donc 1. → Boite 1."},
    {"cat": "Déduction", "enonce": "Dans un village, tout le monde se connaît. Ama connaît Brice. Brice connaît Chidi. Ama connaît-il Chidi?", "opts": {"A":"Oui, forcément","B":"Non","C":"Peut-être","D":"Impossible"}, "rep": "A", "exp": "Si tout le monde se connaît dans le village, Ama connaît forcément Chidi."},
    {"cat": "Déduction", "enonce": "Il y a 3 suspects. L'un est innocent, deux sont coupables. Le suspect A dit: 'B est innocent'. Le suspect B dit: 'C est coupable'. Si A dit la vérité...", "opts": {"A":"B est coupable","B":"B est innocent et C est coupable","C":"C est innocent","D":"A est coupable"}, "rep": "B", "exp": "Si A dit la vérité → B innocent. Alors les coupables sont A et C. B (innocent) dit: C coupable → vrai."},
    {"cat": "Déduction", "enonce": "Tout nombre pair est divisible par 2. 14 est divisible par 2. Donc 14 est...", "opts": {"A":"Impair","B":"Premier","C":"Pair","D":"Multiple de 7 seulement"}, "rep": "C", "exp": "Par définition: tout nombre divisible par 2 est pair."},
    {"cat": "Déduction", "enonce": "Dans un sac: 3 boules rouges, 2 bleues. On tire une boule. La probabilité qu'elle soit rouge est:", "opts": {"A":"1/2","B":"3/5","C":"2/5","D":"1/3"}, "rep": "B", "exp": "P(rouge) = 3/(3+2) = 3/5."},
    {"cat": "Déduction", "enonce": "Un rectangle a une longueur double de sa largeur. Son périmètre est 36 cm. Quelle est sa largeur?", "opts": {"A":"6 cm","B":"9 cm","C":"12 cm","D":"18 cm"}, "rep": "A", "exp": "L=2l. Périmètre=2(L+l)=2(2l+l)=6l=36. l=6 cm."},
    {"cat": "Déduction", "enonce": "Si 5 stylos coûtent 2500 FCFA, combien coûtent 8 stylos?", "opts": {"A":"3500 FCFA","B":"4000 FCFA","C":"3000 FCFA","D":"3200 FCFA"}, "rep": "B", "exp": "Prix unitaire = 2500/5=500 FCFA. 8×500=4000 FCFA."},
]


def step4_psycho(start_numero):
    print("\n" + "="*60)
    print("🧠 STEP 4 : PSYCHOTECHNIQUE (QCM Banque)")
    print("="*60)
    
    # Récupérer les questions existantes dans PSY pour éviter les doublons
    existing = api_get("questions", f"?select=enonce&matiere_id=eq.{MATIERE_PSY_ID}&limit=2000")
    existing_keys = set()
    for q in existing:
        key = ' '.join(str(q.get('enonce', '')).lower().split())[:200]
        existing_keys.add(key)
    
    print(f"  Questions PSY déjà en BDD: {len(existing_keys)}")
    
    # Filtrer les nouvelles questions
    new_q = []
    seen_new = set()
    for q in PSYCHO_QCM_BANK:
        key = ' '.join(q['enonce'].lower().split())[:200]
        if key not in existing_keys and key not in seen_new:
            new_q.append(q)
            seen_new.add(key)
    
    print(f"  Nouvelles questions à insérer: {len(new_q)}")
    
    if not new_q:
        print("  ✅ Rien à insérer")
        return 0, 0, start_numero
    
    # Organiser par catégorie → séries
    cats = list(dict.fromkeys(q['cat'] for q in new_q))
    
    # Chercher dernière série PSY
    existing_series = api_get("series_qcm", f"?select=numero&matiere_id=eq.{MATIERE_PSY_ID}&order=numero.desc&limit=1")
    next_num = 1
    if existing_series:
        next_num = existing_series[0]['numero'] + 1
    
    series_created = {}
    print(f"\n  Création de {len(cats)} séries thématiques PSY...")
    
    for cat in cats:
        cat_q = [q for q in new_q if q['cat'] == cat]
        serie_data = {
            "id": str(uuid.uuid4()),
            "matiere_id": MATIERE_PSY_ID,
            "titre": f"Série {next_num:02d} — {cat[:40]}",
            "numero": next_num,
            "niveau": "INTERMEDIAIRE",
            "duree_minutes": 20,
            "nb_questions": len(cat_q),
            "est_demo": False,
            "actif": True,
            "published": True,
        }
        result = api("POST", "series_qcm", data=serie_data)
        if result is not None:
            series_created[cat] = serie_data['id']
            print(f"    ✅ Série {next_num:02d}: {cat} ({len(cat_q)} questions)")
            next_num += 1
        time.sleep(0.2)
    
    # Insérer les questions
    questions_db = []
    current_num = start_numero
    cat_counters = {}
    
    for q in new_q:
        cat = q['cat']
        serie_id = series_created.get(cat)
        opts = q['opts']
        
        cat_counters[cat] = cat_counters.get(cat, 0) + 1
        
        questions_db.append({
            "id": str(uuid.uuid4()),
            "matiere_id": MATIERE_PSY_ID,
            "serie_id": serie_id,
            "numero": current_num,
            "enonce": q['enonce'],
            "type": "QCM",
            "option_a": opts.get('A', ''),
            "option_b": opts.get('B', ''),
            "option_c": opts.get('C', ''),
            "option_d": opts.get('D', ''),
            "option_e": opts.get('E', None),
            "bonne_reponse": q['rep'],
            "explication": q.get('exp', ''),
            "difficulte": "MOYEN",
            "published": True,
            "version": 1,
            "tags": [cat],
            "numero_serie": cat_counters[cat],
        })
        current_num += 1
    
    # Insérer en batch
    print(f"\n  Insertion de {len(questions_db)} questions PSY...")
    inserted = 0
    for i in range(0, len(questions_db), 20):
        batch = questions_db[i:i+20]
        result = api("POST", "questions", data=batch)
        if result is not None:
            inserted += len(batch)
            print(f"    📤 Lot {i//20+1}: {min(i+20, len(questions_db))}/{len(questions_db)}")
        time.sleep(0.3)
    
    # Aussi: assigner les questions PSY existantes sans série à la série 1
    print("\n  Attribution des questions PSY sans série...")
    q_no_serie = api_get("questions", 
                          f"?select=id&matiere_id=eq.{MATIERE_PSY_ID}&serie_id=is.null&limit=500")
    
    if q_no_serie and series_created:
        first_serie = list(series_created.values())[0]
        batch_ids = [q['id'] for q in q_no_serie]
        for i in range(0, len(batch_ids), 20):
            chunk = batch_ids[i:i+20]
            ids_csv = ",".join(chunk)
            api("PATCH", f"questions?id=in.({ids_csv})", 
                data={"serie_id": first_serie})
            time.sleep(0.1)
        print(f"    ✅ {len(batch_ids)} questions attribuées à la série existante")
    
    print(f"\n  ✅ PSY: {inserted} questions insérées, {len(series_created)} séries créées")
    return inserted, len(series_created), current_num


# ================================================================
# STEP 5 : MISE À JOUR DES COMPTEURS
# ================================================================

def step5_update_counters():
    print("\n" + "="*60)
    print("📊 STEP 5 : MISE À JOUR DES COMPTEURS")
    print("="*60)
    
    # Récupérer toutes les séries actives
    all_series = api_get("series_qcm", "?select=id,matiere_id,numero&actif=eq.true&limit=500")
    all_questions = api_get("questions", "?select=id,serie_id,matiere_id&published=eq.true&limit=10000")
    
    q_by_serie = Counter(q.get('serie_id') for q in all_questions if q.get('serie_id'))
    
    updated = 0
    for serie in all_series:
        nb_real = q_by_serie.get(serie['id'], 0)
        result = api("PATCH", f"series_qcm?id=eq.{serie['id']}", 
                     data={"nb_questions": nb_real})
        if result is not None:
            updated += 1
        time.sleep(0.05)
    
    print(f"  ✅ {updated} séries mises à jour")
    
    # Résumé final par matière
    print("\n=== RÉSUMÉ FINAL ===")
    matieres = api_get("matieres", "?select=id,code,nom&order=nom.asc")
    id_to_code = {m['id']: m['code'] for m in matieres}
    
    q_by_mat = Counter(q.get('matiere_id') for q in all_questions)
    series_by_mat = Counter(s.get('matiere_id') for s in all_series)
    
    for m in matieres:
        nb_q = q_by_mat.get(m['id'], 0)
        nb_s = series_by_mat.get(m['id'], 0)
        if nb_q > 0 or nb_s > 0:
            print(f"  [{m['code']:8}] {m['nom'][:30]:30} | {nb_q:4} questions | {nb_s:3} séries")
    
    return updated


# ================================================================
# MAIN
# ================================================================

def main():
    print("=" * 60)
    print("🚀 EF-FORT.BF — IMPORT MAÎTRE")
    print("=" * 60)
    print("Fichiers source:")
    print("  - Force Armée: /home/user/uploaded_files/force armée nationale.md")
    print("  - Actualité:   /home/user/uploaded_files/actualité internationale.md")
    print("  - Psycho PDF:  (intégré dans le script)")
    
    # Numéro de départ global
    start = 2000  # Après les questions existantes
    
    try:
        # Step 1: Nettoyage
        cleanup_stats = step1_cleanup()
        
        # Parsers
        print("\n⚙️  Parsing des fichiers...")
        q_armee = parse_force_armee("/home/user/uploaded_files/force armée nationale.md")
        q_actu = parse_actualite("/home/user/uploaded_files/actualité internationale.md")
        print(f"  Force Armée: {len(q_armee)} questions uniques")
        print(f"  Actualité:   {len(q_actu)} questions uniques")
        print(f"  Psycho Bank: {len(PSYCHO_QCM_BANK)} questions dans la banque")
        
        # Step 2: Force Armée
        ins_armee, ser_armee, start = step2_force_armee(q_armee, start)
        
        # Step 3: Actualité
        ins_actu, ser_actu, start = step3_actualite(q_actu, start)
        
        # Step 4: Psychotechnique
        ins_psy, ser_psy, start = step4_psycho(start)
        
        # Step 5: Mise à jour compteurs
        step5_update_counters()
        
        # Résumé
        print("\n" + "="*60)
        print("🎉 IMPORT TERMINÉ AVEC SUCCÈS!")
        print("="*60)
        print(f"  Force Armée:   {ins_armee} questions + {ser_armee} séries")
        print(f"  Actualité:     {ins_actu} questions + {ser_actu} séries")
        print(f"  Psycho:        {ins_psy} questions + {ser_psy} séries")
        print(f"  Nettoyage:     {cleanup_stats['ghost_deleted']} séries fantômes supprimées")
        print(f"  PSY fusionnées: {cleanup_stats['psy_migrated']} questions migrées")
        print("="*60)
        
    except Exception as e:
        print(f"\n❌ ERREUR CRITIQUE: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
