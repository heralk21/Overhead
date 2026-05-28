import SwiftUI
import CoreLocation
import Combine

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  LED MATRIX WATCH DISPLAY
//  Target: watchOS 7+  (SE 1st gen and all newer models)
//  Grid: 54×52 LEDs — fits all watch sizes (40mm → 49mm)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: ── 5×7 BITMAP FONT ──────────────────────────────────

private let FONT: [Character: [UInt8]] = [
    " ":[0,0,0,0,0,0,0],
    "A":[14,17,17,31,17,17,17],"B":[30,17,17,30,17,17,30],
    "C":[14,17,16,16,16,17,14],"D":[28,18,17,17,17,18,28],
    "E":[31,16,16,30,16,16,31],"F":[31,16,16,30,16,16,16],
    "G":[14,17,16,23,17,17,14],"H":[17,17,17,31,17,17,17],
    "I":[14,4,4,4,4,4,14],     "J":[7,2,2,2,2,18,12],
    "K":[17,18,20,24,20,18,17],"L":[16,16,16,16,16,16,31],
    "M":[17,27,21,21,17,17,17],"N":[17,25,21,19,17,17,17],
    "O":[14,17,17,17,17,17,14],"P":[30,17,17,30,16,16,16],
    "Q":[14,17,17,17,21,18,13],"R":[30,17,17,30,20,18,17],
    "S":[15,16,16,14,1,1,30],  "T":[31,4,4,4,4,4,4],
    "U":[17,17,17,17,17,17,14],"V":[17,17,17,17,10,10,4],
    "W":[17,17,17,21,21,27,17],"X":[17,17,10,4,10,17,17],
    "Y":[17,17,10,4,4,4,4],    "Z":[31,1,2,4,8,16,31],
    "0":[14,17,19,21,25,17,14],"1":[4,12,4,4,4,4,14],
    "2":[14,17,1,2,4,8,31],    "3":[31,2,4,2,1,17,14],
    "4":[2,6,10,18,31,2,2],    "5":[31,16,30,1,1,17,14],
    "6":[6,8,16,30,17,17,14],  "7":[31,1,2,4,8,8,8],
    "8":[14,17,17,14,17,17,14],"9":[14,17,17,15,1,2,12],
    ".":[0,0,0,0,0,4,4],       ":":[0,4,4,0,4,4,0],
    "-":[0,0,0,31,0,0,0],      ">":[0,8,4,2,4,8,0],
    "+":[0,4,4,31,4,4,0],      "/":[0,1,2,4,8,16,0],
]

// MARK: ── LED COLOR ─────────────────────────────────────────

private struct LC {
    let r: Double, g: Double, b: Double
    var color: Color { Color(red: r, green: g, blue: b) }
    var glow:  Color { Color(red: r, green: g, blue: b).opacity(0.26) }
    static let wh = LC(r:0.92,g:0.93,b:0.98)
    static let cy = LC(r:0.40,g:0.78,b:0.98)
    static let gn = LC(r:0.20,g:0.90,b:0.48)
    static let dm = LC(r:0.35,g:0.40,b:0.50)
    static let xx = LC(r:0.10,g:0.12,b:0.18)
}

// MARK: ── LED BUFFER ────────────────────────────────────────

private struct LP { var c: LC = LC(r:0,g:0,b:0); var on = false }

private final class LB {
    let w: Int, h: Int; var px: [[LP]]
    init(_ w: Int, _ h: Int) {
        self.w = w; self.h = h
        px = .init(repeating: .init(repeating: LP(), count: w), count: h)
    }
    func set(_ x: Int, _ y: Int, _ c: LC) {
        guard x >= 0, x < w, y >= 0, y < h else { return }
        px[y][x] = LP(c: c, on: true)
    }
    func txt(_ s: String, _ x: Int, _ y: Int, _ c: LC) {
        var cx = x
        for ch in s {
            if let g = FONT[ch] ?? FONT[Character(ch.uppercased())] {
                for row in 0..<7 { for col in 0..<5 {
                    if g[row] & (1 << (4-col)) != 0 { set(cx+col, y+row, c) }
                }}
            }
            cx += 6
        }
    }
    func cTxt(_ s: String, _ y: Int, _ c: LC) {
        txt(s, max(0, (w - s.count * 6) / 2), y, c)
    }
    func hline(_ y: Int, _ c: LC) { for x in 0..<w { set(x, y, c) } }
}

