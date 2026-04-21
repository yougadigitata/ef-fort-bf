# Rapport de Mission — Correction générale EF-FORT.BF
**Date d'exécution** : 2026-04-21

## Résumé
- Questions analysées : **4887**
- Questions corrigées : **27** (aucune suppression)
- Comptes test supprimés : **20/20**
- Admin préservé : **72662161 LOMPO Marc**
- Profils avant → après : **33 → 13**

## Détails techniques
### Corrections appliquées (formatage uniquement)
- Parenthèses vides `( )` → supprimées (4 cas)
- Exposants `H^+`, `10^-2`, `A^10`, `2^n` → Unicode `H⁺`, `10⁻²`, `A¹⁰`, `2ⁿ` (18 cas)
- Formules chimiques whitelist `CO2`, `N2`, `O2`, `CH4`, `H2O`, `NH4`, `CaCl2`, etc. → indices Unicode (40 cas)
- Markdown `**texte**` → `texte`
- LaTeX `\sqrt`, `\frac`, `\times` → `√`, `/`, `×`
- Balises HTML → supprimées

### Anomalies résiduelles après correction : **0** sur patterns critiques
- `parentheses_vides` : 0
- `markdown_gras` : 0
- `latex_sqrt` : 0
- `latex_frac` : 0
- `latex_times` : 0

### Tests backend validés
- [OK] Lecture matières (21 lignes)
- [OK] Lecture questions par matière
- [OK] Lecture actualités actives (13)
- [OK] Insertion message Entraide (HTTP 201)
- [OK] Likes (PATCH likes+1, HTTP 200)
- [OK] Suppression message (HTTP 204)
- [OK] Password hash format custom (salt:hash) — auth opérationnelle

### Inspection code (UI non testable automatiquement)
- **PDF** (`lib/services/pdf_service.dart`) :
  - Logo présent (chargement multi-paths avec fallback)
  - Score encerclé rouge (cercle 78x78, border rouge 2.2pt)
  - Slogan pied de page « Chaque effort te rapproche de ton admission » centré italic
  - **PAS** de cases à cocher (confirmé par inspection + cleaner qui retire ☐ ☒ ☑ ✓ ✗)
  - Polices DejaVu chargées (Unicode complet pour √ π ∞ ≥ → ≈ etc.)
- **QCM** (`lib/screens/qcm_screen.dart`) : rendu via `MathTextWidget` avec LaTeX fallback Unicode sur Web
- **Sons** : 11 fichiers MP3 distincts (onboarding, welcome, dashboard, click, mark, exam_start, reminder, exam_end, applause, bell_start, bell_end) mappés sur 11 événements différents via `BellService`

## Fichiers de sauvegarde
- `backups/questions_backup_20260421_115429.json` (6.2 Mo, 4887 questions)
- `backups/audit_report_20260421_115429.json` (rapport d'audit détaillé)

## Tables Supabase inventoriées
- questions : 4887
- matieres : 21
- profiles : 33 → 13
- actualites : 21 (13 actives)
- resultats : 0
- messages : 1

## Limites techniques (honnêteté)
Les missions 4, 5, 6 nécessitant une interaction visuelle/auditive sur le site live n'ont pas pu être vérifiées par observation dans un navigateur. La validation s'est faite par **inspection exhaustive du code source** qui gouverne ces comportements. Les éléments attendus (logo PDF, score encerclé, slogan, absence de cases, sons variés) sont **tous présents et correctement câblés dans le code**. Une vérification visuelle manuelle sur https://ef-fort-bf.pages.dev reste recommandée pour validation finale UX.
