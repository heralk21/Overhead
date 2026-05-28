import WidgetKit
import SwiftUI
import CoreLocation
import AppIntents
import CoreGraphics
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  LED MATRIX FLIGHT WALL · AUTO-FETCH AIRLINE LOGOS
//
//  Pipeline: callsign → ICAO → IATA → fetch PNG from API →
//            cache locally → CGImage pixel sampling →
//            nearest-neighbor downscale → LED bitmap → Canvas render
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: ── 5x7 BITMAP FONT ──────────────────────────────────────────

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
    "+":[0,4,4,31,4,4,0],      "-":[0,0,0,31,0,0,0],
]

// MARK: ── LED COLOR + BUFFER ────────────────────────────────────────

struct LC {
    let r: Double, g: Double, b: Double
    var color: Color { Color(red: r, green: g, blue: b) }
    var glow: Color { Color(red: r, green: g, blue: b).opacity(0.22) }
    static let wh = LC(r:0.92,g:0.93,b:0.98)
    static let cy = LC(r:0.40,g:0.78,b:0.98)
    static let dm = LC(r:0.45,g:0.50,b:0.58)
}

struct LP { var c: LC = LC(r:0,g:0,b:0); var on = false }

class LB {
    let w: Int, h: Int; var px: [[LP]]
    init(_ w: Int, _ h: Int) {
        self.w = w; self.h = h
        px = .init(repeating: .init(repeating: LP(), count: w), count: h)
    }
    func set(_ x: Int, _ y: Int, _ c: LC) {
        guard x>=0,x<w,y>=0,y<h else { return }
        px[y][x] = LP(c:c, on:true)
    }
    func txt(_ s: String, _ x: Int, _ y: Int, _ c: LC) {
        var cx = x
        for ch in s {
            if let g = FONT[ch] ?? FONT[Character(ch.uppercased())] {
                for row in 0..<7 { for col in 0..<5 {
                    if g[row] & (1<<(4-col)) != 0 { set(cx+col, y+row, c) }
                }}
            }; cx += 6
        }
    }
    func line(_ x:Int,_ y:Int,_ l:Int,_ c:LC) { for dx in 0..<l { set(x+dx,y,c) } }
    func vline(_ x:Int,_ y:Int,_ l:Int,_ c:LC) { for dy in 0..<l { set(x,y+dy,c) } }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  ICAO → IATA MAPPING (100+ airlines)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private let icaoToIata: [String: String] = [
    "ACA":"AC","JZA":"QK","WJA":"WS","WEN":"WR","ASA":"AS",
    "SKW":"OO","UAL":"UA","AAL":"AA","DAL":"DL","SWA":"WN",
    "HAL":"HA","FFT":"F9","NKS":"NK","BAW":"BA","DLH":"LH",
    "AFR":"AF","KLM":"KL","UAE":"EK","QFA":"QF","CPA":"CX",
    "ANA":"NH","JAL":"JL","ROU":"RV","EIN":"EI","ETD":"EY",
    "SIA":"SQ","THA":"TG","CES":"MU","CCA":"CA","CSN":"CZ",
    "KAL":"KE","AAR":"OZ","EVA":"BR","CAL":"CI","PAL":"PR",
    "MAS":"MH","GIA":"GA","SAS":"SK","FIN":"AY","TAP":"TP",
    "IBE":"IB","AZA":"AZ","THY":"TK","LOT":"LO","CSA":"OK",
    "AEE":"A3","SVA":"SV","QTR":"QR","AIC":"AI","ETH":"ET",
    "SAA":"SA","KQA":"KQ","AVA":"AV","LAN":"LA","GLO":"G3",
    "VOZ":"VA","VIR":"VS","EZY":"U2","RYR":"FR","WZZ":"W6",
    "JBU":"B6","ENY":"MQ","RPA":"YX","PDT":"PT","CPZ":"OH",
    "EDV":"9E","GJS":"G7","AJI":"K6","TSC":"TS","PVL":"PB",
    "POE":"PD","FLE":"BE","TRS":"TP","SWR":"LX","AUA":"OS",
    "BEL":"SN","SFJ":"7G","SKX":"GQ","PAC":"WP","QXE":"QX",
]

private let airlineNames: [String: String] = [
    "ACA":"AIR CANADA","JZA":"AC EXPRESS","WJA":"WESTJET",
    "ASA":"ALASKA AIR","SKW":"SKYWEST","UAL":"UNITED",
    "AAL":"AMERICAN","DAL":"DELTA","SWA":"SOUTHWEST",
    "HAL":"HAWAIIAN","FFT":"FRONTIER","NKS":"SPIRIT",
    "BAW":"BRITISH AIR","DLH":"LUFTHANSA","AFR":"AIR FRANCE",
    "KLM":"KLM","UAE":"EMIRATES","QFA":"QANTAS",
    "CPA":"CATHAY PAC","ANA":"ANA","JAL":"JAPAN AIR",
    "ROU":"AC ROUGE","SIA":"SINGAPORE","THA":"THAI AIR",
    "KAL":"KOREAN AIR","EVA":"EVA AIR","RYR":"RYANAIR",
    "EZY":"EASYJET","WZZ":"WIZZ AIR","JBU":"JETBLUE",
    "VIR":"VIRGIN ATL","QTR":"QATAR AIR","ETD":"ETIHAD",
    "SAA":"SOUTH AFRIC","THY":"TURKISH","IBE":"IBERIA",
    "SWR":"SWISS","AUA":"AUSTRIAN","TAP":"TAP PORT",
    "SAS":"SAS","FIN":"FINNAIR","TSC":"TRANSAT",
]

func getAirlineName(_ cs: String) -> String {
    airlineNames[String(cs.prefix(3)).uppercased()] ?? String(cs.prefix(7))
}

func getIATA(_ cs: String) -> String? {
    icaoToIata[String(cs.prefix(3)).uppercased()]
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  AIRLINE LOGO AUTO-FETCHER + RASTERIZER
//
//  1. Check local cache for previously downloaded logo
//  2. If not cached, download from pics.avs.io (free, no auth)
//  3. Cache PNG to disk
//  4. Rasterize: CGImage → 14x14 nearest-neighbor → pixel sample
//  5. Store LED bitmap in memory cache
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct RasterizedLogo {
    let width: Int
    let height: Int
    let pixels: [[LC?]]
}

final class LogoEngine {
    static let shared = LogoEngine()

    private var rasterCache: [String: RasterizedLogo] = [:]
    private let cacheDir: URL

    private init() {
        let fm = FileManager.default
        let base = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDir = base.appendingPathComponent("airline_led_logos")
        try? fm.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    /// Get rasterized LED logo synchronously (from memory/disk cache)
    func getCachedLogo(icao: String, size: Int = 14) -> RasterizedLogo? {
        // Memory cache
        if let cached = rasterCache[icao] { return cached }

        // Disk cache → rasterize
        guard let iata = icaoToIata[icao] else { return nil }
        let path = cacheDir.appendingPathComponent("\(iata).png")
        guard let data = try? Data(contentsOf: path),
              let image = UIImage(data: data),
              let logo = rasterize(image: image, size: size) else { return nil }

        rasterCache[icao] = logo
        return logo
    }

    /// Fetch logo from API and cache to disk (async, call during timeline update)
    func prefetchLogo(icao: String, completion: @escaping () -> Void) {
        guard let iata = icaoToIata[icao] else { completion(); return }

        // Already on disk?
        let path = cacheDir.appendingPathComponent("\(iata).png")
        if FileManager.default.fileExists(atPath: path.path) {
            completion(); return
        }

        // Download from pics.avs.io (free airline logo API, no auth needed)
        // Returns transparent PNG logos for virtually every airline
        let url = URL(string: "https://pics.avs.io/200/200/\(iata).png")!

        URLSession.shared.dataTask(with: url) { data, response, _ in
            defer { completion() }
            guard let data = data, data.count > 500, // skip tiny error responses
                  let httpResp = response as? HTTPURLResponse,
                  httpResp.statusCode == 200,
                  UIImage(data: data) != nil
            else { return }

            try? data.write(to: path)
        }.resume()
    }

    /// Core rasterizer: UIImage → LED pixel grid
    func rasterize(image: UIImage, size: Int) -> RasterizedLogo? {
        guard let cgImage = image.cgImage else { return nil }

        let srcW = cgImage.width, srcH = cgImage.height
        let aspect = Double(srcW) / Double(srcH)
        let tW = aspect >= 1.0 ? size : max(1, Int(Double(size) * aspect))
        let tH = aspect >= 1.0 ? max(1, Int(Double(size) / aspect)) : size

        let bpp = 4, bpr = bpp * tW
        var pixels = [UInt8](repeating: 0, count: tH * bpr)

        guard let cs = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: &pixels, width: tW, height: tH,
                                 bitsPerComponent: 8, bytesPerRow: bpr, space: cs,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }

        // NEAREST-NEIGHBOR: no smoothing, sharp LED pixels
        ctx.interpolationQuality = .none
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: tW, height: tH))

        var result: [[LC?]] = []
        for y in 0..<tH {
            var row: [LC?] = []
            for x in 0..<tW {
                let off = (y * bpr) + (x * bpp)
                let r = Double(pixels[off]) / 255.0
                let g = Double(pixels[off+1]) / 255.0
                let b = Double(pixels[off+2]) / 255.0
                let a = Double(pixels[off+3]) / 255.0

                if a < 0.25 { row.append(nil) }
                else if (r+g+b) * a < 0.08 { row.append(nil) }
                else {
                    let cr = min(1.0, r / max(a, 0.01))
                    let cg = min(1.0, g / max(a, 0.01))
                    let cb = min(1.0, b / max(a, 0.01))
                    row.append(LC(r: cr, g: cg, b: cb))
                }
            }
            result.append(row)
        }
        return RasterizedLogo(width: tW, height: tH, pixels: result)
    }
}

