#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "▶ Generating store marketing screenshots…"
python3 -m pip install -q pillow 2>/dev/null || pip3 install -q pillow
python3 tools/generate_store_screenshots.py

echo ""
echo "Store assets ready in store_assets/final/"
