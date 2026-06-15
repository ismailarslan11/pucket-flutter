#!/usr/bin/env bash
# Firebase + Google Sign-In kurulumu (pucket-9413c)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Firebase CLI kuruluyor (proje içi)"
if [[ ! -f package.json ]]; then
  echo "Hata: package.json bulunamadı."
  exit 1
fi
npm install --no-fund --no-audit
export PATH="$ROOT/node_modules/.bin:$PATH:$HOME/.pub-cache/bin"

if ! firebase --version >/dev/null 2>&1; then
  echo "Hata: firebase komutu çalışmıyor. Node.js/npm kurulu mu?"
  exit 1
fi
echo "Firebase CLI: $(firebase --version)"

echo "==> Firebase girişi"
if ! firebase projects:list --json 2>/dev/null | grep -q '"status":"OK"'; then
  echo "Tarayıcıda Google hesabınızla giriş yapın..."
  firebase login
fi

ACCOUNT=$(firebase login:list 2>/dev/null | grep -E '^\*' | sed 's/^\* //' | head -1 || true)
echo "Giriş yapılan hesap: ${ACCOUNT:-bilinmiyor}"

echo "==> Firebase projeleri"
if ! firebase projects:list 2>&1 | grep -q pucket-9413c; then
  echo ""
  echo "UYARI: 'pucket-9413c' bu hesapta görünmüyor."
  echo "  • pucket-9413c farklı bir Google hesabına ait olabilir"
  echo "  • veya bu hesaba Firebase projesine davet edilmeniz gerekebilir"
  echo ""
  firebase projects:list || true
  echo ""
  read -r -p "Yine de devam etmek istiyor musunuz? (y/n) " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]] || exit 1
fi

echo "==> FlutterFire CLI"
if ! command -v flutterfire >/dev/null 2>&1; then
  dart pub global activate flutterfire_cli
fi

echo "==> iOS / Android / Web yapılandırması"
flutterfire configure \
  --project=pucket-9413c \
  --platforms=ios,android,web \
  --ios-bundle-id=com.pucket.pucketFlutter \
  --android-package-name=com.pucket.pucket_flutter \
  --yes \
  --overwrite-firebase-options

echo "==> build_config.dart güncelleniyor"
cat > "$ROOT/lib/config/build_config.dart" <<'DART'
/// Otomatik oluşturulur — `tool/setup_firebase.sh` ile güncellenir.
const bool kFirebaseNativeReady = true;
DART

WEB_CLIENT=""
if [[ -f android/app/google-services.json ]]; then
  WEB_CLIENT=$(python3 - <<'PY' "$ROOT/android/app/google-services.json"
import json, sys
data = json.load(open(sys.argv[1]))
for client in data.get("client", []):
    for oauth in client.get("oauth_client", []):
        if oauth.get("client_type") == 3:
            print(oauth["client_id"])
            raise SystemExit
PY
)
fi

IOS_CLIENT=""
if [[ -f ios/Runner/GoogleService-Info.plist ]]; then
  IOS_CLIENT=$(/usr/libexec/PlistBuddy -c 'Print :CLIENT_ID' "$ROOT/ios/Runner/GoogleService-Info.plist")
fi

cat > "$ROOT/lib/config/google_auth_config.generated.dart" <<DART
// Otomatik oluşturulur — elle düzenlemeyin.
class GoogleAuthConfigGenerated {
  static const webClientId = '$WEB_CLIENT';
  static const iosClientId = '$IOS_CLIENT';
}
DART

echo "==> iOS Info.plist Google URL scheme güncelleniyor"
bash "$ROOT/tool/apply_ios_google_plist.sh"

if [[ -f android/app/google-services.json ]]; then
  echo "==> Android debug SHA-1 (Firebase Console → Android app → SHA certificate):"
  if [[ -f "$HOME/.android/debug.keystore" ]]; then
    keytool -list -v \
      -keystore "$HOME/.android/debug.keystore" \
      -alias androiddebugkey \
      -storepass android -keypass android 2>/dev/null | grep "SHA1:" || true
  else
    echo "   (Henüz debug.keystore yok — ilk Android build'den sonra tekrar çalıştırın)"
  fi
fi

echo ""
echo "Kurulum tamam. Uygulamayı çalıştırın:"
echo "  cd $ROOT && flutter run"
