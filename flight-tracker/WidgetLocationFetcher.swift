import CoreLocation
import Foundation

/// Resolves a coordinate for the widget extension — shared cache first, then a brief GPS read.
/// Last-known App Group location is kept indefinitely so the widget still works after the app is closed.
enum WidgetLocationFetcher {
    private static let freshAge: TimeInterval = 15 * 60

    static func coordinate() async -> CLLocationCoordinate2D? {
        if let shared = SharedWidgetLocation.coordinate(maxAge: freshAge) {
            return shared
        }
        if let gps = await cachedSystemLocation(maxAge: freshAge) {
            persist(gps)
            return gps
        }
        if let live = await liveCoordinate(timeout: 4) {
            persist(live)
            return live
        }
        if let shared = SharedWidgetLocation.coordinate(maxAge: .infinity) {
            return shared
        }
        return await cachedSystemLocation(maxAge: .infinity)
    }

    private static func persist(_ coord: CLLocationCoordinate2D) {
        SharedWidgetLocation.save(
            CLLocation(latitude: coord.latitude, longitude: coord.longitude),
            reloadWidget: false
        )
    }

    @MainActor
    private static func systemLocation(maxAge: TimeInterval) -> CLLocationCoordinate2D? {
        let manager = CLLocationManager()
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            break
        default:
            return nil
        }
        guard let loc = manager.location else { return nil }
        if maxAge.isFinite, abs(loc.timestamp.timeIntervalSinceNow) >= maxAge {
            return nil
        }
        return loc.coordinate
    }

    private static func cachedSystemLocation(maxAge: TimeInterval) async -> CLLocationCoordinate2D? {
        await MainActor.run { systemLocation(maxAge: maxAge) }
    }

    private static func liveCoordinate(timeout: TimeInterval) async -> CLLocationCoordinate2D? {
        let status = await MainActor.run { CLLocationManager().authorizationStatus }
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            break
        default:
            return nil
        }

        return await withTaskGroup(of: CLLocationCoordinate2D?.self) { group in
            group.addTask {
                do {
                    let updates = CLLocationUpdate.liveUpdates()
                    for try await update in updates {
                        if update.authorizationDenied { return nil }
                        if let loc = update.location { return loc.coordinate }
                    }
                } catch {
                    return nil
                }
                return nil
            }
            group.addTask {
                let nanos = UInt64(max(0, timeout) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                return nil
            }
            for await value in group {
                group.cancelAll()
                if let value { return value }
            }
            return nil
        }
    }
}
