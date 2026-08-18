# Overhead — reel assembly guide

Target: **16:9, 1920×1080, 60fps, ~50s.** Music + kinetic type, no voiceover.
Palette: Navy `#0A0F1A` · LED blue `#73B8EB` · Cyan `#61CCF5` · Coral `#EB4848`.

## Timeline (revised per director notes)

| # | Beat | Source | ~Dur | Notes |
|---|------|--------|------|-------|
| 1–3 | Intro (one continuous shot) | `overhead-intro.mp4` ✅ | 9.9s | Dots pop, radar sweep, one ignites coral (LED "SCANNING AIRSPACE") → **continuous zoom INTO the coral dot** → coral morphs into the real `ac_b777` → **zooms out** to the plane as a pin on a faint map grid. No quick card. **Cross-dissolve into your map recording here** (grid → real map, plane = live pin). |
| 3b | App map (tracked plane) | **your recording** ⬜ | ~4s | The followed plane live on the map. Frame at ~8–12° tilt. |
| 4 | Add the widget | **synthetic (me)** + record | ~7s | Home screen → tap **+** → widget gallery → Overhead → add. Inspo-2 callout style. I build home/gallery; you record in-app bits. |
| 5 | Widget wakes | synthetic/record ⬜ | ~5s | Widget shows LED "SCANNING AIRSPACE", then the plane pops on. |
| 6 | Widget → app (lands) | **your recording** + transition | ~6s | Widget's plane zooms up, app opens on that flight, airline details. |
| 7 | Long-press → detail | **your recording** ⬜ | ~6s | Hold "See Airplane Details" → sheet to 60%. Labels: `label-beat4-longpress`, `label-beat4-sheet`. |
| 8 | Logo resolution | `overhead-logo-beat6.mp4` ✅ | 5.6s | Dots → ring + plane → OVERHEAD + tagline. |

## LED section headings (transparent PNG, in `headings/`)
Dot-matrix titles in the app's `LEDLabel` style (5×7 grid, dim off-pixels) — use them to open each section so the video quotes the app's own typography. Files: `led-live-airspace`, `led-tap-to-know`, `led-the-details`, `led-from-anywhere`, `led-on-your-wrist`, `led-overhead`. Animate: dots flicker/type on (0.4s), hold ~1.5s, cut. Center them, upper-third.

## Labels (transparent PNG, in `labels/`)
Descriptive callouts (white SF title + LED-blue accent). Drop over the matching recording. Animate: **fade in 0.3s + slide up 20px**, hold ~2s, fade out 0.3s. Max ~2 labels at once. Lower-left; reposition if it covers the card.

## Framing the recordings (from inspiration video 2)
Don't lay the phone recordings flat. Frame each inside a **subtle 3D perspective tilt** (~8–12° Y-rotation) floating on the navy with a soft drop shadow, like a product hero shot — then cut to a flat straight-on view for the key interaction. Use the labels above as **pointing callouts** to the exact UI element (LED callsign, the long-press button, the widget).

## Export quality (fixed)
Renders now encode at **CRF 14 / preset slow / High profile (~4.8 Mbps)** with anti-banding dither in `common.py` — clean dark gradients, no blockiness. If you re-export the final cut, match: 1080p, H.264 High, CRF 14–18 (or 12–20 Mbps bitrate), 60fps. Avoid CapCut's low "recommended" bitrate default.

## Recording specs (for beats 3–5)
iPhone 15 Pro simulator, status bar `9:41` (see VIDEO_WALKTHROUGH.md), fixed Vancouver location, 60fps, portrait ok (I'll frame inside the 16:9 canvas), slow deliberate taps. ProRes/HEVC both fine.

## Re-rendering any synthetic beat
`python3 render_beatXX.py` — edits to timing/colors are near the top of each script. Encoder is the pip `imageio-ffmpeg` bundled binary (no system ffmpeg needed).

## Music
Pick a driving, minimal electronic track (~50s). Hit the logo-dot alignment (Beat 6, ~2s in) on a downbeat. Duck nothing — no VO.
