# Overhead Product Reel — Creative Guide
## Styled after your UX portfolio reference (`demo video - ux portfolio.mp4`)

**Reference analyzed:** 53 sec · 1280×720 landscape · dark cinematic · feature-chapter storytelling  
**Your target:** iPhone 17 Pro UI · Jitter animation · portfolio-quality product reel

---

## What makes the reference video work

Your reference is a **Google Maps / Polaris-style travel app** reel. It is NOT a screen recording — it's a **designed film** with these recurring techniques:

| Technique | What it does | Example in reference |
|-----------|--------------|----------------------|
| **Chapter headlines** | One idea per beat | "Memories" → "You can share with friends" |
| **Split canvas** | Text left, UI right | Headline + iMessage bubble with link preview |
| **Floating phone** | UI hovers in dark space with rim glow | Revolver Canggu card on black gradient |
| **Parallax debris** | Small photos/icons drift in background | Travel photos scattered during "unforgettable moments" |
| **Progress scrub bar** | Horizontal bar with blue pill slides | "Turn Ideas into..." |
| **Depth-of-field** | Background UI blurs, one element pops | "New York Adventure" card lifts forward |
| **Feature callout pill** | Teal tooltip + sparkle icon | "Drag, edit, or remove stops..." |
| **Italic accent word** | One word in headline gets color/style | "Guiding you through *Paths*" |
| **Hero artifact** | Big beautiful object at climax | NY Adventure ticket card |
| **Dramatic verb moment** | Single word blows up with glow | "Save" in neon teal |
| **Completion beat** | Minimal end state | Sparkle icon + "Itinerary created" |

**Pacing:** ~6–8 chapters in 53 seconds ≈ **6–8 seconds per beat**, with 1–2 second transitions.

---

## How to translate this to Overhead

Your app is different — it's a **live flight radar**, not a trip planner. Don't copy the itinerary UI. Copy the **film grammar** and map each chapter to your real features.

### Overhead's story (your narrative arc)

> *"Look up. Every plane overhead — identified, tracked, and understood."*

| Chapter | Reference equivalent | Overhead feature | Headline copy |
|---------|---------------------|------------------|---------------|
| 1. Hook | Black fade in | App identity | **"Overhead"** / *See what's flying above you* |
| 2. Discovery | Floating list | Map + pins appear | **"Scan"** / *Commercial flights near you* |
| 3. Identity | Tap list item | Tap aircraft pin | **"Identify"** / *Every pin is a real flight* |
| 4. Live data | Detail card | Quick card stats | **"Track"** / *Altitude, speed, heading, status* |
| 5. Depth | AI suggestions / specs | Aircraft detail | **"Know the aircraft"** / *Type, registration, capacity* |
| 6. Overview | Itineraries list | Flights board | **"See them all"** / *Every flight in your sky* |
| 7. Share | iMessage link share | Deep link / widget | **"Share a flight"** / *Send a live link to friends* |
| 8. Climax | Journey ticket card | Flight "ticket" hero | **"ACA873"** / *YVR → YYZ · 35,000 ft* |
| 9. Outro | "Itinerary created" | Brand close | Sparkle → **"Overhead"** logo |

---

## Format decision (important)

Your reference is **landscape 1280×720** (portfolio / YouTube / Behance).

For Jitter you have two valid outputs:

### Option A — Portfolio style (matches reference) ✅ Recommended
- **Canvas:** 1920×1080 or 1280×720 (16:9)
- **Phone:** iPhone 17 Pro mockup **floating** in center or right third
- **Typography:** Large headlines on left or overlaid on black
- **Best for:** UX portfolio, Behance, LinkedIn, website hero

### Option B — Social vertical
- **Canvas:** 1080×1920 (9:16)
- **Phone:** Full-bleed 402×874 UI, edge to edge
- **Best for:** Instagram Reels, TikTok, App Store preview

**Recommendation:** Build UI frames at **402×874** in Figma (your app), then place them inside a **landscape Jitter scene** with black cinematic letterboxing — exactly like the reference.

---

## Shot-by-shot storyboard (55 sec, Overhead version)

Use this in Jitter. Timing mirrors your reference's rhythm.

### Shot 1 — Cold open (0:00–0:04)
- **Visual:** Pure black → subtle navy radial gradient (`#0A0F1A`)
- **Text:** **"Overhead"** fades up, large white SF Pro Display
- **Sub:** *See what's flying above you* in text-secondary gray
- **Motion:** Text opacity 0→100%, slight Y translate +8pt

### Shot 2 — Scan (0:04–0:10)
- **Visual:** iPhone 17 Pro floats in, soft blue rim light on left edge
- **UI:** Map idle state, scanning overlay briefly, then pins populate
- **Headline (left):** **"Scan"** / *Your sky, live*
- **Motion:** Phone scale 0.92→1.0 spring; pins stagger fade-in 0.1s apart
- **Extra:** 2–3 faint aircraft icons drift in background (parallax, blurred)

