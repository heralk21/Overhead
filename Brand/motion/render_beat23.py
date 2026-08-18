#!/usr/bin/env python3
"""Overhead - Beat 2-3: coral dot -> Boeing 777 -> Quick Card -> takeoff.
Coral dot centers & morphs into the real top-down ac_b777 model; the glass
Quick Card slides up with LED callsign; the 777 takes off out of the card and
zooms up (hands off to the map recording).
"""
import math, os
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont
import common, led

W, H = 1920, 1080
FPS = 60
DUR = 6.6
OUT = os.path.join(os.path.dirname(__file__), "overhead-777-beat23.mp4")
NAVY = (10, 15, 26)
CX, CY = W*0.5, H*0.46
LED = (115, 184, 235); CORAL = (235, 72, 72); CYAN = (97, 204, 245)

_p = Image.open(os.path.join(os.path.dirname(__file__),
      "..", "..", "flight-tracker", "Assets.xcassets", "Aircraft",
      "ac_b777.imageset", "ac_b777.png")).convert("RGBA")
PLANE = _p.crop(_p.getbbox())
PH = 300.0  # target plane height at full morph (px)
PW = PH * PLANE.width / PLANE.height
CALL = led.render("UAL 287", pitch=7, color=LED, off=True)

def clamp01(v): return 0.0 if v<0 else 1.0 if v>1 else v
def _cb(t,p1,p2): return 3*p1*(1-t)**2*t+3*p2*(1-t)*t*t+t**3
def bez(x,x1,y1,x2,y2):
    x=clamp01(x)
    if x<=0: return 0.0
    if x>=1: return 1.0
    lo,hi=0.,1.
    for _ in range(20):
        m=(lo+hi)/2
        if _cb(m,x1,x2)<x: lo=m
        else: hi=m
    return _cb((lo+hi)/2,y1,y2)
def eout(x): return bez(x,.2,.9,.25,1)
def eio(x): return bez(x,.45,0,.55,1)
def ein(x): return bez(x,.55,0,.9,.4)
def F(sz,mono=False):
    p="/System/Library/Fonts/SFNSMono.ttf" if mono else "/System/Library/Fonts/SFNS.ttf"
    try: return ImageFont.truetype(p,sz)
    except Exception: return ImageFont.load_default()
F_AIR=F(30,True); F_TEL=F(26,True)

def disc(d,x,y,r,col,a):
    a=int(255*clamp01(a))
    if a<=0 or r<=0: return
    d.ellipse([x-r,y-r,x+r,y+r], fill=(col[0],col[1],col[2],a))

def plane_layer(scale, tint, alpha):
    w=max(1,int(PW*scale)); h=max(1,int(PH*scale))
    im=PLANE.resize((w,h), Image.LANCZOS)
    if tint>0:
        ov=Image.new("RGBA",(w,h),CORAL+(0,))
        a=im.split()[3].point(lambda v:int(v*tint*0.85))
        ov.putalpha(a); im=Image.alpha_composite(im,ov)
    if alpha<1:
        im.putalpha(im.split()[3].point(lambda v:int(v*alpha)))
    return im

def frame(t):
    base=Image.new("RGB",(W,H),NAVY)
    gw,gh=W//2,H//2
    glow=Image.new("RGB",(gw,gh),(0,0,0)); gd=ImageDraw.Draw(glow)
    core=Image.new("RGBA",(W,H),(0,0,0,0)); cd=ImageDraw.Draw(core)

    z=1.0+0.5*eio(clamp01(t/1.2))
    launch=clamp01((t-3.6)/1.6)
    dy=-ein(launch)*(H*1.15)

    # coral dot -> flash -> plane
    morph=clamp01((t-0.7)/1.4)
    dot_a=clamp01(t/0.4)*clamp01((1.5-t)/0.6)
    if dot_a>0:
        r=10*z
        gd.ellipse([(CX-46*z)/2,(CY-46*z)/2,(CX+46*z)/2,(CY+46*z)/2],
                   fill=(int(150*dot_a),int(40*dot_a),int(40*dot_a)))
        disc(cd,CX,CY,r,CORAL,dot_a); disc(cd,CX,CY,r*0.4,(255,220,215),dot_a)
    if morph>0:
        pscale=(0.28+0.72*eout(morph))*(1.0+0.16*launch)
        palpha=clamp01(morph/0.35)*clamp01((6.6-t)/0.5 if t>6.0 else 1)
        tint=1-clamp01(morph*1.2)
        py=CY+dy
        # plane glow
        pl=plane_layer(pscale,tint,palpha)
        pgl=pl.filter(ImageFilter.GaussianBlur(18))
        core.alpha_composite(pgl,(int(CX-pl.width/2),int(py-pl.height/2)))
        # takeoff trail
        if launch>0:
            for k in range(1,7):
                ty=py+k*40*(0.5+launch)
                tl=plane_layer(pscale,0,palpha*(0.42-k*0.06)*launch)
                if tl.getbbox(): core.alpha_composite(tl,(int(CX-tl.width/2),int(ty-tl.height/2)))
        core.alpha_composite(pl,(int(CX-pl.width/2),int(py-pl.height/2)))

    # quick card rises, recedes on takeoff
    cr=eout(clamp01((t-2.0)/1.0))
    crec=eout(clamp01((t-3.7)/0.9))
    cyoff=crec*(H*0.6)
    if cr>0 and crec<1:
        ca=cr*(1-crec)
        cw,ch=int(W*0.42),int(H*0.52)
        cx0=int(CX-cw/2); cy0=int(H-cr*ch*0.82+cyoff)
        gl=Image.new("RGBA",(W,H),(0,0,0,0)); g=ImageDraw.Draw(gl)
        g.rounded_rectangle([cx0,cy0,cx0+cw,cy0+ch],radius=40,
                            fill=(24,36,52,int(150*ca)),outline=(255,255,255,int(60*ca)),width=2)
        g.rounded_rectangle([CX-30,cy0+22,CX+30,cy0+28],radius=3,fill=(255,255,255,int(110*ca)))
        # LED callsign
        lm=CALL.copy(); lm.putalpha(CALL.split()[3].point(lambda v:int(v*ca)))
        gl.alpha_composite(lm,(int(CX-lm.width/2),cy0+52))
        g.text((CX-cw/2+40,cy0+120),"UNITED",font=F_AIR,fill=(235,72,72,int(230*ca)))
        g.text((CX-cw/2+40,cy0+168),"35,000 FT   486 KT   271°",font=F_TEL,fill=(97,204,245,int(210*ca)))
        core.alpha_composite(gl)

    glow=glow.filter(ImageFilter.GaussianBlur(11)).resize((W,H),Image.BILINEAR)
    img=ImageChops.screen(base,glow).convert("RGBA")
    img=Image.alpha_composite(img,core)
    # end push-in / speed blur handoff
    return img.convert("RGB")

if __name__=="__main__":
    common.render(OUT, FPS, frame, int(DUR*FPS))
