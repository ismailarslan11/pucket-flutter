#!/usr/bin/env bash
# Android Play Store release keystore oluşturur (bir kez çalıştırın).
set -euo pipefail
cd "$(dirname "$0")/.."

KEYSTORE="android/pucket-release.jks"

if [[ -f "$KEYSTORE" ]]; then
  echo "Keystore zaten var: $KEYSTORE"
  exit 0
fi

echo "Android release keystore oluşturuluyor..."
keytool -genkey -v \
  -keystore "$KEYSTORE" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias pucket \
  -storepass "${KEYSTORE_PASS:-changeit}" \
  -keypass "${KEY_PASS:-changeit}" \
  -dname "CN=PUCKET, OU=Mobile, O=Pucket, L=Istanbul, ST=Istanbul, C=TR"

echo ""
echo "Keystore: $KEYSTORE"
echo ""
echo "SHA-1 (Firebase Console > Android app > SHA certificate fingerprints):"
keytool -list -v -keystore "$KEYSTORE" -alias pucket -storepass "${KEYSTORE_PASS:-changeit}" 2>/dev/null | grep SHA1 || true
echo ""
echo "android/key.properties.example dosyasını key.properties olarak kopyalayıp şifreleri girin."
