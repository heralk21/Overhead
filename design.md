# Overhead — Design System

## Overview

Overhead is an iOS app for people who look up when they hear a plane and want to know what is flying overhead. It uses your location and live ADS-B data (OpenSky) to show commercial aircraft on a dark map, with airport-style LED typography and glass panels for quick flight facts and deeper aircraft specs. The core problem it solves is turning an invisible sound in the sky into a readable, trustworthy answer without opening a heavy flight-tracking site.

- Platform: iOS (mobile). Companion surfaces: Home Screen widget ("Overhead Board"), Apple Watch LED display, deep links via `overhead://flight/{icao24}`.
- Design language: Custom dark UI inspired by airport departure LED boards (LED callsigns on cards, widget, and spec labels), layered on native iOS patterns (MapKit map, SwiftUI sheets, SF Symbols, `.ultraThinMaterial` glass, Dynamic Type on the flight list).
- Visual tone: Nocturnal, instrument-panel, aviation-native, precise, tactile glass.

## Handoff note (Stitch / Figma)

This document describes the **shipped iOS app** (`flight-tracker/ContentView.swift`), not a web-style kit. If a tool outputs **JetBrains Mono**, **Inter**, lavender filled buttons, a persistent top app bar, or Home/Search/Profile navigation, that output is **wrong** and should be discarded.

**Source of truth:** Simulator screenshots of the running app, plus this file. App name is **Overhead** (not "Nocturnal Aviation").

## Explicitly NOT in this app

Do not add these when extending the design system or regenerating screens:

| Anti-pattern | What Overhead actually does |
|--------------|----------------------------|
| Top header with logo, settings, "SCANNING 124.7 MHz" | No global header on the map. Loading copy is a **centered glass chip**: "SCANNING AIRSPACE" (only while empty + loading). |
| Map zoom +/- controls, custom compass FAB | MapKit only. User pans/pinches. **Bottom glass pill**: list icon + location/refresh (capsule). |
| Tab bar or Home / Search / Profile nav | Single map screen. No tabs. |
| JetBrains Mono, Inter, or other desktop fonts | **SF Pro** via `Font.system(...)`. Monospaced **design** for data. LED callsigns are **Canvas dot matrices**, not a font file. |
| Lavender / purple primary buttons | CTAs are **frosted glass** (`GlassBg`, `.ultraThinMaterial`). No filled brand-primary buttons on map flow. |
| Flat opaque grey cards | Panels use **blur + 28% black tint + hairline white stroke**. |
| LED callsign as plain bold sans | Quick card callsign = **5×7 glowing dots** (`LEDLabel`). |
| Square red airline icon in detail header | **LED-matrix airline logo** (`AirlineLogoView`, ~56pt) or IATA LED fallback. |
| "HOLD TO…" wide pill CTA in detail sheet | Detail opens from quick card via **long-press** on glass button: **"See Airplane Details"** (plane icon animates). Sheet has **X close**, spec rows, no hold CTA. |
| Board column "FLIGHT TO" merged | Four headers: **FLIGHT** | **TO** | **ALT** | **STATUS** + chevron column. Alt often **12K** style (`34K`), not `34,000`. |
| Split-flap animation in board list | Monospaced **static** callsign text in rows. |
| Dot-grid marketing background on system page | Optional in Figma; **not** in the iOS UI. |
| Web design-system components (search input, pencil FABs, trash chips) | Not in app. |

## Color System

Colors are defined in code (`enum C` in `ContentView.swift`) and in brand docs (`Brand/LogoConcepts/README.md`). `Assets.xcassets/AccentColor` is unset (universal placeholder only). No light mode: `.preferredColorScheme(.dark)` on the root view.

### Primary / Secondary / Accent

| Role | Name | HEX | Usage |
|------|------|-----|--------|
| Primary | Navy | `#0A0F1A` | Map chrome, brand base (`C.navy`, `rgb(0.04, 0.06, 0.10)`) |
| Secondary | Panel | `#172430` | Sheet background (`C.panelBg`, presentation background) |
| Accent | LED Blue | `#73B8EB` | Headers, links, LED labels, loading tint (`C.ledBlue`) |
| Accent | Cyan | `#61CCF5` | Altitude / cruise data emphasis (`C.cyan`) |
| Accent | Coral | `#EB4848` | Airline name in quick card, errors (`C.coral`) |
| Accent | Blue | `#1A42FF` | Defined as `C.blue`; limited in current UI // TODO: confirm primary CTA usage |

