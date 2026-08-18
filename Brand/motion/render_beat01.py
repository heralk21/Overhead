#!/usr/bin/env python3
"""Overhead - Beats 0-1 (cold open + airspace scan) -> MP4.
Cold open: coral dot drifts across black with the hook line.
Scan: radar sweep ignites LED-blue aircraft dots; 'SCANNING AIRSPACE' label.
"""
import math, random, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont
import common, led

SCAN_LED = led.render("SCANNING AIRSPACE", pitch=8, color=(115, 184, 235))

W, H = 1920, 1080
FPS = 60
DUR = 6.2
OUT = os.path.join(os.path.dirname(__file__), "overhead-scan-beat01.mp4")
NAVY = (10, 15, 26)
CX, CY = W * 0.5, H * 0.5
random.seed(7)

def clamp01(v): return 0.0 if v < 0 else 1.0 if v > 1 else v
def _cb(t, p1, p2): return 3*p1*(1-t)**2*t + 3*p2*(1-t)*t*t + t**3
def bez(x, x1, y1, x2, y2):
    x = clamp01(x)
    if x <= 0: return 0.0
    if x >= 1: return 1.0
    lo, hi = 0.0, 1.0
    for _ in range(22):
        m = (lo+hi)/2
        if _cb(m, x1, x2) < x: lo = m
        else: hi = m
    return _cb((lo+hi)/2, y1, y2)
def ease(x): return bez(x, .25, .9, .25, 1)
def eio(x): return bez(x, .45, 0, .55, 1)

def font(path, size):
    try: return ImageFont.truetype(path, size)
    except Exception: return ImageFont.load_default()
F_HOOK = font("/System/Library/Fonts/SFNS.ttf", 58)
F_SCAN = font("/System/Library/Fonts/SFNSMono.ttf", 24)

def tracked(draw, xy, text, fnt, fill, track, alpha, center=None):
    w = sum(fnt.getlength(c)+track for c in text) - track
    x, y = xy
    if center is not None: x = center - w/2
    a = int(255*clamp01(alpha))
    for ch in text:
        draw.text((x, y), ch, font=fnt, fill=(fill[0], fill[1], fill[2], a))
        x += fnt.getlength(ch)+track
    return w

# the coral plane parks upper-right (single tracked aircraft, echoes logo coral)
CORAL_TX, CORAL_TY = 1119, 336
# blue aircraft dots ignite around it as the sweep passes
craft = []
for k in range(14):
    ang = random.uniform(0, 360)
    rad = random.uniform(H*0.16, H*0.42)
    craft.append(dict(ang=ang, rad=rad, big=random.random() < .35))
for c in craft:
    afs = (c["ang"] - 270) % 360
    c["ignite"] = 2.55 + 2.45*(afs/360.0)

def disc(d, x, y, r, col, a):
    a = int(255*clamp01(a))
    if a <= 0 or r <= 0: return
    d.ellipse([x-r, y-r, x+r, y+r], fill=(col[0], col[1], col[2], a))

