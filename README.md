# Facturation Pro (Flutter) — SAER DRAME & D-T-E

Application mobile Android + iOS : choix de l'entreprise, création de factures,
sauvegarde sur le téléphone, PDF (aperçu, partage WhatsApp/e-mail, impression).

## 1. Installer Flutter
https://docs.flutter.dev/get-started/install (Windows : Flutter + Android Studio).
Vérifiez avec : `flutter doctor`

## 2. Préparer le projet (une seule fois)
Dans ce dossier :

    flutter create --org sn.saerdrame --project-name facturation_pro .
    flutter pub get
    dart run flutter_launcher_icons

(`flutter create .` ajoute les dossiers android/ et ios/ sans toucher à lib/ ni pubspec.yaml.)

Nom affiché sous l'icône :
- Android : `android/app/src/main/AndroidManifest.xml` → `android:label="Facturation"`
- iOS : `ios/Runner/Info.plist` → `CFBundleDisplayName`

## 3. Tester
    flutter run          (téléphone branché en USB, mode développeur activé)

## 4. Publier
- **Play Store** : `flutter build appbundle --release` → fichier `build/app/outputs/bundle/release/app-release.aab`
  (créez d'abord une clé de signature : https://docs.flutter.dev/deployment/android#signing-the-app)
- **APK à installer directement** : `flutter build apk --release`
- **App Store** : nécessite un Mac + compte Apple Developer : `flutter build ipa --release`

## Structure
- `lib/companies.dart` : fiches entreprises (SAER DRAME, D-T-E). Pour ajouter une entreprise, ajoutez-en une ici.
- `lib/services/pdf_builder.dart` : modèles de PDF (classique SAER DRAME avec logo/tampon, moderne D-T-E).
- `lib/services/store.dart` : stockage local (téléphone) + numérotation automatique (ex. DTE-2026-001, SD-2026-001).
- `lib/screens/` : accueil, liste, éditeur de facture, aperçu PDF.
- `assets/` : logo, tampon, polices du PDF.

## Prochaine étape (comptes utilisateurs)
Pour l'inscription (compte Google, NINEA, registre de commerce, logo de l'entreprise) il faudra
ajouter Firebase Auth + Firestore ; `Company` est déjà conçu pour être rempli depuis ces données.
