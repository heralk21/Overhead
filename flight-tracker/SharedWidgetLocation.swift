import CoreLocation
import Foundation

/// Last-known user position shared between the app and home-screen widget (App Group).
enum SharedWidgetLocation {
    private static let suiteName = "group.HK.flight-tracker"
    private static let latKey = "shared_last_lat"
    private static let lonKey = "shared_last_lon"
    private static let timeKey = "shared_last_loc_time"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static func save(_ location: CLLocation, reloadWidget: Bool = true) {
        let defaults = defaults
        let previous = coordinate(maxAge: .infinity)
        defaults.set(location.coordinate.latitude, forKey: latKey)
        defaults.set(location.coordinate.longitude, forKey: lonKey)
        defaults.set(location.timestamp.timeIntervalSince1970, forKey: timeKey)

        if reloadWidget, let previous {
            let moved = CLLocation(latitude: previous.latitude, longitude: previous.longitude)
                .distance(from: location)
            if moved > 2000 {
                WidgetBoardStore.reloadTimelines()
            }
        } else if reloadWidget {
            WidgetBoardStore.reloadTimelines()
        }
    }

    static func coordinate(maxAge: TimeInterval = 3600) -> CLLocationCoordinate2D? {
        let defaults = defaults
        guard let savedAt = defaults.object(forKey: timeKey) as? TimeInterval else { return nil }
        if maxAge.isFinite, Date().timeIntervalSince1970 - savedAt > maxAge { return nil }

        let lat = defaults.double(forKey: latKey)
        let lon = defaults.double(forKey: lonKey)
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        guard CLLocationCoordinate2DIsValid(coord) else { return nil }
        guard abs(lat) > 0.0001 || abs(lon) > 0.0001 else { return nil }
        return coord
    }

    static func clear() {
        let defaults = defaults
        defaults.removeObject(forKey: latKey)
        defaults.removeObject(forKey: lonKey)
        defaults.removeObject(forKey: timeKey)
    }
}