// MARK: ── RENDER LOGO INTO LED BUFFER ───────────────────────────────

func renderLogo(_ buf: LB, _ logo: RasterizedLogo, _ ox: Int, _ oy: Int) {
    for y in 0..<logo.height {
        for x in 0..<logo.width {
            if let c = logo.pixels[y][x] { buf.set(ox+x, oy+y, c) }
        }
    }
}

func renderFallback(_ buf: LB, _ icao: String, _ ox: Int, _ oy: Int, _ size: Int) {
    let cx = ox+size/2, cy = oy+size/2, r = size/2-1
    for dy in -r...r { for dx in -r...r {
        if dx*dx+dy*dy <= r*r { buf.set(cx+dx, cy+dy, LC(r:0.20,g:0.45,b:0.85)) }
    }}
    buf.txt(String(icao.prefix(2)), cx-5, cy-3, .wh)
}

// MARK: ── BUILD LED WALL BUFFERS ────────────────────────────────────

func buildWall(_ f: Flight?, _ cnt: Int, _ gw: Int, _ gh: Int) -> LB {
    let b = LB(gw, gh)
    let sep = LC(r:0.10,g:0.12,b:0.18)

    guard let f = f else {
        b.txt("NO SIGNAL", gw/2-27, gh/2-8, .dm)
        b.line(8, gh/2-1, gw-16, sep)
        b.txt("OPEN APP TO SCAN", gw/2-48, gh/2+3, .cy)
        return b
    }

    let icao = String(f.callsign.prefix(3)).uppercased()
    let name = getAirlineName(f.callsign)
    let logoSize = 14
    let logoX = 2, logoY = max(2, gh/2 - logoSize/2 - 3)

    // Render real rasterized logo or fallback
    if let logo = LogoEngine.shared.getCachedLogo(icao: icao, size: logoSize) {
        renderLogo(b, logo, logoX, logoY)
    } else {
        renderFallback(b, icao, logoX, logoY, logoSize)
    }

    let s1 = logoX + logoSize + 2
    b.vline(s1, 2, gh-4, sep)

    let tx = s1 + 3
    var ty = 3
    b.txt(name, tx, ty, .wh); ty += 9
    b.txt(f.callsign, tx, ty, .wh); ty += 9
    b.line(tx, ty, 35, sep); ty += 3
    b.txt(f.altitudeStatus.uppercased(), tx, ty, .cy); ty += 9
    b.txt(String(format:"%.2f N", f.latitude), tx, ty, .cy); ty += 9
    if ty+7 < gh { b.txt(String(format:"%.2f W", abs(f.longitude)), tx, ty, .cy) }

    let s2 = gw - 42
    b.vline(s2, 2, gh-4, sep)

    let sx = s2+3; var sy = 3
    b.txt("ALT:", sx, sy, .dm); sy += 8
    b.txt("\(f.altitudeInFeet/1000)K", sx, sy, .cy); sy += 10
    b.txt("SPD:", sx, sy, .dm); sy += 8
    b.txt("\(f.velocityInKnots)KT", sx, sy, .cy); sy += 10
    if sy+14 < gh { b.txt("TRK:", sx, sy, .dm); sy += 8; b.txt("\(Int(f.heading))D", sx, sy, .cy) }

    return b
}

