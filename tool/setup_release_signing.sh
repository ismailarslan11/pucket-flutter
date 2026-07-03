#!/usr/bin/env bash
# Play Store release imzası + Firebase release SHA-1/256
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/android"
KEYSTORE="$ANDROID_DIR/pucket-release.jks"
KEY_PROPS="$ANDROID_DIR/key.properties"
KEY_PROPS_EXAMPLE="$ANDROID_DIR/key.properties.example"
ENV_FILE="$ROOT/tool/firebase_project.env"
ALIAS="pucket"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

ANDROID_APP_ID="${ANDROID_APP_ID:-}"
FIREBASE_PROJECT="${FIREBASE_PROJECT_ID:-}"

find_keytool() {
  local kt="${JAVA_HOME:-}/bin/keytool"
  if [[ -x "$kt" ]]; then
    echo "$kt"
    return
  fi
  if [[ -x "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/keytool" ]]; then
    echo "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/keytool"
    return
  fi
  if [[ -x "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" ]]; then
    echo "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
    return
  fi
  if command -v keytool >/dev/null 2>&1; then
    command -v keytool
    return
  fi
  echo "Hata: keytool bulunamadı (JDK veya Android Studio gerekli)" >&2
  exit 1
}

KEYTOOL="$(find_keytool)"

if [[ ! -f "$KEYSTORE" ]]; then
  echo "==> Release keystore oluşturuluyor: $KEYSTORE"
  STORE_PASS="$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24)"
  KEY_PASS="$STORE_PASS"

  "$KEYTOOL" -genkeypair -v \
    -keystore "$KEYSTORE" \
    -alias "$ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storepass "$STORE_PASS" \
    -keypass "$KEY_PASS" \
    -dname "CN=PUCKET, OU=Mobile, O=Yesa Studio, L=Istanbul, ST=Istanbul, C=TR"

  cat > "$KEY_PROPS" <<EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$ALIAS
storeFile=../pucket-release.jks
EOF
  chmod 600 "$KEY_PROPS" 2>/dev/null || true

  echo ""
  echo "ÖNEMLİ: Keystore ve şifreler kaydedildi:"
  echo "  • $KEYSTORE"
  echo "  • $KEY_PROPS"
  echo "  Bu dosyaları yedekleyin — kaybederseniz Play Store güncellemesi yapamazsınız."
  echo ""
else
  echo "==> Mevcut keystore kullanılıyor: $KEYSTORE"
  if [[ ! -f "$KEY_PROPS" ]]; then
    echo "Hata: key.properties yok. key.properties.example'dan kopyalayıp doldurun." >&2
    exit 1
  fi
fi

STORE_PASS=$(grep '^storePassword=' "$KEY_PROPS" | cut -d= -f2-)
KEY_PASS=$(grep '^keyPassword=' "$KEY_PROPS" | cut -d= -f2-)
ALIAS_FROM_PROPS=$(grep '^keyAlias=' "$KEY_PROPS" | cut -d= -f2-)
ALIAS="${ALIAS_FROM_PROPS:-$ALIAS}"
STORE_FILE_LINE=$(grep '^storeFile=' "$KEY_PROPS" | cut -d= -f2-)
KEYSTORE_PATH="$ANDROID_DIR/app/$STORE_FILE_LINE"
if [[ ! -f "$KEYSTORE_PATH" ]]; then
  KEYSTORE_PATH="$ANDROID_DIR/${STORE_FILE_LINE#../}"
fi
if [[ ! -f "$KEYSTORE_PATH" ]]; then
  KEYSTORE_PATH="$KEYSTORE"
fi

echo "==> Release SHA parmak izleri"
SHA1=$("$KEYTOOL" -list -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$ALIAS" \
  -storepass "$STORE_PASS" 2>/dev/null | awk -F': ' '/SHA1:/ {print $2; exit}')
SHA256=$("$KEYTOOL" -list -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$ALIAS" \
  -storepass "$STORE_PASS" 2>/dev/null | awk -F': ' '/SHA256:/ {print $2; exit}')

echo "  SHA-1:   ${SHA1:-bulunamadı}"
echo "  SHA-256: ${SHA256:-bulunamadı}"

if [[ -z "$ANDROID_APP_ID" || -z "$FIREBASE_PROJECT" ]]; then
  echo ""
  echo "UYARI: tool/firebase_project.env yok — önce ./tool/setup_firebase_fresh.sh çalıştırın."
  echo "SHA'ları Firebase Console'dan elle ekleyin."
  exit 0
fi

if [[ -f "$ROOT/package.json" ]]; then
  export PATH="$ROOT/node_modules/.bin:$PATH"
  if firebase --version >/dev/null 2>&1; then
    echo "==> Firebase'e release SHA kaydediliyor ($FIREBASE_PROJECT)"
    if [[ -n "${SHA1:-}" ]]; then
      firebase apps:android:sha:create "$ANDROID_APP_ID" "$SHA1" --project="$FIREBASE_PROJECT" 2>/dev/null || true
    fi
    if [[ -n "${SHA256:-}" ]]; then
      firebase apps:android:sha:create "$ANDROID_APP_ID" "$SHA256" --project="$FIREBASE_PROJECT" 2>/dev/null || true
    fi
    echo "==> google-services.json güncelleniyor"
    firebase apps:sdkconfig ANDROID "$ANDROID_APP_ID" --project="$FIREBASE_PROJECT" \
      --out "$ANDROID_DIR/app/google-services.json"
    echo "  ✓ android/app/google-services.json güncellendi"
  fi
fi

echo ""
echo "==> Release build"
echo "  export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
echo "  flutter build apk --release"
