import Foundation
import CoreLocation
import UIKit

// MARK: - Airlines & airports (shared: app, widget, watch)

let AIRLINE_NAMES: [String: String] = [
    "ACA": "AIR CANADA", "JZA": "AC EXPRES", "ROU": "AIR CANADA ROUGE", "WJA": "WESTJET",
    "WEN": "WESTJET EXP", "UAL": "UNITED", "DAL": "DELTA", "AAL": "AMERICAN",
    "SWA": "SOUTHWEST", "ASA": "ALASKA AIR", "SKW": "SKYWEST", "JBU": "JETBLUE",
    "BAW": "BRIT AIRWAYS", "DLH": "LUFTHANSA", "AFR": "AIR FRANCE", "KLM": "KLM",
    "UAE": "EMIRATES", "QFA": "QANTAS", "CPA": "CATHAY PAC", "TSC": "AIR TRANSAT",
    "RYR": "RYANAIR", "EZY": "EASYJET", "THY": "TURKISH AIR", "FIN": "FINNAIR",
    "SAS": "SCANDINAVIAN", "IBE": "IBERIA", "TAP": "TAP PORTUGAL", "AZU": "AZUL",
    "LAM": "LATAM", "VOE": "VOLARIS", "PAL": "PHIL AIR", "FDX": "FEDEX", "UPS": "UPS AIR",
    "HAL": "HAWAIIAN", "FFT": "FRONTIER", "NKS": "SPIRIT", "QTR": "QATAR AIR",
    "ETD": "ETIHAD", "ANA": "ANA", "JAL": "JAPAN AIR", "SIA": "SINGAPORE",
    "KAL": "KOREAN AIR", "EVA": "EVA AIR", "VIR": "VIRGIN ATL", "SWR": "SWISS",
    "AUA": "AUSTRIAN", "VOZ": "VIRGIN AUS",
    // Carriers with bundled logos (kept in sync with AirlineLogoAsset).
    "AAY": "ALLEGIANT", "SCX": "SUN COUNTRY", "MXY": "BREEZE", "VXP": "AVELO",
    "POE": "PORTER", "FLE": "FLAIR", "MPE": "CANADIAN NTH", "SWG": "SUNWING",
    "ITY": "ITA AIRWAYS", "AIC": "AIR INDIA", "IGO": "INDIGO", "SVA": "SAUDIA",
    "THA": "THAI AIR", "CES": "CHINA EAST",
]

private let airlineICAOSet = Set(AIRLINE_NAMES.keys)

let AIRPORTS: [String: (code: String, city: String)] = [
    "CYVR": ("YVR", "VANCOUVER"), "CYYJ": ("YYJ", "VICTORIA"), "CYYZ": ("YYZ", "TORONTO"),
    "CYUL": ("YUL", "MONTREAL"), "CYYC": ("YYC", "CALGARY"), "CYEG": ("YEG", "EDMONTON"),
    "CYOW": ("YOW", "OTTAWA"), "CYXX": ("YXX", "ABBOTSFORD"), "CYLW": ("YLW", "KELOWNA"),
    "KLAX": ("LAX", "LOS ANGELES"), "KJFK": ("JFK", "NEW YORK"), "KORD": ("ORD", "CHICAGO"),
    "KATL": ("ATL", "ATLANTA"), "KSFO": ("SFO", "SAN FRANCISCO"), "KDFW": ("DFW", "DALLAS"),
    "KDEN": ("DEN", "DENVER"), "KSEA": ("SEA", "SEATTLE"), "KMIA": ("MIA", "MIAMI"),
    "EGLL": ("LHR", "LONDON"), "LFPG": ("CDG", "PARIS"), "EHAM": ("AMS", "AMSTERDAM"),
    "EDDF": ("FRA", "FRANKFURT"), "OMDB": ("DXB", "DUBAI"), "OTHH": ("DOH", "DOHA"),
    "VHHH": ("HKG", "HONG KONG"), "RJTT": ("HND", "TOKYO"), "WSSS": ("SIN", "SINGAPORE"),
    "YSSY": ("SYD", "SYDNEY"), "YMML": ("MEL", "MELBOURNE"),
]

