#!/usr/bin/env bash
# Firebase Cloud Messaging (push) kurulumu — pucket-202607
#
# Kullanım:
#   ./tool/setup_firebase_messaging.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_ID="${FIREBASE_PROJECT_ID:-pucket-202607}"
TOPIC="pucket"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}UYARI:${NC} $*"; }

if [[ -f tool/firebase_project.env ]]; then
  # shellcheck disable=SC1091
  source tool/firebase_project.env
  PROJECT_ID="${FIREBASE_PROJECT_ID:-$PROJECT_ID}"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  PUCKET — Firebase Push Bildirim Kurulumu                ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Proje: $PROJECT_ID"
echo "Topic: $TOPIC (uygulama otomatik abone olur)"
echo ""

info "Kod tarafı kontrolü"
checks=0
if [[ -f android/app/google-services.json ]]; then checks=$((checks + 1)); else warn "google-services.json yok"; fi
if grep -q "$PROJECT_ID" android/app/google-services.json 2>/dev/null; then checks=$((checks + 1)); else warn "google-services.json eski proje olabilir"; fi
if grep -q "POST_NOTIFICATIONS" android/app/src/main/AndroidManifest.xml; then checks=$((checks + 1)); else warn "POST_NOTIFICATIONS izni eksik"; fi
if grep -q "firebase_messaging" pubspec.yaml; then checks=$((checks + 1)); else warn "firebase_messaging paketi yok"; fi
if grep -q "pucket_high_importance" android/app/src/main/AndroidManifest.xml; then checks=$((checks + 1)); else warn "bildirim kanalı meta-data eksik"; fi

if [[ $checks -ge 4 ]]; then
  info "Mobil kod hazır ✓"
else
  warn "Bazı kontroller başarısız — yine de devam edebilirsiniz"
fi

export PATH="$ROOT/node_modules/.bin:$PATH"
if command -v firebase >/dev/null 2>&1; then
  info "Firebase CLI — proje doğrulama"
  firebase projects:list 2>/dev/null | grep -q "$PROJECT_ID" && info "Proje erişilebilir ✓" || warn "Proje listede yok — firebase login kontrol edin"
fi

echo ""
echo "────────────────────────────────────────────────────────────"
echo "FIREBASE CONSOLE — Android test (5 dakika)"
echo "────────────────────────────────────────────────────────────"
echo ""
echo "1) Yeni APK yükle (pucket-202607 google-services.json ile build)"
echo "2) Uygulamayı aç → bildirim izni ver"
echo "3) Firebase Console:"
echo "   https://console.firebase.google.com/project/$PROJECT_ID/messaging"
echo ""
echo "4) «Yeni kampanya» / «New campaign» → «Bildirimler» / «Notifications»"
echo "5) Başlık: PUCKET  |  Metin: Test bildirimi"
echo "6) Hedef / Target:"
echo "   • Topic → $TOPIC   (tüm abone cihazlar)"
echo "   veya"
echo "   • «Test mesajı gönder» ile FCM token (logcat’ten)"
echo "7) Gönder / Publish"
echo ""
echo "────────────────────────────────────────────────────────────"
echo "FCM TOKEN alma (tek cihaza test)"
echo "────────────────────────────────────────────────────────────"
echo ""
echo "Telefon USB veya BlueStacks + adb:"
echo "  adb logcat -s flutter | grep 'FCM token'"
echo ""
echo "Firebase → Proje ayarları → Cloud Messaging → «Test mesajı gönder»"
echo "→ Token yapıştır → Test"
echo ""
echo "────────────────────────────────────────────────────────────"
echo "iOS push (App Store / TestFlight öncesi)"
echo "────────────────────────────────────────────────────────────"
echo ""
echo "1) Apple Developer → Keys → + → Apple Push Notifications (APNs)"
echo "2) .p8 dosyasını indir — Key ID ve Team ID not al"
echo "3) Firebase → Proje ayarları → Cloud Messaging → Apple uygulaması"
echo "   https://console.firebase.google.com/project/$PROJECT_ID/settings/cloudmessaging"
echo "4) APNs Authentication Key yükle (.p8)"
echo "5) Xcode → Runner → Signing → Push Notifications capability açık olsun"
echo ""
echo "────────────────────────────────────────────────────────────"
echo "Sunucudan push (ileride — ranked / duyuru)"
echo "────────────────────────────────────────────────────────────"
echo ""
echo "Render → FIREBASE_SERVICE_ACCOUNT_JSON = yeni proje service account JSON"
echo "Firebase Console → Hizmet hesapları → Yeni özel anahtar oluştur"
echo ""
warn "Firebase ↔ AdMob bağlantısı push için gerekli değil."
echo ""
info "Tamamlandı — yukarıdaki adımları Firebase Console’da uygulayın."
