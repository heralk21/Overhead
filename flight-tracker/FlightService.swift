import Combine
import CoreLocation
import Foundation

/// Shared nearby-flight fetch used by the app, widget, and watch.
enum NearbyFlightsFetcher {
    enum Result {
        case flights([Flight])
        case noAircraftNearby
        case unavailable
    }

    private static let hosts = [
        "https://api.airplanes.live/v2/point",
        "https://api.adsb.lol/v2/point"
    ]
    private static let requestTimeout: TimeInterval = 8

    static func fetch(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 50,
        timeout: TimeInterval = requestTimeout
    ) async -> Result {
        let radiusNm = min(250, max(1, Int((radiusKm / 1.852).rounded())))
        return await withTaskGroup(of: (ok: Bool, flights: [Flight])?.self) { group in
            for host in hosts {
                group.addTask {
                    await fetchHost(
                        host,
                        latitude: latitude,
                        longitude: longitude,
                        radiusNm: radiusNm,
                        timeout: timeout
                    )
                }
            }
            var sawOK = false
            for await result in group {
                guard let result else { continue }
                if !result.flights.isEmpty {
                    group.cancelAll()
                    return .flights(result.flights)
                }
                if result.ok { sawOK = true }
            }
            return sawOK ? .noAircraftNearby : .unavailable
        }
    }

    /// Legacy helper for call sites that only need the flight array.
    static func fetchFlights(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 50
    ) async -> [Flight] {
        switch await fetch(latitude: latitude, longitude: longitude, radiusKm: radiusKm) {
        case .flights(let flights): return flights
        case .noAircraftNearby, .unavailable: return []
        }
    }

    private static func fetchHost(
        _ host: String,
        latitude: Double,
        longitude: Double,
        radiusNm: Int,
        timeout: TimeInterval
    ) async -> (ok: Bool, flights: [Flight])? {
        let urlString = "\(host)/\(latitude)/\(longitude)/\(radiusNm)"
        guard let url = URL(string: urlString) else { return nil }

        var req = URLRequest(url: url, timeoutInterval: timeout)
        req.setValue("flight-tracker-ios", forHTTPHeaderField: "User-Agent")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return (true, FlightService.parseFlights(data))
        } catch {
            return nil
        }
    }
}

class FlightService: ObservableObject {
    @Published var flights: [Flight] = []
    @Published var isLoading = false
    @Published var lastUpdate: Date?
    @Published var errorMessage: String?

    private var fetchGeneration = 0

    func fetchFlights(latitude: Double, longitude: Double, radiusKm: Double = 50.0, attempt: Int = 0) {
        if attempt == 0 {
            fetchGeneration += 1
            isLoading = true
            errorMessage = nil
            if flights.isEmpty, let cached = FlightListCache.load(nearLatitude: latitude, nearLongitude: longitude) {
                flights = cached
            }
        }
        let generation = fetchGeneration

        Task { [weak self] in
            guard let self else { return }
            let result = await NearbyFlightsFetcher.fetch(
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm
            )
            await MainActor.run {
                guard generation == self.fetchGeneration else { return }
                switch result {
                case .flights(let parsed):
                    self.isLoading = false
                    self.flights = parsed
                    self.lastUpdate = Date()
                    self.errorMessage = nil
                    FlightListCache.save(parsed, latitude: latitude, longitude: longitude)
                case .noAircraftNearby:
                    self.isLoading = false
                    self.flights = []
                    self.lastUpdate = Date()
                    self.errorMessage = nil
                case .unavailable:
                    if attempt < 1 {
                        Task { [weak self] in
                            try? await Task.sleep(nanoseconds: 700_000_000)
                            await MainActor.run {
                                guard let self, generation == self.fetchGeneration else { return }
                                self.fetchFlights(
                                    latitude: latitude,
                                    longitude: longitude,
                                    radiusKm: radiusKm,
                                    attempt: attempt + 1
                                )
                            }
                        }
                        return
                    }
                    self.isLoading = false
                    if self.flights.isEmpty {
                        self.errorMessage = "Could not load flights. Check your connection and try again."
                    }
                }
            }
        }
    }