// MARK: ── LED CANVAS (watchOS 7+) ──────────────────────────

private struct LEDView: View {
    let buf: LB; let pitch: CGFloat
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color(red: 0.018, green: 0.018, blue: 0.025)))
            let core = pitch * 0.32
            let bloom = pitch * 0.82
            let off   = pitch * 0.15
            for row in 0..<buf.h { for col in 0..<buf.w {
                let cx = CGFloat(col) * pitch + pitch * 0.5
                let cy = CGFloat(row) * pitch + pitch * 0.5
                let p  = buf.px[row][col]
                if p.on {
                    ctx.fill(Path(ellipseIn: CGRect(x:cx-bloom, y:cy-bloom,
                                                    width:bloom*2, height:bloom*2)),
                             with: .color(p.c.glow))
                    ctx.fill(Path(ellipseIn: CGRect(x:cx-core, y:cy-core,
                                                    width:core*2, height:core*2)),
                             with: .color(p.c.color))
                } else {
                    ctx.fill(Path(ellipseIn: CGRect(x:cx-off, y:cy-off,
                                                    width:off*2, height:off*2)),
                             with: .color(Color(red:0.05,green:0.05,blue:0.065)))
                }
            }}
        }
    }
}

// MARK: ── AIRLINE TABLE (max 9 chars = 54 LEDs exact fill) ──

private struct AirlineInfo { let name: String; let color: LC }
private let AIRLINES: [String: AirlineInfo] = [
    "ACA": AirlineInfo(name:"AIR CANAD", color:LC(r:0.90,g:0.08,b:0.10)),
    "JZA": AirlineInfo(name:"AC EXPRES", color:LC(r:0.90,g:0.08,b:0.10)),
    "ROU": AirlineInfo(name:"AC ROUGE",  color:LC(r:0.90,g:0.08,b:0.10)),
    "WJA": AirlineInfo(name:"WESTJET",   color:LC(r:0.00,g:0.65,b:0.65)),
    "WEN": AirlineInfo(name:"WJ ENCORE", color:LC(r:0.00,g:0.60,b:0.60)),
    "DAL": AirlineInfo(name:"DELTA",     color:LC(r:0.10,g:0.25,b:0.70)),
    "SWA": AirlineInfo(name:"SOUTHWEST", color:LC(r:0.90,g:0.45,b:0.05)),
    "AAL": AirlineInfo(name:"AMERICAN",  color:LC(r:0.00,g:0.35,b:0.80)),
    "UAL": AirlineInfo(name:"UNITED",    color:LC(r:0.00,g:0.25,b:0.60)),
    "ASA": AirlineInfo(name:"ALASKA",    color:LC(r:0.00,g:0.30,b:0.65)),
    "SKW": AirlineInfo(name:"SKYWEST",   color:LC(r:0.10,g:0.30,b:0.70)),
    "HAL": AirlineInfo(name:"HAWAIIAN",  color:LC(r:0.55,g:0.00,b:0.45)),
    "FFT": AirlineInfo(name:"FRONTIER",  color:LC(r:0.00,g:0.55,b:0.25)),
    "JBU": AirlineInfo(name:"JETBLUE",   color:LC(r:0.00,g:0.45,b:0.85)),
    "BAW": AirlineInfo(name:"BRIT AIR",  color:LC(r:0.00,g:0.25,b:0.60)),
    "DLH": AirlineInfo(name:"LUFTHANSA", color:LC(r:0.95,g:0.80,b:0.00)),
    "AFR": AirlineInfo(name:"AIR FRANC", color:LC(r:0.00,g:0.20,b:0.60)),
    "KLM": AirlineInfo(name:"KLM",       color:LC(r:0.00,g:0.45,b:0.75)),
    "UAE": AirlineInfo(name:"EMIRATES",  color:LC(r:0.70,g:0.00,b:0.00)),
    "QFA": AirlineInfo(name:"QANTAS",    color:LC(r:0.85,g:0.10,b:0.10)),
    "CPA": AirlineInfo(name:"CATHAY",    color:LC(r:0.00,g:0.50,b:0.50)),
    "ANA": AirlineInfo(name:"ANA",       color:LC(r:0.00,g:0.25,b:0.60)),
    "JAL": AirlineInfo(name:"JAL",       color:LC(r:0.75,g:0.00,b:0.10)),
    "SIA": AirlineInfo(name:"SINGAPORE", color:LC(r:0.80,g:0.00,b:0.00)),
    "RYR": AirlineInfo(name:"RYANAIR",   color:LC(r:0.00,g:0.20,b:0.60)),
    "EZY": AirlineInfo(name:"EASYJET",   color:LC(r:0.90,g:0.45,b:0.00)),
    "TSC": AirlineInfo(name:"TRANSAT",   color:LC(r:0.00,g:0.35,b:0.75)),
    "THY": AirlineInfo(name:"TURKISH",   color:LC(r:0.85,g:0.08,b:0.10)),
    "QTR": AirlineInfo(name:"QATAR AIR", color:LC(r:0.55,g:0.00,b:0.20)),
    "ETD": AirlineInfo(name:"ETIHAD",    color:LC(r:0.70,g:0.60,b:0.30)),
]
private let DEFAULT_AIRLINE = AirlineInfo(name:"UNKNOWN", color:LC(r:0.25,g:0.52,b:0.95))