func displayAP(_ icao: String?) -> (code: String, city: String) {
    guard let s = icao, !s.isEmpty else { return ("", "") }
    if let d = AIRPORTS[s] { return d }
    let up = s.uppercased()
    if let match = AIRPORTS.values.first(where: { $0.code == up }) { return match }
    if s.count == 4 && (s.hasPrefix("K") || s.hasPrefix("C")) { return (String(s.dropFirst()), "") }
    return (up.count >= 3 ? String(up.suffix(3)) : up, "")
}

func isKnownAirportCode(_ code: String) -> Bool {
    let c = code.trimmingCharacters(in: .whitespaces).uppercased()
    guard !c.isEmpty else { return false }
    return c != "???" && c != "—" && c != "-"
}

func knownRouteEnds(_ route: RouteData?) -> (dep: String, arr: String)? {
    guard let r = route, isKnownAirportCode(r.dep), isKnownAirportCode(r.arr) else { return nil }
    return (r.dep, r.arr)
}

func airlineName(_ cs: String) -> String {
    let prefix = String(cs.prefix(3)).uppercased()
    if let name = AIRLINE_NAMES[prefix] { return name }
    let c2 = String(cs.prefix(2)).uppercased()
    if c2 == "CF" || c2 == "CG" || c2 == "CI" { return "PRIVATE FLT" }
    return "CHARTER FLT"
}

// MARK: - Airline logo assets (bundled brand logos, shared: app + widget)

/// Maps a flight callsign to a bundled airline logo image in
/// `Assets.xcassets/AirlineLogos`. Keyed by the 3-letter ICAO callsign prefix
/// so it works identically in the app and the widget. Returns `nil` when no
/// bundled logo exists, letting callers fall back to their default rendering.
enum AirlineLogoAsset {
    private static let byICAO: [String: String] = [
        "ACA": "air_canada", "JZA": "air_canada", "ROU": "air_canada_rouge",
        "WJA": "westjet", "WEN": "westjet",
        "UAL": "united_airlines", "DAL": "delta_air_lines", "AAL": "american_airlines",
        "SWA": "southwest_airlines", "ASA": "alaska_airlines", "JBU": "jetblue",
        "HAL": "hawaiian_airlines", "FFT": "frontier_airlines", "NKS": "spirit_airlines",
        "AAY": "allegiant_air", "SCX": "sun_country_airlines", "MXY": "breeze_airways",
        "VXP": "avelo_airlines", "POE": "porter_airlines", "TSC": "air_transat",
        "FLE": "flair_airlines", "MPE": "canadian_north", "SWG": "sunwing_airlines",
        "BAW": "british_airways", "DLH": "lufthansa", "AFR": "air_france", "KLM": "klm",
        "UAE": "emirates", "QTR": "qatar_airways", "THY": "turkish_airlines",
        "SIA": "singapore_airlines", "CPA": "cathay_pacific", "ITY": "ita_airways",
        "JAL": "japan_airlines", "QFA": "qantas", "AIC": "air_india",
        "RYR": "ryanair", "EZY": "easyjet", "IGO": "indigo", "VIR": "virgin_atlantic",
        "SVA": "saudia", "THA": "thai_airways", "KAL": "korean_air",
        "CES": "china_eastern_airlines",
    ]

    static func assetName(forCallsign callsign: String) -> String? {
        guard callsign.count >= 3 else { return nil }
        return byICAO[String(callsign.prefix(3)).uppercased()]
    }

    private static var preparedCache: [String: UIImage] = [:]

    /// Bundled logo trimmed, centered, and with opaque black matte keyed out to transparency.
    static func preparedImage(named asset: String) -> UIImage? {
        if let cached = preparedCache[asset] { return cached }
        guard let raw = UIImage(named: asset) else { return nil }
        let prepared = raw.preparedAirlineLogo()
        preparedCache[asset] = prepared
        return prepared
    }

    static func preparedImage(forCallsign callsign: String) -> UIImage? {
        guard let asset = assetName(forCallsign: callsign) else { return nil }
        return preparedImage(named: asset)
    }
}

// MARK: - Airline logo image prep (shared: app + widget)