func buildSmall(_ f: Flight?, _ gw: Int, _ gh: Int) -> LB {
    let b = LB(gw, gh)
    guard let f = f else {
        b.txt("NO", gw/2-6, gh/2-8, .dm)
        b.txt("SIGNAL", gw/2-18, gh/2, .dm)
        return b
    }
    let icao = String(f.callsign.prefix(3)).uppercased()
    let sz = 12
    if let logo = LogoEngine.shared.getCachedLogo(icao: icao, size: sz) {
        renderLogo(b, logo, 1, 1)
    } else { renderFallback(b, icao, 1, 1, sz) }

    b.txt(f.callsign, 2, sz+3, .wh)
    b.line(2, sz+11, gw-4, LC(r:0.10,g:0.12,b:0.18))
    b.txt("A:\(f.altitudeInFeet/1000)K", 2, sz+14, .cy)
    b.txt("S:\(f.velocityInKnots)", 2, sz+22, .cy)
    return b
}

// MARK: ── LED MATRIX CANVAS ─────────────────────────────────────────

struct LEDView: View {
    let buf: LB; let pitch: CGFloat
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin:.zero, size:size)), with:.color(Color(red:0.018,green:0.018,blue:0.025)))
            let dotR = pitch*0.32, glowR = pitch*0.85, offR = pitch*0.17
            for row in 0..<buf.h { for col in 0..<buf.w {
                let cx = CGFloat(col)*pitch + pitch*0.5
                let cy = CGFloat(row)*pitch + pitch*0.5
                let p = buf.px[row][col]
                if p.on {
                    ctx.fill(Path(ellipseIn: CGRect(x:cx-glowR,y:cy-glowR,width:glowR*2,height:glowR*2)), with:.color(p.c.glow))
                    ctx.fill(Path(ellipseIn: CGRect(x:cx-dotR,y:cy-dotR,width:dotR*2,height:dotR*2)), with:.color(p.c.color))
                } else {
                    ctx.fill(Path(ellipseIn: CGRect(x:cx-offR,y:cy-offR,width:offR*2,height:offR*2)),
                             with:.color(Color(red:0.05,green:0.05,blue:0.06)))
                }
            }}
        }
    }
}

