#!/usr/bin/env python3
"""Overhead - INTRO: beats 1 + 2-3 joined as one continuous shot.
Radar scan (live) -> continuous zoom INTO the coral dot -> morph to ac_b777
-> zoom OUT to hand off to the app map. No quick card.
"""
import os
from PIL import Image, ImageDraw, ImageFilter
import common
import render_beat01 as b01
import render_beat23 as b23

W, H = 1920, 1080
FPS = 60
OUT = os.path.join(os.path.dirname(__file__), "overhead-intro.mp4")
NAVY = (10, 15, 26)
CORAL_W = (b01.CORAL_TX, b01.CORAL_TY)   # coral dot world position in the scan

# phase boundaries (seconds)
T_SCAN = 4.8      # live scan up to here
T_ZOOM = 7.0      # zoom into coral completes
T_MORPH = 7.5     # 777 fully resolved
T_HOLD = 8.1      # hold on the plane
T_OUT = 9.9       # zoom out to app handoff
DUR = 9.9

def clamp01(v): return 0.0 if v < 0 else 1.0 if v > 1 else v
def lerp(a, b, k): return a + (b - a) * k

_frozen = None
def frozen():
    global _frozen
    if _frozen is None:
        _frozen = b01.frame(T_SCAN).convert("RGB")
    return _frozen

def frame(t):
    if t <= T_SCAN:
        return b01.frame(t)

    base = frozen()
    zk = b23.eio(clamp01((t - T_SCAN) / (T_ZOOM - T_SCAN)))
    smax = 7.0
    s = 1 + (smax - 1) * zk
    cw, ch = W / s, H / s
    cx = lerp(W/2, CORAL_W[0], zk); cy = lerp(H/2, CORAL_W[1], zk)
    left = min(max(cx - cw/2, 0), W - cw)
    top = min(max(cy - ch/2, 0), H - ch)
    img = base.crop((left, top, left+cw, top+ch)).resize((W, H), Image.LANCZOS).convert("RGBA")

    # coral's on-screen position after the crop-zoom
    sx = (CORAL_W[0] - left) * (W / cw)
    sy = (CORAL_W[1] - top) * (H / ch)

    # fade the zoomed scene toward navy as the plane resolves (kills stray glow)
    fade = clamp01((t - (T_SCAN + 1.0)) / 1.4)
    if fade > 0:
        nav = Image.new("RGBA", (W, H), NAVY + (int(255 * fade),))
        img = Image.alpha_composite(img, nav)

    morph = clamp01((t - (T_SCAN + 0.9)) / (T_MORPH - (T_SCAN + 0.9)))
    out = clamp01((t - T_HOLD) / (T_OUT - T_HOLD))

    # zoom-out handoff: faint map grid fades in behind the plane
    if out > 0:
        grid = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        gd = ImageDraw.Draw(grid)
        a = int(45 * out)
        for gx in range(0, W, 120): gd.line([(gx, 0), (gx, H)], fill=(115, 184, 235, a), width=1)
        for gy in range(0, H, 120): gd.line([(0, gy), (W, gy)], fill=(115, 184, 235, a), width=1)
        img = Image.alpha_composite(img, grid)

    # morph: coral -> 777 (coral tint resolves to natural), centered on the coral
    if morph > 0:
        drift = -b23.ein(out) * (H * 0.10)                 # slight upward drift on exit
        pscale = (0.3 + 0.85 * b23.eout(morph)) * (1.0 - 0.86 * b23.eio(out))
        tint = 1 - clamp01(morph * 1.2)
        alpha = clamp01(morph / 0.3)
        pl = b23.plane_layer(pscale, tint, alpha)
        gl = pl.filter(ImageFilter.GaussianBlur(16))
        px = int(lerp(sx, W/2, morph)); py = int(lerp(sy, H/2, morph) + drift)
        img.alpha_composite(gl, (px - gl.width//2, py - gl.height//2))
        img.alpha_composite(pl, (px - pl.width//2, py - pl.height//2))

    return img.convert("RGB")

if __name__ == "__main__":
    common.render(OUT, FPS, frame, int(DUR * FPS))