extension UIImage {
    /// Crops black/transparent padding and keys near-black matte pixels to alpha so logos
    /// composite cleanly on dark UI surfaces and the LED widget board.
    func preparedAirlineLogo(padding: CGFloat = 2) -> UIImage {
        guard let cg = cgImage, cg.width > 0, cg.height > 0 else { return self }
        let w = cg.width, h = cg.height
        let stride = w * 4
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(
            data: &pixels, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: stride,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return self }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        var minX = w, minY = h, maxX = -1, maxY = -1
        for y in 0..<h {
            let row = y * stride
            for x in 0..<w {
                let o = row + x * 4
                if Self.isAirlineLogoBackground(
                    r: pixels[o], g: pixels[o + 1], b: pixels[o + 2], a: pixels[o + 3]
                ) { continue }
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return self }

        let pad = Int(padding.rounded())
        let cropX = max(0, minX - pad)
        let cropY = max(0, minY - pad)
        let cropW = min(w - cropX, maxX - minX + 1 + pad * 2)
        let cropH = min(h - cropY, maxY - minY + 1 + pad * 2)
        let outW = cropW, outH = cropH
        var out = [UInt8](repeating: 0, count: outW * outH * 4)

        for y in 0..<outH {
            for x in 0..<outW {
                let sx = cropX + x, sy = cropY + y
                let si = (sy * w + sx) * 4
                let di = (y * outW + x) * 4
                let r = pixels[si], g = pixels[si + 1], b = pixels[si + 2], a = pixels[si + 3]
                if Self.isAirlineLogoBackground(r: r, g: g, b: b, a: a) {
                    out[di + 3] = 0
                    continue
                }
                let af = CGFloat(a) / 255
                out[di]     = UInt8(min(255, Int(CGFloat(r) / max(af, 0.001))))
                out[di + 1] = UInt8(min(255, Int(CGFloat(g) / max(af, 0.001))))
                out[di + 2] = UInt8(min(255, Int(CGFloat(b) / max(af, 0.001))))
                out[di + 3] = a
            }
        }

        guard let outCtx = CGContext(
            data: &out, width: outW, height: outH,
            bitsPerComponent: 8, bytesPerRow: outW * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let outCG = outCtx.makeImage() else { return self }
        return UIImage(cgImage: outCG, scale: scale, orientation: imageOrientation)
    }

    private static func isAirlineLogoBackground(r: UInt8, g: UInt8, b: UInt8, a: UInt8) -> Bool {
        if a < 12 { return true }
        let peak = max(r, max(g, b))
        if peak < 28 { return true }
        let minC = min(r, min(g, b))
        if peak < 52 && (peak - minC) < 12 { return true }
        return false
    }
}

extension CGRect {
    /// Aspect-fit `imageSize` centered inside `rect` (points).
    static func aspectFit(imageSize: CGSize, in rect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return rect }
        let s = min(rect.width / imageSize.width, rect.height / imageSize.height)
        let fit = CGSize(width: imageSize.width * s, height: imageSize.height * s)
        return CGRect(
            x: rect.midX - fit.width / 2,
            y: rect.midY - fit.height / 2,
            width: fit.width,
            height: fit.height
        )
    }
}

// MARK: - Commercial-only filter

enum CommercialFlightFilter {
    /// Scheduled airline traffic only — hides private/charter/unknown callsigns.
    static func isCommercial(_ flight: Flight) -> Bool {
        let cs = flight.callsign.trimmingCharacters(in: .whitespaces).uppercased()
        guard cs.count >= 3 else { return false }

        let c2 = String(cs.prefix(2))
        if c2 == "CF" || c2 == "CG" || c2 == "CI" { return false }

        let prefix = String(cs.prefix(3))
        guard airlineICAOSet.contains(prefix) else { return false }

        let tail = cs.dropFirst(3)
        guard !tail.isEmpty else { return false }
        return tail.contains(where: \.isNumber)
    }

    static func commercialFlights(from flights: [Flight]) -> [Flight] {
        flights.filter(isCommercial)
    }

    static func nearest(to coord: CLLocationCoordinate2D, from flights: [Flight]) -> Flight? {
        let here = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return commercialFlights(from: flights).min { a, b in
            let da = CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: here)
            let db = CLLocation(latitude: b.latitude, longitude: b.longitude).distance(from: here)
            return da < db
        }
    }
}

