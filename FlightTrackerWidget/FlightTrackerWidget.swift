import WidgetKit
import SwiftUI
import CoreLocation

// LED matrix board widget — layout matched to airport departures inspo.

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
    ".":[0,0,0,0,0,4,4],       "-":[0,0,0,31,0,0,0],
]

private let glyphW = 6
private let glyphH = 7
private let rowStep = glyphH + 2
/// Blank LED rows between aircraft type and status block.
private let sectionGap = 4

struct LC {
    let r: Double, g: Double, b: Double
    var color: Color { Color(red: r, green: g, blue: b) }
    var glow: Color { color.opacity(0.20) }
    static let wh = LC(r: 0.94, g: 0.95, b: 1.0)
    static let cy = LC(r: 0.45, g: 0.82, b: 1.0)
    static let dm = LC(r: 0.22, g: 0.24, b: 0.28)
    static let climb = LC(r: 0.38, g: 0.82, b: 0.58)
    static let coral = LC(r: 0.92, g: 0.28, b: 0.28)
}

private func statusLC(for flight: Flight) -> LC {
    let rgb = flight.statusLEDRGB
    return LC(r: rgb.r, g: rgb.g, b: rgb.b)
}

private func brandLC(callsign: String) -> LC {
    let rgb = AirlineLEDCache.accessibleBrandRGB(callsign: callsign)
    return LC(r: rgb.r, g: rgb.g, b: rgb.b)
}

private func textWidth(_ text: String) -> Int { text.count * glyphW }

struct LP { var c = LC(r: 0, g: 0, b: 0); var on = false }

final class LB {
    let w: Int, h: Int
    var px: [[LP]]

    init(_ w: Int, _ h: Int) {
        self.w = w; self.h = h
        px = .init(repeating: .init(repeating: LP(), count: w), count: h)
        for y in 0..<h {
            for x in 0..<w {
                px[y][x] = LP(c: .dm, on: true)
            }
        }
    }

    func set(_ x: Int, _ y: Int, _ c: LC) {
        guard x >= 0, x < w, y >= 0, y < h else { return }
        px[y][x] = LP(c: c, on: true)
    }

    func fit(_ text: String, maxChars: Int) -> String {
        String(text.prefix(max(0, maxChars)))
    }

    @discardableResult
    func txt(_ s: String, _ x: Int, _ y: Int, _ c: LC) -> Int {
        guard y >= 0, y + glyphH <= h, x < w else { return 0 }
        var cx = x
        for ch in s {
            if cx + glyphW > w { break }
            if let g = FONT[ch] ?? FONT[Character(ch.uppercased())] {
                for row in 0..<glyphH {
                    for col in 0..<5 where g[row] & (1 << (4 - col)) != 0 {
                        set(cx + col, y + row, c)
                    }
                }
            }
            cx += glyphW
        }
        return cx - x
    }

    func hline(_ y: Int, _ x0: Int, _ x1: Int, _ c: LC) {
        guard y >= 0, y < h else { return }
        for x in max(0, x0)...min(w - 1, x1) { set(x, y, c) }
    }
}

// MARK: - Logo

/// Where to draw a bundled airline logo image on the LED grid (cell coordinates).
struct LogoPlacement {
    let asset: String
    let col: Int
    let row: Int
    let size: Int
}

/// Top-down aircraft model art in the medium widget's right column.
struct AircraftPlacement {
    let asset: String
    let col: Int
    let row: Int
    let size: Int
}

func renderBrandLogo(_ buf: LB, callsign: String, ox: Int, oy: Int, size: Int) {
    let brand = AirlineLEDCache.brandRGB(callsign: callsign)
    let c = LC(r: brand.r, g: brand.g, b: brand.b)

    if AirlineLEDCache.prefersTextMark(callsign: callsign),
       let iata = AirlineLEDCache.iata(from: callsign) {
        buf.txt(iata, ox + 2, oy + (size - glyphH) / 2, c)
        return
    }

    guard let grid = AirlineLEDCache.cachedGrid(callsign: callsign, size: size) else {
        if let iata = AirlineLEDCache.iata(from: callsign) {
            buf.txt(iata, ox + 1, oy + (size - glyphH) / 2, c)
        }
        return
    }

    let offX = ox + (size - grid.cols) / 2
    let offY = oy + (size - grid.rows) / 2
    for row in 0..<grid.rows {
        for col in 0..<grid.cols where grid.lit[row * grid.cols + col] {
            buf.set(offX + col, offY + row, c)
        }
    }
}

