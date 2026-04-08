#!/usr/bin/env python3
"""
Script de restauration des tailles normales
Restaure les tailles de police SAUF pour :
- QCM (affichage des questions, options)
- PDF (impressions)
- Simulations examens (feuille de questions, feuille de réponse)
- Matières et séries (déjà bien)
"""
import re
import os

def restore_file_sizes(filepath, mappings):
    """Applique les restaurations de tailles pour un fichier"""
    if not os.path.exists(filepath):
        print(f"⚠️  Fichier ignoré (introuvable): {filepath}")
        return False
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    changes = 0
    
    for old_size, new_size in mappings:
        # Pattern pour capturer fontSize: X avec gestion des espaces
        pattern = rf'fontSize:\s*{old_size}([,\s\)])'
        replacement = rf'fontSize: {new_size}\1'
        new_content = re.sub(pattern, replacement, content)
        if new_content != content:
            changes += 1
            content = new_content
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ {filepath} - {changes} correction(s)")
        return True
    else:
        print(f"ℹ️  {filepath} - Aucune modification")
        return False

# ═══════════════════════════════════════════════════════════════════
# DASHBOARD SCREEN - Restauration des tailles normales
# ═══════════════════════════════════════════════════════════════════
dashboard_mappings = [
    # Titres principaux et sections
    (20, 16),  # Titres de sections
    (22, 16),  # Grands titres
    
    # Textes généraux
    (17, 14),  # Textes normaux
    (15, 13),  # Sous-textes
    
    # Petits textes et labels
    (13, 11),  # Labels
    (11, 9),   # Très petits textes
    (9, 8),    # Mini textes
    
    # Chiffres statistiques (légèrement réduits)
    (34, 24),  # Gros chiffres stats
    (30, 22),  # Chiffres moyens
    
    # Emojis (légèrement réduits)
    (38, 28),  # Grands emojis
    (26, 20),  # Emojis moyens
    (24, 18),  # Petits emojis
]

# ═══════════════════════════════════════════════════════════════════
# PROFIL SCREEN - Restauration complète
# ═══════════════════════════════════════════════════════════════════
profil_mappings = [
    # Header et titres principaux
    (36, 24),  # Emojis header
    (30, 22),  # Chiffres stats
    (28, 20),  # Emojis moyens
    (24, 18),  # Petits emojis/chiffres
    (22, 16),  # Titres
    
    # Textes généraux
    (20, 14),  # Titres sections
    (18, 14),  # Sous-titres
    (17, 13),  # Textes normaux
    (16, 13),  # Textes moyens
    (15, 12),  # Petits textes
    
    # Emojis et icônes
    (44, 32),  # Très gros emojis
    (38, 28),  # Grands emojis
]

# ═══════════════════════════════════════════════════════════════════
# ADMIN SCREEN - Restauration subtile (déjà corrigé mais on vérifie)
# ═══════════════════════════════════════════════════════════════════
admin_mappings = [
    # Titres et sections (léger ajustement)
    (18, 14),  # Titres sections
    (17, 13),  # Textes normaux
    (16, 13),  # Textes moyens
    
    # Tableaux et données
    (14, 12),  # Textes tableaux
    (13, 11),  # Labels
]

# ═══════════════════════════════════════════════════════════════════
# HOME SCREEN - Restauration navigation et interface
# ═══════════════════════════════════════════════════════════════════
home_mappings = [
    # Navigation icons
    (27, 20),  # Icônes actives
    (26, 20),  # Emojis dialogs
    (22, 18),  # Icônes inactives
    
    # Textes dialogs et boutons
    (17, 14),  # Titres dialogs
    (14, 12),  # Textes normaux
    (12, 10),  # Petits textes
    (10, 8),   # Labels navigation
]

# ═══════════════════════════════════════════════════════════════════
# EXÉCUTION DES RESTAURATIONS
# ═══════════════════════════════════════════════════════════════════
print("🔧 RESTAURATION DES TAILLES NORMALES")
print("=" * 70)
print("📌 Conservation des agrandissements pour :")
print("   ✅ QCM (questions, options)")
print("   ✅ PDF (impressions)")
print("   ✅ Simulations examens")
print("   ✅ Matières et séries")
print("=" * 70)

files_modified = 0

print("\n📱 DASHBOARD SCREEN")
if restore_file_sizes('lib/screens/dashboard_screen.dart', dashboard_mappings):
    files_modified += 1

print("\n👤 PROFIL SCREEN")
if restore_file_sizes('lib/screens/profil_screen.dart', profil_mappings):
    files_modified += 1

print("\n🔐 ADMIN SCREEN")
if restore_file_sizes('lib/screens/admin_screen.dart', admin_mappings):
    files_modified += 1

print("\n🏠 HOME SCREEN")
if restore_file_sizes('lib/screens/home_screen.dart', home_mappings):
    files_modified += 1

print("\n" + "=" * 70)
print(f"✅ TERMINÉ - {files_modified} fichier(s) modifié(s)")
print("=" * 70)
print("\n🔍 Fichiers NON touchés (comme demandé) :")
print("   • lib/screens/questions_screen.dart (QCM)")
print("   • lib/screens/simulation_*.dart (Simulations)")
print("   • lib/screens/matieres_screen.dart (Matières)")
print("   • lib/screens/series_*.dart (Séries)")
print("   • lib/services/pdf_*.dart (PDF)")
