#!/usr/bin/env bash
# Production APK/AAB build — sunucu URL'si zorunlu.
#
# Kullanım:
#   export WS_URL=wss://pucket-server.fly.dev
#   export API_URL=https://pucket-server.fly.dev
#   ./tool/build_release.sh apk
#   ./tool/build_release.sh appbundle
#
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:-apk}"
WS_URL="${WS_URL:-}"
API_URL="${API_URL:-}"

if [[ -z "$WS_URL" || -z "$API_URL" ]]; then
  echo "HATA: WS_URL ve API_URL tanımlı olmalı."
  echo ""
  echo "Örnek (Fly.io):"
  echo "  export WS_URL=wss://pucket-server.fly.dev"
  echo "  export API_URL=https://pucket-server.fly.dev"
  echo "  ./tool/build_release.sh apk"
  exit 1
fi

DEFINES=(
  "--dart-define=WS_URL=${WS_URL}"
  "--dart-define=API_URL=${API_URL}"
)

echo "→ WS_URL=$WS_URL"
echo "→ API_URL=$API_URL"
echo "→ Build: $TARGET"

if [[ "$TARGET" == "appbundle" ]]; then
  flutter build appbundle --release "${DEFINES[@]}"
  echo ""
  echo "AAB: build/app/outputs/bundle/release/app-release.aab"
elif [[ "$TARGET" == "apk" ]]; then
  flutter build apk --release "${DEFINES[@]}"
  echo ""
  echo "APK: build/app/outputs/flutter-apk/app-release.apk"
elif [[ "$TARGET" == "ios" ]]; then
  flutter build ipa --release "${DEFINES[@]}"
  echo ""
  echo "IPA: build/ios/ipa/*.ipa"
else
  echo "Geçersiz hedef: $TARGET (apk | appbundle | ios)"
  exit 1
fi
