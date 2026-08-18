# App Store checklist

## Before you upload

### App icon (required)
Add a **1024×1024** PNG to `flight-tracker/Assets.xcassets/AppIcon.appiconset/` and set `filename` in `Contents.json` for each size slot, or drag images into Xcode’s App Icon set.

Repeat for:
- `FlightTrackerWatch Watch App/Assets.xcassets/AppIcon.appiconset`
- Widget icon if you ship a branded widget

Validation fails if the main app icon is missing.

### API keys
1. Copy `Config/Secrets.xcconfig.example` → `Config/Secrets.xcconfig`
2. Add keys (file is gitignored)
3. **Rotate** any keys that were ever committed in source control (RapidAPI / OpenSky)

The app works without keys; AeroDataBox and OpenSky only improve routes and extra aircraft fields.

### Location
`NSLocationWhenInUseUsageDescription` is set in the Xcode target. Test on a real device: deny → Settings path; allow → map centers on you.

### Privacy
`PrivacyInfo.xcprivacy` is included for the app and widget. Update App Store Connect **App Privacy** to match (precise location for app functionality, not linked, not used for tracking).

### Widget
Only the flight board widget ships (placeholder Live Activity and Control widgets were removed).

### Review notes (suggested)
- App uses public ADS-B feeds (airplanes.live / adsb.lol); no account required.
- Location is used only to show nearby traffic.
