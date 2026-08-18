# Overhead — ~2:00 video walkthrough plan

> **Record from:** [`VIDEO_SCRIPT_FINAL.md`](VIDEO_SCRIPT_FINAL.md) (single say + do + design intent table).  
> This file is editing, setup, and backup notes.

**Editor:** CapCut (recommended, ~1–2 hours total). Optional color pass in DaVinci Resolve.  
**Skill level:** Basic to intermediate.  
**Lens:** Product design (problem, hierarchy, interaction), not engineering.

**Core flow to record:** Personal hook (plane watching with friends) → Map → tap pin → **Quick Card** → long-press **See Airplane Details** → **detail sheet**. **High-impact optional beats:** Home Screen **widget** (nearest plane) → tap widget → app opens on that flight → **Apple Watch** glance. Mention: fully working on **your iPhone and Watch**, not just the Simulator.

**Story to weave in:** You and friends go plane watching and compete to guess the **aircraft model**. Today you all **search manually** (FlightAware, Google, etc.). Overhead + widget remove that friction for the **closest plane to you**.

**Record the Simulator app, not Stitch mockups.** Stitch "Redesign" invented a different UI (top header, wrong fonts, lavender buttons). Your submission should match the built app. See `STITCH_INPUT.md`.

---

**Script:** all dialogue and actions are in [`VIDEO_SCRIPT_FINAL.md`](VIDEO_SCRIPT_FINAL.md) (two columns: **Say** · **Do**). No timecodes, no "pick A–D."

---

## B. Recording instructions

### Recommended path: iOS Simulator + macOS capture

Best for clean status bar, repeatable taps, and CapCut import.

1. Open project in Xcode, run **flight-tracker** on **iPhone 15 Pro** simulator.
2. Clean status bar (Terminal):

```bash
xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
```

3. Simulator menu: **Features → Location →** choose a fixed city (e.g. custom near `49.2827, -123.1207` Vancouver default) so flights load consistently.
4. Record with **QuickTime Player → File → New Screen Recording**, select simulator window, or **Cmd+Shift+5** region capture.
5. **Do Not Disturb** on Mac; simulator in **portrait**; window scale **100%** or largest crisp size.
6. Record **2–3 full takes** of the core flow (map → pin → card → long-press → detail). Record **VO separately** in CapCut voice record or Voice Memos for cleaner audio.

### Alternative: On-device iPhone

Higher fidelity motion; use when ADS-B data near you is rich.

1. **Settings → Focus → Do Not Disturb** during capture.
2. Full battery; **Control Center → Screen Recording** (long-press for mic if doing live VO).
3. Or USB to Mac: QuickTime **File → New Movie Recording**, select iPhone camera dropdown for device screen (cleanest wired signal).
4. Same portrait, highest resolution, avoid notifications.

### Prep checklist

- [ ] Location permission granted; wait until pins appear (or use scanning clip intentionally).
- [ ] Disable on-screen keyboard if any field appears // N/A for current build.
- [ ] Reset status bar override after demo: `xcrun simctl status_bar booted clear`
- [ ] **Widget beat on your iPhone:** Home Screen → tap widget → app opens on nearest flight (see section A).
- [ ] **Watch beat (optional):** 2–3s of Overhead on Apple Watch.
- [ ] Say once on camera or VO: app is **live on your iPhone + Watch**, not Simulator-only.
- [ ] Optional: board overlay, Stitch tab (skip if deadline is tight).

---

## C. Editing guide (CapCut, time-boxed)

| Step | Task | Time | Cut first if late |
|------|------|------|-------------------|
| 1 | Import best take + optional VO track; sync | 10 min | — |
| 2 | Trim dead air; keep hook under 15s | 10 min | — |
| 3 | Speed-ramp slow map pans **1.5–2×** (only between taps) | 8 min | Reduce to one ramp |
| 4 | Auto-captions → proofread names (Overhead, Shopify) | 12 min | Fix only misheard words |
| 5 | **2–3 punch-in zooms** (callsign LED, long-press CTA, detail sheet) | 15 min | Drop to 2 zooms |
| 6 | On-screen labels (3 max): e.g. "LED hierarchy", "60% sheet", "Long-press affordance" — SF style, white text, `#73B8EB` accent line | 12 min | Drop to 1 label |
| 7 | Title card 3s: Overhead + Design Apprentice — Product Design | 8 min | Static text only |
| 8 | End card 3s + // TODO: confirm contact | 5 min | Single line end |
| 9 | Royalty-free music (low volume); duck under VO | 10 min | Skip music |
| 10 | Color: slight contrast bump only; match navy `#0A0F1A` in letterbox if needed | 8 min | Skip |
| 11 | Export **1080p**, **30 fps** (60 if screen recording is 60) H.264 | 5 min | — |

**Budget total:** ~1h 45m. **Hard stop at 2h:** skip music, reduce labels/zooms, single take only.

### CapCut specifics

- **Ratio:** 9:16.
- **Captions:** Auto → Style: simple white, dark semi box.
- **Zoom:** Keyframe scale ~115% for 1.5s on UI moments.
- **Fonts:** System-like sans for labels (caption font close to SF Pro).
- **Export:** 1080×1920, recommended bitrate default.

### DaVinci optional (10 min)

- Noise reduction on VO only; lift shadows slightly on screen recording; no heavy grade (preserve LED colors).

---

## Design callouts to align with `design.md`

Use these if you add text overlays:

- Palette: Navy `#0A0F1A`, LED `#73B8EB`, Coral `#EB4848`, Cyan `#61CCF5`
- Glass: blur + thin white stroke, radius 32 card / 36 board
- Typography: LED dot callsign + monospaced telemetry
- Interaction: long-press detail CTA; sheet at 60% detent; board rows full-width tap with chevron