// MARK: - Aircraft types

struct AircraftSpec { let name, wing, range, speed, cat: String }

let AIRCRAFT_DB: [String: AircraftSpec] = [
    "A319": .init(name: "AIRBUS A319", wing: "34.1 M", range: "6,850 KM", speed: "833 KM/H", cat: "NARROW-BODY"),
    "A320": .init(name: "AIRBUS A320", wing: "35.8 M", range: "6,150 KM", speed: "833 KM/H", cat: "NARROW-BODY"),
    "A321": .init(name: "AIRBUS A321", wing: "35.8 M", range: "7,400 KM", speed: "833 KM/H", cat: "NARROW-BODY"),
    "A20N": .init(name: "AIRBUS A320NEO", wing: "35.8 M", range: "6,300 KM", speed: "833 KM/H", cat: "NARROW-BODY"),
    "A21N": .init(name: "AIRBUS A321NEO", wing: "35.8 M", range: "7,400 KM", speed: "833 KM/H", cat: "NARROW-BODY"),
    "A332": .init(name: "AIRBUS A330-200", wing: "60.3 M", range: "13,450 KM", speed: "871 KM/H", cat: "WIDE-BODY"),
    "A333": .init(name: "AIRBUS A330-300", wing: "60.3 M", range: "11,750 KM", speed: "871 KM/H", cat: "WIDE-BODY"),
    "A359": .init(name: "AIRBUS A350-900", wing: "64.8 M", range: "15,000 KM", speed: "903 KM/H", cat: "WIDE-BODY"),
    "A388": .init(name: "AIRBUS A380-800", wing: "79.8 M", range: "15,200 KM", speed: "903 KM/H", cat: "DOUBLE-DECK"),
    "BCS1": .init(name: "AIRBUS A220-100", wing: "35.1 M", range: "5,740 KM", speed: "871 KM/H", cat: "NARROW-BODY"),
    "BCS3": .init(name: "AIRBUS A220-300", wing: "35.1 M", range: "6,300 KM", speed: "871 KM/H", cat: "NARROW-BODY"),
    "B737": .init(name: "BOEING 737-700", wing: "35.8 M", range: "6,370 KM", speed: "842 KM/H", cat: "NARROW-BODY"),
    "B738": .init(name: "BOEING 737-800", wing: "35.8 M", range: "5,765 KM", speed: "842 KM/H", cat: "NARROW-BODY"),
    "B739": .init(name: "BOEING 737-900", wing: "35.8 M", range: "6,045 KM", speed: "842 KM/H", cat: "NARROW-BODY"),
    "B38M": .init(name: "BOEING 737 MAX 8", wing: "35.9 M", range: "6,570 KM", speed: "842 KM/H", cat: "NARROW-BODY"),
    "B752": .init(name: "BOEING 757-200", wing: "38.1 M", range: "7,225 KM", speed: "854 KM/H", cat: "NARROW-BODY"),
    "B763": .init(name: "BOEING 767-300", wing: "47.6 M", range: "11,070 KM", speed: "851 KM/H", cat: "WIDE-BODY"),
    "B772": .init(name: "BOEING 777-200", wing: "60.9 M", range: "9,700 KM", speed: "905 KM/H", cat: "WIDE-BODY"),
    "B77W": .init(name: "BOEING 777-300ER", wing: "64.8 M", range: "13,650 KM", speed: "950 KM/H", cat: "WIDE-BODY"),
    "B788": .init(name: "BOEING 787-8", wing: "60.1 M", range: "13,530 KM", speed: "903 KM/H", cat: "WIDE-BODY"),
    "B789": .init(name: "BOEING 787-9", wing: "60.1 M", range: "14,140 KM", speed: "903 KM/H", cat: "WIDE-BODY"),
    "DH8D": .init(name: "BOMBARDIER Q400", wing: "28.4 M", range: "2,040 KM", speed: "667 KM/H", cat: "TURBOPROP"),
    "CRJ9": .init(name: "BOMBARDIER CRJ-900", wing: "24.9 M", range: "2,875 KM", speed: "830 KM/H", cat: "REGIONAL JET"),
    "E175": .init(name: "EMBRAER E175", wing: "26.0 M", range: "3,735 KM", speed: "870 KM/H", cat: "REGIONAL JET"),
    "E190": .init(name: "EMBRAER E190", wing: "28.7 M", range: "4,537 KM", speed: "870 KM/H", cat: "REGIONAL JET"),
]

