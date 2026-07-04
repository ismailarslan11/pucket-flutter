#!/usr/bin/env bash
# AdMob ID'lerini tool/admob.env'den okuyup projeye uygular.
#
# Kullanım:
#   cp tool/admob.env.example tool/admob.env
#   # admob.env içindeki ID'leri doldur
#   ./tool/setup_admob.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/tool/admob.env"
EXAMPLE="$ROOT/tool/admob.env.example"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}UYARI:${NC} $*"; }
fail()  { echo -e "${RED}HATA:${NC} $*" >&2; exit 1; }

require_var() {
  local name="$1"
  local val="$2"
  if [[ -z "$val" || "$val" == *"XXXXXXXX"* || "$val" == *"YYYYYYYY"* ]]; then
    fail "$name eksik veya örnek değerde — tool/admob.env dosyasını doldurun."
  fi
}

if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f "$EXAMPLE" ]]; then
    cp "$EXAMPLE" "$ENV_FILE"
    warn "tool/admob.env oluşturuldu — AdMob Console ID'lerini doldurup tekrar çalıştırın."
    exit 1
  fi
  fail "tool/admob.env bulunamadı."
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

require_var ADMOB_ANDROID_APP_ID "${ADMOB_ANDROID_APP_ID:-}"
require_var ADMOB_ANDROID_BANNER_ID "${ADMOB_ANDROID_BANNER_ID:-}"
require_var ADMOB_ANDROID_INTERSTITIAL_ID "${ADMOB_ANDROID_INTERSTITIAL_ID:-}"
require_var ADMOB_ANDROID_REWARDED_ID "${ADMOB_ANDROID_REWARDED_ID:-}"
require_var ADMOB_IOS_APP_ID "${ADMOB_IOS_APP_ID:-}"
require_var ADMOB_IOS_BANNER_ID "${ADMOB_IOS_BANNER_ID:-}"
require_var ADMOB_IOS_INTERSTITIAL_ID "${ADMOB_IOS_INTERSTITIAL_ID:-}"
require_var ADMOB_IOS_REWARDED_ID "${ADMOB_IOS_REWARDED_ID:-}"

info "ad_config.generated.dart güncelleniyor"
cat > "$ROOT/lib/config/ad_config.generated.dart" <<DART
// Otomatik oluşturulur — elle düzenlemeyin.
class AdConfigGenerated {
  static const androidBanner = '$ADMOB_ANDROID_BANNER_ID';
  static const androidInterstitial = '$ADMOB_ANDROID_INTERSTITIAL_ID';
  static const androidRewarded = '$ADMOB_ANDROID_REWARDED_ID';

  static const iosBanner = '$ADMOB_IOS_BANNER_ID';
  static const iosInterstitial = '$ADMOB_IOS_INTERSTITIAL_ID';
  static const iosRewarded = '$ADMOB_IOS_REWARDED_ID';
}
DART

info "AndroidManifest.xml → AdMob App ID"
MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"
python3 - <<PY "$MANIFEST" "$ADMOB_ANDROID_APP_ID"
import re, sys
path, app_id = sys.argv[1], sys.argv[2]
text = open(path).read()
new = re.sub(
    r'(<meta-data\s+android:name="com\.google\.android\.gms\.ads\.APPLICATION_ID"\s+android:value=")[^"]*(")',
    r'\g<1>' + app_id + r'\2',
    text,
    count=1,
)
if new == text:
    raise SystemExit('AdMob APPLICATION_ID meta-data bulunamadı')
open(path, 'w').write(new)
PY

info "iOS Info.plist → GADApplicationIdentifier"
/usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier $ADMOB_IOS_APP_ID" \
  "$ROOT/ios/Runner/Info.plist"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  AdMob kurulumu tamamlandı                               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Android App ID:  $ADMOB_ANDROID_APP_ID"
echo "iOS App ID:      $ADMOB_IOS_APP_ID"
echo ""
echo "Firebase ↔ AdMob bağlantısı (önerilir):"
echo "  https://console.firebase.google.com/project/pucket-202607/settings/integrations"
echo "  → AdMob → Bağla → yeni AdMob hesabını seç"
echo ""
echo "Yeniden build:"
echo "  export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
echo "  flutter build apk --release"
echo ""
