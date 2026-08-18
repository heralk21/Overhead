#!/usr/bin/env python3
"""Overhead - Beat 6 (logo resolution) motion sting -> MP4.
Deterministic frame renderer. Geometry parsed from OverHeadLogo.png.
"""
import math, random, os
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont
import common

# ---- config ----
W, H = 1920, 1080
FPS = 60
DUR = 5.6
OUT = os.path.join(os.path.dirname(__file__), "overhead-logo-beat6.mp4")
NAVY = (10, 15, 26)

# logo placement
CX, CY = W * 0.30, H * 0.5
R = min(H * 0.36, W * 0.20)
SZ = R * 0.052                      # dot radius reference (full)
random.seed(42)

# ring: 24 dots, coral at ~332 deg
RN = 24
CORAL_ANGLE = 332
ring = []
for i in range(RN):
    deg = i * (360.0 / RN) + 1
    a = math.radians(deg)
    coral = abs(((deg - CORAL_ANGLE + 540) % 360) - 180) < 8
    ex = CX + math.cos(a) * R
    ey = CY + math.sin(a) * R
    sx = random.uniform(0, W)
    sy = random.uniform(0, H)
    if coral:
        col, op = (235, 72, 72), 1.0
    elif i % 2:
        col, op = (63, 110, 153), 0.6
    else:
        col, op = (115, 184, 235), 0.95
    delay = 0.55 if coral else i * 0.012
    ring.append(dict(sx=sx, sy=sy, ex=ex, ey=ey, col=col, op=op, delay=delay))

# plane: 16 white dots (swept-wing jet, centered), offsets in units of R
PLANE = [(-0.008,-0.486),(-0.008,-0.323),(-0.008,-0.165),(-0.008,-0.009),
         (-0.008,0.138),(-0.008,0.283),(-0.008,0.423),(-0.137,-0.108),
         (0.122,-0.108),(-0.259,-0.046),(0.241,-0.046),(-0.376,0.011),
         (0.358,0.011),(-0.124,0.535),(-0.008,0.535),(0.109,0.535)]

# ---- easing (cubic-bezier solver) ----
def _cb(t, p1, p2):
    return 3*p1*(1-t)**2*t + 3*p2*(1-t)*t*t + t**3
def bezier(x, x1, y1, x2, y2):
    if x <= 0: return 0.0
    if x >= 1: return 1.0
    lo, hi = 0.0, 1.0
    for _ in range(24):
        mid = (lo + hi) / 2
        if _cb(mid, x1, x2) < x: lo = mid
        else: hi = mid
    return _cb((lo + hi) / 2, y1, y2)
def out_cubic(x):  # for scatter->ring (approx of .2,.85,.25,1)
    return bezier(clamp01(x), .2, .85, .25, 1)
def out_soft(x):
    return bezier(clamp01(x), .2, .9, .2, 1)
def clamp01(v): return 0.0 if v < 0 else 1.0 if v > 1 else v

# ---- fonts (SF) ----
def load_font(size):
    for p in ("/System/Library/Fonts/SFNS.ttf",
              "/System/Library/Fonts/HelveticaNeue.ttc",
              "/System/Library/Fonts/Helvetica.ttc"):
        try: return ImageFont.truetype(p, size)
        except Exception: pass
    return ImageFont.load_default()
F_WORD = load_font(84)
F_TAG = load_font(26)

def draw_tracked(draw, xy, text, font, fill, tracking, alpha):
    x, y = xy
    r, g, b = fill
    for ch in text:
        draw.text((x, y), ch, font=font, fill=(r, g, b, int(255 * alpha)))
        x += font.getlength(ch) + tracking
    return x

def tracked_width(text, font, tracking):
    return sum(font.getlength(c) + tracking for c in text) - tracking

def disc(draw, cx, cy, rad, col, alpha):
    a = int(255 * clamp01(alpha))
    if a <= 0 or rad <= 0: return
    draw.ellipse([cx-rad, cy-rad, cx+rad, cy+rad], fill=(col[0], col[1], col[2], a))

# ---- render ----
def frame(t):
    base = Image.new("RGB", (W, H), NAVY)
    # glow layer at half res (cheap blur), on black -> screen blend
    gw, gh = W // 2, H // 2
    glow = Image.new("RGB", (gw, gh), (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    core = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(core)

    # ring dots
    for d in ring:
        fade = clamp01(t / 0.5)
        if fade <= 0: continue
        mv = out_cubic((t - (0.48 + d["delay"])) / 1.25)
        x = d["sx"] + (d["ex"] - d["sx"]) * mv
        y = d["sy"] + (d["ey"] - d["sy"]) * mv
        op = d["op"] * fade
        gd.ellipse([(x-SZ*1.0)/2, (y-SZ*1.0)/2, (x+SZ*1.0)/2, (y+SZ*1.0)/2],
                   fill=(int(d["col"][0]*op), int(d["col"][1]*op), int(d["col"][2]*op)))
        disc(cd, x, y, SZ*0.5, d["col"], op)
        disc(cd, x, y, SZ*0.22, (255, 255, 255), op*0.7)

    # plane dots (bloom in place)
    for (ox, oy) in PLANE:
        dist = math.hypot(ox, oy)
        appear = 1.9 + dist * 0.5
        p = out_soft((t - appear) / 0.55)
        if p <= 0: continue
        scale = 0.2 + 0.8 * p
        x = CX + ox * R
        y = CY + oy * R
        rad = SZ * 0.5 * scale
        col = (242, 247, 252)
        gd.ellipse([(x-SZ*0.9)/2, (y-SZ*0.9)/2, (x+SZ*0.9)/2, (y+SZ*0.9)/2],
                   fill=(int(200*p), int(220*p), int(240*p)))
        disc(cd, x, y, rad, col, p)

    glow = glow.filter(ImageFilter.GaussianBlur(radius=SZ*0.85))
    glow = glow.resize((W, H), Image.BILINEAR)
    frame_img = ImageChops.screen(base, glow).convert("RGBA")
    frame_img = Image.alpha_composite(frame_img, core)

    # text layer
    txt = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    td = ImageDraw.Draw(txt)
    word_x0 = W * 0.545
    wtrack = int(84 * 0.16)
    wfade = clamp01((t - 2.75) / 0.8)
    if wfade > 0:
        we = out_soft(wfade)
        xoff = -40 * (1 - we)
        block_h = 84 + 26 + 30
        wy = CY - block_h/2
        draw_tracked(td, (word_x0 + xoff, wy), "OVERHEAD", F_WORD,
                     (234, 243, 251), wtrack, we)
        tfade = clamp01((t - 3.2) / 0.9)
        if tfade > 0:
            ttrack = int(26 * 0.28)
            ty = wy + 84 + 34
            draw_tracked(td, (word_x0 + xoff, ty), "YOU SEE IT BEFORE YOU HEAR IT",
                         F_TAG, (115, 184, 235), ttrack, out_soft(tfade))
    # soft glow on text
    tglow = txt.filter(ImageFilter.GaussianBlur(6))
    frame_img = Image.alpha_composite(frame_img, tglow)
    frame_img = Image.alpha_composite(frame_img, txt)
    return frame_img.convert("RGB")

if __name__ == "__main__":
    common.render(OUT, FPS, frame, int(DUR * FPS))
