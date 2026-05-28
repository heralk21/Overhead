import Foundation

struct Flight: Identifiable, Codable {
    let id: String
    let callsign: String
    let latitude: Double
    let longitude: Double
    let altitude: Int
    let velocity: Double
    let heading: Double
    let icao24: String

    init(callsign: String, latitude: Double, longitude: Double, altitude: Int, velocity: Double, heading: Double, icao24: String) {
        self.id = icao24
        self.callsign = callsign
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.velocity = velocity
        self.heading = heading
        self.icao24 = icao24
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

    var altitudeStatus: String {
        if altitude < 1000 { return "Takeoff" }
        if altitude < 5000 { return "Climb" }
        if altitude < 10000 { return "Ascending" }
        if altitude < 30000 { return "Cruise" }
        return "High Alt"
    }
}