// MARK: - Board layout (inspo: logo | airline · route · type · status)

private struct BoardLines {
    let airline: String
    let callsign: String
    let aircraft: String
    let status: String
    let place: String
}

private func boardLines(flight: Flight, route: RouteData?, maxChars: Int) -> BoardLines {
    let footer = FlightLEDCopy.boardFooter(flight: flight, route: route)
    func clip(_ s: String) -> String { String(s.prefix(maxChars)) }
    return BoardLines(
        airline: clip(airlineName(flight.callsign)),
        callsign: clip(FlightLEDCopy.displayCallsign(for: flight, maxLength: maxChars)),
        aircraft: clip(FlightLEDCopy.aircraftTypeShort(for: flight)),
        status: clip(footer.label),
        place: clip(footer.place)
    )
}

private struct BoardLayout {
    let gw: Int
    let gh: Int
    let pitch: CGFloat
    let logoSize: Int
    let logoQuarterW: Int
    let textQuarterW: Int
    let textColumnW: Int
    let planeColumnW: Int
    let planeColumnX: Int
    let maxChars: Int
}

private func boardLayout(size: CGSize, reservePlaneColumn: Bool) -> BoardLayout {
    let pitch: CGFloat = 2.5
    let gw = max(108, Int(size.width / pitch))
    let gh = max(52, Int(size.height / pitch))
    let logoQuarterW = gw / 4
    let textQuarterW = gw - logoQuarterW
    let textColumnW: Int
    let planeColumnW: Int
    let planeColumnX: Int
    if reservePlaneColumn {
        textColumnW = (textQuarterW * 11) / 20
        planeColumnW = max(18, textQuarterW - textColumnW - 3)
        planeColumnX = logoQuarterW + textColumnW + 2
    } else {
        textColumnW = textQuarterW
        planeColumnW = 0
        planeColumnX = gw
    }
    let logoSize = min(logoQuarterW - 6, gh - 12)
    let maxChars = max(9, (textColumnW - 4) / glyphW)
    return BoardLayout(
        gw: gw, gh: gh, pitch: pitch,
        logoSize: logoSize, logoQuarterW: logoQuarterW, textQuarterW: textQuarterW,
        textColumnW: textColumnW, planeColumnW: planeColumnW, planeColumnX: planeColumnX,
        maxChars: maxChars
    )
}

private func aircraftPlacement(for flight: Flight, layout: BoardLayout) -> AircraftPlacement? {
    guard layout.planeColumnW > 0,
          AircraftIcon.hasWidgetModel(for: flight.type),
          let asset = AircraftIcon.assetName(for: flight.type) else { return nil }
    let size = layout.logoSize
    let col = layout.planeColumnX + max(0, (layout.planeColumnW - size) / 2)
    let row = max(2, (layout.gh - size) / 2)
    return AircraftPlacement(asset: asset, col: col, row: row, size: size)
}

private struct BoardPlacement {
    let logoX: Int
    let logoY: Int
    let textX: Int
    let startY: Int
}

private func mediumPlacement(layout: BoardLayout) -> BoardPlacement {
    let blockH = rowStep * 4 + glyphH + sectionGap
    let startY = max(2, (layout.gh - blockH) / 2)
    let logoX = max(2, layout.logoQuarterW / 2 - layout.logoSize / 2)
    let logoY = max(2, (layout.gh - layout.logoSize) / 2)
    let textX = layout.logoQuarterW + 3
    return BoardPlacement(
        logoX: logoX,
        logoY: logoY,
        textX: textX,
        startY: startY
    )
}

