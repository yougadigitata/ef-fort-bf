# CHANGELOG — Insertion 5 séries (50 questions) dans Examens Types + Nettoyage

## Date : 2025-04-04

## Résumé des modifications

### Étape 1 — Nettoyage
- Suppression de toutes les anciennes simulations_examens (IDs 14-25, 12 entrées)
- Table simulations_examens complètement vidée avant insertion des nouvelles données

### Étape 2 — Insertion des 5 nouvelles séries

| Série | Thème | Matière dans Examens Types | ID simulation |
|-------|-------|--------------------------|---------------|
| Série 1 | Histoire-Géographie du Burkina Faso | Agriculture & environnement | 32 |
| Série 2 | Sciences & Culture Générale | Concours de la santé | 33 |
| Série 3 | Géopolitique & Organisations Internationales | Justice & sécurité | 34 |
| Série 4 | Institutions & Littérature | Administration générale | 35 |
| Série 5 | Orthographe & Culture Diversifiée | Éducation & formation | 36 |

### Données insérées
- **5 simulations_examens** publiées (published=true)
- **250 questions** (50 par série, numérotées 1-50 dans chaque série)
- **Explications détaillées** incluses pour chaque question
- **Options A, B, C, D** avec bonne réponse identifiée
- Durée : 90 minutes par série
- Correction complète disponible après soumission

### Structure technique
- Table `simulations_examens` : 5 entrées avec question_ids
- Table `series_qcm` : 5 nouvelles séries créées
- Table `questions` : 250 nouvelles questions insérées
- API `/api/simulations-admin` : retourne les 5 nouvelles simulations
- Numérotation corrigée : réponses 1 à 50 par série (et non 51-100, 101-150, etc.)
