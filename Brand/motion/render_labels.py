#!/usr/bin/env python3
"""Overhead - kinetic-type label overlays (transparent PNG) for the recordings.
Lower-left lockup: LED-blue accent bar + white SF title + LED-blue mono subtitle.
Drop onto footage in CapCut/Resolve and animate (fade + 20px slide-up).
"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1920, 1080
OUTDIR = os.path.join(os.path.dirname(__file__), "labels")
os.makedirs(OUTDIR, exist_ok=True)
LED = (115, 184, 235)
WHITE = (234, 243, 251)

def font(path, size):
    try: return ImageFont.truetype(path, size)
    except Exception: return ImageFont.load_default()
F_TITLE = font("/System/Library/Fonts/SFNS.ttf", 52)
F_SUB = font("/System/Library/Fonts/SFNSMono.ttf", 24)

LABELS = [
    ("beat3-led",       "LED callsign",  "AIRPORT-BOARD HIERARCHY"),
    ("beat3-telemetry", "Altitude · speed · heading", "ONE COLUMN, LIKE A BOARD"),
    ("beat4-longpress", "Long-press",    "SPECS, ON PURPOSE"),
    ("beat4-sheet",     "60% sheet",     "THE MAP NEVER LEAVES"),
    ("beat5-widget",    "Nearest flight","STRAIGHT FROM YOUR HOME SCREEN"),
    ("beat5-watch",     "On your wrist", "THE SAME LED GLANCE"),
]

def tracked(d, xy, text, fnt, fill, track):
    x, y = xy
    for ch in text:
        d.text((x, y), ch, font=fnt, fill=fill)
        x += fnt.getlength(ch) + track
    return x

def make(name, title, sub):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x0, y0 = 150, H - 250
    # accent bar
    d.rounded_rectangle([x0, y0, x0+5, y0+96], radius=2, fill=LED+(255,))
    tx = x0 + 30
    # subtle glow for legibility over bright footage
    gl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gl)
    gd.text((tx, y0-4), title, font=F_TITLE, fill=(0, 0, 0, 200))
    tracked(gd, (tx, y0+66), sub, F_SUB, (0, 0, 0, 200), 6)
    gl = gl.filter(ImageFilter.GaussianBlur(7))
    img = Image.alpha_composite(img, gl)
    d = ImageDraw.Draw(img)
    d.text((tx, y0-4), title, font=F_TITLE, fill=WHITE+(255,))
    tracked(d, (tx, y0+66), sub, F_SUB, LED+(255,), 6)
    p = os.path.join(OUTDIR, f"label-{name}.png")
    img.save(p)
    return p

if __name__ == "__main__":
    for n, t, s in LABELS:
        print("wrote", make(n, t, s))
