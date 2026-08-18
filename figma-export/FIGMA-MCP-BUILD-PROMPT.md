# Overhead — Figma MCP Build Prompt (iPhone 17 Pro → Jitter Reel)

**Copy everything below the line into Claude (with Figma MCP enabled) or Cursor Agent chat.**

---

## PROMPT START

You are building a pixel-accurate Figma design file for **Overhead**, an iOS flight tracker app. The goal is production-quality screens that can be imported into **Jitter** to create a product reel at **iPhone 17 Pro** size.

### Prerequisites

1. **Figma MCP must be connected** (remote server: `https://mcp.figma.com/mcp`)
   - In Cursor: type `/add-plugin figma` or add MCP in Settings → MCP
   - In Claude Code: `claude plugin install figma@claude-plugins-official`
2. **Open or create a Figma Design file** named `Overhead — Product Reel`
3. **Read these local source files** before building anything:
   - `flight-tracker/figma-export/manifest.json` — asset catalog + component names
   - `flight-tracker/figma-export/sample-content.json` — screen data, tokens, demo flights
   - `flight-tracker/figma-export/led-font/manifest.json` — LED glyph inventory
   - `flight-tracker/figma-export/README.md` — import order

4. **Import assets into Figma first** (drag from disk or use MCP image upload if available):
   - `figma-export/assets/airline-logos/*.png` (44 files)
   - `figma-export/assets/aircraft/*.png` (29 files)
   - `figma-export/led-font/words/*.svg` (28 pre-composed LED strings)
   - `figma-export/assets/app-icon/overhead-logo.png`

---

## Target device: iPhone 17 Pro

| Property | Value |
|----------|-------|
| Logical frame | **402 × 874 pt** |
| Export @3x (Jitter) | **1206 × 2622 px** |
| Aspect ratio | ~9:19.5 |
| Safe area top | 62 pt (Dynamic Island) |
| Safe area bottom | 34 pt (home indicator) |
| Status bar height | 54 pt |

**All reel frames MUST be exactly 402 × 874 pt.** Name the device preset `iPhone 17 Pro` in Figma. If the preset is unavailable, create a custom frame at 402×874 with rounded display corners.

### Concentric glass popup corners (critical)

The app uses hardware-matched bottom card corners from `ScreenCornerRadius.swift`:

- Card horizontal margin: **10 pt** from screen edge → card width = **382 pt**
- Card bottom margin: **6 pt** from physical bottom
- Top corner radius: **28 pt** (continuous / squircle)
- Bottom corner radius: **display corner radius − 10 pt** ≈ **48 pt** on iPhone 17 Pro
- Use **uneven corner radii** — NOT a uniform rounded rect

---

## Figma file structure (create these pages)

```
00 — Cover
01 — Foundations
02 — Components
03 — Reel Screens          ← primary deliverable for Jitter
04 — Reel Storyboard       ← numbered shot sequence for animation
05 — Widget (optional)
06 — Watch (optional)
```

---

## Phase 1: Foundations (`01 — Foundations`)

Create **Figma Variables** (color + number modes):

### Colors
| Variable | Hex |
|----------|-----|
| navy | #0A0F1A |
| panel-bg | #172430 |
| led-blue | #73B8EB |
| coral | #EB4747 |
| climb | #61D194 |
| text-primary | #FFFFFF |
| text-secondary | #FFFFFF 50% |
| text-dim | #FFFFFF 24% |
| separator | #FFFFFF 12% |
| glass-border | #FFFFFF 12% |
| glass-inset | #FFFFFF 7% |
| map-bg | #050609 |

### Numbers
| Variable | pt |
|----------|-----|
| screen-margin | 10 |
| bottom-margin | 6 |
| card-padding-h | 20 |
| bottom-pill-offset | 34 |
| popup-top-radius | 28 |
| popup-bottom-radius | 48 |
| grabber-dash-w | 36 |
| grabber-dash-h | 4 |
| close-diameter | 32 |

### Effect styles
| Name | Spec |
|------|------|
| Glass/Popup-Shadow | Y: −6, blur: 22, #000000 32% |
| Glass/Material | Background blur: 40, fill white 8% on dark |
| Glass/Border | Inside stroke 0.5px, glass-border |

### Text styles (SF Pro)
| Name | Size | Weight |
|------|------|--------|
| Title/Bold | 20 | Bold |
| CTA/Semibold | 16 | Semibold |
| Row/Label | 12 | Medium, UPPERCASE |
| Row/Value | 13 | Medium |
| Board/Header | 11 | Medium, UPPERCASE |

---

## Phase 2: Components (`02 — Components`)

Build in this order. Every component uses **auto-layout**. Name with `/` hierarchy.

### Atoms
```
Grabber/Dash           36×4, radius 3, fill text-dim
Button/Close           32 circle, glass blur, xmark 13pt semibold, 44×44 tap area
Divider/H              0.5px separator, full width minus 40pt horizontal padding
LED/Word/*             import from led-font/words/*.svg as components
Logo/Airline/*         from assets/airline-logos, default 56pt
Icon/Aircraft/*        from assets/aircraft, nose up, rotate on map
```