### Neutral & gray scale

| Token | HEX / value | Usage |
|-------|-------------|--------|
| Text primary (`C.t1`) | `#FFFFFF` | Headlines, values |
| Text secondary (`C.t2`) | `#FFFFFF` at 50% opacity | Labels, subtitles |
| Text tertiary (`C.t3`) | `#FFFFFF` at 24% opacity | Handles, de-emphasized chrome |
| Separator (`C.sep`) | `#FFFFFF` at 12% opacity | 0.5pt row dividers |
| Detail screen fill | `#141C29` | `FlightDetailView` background (`rgb(0.08, 0.11, 0.16)`) |
| Flap tile fill | `#171F29` | Legacy split-flap component in code (`rgb(0.09, 0.12, 0.16)`); not used in current board list UI |
| Glass tint | `#000000` at 28% over blur | `GlassBg` inner fill |
| Glass stroke | `#FFFFFF` at 18% opacity, 0.5pt | Panel edges |
| Widget / LED bezel bg | `#050506` | Widget canvas (`rgb(0.018, 0.018, 0.025)`) |
| Logo tile bg | `#050508` | Airline LED logo backing (`rgb(0.02, 0.02, 0.03)`) |

### Semantic

| Role | HEX | Usage |
|------|-----|--------|
| Error | `#EB4848` (`C.coral`) | Error banner icon, retry adjacent copy |
| Warning | System Orange | Board row status: Takeoff, Climb |
| Success | // TODO: confirm | Not defined as a dedicated token |
| Info | `#73B8EB` / `#61CCF5` | Loading states, cruise / high-alt status |

### Background & surface

| Surface | HEX | Notes |
|---------|-----|--------|
| Map | MapKit dark standard | Full-bleed under UI |
| Glass panel | `.ultraThinMaterial` + `#000000` 28% + stroke | `GlassBg`, `QuickCard`, `BoardOverlay`, banners |
| Bottom pill | `.ultraThinMaterial` + capsule stroke 15% white | Floating controls |
| Sheet | `#172430` | `presentationBackground(C.panelBg)`, corner radius 28 |

### Airline brand accents (contextual)

Airline-specific LED/logo colors (e.g. Air Canada `#E6141A`, WestJet `#00A6A6`) are mapped in `airlineLEDColor` / `AirlineLogo.brandColor`. Default fallback: `#73B8EB`.

### Light / dark mode

Dark only in the main app. Widget and watch use the same dark LED palette.

## Typography

### Font families

- **Only iOS system fonts.** Primary and UI: **SF Pro** via `.font(.system(...))`.
- **Monospaced data:** `.font(.system(..., design: .monospaced))` or `.system(.caption, design: .monospaced)` (Dynamic Type).
- **LED display type:** Not a font. Rendered by `LEDLabel` (5×7 dot bitmap in code). Use dot-matrix **visual** in mocks; do not substitute JetBrains Mono or Inter.
- No `UIAppFonts`, no JetBrains Mono, no Inter // TODO: confirm if marketing site uses separate fonts later.

### Type scale

| Style | Size (pt) | Weight | Design | Usage |
|-------|-----------|--------|--------|--------|
| Display LED (callsign) | ~6.5 dot pitch (scales) | N/A | Custom 5×7 dot matrix (`LEDLabel`) | Quick card callsign |
| H1 | 20 | Bold | Default | Airline name in detail sheet |
| H2 | 18 | Semibold | Default | CTA plane icon |
| Body / CTA | 16 | Semibold | Default | "See Airplane Details" |
| Body | 13 | Semibold | Monospaced | Airline in quick card |
| Data label / value | Dynamic **Caption** (~12pt default) | Medium / Semibold | Monospaced | Quick card telemetry rows (`qRow`) |
| Data label | 11 | Medium | Monospaced | Spec skeleton labels |
| Data value | 12 | Regular | Monospaced | Spec row values |
| Board title | 11 base (`@ScaledMetric` → caption) | Heavy | Monospaced, tracking 3 | "FLIGHTS" toolbar title |
| Board column | 11 base | Heavy | Monospaced, tracking 1.2 | Column headers (LED blue 85%) |
| Board row | 14 base (`@ScaledMetric` → subheadline) | Semibold | Monospaced | Callsign, destination, alt, status |
| Caption / loading | 10 | Heavy | Monospaced, tracking 2 | "SCANNING AIRSPACE" |
| Pin (map) | 13 / 20 | Medium / Semibold | Default | Unselected / selected aircraft |
| Bottom pill icons | 17 | Medium | Default | List, location |
| Error | 12 | Medium / Semibold | Default | Banner copy, Retry |

