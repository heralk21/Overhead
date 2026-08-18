# Overhead — Figma MCP Prompt: 9 Cinematic Reel Frames

**Copy everything below the line into Claude/Cursor with Figma MCP enabled.**

---

## PROMPT START

You are building **9 cinematic landscape frames** for the **Overhead** flight tracker product reel. These frames sit alongside the app UI screens and are used in **Jitter** at **1920×1080** (16:9 portfolio format, matching a UX demo reel reference).

### Source files (read first)

| File | Purpose |
|------|---------|
| `flight-tracker/figma-export/sample-content.json` | Design tokens, demo flight ACA873 |
| `flight-tracker/figma-export/manifest.json` | Asset paths, component names |
| `flight-tracker/figma-export/hero-flight-ticket-spec.json` | **Exact spec for Frame 08** |
| `flight-tracker/figma-export/overhead-cinematic-storyboard.json` | Shot timing + frame names |
| `flight-tracker/figma-export/OVERHEAD-REEL-CREATIVE-GUIDE.md` | Creative direction |
| `flight-tracker/figma-export/assets/` | Airline logos, aircraft PNGs |
| `flight-tracker/figma-export/led-font/words/` | LED SVG text |

### Figma file setup

- **File name:** `Overhead — Product Reel`
- **Page:** `04 — Reel Cinematic`
- **Master frame size:** **1920 × 1080 pt** (all 9 frames)
- **Phone UI inset:** iPhone 17 Pro content at **402 × 874** inside device bezel component
- **Background:** `#000000` with subtle `#0A0F1A` radial glow behind focal elements

### Brand tokens (use Figma variables)

```
led-blue:    #73B8EB
coral:       #EB4747
climb:       #61D194
navy:        #0A0F1A
text-primary:#FFFFFF
text-secondary: rgba(255,255,255,0.50)
glass-inset: rgba(255,255,255,0.07)
glass-border:rgba(255,255,255,0.12)
```

### Shared components to build first

Before any frame, create these on page `02 — Components`:

```
Cinematic/BG-Black          1920×1080 fill #000000
Cinematic/BG-Radial-Glow    900×900 ellipse, radial #0A0F1A → transparent
Cinematic/Headline-Block      Auto-layout vertical: title 56pt Bold + subtitle 20pt Regular gray
Cinematic/Phone-17-Pro        402×874 screen + bezel, optional left rim glow (#73B8EB 35% blur 8)
Cinematic/Callout-Pill        led-blue fill, dark text, ✦ icon right — see Frame 05
Cinematic/iMessage/Incoming Gray bubble, radius 18, fill rgba(255,255,255,0.12)
Cinematic/iMessage/LinkPreview  Blue bubble #007AFF with embedded flight mini-card
Cinematic/Hero-Flight-Ticket  Per hero-flight-ticket-spec.json exactly
Cinematic/Parallax/Aircraft   Aircraft PNG at 30% opacity, blur 4, various rotations
```

### Demo flight data (use throughout)

**Primary:** ACA873 — Air Canada, YVR→YYZ, 35,000 FT, 478 KT, 270° W, HI-ALT, B737-800, C-FRSR  
**Secondary:** WJA158 — WestJet, YVR→YYC, 8,200 FT, T/OFF

---

## Frame-by-frame build instructions

---

### Frame 01: `Reel/Cinematic/01-Hook`
**Duration in reel:** 4 sec  
**Purpose:** Cold open — brand identity only

**Layers (top to bottom):**
```
BG/Canvas                     1920×1080 #000000
BG/Radial-Glow                center, subtle navy bloom
Text/Title                    "Overhead" — SF Pro Display 72pt Bold #FFFFFF, centered
Text/Subtitle                 "See what's flying above you" — SF Pro Text 22pt Regular text-secondary
                              Position: vertical center, subtitle 16pt below title
```

**No phone. No UI.** Pure typography on black.

---

### Frame 02: `Reel/Cinematic/02-Scan-Split`
**Duration:** 6 sec  
**Purpose:** Map scan + pins appear

**Layout:** Split — headline left 40%, phone right 55%

**Left column (x: 120, vertically centered):**
```
Headline/Title                "Scan"
Headline/Subtitle             "Your sky, live"
```

**Right area (x: 780, y: 103):**
```
Phone/Device                  Cinematic/Phone-17-Pro instance
  └─ Screen content:          Reel / 01 — Map Idle OR scanning state
     Layer/Map                #050609 dark map
     Layer/Pins               5 aircraft instances (ACA873 selected/larger)
     Component/Bottom-Pill    visible at bottom
BG/Rim-Light                  4pt #73B8EB strip on phone left edge, blur 8
```

**Background parallax (optional, behind phone):**
```
Parallax/AC-1                 ac_b737.png, 48pt, rotation 45°, opacity 20%, blur 6, x:1100 y:200
Parallax/AC-2                 ac_a321.png, 36pt, rotation 120°, opacity 15%, x:1300 y:600
Parallax/AC-3                 ac_b777.png, 40pt, rotation 280°, opacity 15%, x:950 y:750
```