### Molecules
```
Row/Quick-Stat         H-stack: label (text-secondary) + value (text-primary), pad 20h 9v
Row/Spec               H-stack: LED label (led-blue 2.2pt) + value 13pt regular
Row/Board              LED callsign 2.0pt | alt 52w | status 76w | chevron 48w, height 52
Toolbar/Bottom-Pill    Capsule: list 66×52 | divider 0.5×22 | refresh 66×52
Button/Detail-CTA      54h, glass-inset fill, "See Airplane Details" 16pt semibold
Button/Board-Refresh   34×34, radius 10, arrow.clockwise 15pt
Banner/Error           radius 16, coral triangle + message + Retry led-blue
Overlay/Scanning       radius 20, LED "SCANNING AIRSPACE" + spinner
```

### Organisms
```
Shell/Glass-Popup      382w, uneven corners (28 top / 48 bottom), glass material + border + shadow
Card/Grabber-Chrome    12h dash row + optional Close absolute top-trailing 8pt inset
Card/Quick             Shell + grabber + callsign LED + airline + 4 stat rows + CTA
Card/Detail            Shell + grabber + logo 56 + title + spec list
Card/Board             Shell + grabber (no close) + FLIGHTS title + refresh + table
```

---

## Phase 3: Reel Screens (`03 — Reel Screens`)

Create **one frame per state** at **402 × 874**. Use exact layer names — Jitter uses these for scene mapping.

### Screen inventory (build all 8)

