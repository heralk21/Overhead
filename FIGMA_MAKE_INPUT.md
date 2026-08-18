# Figma Make prompt guide — Overhead

Use with [Figma Make](https://www.figma.com/) (AI design generation). Pair with **`design.md`** (tokens) and **Simulator screenshots** (layout truth). Do not feed prior Stitch outputs as reference.

**Frame:** iPhone 15 Pro, **393 × 852**, portrait, dark mode only.

---

## Before you prompt

1. Export **4–6 PNGs** from the iOS Simulator (see screenshot list below).
2. In Figma Make, **attach those images** to the prompt when the UI allows it.
3. Prefer **"match" / "edit" / "from image"** style flows over open-ended "create a new aviation app."
4. If Make invents a top header, Inter, or lavender buttons, paste a **recovery prompt** from section 4.

### Screenshots to attach (minimum)

| File | Must show |
|------|-----------|
| Map idle | Full-bleed map, plane pins, **bottom glass pill only** (no top bar) |
| Quick card | LED dot callsign, coral airline, telemetry rows, **See Airplane Details** |
| Detail sheet | Map visible above sheet (~60%), LED airline logo, spec rows, **X** close |
| Board | Glass panel, **FLIGHTS**, columns FLIGHT / TO / ALT / STATUS, chevrons |

Optional: scanning chip, error banner, widget, long-press CTA mid-gesture.

---

## 1. Main prompt (design system + 4 screens)

Copy everything inside the block into Figma Make.

```
Project: Overhead — iOS flight tracker (existing shipped app). 
I attached screenshots of the REAL app. Match them. Do not redesign into a different product.

PRODUCT
Overhead shows commercial aircraft on a dark map near the user. Airport LED board aesthetic: dot-matrix callsigns, frosted glass cards, monospaced flight data. One map screen, no tabs.

PLATFORM
- Mobile iOS, portrait 393×852
- Dark mode only
- SF Pro for UI; SF Mono for data tables
- LED callsigns = 5×7 DOT GRID with glowing round dots and dim off-dots (NOT bold sans, NOT JetBrains Mono, NOT Inter)

COLORS (use exactly, no extra accent hues)
- Navy #0A0F1A
- Panel / sheet #172430
- LED blue #73B8EB (headers, links, LED label color)
- Cyan #61CCF5 (altitude, cruise status)
- Coral #EB4848 (airline name in quick card, errors)
- Text primary #FFFFFF
- Text secondary #FFFFFF 50%
- Text tertiary #FFFFFF 24%
- Separator #FFFFFF 12%
- Detail fill #141C29 (inside sheet content area)
- Glass: background blur + #000000 28% overlay + 0.5px border #FFFFFF 18%

CORNER RADIUS
- Drag handle 3
- Toolbar chips 12
- Detail CTA 16
- Quick card 32
- Board / large glass 36
- Sheet top 28
- Airline LED logo tile 10

SPACING
- 4pt base grid
- Screen edge inset for floating panels: 10
- Panel inner padding: 20
- Row vertical padding: 8 (quick card), 52 min height (board rows)

GLASS COMPONENT RULE
Frosted translucent panel: heavy background blur, black 28% tint, 0.5pt white hairline at 18% opacity. No flat #333 cards. No lavender filled primary buttons.

TYPOGRAPHY
- Airline in quick card: 13pt semibold monospaced, coral
- Telemetry labels/values: caption-scale monospaced (~12pt), label 50% white, value white semibold
- Board "FLIGHTS": heavy monospaced, #73B8EB, letter-spacing +3
- Board column headers: heavy monospaced 11pt, #73B8EB 85%, tracking +1.2
- Board rows: semibold monospaced 14pt; alt in cyan; status orange (climb) or cyan (cruise) or blue default
- Detail airline name: 20pt bold white

FORBIDDEN (do not generate)
- App name other than Overhead (not "Nocturnal Aviation")
- Top navigation bar on map (no logo strip, no settings, no "124.7 MHz" in header)
- Map zoom +/- buttons, compass FAB, tab bar, Home/Search/Profile nav
- JetBrains Mono, Inter, Roboto, purple/lavender primary buttons
- Merged board column "FLIGHT TO" (must be separate FLIGHT and TO)
- Plain bold text for flight ID on quick card (must be LED dots)
- Red square airline logo; use LED dot-matrix logo square ~56px
- "HOLD TO" or primary button inside detail sheet
- Split-flap animated letters in board list (static monospaced callsigns only)
- Web-only kit pieces: search bars, pencil FABs, trash icon chips, 10-step color marketing scales unless sampled from UI

SCREENS TO CREATE (4 frames, auto-layout, name layers clearly)

Frame 1 — Map idle
- Edge-to-edge dark map placeholder (subtle, not decorative grid)
- Several small white airplane icons, one optional soft glow if selected
- Bottom center: frosted glass CAPSULE, two zones: list icon | location icon, vertical hairline between
- Status bar iOS style, time 9:41
- Nothing else floating on map

Frame 2 — Map + quick card
- Same map, selected plane with white glow in upper area
- Bottom glass card (r32): top drag pill 36×4; close X 44×44 top right
- LED dot-matrix callsign large (e.g. ACA829)
- Row: coral airline left, route YYZ → YVR right monospaced
- Rows: ALTITUDE / SPEED / HEADING / STATUS with monospaced values
- Glass button 54px tall: airplane icon left, label "See Airplane Details"
- Bottom pill may hide behind card (ok)

Frame 3 — Detail sheet 60%
- Map visible in top ~40% of frame
- Sheet #172430, top corners 28, drag indicator
- Close X top right
- Row: LED logo 56 + airline name bold + optional "Loading more specs…"
- Spec rows: left label as small blue LED dots spelling TYPE, REGISTRATION, etc.; right value monospaced white
- Dividers 0.5px white 12%
- No bottom CTA in sheet

Frame 4 — Board overlay
- Map dimmed/full behind bottom sheet
- Glass panel r36, max height ~580, handle on top
- Toolbar: 44px map button left, FLIGHTS center tracked blue, 44px refresh right
- Table header: FLIGHT | TO | ALT | STATUS
- 3–4 rows: callsign | airport code | 34K cyan | CRUISE cyan | chevron right
- One row CLIMB status in orange

Also output a compact Design system page on a separate frame:
- Color swatches (6 core hexes only)
- Type specimens: SF Pro body, SF Mono data, LED component sample
- Components: Glass panel, LED label, Bottom pill, Board row, Map pin
- Short glass rule text
- No web nav, no Inter, no lavender buttons

Style: nocturnal, precise, aviation instrument. High fidelity iOS, not Material, not Dribbble generic dashboard.
```

---

## 2. Short prompt (screens only, if character limit)

```
Overhead iOS app — match attached screenshots exactly. Dark map full bleed, no top header. Bottom glass pill (list + location). Quick card: LED DOT MATRIX callsign, coral airline, monospaced ALT/SPEED/HEADING/STATUS, glass "See Airplane Details". Detail sheet 60% height #172430, LED airline logo, blue LED spec labels. Board: FLIGHTS, columns FLIGHT|TO|ALT|STATUS, chevrons. Colors: #0A0F1A #172430 #73B8EB #61CCF5 #EB4848. SF Pro + SF Mono only. Glass = blur + 28% black + white 18% stroke. NO Inter, NO JetBrains, NO tabs, NO zoom buttons, NO lavender buttons. iPhone 15 Pro 393×852 portrait.
```

---

## 3. Design system page only

Use when screens already exist and you only need tokens/components.

```
Create one Figma frame: "Overhead — Design system" for an existing iOS app.

Extract from attached screenshots only. App name Overhead.

Colors (swatches): #0A0F1A navy, #172430 panel, #73B8EB LED, #61CCF5 cyan, #EB4848 coral, #FFFFFF + 50% + 24% text, #050506 widget black.

Typography specimens:
- SF Pro 20 bold (headline)
- SF Pro 16 semibold (CTA label)
- SF Mono 12 medium / semibold (data)
- LED component: 5×7 dot grid with glow (describe as component, not Inter)

Components with variants:
1. Glass panel — blur, 28% black, 0.5px white 18% border; radii 16 / 32 / 36
2. Bottom pill — capsule, two icon slots, divider
3. Quick card row — label t2, value t1
4. Board row — callsign, dest, alt cyan, status color, chevron
5. Map pin — white airplane 13px and selected 20px with glow
6. LED logo tile 56px r10

Spacing scale: 4, 8, 10, 12, 20, 34, 44, 52.

Do NOT include: search inputs, tab bars, Home/Profile icons, JetBrains/Inter, purple primary buttons, dot-grid poster background, or "Nocturnal Aviation" title.
```

---

## 4. Recovery prompts (paste one at a time)

**Remove header**
```
Delete the top app bar completely. Map must extend under the status bar. No logo, no MHz text, no settings gear in the header area.
```

**Fix fonts**
```
Change all text to SF Pro or SF Mono. Remove JetBrains Mono and Inter everywhere. Flight callsign on quick card must be a dot-matrix LED component.
```

**Fix board**
```
Board table needs five zones: flexible FLIGHT callsign, TO 44px, ALT 48px cyan, STATUS 58px, chevron 44px. Headers spelled FLIGHT, TO, ALT, STATUS. Alt format 34K not 34,000.
```

**Fix detail sheet**
```
Remove HOLD TO button. Add LED-matrix airline logo 56px. Spec rows with blue LED labels on left. Sheet height 60% so map shows on top. Background #172430.
```

**Fix colors**
```
Remove lavender and purple. Primary surfaces are navy #0A0F1A and glass blur. Accents only #73B8EB #61CCF5 #EB4848.
```

---

## 5. Per-screen micro-prompts

Use to regenerate a single frame without redoing the file.

| Frame | Prompt |
|-------|--------|
| Map idle | `iPhone dark map edge-to-edge, white airplane pins, only bottom frosted capsule with list and location icons, 10px margin, no top UI, #0A0F1A feel` |
| Quick card | `Bottom glass card r32, LED dot callsign ACA829, coral AIR CANADA, monospaced flight data rows, glass button See Airplane Details with plane icon, 20px inner padding` |
| Detail | `iOS half sheet 60%, #172430, map peek top, LED airline logo, spec list blue LED labels, X close, no CTA button` |
| Board | `Bottom glass sheet r36, FLIGHTS title, table FLIGHT TO ALT STATUS, cyan 34K, chevron rows, map and refresh 44px buttons` |

---

## 6. After Make: manual polish in Figma

Make may not render real iOS blur. Touch up in 10–15 minutes:

1. Replace map placeholder with a cropped Simulator screenshot.
2. LED callsign: paste from app screenshot or rebuild with a 5×7 dot component.
3. Apply **background blur** (40–80) + fill `#000000` 28% on glass layers.
4. Enable **SF Pro** / **SF Mono** from Figma font picker (or iOS font if installed).
5. Compare frame to Simulator side-by-side using `design.md` anti-patterns table.

---

## 7. Case study export

For Shopify or portfolio:

- **Truth frame:** Simulator screenshot (annotated).
- **System frame:** Figma Make output after recovery prompts.
- **Caption:** "Built in SwiftUI; Figma Make used to document tokens from production UI."

Link to `design.md` for engineering handoff.
