# 📱 DOCUMENTATION PLAY STORE — EF-FORT.BF
## Guide complet de déploiement Android

---

## 1. INFORMATIONS DE L'APPLICATION

| Champ | Valeur |
|-------|--------|
| **Nom de l'app** | EF-FORT.BF |
| **Package name** | `com.effortbf.app` |
| **Version actuelle** | 5.1.0 (code: 5) |
| **SDK minimum** | API 21 (Android 5.0) |
| **SDK cible** | API 35 (Android 15) |
| **Catégorie** | Éducation |
| **Âge minimum** | 13+ |

---

## 2. PRÉREQUIS TECHNIQUES

### 2.1 Générer le Keystore de production

```bash
# Générer un keystore sécurisé (à faire UNE SEULE FOIS)
keytool -genkey -v \
  -keystore ef-fort-bf-release.jks \
  -alias effortbf \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=EF-FORT.BF, OU=Mobile, O=EF-FORT, L=Ouagadougou, ST=Centre, C=BF"

# ⚠️ IMPORTANT : Conservez le fichier .jks et les mots de passe en lieu sûr !
# ⚠️ Si vous perdez le keystore, vous ne pourrez plus mettre à jour l'app sur le Play Store
```

### 2.2 Configurer key.properties

Créer le fichier `android/key.properties` :
```properties
storePassword=VOTRE_MOT_DE_PASSE_STORE
keyPassword=VOTRE_MOT_DE_PASSE_CLE
keyAlias=effortbf
storeFile=../ef-fort-bf-release.jks
```

### 2.3 Configurer android/app/build.gradle.kts

```kotlin
// Ajouter AVANT android {}
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    // ...
    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

---

## 3. GÉNÉRER L'AAB (Android App Bundle)

```bash
# 1. Nettoyer les builds précédents
cd ef-fort-bf
flutter clean

# 2. Récupérer les dépendances
flutter pub get

# 3. Générer l'AAB de production
flutter build appbundle --release

# Le fichier sera disponible à :
# build/app/outputs/bundle/release/app-release.aab
```

### Vérification de l'AAB
```bash
# Vérifier la taille
ls -lh build/app/outputs/bundle/release/app-release.aab

# Vérifier la signature (optionnel)
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

---

## 4. PERMISSIONS NÉCESSAIRES

Dans `android/app/src/main/AndroidManifest.xml` :

```xml
<!-- Internet (obligatoire pour l'app) -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Vibration pour les retours haptiques -->
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Audio pour les sons de notification -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### Justifications des permissions pour le Play Store :

| Permission | Justification |
|-----------|---------------|
| `INTERNET` | Accès aux QCM, séries et examens stockés sur notre serveur Supabase |
| `VIBRATE` | Retours haptiques lors de la navigation et des réponses aux questions |

---

## 5. PRÉREQUIS ADMINISTRATIFS

### 5.1 Compte Développeur Google Play
- **Coût** : 25 USD (frais uniques)
- **Inscription** : https://play.google.com/console/
- **Délai** : 24-48h pour validation du compte

### 5.2 Fichiers requis pour la soumission

#### a) Icône de l'application
- **Taille** : 512 × 512 pixels
- **Format** : PNG 32-bit
- **Fond** : Pas de fond transparent
- **Fichier actuel** : `assets/images/logo_effort.png`

#### b) Captures d'écran (obligatoires)
- **Téléphone** : minimum 2 captures (1080×1920 ou 1440×2560)
- **Tablette 7"** : optionnel
- **Tablette 10"** : optionnel

#### c) Bannière de fonctionnalité
- **Taille** : 1024 × 500 pixels
- **Format** : PNG ou JPG

---

## 6. FICHE DE L'APPLICATION (Play Store)

### Titre (max 30 caractères)
```
EF-FORT.BF - Concours Burkina
```

### Description courte (max 80 caractères)
```
Préparez les concours de la Fonction Publique du Burkina Faso
```

### Description longue (max 4000 caractères)
```
🇧🇫 EF-FORT.BF — La plateforme N°1 de préparation aux concours directs 
de la Fonction Publique du Burkina Faso.

📚 CONTENU RICHE ET VARIÉ
• 20 000+ QCM organisés en 20 matières officielles
• Séries de 20 questions par thématique
• Examens Types (50 questions) en conditions réelles
• Matière exclusive : Préparation Haut Niveau (13 séries)

🎯 MATIÈRES DISPONIBLES
• Psychotechnique • Droit • Économie • Mathématiques
• Sciences Physiques • SVT • Culture Générale
• Actualité Internationale • Guide Panafricain
• Figure Africaine • Force Armée Nationale
• Français • Anglais • Informatique • Communication
• Histoire-Géographie • Alliance des États du Sahel
• Burkina Faso • Préparation Haut Niveau

✅ FONCTIONNALITÉS CLÉS
• Mode QCM interactif avec corrections détaillées
• Timer anti-fraude (5 min pour matières, 30 min pour examens)
• Score sur 20, mentions et encouragements personnalisés
• Export PDF des résultats avec logo et corrections
• Surveillance virtuelle pour les examens types

👥 COMMUNAUTÉ ENTRAIDE
• Forum questions-réponses entre candidats
• 1 message par jour (suppression après 24h)
• Réponses de l'équipe pédagogique

📊 TABLEAU DE BORD PERSONNEL
• Suivi en temps réel de votre progression
• Score moyen, simulations et questions traitées
• Historique de vos performances

🆓 ESSAI GRATUIT
La première série de chaque matière est accessible gratuitement.
Les autres séries et les Examens Types nécessitent un abonnement.