/// LED grid locked to widget bounds; all glyphs stay inside the matrix.
func buildWall(flight: Flight?, route: RouteData?, size: CGSize) -> (LB, CGFloat, LogoPlacement?, AircraftPlacement?) {
    guard let f = flight else {
        let layout = boardLayout(size: size, reservePlaneColumn: false)
        let b = LB(layout.gw, layout.gh)
        let fitPitch = min(size.width / CGFloat(layout.gw), size.height / CGFloat(layout.gh))
        let y = (layout.gh - glyphH) / 2
        b.txt(b.fit("SCANNING", maxChars: 8), (layout.gw - 8 * glyphW) / 2, max(2, y - 5), .cy)
        b.txt(b.fit("AIRSPACE", maxChars: 8), (layout.gw - 8 * glyphW) / 2, y + 6, .wh)
        return (b, fitPitch, nil, nil)
    }

    let hasPlaneArt = AircraftIcon.hasWidgetModel(for: f.type)
    let layout = boardLayout(size: size, reservePlaneColumn: hasPlaneArt)
    let b = LB(layout.gw, layout.gh)
    let fitPitch = min(size.width / CGFloat(layout.gw), size.height / CGFloat(layout.gh))

    let lines = boardLines(flight: f, route: route, maxChars: layout.maxChars)
    let place = mediumPlacement(layout: layout)
    let logoY = place.logoY

    // Prefer the bundled brand logo; fall back to the LED-dot mark.
    let placement: LogoPlacement?
    if let asset = AirlineLogoAsset.assetName(forCallsign: f.callsign) {
        placement = LogoPlacement(asset: asset, col: place.logoX, row: logoY, size: layout.logoSize)
    } else {
        renderBrandLogo(b, callsign: f.callsign, ox: place.logoX, oy: logoY, size: layout.logoSize)
        placement = nil
    }

    let y0 = place.startY
    let y1 = y0 + rowStep
    let y2 = y1 + rowStep
    let y3 = y2 + rowStep + sectionGap
    let y4 = y3 + rowStep

    b.txt(lines.airline, place.textX, y0, .wh)
    b.txt(lines.callsign, place.textX, y1, brandLC(callsign: f.callsign))
    b.txt(lines.aircraft, place.textX, y2, .wh)
    b.txt(lines.status, place.textX, y3, statusLC(for: f))
    b.txt(lines.place, place.textX, y4, .wh)

    let plane = aircraftPlacement(for: f, layout: layout)
    return (b, fitPitch, placement, plane)
}

func buildSmall(flight: Flight?, route: RouteData?, size: CGSize) -> (LB, CGFloat, LogoPlacement?) {
    let pitch: CGFloat = 2.5
    let gw = max(48, Int(size.width / pitch))
    let gh = max(48, Int(size.height / pitch))
    let fitPitch = min(size.width / CGFloat(gw), size.height / CGFloat(gh))
    let b = LB(gw, gh)

    guard let f = flight else {
        let y = gh / 2
        b.txt("SCAN", (gw - 5 * glyphW) / 2, y - 8, .cy)
        b.txt("AIRSPACE", (gw - 8 * glyphW) / 2, y + 2, .wh)
        return (b, fitPitch, nil)
    }

    let logoSize = 18
    let airline = String(airlineName(f.callsign).prefix(9))
    let secondLine = FlightLEDCopy.routeLine(route) ?? FlightLEDCopy.displayCallsign(for: f)
    let secondColor: LC = FlightLEDCopy.routeLine(route) != nil ? .wh : brandLC(callsign: f.callsign)

    let blockW = max(logoSize, textWidth(airline), textWidth(secondLine)) + 6
    let blockH = logoSize + 4 + glyphH + 2 + glyphH
    let originX = max(2, (gw - blockW) / 2)
    let originY = max(2, (gh - blockH) / 2)
    let logoX = originX + (blockW - logoSize) / 2
    let textX = originX + 3

    let placement: LogoPlacement?
    if let asset = AirlineLogoAsset.assetName(forCallsign: f.callsign) {
        placement = LogoPlacement(asset: asset, col: logoX, row: originY, size: logoSize)
    } else {
        renderBrandLogo(b, callsign: f.callsign, ox: logoX, oy: originY, size: logoSize)
        placement = nil
    }

    var y = originY + logoSize + 4
    b.txt(airline, textX, y, .wh)
    y += glyphH + 2
    b.txt(secondLine, textX, y, secondColor)
    return (b, fitPitch, placement)
}

// MARK: - Canvas

struct LEDView: View {
    let buf: LB
    let pitch: CGFloat
    var logo: LogoPlacement? = nil
    var aircraft: AircraftPlacement? = nil

