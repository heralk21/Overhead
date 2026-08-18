import Foundation

/// Scheduled route from AeroDataBox (fills missing OpenSky arrival, e.g. YYJ → YVR).
enum AeroDataBoxRouteService {
    private static let host = "https://aerodatabox.p.rapidapi.com"

    static func fetch(icao24: String, callsign: String, knownDepartureICAO: String? = nil) async -> (departure: String?, arrival: String?)? {
        guard !APIConfiguration.aeroDataBoxKey.isEmpty else { return nil }

        var dep: String?
        var arr: String?

        let cs = callsign.trimmingCharacters(in: .whitespaces).uppercased()
        let hex = icao24.lowercased()
        let dates = localDatesForLookup()

        for date in dates {
            if !cs.isEmpty {
                for search in ["callsign", "number"] {
                    if let route = await request(searchBy: search, param: cs, date: date) {
                        dep = dep ?? route.departure
                        arr = arr ?? route.arrival
                        if dep != nil, arr != nil { return (dep, arr) }
                    }
                }
            }
            if let route = await request(searchBy: "icao24", param: hex, date: date) {
                dep = dep ?? route.departure
                arr = arr ?? route.arrival
                if dep != nil, arr != nil { return (dep, arr) }
            }
        }

        if arr == nil, let depICAO = knownDepartureICAO ?? dep, !cs.isEmpty || !hex.isEmpty {
            if let route = await fetchFromAirportBoard(
                departureAirport: depICAO, callsign: cs, icao24: hex
            ) {
                dep = dep ?? route.departure
                arr = arr ?? route.arrival
            }
        }

        guard dep != nil || arr != nil else { return nil }
        return (departure: dep, arrival: arr)
    }

    /// Match callsign on the departure board at the origin airport (best for airborne flights).
    private static func fetchFromAirportBoard(
        departureAirport: String,
        callsign: String,
        icao24: String
    ) async -> (departure: String?, arrival: String?)? {
        let code = departureAirport.uppercased()
        let codeType = code.count == 4 ? "icao" : "iata"
        guard var components = URLComponents(string: "\(host)/flights/airports/\(codeType)/\(code)") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "offsetMinutes", value: "-180"),
            URLQueryItem(name: "durationMinutes", value: "480"),
        ]
        guard let url = components.url else { return nil }

        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue(APIConfiguration.aeroDataBoxKey, forHTTPHeaderField: "X-RapidAPI-Key")
        req.setValue("aerodatabox.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  !data.isEmpty else { return nil }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

            let target = normalizeCallsign(callsign)
            let hex = icao24.lowercased()
            if let departures = json["departures"] as? [[String: Any]] {
                for flight in departures where flightMatches(flight, callsign: target, icao24: hex) {
                    // Departures board: movement.airport is the destination.
                    let movement = flight["movement"] as? [String: Any]
                    let dest = airportCode(from: movement?["airport"] as? [String: Any])
                    if dest != nil { return (departure: code, arrival: dest) }
                }
            }
            if let arrivals = json["arrivals"] as? [[String: Any]] {
                for flight in arrivals where flightMatches(flight, callsign: target, icao24: hex) {
                    let movement = flight["movement"] as? [String: Any]
                    let origin = airportCode(from: movement?["airport"] as? [String: Any])
                    if origin != nil { return (departure: origin, arrival: code) }
                }
            }
        } catch {}
        return nil
    }

    private static func request(searchBy: String, param: String, date: String) async -> (departure: String?, arrival: String?)? {
        let encoded = param.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? param
        guard let url = URL(string: "\(host)/flights/\(searchBy)/\(encoded)/\(date)") else { return nil }

        var req = URLRequest(url: url, timeoutInterval: 6)
        req.setValue(APIConfiguration.aeroDataBoxKey, forHTTPHeaderField: "X-RapidAPI-Key")
        req.setValue("aerodatabox.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode), !data.isEmpty else { return nil }
            return parseFlights(data)
        } catch {
            return nil
        }
    }

    private static func parseFlights(_ data: Data) -> (departure: String?, arrival: String?)? {
        if let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for flight in pickFlights(list) {
                let dep = airportCode(from: flight["departure"] as? [String: Any])
                let arr = airportCode(from: flight["arrival"] as? [String: Any])
                if dep != nil || arr != nil { return (dep, arr) }
            }
        }
        if let flight = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let dep = airportCode(from: flight["departure"] as? [String: Any])
            let arr = airportCode(from: flight["arrival"] as? [String: Any])
            if dep != nil || arr != nil { return (dep, arr) }
        }
        return nil
    }

    private static func pickFlights(_ list: [[String: Any]]) -> [[String: Any]] {
        let active = list.filter { flight in
            let status = (flight["status"] as? String ?? "").lowercased()
            return status.contains("air") || status.contains("enroute") || status.contains("depart")
        }
        return active.isEmpty ? list : active
    }

    private static func flightMatches(_ flight: [String: Any], callsign target: String, icao24 hex: String) -> Bool {
        if !hex.isEmpty,
           let ac = flight["aircraft"] as? [String: Any],
           let modeS = (ac["modeS"] as? String)?.lowercased(),
           modeS == hex { return true }
        guard !target.isEmpty else { return false }

        let keys = ["callSign", "callsign", "number", "flightNumber", "iataFlightNumber"]
        for key in keys {
            guard let raw = flight[key] as? String else { continue }
            let candidate = normalizeCallsign(raw)
            if candidate == target { return true }
            if candidate.count >= 4, target.count >= 4,
               candidate.suffix(4) == target.suffix(4),
               candidate.prefix(3) == target.prefix(3) { return true }
        }
        // Jazz often flies as JZA158 on ADS-B but AC 8158 on the departure board.
        let digits = target.filter(\.isNumber)
        if digits.count >= 2 {
            let number = normalizeCallsign(flight["number"] as? String ?? "")
            if number.contains(digits) { return true }
            let callSign = normalizeCallsign(flight["callSign"] as? String ?? "")
            if callSign.contains(digits) { return true }
        }
        return false
    }

    private static func normalizeCallsign(_ s: String) -> String {
        s.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    private static func airportCode(from leg: [String: Any]?) -> String? {
        guard let leg else { return nil }
        // FIDS movement.airport or flight leg wrapper
        if let airport = leg["airport"] as? [String: Any] {
            return airportCode(from: airport)
        }
        if let iata = leg["iata"] as? String, !iata.isEmpty { return iata }
        if let icao = leg["icao"] as? String, !icao.isEmpty { return icao }
        return nil
    }

    private static func localDatesForLookup() -> [String] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        return [fmt.string(from: today), fmt.string(from: yesterday)]
    }
}
