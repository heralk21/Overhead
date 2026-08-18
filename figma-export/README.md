# Overhead — Figma Export Kit

Everything you need to rebuild the Overhead app UI in Figma with accurate layers, assets, and sample content.

## Folder structure

```
figma-export/
├── manifest.json           ← Asset catalog + Figma component naming
├── sample-content.json     ← Screen-by-screen demo data + design tokens
├── assets/
│   ├── airline-logos/      ← 44 bundled airline PNGs
│   ├── aircraft/           ← 29 top-down aircraft PNGs
│   └── app-icon/           ← App logo
├── led-font/
│   ├── manifest.json       ← LED glyph + word inventory
│   ├── chars/              ← 126 individual character SVGs (3 variants each)
│   └── words/              ← 28 pre-composed LED strings at correct dot sizes
└── scripts/
    └── generate_led_svgs.py
```

## Quick start in Figma

### For Claude / Cursor + Figma MCP (product reel)
| Prompt file | Use for |
|-------------|---------|
| `FIGMA-MCP-BUILD-PROMPT.md` | 8 app UI screens (402×874) |
| `FIGMA-MCP-CINEMATIC-PROMPT.md` | **9 cinematic landscape frames (1920×1080)** |
| `hero-flight-ticket-spec.json` | Exact layer spec for climax ticket card |
| `OVERHEAD-REEL-CREATIVE-GUIDE.md` | Creative direction + Jitter workflow |
| `overhead-cinematic-storyboard.json` | Shot timing for Jitter |

### Manual import
- Drag `assets/airline-logos/*.png` into Figma → create components named `Logo/Airline/{name}`
- Drag `assets/aircraft/*.png` into Figma → create components named `Icon/Aircraft/{type}`
- Drag `led-font/words/*.svg` into Figma for ready-made LED text
- Drag `led-font/chars/*.svg` if building custom LED strings

### 2. Set up tokens
Open `sample-content.json` → copy `designTokens` into Figma Variables:
- Colors (navy, ledBlue, coral, climb, etc.)
- Spacing (screenMargin 10, cardPaddingH 20, etc.)
- Corner radii (popup top 28, bottom 47)

### 3. Build screens
Use `sample-content.json` → `screens` section. Each key is a frame name:
- `iOS / Map / Default`
- `iOS / Quick-Card / Default`
- `iOS / Detail / Loaded`
- `iOS / Board / With-Flights`
- Widget + Watch variants

### 4. Wire prototype
Use `prototypeConnections` in `sample-content.json` for interaction mapping.

## LED font usage

| Context | dotPt | Pre-built SVG |
|---------|-------|---------------|
| Quick card callsign | 6.5 | `led-font/words/quick-callsign-aca873-6.5pt.svg` |
| Board title | 3.0 | `led-font/words/board-title-3.0pt.svg` |
| Board callsign | 2.0 | `led-font/words/board-callsign-*.svg` |
| Spec labels | 2.2 | `led-font/words/spec-*.svg` |
| Scanning overlay | 1.9 | `led-font/words/scanning-overlay-1.9pt.svg` |

To regenerate after FONT table changes:
```bash
python3 figma-export/scripts/generate_led_svgs.py
```

## Airline logo lookup

See `manifest.json` → `airlineLogos` for ICAO prefix → file mapping.
Example: callsign `ACA873` → ICAO `ACA` → `assets/airline-logos/air_canada.png`

## Glass popup shell

Card width = **373pt** (393 − 20 margin).
- Top corners: **28pt** continuous
- Bottom corners: **47pt** continuous (iPhone 15 Pro concentric)
- Border: white 12%, 0.5px
- Shadow: Y −6, blur 22, black 32%
- Fill: background blur ~40, white ~8%

## Sample flights

Five realistic demo flights in `sample-content.json` → `sampleFlights`:
ACA873, WJA158, DAL412, UAL892, SWA2847

Use these across map pins, quick card, board rows, detail view, widget, and watch.
