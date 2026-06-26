#!/usr/bin/env python3
"""PUCKET ses dosyalarını üretir — arcade / air-hockey tarzı."""
import math
import struct
import wave
from pathlib import Path

SR = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def clamp(x: float) -> int:
    return max(-32767, min(32767, int(x)))


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(struct.pack("<h", clamp(s * 32767)) for s in samples)
        w.writeframes(frames)


def env_adsr(i: int, n: int, a=0.01, d=0.08, s=0.55, r=0.12) -> float:
    t = i / SR
    ta, td, tr = a, d, r
    total = n / SR
    if t < ta:
        return t / ta
    if t < ta + td:
        return 1.0 - (1.0 - s) * ((t - ta) / td)
    if t < total - tr:
        return s
    if t < total:
        return s * (1.0 - (t - (total - tr)) / tr)
    return 0.0


def sine(freq: float, t: float, phase: float = 0.0) -> float:
    return math.sin(2 * math.pi * freq * t + phase)


def tri(freq: float, t: float) -> float:
    p = (freq * t) % 1.0
    return 1.0 - 4.0 * abs(p - 0.5)


def noise(seed: int) -> float:
    seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
    return (seed / 0x7FFFFFFF) * 2.0 - 1.0


def tone_burst(freq: float, dur: float, vol=0.35, wave_fn=sine, detune=0.0) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env_adsr(i, n, a=0.002, d=0.06, s=0.4, r=min(0.08, dur * 0.35))
        s = wave_fn(freq, t) * 0.7 + wave_fn(freq + detune, t) * 0.3
        out.append(vol * e * s)
    return out


def mix(*tracks: list[float]) -> list[float]:
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for tr in tracks:
        for i, v in enumerate(tr):
            out[i] += v
    peak = max(abs(x) for x in out) or 1.0
    if peak > 0.95:
        out = [x / peak * 0.95 for x in out]
    return out


def pad(track: list[float], n: int) -> list[float]:
    return track + [0.0] * (n - len(track))


def generate_shot() -> list[float]:
    # Hızlı flick + hafif whoosh
    n = int(SR * 0.14)
    out = []
    for i in range(n):
        t = i / SR
        e = math.exp(-t * 28)
        f = 900 - t * 4200
        whoosh = sine(max(80, f), t) * 0.25
        click = sine(1800, t) * math.exp(-t * 60) * 0.35
        snap = noise(i) * math.exp(-t * 45) * 0.18
        out.append((whoosh + click + snap) * e)
    return out


def generate_hit() -> list[float]:
    n = int(SR * 0.09)
    out = []
    for i in range(n):
        t = i / SR
        e = math.exp(-t * 35)
        body = tri(320, t) * 0.35 + sine(640, t) * 0.2
        ring = sine(1200 + 800 * math.exp(-t * 20), t) * math.exp(-t * 50) * 0.25
        clack = noise(i) * math.exp(-t * 55) * 0.15
        out.append((body + ring + clack) * e)
    return out


def generate_win() -> list[float]:
    notes = [523.25, 659.25, 783.99, 1046.5]  # C5 E5 G5 C6
    parts = []
    t0 = 0.0
    for j, f in enumerate(notes):
        seg = tone_burst(f, 0.11, vol=0.32, wave_fn=tri)
        seg2 = tone_burst(f * 2, 0.11, vol=0.12, wave_fn=sine)
        combined = mix(seg, seg2)
        gap = int(SR * 0.025)
        parts.append([0.0] * gap + combined)
    tail = tone_burst(1046.5, 0.35, vol=0.28, wave_fn=sine)
    tail += tone_burst(1318.5, 0.35, vol=0.18, wave_fn=sine)
    sparkle = []
    for i in range(int(SR * 0.35)):
        t = i / SR
        sparkle.append(sine(1567 + 200 * sine(8, t), t) * math.exp(-t * 4) * 0.08)
    return mix(*parts, tail, sparkle)


def generate_lose() -> list[float]:
    notes = [392.0, 349.23, 293.66]
    parts = []
    for f in notes:
        parts.append(tone_burst(f, 0.16, vol=0.22, wave_fn=tri))
        parts.append([0.0] * int(SR * 0.04))
    return mix(*parts)


def note_at(freq: float, start: float, dur: float, vol=0.18, wave_fn=tri) -> list[float]:
    pre = int(SR * start)
    seg = tone_burst(freq, dur, vol=vol, wave_fn=wave_fn, detune=1.5)
    return [0.0] * pre + seg