### Shot 3 — Identify (0:10–0:16)
- **Visual:** Map zooms toward ACA873 pin; pin scales up + glow
- **Headline:** **"Identify"** / *Tap any aircraft*
- **UI:** Quick card slides up from bottom (spring, 0.42s feel)
- **LED callsign:** ACA873 in dot-matrix (your SVG asset)
- **Motion:** Map subtle Ken Burns drift; card slide-up

### Shot 4 — Track (0:16–0:22)
- **Visual:** Quick card full view; stat rows highlight one by one
- **Headline:** **"Track"** / *Altitude · Speed · Heading · Status*
- **UI:** Rows pulse: ALTITUDE → SPEED → HEADING → STATUS
- **Accent:** STATUS "HI-ALT" in white; show T/OFF variant flash in coral/climb
- **Motion:** Row background flash `glass-inset` 7% → 14% → 7%

### Shot 5 — Know the aircraft (0:22–0:28)
- **Visual:** Long-press CTA animates (airplane slides across pill)
- **Transition:** Quick card → Detail card
- **Headline:** **"Know the aircraft"** / *Specs from real data*
- **UI:** Air Canada logo + spec rows scroll slowly
- **Callout pill (reference style):** Teal/led-blue pill appears right:
  > *"Type, registration, capacity, wingspan — enriched live"*
  with small ✦ icon
- **Motion:** Depth blur on map; detail card sharp

### Shot 6 — See them all (0:28–0:34)
- **Visual:** Board overlay slides up; map still visible above
- **Headline:** **"See them all"** / *Every flight nearby*
- **UI:** LED "FLIGHTS" title; 5 rows stagger in
- **Motion:** One row (WJA158) lifts forward with shadow (reference list focus)
- **Tap:** Row highlights → transitions to detail

### Shot 7 — Share (0:34–0:40)
- **Visual:** Split layout like reference "Memories" shot
- **Left headline:** **"Share"** / *Send a flight to anyone*
- **Right:** iMessage-style bubbles:
  - Gray: *"What flight is that overhead? 👀"*
  - Blue link preview with **mini flight card**:
    - Air Canada logo, ACA873, YVR→YYZ, 35K ft
    - Link: `overhead://flight/c05829`
- **Motion:** Bubbles pop in with spring; link card scales 0.9→1.0

### Shot 8 — Hero ticket (0:40–0:48) ⭐ Climax
- **Visual:** Reference's journey ticket — but **flight-themed**
- **Hero card design:**
  ```
  ┌─────────────────────────┐
  │  ✦  [Air Canada logo]   │
  │                         │
  │      ACA873             │  ← LED dot style or bold white
  │   AIR CANADA            │  ← coral
  │  ─────────────────────  │
  │  YVR          YYZ       │
  │  MAY 17       35,000 FT │
  │  ─────────────────────  │
  │  B737-800  ·  HI-ALT    │
  │  478 KT    ·  270° W    │
  └─────────────────────────┘
  ```
- **Gradient:** Navy `#0A0F1A` → led-blue `#73B8EB` (your brand, not reference teal)
- **Left text:** *With Overhead*
- **Right text:** **"Every flight, identified"**
- **Motion:** Card rotates slightly 3D (Jitter 3D tilt); gradient shimmers

### Shot 9 — Outro (0:48–0:55)
- **Visual:** Black → led-blue sparkle icon center
- **Text:** **"Flight"** ← left · **"tracked"** ← right (reference "Itinerary created")
- **Underline** under "tracked"
- **Final:** Overhead logo + `overhead.app` or app name
- **Motion:** Words slide in from sides; sparkle pulse

---

## Visual system for Overhead reel

Adapt reference aesthetics to **your** brand:

| Reference | Overhead equivalent |
|-----------|---------------------|
| Teal/cyan accent | **LED blue** `#73B8EB` |
| Blue link bubbles | Same, but preview shows flight card |
| Purple/blue gradients | **Navy → led-blue** gradient |
| Sparkle AI icon | ✦ or radar pulse ring (your app has no AI — use **radar/scan** motif) |
| Travel photos parallax | **Aircraft top-down icons** + airline logos drifting |
| Glass cards | Your actual `Glass-Popup` cards (ultraThinMaterial style) |
| SF Pro typography | Same — matches iOS |

**Do NOT use** itinerary/planner UI patterns. **DO use** LED dot-matrix text, coral airline names, dark map, glass bottom cards.

---

## What to build in Figma (extra reel frames)

Beyond the 8 app screens you already have, create these **cinematic frames** for Jitter:

### Landscape compositions (1920×1080)

| Frame | Contents |
|-------|----------|
| `Reel/Cinematic/01-Hook` | Black + "Overhead" headline only |
| `Reel/Cinematic/02-Scan-Split` | Headline left + floating phone right |
| `Reel/Cinematic/03-Identify` | Phone with map + pin glow |
| `Reel/Cinematic/04-Track-Split` | Headline left + quick card phone |
| `Reel/Cinematic/05-Detail-Callout` | Detail card + led-blue tooltip pill |
| `Reel/Cinematic/06-Board-Focus` | Board with one row elevated |
| `Reel/Cinematic/07-Share-iMessage` | Split: headline + chat bubbles + link preview |
| `Reel/Cinematic/08-Hero-Ticket` | Large flight ticket card + tagline |
| `Reel/Cinematic/09-Outro` | "Flight tracked" + logo |