def frame(t):
    base = Image.new("RGB", (W, H), (0, 0, 0))
    # fade black -> navy
    nav = ease(clamp01(t/0.7))
    base = Image.new("RGB", (W, H), (int(NAVY[0]*nav), int(NAVY[1]*nav), int(NAVY[2]*nav)))
    gw, gh = W//2, H//2
    glow = Image.new("RGB", (gw, gh), (0, 0, 0)); gd = ImageDraw.Draw(glow)
    core = Image.new("RGBA", (W, H), (0, 0, 0, 0)); cd = ImageDraw.Draw(core)

    # --- coral plane: flies in from left, parks upper-right, holds ---
    dprog = clamp01((t-0.3)/2.1)
    sx0, sy0 = W*0.12, H*0.30
    coral_x = sx0 + (CORAL_TX-sx0)*eio(dprog)
    coral_y = sy0 + (CORAL_TY-sy0)*eio(dprog)
    if dprog >= 1: coral_y += math.sin(t*2.2)*4   # gentle parked bob
    cop = clamp01((t-0.3)/0.5)
    moving = dprog < 1
    if moving:
        for tr in range(6):
            tx = coral_x - tr*16
            disc(cd, tx, coral_y, 6-tr*0.7, (235,72,72), cop*(0.5-tr*0.08))
    gd.ellipse([(coral_x-28)/2,(coral_y-28)/2,(coral_x+28)/2,(coral_y+28)/2], fill=(int(130*cop),int(32*cop),int(32*cop)))
    disc(cd, coral_x, coral_y, 8, (235,72,72), cop)
    disc(cd, coral_x, coral_y, 3.5, (255,220,215), cop*0.9)
    lock = clamp01((t-4.7)/0.5)   # 'locked' ring once scan resolves
    if lock > 0:
        cd.ellipse([coral_x-20, coral_y-20, coral_x+20, coral_y+20], outline=(235,120,120,int(150*lock)), width=2)

    # --- scan phase ---
    scan_on = clamp01((t-2.4)/0.5)
    # expanding rings
    if scan_on > 0:
        for ri in range(4):
            rp = ((t-2.4)/1.6 + ri*0.25) % 1.0
            rr = rp*H*0.5
            ra = (1-rp)*0.5*scan_on
            if ra > 0.02:
                col = (int(115*ra*2), int(184*ra*2), int(235*ra*2))
                col = tuple(min(255,c) for c in col)
                gd.ellipse([(CX-rr)/2,(CY-rr)/2,(CX+rr)/2,(CY+rr)/2], outline=col, width=2)
        # rotating sweep (fan of fading spokes)
        sp = eio(clamp01((t-2.55)/2.45))
        lead = math.radians(270 + 360*sp)
        for j in range(28):
            frac = j/28.0
            aa = lead - math.radians(70)*frac
            al = (1-frac)*0.5*scan_on
            ex = CX+math.cos(aa)*H*0.46; ey = CY+math.sin(aa)*H*0.46
            gd.line([CX/2, CY/2, ex/2, ey/2], fill=(int(90*al),int(150*al),int(200*al)), width=2)

    # 'you' marker at center
    yop = clamp01((t-2.35)/0.4)*clamp01((5.6-t)/0.6)
    if yop > 0:
        pr = 0.5+0.5*math.sin(t*4)
        disc(cd, CX, CY, 5, (240,246,252), yop)
        gd.ellipse([(CX-30)/2,(CY-30)/2,(CX+30)/2,(CY+30)/2], outline=(int(120*yop),int(150*yop),int(180*yop)), width=2)
        rr = 16+pr*8
        cd.ellipse([CX-rr,CY-rr,CX+rr,CY+rr], outline=(200,220,240,int(90*yop)), width=2)

    # aircraft dots ignite as sweep passes
    for c in craft:
        lit = clamp01((t-c["ignite"])/0.35)
        if lit <= 0: continue
        flash = clamp01(1-(t-c["ignite"])/0.2)
        x = CX+math.cos(math.radians(c["ang"]))*c["rad"]
        y = CY+math.sin(math.radians(c["ang"]))*c["rad"]
        col = (115,184,235)
        base_a = (0.9 if c["big"] else 0.6)*lit
        g = base_a + flash*0.8
        gsz = 30 if c["big"] else 22
        gd.ellipse([(x-gsz)/2,(y-gsz)/2,(x+gsz)/2,(y+gsz)/2], fill=(min(255,int(col[0]*g)),min(255,int(col[1]*g)),min(255,int(col[2]*g))))
        disc(cd, x, y, 7 if c["big"] else 5, col, base_a+flash*0.5)
        disc(cd, x, y, 2.6, (255,255,255), (base_a)*0.7+flash*0.6)

    glow = glow.filter(ImageFilter.GaussianBlur(12)).resize((W, H), Image.BILINEAR)
    img = ImageChops.screen(base, glow).convert("RGBA")
    img = Image.alpha_composite(img, core)

    # --- text ---
    txt = Image.new("RGBA", (W, H), (0, 0, 0, 0)); td = ImageDraw.Draw(txt)
    hook_a = clamp01((t-0.9)/0.7) * clamp01((2.55-t)/0.5)
    if hook_a > 0:
        tracked(td, (0, H*0.62), "You hear it before you see it", F_HOOK, (222,233,244), 2, hook_a, center=CX)
    tg = txt.filter(ImageFilter.GaussianBlur(5))
    img = Image.alpha_composite(img, tg)
    img = Image.alpha_composite(img, txt)
    # LED dot-matrix section label (app LEDLabel style)
    scan_a = clamp01((t-3.0)/0.5) * clamp01((5.7-t)/0.6)
    if scan_a > 0:
        lm = SCAN_LED.copy()
        lm.putalpha(SCAN_LED.split()[3].point(lambda v: int(v*scan_a)))
        img.alpha_composite(lm, (int(CX-lm.width/2), int(CY+H*0.28)))
    return img.convert("RGB")

if __name__ == "__main__":
    common.render(OUT, FPS, frame, int(DUR*FPS))
