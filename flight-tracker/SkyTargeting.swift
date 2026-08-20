import CoreGraphics
import CoreLocation
import Foundation

/// Maps a nearby ADS-B target onto the sky (azimuth / elevation from the user).
enum SkyGeometry {
    /// Compass bearing in degrees true, 0 = north, clockwise.
    static func azimuth(from origin: CLLocationCoordinate2D, to target: CLLocationCoordinate2D) -> Double {
        let lat1 = origin.latitude * .pi / 180
        let lat2 = target.latitude * .pi / 180
        let dLon = (target.longitude - origin.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return wrap360(atan2(y, x) * 180 / .pi)
    }

    /// Elevation above the horizon in degrees (90 = overhead).
    static func elevation(distanceMeters: Double, altitudeMeters: Double) -> Double {
        guard distanceMeters > 8 else { return 90 }
        return atan2(max(0, altitudeMeters), distanceMeters) * 180 / .pi
    }

    static func wrap360(_ deg: Double) -> Double {
        let m = deg.truncatingRemainder(dividingBy: 360)
        return m >= 0 ? m : m + 360
    }

    /// Signed smallest angle, −180…180.
    static func delta(_ a: Double, _ b: Double) -> Double {
        var d = (a - b).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }

    /// Angular distance in degrees between look direction and a sky point.
    static func angularError(lookAz: Double, lookEl: Double, targetAz: Double, targetEl: Double) -> Double {
        let dAz = delta(targetAz, lookAz)
        let dEl = targetEl - lookEl
        let azWeight = max(0.12, cos(lookEl * .pi / 180))
        return hypot(dAz * azWeight, dEl)
    }

    /// Project a sky offset onto the camera plane. Nil if well outside the frame.
    static func project(
        lookAz: Double,
        lookEl: Double,
        targetAz: Double,
        targetEl: Double,
        in size: CGSize,
        fovHorizontal: Double
    ) -> CGPoint? {
        guard size.width > 0, size.height > 0, fovHorizontal > 1 else { return nil }
        let fovV = fovHorizontal * Double(size.height / size.width)
        let dAz = delta(targetAz, lookAz)
        let dEl = targetEl - lookEl
        if abs(dAz) > fovHorizontal * 0.85 || abs(dEl) > fovV * 0.85 { return nil }
        let x = size.width / 2 + CGFloat(dAz / fovHorizontal) * size.width
        let y = size.height / 2 - CGFloat(dEl / fovV) * size.height
        return CGPoint(x: x, y: y)
    }
}

struct SkyTarget {
    let flight: Flight
    let azimuth: Double
    let elevation: Double
    let distance: CLLocationDistance
    let angularError: Double
    let screenPoint: CGPoint?
}

enum SkyTargeting {
    static let scanRadiusMeters: CLLocationDistance = 1_000

    static func targets(
        flights: [Flight],
        from origin: CLLocationCoordinate2D,
        lookAzimuth: Double,
        lookElevation: Double,
        viewSize: CGSize,
        fovHorizontal: Double,
        maxDistance: CLLocationDistance = scanRadiusMeters
    ) -> [SkyTarget] {
        let here = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        return flights.compactMap { flight in
            let there = CLLocation(latitude: flight.latitude, longitude: flight.longitude)
            let dist = here.distance(from: there)
            guard dist <= maxDistance else { return nil }
            let az = SkyGeometry.azimuth(from: origin, to: flight.coordinate)
            let el = SkyGeometry.elevation(distanceMeters: dist, altitudeMeters: Double(flight.altitude))
            let err = SkyGeometry.angularError(
                lookAz: lookAzimuth, lookEl: lookElevation, targetAz: az, targetEl: el
            )
            let pt = SkyGeometry.project(
                lookAz: lookAzimuth, lookEl: lookElevation,
                targetAz: az, targetEl: el,
                in: viewSize, fovHorizontal: fovHorizontal
            )
            return SkyTarget(
                flight: flight, azimuth: az, elevation: el,
                distance: dist, angularError: err, screenPoint: pt
            )
        }
        .sorted { $0.angularError < $1.angularError }
    }

    /// Only the nearby aircraft sitting inside the viewfinder, not whatever is off in the sky.
    static func lockCandidate(in targets: [SkyTarget], viewfinder: CGRect) -> SkyTarget? {
        let hot = viewfinder.insetBy(dx: 18, dy: 18)
        return targets.first { target in
            guard let pt = target.screenPoint else { return false }
            return hot.contains(pt)
        }
    }
}

extension Flight {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
