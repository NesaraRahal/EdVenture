#!/usr/bin/env python3
"""
Generate lightweight WAV sound effects for EdVenture.
No external deps required.
"""

import math
import wave
import struct
from pathlib import Path

SAMPLE_RATE = 44100


def adsr_envelope(i, total):
    t = i / max(total, 1)
    attack = 0.06
    decay = 0.12
    sustain = 0.78
    release = 0.22

    if t < attack:
        return t / attack
    if t < attack + decay:
        p = (t - attack) / decay
        return 1.0 - p * (1.0 - sustain)
    if t < 1.0 - release:
        return sustain
    p = (t - (1.0 - release)) / release
    return sustain * (1.0 - p)


def tone(freq, duration, volume=0.45, phase=0.0):
    n = int(SAMPLE_RATE * duration)
    out = []
    for i in range(n):
        env = adsr_envelope(i, n)
        s = math.sin(2 * math.pi * freq * i / SAMPLE_RATE + phase)
        out.append(s * env * volume)
    return out


def noise(duration, volume=0.15):
    # deterministic pseudo-noise from sine chaos (no random import needed)
    n = int(SAMPLE_RATE * duration)
    out = []
    x = 0.12345
    for i in range(n):
        x = (x * 3.987654321 + 0.123456789) % 1.0
        v = (x * 2.0 - 1.0)
        env = adsr_envelope(i, n)
        out.append(v * env * volume)
    return out


def mix(*tracks):
    size = max((len(t) for t in tracks), default=0)
    out = [0.0] * size
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    # soft clip
    for i, v in enumerate(out):
        out[i] = math.tanh(v)
    return out


def write_wav(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in data:
            s = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(s * 32767))
        wf.writeframes(frames)


def generate_click():
    return mix(
        tone(1400, 0.06, 0.25),
        tone(2100, 0.05, 0.18, phase=0.3),
        noise(0.035, 0.06),
    )


def generate_hint():
    a = tone(880, 0.10, 0.24)
    b = tone(1174.66, 0.12, 0.22)
    gap = [0.0] * int(0.025 * SAMPLE_RATE)
    return a + gap + b


def generate_correct():
    n1 = tone(523.25, 0.11, 0.22)
    n2 = tone(659.25, 0.11, 0.22)
    n3 = tone(783.99, 0.14, 0.22)
    gap = [0.0] * int(0.018 * SAMPLE_RATE)
    return n1 + gap + n2 + gap + n3


def generate_wrong():
    n1 = tone(440.0, 0.12, 0.24)
    n2 = tone(349.23, 0.16, 0.24)
    gap = [0.0] * int(0.012 * SAMPLE_RATE)
    return mix(n1 + gap + n2, noise(0.30, 0.03))


def generate_next():
    return mix(
        tone(760, 0.08, 0.22),
        tone(1020, 0.09, 0.20),
    )


def main():
    root = Path(__file__).resolve().parents[1]
    out = root / "EdVenture" / "Resources" / "SFX"

    sounds = {
        "ui_click.wav": generate_click(),
        "ui_hint.wav": generate_hint(),
        "ui_correct.wav": generate_correct(),
        "ui_wrong.wav": generate_wrong(),
        "ui_next.wav": generate_next(),
    }

    for name, data in sounds.items():
        write_wav(out / name, data)
        print(f"generated: {out / name}")


if __name__ == "__main__":
    main()
