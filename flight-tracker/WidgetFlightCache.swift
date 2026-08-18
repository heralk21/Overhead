import CoreLocation
import Foundation

/// Keeps small and medium widgets on the same nearby flight between reloads at one place.
enum WidgetFlightCache {
    private struct Snapshot: Codable {
        let flight: Flight
        let latitude: Double
        let longitude: Double
        let savedAt: Date
    }

    private static let fileName = "widget_pinned_flight.json"
    private static let stickRadiusMeters: CLLocationDistance = 25_000

    private static var fileURL: URL {
        if let group = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.HK.flight-tracker"
        ) {
            return group.appendingPathComponent(fileName)
        }
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(fileName)
    }

    static func pinnedFlight(in flights: [Flight], near coord: CLLocationCoordinate2D) -> Flight? {
        guard let cached = load(), isNear(cached, coord) else { return nil }
        return CommercialFlightFilter.commercialFlights(from: flights)
            .first { $0.icao24 == cached.flight.icao24 }
    }

    /// Prefer the cached flight while still near the user; otherwise pin the nearest.
    static func resolve(
        nearest: Flight?,
        from flights: [Flight],
        near coord: CLLocationCoordinate2D
    ) -> Flight? {
        if let current = pinnedFlight(in: flights, near: coord) {
            return current
        }
        clear()
        if let nearest {
            save(nearest, near: coord)
            return nearest
        }
        return nil
    }

    private static func isNear(_ snapshot: Snapshot, _ coord: CLLocationCoordinate2D) -> Bool {
        let here = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let saved = CLLocation(latitude: snapshot.latitude, longitude: snapshot.longitude)
        return here.distance(from: saved) <= stickRadiusMeters
    }

    private static func load() -> Snapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    private static func save(_ flight: Flight, near coord: CLLocationCoordinate2D) {
        let snapshot = Snapshot(
            flight: flight,
            latitude: coord.latitude,
            longitude: coord.longitude,
            savedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
