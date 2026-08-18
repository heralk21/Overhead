#!/usr/bin/env python3
"""LED dot-matrix section headings (transparent PNG) - the app's LEDLabel style.
Drop between/over beats as section titles. Animate: dots flicker/type on, hold, cut.
"""
import os
import led

OUTDIR = os.path.join(os.path.dirname(__file__), "headings")
os.makedirs(OUTDIR, exist_ok=True)
LED = (115, 184, 235)
CYAN = (97, 204, 245)

HEADINGS = [
    ("live-airspace", "LIVE AIRSPACE", LED),
    ("tap-to-know",   "TAP TO KNOW",   LED),
    ("the-details",   "THE DETAILS",   CYAN),
    ("from-anywhere", "FROM ANYWHERE", LED),
    ("on-your-wrist", "ON YOUR WRIST", LED),
    ("overhead",      "OVERHEAD",      LED),
]

if __name__ == "__main__":
    for name, text, col in HEADINGS:
        img = led.render(text, pitch=16, color=col, off=True)
        p = os.path.join(OUTDIR, f"led-{name}.png")
        img.save(p)
        print("wrote", p, img.size)
