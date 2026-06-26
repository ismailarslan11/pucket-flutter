#!/usr/bin/env bash
# Render PostgreSQL kurulum yardımcısı
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER="$ROOT/server"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  PUCKET — Kalıcı Veritabanı Kurulumu (Render)            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "ÖNCE RENDER'DA ŞUNLARI YAP (tarayıcıda):"
echo ""
echo "  1. https://dashboard.render.com → Giriş yap"
echo ""
echo "  2. Sağ üst [New +] → PostgreSQL"
echo "     • Name: pucket-db"
echo "     • Plan: Free"
echo "     → [Create Database]"
echo ""
echo "  3. Oluşan veritabanı sayfasında:"
echo "     • 'Connections' bölümünü aç"
echo "     • 'External Database URL' satırını KOPYALA"
echo "       (postgres://pucket:xxxx@dpg-xxxx.render.com/pucket)"
echo ""
echo "  4. Sol menüden web servisini aç: pucket-flutter-2"
echo "     • Environment → Add Environment Variable"
echo "     • Key:   DATABASE_URL"
echo "     • Value: (az önce kopyaladığın URL)"
echo "     → Save Changes"
echo ""
echo "  5. Aynı sayfada [Manual Deploy] → Deploy latest commit"
echo ""
echo "──────────────────────────────────────────────────────────"
echo ""
read -r -p "External Database URL'yi yapıştır (Enter = sadece talimat): " DB_URL

if [[ -z "${DB_URL:-}" ]]; then
  echo ""
  echo "URL girmedin. Render adımlarını bitirince tekrar çalıştır:"
  echo "  bash tool/setup_render_db.sh"
  exit 0
fi

echo ""
echo "==> Mevcut oyuncu verileri PostgreSQL'e aktarılıyor…"
cd "$SERVER"
DATABASE_URL="$DB_URL" npm run import-db

echo ""
echo "✓ Veritabanı hazır!"
echo ""
echo "Son adım: Render'da web servisini deploy et (Manual Deploy)."
echo "Logda şunu görmelisin: Veritabanı: PostgreSQL (12 oyuncu)"
echo ""
echo "Test: https://pucket-flutter-2.onrender.com/health"
echo ""
