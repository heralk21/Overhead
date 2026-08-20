import CoreLocation
import MapKit

/// Camera math for the map — user location first, nearby traffic fitted without pulling to the world.
enum MapFraming {
    static let defaultUserSpan = 0.35
    static let minFitSpan = 0.12
    static let maxFitSpan = 0.5
    static let nearbyCutoffMeters: CLLocationDistance = 300_000

    static func region(center: CLLocationCoordinate2D, spanDegrees: Double) -> MKCoordinateRegion {
        let span = max(0.02, spanDegrees)
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
    }

    static func focused(on flight: CLLocationCoordinate2D, spanDegrees: Double, southShiftRatio: Double) -> MKCoordinateRegion {
        let span = max(0.02, spanDegrees)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: flight.latitude - span * southShiftRatio,
                longitude: flight.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
    }

    /// Bounding box of the user plus the closest flights, clamped so the camera stays local.
    static func fitting(
        user: CLLocationCoordinate2D,
        flights: [Flight],
        count: Int = 5
    ) -> MKCoordinateRegion? {
        let here = CLLocation(latitude: user.latitude, longitude: user.longitude)
        let closest = Array(flights.sorted {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: here)
                < CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: here)
        }.prefix(count))
        guard !closest.isEmpty else { return nil }

        let nearest = closest.compactMap {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: here)
        }.min() ?? .infinity
        guard nearest < nearbyCutoffMeters else {
            return region(center: user, spanDegrees: defaultUserSpan)
        }

        let lats = closest.map(\.latitude) + [user.latitude]
        let lons = closest.map(\.longitude) + [user.longitude]
        let latSpan = max((lats.max()! - lats.min()!) * 1.6, minFitSpan)
        let lonSpan = max((lons.max()! - lons.min()!) * 1.6, minFitSpan)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (lats.min()! + lats.max()!) / 2,
                longitude: (lons.min()! + lons.max()!) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: min(latSpan, maxFitSpan),
                longitudeDelta: min(lonSpan, maxFitSpan)
            )
        )
    }
}

#if DEBUG
extension MapFraming {
    /// Sanity checks for camera math. Traps in debug if framing drifts.
    static func selfCheck() {
        let user = CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
        let local = region(center: user, spanDegrees: defaultUserSpan)
        assert(abs(local.center.latitude - user.latitude) < 0.00001)
        assert(abs(local.span.latitudeDelta - defaultUserSpan) < 0.00001)

        let pin = focused(on: user, spanDegrees: 0.05, southShiftRatio: 0.3)
        assert(pin.center.latitude < user.latitude)

        let nearby = Flight(
            callsign: "TEST1",
            latitude: user.latitude + 0.04,
            longitude: user.longitude,
            altitude: 10_000,
            velocity: 200,
            heading: 90,
            icao24: "test1"
        )
        let fitted = fitting(user: user, flights: [nearby])
        assert(fitted != nil)
        assert(fitted!.span.latitudeDelta <= maxFitSpan + 0.0001)
        assert(fitted!.span.latitudeDelta >= minFitSpan - 0.0001)

        let far = Flight(
            callsign: "FAR1",
            latitude: user.latitude + 5,
            longitude: user.longitude,
            altitude: 10_000,
            velocity: 200,
            heading: 90,
            icao24: "far1"
        )
        let fallback = fitting(user: user, flights: [far])
        assert(fallback != nil)
        assert(abs(fallback!.center.latitude - user.latitude) < 0.00001)
    }
}
#endif