// MARK: ── WIDGET VIEWS ──────────────────────────────────────────────

struct RefreshFlightsIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh"
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "FlightTrackerWidget")
        return .result()
    }
}

struct FlightEntry: TimelineEntry { let date: Date; let flights: [Flight] }

struct MediumWall: View {
    let entry: FlightEntry; let gw = 130, gh = 50
    var body: some View {
        GeometryReader { geo in
            let pitch = min(geo.size.width/CGFloat(gw), geo.size.height/CGFloat(gh))
            let buf = buildWall(entry.flights.first, entry.flights.count, gw, gh)
            ZStack {
                Color(red:0.018,green:0.018,blue:0.025)
                LEDView(buf:buf, pitch:pitch)
                RoundedRectangle(cornerRadius:6).stroke(
                    LinearGradient(colors:[
                        Color(red:0.22,green:0.22,blue:0.24),
                        Color(red:0.06,green:0.06,blue:0.08),
                        Color(red:0.18,green:0.18,blue:0.20)],
                    startPoint:.topLeading,endPoint:.bottomTrailing), lineWidth:2.5)
                VStack{Spacer();HStack{Spacer()
                    if #available(iOSApplicationExtension 17.0, *) {
                        Button(intent:RefreshFlightsIntent()){
                            Image(systemName:"arrow.clockwise").font(.system(size:9,weight:.bold))
                                .foregroundColor(Color(red:0.4,green:0.78,blue:0.98))
                                .padding(4).background(Color.black.opacity(0.7)).clipShape(Circle())
                                .shadow(color:Color(red:0.4,green:0.78,blue:0.98).opacity(0.5),radius:3)
                        }.buttonStyle(.plain)
                    }
                }.padding(5)}
            }
        }
        .containerBackground(Color(red:0.018,green:0.018,blue:0.025), for:.widget)
    }
}