// MARK: - Widget / LED copy helpers

enum FlightLEDCopy {
    static func aircraftTypeLine(for flight: Flight) -> String {
        let code = flight.type.uppercased()
        if !code.isEmpty, let spec = AIRCRAFT_DB[code] {
            return String(spec.name.prefix(14))
        }
        if !code.isEmpty { return code }
        return "—"
    }

    /// Shorter label for home-screen widget (fits LED grid).
    static func aircraftTypeShort(for flight: Flight) -> String {
        let code = flight.type.uppercased()
        switch code {
        case "DH8D": return "DHC-8 Q400"
        case "B738": return "B737-800"
        case "B38M": return "737 MAX 8"
        case "A320", "A20N": return "A320"
        case "A321", "A21N": return "A321"
        case "A388": return "A380-800"
        case "B77W": return "777-300ER"
        case "E175": return "E175"
        case "E190": return "E190"
        case "CRJ9": return "CRJ-900"
        default:
            if let spec = AIRCRAFT_DB[code] {
                return String(spec.name.prefix(11))
            }
            return code.isEmpty ? "—" : String(code.prefix(8))
        }
    }

    static func routeLine(_ route: RouteData?) -> String? {
        guard let ends = knownRouteEnds(route) else { return nil }
        return "\(ends.dep)-\(ends.arr)"
    }

    /// ICAO callsign for LED boards (e.g. JBU50), not marketing IATA (B6 50).
    static func displayCallsign(for flight: Flight, maxLength: Int = 7) -> String {
        let trimmed = flight.callsign.trimmingCharacters(in: .whitespaces).uppercased()
        if !trimmed.isEmpty { return String(trimmed.prefix(maxLength)) }
        let reg = flight.registration.trimmingCharacters(in: .whitespaces).uppercased()
        if !reg.isEmpty { return String(reg.prefix(maxLength)) }
        let icao = flight.icao24.trimmingCharacters(in: .whitespaces).uppercased()
        if !icao.isEmpty { return String(icao.prefix(maxLength)) }
        return "—"
    }

    static func flightNumberLine(_ callsign: String) -> String {
        let c = callsign.trimmingCharacters(in: .whitespaces).uppercased()
        guard c.count > 3, let iata = AirlineLEDCache.iata(from: c) else {
            return String(c.prefix(12))
        }
        let num = c.dropFirst(3).trimmingCharacters(in: .whitespaces)
        return num.isEmpty ? iata : "\(iata) \(num)"
    }

    /// Bottom status lines like the airport LED board inspo.
    static func boardFooter(flight: Flight, route: RouteData?) -> (label: String, place: String) {
        if let ends = knownRouteEnds(route) {
            let dep = displayAP(ends.dep)
            let arr = displayAP(ends.arr)
            let alt = flight.altitudeInFeet
            if alt < 12_000 {
                if !dep.city.isEmpty { return ("ARRIVING FROM", airportPlaceName(dep)) }
                if !dep.code.isEmpty { return ("ARRIVING FROM", "\(dep.code) INTL") }
            }
            if !arr.city.isEmpty { return ("EN ROUTE TO", airportPlaceName(arr)) }
            if !arr.code.isEmpty { return ("EN ROUTE TO", "\(arr.code) INTL") }
        }
        let altK = max(1, flight.altitudeInFeet / 1000)
        return (flight.phase.compactName, "\(altK)K FT")
    }

    private static func airportPlaceName(_ ap: (code: String, city: String)) -> String {
        if !ap.city.isEmpty {
            let c = ap.city.capitalized
            if c == "DUBAI" { return "Dubai Intl" }
            if c == "LOS ANGELES" { return "Los Angeles Intl" }
            return c
        }
        return ap.code
    }
}