---

### Frame 03: `Reel/Cinematic/03-Identify`
**Duration:** 6 sec  
**Purpose:** Tap pin → quick card

**Layout:** Phone centered (x: 759, y: 103), headline overlaid bottom-left

**Phone screen content:**
```
App state: Reel / 03 — Quick Card (full)
- Map dimmed behind card
- Quick card with ACA873 LED callsign
- Airline AIR CANADA coral
- 4 stat rows
- Detail CTA visible
```

**Overlay text (x: 120, y: 820):**
```
Headline/Title                "Identify"
Headline/Subtitle             "Tap any aircraft"
```

**Pin glow (on map layer, if separate):**
```
Pin/Glow/ACA873               Circle 80pt, #73B8EB 25% opacity, blur 20, behind selected pin
```

---

### Frame 04: `Reel/Cinematic/04-Track-Split`
**Duration:** 6 sec  
**Purpose:** Highlight live stat rows

**Layout:** Same split as Frame 02 — headline left, phone right

**Left:**
```
Headline/Title                "Track"
Headline/Subtitle             "Altitude · Speed · Heading · Status"
```

**Right phone:** Quick card fully visible. **Each stat row is a separate layer** for Jitter highlight animation:
```
Row/Stat/Altitude             label + "35000 FT" — normal state
Row/Stat/Speed                label + "478 KT"
Row/Stat/Heading              label + "270° W"
Row/Stat/Status               label + "HI-ALT" white
Row/Stat/Altitude/Highlight   duplicate with glass-inset bg 14% — for Jitter pulse
```

---

### Frame 05: `Reel/Cinematic/05-Detail-Callout`
**Duration:** 6 sec  
**Purpose:** Aircraft specs + feature callout pill (reference tooltip style)

**Layout:** Phone left-center, callout pill right

**Phone (x: 200, y: 103):**
```
App state: Reel / 04 — Detail Loaded
- Air Canada logo 56pt
- 9 spec rows (TYPE through CATEGORY)
- Map blurred/dimmed behind
```

**Callout pill (x: 1050, y: 380):**
```
Callout/Shell                 340×56 pill, corner radius 28
Callout/Fill                  #73B8EB (led-blue)
Callout/Text                  "Type, registration, capacity — enriched live"
                              SF Pro Text 13 Medium #0A0F1A
Callout/Icon                  Circle 40pt #0A0F1A, white ✦ or radar icon 18pt
                              Position: right edge of pill, overlapping
```

**Headline (x: 1050, y: 280):**
```
Headline/Title                "Know the aircraft"
Headline/Subtitle             "Specs from real data"
```

---

### Frame 06: `Reel/Cinematic/06-Board-Focus`
**Duration:** 6 sec  
**Purpose:** Flights board with one row elevated (reference depth-of-field)

**Layout:** Phone centered, board card dominant

**Phone screen:**
```
App state: Reel / 05 — Board Open
- Board overlay ~60% screen height
- LED "FLIGHTS" title
- 5 rows: ACA873, WJA158, DAL412, UAL892, SWA2847
```

**Depth effect layers:**
```
Board/Rows/Background         All rows at opacity 70%, blur 2 (except focus row)
Board/Row/WJA158/Elevated     Full opacity, no blur, scale 102%, shadow Y:8 blur:24 #000 40%
                              This row lifts forward — reference "New York Adventure" focus
Headline/Title                "See them all" — x:120 y:120
Headline/Subtitle             "Every flight nearby"
```

---

### Frame 07: `Reel/Cinematic/07-Share-iMessage`
**Duration:** 6 sec  
**Purpose:** iMessage share moment (direct reference to "Memories" shot)

**Layout:** Split 50/50

**Left (x: 120, y: 380):**
```
Headline/Title                "Share"
Headline/Subtitle             "Send a flight to anyone"
```

**Right (x: 980, y: 200):**
```
iMessage/Incoming             "What flight is that overhead? 👀"
                              Gray bubble, top-right area
                              SF Pro Text 15pt #FFFFFF, bubble fill rgba(255,255,255,0.12)
                              radius 18, tail bottom-left

iMessage/LinkPreview          Below incoming, x: 900
  └─ Bubble fill              #007AFF (iOS link blue)
  └─ MiniCard                 Embedded flight preview:
       Logo                   air_canada.png 32pt
       Callsign               ACA873 — SF Pro 17 Semibold white
       Route                  YVR → YYZ — 13pt rgba(255,255,255,0.80)
       Altitude               35,000 FT — 12pt rgba(255,255,255,0.60)
       Link                   overhead://flight/c05829 — 11pt underline white
```

---

