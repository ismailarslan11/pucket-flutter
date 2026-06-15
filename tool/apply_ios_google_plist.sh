#!/usr/bin/env bash
# GoogleService-Info.plist → Info.plist (GIDClientID, GIDServerClientID, URL scheme)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLIST="$ROOT/ios/Runner/GoogleService-Info.plist"
INFO="$ROOT/ios/Runner/Info.plist"

if [[ ! -f "$PLIST" ]]; then
  echo "GoogleService-Info.plist bulunamadı: $PLIST"
  echo "Önce tool/setup_firebase.sh çalıştırın veya Firebase Console'dan indirin."
  exit 1
fi

CLIENT_ID=$(/usr/libexec/PlistBuddy -c 'Print :CLIENT_ID' "$PLIST")
REVERSED=$(/usr/libexec/PlistBuddy -c 'Print :REVERSED_CLIENT_ID' "$PLIST")

# Web client ID — oauth_client type 3 from google-services.json if present
WEB_CLIENT=""
JSON="$ROOT/android/app/google-services.json"
if [[ -f "$JSON" ]]; then
  WEB_CLIENT=$(python3 - <<'PY' "$JSON"
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

# GIDClientID
/usr/libexec/PlistBuddy -c "Delete :GIDClientID" "$INFO" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :GIDClientID string $CLIENT_ID" "$INFO"

if [[ -n "$WEB_CLIENT" ]]; then
  /usr/libexec/PlistBuddy -c "Delete :GIDServerClientID" "$INFO" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :GIDServerClientID string $WEB_CLIENT" "$INFO"
fi

# CFBundleURLTypes — Google Sign-In callback
/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$INFO" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$INFO"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$INFO"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleTypeRole string Editor" "$INFO"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$INFO"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string $REVERSED" "$INFO"

echo "Info.plist güncellendi (CLIENT_ID + URL scheme)."