📱 COMPATIBLE
• Android 5.0 et supérieur
• Fonctionne sans connexion (mode offline pour révisions)

EF-FORT.BF — Chaque effort te rapproche de ton admission !
```

---

## 7. POLITIQUE DE CONFIDENTIALITÉ

Créer une page web avec le contenu suivant (obligatoire pour le Play Store) :

```
POLITIQUE DE CONFIDENTIALITÉ — EF-FORT.BF

Dernière mise à jour : [DATE]

1. DONNÉES COLLECTÉES
   - Numéro de téléphone (inscription)
   - Prénom et nom
   - Scores et résultats des QCM

2. UTILISATION DES DONNÉES
   - Authentification et identification de l'utilisateur
   - Suivi de la progression personnelle
   - Amélioration des contenus pédagogiques

3. PARTAGE DES DONNÉES
   - Aucun partage avec des tiers à des fins commerciales
   - Données stockées sur Supabase (infrastructure sécurisée)

4. SÉCURITÉ
   - Mots de passe hashés (bcrypt)
   - Connexion HTTPS uniquement
   - Jetons JWT pour les sessions

5. DROITS DES UTILISATEURS
   - Droit à l'effacement de votre compte : contactez-nous
   - Contact : support@ef-fort.bf

6. CONTACT
   EF-FORT.BF — Ouagadougou, Burkina Faso
   Email : support@ef-fort.bf
```

**URL de la politique** : À héberger sur https://ef-fort-bf.pages.dev/privacy-policy

---

## 8. CLASSIFICATION DU CONTENU

| Critère | Valeur |
|---------|--------|
| Violence | Aucune |
| Contenu adulte | Aucun |
| Jeux de hasard | Aucun |
| Langage | Français uniquement |
| Données personnelles | Numéro de téléphone (compte utilisateur) |
| **Âge minimum recommandé** | 13 ans |
| **PEGI** | PEGI 3 |

---

## 9. ÉTAPES DE SOUMISSION PLAY STORE

### Étape 1 : Préparer la console
1. Connexion sur https://play.google.com/console/
2. Créer une nouvelle application
3. Choisir la langue principale : Français

### Étape 2 : Configurer la fiche Play Store
1. Remplir le titre, description courte, description longue
2. Uploader l'icône (512×512)
3. Uploader les captures d'écran (min 2)
4. Uploader la bannière (1024×500)
5. Sélectionner la catégorie : Éducation
6. Renseigner l'URL de la politique de confidentialité

### Étape 3 : Configurer le contenu
1. Remplir le questionnaire de classification du contenu
2. Déclarer les permissions et leur usage
3. Renseigner les informations sur les données collectées

### Étape 4 : Uploader l'AAB
1. Aller dans "Production" > "Créer une nouvelle version"
2. Uploader `app-release.aab`
3. Rédiger les notes de version (obligatoire)
4. Activer Google Play App Signing (recommandé)

### Étape 5 : Soumettre pour révision
1. Vérifier que tous les champs sont remplis
2. Cliquer "Envoyer pour révision"
3. Délai de révision : 3-7 jours ouvrés

---

## 10. NOTES DE VERSION POUR LA PREMIÈRE SOUMISSION

```
Version 5.1.0 — EF-FORT.BF

🎉 Première version officielle sur Google Play Store

✨ NOUVEAUTÉS
• 50 nouvelles questions haut niveau (Séries 11, 12, 13)
• Banque de QCM enrichie : géographie, sciences naturelles,
  littérature africaine
• Questions de niveau concours difficile avec explications détaillées

🔧 AMÉLIORATIONS
• Correction accès gratuit/premium : Série 1 de chaque matière gratuite
• Optimisation du temps de chargement des QCM
• PDF amélioré avec logo, slogan et corrections détaillées

📚 CONTENU
• 20 matières officielles
• 13 séries de Préparation Haut Niveau
• 50 questions Géo/Sciences/Littérature africaine ajoutées
```

---

## 11. CHECKLIST FINALE AVANT SOUMISSION

- [ ] Keystore généré et sauvegardé en sécurité
- [ ] AAB généré et signé : `app-release.aab`
- [ ] AAB testé sur un vrai appareil Android
- [ ] Compte développeur Google Play actif (25$)
- [ ] Icône 512×512 préparée
- [ ] Minimum 2 captures d'écran préparées
- [ ] Description courte et longue rédigées
- [ ] Politique de confidentialité hébergée en ligne
- [ ] Classification du contenu remplie
- [ ] Permissions justifiées
- [ ] Notes de version rédigées

---

## 12. COMMANDES RÉCAPITULATIVES

```bash
# === SÉQUENCE COMPLÈTE POUR GÉNÉRER L'AAB ===

# 1. Se placer dans le projet
cd ef-fort-bf

# 2. Vérifier Flutter
flutter doctor -v

# 3. Nettoyer
flutter clean

# 4. Dépendances
flutter pub get

# 5. Analyser le code
flutter analyze

# 6. Construire l'AAB release
flutter build appbundle --release --dart-define=debugShowCheckedModeBanner=false

# 7. Vérifier le fichier généré
ls -lh build/app/outputs/bundle/release/app-release.aab

# 8. (Optionnel) Générer l'APK pour test
flutter build apk --release --dart-define=debugShowCheckedModeBanner=false

echo "✅ Build terminé ! Fichier prêt pour upload sur Google Play Store"
```

---

*Document généré le $(date +"%d/%m/%Y") — EF-FORT.BF v5.1.0*