#### Frame: `Reel / 01 — Map Idle`
- Full-bleed dark map placeholder (#050609 with subtle texture or screenshot)
- 5 aircraft pin instances (from sample-content.json `sampleFlights`):
  - ACA873 selected (larger, ac_b737, rotation 270°)
  - WJA158, DAL412, UAL892, SWA2847 (smaller, rotated by heading)
- User location blue dot (center-ish)
- Bottom pill at y = bottom − 34 − safe area
- **No cards open**

#### Frame: `Reel / 02 — Map Scanning`
- Same as Map Idle but dim map slightly
- Centered Overlay/Scanning component

#### Frame: `Reel / 03 — Quick Card`
- Map visible behind (dimmed ~15%)
- Card/Quick instance at bottom with flight **ACA873**:
  - LED callsign: `quick-callsign-aca873-6.5pt.svg`
  - Airline: AIR CANADA (coral)
  - ALTITUDE 35000 FT | SPEED 478 KT | HEADING 270° W | STATUS HI-ALT
  - Detail CTA at bottom
- Bottom pill **hidden**

#### Frame: `Reel / 04 — Detail Loaded`
- Map dimmed behind
- Card/Detail with ACA873:
  - Logo: air_canada.png 56pt
  - Title: AIR CANADA 20pt bold
  - 9 spec rows (TYPE through CATEGORY) — data from sample-content.json
- Bottom pill hidden

#### Frame: `Reel / 05 — Board Open`
- Map visible behind
- Card/Board with 5 rows (ACA873, WJA158, DAL412, UAL892, SWA2847)
- LED title FLIGHTS 3.0pt
- Column headers: FLIGHT | ALT | STATUS
- No close button on grabber (drag only)

#### Frame: `Reel / 06 — Board → Detail Transition`
- Duplicate Detail Loaded but annotate in layer name this is the post-tap state
- (For Jitter: animate from Board row tap)

#### Frame: `Reel / 07 — Map Error`
- Map idle base
- Error banner at top (padding-top 56):
  - "Location access is required to find flights near you."
  - Retry button led-blue

#### Frame: `Reel / 08 — Widget Medium` (bonus for reel cutaway)
- Frame 338 × 158 (scale up in Jitter or place centered on 402×874 with label)
- Medium widget with ACA873: logo | AIR CANADA / AC 873 / B737-800 / EN ROUTE TO Toronto Intl | aircraft art

---

## Phase 4: Reel Storyboard (`04 — Reel Storyboard`)

Create a horizontal storyboard frame with **numbered shots** for Jitter. Each shot = one Reel screen instance with duration note:

| Shot | Frame | Duration | Motion note |
|------|-------|----------|-------------|
| 1 | 01 Map Idle | 2.0s | Slow map drift, pins visible |
| 2 | 02 Scanning | 1.5s | Scanning overlay fades in |
| 3 | 01 Map Idle | 0.5s | Scanning fades out, flights appear |
| 4 | 01 Map Idle | 1.0s | Camera eases toward ACA873 pin |
| 5 | 03 Quick Card | 2.5s | Card slides up from bottom (spring) |
| 6 | 03 Quick Card | 1.5s | Highlight stat rows sequentially |
| 7 | 04 Detail | 2.0s | Quick card → Detail (CTA long-press sim) |
| 8 | 04 Detail | 2.0s | Scroll spec rows slowly |
| 9 | 05 Board | 2.0s | Detail dismisses, board slides up |
| 10 | 05 Board | 1.5s | Row highlight → tap WJA158 |
| 11 | 06 Detail | 2.0s | WestJet detail card |
| 12 | 01 Map Idle | 2.0s | All cards dismiss, map returns |
| 13 | 08 Widget | 1.5s | Cut to widget (optional) |
| 14 | 01 Map Idle | 1.0s | Logo + "Overhead" end card overlay |

**Total reel: ~22 seconds** (adjust in Jitter)

---

## Layer naming rules (strict — do not deviate)

```
[Category]/[Name]/[Variant]
```

Examples:
- `Layer/Map`
- `Layer/Aircraft-Pin/ACA873/Selected`
- `Component/Bottom-Pill`
- `Card/Quick/Shell`
- `Content/Callsign-LED`
- `Row/Stat/Altitude`
- `Chrome/Grabber`
- `Chrome/Close`

Every text layer: include content in name when helpful, e.g. `Text/Airline/AIR-CANADA`

---

## Auto-layout rules

| Element | Layout |
|---------|--------|
| All cards | Vertical auto-layout, spacing 0, width 382, hug height |
| Stat rows | Horizontal, space-between, padding 20h 9v |
| Board rows | Height 52, grid columns as specified |
| Close button | Absolute position top-trailing, 8pt inset from card corner |
| Bottom pill | Centered horizontally, fixed 34pt from bottom safe area |
| Map | Fill parent, clip content |

---

## Glass material recipe (Figma)

Do NOT use flat gray fills. For every glass surface:

1. Fill: `#FFFFFF` at **8%** opacity
2. Background blur: **40**
3. Inside stroke: **0.5px**, `#FFFFFF` at **12%**
4. Effect: shadow Y **−6**, blur **22**, `#000000` at **32%**

Nested controls (CTA, refresh button): fill `#FFFFFF` at **7%**, same border.

---

## LED text rules

**Never use SF Pro for callsigns or board text.** Use imported SVG components:

| Context | SVG file | Height |
|---------|----------|--------|
| Quick callsign | `quick-callsign-aca873-6.5pt.svg` | 45.5pt |
| Board title | `board-title-3.0pt.svg` | 21pt |
| Board callsign | `board-callsign-aca873-2.0pt.svg` | 14pt |
| Spec labels | `spec-type-2.2pt.svg` etc. | 15.4pt |
| Scanning | `scanning-overlay-1.9pt.svg` | 13.3pt |

---

## Jitter export checklist

When Figma file is complete, verify before Jitter import:

- [ ] All reel frames are **402 × 874 pt**
- [ ] Frame names start with `Reel /` prefix
- [ ] No rasterized screenshots of UI — all vectors/components (Jitter animates layers)
- [ ] Aircraft pins are separate rotatable layers
- [ ] Cards are separate groups that can translate Y independently
- [ ] LED text is vector (SVG), not outlined incorrectly
- [ ] Bottom pill is its own component (show/hide per shot)
- [ ] Export from Figma at **1x** for Jitter (Jitter handles scaling); or **3x** for final 1206×2622 if needed
- [ ] Dark mode only — no light variants
- [ ] Storyboard page documents shot order and timing

### Jitter import settings
- Source: Figma plugin "Import from Figma"
- Canvas: **402 × 874** (or 1206 × 2622 @3x)
- FPS: **60**
- Background: transparent or #050609
- Animate: position, opacity, scale only on pins/cards (no blur animation — performance)

---

## Build order (follow sequentially)

1. Create file + pages
2. Foundations (variables, styles)
3. Import assets → componentize
4. Shell/Glass-Popup (hardest — get corners right first)
5. Card/Quick → test on Reel / 03
6. Card/Detail → Reel / 04
7. Card/Board → Reel / 05
8. Map base + pins → Reel / 01
9. Overlays (scanning, error) → Reel / 02, 07
10. Storyboard page with shot sequence
11. Self-review against sample-content.json row by row

---

## Accuracy checklist (reject your own work if any fail)

- [ ] No TabBar or NavigationStack — single map + overlay cards only
- [ ] Board grabber has NO close button (drag dismiss only)
- [ ] Quick card HAS close button (top-trailing)
- [ ] Airline name is **coral** (#EB4747), not white
- [ ] Status colors: T/OFF = climb, LAND = coral, HI-ALT = white
- [ ] Card bottom corners are more rounded than top (concentric)
- [ ] Callsign uses LED dot matrix, not typography
- [ ] "See Airplane Details" is a long-press CTA style pill, not a standard blue button
- [ ] Bottom pill is capsule glass, not a rectangle
- [ ] Map pins rotate by heading (separate rotation per pin layer)

---

## Source code reference (for disputes)

If unsure about a measurement, read the SwiftUI source:
- `flight-tracker/ContentView.swift` — all UI components
- `flight-tracker/ScreenCornerRadius.swift` — popup corner math
- `flight-tracker/FlightDisplay.swift` — airline names, logos, aircraft specs

---

## PROMPT END

**After pasting:** Tell the agent which Figma file URL or file key to write to, then say:

> Build all 8 Reel screens for iPhone 17 Pro using the figma-export kit. Start with Foundations, then Components, then Reel / 01 — Map Idle. Work sequentially and verify each frame against sample-content.json before moving on.
