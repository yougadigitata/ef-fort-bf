#!/usr/bin/env python3
import re

# Lire le fichier
with open('lib/screens/admin_screen.dart', 'r') as f:
    content = f.read()

# Remplacer fontSize: 17 par fontSize: 13 (textes normaux)
content = re.sub(r'fontSize:\s*17([,\s])', r'fontSize: 13\1', content)

# Remplacer fontSize: 18 par fontSize: 14 (titres)
content = re.sub(r'fontSize:\s*18([,\s])', r'fontSize: 14\1', content)

# Remplacer fontSize: 20 par fontSize: 16 (gros titres)
content = re.sub(r'fontSize:\s*20([,\s])', r'fontSize: 16\1', content)

# Remplacer fontSize: 22 par fontSize: 16 (titres de sections)
content = re.sub(r'fontSize:\s*22([,\s])', r'fontSize: 16\1', content)

# Remplacer fontSize: 24 par fontSize: 18 (chiffres stat)
content = re.sub(r'fontSize:\s*24([,\s])', r'fontSize: 18\1', content)

# Écrire le fichier
with open('lib/screens/admin_screen.dart', 'w') as f:
    f.write(content)

print("✅ Tailles de police corrigées!")
