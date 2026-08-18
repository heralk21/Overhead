import Foundation

/// Combines OpenSky history + AeroDataBox schedule / airport board for best dep/arr coverage.
enum RouteLookupService {
    static func fetch(icao24: String, callsign: String) async -> (departure: String?, arrival: String?)? {
        var dep: String?
        var arr: String?

        if let os = await OpenSkyRouteService.fetchAirports(icao24: icao24) {
            dep = os.departure
            arr = os.arrival
        }

        if dep == nil || arr == nil {
            if let adb = await AeroDataBoxRouteService.fetch(
                icao24: icao24,
                callsign: callsign,
                knownDepartureICAO: dep
            ) {
                if dep == nil { dep = adb.departure }
                if arr == nil { arr = adb.arrival }
            }
        }

        guard dep != nil || arr != nil else { return nil }
        return (departure: dep, arrival: arr)
    }
}
