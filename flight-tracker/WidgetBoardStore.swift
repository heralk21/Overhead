import CoreLocation
import Foundation
import WidgetKit

/// Last successful Home Screen board, shared between the app and widget (App Group).
/// Snapshot is what the widget shows immediately — timeline fetch then replaces it.
enum WidgetBoardStore {
    static let kind = "FlightTrackerWidget"
    /// Fresh enough to show on first paint / gallery snapshot.
    static let maxSnapshotAge: TimeInterval = 45 * 60
    /// If a live fetch fails, keep showing this rather than "SCANNING AIRSPACE".
    static let maxFallbackAge: TimeInterval = 2 * 60 * 60

    struct Snapshot: Codable {
        var flight: Flight?
        var route: RouteData?
        var latitude: Double?
        var longitude: Double?
        var savedAt: Date
    }

    private static let suiteName = "group.HK.flight-tracker"
    private static let key = "widget_board_snapshot"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static func load() -> Snapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    static func load(maxAge: TimeInterval) -> Snapshot? {
        guard let snap = load() else { return nil }
        guard Date().timeIntervalSince(snap.savedAt) <= maxAge else { return nil }
        return snap
    }

    static func save(flight: Flight?, route: RouteData?, near coord: CLLocationCoordinate2D?) {
        let snap = Snapshot(
            flight: flight,
            route: route,
            latitude: coord?.latitude,
            longitude: coord?.longitude,
            savedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(snap) else { return }
        defaults.set(data, forKey: key)
    }

    /// Writes the nearest commercial flight from an in-app fetch so the widget
    /// has something to show without waiting on its own timeline.
    static func publish(
        flights: [Flight],
        routes: [String: RouteData],
        near coord: CLLocationCoordinate2D,
        reload: Bool = false
    ) {
        let nearest = CommercialFlightFilter.nearest(to: coord, from: flights)
        let flight = WidgetFlightCache.resolve(nearest: nearest, from: flights, near: coord)
        let route = flight.flatMap { routes[$0.icao24] }.flatMap { knownRouteEnds($0) == nil ? nil : $0 }
        save(flight: flight, route: route, near: coord)
        if reload { reloadTimelines() }
    }

    static func reloadTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}

enum AsyncTimeout {
    private enum Timed<T: Sendable>: Sendable {
        case success(T)
        case timeout
    }

    /// Returns `nil` if `seconds` elapses first. A successful `nil` from `operation`
    /// (when `T` is Optional) is still a success — not a timeout.
    static func value<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async -> T
    ) async -> T? {
        await withTaskGroup(of: Timed<T>.self) { group in
            group.addTask { .success(await operation()) }
            group.addTask {
                let nanos = UInt64(max(0, seconds) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                return .timeout
            }
            let first = await group.next()
            group.cancelAll()
            if case .success(let value) = first { return value }
            return nil
        }
    }
}