### Line height & letter spacing

- `tracking(0.3)` on spec row values.
- `tracking(1.2)` board column headers; `tracking(2)` scanning label; `tracking(3)` "FLIGHTS" title.
- Board and quick-card row fonts scale with **Dynamic Type** via `@ScaledMetric` (board) and `.caption` (quick card).
- LED labels: vertical centering via geometry; height = `7 × dotPt`.
- No explicit line-height tokens // TODO: confirm if Stitch needs fixed line heights per style.

## Spacing Scale

No formal spacing enum. Recurring values suggest a **4pt base** with common steps:

| Token | pt | Observed usage |
|-------|-----|----------------|
| xs | 4 | Icon gaps, VStack tight groups |
| sm | 8 | Row padding vertical (quick card), close button trailing |
| md | 12 | Toolbar padding, board row vertical |
| lg | 16–20 | Horizontal screen/panel padding (dominant **20**) |
| xl | 34 | Bottom pill offset from safe area |
| 2xl | 40 | Quick card max height fraction // TODO: confirm naming |

**Board overlay constants:** `hPad` = 20; column widths — To **44**, Alt **48**, Status **58**, Action **44**; flight column flexible; row `minHeight` **52** (scales with Dynamic Type).

## Layout & Grid

- **Screen padding:** 10pt outer margin on glass overlays (quick card, board); 20pt inner content padding on cards and detail sheet.
- **Safe area:** Map `ignoresSafeArea()`; board overlay `ignoresSafeArea(edges: .bottom)`; error banner `padding(.top, 56)` below status bar.
- **Quick card:** Max height ~40% of screen (`geo.size.height * 0.40`), horizontal inset 10.
- **Detail sheet:** iOS 16+ detents `.fraction(0.60)` and `.large` so map remains visible above sheet.
- **Board grid:** `HStack` with flexible callsign column + fixed To / Alt / Status / chevron columns; 10pt inter-column spacing.
- **Patterns:** Full-bleed map + bottom anchored glass card; bottom sheet list overlay; modal half-sheet for specs.

## Components

### Primary CTA — `DetailAnimButton`

- **Visual:** Glass panel (radius 16), height 54, label "See Airplane Details", airplane SF Symbol with LED blue glow shadow.
- **Variants:** Default (label visible); long-press (label fades, plane animates right).
- **States:** Default; pressing (`@GestureState`); triggers detail on long-press end (0.55s). Not a tap button.
- **Interaction:** `LongPressGesture(minimumDuration: 0.55)`.

### Ghost / icon buttons

- **Map / refresh (board toolbar):** **44×44**, radius 12, fill white 9%, stroke separator. Labels: "Back to map", "Refresh flights".
- **Close (quick card):** 32pt circle, 44×44 hit target, xmark 11pt bold. Label: "Dismiss".
- **Close (detail):** 38pt circle. Label: "Close".
- **Dismiss:** No disabled style in code.

### Bottom pill (`bottomPill`)

- **Visual:** Capsule, `.ultraThinMaterial`, 0.5pt vertical divider (white 18%).
- **Actions:** List (opens board), location/refresh (shows `ProgressView` while loading).
- **States:** Default; loading on refresh half.
- **Accessibility:** "Flight list" + hint; refresh label reflects loading state.

### Text inputs

- None in current UI // TODO: confirm if search is planned.

### Cards

#### `QuickCard`

- Glass `radius: 32`, drag handle 36×4 (radius 3), LED callsign, monospaced data rows, coral airline + route, `DetailAnimButton`.
- **States:** Shown when `quickFlight` set; hidden when board open.

#### `BoardOverlay`

- Glass `radius: 36`, max height 580, clipped continuous rounded rect.
- **List rows:** Monospaced semibold callsign (not split-flap); destination (`—` if unknown, tertiary color); cyan altitude; color-coded status; **chevron.right** in action column.
- **Interaction:** Entire row is a plain `Button` (min height 52pt); opens flight detail sheet. Hint: "Opens flight details".
- **Empty state:** "No flights nearby" (subheadline monospaced).
- **States:** Open/closed via spring animation; refresh reloads flights; `LazyVStack` + bounce based on size.

