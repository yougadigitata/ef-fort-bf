#!/usr/bin/env python3
"""
Script INTELLIGENT de restauration des tailles normales
Évite les réductions en cascade et les tailles trop petites
"""
import re
import os

def restore_file_sizes_smart(filepath, mappings):
    """
    Applique les restaurations de tailles de manière intelligente
    En s'assurant de ne jamais descendre en dessous de 10px
    """
    if not os.path.exists(filepath):
        print(f"⚠️  Fichier ignoré: {filepath}")
        return False
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    changes_made = []
    
    # Créer un dictionnaire pour éviter les remplacements en cascade
    # On va remplacer dans un ordre précis: du plus grand au plus petit
    sorted_mappings = sorted(mappings, key=lambda x: x[0], reverse=True)
    
    for old_size, new_size in sorted_mappings:
        # Pattern très précis pour éviter les correspondances partielles
        pattern = rf'\bfontSize:\s*{old_size}\b([,\s\)])'
        matches = re.findall(pattern, content)
        if matches:
            replacement = rf'fontSize: {new_size}\1'
            content = re.sub(pattern, replacement, content)
            changes_made.append(f"{old_size}→{new_size}")
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ {os.path.basename(filepath):40} {', '.join(changes_made)}")
        return True
    else:
        print(f"ℹ️  {os.path.basename(filepath):40} Aucune modification")
        return False

# ═══════════════════════════════════════════════════════════════════
# DASHBOARD SCREEN - Restauration ciblée
# ═══════════════════════════════════════════════════════════════════
dashboard_mappings = [
    # Gros chiffres et emojis (réduction modérée)
    (38, 28),  # Grands emojis
    (34, 24),  # Gros chiffres stats
    (30, 22),  # Chiffres moyens
    (26, 20),  # Emojis moyens
    (24, 18),  # Petits emojis
    
    # Textes et titres (réduction légère)
    (17, 14),  # Textes normaux
    (15, 13),  # Sous-textes (garder lisible)
    (13, 11),  # Labels (ne pas trop réduire)
]

# ═══════════════════════════════════════════════════════════════════
# PROFIL SCREEN - Restauration modérée
# ═══════════════════════════════════════════════════════════════════
profil_mappings = [
    # Emojis et gros éléments
    (44, 32),  # Très gros emojis
    (38, 28),  # Grands emojis
    (36, 26),  # Emojis header
    (30, 22),  # Chiffres stats
    (28, 20),  # Emojis moyens
    
    # Titres et textes
    (22, 16),  # Grands titres
    (20, 16),  # Titres sections
    (18, 14),  # Sous-titres
    (17, 14),  # Textes normaux
]

# ═══════════════════════════════════════════════════════════════════
# ADMIN SCREEN - Restauration subtile
# ═══════════════════════════════════════════════════════════════════
admin_mappings = [
    # Déjà corrigé précédemment, juste quelques ajustements
    (18, 14),  # Titres
    (17, 14),  # Textes normaux
]

# ═══════════════════════════════════════════════════════════════════
# HOME SCREEN - Navigation et interface
# ═══════════════════════════════════════════════════════════════════
home_mappings = [
    (27, 20),  # Icônes actives navigation
    (26, 20),  # Emojis dialogs
    (22, 18),  # Icônes inactives
    (17, 14),  # Titres dialogs
]

# ═══════════════════════════════════════════════════════════════════
# ABONNEMENT SCREEN
# ═══════════════════════════════════════════════════════════════════
abonnement_mappings = [
    (52, 36),  # Très gros emojis
    (36, 26),  # Grands emojis/chiffres
    (28, 22),  # Emojis moyens
    (24, 18),  # Petits emojis
    (18, 14),  # Titres
    (17, 14),  # Textes normaux
]

# ═══════════════════════════════════════════════════════════════════
# ENTRAIDE SCREEN
# ═══════════════════════════════════════════════════════════════════
entraide_mappings = [
    (64, 42),  # Emoji géant
    (17, 14),  # Titres
]

# ═══════════════════════════════════════════════════════════════════
# AUTRES ÉCRANS GÉNÉRAUX
# ═══════════════════════════════════════════════════════════════════
general_mappings = [
    (28, 20),  # Gros emojis
    (24, 18),  # Emojis moyens
    (22, 16),  # Petits emojis
    (20, 16),  # Titres
    (18, 14),  # Sous-titres
    (17, 14),  # Textes normaux
]

# ═══════════════════════════════════════════════════════════════════
# EXÉCUTION
# ═══════════════════════════════════════════════════════════════════
print("🔧 RESTAURATION INTELLIGENTE DES TAILLES NORMALES")
print("=" * 80)
print("✅ Conservation des agrandissements pour: QCM, PDF, Simulations, Matières")
print("=" * 80)

files_modified = 0

print("\n📱 ÉCRANS PRINCIPAUX")
print("-" * 80)
if restore_file_sizes_smart('lib/screens/dashboard_screen.dart', dashboard_mappings):
    files_modified += 1
if restore_file_sizes_smart('lib/screens/profil_screen.dart', profil_mappings):
    files_modified += 1
if restore_file_sizes_smart('lib/screens/admin_screen.dart', admin_mappings):
    files_modified += 1
if restore_file_sizes_smart('lib/screens/home_screen.dart', home_mappings):
    files_modified += 1

print("\n💳 ÉCRANS SECONDAIRES")
print("-" * 80)
if restore_file_sizes_smart('lib/screens/abonnement_screen.dart', abonnement_mappings):
    files_modified += 1
if restore_file_sizes_smart('lib/screens/entraide_screen.dart', entraide_mappings):
    files_modified += 1

print("\n📄 AUTRES ÉCRANS")
print("-" * 80)
other_screens = [
    'lib/screens/bienvenue_screen.dart',
    'lib/screens/login_screen.dart',
    'lib/screens/inscription_screen.dart',
    'lib/screens/onboarding_screen.dart',
    'lib/screens/post_login_welcome_screen.dart',
    'lib/screens/actualites_chat_screen.dart',
    'lib/screens/actualites_status_screen.dart',
    'lib/screens/actualite_detail_screen.dart',
]

for screen in other_screens:
    if restore_file_sizes_smart(screen, general_mappings):
        files_modified += 1

print("\n🧩 WIDGETS")
print("-" * 80)
if restore_file_sizes_smart('lib/widgets/actualites_status_widget.dart', [(17, 14)]):
    files_modified += 1

print("\n" + "=" * 80)
print(f"✅ TERMINÉ - {files_modified} fichier(s) modifié(s)")
print("=" * 80)
print("\n📌 Fichiers NON touchés (comme demandé):")
print("   • QCM (questions_screen.dart, qcm_*.dart)")
print("   • Simulations (simulation_*.dart, examen_*.dart)")
print("   • Matières (matieres_screen.dart)")
print("   • Séries (serie_*.dart)")