    var body: some View {
        Canvas { ctx, canvasSize in
            let dotR = pitch * 0.36
            let glowR = pitch * 0.72
            for row in 0..<buf.h {
                for col in 0..<buf.w {
                    let cx = CGFloat(col) * pitch + pitch * 0.5
                    let cy = CGFloat(row) * pitch + pitch * 0.5
                    let p = buf.px[row][col]
                    if p.on && p.c.r + p.c.g + p.c.b > 0.35 {
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: cx - glowR, y: cy - glowR, width: glowR * 2, height: glowR * 2)),
                            with: .color(p.c.glow))
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2)),
                            with: .color(p.c.color))
                    } else if p.on {
                        let d = pitch * 0.14
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: cx - d, y: cy - d, width: d * 2, height: d * 2)),
                            with: .color(Color(red: 0.06, green: 0.065, blue: 0.08)))
                    }
                }
            }

            // Bundled brand logo — aspect-fit inside reserved cells, no opaque black matte.
            if let logo, let ui = AirlineLogoAsset.preparedImage(named: logo.asset) {
                let rect = CGRect(x: CGFloat(logo.col) * pitch,
                                  y: CGFloat(logo.row) * pitch,
                                  width: CGFloat(logo.size) * pitch,
                                  height: CGFloat(logo.size) * pitch)
                let fit = CGRect.aspectFit(imageSize: ui.size, in: rect.insetBy(dx: pitch * 0.4, dy: pitch * 0.4))
                ctx.draw(ctx.resolve(Image(uiImage: ui)), in: fit)
            }

            if let aircraft, let ui = AircraftIcon.widgetModelImage(named: aircraft.asset) {
                let rect = CGRect(x: CGFloat(aircraft.col) * pitch,
                                  y: CGFloat(aircraft.row) * pitch,
                                  width: CGFloat(aircraft.size) * pitch,
                                  height: CGFloat(aircraft.size) * pitch)
                let fit = CGRect.aspectFit(imageSize: ui.size, in: rect.insetBy(dx: pitch * 0.15, dy: pitch * 0.15))
                // Bundled renders are authored nose-up (north). Draw without heading rotation.
                ctx.draw(ctx.resolve(Image(uiImage: ui)), in: fit)
            }
        }
        .frame(width: CGFloat(buf.w) * pitch, height: CGFloat(buf.h) * pitch)
    }
}

private struct BoardBezel: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color(red: 0.28, green: 0.28, blue: 0.30),
                        Color(red: 0.08, green: 0.08, blue: 0.10),
                        Color(red: 0.22, green: 0.22, blue: 0.24),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
    }
}

// MARK: - Widget views

struct FlightEntry: TimelineEntry {
    let date: Date
    let flight: Flight?
    let route: RouteData?
}

struct MediumWall: View {
    let entry: FlightEntry

