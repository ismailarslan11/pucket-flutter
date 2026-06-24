#!/usr/bin/env bash
# Fly.io'ya sunucu deploy (fly CLI gerekli: https://fly.io/docs/hands-on/install-flyctl/)
set -euo pipefail
cd "$(dirname "$0")/../server"

if ! command -v fly &>/dev/null; then
  echo "fly CLI yok. Kur: curl -L https://fly.io/install.sh | sh"
  exit 1
fi

if [[ ! -f fly.toml ]]; then
  echo "fly.toml bulunamadı"
  exit 1
fi

echo "→ fly deploy (server/)"
fly deploy

echo ""
echo "Deploy sonrası test:"
echo "  curl https://pucket-server.fly.dev/health"
echo ""
echo "Flutter build:"
echo "  export WS_URL=wss://pucket-server.fly.dev"
echo "  export API_URL=https://pucket-server.fly.dev"
echo "  ../tool/build_release.sh apk"
