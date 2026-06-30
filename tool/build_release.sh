#!/usr/bin/env bash
# Production APK/AAB/IPA build
#
# Kullanım:
#   ./tool/build_release.sh appbundle
#   ./tool/build_release.sh apk
#   ./tool/build_release.sh ios
#
# İsteğe bağlı override:
#   export WS_URL=wss://...
#   export API_URL=https://...
#   export TEST_ADS=1          # yalnızca debug: Google test reklamları
#
# iOS prod reklam (TEST_ADS=0 iken zorunlu):
#   cp tool/admob_ios.env.example tool/admob_ios.env
#   # AdMob Console → iOS uygulaması (com.pucket.pucketFlutter) ID'lerini doldur
#
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:-appbundle}"
WS_URL="${WS_URL:-wss://pucket-flutter-2.onrender.com}"
API_URL="${API_URL:-https://pucket-flutter-2.onrender.com}"
TEST_ADS="${TEST_ADS:-0}"

if [[ -f tool/admob_ios.env ]]; then
  set -a
  # shellcheck disable=SC1091
  source tool/admob_ios.env
  set +a
fi

DEFINES=(
  "--dart-define=WS_URL=${WS_URL}"
  "--dart-define=API_URL=${API_URL}"
)

if [[ "$TEST_ADS" == "1" ]]; then
  DEFINES+=("--dart-define=ADMOB_USE_TEST_ADS=true")
fi

echo "→ WS_URL=$WS_URL"
echo "→ API_URL=$API_URL"
echo "→ Build: $TARGET"
echo "→ TEST_ADS=$TEST_ADS (1=Google test reklam, 0=prod birimler)"

if [[ "$TARGET" == "ios" && "$TEST_ADS" != "1" ]]; then
  IOS_APP_ID="${ADMOB_IOS_APP_ID:-ca-app-pub-2558408055462441~7988103551}"
  IOS_BANNER_ID="${ADMOB_IOS_BANNER_ID:-ca-app-pub-2558408055462441/8708525371}"
  /usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier ${IOS_APP_ID}" ios/Runner/Info.plist
  DEFINES+=("--dart-define=ADMOB_IOS_BANNER_ID=${IOS_BANNER_ID}")
  if [[ -n "${ADMOB_IOS_INTERSTITIAL_ID:-}" ]]; then
    DEFINES+=("--dart-define=ADMOB_IOS_INTERSTITIAL_ID=${ADMOB_IOS_INTERSTITIAL_ID}")
  fi
  echo "→ iOS AdMob App ID: ${IOS_APP_ID}"
fi

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
