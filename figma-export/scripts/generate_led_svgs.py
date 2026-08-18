#!/usr/bin/env python3
"""Generate LED dot-matrix SVG characters and words from the app's FONT glyph table."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHARS_DIR = ROOT / "led-font" / "chars"
WORDS_DIR = ROOT / "led-font" / "words"

# Extracted from ContentView.swift — keep in sync with FONT constant
FONT: dict[str, list[int]] = {
    " ": [0, 0, 0, 0, 0, 0, 0],
    "A": [14, 17, 17, 31, 17, 17, 17],
    "B": [30, 17, 17, 30, 17, 17, 30],
    "C": [14, 17, 16, 16, 16, 17, 14],
    "D": [28, 18, 17, 17, 17, 18, 28],
    "E": [31, 16, 16, 30, 16, 16, 31],
    "F": [31, 16, 16, 30, 16, 16, 16],
    "G": [14, 17, 16, 23, 17, 17, 14],
    "H": [17, 17, 17, 31, 17, 17, 17],
    "I": [14, 4, 4, 4, 4, 4, 14],
    "J": [7, 2, 2, 2, 2, 18, 12],
    "K": [17, 18, 20, 24, 20, 18, 17],
    "L": [16, 16, 16, 16, 16, 16, 31],
    "M": [17, 27, 21, 21, 17, 17, 17],
    "N": [17, 25, 21, 19, 17, 17, 17],
    "O": [14, 17, 17, 17, 17, 17, 14],
    "P": [30, 17, 17, 30, 16, 16, 16],
    "Q": [14, 17, 17, 17, 21, 18, 13],
    "R": [30, 17, 17, 30, 20, 18, 17],
    "S": [15, 16, 16, 14, 1, 1, 30],
    "T": [31, 4, 4, 4, 4, 4, 4],
    "U": [17, 17, 17, 17, 17, 17, 14],
    "V": [17, 17, 17, 17, 10, 10, 4],
    "W": [17, 17, 17, 21, 21, 27, 17],
    "X": [17, 17, 10, 4, 10, 17, 17],
    "Y": [17, 17, 10, 4, 4, 4, 4],
    "Z": [31, 1, 2, 4, 8, 16, 31],
    "0": [14, 17, 19, 21, 25, 17, 14],
    "1": [4, 12, 4, 4, 4, 4, 14],
    "2": [14, 17, 1, 2, 4, 8, 31],
    "3": [31, 2, 4, 2, 1, 17, 14],
    "4": [2, 6, 10, 18, 31, 2, 2],
    "5": [31, 16, 30, 1, 1, 17, 14],
    "6": [6, 8, 16, 30, 17, 17, 14],
    "7": [31, 1, 2, 4, 8, 8, 8],
    "8": [14, 17, 17, 14, 17, 17, 14],
    "9": [14, 17, 17, 15, 1, 2, 12],
    ".": [0, 0, 0, 0, 0, 4, 4],
    ":": [0, 4, 4, 0, 4, 4, 0],
    "-": [0, 0, 0, 31, 0, 0, 0],
    "/": [1, 2, 4, 8, 16, 0, 0],
    ",": [0, 0, 0, 0, 4, 4, 8],
}

COLS = 5
ROWS = 7
GLYPH_STEP = 6  # 5 cols + 1 gap

# App color tokens
COLORS = {
    "white": "#FFFFFF",
    "led-blue": "#73B8EB",
    "coral": "#EB4747",
    "climb": "#61D194",
    "dim": "rgba(255,255,255,0.07)",
    "dim-led-blue": "rgba(115,184,235,0.07)",
}


def safe_filename(ch: str) -> str:
    if ch == " ":
        return "space"
    if ch == ".":
        return "period"
    if ch == ":":
        return "colon"
    if ch == "-":
        return "hyphen"
    if ch == "/":
        return "slash"
    if ch == ",":
        return "comma"
    return ch.upper() if ch.isalpha() else ch


def glyph_dots(ch: str, dimmed: bool, color_on: str, color_dim: str) -> list[str]:
    g = FONT.get(ch) or FONT.get(ch.upper(), FONT[" "])
    dots: list[str] = []
    for row in range(ROWS):
        for col in range(COLS):
            lit = (g[row] & (1 << (4 - col))) != 0
            if lit:
                dots.append(f'<circle cx="{col}" cy="{row}" r="0.38" fill="{color_on}"/>')
            elif dimmed:
                dots.append(f'<circle cx="{col}" cy="{row}" r="0.20" fill="{color_dim}"/>')
    return dots


def char_svg(ch: str, dimmed: bool = True, color: str = "white") -> str:
    color_on = COLORS[color]
    color_dim = COLORS["dim"] if color == "white" else COLORS["dim-led-blue"]
    w = GLYPH_STEP
    h = ROWS
    dots = glyph_dots(ch, dimmed, color_on, color_dim)
    label = safe_filename(ch)
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w * 10}" height="{h * 10}">
  <title>LED / {label}</title>
  <g transform="translate(0.5, 0.5)">
    {''.join(dots)}
  </g>
</svg>
"""