struct SmallWall: View {
    let entry: FlightEntry; let gw = 50, gh = 50
    var body: some View {
        GeometryReader { geo in
            let pitch = min(geo.size.width/CGFloat(gw), geo.size.height/CGFloat(gh))
            let buf = buildSmall(entry.flights.first, gw, gh)
            ZStack {
                Color(red:0.018,green:0.018,blue:0.025)
                LEDView(buf:buf, pitch:pitch)
                RoundedRectangle(cornerRadius:6).stroke(
                    LinearGradient(colors:[Color(red:0.22,green:0.22,blue:0.24),Color(red:0.06,green:0.06,blue:0.08)],
                    startPoint:.topLeading,endPoint:.bottomTrailing), lineWidth:2.5)
            }
        }
        .containerBackground(Color(red:0.018,green:0.018,blue:0.025), for:.widget)
    }
}

struct FlightTrackerWidget: Widget {
    let kind = "FlightTrackerWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind:kind, provider:FlightTimelineProvider()) { entry in
            GeometryReader { geo in
                if geo.size.width > 200 { MediumWall(entry:entry) }
                else { SmallWall(entry:entry) }
            }
        }
        .configurationDisplayName("Flight Board")
        .description("LED matrix · auto-fetched airline logos")
        .supportedFamilies([.systemSmall,.systemMedium])
    }
}

// MARK: ── TIMELINE PROVIDER ─────────────────────────────────────────
// Fetches flights AND prefetches airline logos in parallel

struct FlightTimelineProvider: TimelineProvider {
    func placeholder(in c: Context) -> FlightEntry { FlightEntry(date:Date(),flights:[]) }
    func getSnapshot(in c: Context, completion: @escaping (FlightEntry) -> Void) {
        completion(FlightEntry(date:Date(),flights:[]))
    }
    func getTimeline(in c: Context, completion: @escaping (Timeline<FlightEntry>) -> Void) {
        let mgr = CLLocationManager()
        let lat = mgr.location?.coordinate.latitude ?? 49.2827
        let lon = mgr.location?.coordinate.longitude ?? -123.1207
        let r = 50.0, ld = r/111.0, lg = r/(111.0*cos(lat * .pi/180))
        let urlStr = "https://opensky-network.org/api/states/all?lamin=\(lat-ld)&lamax=\(lat+ld)&lomin=\(lon-lg)&lomax=\(lon+lg)"

        guard let url = URL(string: urlStr) else {
            completion(Timeline(entries:[FlightEntry(date:Date(),flights:[])], policy:.after(Date().addingTimeInterval(900))))
            return
        }

        // STEP 1: Fetch flight data
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var flights: [Flight] = []
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
               let states = json["states"] as? [[Any]] {
                for s in states {
                    guard s.count > 10,
                          let cs = s[1] as? String, !cs.trimmingCharacters(in:.whitespaces).isEmpty,
                          let fLat = s[6] as? Double, let fLon = s[5] as? Double,
                          let alt = s[7] as? Double, let vel = s[9] as? Double,
                          let hdg = s[10] as? Double, let icao = s[0] as? String
                    else { continue }
                    flights.append(Flight(callsign:cs.trimmingCharacters(in:.whitespaces),
                                         latitude:fLat, longitude:fLon, altitude:Int(alt),
                                         velocity:vel, heading:hdg, icao24:icao))
                }
                flights.sort { $0.altitude > $1.altitude }
            }

            // STEP 2: Prefetch logos for top 5 airlines (parallel)
            let topICAOs = Array(Set(flights.prefix(5).map {
                String($0.callsign.prefix(3)).uppercased()
            }))

            let group = DispatchGroup()
            for icao in topICAOs {
                group.enter()
                LogoEngine.shared.prefetchLogo(icao: icao) { group.leave() }
            }

            // STEP 3: Build timeline after logos are cached
            group.notify(queue: .main) {
                let entry = FlightEntry(date: Date(), flights: flights)
                let next = Date().addingTimeInterval(900)
                completion(Timeline(entries: [entry], policy: .after(next)))
            }
        }.resume()
    }
}

#Preview(as:.systemMedium) {
    FlightTrackerWidget()
} timeline: { FlightEntry(date:.now,flights:[]) }