    fileprivate static func parseFlights(_ data: Data) -> [Flight] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ac = json["ac"] as? [[String: Any]] else { return [] }

        var result: [Flight] = []
        for a in ac {
            guard let lat = jsonNumber(a["lat"]),
                  let lon = jsonNumber(a["lon"]),
                  let hex = a["hex"] as? String else { continue }

            let gsKnots = jsonNumber(a["gs"]) ?? 0

            let altFeet: Double
            let onGround: Bool
            if let baro = a["alt_baro"] as? String, baro.lowercased() == "ground" {
                altFeet = 0
                onGround = true
            } else if let f = jsonNumber(a["alt_baro"]) {
                altFeet = f
                onGround = f <= 50 && gsKnots < 40
            } else if let f = jsonNumber(a["alt_geom"]) {
                altFeet = f
                onGround = false
            } else {
                altFeet = 0
                onGround = false
            }
            let altMeters = Int(altFeet / 3.28084)

            let verticalRateFpm: Int?
            if let rate = jsonNumber(a["baro_rate"]) ?? jsonNumber(a["geom_rate"]) {
                verticalRateFpm = Int(rate.rounded())
            } else {
                verticalRateFpm = nil
            }

            let velocityMs = gsKnots / 1.943844

            let heading = jsonNumber(a["track"]) ?? jsonNumber(a["true_heading"]) ?? 0

            let selectedAltitudeFt: Int?
            if let mcp = jsonNumber(a["nav_altitude_mcp"]) ?? jsonNumber(a["nav_altitude_fms"]), mcp > 0 {
                selectedAltitudeFt = Int(mcp.rounded())
            } else {
                selectedAltitudeFt = nil
            }

            let callsign = ((a["flight"] as? String) ?? "")
                .trimmingCharacters(in: .whitespaces)
            let registration = ((a["r"] as? String) ?? "")
                .trimmingCharacters(in: .whitespaces)
            let type = ((a["t"] as? String) ?? "")
                .trimmingCharacters(in: .whitespaces)

            let label = callsign.isEmpty ? registration : callsign
            guard !label.isEmpty else { continue }

            result.append(Flight(
                callsign: label,
                latitude: lat,
                longitude: lon,
                altitude: altMeters,
                velocity: velocityMs,
                heading: heading,
                icao24: hex,
                registration: registration,
                type: type,
                verticalRateFpm: verticalRateFpm,
                onGround: onGround,
                selectedAltitudeFt: selectedAltitudeFt
            ))
        }
        return result.sorted { $0.altitude > $1.altitude }
    }

    private static func jsonNumber(_ raw: Any?) -> Double? {
        if let n = raw as? NSNumber { return n.doubleValue }
        if let s = raw as? String { return Double(s) }
        return nil
    }
}

/// Last successful nearby list so the map can paint on launch instead of waiting.
private enum FlightListCache {
    private static let suiteName = "group.HK.flight-tracker"
    private static let key = "overhead.last_flights"
    private static let maxAge: TimeInterval = 45 * 60
    private static let maxDistance: CLLocationDistance = 80_000

    private struct Payload: Codable {
        var latitude: Double
        var longitude: Double
        var savedAt: Date
        var flights: [Flight]
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static func save(_ flights: [Flight], latitude: Double, longitude: Double) {
        let payload = Payload(
            latitude: latitude,
            longitude: longitude,
            savedAt: Date(),
            flights: Array(flights.prefix(80))
        )
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults.set(data, forKey: key)
    }

    static func load(nearLatitude: Double, nearLongitude: Double) -> [Flight]? {
        guard let data = defaults.data(forKey: key),
              let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else { return nil }
        guard Date().timeIntervalSince(payload.savedAt) <= maxAge else { return nil }
        let here = CLLocation(latitude: nearLatitude, longitude: nearLongitude)
        let there = CLLocation(latitude: payload.latitude, longitude: payload.longitude)
        guard here.distance(from: there) <= maxDistance else { return nil }
        return payload.flights.isEmpty ? nil : payload.flights
    }
}
