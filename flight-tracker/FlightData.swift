import Foundation

struct Flight: Identifiable, Codable, Sendable {
    let id: String
    let callsign: String
    let latitude: Double
    let longitude: Double
    let altitude: Int          // meters (kept in meters so all UI math is unchanged)
    let velocity: Double       // meters/second
    let heading: Double        // degrees true
    let icao24: String
    let registration: String   // tail number, e.g. "C-GITS" (empty if unknown)
    let type: String           // ICAO type code, e.g. "B738" (empty if unknown)
    /// Barometric climb/descent rate from ADS-B, feet per minute (negative = descending).
    let verticalRateFpm: Int?
    /// Transponder reports on the surface (`alt_baro: "ground"`).
    let onGround: Bool
    /// Autopilot / FMS selected altitude in feet, when the ADS-B feed includes it.
    let selectedAltitudeFt: Int?

    init(
        callsign: String,
        latitude: Double,
        longitude: Double,
        altitude: Int,
        velocity: Double,
        heading: Double,
        icao24: String,
        registration: String = "",
        type: String = "",
        verticalRateFpm: Int? = nil,
        onGround: Bool = false,
        selectedAltitudeFt: Int? = nil
    ) {
        self.id = icao24
        self.callsign = callsign
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.velocity = velocity
        self.heading = heading
        self.icao24 = icao24
        self.registration = registration
        self.type = type
        self.verticalRateFpm = verticalRateFpm
        self.onGround = onGround
        self.selectedAltitudeFt = selectedAltitudeFt
    }

    var altitudeInFeet: Int { Int(Double(altitude) * 3.28084) }
    var velocityInKnots: Int { Int(velocity * 1.943844) }

    var headingDirection: String {
        switch heading {
        case 0..<45: return "N"
        case 45..<135: return "E"
        case 135..<225: return "S"
        case 225..<315: return "W"
        default: return "N"
        }
    }

    var phase: FlightPhase {
        FlightPhase.classify(
            altitudeFt: altitudeInFeet,
            speedKt: velocityInKnots,
            verticalRateFpm: verticalRateFpm,
            onGround: onGround,
            selectedAltitudeFt: selectedAltitudeFt
        )
    }

    /// Full label for cards: ON LAND, TAKING OFF, LANDING, CRUISE.
    var altitudeStatus: String { phase.displayName }

    /// LED dot colour for board/widget status — matches in-app `boardStatusColor`.
    var statusLEDRGB: (r: Double, g: Double, b: Double) {
        switch phase {
        case .takingOff: return (0.38, 0.82, 0.58)
        case .landing: return (0.92, 0.28, 0.28)
        case .onLand: return (0.55, 0.58, 0.62)
        case .cruise: return (0.94, 0.95, 1.0)
        }
    }
}

/// Four user-facing phases. Derived from ADS-B: on-ground flag, altitude,
/// ground speed, vertical rate, and selected altitude when present.
enum FlightPhase: String, Codable, Sendable {
    case onLand
    case takingOff
    case landing
    case cruise

    var displayName: String {
        switch self {
        case .onLand: return "ON LAND"
        case .takingOff: return "TAKING OFF"
        case .landing: return "LANDING"
        case .cruise: return "CRUISE"
        }
    }

    /// Fits the board STATUS column and watch LED row.
    var compactName: String {
        switch self {
        case .onLand: return "ON LAND"
        case .takingOff: return "TAKEOFF"
        case .landing: return "LANDING"
        case .cruise: return "CRUISE"
        }
    }

    /// Climb-out vs enroute: below this, a real climb is still departure.
    private static let climbOutCeilingFt = 18_000
    /// Terminal-area approach: below this, a real descent is inbound.
    private static let approachCeilingFt = 14_000
    private static let strongApproachCeilingFt = 18_000
    private static let climbFpm = 400
    private static let descentFpm = -400
    private static let strongDescentFpm = -900
    private static let levelFpm = 250

    static func classify(
        altitudeFt: Int,
        speedKt: Int,
        verticalRateFpm: Int?,
        onGround: Bool,
        selectedAltitudeFt: Int?
    ) -> FlightPhase {
        let ft = max(0, altitudeFt)
        let kts = max(0, speedKt)
        let vr = verticalRateFpm
        let selected = selectedAltitudeFt.flatMap { $0 > 0 ? $0 : nil }
        let onSurface = onGround || (ft <= 50 && kts < 40)

        if onSurface {
            return classifySurface(speedKt: kts, verticalRateFpm: vr, selectedAltitudeFt: selected)
        }
        return classifyAirborne(
            altitudeFt: ft,
            speedKt: kts,
            verticalRateFpm: vr,
            selectedAltitudeFt: selected
        )
    }

    /// Taxi / parked = ON LAND. High-speed runway only when climb or MCP makes intent clear.
    private static func classifySurface(
        speedKt kts: Int,
        verticalRateFpm vr: Int?,
        selectedAltitudeFt selected: Int?
    ) -> FlightPhase {
        guard kts >= 70 else { return .onLand }

        if (vr ?? 0) >= 150 { return .takingOff }
        if (vr ?? 0) <= -150 { return .landing }
        if let selected, selected >= 3_000 { return .takingOff }
        if let selected, selected <= 1_500 { return .landing }
        return .onLand
    }

    private static func classifyAirborne(
        altitudeFt ft: Int,
        speedKt kts: Int,
        verticalRateFpm vr: Int?,
        selectedAltitudeFt selected: Int?
    ) -> FlightPhase {
        if let selected {
            let toGo = selected - ft
            if toGo >= 2_500 && (vr ?? 1) >= 0 && ft < 20_000 {
                return .takingOff
            }
            if toGo <= -2_500 && (vr ?? -1) <= 0 && ft < strongApproachCeilingFt {
                return .landing
            }
            if abs(toGo) <= 800 && ft >= 5_000 {
                return .cruise
            }
        }

        if let vr {
            if vr >= climbFpm && ft < climbOutCeilingFt { return .takingOff }
            if vr >= 250 && ft < 10_000 { return .takingOff }
            if vr <= strongDescentFpm && ft < strongApproachCeilingFt { return .landing }
            if vr <= descentFpm && ft < approachCeilingFt { return .landing }
            if vr <= -250 && ft < 8_000 { return .landing }
            if vr > descentFpm && vr < climbFpm && ft >= 10_000 { return .cruise }
            if abs(vr) < levelFpm && ft >= 6_000 { return .cruise }
        } else if ft >= 10_000 {
            return .cruise
        }

        if ft >= 10_000 { return .cruise }
        if ft >= 8_000 && kts >= 200 { return .cruise }

        // Low, no usable vertical rate — speed separates departure from approach.
        if ft < 3_000 {
            return kts >= 185 ? .takingOff : .landing
        }
        if ft < 6_000 {
            if kts >= 220 { return .takingOff }
            if kts <= 175 { return .landing }
            return .cruise
        }

        return .cruise
    }
}