    var body: some View {
        GeometryReader { geo in
            let (buf, pitch, logo, aircraft) = buildWall(flight: entry.flight, route: entry.route, size: geo.size)
            let ledW = CGFloat(buf.w) * pitch
            let ledH = CGFloat(buf.h) * pitch

            ZStack {
                Color(red: 0.018, green: 0.018, blue: 0.025)

                LEDView(buf: buf, pitch: pitch, logo: logo, aircraft: aircraft)
                    .frame(width: ledW, height: ledH)

                BoardBezel()
                    .frame(width: ledW + 8, height: ledH + 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .widgetURL(widgetDeepLink(for: entry.flight))
        .containerBackground(Color(red: 0.018, green: 0.018, blue: 0.025), for: .widget)
    }
}

private func widgetDeepLink(for flight: Flight?) -> URL? {
    guard let flight else { return nil }
    return FlightDeepLink.url(icao24: flight.icao24)
}

struct SmallWall: View {
    let entry: FlightEntry

    var body: some View {
        GeometryReader { geo in
            let (buf, pitch, logo) = buildSmall(flight: entry.flight, route: entry.route, size: geo.size)
            let ledW = CGFloat(buf.w) * pitch
            let ledH = CGFloat(buf.h) * pitch

            ZStack {
                Color(red: 0.018, green: 0.018, blue: 0.025)
                LEDView(buf: buf, pitch: pitch, logo: logo)
                    .frame(width: ledW, height: ledH)
                BoardBezel()
                    .frame(width: ledW + 6, height: ledH + 6)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .widgetURL(widgetDeepLink(for: entry.flight))
        .containerBackground(Color(red: 0.018, green: 0.018, blue: 0.025), for: .widget)
    }
}

struct WidgetBoardView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FlightEntry

    var body: some View {
        switch family {
        case .systemMedium: MediumWall(entry: entry)
        default: SmallWall(entry: entry)
        }
    }
}

struct FlightTrackerWidget: Widget {
    let kind = WidgetBoardStore.kind
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlightTimelineProvider()) { entry in
            WidgetBoardView(entry: entry)
        }
        .configurationDisplayName("Overhead Board")
        .description("Nearest commercial flight · LED airline logo")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FlightTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlightEntry {
        cachedEntry(maxAge: WidgetBoardStore.maxFallbackAge)
            ?? FlightEntry(date: Date(), flight: nil, route: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (FlightEntry) -> Void) {
        completion(
            cachedEntry(maxAge: WidgetBoardStore.maxFallbackAge)
                ?? FlightEntry(date: Date(), flight: nil, route: nil)
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlightEntry>) -> Void) {
        Task {
            let (entry, reloadAfter) = await Self.loadBoard()
            completion(Timeline(
                entries: [entry],
                policy: .after(Date().addingTimeInterval(reloadAfter))
            ))
        }
    }

    private func cachedEntry(maxAge: TimeInterval) -> FlightEntry? {
        guard let snap = WidgetBoardStore.load(maxAge: maxAge) else { return nil }
        return FlightEntry(date: Date(), flight: snap.flight, route: snap.route)
    }

    /// WidgetKit kills slow timeline work. Return a plane first; route/logo are optional extras.
    private static func loadBoard() async -> (FlightEntry, TimeInterval) {
        let cached = WidgetBoardStore.load()
        let retrySoon: TimeInterval = 90
        let retryEmpty: TimeInterval = 180
        let refreshLive: TimeInterval = 300

        func fallback(_ interval: TimeInterval) -> (FlightEntry, TimeInterval) {
            if let cached, Date().timeIntervalSince(cached.savedAt) <= WidgetBoardStore.maxFallbackAge {
                return (FlightEntry(date: Date(), flight: cached.flight, route: cached.route), interval)
            }
            return (FlightEntry(date: Date(), flight: nil, route: nil), interval)
        }

        guard let coord = await WidgetLocationFetcher.coordinate() else {
            return fallback(retrySoon)
        }

        let result = await NearbyFlightsFetcher.fetch(
            latitude: coord.latitude,
            longitude: coord.longitude,
            radiusKm: 50,
            timeout: 8
        )

        switch result {
        case .unavailable:
            return fallback(120)

        case .noAircraftNearby:
            WidgetBoardStore.save(flight: nil, route: nil, near: coord)
            return (FlightEntry(date: Date(), flight: nil, route: nil), retryEmpty)

        case .flights(let all):
            let nearest = CommercialFlightFilter.nearest(to: coord, from: all)
            let flight = WidgetFlightCache.resolve(nearest: nearest, from: all, near: coord)
            var route: RouteData?
            if let flight {
                if cached?.flight?.icao24 == flight.icao24 {
                    route = cached?.route
                }
                if knownRouteEnds(route) == nil {
                    if let lookedUp = await AsyncTimeout.value(seconds: 2.5, operation: {
                        await lookupRoute(flight)
                    }) {
                        route = lookedUp ?? route
                    }
                }
                if AirlineLogoAsset.assetName(forCallsign: flight.callsign) == nil,
                   AirlineLEDCache.cachedGrid(callsign: flight.callsign) == nil {
                    await AsyncTimeout.value(seconds: 1.0, operation: {
                        await AirlineLEDCache.prefetch(callsign: flight.callsign)
                    })
                }
            }
            WidgetBoardStore.save(flight: flight, route: route, near: coord)
            return (
                FlightEntry(date: Date(), flight: flight, route: route),
                flight == nil ? retryEmpty : refreshLive
            )
        }
    }

    private static func lookupRoute(_ flight: Flight) async -> RouteData? {
        guard let airports = await RouteLookupService.fetch(
            icao24: flight.icao24,
            callsign: flight.callsign
        ) else { return nil }
        let d = displayAP(airports.departure).code
        let a = displayAP(airports.arrival).code
        guard isKnownAirportCode(d), isKnownAirportCode(a) else { return nil }
        return RouteData(dep: d, arr: a)
    }
}

#Preview(as: .systemMedium) {
    FlightTrackerWidget()
} timeline: {
    FlightEntry(date: .now, flight: nil, route: nil)
}
