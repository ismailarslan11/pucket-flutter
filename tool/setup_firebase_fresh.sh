#!/usr/bin/env bash
# PUCKET — Sıfırdan Firebase kurulumu (yeni hesap + yeni proje)
#
# Kullanım:
#   cd ~/Projects/pucket_flutter
#   chmod +x tool/setup_firebase_fresh.sh
#   ./tool/setup_firebase_fresh.sh
#
# Önce tarayıcıda YENİ Google hesabıyla giriş yapacaksınız.
# Android paket adı: com.yesastudio.pucket (eski OAuth çakışmasını önler)
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ANDROID_PACKAGE="com.yesastudio.pucket"
IOS_BUNDLE="com.pucket.pucketFlutter"
ENV_FILE="$ROOT/tool/firebase_project.env"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}UYARI:${NC} $*"; }
fail()  { echo -e "${RED}HATA:${NC} $*" >&2; exit 1; }

find_keytool() {
  local kt="${JAVA_HOME:-}/bin/keytool"
  if [[ -x "$kt" ]]; then echo "$kt"; return; fi
  if [[ -x "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/keytool" ]]; then
    echo "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/keytool"
    return
  fi
  if command -v keytool >/dev/null 2>&1; then command -v keytool; return; fi
  fail "keytool bulunamadı — JDK 17 kurun: brew install openjdk@17"
}

KEYTOOL="$(find_keytool)"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  PUCKET — Sıfırdan Firebase Kurulumu                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Android paket: $ANDROID_PACKAGE"
echo "iOS bundle:    $IOS_BUNDLE"
echo ""

info "Node / Firebase CLI"
[[ -f package.json ]] || fail "package.json yok"
npm install --no-fund --no-audit --silent
export PATH="$ROOT/node_modules/.bin:$PATH:$HOME/.pub-cache/bin"
firebase --version >/dev/null || fail "firebase CLI çalışmıyor"

info "FlutterFire CLI"
if ! command -v flutterfire >/dev/null 2>&1; then
  dart pub global activate flutterfire_cli
fi

echo ""
warn "YENİ Firebase hesabı kullanacaksınız."
echo "  1) Eski hesaptan çıkış (önerilir)"
echo "  2) Yeni Google hesabıyla giriş"
echo ""
read -r -p "Firebase'den çıkış yapılsın mı? (E/h) " LOGOUT_ANS
if [[ "${LOGOUT_ANS:-E}" =~ ^[EeYy]$ ]]; then
  firebase logout || true
fi

info "Firebase girişi (tarayıcı açılacak)"
firebase login --reauth

ACCOUNT=$(firebase login:list 2>/dev/null | grep -E '^\*' | sed 's/^\* //' | head -1 || true)
echo "Giriş yapılan hesap: ${ACCOUNT:-bilinmiyor}"
echo ""

info "Mevcut Firebase projeleri"
firebase projects:list || true
echo ""

DEFAULT_PROJECT_ID="pucket-$(date +%Y%m)"
read -r -p "Yeni Firebase proje ID'si [$DEFAULT_PROJECT_ID]: " PROJECT_ID
PROJECT_ID="${PROJECT_ID:-$DEFAULT_PROJECT_ID}"

if firebase projects:list 2>/dev/null | grep -q "$PROJECT_ID"; then
  warn "Proje '$PROJECT_ID' zaten var — kullanılacak."
else
  info "Firebase projesi oluşturuluyor: $PROJECT_ID"
  firebase projects:create "$PROJECT_ID" --display-name "PUCKET" || fail "Proje oluşturulamadı"
  sleep 3
fi