#### `FlightDetailView`

- Flat `#141C29` screen in sheet; `AirlineLogoView` 56pt; `SpecRow` list; skeleton rows while API loads; empty state copy.

### Navigation

- **No tab bar.** Single map root.
- **Bottom pill:** List toggle + locate/refresh (not a classic tab bar).
- **Sheets:** `FlightDetailView` with drag indicator (iOS 16+).
- **Back:** Swipe/drag on sheet; xmark; quick card dismiss returns to map overview zoom.

### List rows

- **Quick card `qRow`:** Label left (t2), value right (t1), 8pt vertical padding; combined VoiceOver label per row (e.g. "Altitude, 35000 FT").
- **Board row:** Full-width tappable row; callsign + dest + alt + status + chevron; rich accessibility label (airline, flight, destination, altitude, status).
- **Spec row:** LED blue label left, monospaced value right, 15pt vertical padding, separator.

### Modals / sheets

- **Flight detail:** Half and full detents, corner radius 28, background `#172430`.
- **Board:** Custom overlay (not system sheet), slides from bottom.

### Map pins (`LiveMap` / `FlightPin`)

- White SF Symbol airplane, rotated to heading; selected: larger, stronger white shadow.
- **States:** Default; selected (scale 1.3, spring animation).

### LED label (`LEDLabel`)

- Custom Canvas dot matrix; dim off-pixel dots at 7% opacity; glow shadow `radius: pt × 0.55`.
- Auto-scales to fit width.

### Glass panel (`GlassBg`)

- **Variants:** `radius` default 36; 16–32 on cards; 20 on loading chip.
- **States:** Static (no pressed state).

### Loading / error

- **Scanning overlay:** Glass radius 20, `ProgressView` tinted LED blue.
- **Error banner:** Top glass card, coral warning icon, Retry text button (ledBlue).
- **Spec skeleton:** Pulsing placeholder bar, 75ms repeat animation.

### Airline logo (`AirlineLogoView`)

- LED rasterized logo, text mark (e.g. WS), or fallback IATA / airplane icon.
- **States:** Loading (`ProgressView`); loaded grid; fallback.

## Border Radius & Shadow

| Element | Corner radius (pt) | Shadow / elevation |
|---------|-------------------|-------------------|
| Glass panels (default) | 36 | No drop shadow; material blur |
| Quick card | 32 | Same as GlassBg |
| Detail CTA | 16 | Plane icon: ledBlue 50%, radius 4 |
| Board toolbar buttons | 12 | None |
| Sheet (system) | 28 | System sheet shadow |
| Airline logo tile | 10 (continuous) | Brand color 35%, radius 6 |
| Drag handle | 3 | None |
| Flap tile (legacy, unused in board) | 3 | 3D flip effect if re-enabled |
| Bottom pill | Capsule | Stroke only |
| Map pin (selected) | N/A | White shadow radius 5, opacity 0.55 |
| LED label | N/A | Color glow, radius `dotPt × 0.55` |
| Widget bezel | 10 | Gradient stroke 3pt, no drop shadow |

## Mobile-Specific Notes

- **Minimum touch target:** Quick card close and board toolbar buttons use **44×44** pt. Board rows use `minHeight` 52pt and full-row `contentShape` for tap.
- **Safe area:** Bottom pill `padding(.bottom, 34)`; map full bleed; sheet preserves top map peek at 60% detent.
- **Status bar:** Dark content on dark map; use Simulator status bar override for demos (see `VIDEO_WALKTHROUGH.md`).
- **Navigation:** No navigation stack; pinch/pan map; tap pin to select; tap pin again to deselect; board slides over map; tap any board row or open from board → detail sheet; system sheet drag to dismiss.
- **Gestures:** Long-press on detail CTA; map pan/zoom; sheet drag indicator on iOS 16+.
- **Dynamic Type:** Board header/row fonts and row height scale via `@ScaledMetric`; quick card telemetry uses semantic `.caption`.
- **Haptics:** None implemented // TODO: confirm if long-press should add light impact.
- **Accessibility:** VoiceOver on dismiss/close, board toolbar, pill, board rows (combined labels + hints), quick card rows, and "FLIGHTS" header trait. **LED callsign on quick card** has `accessibilityLabel("Flight {callsign}")` but remains visually dot-matrix // TODO: confirm LED spec labels in detail sheet for VoiceOver.
