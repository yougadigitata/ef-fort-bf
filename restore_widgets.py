#!/usr/bin/env python3
"""
Script de restauration des widgets
"""
import re
import os

def restore_file_sizes(filepath, mappings):
    if not os.path.exists(filepath):
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

# Widgets actualités
widget_mappings = [
    (17, 14),  # Réduire légèrement
]

print("🧩 RESTAURATION DES WIDGETS")
print("=" * 70)

files_modified = 0

if restore_file_sizes('lib/widgets/actualites_status_widget.dart', widget_mappings):
    files_modified += 1

print("\n" + "=" * 70)
print(f"✅ TERMINÉ - {files_modified} widget(s) modifié(s)")
print("=" * 70)
