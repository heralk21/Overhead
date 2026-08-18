import Foundation

/// Route endpoints from OpenSky `/flights/aircraft` (often missing arrival while airborne).
enum OpenSkyRouteService {
    private static let flightsBase = "https://opensky-network.org/api/flights/aircraft"

    static func fetchAirports(icao24: String) async -> (departure: String?, arrival: String?)? {
        let end = Int(Date().timeIntervalSince1970)
        let begin = end - 86_400
        guard var components = URLComponents(string: flightsBase) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "icao24", value: icao24.lowercased()),
            URLQueryItem(name: "begin", value: String(begin)),
            URLQueryItem(name: "end", value: String(end)),
        ]
        guard let url = components.url else { return nil }

        var req = URLRequest(url: url, timeoutInterval: 6)
        req.setValue("flight-tracker-ios", forHTTPHeaderField: "User-Agent")
        if let token = try? await OpenSkyAuth.shared.bearerToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            guard let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  !list.isEmpty else { return nil }
            return mergeAirports(from: list)
        } catch {
            return nil
        }
    }

    /// Prefer a segment with both airports; otherwise merge dep/arr from any segment today.
    private static func mergeAirports(from list: [[String: Any]]) -> (departure: String?, arrival: String?)? {
        for flight in list.reversed() {
            let d = nonEmpty(flight["estDepartureAirport"] as? String)
            let a = nonEmpty(flight["estArrivalAirport"] as? String)
            if d != nil, a != nil { return (d, a) }
        }

        var dep: String?
        var arr: String?
        for flight in list.reversed() {
            if dep == nil { dep = nonEmpty(flight["estDepartureAirport"] as? String) }
            if arr == nil { arr = nonEmpty(flight["estArrivalAirport"] as? String) }
        }
        if dep == nil, arr == nil { return nil }
        return (dep, arr)
    }

    private static func nonEmpty(_ s: String?) -> String? {
        guard let s, !s.isEmpty else { return nil }
        return s
    }
}