// MARK: ── AIRPORT DISPLAY MAP ───────────────────────────────

private let AIRPORTS: [String: String] = [
    "CYVR":"YVR","CYYZ":"YYZ","CYUL":"YUL","CYYC":"YYC","CYEG":"YEG",
    "CYOW":"YOW","CYWG":"YWG","CYHZ":"YHZ","CYQB":"YQB",
    "KLAX":"LAX","KJFK":"JFK","KORD":"ORD","KATL":"ATL","KSFO":"SFO",
    "KDFW":"DFW","KLAS":"LAS","KDEN":"DEN","KSEA":"SEA","KMIA":"MIA",
    "KBOS":"BOS","KEWR":"EWR","KPHX":"PHX","KIAH":"IAH","KTPA":"TPA",
    "KMCO":"MCO","KBNA":"BNA","KRDU":"RDU","KAUS":"AUS","KPDX":"PDX",
    "EGLL":"LHR","EGKK":"LGW","EGCC":"MAN","EGPH":"EDI",
    "LFPG":"CDG","EHAM":"AMS","EDDF":"FRA","EDDM":"MUC",
    "LEMD":"MAD","LEBL":"BCN","LIRF":"FCO","LSZH":"ZRH",
    "OMDB":"DXB","OTHH":"DOH","VHHH":"HKG","RJTT":"HND",
    "RJAA":"NRT","RKSI":"ICN","WSSS":"SIN","YMML":"MEL","YSSY":"SYD",
]
private func displayAP(_ code: String?) -> String {
    guard let c = code, !c.isEmpty else { return "???" }
    if let d = AIRPORTS[c] { return d }
    if c.count == 4 && (c.hasPrefix("K") || c.hasPrefix("C")) { return String(c.dropFirst()) }
    return c.count >= 3 ? String(c.suffix(3)) : c
}

// MARK: ── ROUTE STORE ───────────────────────────────────────
// FIX: import Combine at top → ObservableObject and @Published work

final class WatchRouteStore: ObservableObject {  // ✓ Combine imported
    static let shared = WatchRouteStore()
    @Published var routes: [String: (dep: String, arr: String)] = [:]  // ✓ Combine imported

    func fetch(icao24: String) {
        guard routes[icao24] == nil else { return }
        let end = Int(Date().timeIntervalSince1970), begin = end - 86400
        guard let url = URL(string:
            "https://opensky-network.org/api/flights/aircraft?icao24=\(icao24)&begin=\(begin)&end=\(end)")
        else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, _ in
            guard let data = data,
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let last = list.last
            else { return }

            let dep = displayAP(last["estDepartureAirport"] as? String)
            let arr = displayAP(last["estArrivalAirport"]   as? String)
            guard dep != "???" || arr != "???" else { return }

            DispatchQueue.main.async {
                self?.routes[icao24] = (dep: dep, arr: arr)
            }
        }.resume()
    }
}

// MARK: ── BUILD BUFFERS ─────────────────────────────────────

private func buildWelcome(_ gw: Int, _ gh: Int) -> LB {
    let b = LB(gw, gh)
    b.cTxt("RADAR",    16, .cy)   // 5 chars = 30 LEDs ✓
    b.hline(25, .xx)
    b.cTxt("TAP SCAN", 29, .dm)  // 8 chars = 48 LEDs ✓
    return b
}