echo ""
echo "────────────────────────────────────────────────────────────"
echo "ŞİMDİ TARAYICIDA (Firebase Console) şunları yapın:"
echo "────────────────────────────────────────────────────────────"
echo ""
echo "  A) https://console.firebase.google.com/project/$PROJECT_ID"
echo ""
echo "  B) Authentication → Sign-in method:"
echo "     • Google → Etkinleştir → Destek e-postası seç → Kaydet"
echo "     • Apple → Etkinleştir (iOS için, isteğe bağlı)"
echo "     • Anonymous → Etkinleştir (isteğe bağlı)"
echo ""
echo "  C) Firestore Database → Veritabanı oluştur:"
echo "     • Production mode"
echo "     • Bölge: europe-west3 (Frankfurt) veya europe-west1"
echo ""
echo "  D) Proje ayarları → Genel → Destek e-postası ekle"
echo ""
echo "  E) Google Cloud'ta OAuth onay ekranı:"
echo "     • Proje ayarları → Google Cloud'ta aç"
echo "     • OAuth onay ekranı → Harici → Üretim"
echo ""
read -r -p "Yukarıdaki adımları tamamladınız mı? (E/h) " READY
READY="$(printf '%s' "${READY:-E}" | tr -d '[:space:]\r' | tr '[:upper:]' '[:lower:]')"
case "$READY" in
  e|y|evet|yes|"") ;;
  *) fail "Önce Firebase Console adımlarını tamamlayın. (Cevap: '$READY')" ;;
esac

info "FlutterFire yapılandırması"
flutterfire configure \
  --project="$PROJECT_ID" \
  --platforms=android,ios,web,macos \
  --android-package-name="$ANDROID_PACKAGE" \
  --ios-bundle-id="$IOS_BUNDLE" \
  --yes \
  --overwrite-firebase-options

ANDROID_APP_ID=""
if [[ -f android/app/google-services.json ]]; then
  ANDROID_APP_ID=$(python3 - <<'PY' "$ROOT/android/app/google-services.json"
import json, sys
data = json.load(open(sys.argv[1]))
print(data["client"][0]["client_info"]["mobilesdk_app_id"])
PY
)
fi
[[ -n "$ANDROID_APP_ID" ]] || fail "google-services.json oluşturulamadı"

info "Android SHA parmak izleri kaydediliyor"
if [[ -f "$HOME/.android/debug.keystore" ]]; then
  DBG_SHA1=$("$KEYTOOL" -list -v \
    -keystore "$HOME/.android/debug.keystore" \
    -alias androiddebugkey \
    -storepass android -keypass android 2>/dev/null | awk -F': ' '/SHA1:/ {print $2; exit}')
  DBG_SHA256=$("$KEYTOOL" -list -v \
    -keystore "$HOME/.android/debug.keystore" \
    -alias androiddebugkey \
    -storepass android -keypass android 2>/dev/null | awk -F': ' '/SHA256:/ {print $2; exit}')
  [[ -n "${DBG_SHA1:-}" ]] && firebase apps:android:sha:create "$ANDROID_APP_ID" "$DBG_SHA1" --project="$PROJECT_ID" 2>/dev/null || true
  [[ -n "${DBG_SHA256:-}" ]] && firebase apps:android:sha:create "$ANDROID_APP_ID" "$DBG_SHA256" --project="$PROJECT_ID" 2>/dev/null || true
  echo "  Debug SHA-1:   ${DBG_SHA1:-yok}"
fi

