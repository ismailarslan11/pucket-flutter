#!/usr/bin/env python3
"""Generate App Store / Play Store marketing screenshots for PUCKET."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "store_assets" / "final"
LOGO = ROOT / "assets" / "images" / "pucket_logo.png"

IPHONE_67 = (1290, 2796)
IPHONE_65 = (1284, 2778)
ANDROID = (1080, 1920)
FEATURE = (1024, 500)

PHONE = (390, 844)  # logical phone screen inside marketing frame


class C:
    BG = (13, 13, 18)
    PURPLE = (124, 58, 237)
    PURPLE_L = (168, 85, 247)
    PURPLE_D = (91, 33, 182)
    PINK = (236, 72, 153)
    CYAN = (56, 189, 248)
    YELLOW = (251, 191, 36)
    WHITE = (255, 255, 255)
    CARD = (24, 24, 31)
    BORDER = (42, 42, 56)
    RED = (232, 48, 48)
    BLUE = (48, 128, 232)
    GREEN_T = (74, 140, 12)
    GREEN_B = (87, 160, 15)
    MUTED = (150, 150, 165)
    DARK = (26, 26, 26)


SCENES = [
    ("01_hero", "Disk Flicking'in\nYeni Adresi", "PLAY. POCKET. WIN.", C.PURPLE, "hero"),
    ("02_menu", "Online\nMultiplayer", "Gerçek rakiplerle anında oyna", C.CYAN, "menu"),
    ("03_gameplay", "Strateji\n& Refleks", "Diskini fırlat, kapıyı geç", C.PINK, "gameplay"),
    ("04_ranked", "ELO ile\nYüksel", "Liglerde zirveye çık", C.YELLOW, "ranked"),
    ("05_match", "Anında\nEşleşme", "Dünyanın her yerinden oyuncular", C.PURPLE, "match"),
    ("06_login", "Hemen\nBaşla", "Google, Apple veya misafir", C.CYAN, "login"),
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    paths = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for p in paths:
        if Path(p).exists():
            try:
                return ImageFont.truetype(p, size)
            except OSError:
                pass
    return ImageFont.load_default()


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def radial_bg(size: tuple[int, int], accent: tuple[int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size, C.BG)
    draw = ImageDraw.Draw(img)
    cx, cy = w // 2, int(h * 0.16)
    max_r = int(math.hypot(w, h))
    for r in range(max_r, 0, -6):
        t = 1 - r / max_r
        col = (
            lerp(C.BG[0], accent[0], t * 0.6),
            lerp(C.BG[1], accent[1], t * 0.6),
            lerp(C.BG[2], accent[2], t * 0.6),
        )
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=col)
    return img


def screen_bg() -> Image.Image:
    img = Image.new("RGB", PHONE, C.BG)
    draw = ImageDraw.Draw(img)
    cx, cy = PHONE[0] // 2, int(PHONE[1] * 0.2)
    for r in range(500, 0, -4):
        t = 1 - r / 500
        col = (lerp(13, 26, t), lerp(13, 16, t), lerp(18, 53, t))
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=col)
    return img


def paste_logo(base: Image.Image, xy: tuple[int, int], height: int) -> None:
    if not LOGO.exists():
        return
    logo = Image.open(LOGO).convert("RGBA")
    w = int(height * logo.width / logo.height)
    logo = logo.resize((w, height), Image.Resampling.LANCZOS)
    base.paste(logo, xy, logo)


def draw_btn(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, label: str, fill: tuple, shadow: tuple | None = None) -> None:
    if shadow:
        draw.rounded_rectangle((x, y + 4, x + w, y + h + 4), radius=6, fill=shadow)
    draw.rounded_rectangle((x, y, x + w, y + h), radius=6, fill=fill)
    f = font(13, bold=True)
    bb = draw.textbbox((0, 0), label, font=f)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    draw.text((x + (w - tw) / 2, y + (h - th) / 2 - 1), label, fill=C.WHITE if fill != C.YELLOW else (0, 0, 0), font=f)


def draw_tagline(draw: ImageDraw.ImageDraw, y: int, center_x: int) -> None:
    f = font(10, bold=True)
    parts = [("PLAY.", C.PURPLE), (" POCKET.", C.PINK), (" WIN.", C.CYAN)]
    total = sum(draw.textbbox((0, 0), t, font=f)[2] for t, _ in parts)
    x = center_x - total // 2
    for text, color in parts:
        draw.text((x, y), text, fill=color, font=f)
        x += draw.textbbox((0, 0), text, font=f)[2]


def scene_hero() -> Image.Image:
    img = screen_bg()
    draw = ImageDraw.Draw(img)
    paste_logo(img, ((PHONE[0] - 180) // 2, 260), 180)
    draw_tagline(draw, 470, PHONE[0] // 2)
    f = font(11)
    t = "ONLINE MULTIPLAYER"
    bb = draw.textbbox((0, 0), t, font=f)
    draw.text(((PHONE[0] - bb[2]) // 2, 500), t, fill=C.CYAN, font=f)
    return img


def scene_menu() -> Image.Image:
    img = screen_bg()
    draw = ImageDraw.Draw(img)
    # profile bar
    draw.rectangle((0, 44, PHONE[0], 98), fill=(255, 255, 255, 10))
    draw.ellipse((16, 54, 54, 92), outline=C.PURPLE, width=2, fill=(124, 58, 237, 40))
    draw.text((28, 62), "İ", fill=C.PURPLE, font=font(18, bold=True))
    draw.text((62, 56), "İsmail", fill=C.WHITE, font=font(12, bold=True))
    draw.text((62, 74), "1485 ELO  •  47G 21M", fill=C.MUTED, font=font(9))
    draw.rounded_rectangle((300, 58, 374, 82), radius=10, outline=C.YELLOW, width=1)
    draw.text((312, 63), "🥇 Altın", fill=C.YELLOW, font=font(9, bold=True))

    paste_logo(img, ((PHONE[0] - 130) // 2, 118), 110)
    draw_tagline(draw, 250, PHONE[0] // 2)

    card_x, card_w = 24, PHONE[0] - 48
    draw.rounded_rectangle((card_x, 290, card_x + card_w, 380), radius=12, fill=C.CARD, outline=C.BORDER)
    draw.text((card_x + 14, 302), "Günlük Görevler", fill=C.WHITE, font=font(12, bold=True))
    draw.text((card_x + card_w - 40, 302), "🔥 5", fill=C.YELLOW, font=font(12, bold=True))

    y = 400
    draw_btn(draw, card_x, y, card_w, 46, "DERECELİ MAÇ", C.PURPLE_D, C.PURPLE_D)
    y += 56
    draw_btn(draw, card_x, y, card_w, 46, "HIZLI MAÇ", C.PURPLE)
    y += 56
    draw_btn(draw, card_x, y, card_w, 46, "ODA OLUŞTUR", C.PURPLE_L)
    y += 56
    draw_btn(draw, card_x, y, card_w, 52, "KARİYER", (106, 48, 147))
    return img


def scene_gameplay() -> Image.Image:
    img = Image.new("RGB", PHONE, C.BG)
    draw = ImageDraw.Draw(img)
    # top bar
    draw.rectangle((0, 44, PHONE[0], 96), fill=C.DARK)
    draw.text((20, 58), "SEN", fill=C.RED, font=font(8, bold=True))
    draw.text((20, 70), "1", fill=C.RED, font=font(22, bold=True))
    draw.text((170, 58), "DERECELİ", fill=C.MUTED, font=font(7))
    draw.text((165, 70), "1520", fill=C.YELLOW, font=font(10, bold=True))
    draw.text((300, 58), "NOVAX", fill=C.BLUE, font=font(8, bold=True))
    draw.text((330, 70), "0", fill=C.BLUE, font=font(22, bold=True))
    draw.rectangle((0, 96, PHONE[0], 120), fill=(20, 20, 20))
    draw.text((130, 104), "ROUND 2/3", fill=(68, 68, 68), font=font(9, bold=True))
    draw.text((230, 104), "01:34", fill=C.YELLOW, font=font(10, bold=True))

    # field
    top, bot = 120, PHONE[1] - 60
    mid = (top + bot) // 2
    draw.rectangle((0, top, PHONE[0], mid), fill=C.GREEN_T)
    draw.rectangle((0, mid, PHONE[0], bot), fill=C.GREEN_B)
    draw.rectangle((0, mid - 3, PHONE[0], mid + 3), fill=(13, 13, 13))
    gate_w = 70
    gx = (PHONE[0] - gate_w) // 2
    draw.rectangle((gx, mid - 14, gx + gate_w, mid + 14), fill=(124, 58, 237, 80))
    draw.rectangle((gx, mid - 14, gx + gate_w, mid + 14), outline=C.PURPLE_L, width=2)

    def disc(cx, cy, color):
        r = 16
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color, outline=(0, 0, 0), width=1)

    # red side
    for x in (80, 200, 310):
        disc(x, mid + 80, C.RED)
    disc(195, mid + 30, C.RED)  # moving disc near gate
    # blue side
    for x in (100, 195, 290):
        disc(x, mid - 70, C.BLUE)

    draw.rectangle((0, bot, PHONE[0], PHONE[1]), fill=(20, 20, 20))
    draw.text((16, bot + 16), "Kalan: 4", fill=C.YELLOW, font=font(14, bold=True))
    draw.text((200, bot + 20), "Sürükle → fırlat", fill=C.MUTED, font=font(9))
    return img


def scene_ranked() -> Image.Image:
    img = screen_bg()
    draw = ImageDraw.Draw(img)
    draw.text((PHONE[0] // 2 - 70, 200), "DERECELİ MAÇ", fill=C.PURPLE, font=font(18, bold=True))
    cx, cw = 30, PHONE[0] - 60
    draw.rounded_rectangle((cx, 260, cx + cw, 460), radius=14, fill=C.CARD, outline=C.BORDER)
    draw.ellipse((cx + cw // 2 - 16, 290, cx + cw // 2 + 16, 322), outline=C.PURPLE, width=3)
    draw.text((cx + cw // 2 - 28, 340), "ELO PUANIN", fill=C.MUTED, font=font(8))
    draw.text((cx + cw // 2 - 50, 360), "1485", fill=C.YELLOW, font=font(40, bold=True))
    draw.rounded_rectangle((cx + cw // 2 - 40, 420, cx + cw // 2 + 40, 444), radius=10, outline=C.YELLOW)
    draw.text((cx + cw // 2 - 30, 425), "🥇 Altın", fill=C.YELLOW, font=font(10, bold=True))
    draw.text((cx + cw // 2 - 50, 470), "Rakip aranıyor…", fill=C.MUTED, font=font(11))
    return img


def scene_match() -> Image.Image:
    img = screen_bg()
    draw = ImageDraw.Draw(img)
    paste_logo(img, ((PHONE[0] - 90) // 2, 180), 90)
    draw.text((PHONE[0] // 2 - 80, 290), "RAKİP BULUNDU!", fill=C.PINK, font=font(18, bold=True))
    cx, cw = 30, PHONE[0] - 60
    draw.rounded_rectangle((cx, 340, cx + cw, 480), radius=14, fill=C.CARD, outline=C.PURPLE_L)
    draw.text((cx + 40, 365), "SEN", fill=C.MUTED, font=font(8))
    draw.text((cx + 30, 385), "İsmail", fill=C.WHITE, font=font(11, bold=True))
    draw.text((cx + 40, 410), "1485", fill=C.RED, font=font(26, bold=True))
    draw.text((PHONE[0] // 2 - 12, 400), "VS", fill=(68, 68, 68), font=font(16, bold=True))
    draw.text((cx + cw - 90, 365), "RAKİP", fill=C.MUTED, font=font(8))
    draw.text((cx + cw - 80, 385), "NovaX", fill=C.WHITE, font=font(11, bold=True))
    draw.text((cx + cw - 80, 410), "1520", fill=C.BLUE, font=font(26, bold=True))
    draw_btn(draw, cx, 520, cw, 48, "MAÇA BAŞLA", C.PURPLE_D)
    return img


def scene_login() -> Image.Image:
    img = screen_bg()
    draw = ImageDraw.Draw(img)
    paste_logo(img, ((PHONE[0] - 120) // 2, 160), 120)
    draw_tagline(draw, 310, PHONE[0] // 2)
    cx, cw = 45, PHONE[0] - 90
    draw.rounded_rectangle((cx, 360, cx + cw, 620), radius=16, fill=C.CARD, outline=C.BORDER)
    draw.text((cx + 40, 385), "Devam etmek için giriş yap", fill=C.MUTED, font=font(11))
    draw_btn(draw, cx + 20, 420, cw - 40, 44, "Google ile devam", (66, 133, 244))
    draw.rounded_rectangle((cx + 20, 476, cx + cw - 20, 520), radius=8, fill=C.WHITE)
    draw.text((cx + 55, 490), " Apple ile devam et", fill=(0, 0, 0), font=font(12, bold=True))
    draw.rounded_rectangle((cx + 20, 540, cx + cw - 20, 584), radius=8, outline=C.BORDER)
    draw.text((cx + 95, 555), "👤  Misafir", fill=C.MUTED, font=font(12))
    return img


SCENE_BUILDERS = {
    "hero": scene_hero,
    "menu": scene_menu,
    "gameplay": scene_gameplay,
    "ranked": scene_ranked,
    "match": scene_match,
    "login": scene_login,
}


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return m


def compose_marketing(screen: Image.Image, headline: str, subtitle: str, accent: tuple, canvas: tuple[int, int]) -> Image.Image:
    cw, ch = canvas
    base = radial_bg(canvas, accent)
    draw = ImageDraw.Draw(base)
    tf = font(int(ch * 0.052), bold=True)
    sf = font(int(ch * 0.022))
    tagf = font(int(ch * 0.018), bold=True)

    hy = int(ch * 0.07)
    for i, line in enumerate(headline.split("\n")):
        bb = draw.textbbox((0, 0), line, font=tf)
        draw.text(((cw - bb[2] + bb[0]) // 2, hy + i * int(ch * 0.058)), line, fill=C.WHITE, font=tf)

    sb = draw.textbbox((0, 0), subtitle, font=sf)
    draw.text(((cw - sb[2] + sb[0]) // 2, hy + int(ch * 0.13)), subtitle, fill=C.MUTED, font=sf)

    parts = [("PLAY.", accent), (" POCKET.", C.PINK), (" WIN.", C.CYAN)]
    tx = (cw - sum(draw.textbbox((0, 0), t, font=tagf)[2] - draw.textbbox((0, 0), t, font=tagf)[0] for t, _ in parts)) // 2
    ty = hy + int(ch * 0.165)
    for text, color in parts:
        draw.text((tx, ty), text, fill=color, font=tagf)
        tx += draw.textbbox((0, 0), text, font=tagf)[2] - draw.textbbox((0, 0), text, font=tagf)[0]

    phone_w = int(cw * 0.78)
    phone_h = int(phone_w * screen.height / screen.width)
    max_h = int(ch * 0.62)
    if phone_h > max_h:
        phone_h = max_h
        phone_w = int(phone_h * screen.width / screen.height)
    screen_r = screen.resize((phone_w, phone_h), Image.Resampling.LANCZOS)
    radius = int(phone_w * 0.07)
    mask = rounded_mask((phone_w, phone_h), radius)

    shadow = Image.new("RGBA", (phone_w + 40, phone_h + 40), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((20, 20, phone_w + 20, phone_h + 20), radius=radius, fill=(0, 0, 0, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(16))

    px, py = (cw - phone_w) // 2, int(ch * 0.28)
    base.paste(shadow, (px - 20, py - 8), shadow)
    base.paste(screen_r, (px, py), mask)
    ImageDraw.Draw(base).rounded_rectangle((px, py, px + phone_w, py + phone_h), radius=radius, outline=(255, 255, 255, 50), width=2)
    return base


def feature_graphic() -> Image.Image:
    w, h = FEATURE
    img = radial_bg((w, h), C.PURPLE)
    draw = ImageDraw.Draw(img)
    if LOGO.exists():
        logo = Image.open(LOGO).convert("RGBA")
        lh = int(h * 0.72)
        lw = int(lh * logo.width / logo.height)
        logo = logo.resize((lw, lh), Image.Resampling.LANCZOS)
        img.paste(logo, (int(w * 0.05), (h - lh) // 2), logo)
    draw.text((int(w * 0.38), int(h * 0.28)), "PUCKET", fill=C.WHITE, font=font(54, bold=True))
    draw.text((int(w * 0.38), int(h * 0.52)), "Online Disk Flicking", fill=C.MUTED, font=font(24))
    x = int(w * 0.38)
    for text, color in [("PLAY.", C.PURPLE_L), (" POCKET.", C.PINK), (" WIN.", C.CYAN)]:
        draw.text((x, int(h * 0.68)), text, fill=color, font=font(22, bold=True))
        x += draw.textbbox((0, 0), text, font=font(22, bold=True))[2]
    return img


def save(img: Image.Image, path: Path, size: tuple[int, int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = img.resize(size, Image.Resampling.LANCZOS) if img.size != size else img
    out.save(path, "PNG", optimize=True)
    print(f"  ✓ {path.relative_to(ROOT)}  ({size[0]}×{size[1]})")


def main() -> None:
    print("Generating PUCKET store screenshots…\n")
    screens_dir = OUT / "screens_only"
    for name, headline, subtitle, accent, key in SCENES:
        screen = SCENE_BUILDERS[key]()
        save(screen, screens_dir / f"{name}.png", (PHONE[0] * 3, PHONE[1] * 3))

        marketing = compose_marketing(screen, headline, subtitle, accent, IPHONE_67)
        save(marketing, OUT / "iphone_6.7" / f"{name}.png", IPHONE_67)
        save(marketing, OUT / "iphone_6.5" / f"{name}.png", IPHONE_65)
        save(marketing, OUT / "android" / f"{name}.png", ANDROID)

    save(feature_graphic(), OUT / "feature_graphic" / "play_store_feature.png", FEATURE)
    print(f"\nDone → {OUT}")


if __name__ == "__main__":
    main()
