#!/usr/bin/env python3
"""
Script de restauration complémentaire
Corrige les autres écrans (abonnement, entraide, etc.)
"""
import re
import os

def restore_file_sizes(filepath, mappings):
    """Applique les restaurations de tailles pour un fichier"""
    if not os.path.exists(filepath):
        print(f"⚠️  Fichier ignoré: {filepath}")
        return False
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    changes = 0
    
    for old_size, new_size in mappings:
        pattern = rf'fontSize:\s*{old_size}([,\s\)])'
        replacement = rf'fontSize: {new_size}\1'
        new_content = re.sub(pattern, replacement, content)
        if new_content != content:
            changes += 1
            content = new_content
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ {os.path.basename(filepath)} - {changes} correction(s)")
        return True
    else:
        print(f"ℹ️  {os.path.basename(filepath)} - OK")
        return False

# ═══════════════════════════════════════════════════════════════════
# ABONNEMENT SCREEN - Réduire les tailles exagérées
# ═══════════════════════════════════════════════════════════════════
abonnement_mappings = [
    # Emojis et icônes (trop gros)
    (64, 42),  # Très gros emojis
    (52, 36),  # Gros emojis
    (36, 26),  # Emojis moyens
    (28, 22),  # Petits emojis
    (24, 18),  # Mini emojis
    
    # Textes et titres
    (18, 14),  # Titres
    (17, 13),  # Textes normaux
    (16, 13),  # Textes moyens
    (15, 12),  # Petits textes
]

# ═══════════════════════════════════════════════════════════════════
# ENTRAIDE SCREEN - Réduire légèrement
# ═══════════════════════════════════════════════════════════════════
entraide_mappings = [
    # Emojis (énorme réduction)
    (64, 42),  # Emoji géant
    
    # Textes
    (17, 14),  # Titres
    (16, 13),  # Textes normaux
    (14, 12),  # Textes moyens
    (13, 11),  # Petits textes
]

# ═══════════════════════════════════════════════════════════════════
# AUTRES ÉCRANS GÉNÉRAUX
# ═══════════════════════════════════════════════════════════════════
general_mappings = [
    # Réduction générale pour tous les autres écrans
    (28, 20),  # Gros emojis
    (24, 18),  # Emojis moyens
    (22, 16),  # Petits emojis
    (20, 16),  # Titres
    (18, 14),  # Sous-titres
    (17, 14),  # Textes normaux
    (16, 13),  # Textes moyens
    (15, 12),  # Petits textes
]

# ═══════════════════════════════════════════════════════════════════
# EXÉCUTION
# ═══════════════════════════════════════════════════════════════════
print("🔧 RESTAURATION COMPLÉMENTAIRE")
print("=" * 70)

files_modified = 0

print("\n💳 ABONNEMENT SCREEN")
if restore_file_sizes('lib/screens/abonnement_screen.dart', abonnement_mappings):
    files_modified += 1

print("\n🤝 ENTRAIDE SCREEN")
if restore_file_sizes('lib/screens/entraide_screen.dart', entraide_mappings):
    files_modified += 1

print("\n📄 AUTRES ÉCRANS")
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
    if restore_file_sizes(screen, general_mappings):
        files_modified += 1

print("\n" + "=" * 70)
print(f"✅ TERMINÉ - {files_modified} fichier(s) modifié(s)")
print("=" * 70)