### Components to add

```
Cinematic/Headline          Large title + gray subtitle, left-aligned
Cinematic/Phone-Frame       iPhone 17 Pro bezel, optional rim glow
Cinematic/Progress-Bar      Dark pill + led-blue sliding indicator
Cinematic/Callout-Pill      led-blue bg, dark text, ✦ icon
Cinematic/iMessage/Incoming Gray bubble
Cinematic/iMessage/LinkPreview  Blue bubble + flight mini card
Cinematic/Hero-Flight-Ticket    Gradient ticket with LED callsign
Cinematic/Parallax/Aircraft     Small aircraft PNG, 30% opacity, blurred
Cinematic/Parallax/Logo         Airline logo, floating
```

### Hero flight ticket specs
- Size: ~320×480 pt
- Corner radius: 24pt continuous
- Ticket notches on left/right at 40% height (like reference)
- Gradient: top `#73B8EB` → bottom `#0A0F1A`
- LED callsign or 32pt bold white
- Divider: white 12% opacity
- Stats row: monospaced or LED style

---

## Jitter production workflow

### Step 1 — Figma
1. Build all `Reel/Cinematic/*` landscape frames
2. Keep every animatable element on **separate layers**
3. Name layers exactly as storyboard (Jitter imports by layer name)

### Step 2 — Jitter project setup
- **Scene size:** 1920×1080 (or 1280×720 to match reference exactly)
- **FPS:** 60
- **Duration:** ~55 sec
- Import Figma file via Jitter plugin

### Step 3 — Motion recipes (copy reference feel)

| Effect | Jitter settings |
|--------|-----------------|
| Phone entrance | Scale 92→100%, opacity 0→100%, spring easing |
| Card slide-up | Y +120→0, spring, overshoot slight |
| Headline fade | Opacity + Y, 400ms ease-out |
| Row highlight | Background opacity pulse, 300ms |
| Parallax drift | Slow X/Y movement, 8–12 sec loop |
| Depth blur | Blur 0→12 on background layer, 500ms |
| Hero card 3D | Rotate Y −8° → 0°, perspective |
| iMessage pop | Scale 0→100%, spring, stagger 150ms |
| Glow pulse | Shadow blur 0→20→0 on pin/ticket |

### Step 4 — Audio (optional but elevates)
- Subtle ambient drone (dark, minimal)
- Soft UI ticks on pin appear / card slide
- One satisfying "whoosh" on hero ticket reveal
- Reference uses no voiceover — typography carries the story

### Step 5 — Export
- **Portfolio:** 1920×1080 MP4, H.264, 60fps
- **Social cut:** Crop center 1080×1920 from phone-focused shots (shots 3–6)
- **GIF:** 10-sec loop of shots 3→4→5 for Twitter/LinkedIn

---

## Accuracy rules (Overhead-specific)

When adapting reference creativity, keep these from the real app:

- ✅ Dark map full-screen base
- ✅ Glass popup cards with concentric corners
- ✅ LED dot-matrix callsigns (never plain SF Pro for flight numbers)
- ✅ Coral airline names
- ✅ Bottom pill (list + refresh) on map idle
- ✅ No tab bar — ever
- ✅ Status colors: climb / coral / white
- ❌ Don't add itinerary forms, explore tabs, or AI sparkle unless you mean "data enrichment"
- ❌ Don't use reference's teal — use led-blue `#73B8EB`

---

## Production checklist

### Figma
- [ ] 8 app UI frames at 402×874 (already specced)
- [ ] 9 cinematic landscape frames at 1920×1080
- [ ] Hero flight ticket component
- [ ] iMessage share preview component
- [ ] iPhone 17 Pro device frame with rim glow
- [ ] Headline text components (5 chapter titles)

### Jitter
- [ ] Import all cinematic frames
- [ ] Build 9 scenes matching shot list timing
- [ ] Add parallax aircraft layers on shots 2–3
- [ ] Spring transitions between scenes (not hard cuts)
- [ ] Export 1920×1080 MP4

### Time estimate
| Phase | Hours |
|-------|-------|
| Figma cinematic frames | 4–6 |
| Jitter animation | 3–5 |
| Sound + polish | 1–2 |
| **Total** | **8–13 hrs** |

---

## Quick start (do this next)

1. **Watch your reference** and note the beats — it's ~7 chapters in 53 sec
2. **In Figma:** create `Reel/Cinematic/01-Hook` — black + "Overhead" text only
3. **In Figma:** create `Reel/Cinematic/08-Hero-Ticket` — the flight ticket (most shareable frame)
4. **In Jitter:** animate Hook → Scan → Identify as a 15-sec proof-of-concept
5. If the feel is right, build remaining chapters

Your `figma-export/` kit already has assets, LED SVGs, sample flight data (ACA873), and screen specs. This guide adds the **film layer** on top.