def word_svg(
    text: str,
    dot_pt: float,
    dimmed: bool = True,
    color: str = "white",
    name: str | None = None,
) -> str:
    color_on = COLORS[color]
    color_dim = COLORS["dim"] if color == "white" else COLORS["dim-led-blue"]
    r_on = dot_pt * 0.38
    r_dim = r_on * 0.52

    circles: list[str] = []
    cx_offset = 0.0
    for ch in text.upper():
        g = FONT.get(ch) or FONT.get(ch.upper(), FONT[" "])
        for row in range(ROWS):
            for col in range(COLS):
                x = cx_offset + col * dot_pt + r_on
                y = row * dot_pt + r_on
                lit = (g[row] & (1 << (4 - col))) != 0
                if lit:
                    circles.append(
                        f'<circle cx="{x:.3f}" cy="{y:.3f}" r="{r_on:.3f}" fill="{color_on}"/>'
                    )
                elif dimmed:
                    circles.append(
                        f'<circle cx="{x:.3f}" cy="{y:.3f}" r="{r_dim:.3f}" fill="{color_dim}"/>'
                    )
        cx_offset += GLYPH_STEP * dot_pt

    width = len(text) * GLYPH_STEP * dot_pt
    height = ROWS * dot_pt
    slug = name or re.sub(r"[^A-Za-z0-9]+", "-", text).strip("-").lower()
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width:.2f} {height:.2f}" width="{width:.1f}" height="{height:.1f}">
  <title>LED Word / {slug} / {dot_pt}pt</title>
  {''.join(circles)}
</svg>
"""


# Words used across screens, keyed by (text, dot_pt, dimmed, color)
WORD_PRESETS: list[tuple[str, float, bool, str, str]] = [
    # Quick card
    ("ACA873", 6.5, False, "white", "quick-callsign-aca873"),
    ("WJA158", 6.5, False, "white", "quick-callsign-wja158"),
    # Board
    ("FLIGHTS", 3.0, False, "white", "board-title"),
    ("ACA873", 2.0, False, "led-blue", "board-callsign-aca873"),
    ("WJA158", 2.0, False, "led-blue", "board-callsign-wja158"),
    ("DAL412", 2.0, False, "led-blue", "board-callsign-dal412"),
    ("UAL892", 2.0, False, "led-blue", "board-callsign-ual892"),
    ("SWA2847", 2.0, False, "led-blue", "board-callsign-swa2847"),
    # Detail spec labels
    ("TYPE", 2.2, True, "led-blue", "spec-type"),
    ("REGISTRATION", 2.2, True, "led-blue", "spec-registration"),
    ("FIRST FLIGHT", 2.2, True, "led-blue", "spec-first-flight"),
    ("CAPACITY", 2.2, True, "led-blue", "spec-capacity"),
    ("ENGINES", 2.2, True, "led-blue", "spec-engines"),
    ("WINGSPAN", 2.2, True, "led-blue", "spec-wingspan"),
    ("RANGE", 2.2, True, "led-blue", "spec-range"),
    ("MAX SPEED", 2.2, True, "led-blue", "spec-max-speed"),
    ("CATEGORY", 2.2, True, "led-blue", "spec-category"),
    # Overlays
    ("SCANNING AIRSPACE", 1.9, False, "led-blue", "scanning-overlay"),
    # Widget
    ("SCAN", 2.0, False, "led-blue", "widget-scan"),
    ("AIRSPACE", 2.0, False, "white", "widget-airspace"),
    ("SCANNING", 2.0, False, "led-blue", "widget-scanning"),
    # Watch
    ("RADAR", 2.0, False, "led-blue", "watch-radar"),
    ("TAP SCAN", 2.0, True, "white", "watch-tap-scan"),
    ("NO SIGNAL", 2.0, True, "white", "watch-no-signal"),
    ("TAP RETRY", 2.0, True, "white", "watch-tap-retry"),
    ("YVR > YYZ", 2.0, False, "climb", "watch-route"),
    ("A:35KFT", 2.0, False, "led-blue", "watch-altitude"),
    ("S:480KT", 2.0, False, "led-blue", "watch-speed"),
]


def main() -> None:
    CHARS_DIR.mkdir(parents=True, exist_ok=True)
    WORDS_DIR.mkdir(parents=True, exist_ok=True)

    char_manifest = []
    for ch in sorted(FONT.keys(), key=lambda c: (not c.isalnum(), c)):
        for variant in [("dim-white", True, "white"), ("solid-white", False, "white"), ("solid-led-blue", False, "led-blue")]:
            suffix, dimmed, color = variant
            fname = f"{safe_filename(ch)}-{suffix}.svg"
            path = CHARS_DIR / fname
            path.write_text(char_svg(ch, dimmed=dimmed, color=color), encoding="utf-8")
            char_manifest.append({
                "file": f"led-font/chars/{fname}",
                "character": ch,
                "variant": suffix,
                "dimmed": dimmed,
                "color": color,
                "figmaComponent": f"LED/Char/{safe_filename(ch)}/{suffix}",
            })

    word_manifest = []
    for text, dot_pt, dimmed, color, name in WORD_PRESETS:
        fname = f"{name}-{dot_pt}pt.svg"
        path = WORDS_DIR / fname
        path.write_text(word_svg(text, dot_pt, dimmed, color, name), encoding="utf-8")
        word_manifest.append({
            "file": f"led-font/words/{fname}",
            "text": text,
            "dotPt": dot_pt,
            "dimmed": dimmed,
            "color": color,
            "frameHeight": round(ROWS * dot_pt, 1),
            "figmaComponent": f"LED/Word/{name}",
        })

    meta = {
        "generatedBy": "figma-export/scripts/generate_led_svgs.py",
        "glyphGrid": {"cols": COLS, "rows": ROWS, "charStep": GLYPH_STEP},
        "dotRadiusFormula": "r = dotPt × 0.38 (lit), r = dotPt × 0.38 × 0.52 (dimmed)",
        "colors": COLORS,
        "characters": char_manifest,
        "words": word_manifest,
    }
    (ROOT / "led-font" / "manifest.json").write_text(
        json.dumps(meta, indent=2), encoding="utf-8"
    )
    print(f"Generated {len(char_manifest)} char SVGs, {len(word_manifest)} word SVGs")


if __name__ == "__main__":
    main()
