import Foundation

/// Opens a specific aircraft in Overhead from the home-screen widget (`overhead://flight/{icao24}`).
enum FlightDeepLink {
    static let scheme = "overhead"

    static func url(icao24: String) -> URL? {
        let id = icao24.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !id.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = "flight"
        components.path = "/\(id)"
        return components.url
    }

    static func icao24(from url: URL) -> String? {
        guard url.scheme?.lowercased() == scheme,
              url.host?.lowercased() == "flight" else { return nil }
        let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        return id.isEmpty ? nil : id
    }
}