KEY_PROPS="$ROOT/android/key.properties"
KEYSTORE="$ROOT/android/pucket-release.jks"
if [[ -f "$KEY_PROPS" && -f "$KEYSTORE" ]]; then
  STORE_PASS=$(grep '^storePassword=' "$KEY_PROPS" | cut -d= -f2-)
  KEY_ALIAS=$(grep '^keyAlias=' "$KEY_PROPS" | cut -d= -f2-)
  REL_SHA1=$("$KEYTOOL" -list -v \
    -keystore "$KEYSTORE" \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASS" 2>/dev/null | awk -F': ' '/SHA1:/ {print $2; exit}')
  REL_SHA256=$("$KEYTOOL" -list -v \
    -keystore "$KEYSTORE" \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASS" 2>/dev/null | awk -F': ' '/SHA256:/ {print $2; exit}')
  [[ -n "${REL_SHA1:-}" ]] && firebase apps:android:sha:create "$ANDROID_APP_ID" "$REL_SHA1" --project="$PROJECT_ID" 2>/dev/null || true
  [[ -n "${REL_SHA256:-}" ]] && firebase apps:android:sha:create "$ANDROID_APP_ID" "$REL_SHA256" --project="$PROJECT_ID" 2>/dev/null || true
  echo "  Release SHA-1: ${REL_SHA1:-yok}"
else
  warn "Release keystore yok — ./tool/setup_release_signing.sh sonra çalıştırın"
fi

sleep 5
info "google-services.json yenileniyor"
firebase apps:sdkconfig ANDROID "$ANDROID_APP_ID" --project="$PROJECT_ID" \
  --out android/app/google-services.json

HAS_ANDROID_OAUTH=$(python3 - <<'PY' "$ROOT/android/app/google-services.json"
import json, sys
data = json.load(open(sys.argv[1]))
types = [o.get("client_type") for c in data.get("client", []) for o in c.get("oauth_client", [])]
print("1" if 1 in types else "0")
PY
)

if [[ "$HAS_ANDROID_OAUTH" != "1" ]]; then
  warn "google-services.json içinde Android OAuth istemcisi (client_type:1) YOK!"
  echo ""
  echo "  Google Cloud Console → Kimlik Bilgileri → OAuth istemci kimliği oluştur:"
  echo "    Tür: Android"
  echo "    Paket: $ANDROID_PACKAGE"
  echo "    SHA-1: (yukarıdaki release veya debug SHA-1)"
  echo ""
  echo "  Oluşturduktan sonra google-services.json'ı Firebase'den tekrar indirin"
  echo "  veya bu scripti bir kez daha çalıştırın."
else
  info "Android OAuth istemcisi doğrulandı ✓"
fi

info "google_auth_config.generated.dart güncelleniyor"
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
  IOS_CLIENT=$(/usr/libexec/PlistBuddy -c 'Print :CLIENT_ID' "$ROOT/ios/Runner/GoogleService-Info.plist" 2>/dev/null || true)
fi

cat > "$ROOT/lib/config/google_auth_config.generated.dart" <<DART
// Otomatik oluşturulur — elle düzenlemeyin.
class GoogleAuthConfigGenerated {
  static const webClientId = '$WEB_CLIENT';
  static const iosClientId = '$IOS_CLIENT';
}
DART

cat > "$ROOT/lib/config/build_config.dart" <<'DART'
/// Otomatik oluşturulur — `tool/setup_firebase_fresh.sh` ile güncellenir.
const bool kFirebaseNativeReady = true;
DART

bash "$ROOT/tool/apply_ios_google_plist.sh" 2>/dev/null || true

cat > "$ENV_FILE" <<EOF
# tool/setup_firebase_fresh.sh tarafından oluşturuldu — $(date -u +%Y-%m-%dT%H:%M:%SZ)
FIREBASE_PROJECT_ID=$PROJECT_ID
ANDROID_APP_ID=$ANDROID_APP_ID
ANDROID_PACKAGE=$ANDROID_PACKAGE
IOS_BUNDLE_ID=$IOS_BUNDLE
EOF
chmod 600 "$ENV_FILE" 2>/dev/null || true

info "Firestore kuralları yayınlanıyor"
if firebase deploy --only firestore:rules --project="$PROJECT_ID" 2>/dev/null; then
  info "Firestore rules yayınlandı ✓"
else
  warn "Firestore rules otomatik yayınlanamadı."
  echo "  Firebase Console → Firestore → Rules → firestore.rules içeriğini yapıştır → Publish"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Kurulum tamamlandı                                      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Proje ID:     $PROJECT_ID"
echo "Android app:  $ANDROID_APP_ID"
echo "Paket adı:    $ANDROID_PACKAGE"
echo ""
echo "── Sonraki adımlar ──"
echo ""
echo "1) Release APK build:"
echo "   export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
echo "   flutter build apk --release"
echo ""
echo "2) Sunucu (Render) — Service Account JSON:"
echo "   Firebase Console → Proje ayarları → Hizmet hesapları"
echo "   → Yeni özel anahtar oluştur → JSON indir"
echo "   Render → Environment → FIREBASE_SERVICE_ACCOUNT_JSON = (tüm JSON)"
echo ""
echo "3) AdMob — yeni hesapta uygulama + birimler:"
echo "   cp tool/admob.env.example tool/admob.env"
echo "   # AdMob Console ID'lerini doldur"
echo "   ./tool/setup_admob.sh"
echo "   Firebase → Entegrasyonlar → AdMob bağla"
echo ""
echo "4) Eski Firebase projelerini sil (isteğe bağlı):"
echo "   pucket-9413c ve pucket-c6794 → Proje ayarları → Projeyi sil"
echo ""
echo "5) Test:"
echo "   flutter run -d <cihaz>"
echo "   Google ile giriş yap"
echo ""
