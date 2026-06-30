#!/usr/bin/env python3
"""Crop the PUCKET emblem and build a full-bleed launcher icon (no white padding)."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "images" / "pucket_logo.png"
OUT = ROOT / "assets" / "images" / "app_icon.png"

SIZE = 1024
# Logo arka planı: üst mavi, alt turuncu (kenarlarda beyaz kalmasın).
TOP_BG = (22, 96, 169)
BOTTOM_BG = (250, 78, 4)


def _gradient_background(size: int) -> Image.Image:
    canvas = Image.new("RGB", (size, size))
    px = canvas.load()
    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(TOP_BG[0] * (1 - t) + BOTTOM_BG[0] * t)
        g = int(TOP_BG[1] * (1 - t) + BOTTOM_BG[1] * t)
        b = int(TOP_BG[2] * (1 - t) + BOTTOM_BG[2] * t)
        for x in range(size):
            px[x, y] = (r, g, b)
    return canvas


def main() -> None:
    img = Image.open(SRC).convert("RGBA")
    w, h = img.size

    # Center square: circular emblem + wordmark (wide logo is ~16:9).
    side = h
    left = max(0, (w - side) // 2)
    emblem = img.crop((left, 0, left + side, side))
    emblem = emblem.resize((SIZE, SIZE), Image.Resampling.LANCZOS)

    canvas = _gradient_background(SIZE)
    canvas.paste(emblem, (0, 0), emblem)
    canvas.save(OUT, "PNG", optimize=True)
    print(f"Wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