def drum_kick(start: float) -> list[float]:
    pre = int(SR * start)
    n = int(SR * 0.12)
    seg = []
    for i in range(n):
        t = i / SR
        f = 120 * math.exp(-t * 18) + 40
        seg.append(sine(f, t) * math.exp(-t * 22) * 0.55)
    return [0.0] * pre + seg


def drum_snare(start: float) -> list[float]:
    pre = int(SR * start)
    n = int(SR * 0.08)
    seg = []
    for i in range(n):
        t = i / SR
        seg.append((noise(i + 99) * 0.45 + sine(180, t) * 0.25) * math.exp(-t * 30))
    return [0.0] * pre + seg


def drum_hat(start: float) -> list[float]:
    pre = int(SR * start)
    n = int(SR * 0.04)
    seg = []
    for i in range(n):
        t = i / SR
        seg.append(noise(i + 7) * math.exp(-t * 70) * 0.12)
    return [0.0] * pre + seg


def generate_menu_loop() -> list[float]:
    """Neşeli arcade menü — ~16 sn döngü, 118 BPM."""
    bpm = 118
    beat = 60.0 / bpm
    bar = beat * 4

    # C major → F → G → C (oyun hissi)
    progressions = [
        [(261.63, 0), (329.63, 0), (392.0, 0)],  # C
        [(349.23, bar), (440.0, bar), (523.25, bar)],  # F
        [(392.0, bar * 2), (493.88, bar * 2), (587.33, bar * 2)],  # G
        [(261.63, bar * 3), (329.63, bar * 3), (392.0, bar * 3)],  # C
    ]

    melody = [
        (523.25, 0.0, 0.22),
        (659.25, beat * 0.5, 0.22),
        (783.99, beat * 1.0, 0.22),
        (659.25, beat * 1.5, 0.18),
        (587.33, beat * 2.0, 0.22),
        (659.25, beat * 2.5, 0.18),
        (523.25, beat * 3.0, 0.35),
        (523.25, bar + 0.0, 0.22),
        (587.33, bar + beat * 0.5, 0.22),
        (659.25, bar + beat * 1.0, 0.22),
        (783.99, bar + beat * 1.5, 0.28),
        (659.25, bar + beat * 2.5, 0.22),
        (587.33, bar + beat * 3.0, 0.35),
    ]

    total = bar * 4
    n = int(SR * total)
    tracks = []

    for roots in progressions:
        for f, st in roots:
            tracks.append(note_at(f / 2, st, beat * 3.5, vol=0.14, wave_fn=sine))

    for f, st, dur in melody:
        tracks.append(note_at(f, st, dur, vol=0.11, wave_fn=tri))
        tracks.append(note_at(f / 2, st + 0.02, dur * 0.9, vol=0.06, wave_fn=sine))

    for b in range(16):
        t = b * beat
        tracks.append(drum_kick(t))
        if b % 2 == 1:
            tracks.append(drum_snare(t))
        tracks.append(drum_hat(t + beat * 0.5))

    mixed = mix(*tracks)
    return mixed[:n]


def generate_game_loop() -> list[float]:
    """Maç içi — daha hafif, gerilim + enerji, ~12 sn."""
    bpm = 128
    beat = 60.0 / bpm
    bar = beat * 4
    total = bar * 2
    n = int(SR * total)
    tracks = []

    bass_pattern = [110.0, 110.0, 130.81, 98.0]
    for i, f in enumerate(bass_pattern):
        tracks.append(note_at(f, i * beat, beat * 0.85, vol=0.16, wave_fn=sine))

    pulse_notes = [
        (440, 0.0), (554.37, beat), (659.25, beat * 2), (554.37, beat * 3),
        (493.88, bar), (587.33, bar + beat), (659.25, bar + beat * 2), (587.33, bar + beat * 3),
    ]
    for f, st in pulse_notes:
        tracks.append(note_at(f, st, beat * 0.35, vol=0.07, wave_fn=tri))

    for b in range(8):
        t = b * beat
        tracks.append(drum_kick(t))
        if b % 2 == 1:
            tracks.append(drum_snare(t))
        tracks.append(drum_hat(t + beat * 0.5))

    mixed = mix(*tracks)
    return mixed[:n]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    write_wav(OUT / "menu.wav", generate_menu_loop())
    write_wav(OUT / "game.wav", generate_game_loop())
    write_wav(OUT / "shot.wav", generate_shot())
    write_wav(OUT / "hit.wav", generate_hit())
    write_wav(OUT / "win.wav", generate_win())
    write_wav(OUT / "lose.wav", generate_lose())
    print(f"Generated sounds in {OUT}")


if __name__ == "__main__":
    main()