### Frame 08: `Reel/Cinematic/08-Hero-Ticket` ⭐ CLIMAX
**Duration:** 8 sec  
**Purpose:** Hero flight ticket — build EXACTLY per `hero-flight-ticket-spec.json`

**Read `hero-flight-ticket-spec.json` in full.** Key requirements:

- Ticket: **360×520**, corner radius **24 continuous**
- **Ticket notches** at 38% height left + right (semicircle cutouts, fill #000)
- **Gradient** top→bottom: `#73B8EB` → `#3D8FCC` → `#1A3A5C` → `#0A0F1A`
- LED callsign: `quick-callsign-aca873-6.5pt.svg`
- Airline: AIR CANADA in **coral** `#EB4747`
- Route: YVR — airplane icon — YYZ (36pt bold)
- Stats grid: ALTITUDE, STATUS, SPEED, HEADING
- Chips: NARROW-BODY + ● LIVE (climb green)
- Right tagline: "With Overhead" + **"Every flight, identified"** 48pt
- Action pills: "Back to Map" + "Share Flight"
- Brand footer: Overhead logo + name

**This is the most important frame. Spend the most time here.**

---

### Frame 09: `Reel/Cinematic/09-Outro`
**Duration:** 7 sec  
**Purpose:** Completion beat (reference "Itinerary created")

**Layout:** Centered minimal

**Layers:**
```
BG/Canvas                     #000000
BG/Radial-Glow                subtle center

Icon/Sparkle                  Circle 48pt, fill #73B8EB, white ✦ 24pt — center top third

Text/Left                     "Flight" — SF Pro Display 40pt Regular #FFFFFF
                              x: 720 y: 520

Text/Right                    "tracked" — SF Pro Display 40pt Regular #FFFFFF
                              x: 1080 y: 520
                              Underline: 1pt white, width matches text, y+6

Brand/Logo                    overhead-logo.png 64pt — center, y: 620
Brand/Name                    "Overhead" — SF Pro Display 24pt Medium white, below logo
```

---

## Layer naming rules (strict)

```
[Category]/[Name]/[Variant]
```

Every animatable element = **separate layer**. Jitter imports by layer name.

**Must be separate layers for animation:**
- Each headline word group
- Phone shell vs screen content
- Each iMessage bubble
- Each board row
- Each stat row + highlight variant
- Ticket sections (callsign, route, stats, chips)
- Parallax aircraft (each instance)
- Callout pill text vs icon

---

## Auto-layout rules

| Element | Rule |
|---------|------|
| Headline blocks | Vertical auto-layout, left-aligned, gap 8 |
| Ticket interior | Vertical auto-layout, padding 28, gap 0 |
| Stats grid | 2-column auto-layout, gap 16/24 |
| Action pills | Horizontal auto-layout, gap 12 |
| iMessage stack | Vertical, right-aligned, gap 12 |

---

## Jitter export prep

After all 9 frames built, verify:

- [ ] All frames exactly **1920×1080**
- [ ] Frame names match: `Reel/Cinematic/01-Hook` through `09-Outro`
- [ ] No merged layers on animated elements
- [ ] LED text is vector (SVG), not rasterized
- [ ] Phone screen uses real app components from `03 — Reel Screens` page
- [ ] Hero ticket matches `hero-flight-ticket-spec.json` gradient stops
- [ ] iMessage link preview uses real ACA873 data

Export storyboard timing from `overhead-cinematic-storyboard.json`.

---

## Build order

1. Shared components (Headline, Phone, Callout, iMessage, Hero Ticket)
2. Frame 01 Hook (simplest — validates typography)
3. Frame 08 Hero Ticket (hardest — do while fresh)
4. Frame 07 Share (iMessage — high visual impact)
5. Frames 02, 03, 04 (phone + map states)
6. Frame 05 Detail callout
7. Frame 06 Board focus
8. Frame 09 Outro
9. Cross-check all against `overhead-cinematic-storyboard.json`

---

## Accuracy checklist

- [ ] Landscape 1920×1080 — NOT vertical phone-only
- [ ] LED callsigns on ticket and app UI — never plain SF Pro for flight numbers
- [ ] Coral `#EB4747` for airline names
- [ ] Led-blue `#73B8EB` as accent — NOT reference teal
- [ ] Dark map `#050609` in phone screens
- [ ] Glass cards with concentric corners in phone UI
- [ ] No tab bar in any phone screen
- [ ] Hero ticket has perforated notches
- [ ] iMessage preview shows `overhead://` deep link

---

## PROMPT END

**Kickoff message to append:**

> Build all 9 cinematic frames on page `04 — Reel Cinematic` in [YOUR FIGMA FILE URL].  
> Source kit: `/Users/heralkumar/Desktop/ios app - flight tracker/flight-tracker/figma-export/`  
> Start with shared components, then Frame 01 Hook, then Frame 08 Hero Ticket per `hero-flight-ticket-spec.json`.  
> Work sequentially. Verify each frame before continuing.
