#!/usr/bin/env python3
"""PUCKET reklam / tanıtım videosu (store_assets + logo + oyun sesleri)."""

from __future__ import annotations

import math
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "store_assets" / "promo"
TMP = OUT_DIR / "_tmp"
LOGO = ROOT / "assets" / "images" / "pucket_logo.png"
SHOTS = ROOT / "store_assets" / "final" / "android"
MENU_WAV = ROOT / "assets" / "sounds" / "menu.wav"
HIT_WAV = ROOT / "assets" / "sounds" / "hit.wav"

W, H = 1080, 1920
FPS = 30


def run(cmd: list[str]) -> None:
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=True)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def radial_bg(size: tuple[int, int], center: tuple[int, int], c1, c2, c3) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size, c1)
    draw = ImageDraw.Draw(img)
    cx, cy = center
    max_r = math.hypot(w, h)
    steps = 80
    for i in range(steps, 0, -1):
        t = i / steps
        r = max_r * t
        color = (
            int(c2[0] * (1 - t) + c3[0] * t),
            int(c2[1] * (1 - t) + c3[1] * t),
            int(c2[2] * (1 - t) + c3[2] * t),
        )
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color)
    return img.filter(ImageFilter.GaussianBlur(2))


def draw_title_card(
    title: str,
    subtitle: str,
    *,
    show_logo: bool = True,
    accent=(168, 85, 247),
) -> Image.Image:
    base = radial_bg((W, H), (W // 2, H // 3), (8, 6, 18), (30, 10, 60), (13, 13, 18))
    draw = ImageDraw.Draw(base)

    y = 280
    if show_logo and LOGO.exists():
        logo = Image.open(LOGO).convert("RGBA")
        lw = 520
        lh = int(logo.height * (lw / logo.width))
        logo = logo.resize((lw, lh), Image.Resampling.LANCZOS)
        base.paste(logo, ((W - lw) // 2, y), logo)
        y += lh + 40
    else:
        y = 420

    f_title = font(92, bold=True)
    f_sub = font(44, bold=False)
    tw = draw.textlength(title, font=f_title)
    draw.text(((W - tw) / 2, y), title, fill=(255, 255, 255), font=f_title)
    sw = draw.textlength(subtitle, font=f_sub)
    draw.text(((W - sw) / 2, y + 110), subtitle, fill=accent, font=f_sub)

    # neon lines
    draw.rectangle((120, H - 180, W - 120, H - 176), fill=accent)
    tag = "pucket.app"
    ft = font(32, bold=True)
    tg = draw.textlength(tag, font=ft)
    draw.text(((W - tg) / 2, H - 130), tag, fill=(180, 180, 200), font=ft)
    return base


def fit_phone_screenshot(path: Path) -> Image.Image:
    src = Image.open(path).convert("RGB")
    # Marketing frame içindeki telefon alanını kırp (yaklaşık orta bölüm)
    sw, sh = src.size
    crop = src.crop((int(sw * 0.12), int(sh * 0.08), int(sw * 0.88), int(sh * 0.92)))
    cw, ch = crop.size
    target_w = int(W * 0.82)
    target_h = int(target_w * ch / cw)
    if target_h > int(H * 0.78):
        target_h = int(H * 0.78)
        target_w = int(target_h * cw / ch)
    phone = crop.resize((target_w, target_h), Image.Resampling.LANCZOS)

    bg = radial_bg((W, H), (W // 2, H // 2), (6, 4, 14), (40, 12, 80), (10, 8, 20))
    px = (W - target_w) // 2
    py = (H - target_h) // 2 + 40
    shadow = Image.new("RGBA", (target_w + 40, target_h + 40), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((20, 20, target_w + 20, target_h + 20), radius=36, fill=(0, 0, 0, 120))
    bg.paste(shadow, (px - 20, py - 10), shadow)
    bg.paste(phone, (px, py))
    return bg


def image_to_clip(img_path: Path, out_path: Path, seconds: float, zoom: float = 1.08) -> None:
    run([
        "ffmpeg", "-y", "-loop", "1", "-i", str(img_path),
        "-vf",
        (
            f"scale={W}:{H}:force_original_aspect_ratio=increase,"
            f"crop={W}:{H},"
            f"zoompan=z='min(zoom+0.0008,{zoom})':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':"
            f"d={int(seconds * FPS)}:s={W}x{H}:fps={FPS}"
        ),
        "-t", str(seconds),
        "-pix_fmt", "yuv420p",
        str(out_path),
    ])


def main() -> int:
    if shutil.which("ffmpeg") is None:
        print("ffmpeg gerekli: brew install ffmpeg", file=sys.stderr)
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    if TMP.exists():
        shutil.rmtree(TMP)
    TMP.mkdir(parents=True)

    cards = [
        ("01_open", draw_title_card("PUCKET", "Diskini fırlat · Rakibini yen", show_logo=True), 3.2),
        ("02_hook", draw_title_card("ONLINE ARENA", "Gerçek rakipler · Anlık maçlar", show_logo=False), 2.4),
    ]
    shots = [
        ("03_game", SHOTS / "03_gameplay.png", 4.0, "Hız · Strateji · Refleks"),
        ("04_rank", SHOTS / "04_ranked.png", 3.5, "Ranked · ELO · Lig"),
        ("05_friends", SHOTS / "05_match.png", 3.5, "Arkadaşınla oyna"),
        ("06_cta", SHOTS / "02_menu.png", 3.2, None),
    ]
    end_card = draw_title_card("HEMEN OYNA", "Ücretsiz · Rekabet · Eğlence", show_logo=True)

    png_paths: list[tuple[Path, float]] = []
    for name, img, sec in cards:
        p = TMP / f"{name}.png"
        img.save(p, "PNG")
        png_paths.append((p, sec))

    for name, shot, sec, caption in shots:
        frame = fit_phone_screenshot(shot)
        if caption:
            draw = ImageDraw.Draw(frame)
            ft = font(52, bold=True)
            tw = draw.textlength(caption, font=ft)
            draw.text(((W - tw) / 2, 120), caption, fill=(255, 255, 255), font=ft)
        p = TMP / f"{name}.png"
        frame.save(p, "PNG")
        png_paths.append((p, sec))

    p = TMP / "07_end.png"
    end_card.save(p, "PNG")
    png_paths.append((p, 3.0))

    clips: list[Path] = []
    for i, (png, sec) in enumerate(png_paths):
        clip = TMP / f"clip_{i:02d}.mp4"
        image_to_clip(png, clip, sec)
        clips.append(clip)

    concat_list = TMP / "concat.txt"
    concat_list.write_text("\n".join(f"file '{c}'" for c in clips) + "\n", encoding="utf-8")

    silent = TMP / "silent.mp4"
    run([
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(concat_list),
        "-c:v", "libx264", "-pix_fmt", "yuv420p", str(silent),
    ])

    total_dur = sum(s for _, s in png_paths)
    out_video = OUT_DIR / "pucket_promo_9x16.mp4"

    if MENU_WAV.exists() and HIT_WAV.exists():
        run([
            "ffmpeg", "-y",
            "-i", str(silent),
            "-i", str(MENU_WAV),
            "-i", str(HIT_WAV),
            "-filter_complex",
            (
                f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total_dur},volume=0.35[music];"
                f"[2:a]adelay=8000|8000,volume=0.55[hit];"
                f"[music][hit]amix=inputs=2:duration=first:dropout_transition=2[aout]"
            ),
            "-map", "0:v", "-map", "[aout]",
            "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
            "-shortest", str(out_video),
        ])
    else:
        shutil.copy(silent, out_video)

    # 16:9 YouTube versiyonu
    out_wide = OUT_DIR / "pucket_promo_16x9.mp4"
    run([
        "ffmpeg", "-y", "-i", str(out_video),
        "-vf",
        f"scale=1920:1080:force_original_aspect_ratio=decrease,"
        f"pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x0a0612",
        "-c:v", "libx264", "-c:a", "copy", str(out_wide),
    ])

    shutil.rmtree(TMP)
    print(f"\n✓ Dikey (Reels/Shorts): {out_video}")
    print(f"✓ Yatay (YouTube):       {out_wide}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
