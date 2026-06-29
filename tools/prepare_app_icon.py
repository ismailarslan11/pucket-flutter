#!/usr/bin/env python3
"""Crop the P icon from the full PUCKET logo for launcher / favicon use."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "images" / "pucket_logo.png"
OUT = ROOT / "assets" / "images" / "app_icon.png"


def main() -> None:
    img = Image.open(SRC).convert("RGBA")
    w, h = img.size

    # Upper "P" mark only (no wordmark / tagline).
    size = int(min(w, h * 0.54))
    left = (w - size) // 2
    top = int(h * 0.03)
    icon = img.crop((left, top, left + size, top + size))

    canvas = Image.new("RGBA", (1024, 1024), (255, 255, 255, 255))
    pad = int(1024 * 0.08)
    inner = 1024 - pad * 2
    icon = icon.resize((inner, inner), Image.Resampling.LANCZOS)
    canvas.paste(icon, (pad, pad - 20), icon)
    canvas.convert("RGB").save(OUT, "PNG", optimize=True)
    print(f"Wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
