#!/usr/bin/env bash
# Production APK/AAB build
#
# Kullanım:
#   ./tool/build_release.sh appbundle
#   ./tool/build_release.sh apk
#
# İsteğe bağlı override:
#   export WS_URL=wss://...
#   export API_URL=https://...
#
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:-appbundle}"
WS_URL="${WS_URL:-wss://pucket-flutter-2.onrender.com}"
API_URL="${API_URL:-https://pucket-flutter-2.onrender.com}"

DEFINES=(
  "--dart-define=WS_URL=${WS_URL}"
  "--dart-define=API_URL=${API_URL}"
)

echo "→ WS_URL=$WS_URL"
echo "→ API_URL=$API_URL"
echo "→ Build: $TARGET"
echo "→ AdMob: release Android ID'leri ad_config.dart içinde"

if [[ "$TARGET" == "appbundle" ]]; then
  flutter build appbundle --release "${DEFINES[@]}"
  echo ""
  echo "AAB: build/app/outputs/bundle/release/app-release.aab"
elif [[ "$TARGET" == "apk" ]]; then
  flutter build apk --release "${DEFINES[@]}"
  OUT="pucket-$(grep '^version:' pubspec.yaml | awk '{print $2}').apk"
  cp build/app/outputs/flutter-apk/app-release.apk "$OUT"
  echo ""
  echo "APK: build/app/outputs/flutter-apk/app-release.apk"
  echo "     $OUT"
elif [[ "$TARGET" == "ios" ]]; then
  flutter build ipa --release "${DEFINES[@]}"
  echo ""
  echo "IPA: build/ios/ipa/*.ipa"
else
  echo "Geçersiz hedef: $TARGET (apk | appbundle | ios)"
  exit 1
fi