private func buildWatch(
    _ f: Flight?,
    _ loading: Bool,
    _ routes: [String: (dep: String, arr: String)],
    _ gw: Int, _ gh: Int
) -> LB {
    let b = LB(gw, gh)

    if loading && f == nil {
        b.cTxt("SCANNING", 18, .cy)  // 8 chars = 48 LEDs ✓
        b.cTxt("AIRSPACE", 28, .dm)  // 8 chars = 48 LEDs ✓
        return b
    }
    guard let f = f else {
        b.cTxt("NO SIGNAL", 18, .dm) // 9 chars = 54 LEDs ✓
        b.hline(27, .xx)
        b.cTxt("TAP RETRY", 31, .dm) // 9 chars = 54 LEDs ✓
        return b
    }

    let icao = String(f.callsign.prefix(3)).uppercased()
    let info = AIRLINES[icao] ?? DEFAULT_AIRLINE

    // Airline name — max 9 chars × 6 = 54 LEDs (exact grid width)
    b.cTxt(String(info.name.prefix(9)), 2, info.color)
    b.hline(10, .xx)

    // Callsign — max 7 chars = 42 LEDs, centered
    b.cTxt(String(f.callsign.prefix(7)), 12, .wh)
    b.hline(20, .xx)

    // Route "YVR > YYZ" (9 chars = 54 LEDs) or status (max 9 chars)
    if let rt = routes[f.icao24] {
        let route = String("\(rt.dep) > \(rt.arr)".prefix(9))
        b.cTxt(route, 22, .gn)
    } else {
        let status = String(f.altitudeStatus.uppercased().prefix(9))
        b.cTxt(status, 22, .dm)
    }
    b.hline(30, .xx)

    // Altitude — "A:35KFT" = 7 chars = 42 LEDs ✓
    b.cTxt("A:\(f.altitudeInFeet / 1000)KFT", 32, .cy)
    // Speed — "S:480KT" = 7 chars = 42 LEDs ✓
    b.cTxt("S:\(f.velocityInKnots)KT", 41, .cy)

    return b
}

// MARK: ── PANEL VIEW ────────────────────────────────────────

// MARK: ── CONTENT VIEW ──────────────────────────────────────

struct ContentView: View {
    @StateObject  private var service = FlightService()
    @ObservedObject private var store = WatchRouteStore.shared
    @State private var loaded = false
    private let gw = 54, gh = 52

    private var currentBuf: LB {
        guard loaded else { return buildWelcome(gw, gh) }
        return buildWatch(service.flights.first, service.isLoading, store.routes, gw, gh)
    }

    var body: some View {
        ZStack {
            // Background fills full screen including safe area
            Color(red: 0.018, green: 0.018, blue: 0.025)
                .ignoresSafeArea()

            // GeometryReader measures the safe content area
            GeometryReader { geo in
                let pitch = min(geo.size.width  / CGFloat(gw),
                               geo.size.height / CGFloat(gh))
                let ledW  = CGFloat(gw) * pitch
                let ledH  = CGFloat(gh) * pitch

                // LEDView sized to exactly the grid, then centered
                // .position anchors the view's center to the given point
                LEDView(buf: currentBuf, pitch: pitch)
                    .frame(width: ledW, height: ledH)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .onTapGesture { refresh() }
        // FIX: use .count (Int = Equatable) instead of [Flight] array
        // [Flight] isn't Equatable so onChange(of:) won't compile
        .onReceive(service.$flights) { fl in
            if let top = fl.first {
                store.fetch(icao24: top.icao24)
            }
        }
    }

    private func refresh() {
        loaded = true
        let mgr = CLLocationManager()
        mgr.requestWhenInUseAuthorization()
        // Use last known location; fall back to Vancouver if none available
        let coord = mgr.location?.coordinate
        service.fetchFlights(
            latitude:  coord?.latitude  ?? 49.2827,
            longitude: coord?.longitude ?? -123.1207
        )
        // If no cached location, wait briefly for GPS then retry once
        if coord == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let loc = CLLocationManager().location {
                    service.fetchFlights(latitude:  loc.coordinate.latitude,
                                        longitude: loc.coordinate.longitude)
                }
            }
        }
    }
}

#Preview { ContentView() }
