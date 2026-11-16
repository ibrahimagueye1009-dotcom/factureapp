#!/usr/bin/env bash
# Build iOS local — à exécuter sur un Mac uniquement.
#
#   ./scripts/build_ios.sh             → build non signé (tests, simulateur/device via Xcode)
#   ./scripts/build_ios.sh --signed    → IPA signé (nécessite certificat + profil installés
#                                        et ios/ExportOptionsRelease.plist présent)
#
# ExportOptionsRelease.plist minimal (à compléter avec votre Team ID et le nom du profil) :
#   <?xml version="1.0" encoding="UTF-8"?>
#   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
#   <plist version="1.0"><dict>
#     <key>method</key><string>app-store</string>
#     <key>teamID</key><string>VOTRE_TEAM_ID</string>
#     <key>signingStyle</key><string>manual</string>
#     <key>provisioningProfiles</key><dict>
#       <key>sn.saerdrame.facturationPro</key><string>NOM_DU_PROFIL</string>
#     </dict>
#   </dict></plist>

set -euo pipefail

if [ "$(uname)" != "Darwin" ]; then
  echo "ERREUR : ce script doit être exécuté sur macOS (Xcode requis)." >&2
  exit 1
fi

# 1. Dépendances Flutter
flutter clean
flutter pub get

# 2. Plist Firebase — indispensable car référencé dans le projet Xcode
if [ ! -f ios/Runner/GoogleService-Info.plist ]; then
  echo "AVERTISSEMENT : ios/Runner/GoogleService-Info.plist absent."
  echo "→ Copiez-y le fichier téléchargé depuis la console Firebase, ou un stub sera généré (build OK, Firebase inopérant à l'exécution)."
  printf '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>API_KEY</key><string>stub-api-key</string><key>GCM_SENDER_ID</key><string>000000000000</string><key>PLIST_VERSION</key><string>1</string><key>BUNDLE_ID</key><string>sn.saerdrame.facturationPro</string><key>PROJECT_ID</key><string>stub-project</string><key>STORAGE_BUCKET</key><string>stub-project.appspot.com</string><key>GOOGLE_APP_ID</key><string>1:000000000000:ios:stub0000000000</string></dict></plist>' > ios/Runner/GoogleService-Info.plist
fi

# 3. CocoaPods (après pub get : il dépend des fichiers générés)
(cd ios && pod install)

# 4. Build
if [ "${1:-}" = "--signed" ]; then
  if [ ! -f ios/ExportOptionsRelease.plist ]; then
    echo "ERREUR : ios/ExportOptionsRelease.plist introuvable (modèle en tête de script)." >&2
    exit 1
  fi
  flutter build ipa --release --export-options-plist=ios/ExportOptionsRelease.plist
  echo "IPA : build/ios/ipa/*.ipa"
else
  flutter build ios --release --no-codesign
  echo "App non signée : build/ios/iphoneos/Runner.app"
  echo "→ Pour l'installer sur un iPhone : Fenêtres & Applications > Xcode > Devices, ou Apple Configurator."
fi
