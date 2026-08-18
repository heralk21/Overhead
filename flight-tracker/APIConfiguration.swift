import Foundation

/// API keys are injected at build time via `Config/Secrets.xcconfig` → Info.plist.
/// Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig` and fill in values.
enum APIConfiguration {
    private static func plistString(_ key: String) -> String {
        let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        // Xcode leaves unresolved $(VAR) in plist when xcconfig is missing.
        if trimmed.hasPrefix("$(") { return "" }
        return trimmed
    }

    /// Optional RapidAPI AeroDataBox key (extra aircraft seats/engines; app works without it).
    static var aeroDataBoxKey: String { plistString("AERO_DATABOX_API_KEY") }

    /// OpenSky OAuth client id (route lookups; optional).
    static var openSkyClientID: String { plistString("OPEN_SKY_CLIENT_ID") }

    /// OpenSky OAuth client secret (route lookups; optional).
    static var openSkyClientSecret: String { plistString("OPEN_SKY_CLIENT_SECRET") }
}
