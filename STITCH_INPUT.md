# Google Stitch input guide — Overhead

Use this with [Google Stitch](https://stitch.withgoogle.com) and the companion file `design.md`. Upload screenshots first, then paste the prompt below.

---

## 1. Screenshots to capture and upload

Capture in **portrait**, **dark mode**, on a clean status bar (9:41, full battery). Prefer **iPhone 15 Pro** simulator or device at **3x** scale.


| #   | Screen                                        | What it demonstrates                                                                                                                                                                                  |
| --- | --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Map — idle**                                | Full-bleed dark MapKit, nearby white airplane pins, bottom glass pill (list + location), no card open. Shows overall layout and nocturnal tone.                                                       |
| 2   | **Map — plane selected (Quick Card)**         | One pin selected (larger/glow), bottom `QuickCard`: LED callsign, coral airline, route if known, monospaced ALT/SPEED/HEADING/STATUS, glass radius 32, drag handle.                                   |
| 3   | **Quick Card — long-press CTA (mid-gesture)** | Finger on "See Airplane Details" during long-press: label fading, plane icon shifted right (optional: two frames if Stitch needs motion).                                                             |
| 4   | **Flight detail sheet (60% detent)**          | Half sheet over visible map: airline logo (LED matrix), bold airline name, spec rows with blue LED labels, monospaced values.                                                                         |
| 5   | **Flight detail — loading**                   | Same sheet while "Loading more specs…" and skeleton rows visible (pick a flight with slow enrichment or airplane icon loading state).                                                                 |
| 6   | **Board overlay**                             | `BoardOverlay` open: "FLIGHTS" header, monospaced callsign rows (not split-flap), destination/alt/status columns, cyan alt, chevron per row, 44pt map + refresh toolbar, glass panel max ~580pt tall. |
| 6b  | **Board — empty** (optional)                  | "No flights nearby" empty state if you can trigger zero results.                                                                                                                                      |
| 7   | **First-load scanning**                       | "SCANNING AIRSPACE" glass chip centered on map (clear cache or fresh install if needed).                                                                                                              |
| 8   | **Error banner** (optional)                   | Top glass error with coral icon + Retry (airplane mode or blocked network).                                                                                                                           |
| 9   | **Home Screen widget**                        | Medium "Overhead Board" widget: LED bezel, cyan/white dots, refresh button — shows brand extension beyond phone UI.                                                                                   |


**Minimum set for Stitch:** 1, 2, 4, 6 (four screens). Add 3, 5, 9 if you have time.

---

## 2. Ready-to-paste Stitch prompt

**Mode:** Redesign (or Ideate if you want exploratory variants)  
**Format:** Mobile app

```
I'm submitting an iOS product design case study. Use the uploaded screenshots AND the attached design.md spec to extract a cohesive mobile design system, then regenerate key screens that match my existing visual language (not a generic Material or plain iOS template).

App: Overhead — a location-aware flight tracker that shows commercial aircraft overhead on a dark map, with airport LED board typography and frosted glass panels.

Platform: iOS, portrait, dark-only.

Palette (use exactly):
- Navy background #0A0F1A
- Panel/sheet #172430
- LED accent #73B8EB
- Data cyan #61CCF5
- Live/coral #EB4848
- Text: white #FFFFFF, secondary 50% white, tertiary 24% white
- Separators: white 12% opacity
- Widget/LED black #050506

Typography:
- SF Pro system UI for standard text
- Monospaced semibold for flight telemetry (11–13pt)
- Custom 5×7 LED dot-matrix for callsigns and spec labels (glowing dots, dim off-cells)
- Heavy tracked monospaced for "FLIGHTS" board header (~11pt, tracking 3)
- Board list: monospaced semibold ~14pt rows (callsign flexible width), not animated split-flap

Tone: nocturnal, aviation instrument, precise, tactile glass. Inspired by airport departure LED boards (dot-matrix on cards/widget; readable list typography on the board).

Components to preserve:
1. Full-bleed dark map with white airplane pins (heading-rotated)
2. Bottom glass Quick Card (32px corner radius): LED callsign, coral airline, route, data rows, long-press CTA "See Airplane Details"
3. Half-height detail sheet (60% detent) with LED-matrix airline logo and spec list
4. Bottom glass pill: list + location (capsule, blur material)
5. Board overlay list: monospaced flight column, fixed TO/ALT/STATUS columns, chevron affordance, full-row tap target, color-coded status (orange climb, cyan cruise)

Deliverables:
- Design system page: color, type, spacing (4pt base, 20pt screen gutters), radius (3 handle, 16 CTA, 32 card, 36 panel), glass + stroke rules
- Screen designs: Map idle, Map + Quick Card, Detail sheet, Board overlay
- States: loading scan chip, error banner, long-press CTA, skeleton spec rows

Do not switch to light mode. Do not replace LED typography with plain sans-serif for callsigns. Keep map visible behind sheets. Touch targets at least 44pt for primary actions.
```

Attach `**design.md**` in Stitch if the product supports file context; otherwise paste the Color System and Typography sections from it into the prompt.

---

## 3. Refinement checklist (follow-up prompts)

Run these after the first generation if output drifts from the app.

1. **Palette drift**
  "Recolor all backgrounds and accents to match: navy #0A0F1A, panel #172430, LED #73B8EB, cyan #61CCF5, coral #EB4848 only. Remove purple gradients and extra accent colors."
2. **Typography**
  "Quick card callsign and detail spec labels use 5×7 LED dot matrices with glow. Quick card telemetry and board list rows use monospaced semibold (caption/subheadline scale). Board title 'FLIGHTS' uses heavy monospaced with tracking 3. Do not use split-flap animation in the board list."
3. **Glass panels**
  "Cards use frosted glass: heavy blur, 28% black tint, 0.5pt white stroke at 18% opacity, corner radius 32 for quick card and 36 for board. No flat gray cards."
4. **Spacing**
  "Use 20pt horizontal padding inside panels, 10pt outer margin to screen edge, 8pt vertical row padding in data lists. Align to 4pt grid."
5. **Map + sheet composition**
  "Detail sheet stops at 60% screen height so the map stays visible on top. Drag indicator visible. Sheet background #172430, corner radius 28."
6. **Interactive states**
  "Add frames for: selected map pin (larger plane, white glow), long-press CTA with faded label, loading skeleton bars in spec list, coral error banner with Retry."
7. **Board overlay**
  "Monospaced callsign column (flex width), TO 44pt, ALT 48pt cyan, STATUS 58pt color-coded, chevron action 44pt. Full-row tap targets min 52pt height. Toolbar buttons 44pt with 12pt radius. Optional empty state: 'No flights nearby'."
8. **Mobile fidelity**
  "Portrait iPhone safe areas, 44pt minimum tap targets on close and primary actions, dark status bar content."

