import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - 5×7 LED bitmap font
let FONT: [Character:[UInt8]] = [
    " ":[0,0,0,0,0,0,0],
    "A":[14,17,17,31,17,17,17],"B":[30,17,17,30,17,17,30],
    "C":[14,17,16,16,16,17,14],"D":[28,18,17,17,17,18,28],
    "E":[31,16,16,30,16,16,31],"F":[31,16,16,30,16,16,16],
    "G":[14,17,16,23,17,17,14],"H":[17,17,17,31,17,17,17],
    "I":[14,4,4,4,4,4,14],    "J":[7,2,2,2,2,18,12],
    "K":[17,18,20,24,20,18,17],"L":[16,16,16,16,16,16,31],
    "M":[17,27,21,21,17,17,17],"N":[17,25,21,19,17,17,17],
    "O":[14,17,17,17,17,17,14],"P":[30,17,17,30,16,16,16],
    "Q":[14,17,17,17,21,18,13],"R":[30,17,17,30,20,18,17],
    "S":[15,16,16,14,1,1,30], "T":[31,4,4,4,4,4,4],
    "U":[17,17,17,17,17,17,14],"V":[17,17,17,17,10,10,4],
    "W":[17,17,17,21,21,27,17],"X":[17,17,10,4,10,17,17],
    "Y":[17,17,10,4,4,4,4],   "Z":[31,1,2,4,8,16,31],
    "0":[14,17,19,21,25,17,14],"1":[4,12,4,4,4,4,14],
    "2":[14,17,1,2,4,8,31],   "3":[31,2,4,2,1,17,14],
    "4":[2,6,10,18,31,2,2],   "5":[31,16,30,1,1,17,14],
    "6":[6,8,16,30,17,17,14], "7":[31,1,2,4,8,8,8],
    "8":[14,17,17,14,17,17,14],"9":[14,17,17,15,1,2,12],
    ".":[0,0,0,0,0,4,4],      ":":[0,4,4,0,4,4,0],
    "-":[0,0,0,31,0,0,0],     "/":[1,2,4,8,16,0,0],
    ",":[0,0,0,0,4,4,8],
]

// MARK: - Colors
enum C {
    static let navy    = Color(red:0.04,green:0.06,blue:0.10)
    static let panelBg = Color(red:0.09,green:0.14,blue:0.19)
    static let blue    = Color(red:0.10,green:0.26,blue:1.00)
    static let ledBlue = Color(red:0.45,green:0.72,blue:0.92)
    static let coral   = Color(red:0.92,green:0.28,blue:0.28)
    static let cyan    = Color(red:0.38,green:0.80,blue:0.96)
    static let sep     = Color.white.opacity(0.12)
    static let t1      = Color.white
    static let t2      = Color.white.opacity(0.50)
    static let t3      = Color.white.opacity(0.24)
    static let climb   = Color(red: 0.38, green: 0.82, blue: 0.58)
}

/// Consistent LED dot sizes across the app.
enum LEDSize {
    static let boardTitle: CGFloat = 3.0
    static let boardHeader: CGFloat = 2.1
    static let boardCallsign: CGFloat = 2.0
    static let scanChip: CGFloat = 1.9
    static let cardCallsign: CGFloat = 6.5
    static let specLabel: CGFloat = 2.2
}

/// Shared top chrome spacing for all glass cards.
enum CardChrome {
    static let topPadding: CGFloat = 8
    static let dashHeight: CGFloat = 4
    /// Gap between grabber dash and the first row of card content.
    static let grabberToContent: CGFloat = 22
    /// Quick + detail cards — modest gap below the dash.
    static let grabberToContentCompact: CGFloat = 12
    /// List title row — 4pt lower than the default.
    static let listTitleTopGap: CGFloat = 26
    static let closeDiameter: CGFloat = 32
    /// Inset from the card's top-trailing corner — follows the border curve.
    static let closeBorderInset: CGFloat = 8
    /// Keeps buttons / last rows above the card's bottom edge (inside the glass).
    static let sheetContentBottomInset: CGFloat = 8
    /// Clears the top squircle clip so the grabber / heading aren't cut off.
    static let sheetContentTopInset: CGFloat = 6
    /// Horizontal inset of the swipe footer — matches quick-card content padding (20pt).
    static let detailFooterInsetFromCard: CGFloat = 20
    /// Gap above and below the swipe pill (divider → pill → card bottom).
    static let detailFooterVerticalGap: CGFloat = 12
}

/// Shared insets for floating glass popups (used in concentric radius math).
enum CardLayout {
    /// Horizontal gap from the display edge — also used in [screen radius − padding].
    static let screenMargin: CGFloat = 10
    /// Small gap between the card bottom curve and the physical screen edge.
    static let bottomMargin: CGFloat = 6
}

/// Border-aligned dismiss control — glass circle tucked into the card corner.
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color.white)
                .frame(width: CardChrome.closeDiameter, height: CardChrome.closeDiameter)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .accessibilityLabel("Close")
    }
}

/// Grab handle + optional close. Content gap is applied by each card below this view.
struct CardGrabber: View {
    var onClose: (() -> Void)? = nil
    var onDragDismiss: (() -> Void)? = nil
    @Binding var dragOffset: CGFloat

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                let shouldDismiss = value.translation.height > 56
                    || value.predictedEndTranslation.height > 110
                if shouldDismiss, let onDragDismiss {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                        dragOffset = 0
                        onDragDismiss()
                    }
                } else {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private var dashRowHeight: CGFloat {
        CardChrome.topPadding + CardChrome.dashHeight
    }

    var body: some View {
        Color.clear
            .frame(height: dashRowHeight)
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .fill(C.t3)
                    .frame(width: 36, height: CardChrome.dashHeight)
                    .padding(.top, CardChrome.topPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .contentShape(Rectangle())
                    .gesture(dragGesture)
            }
            .overlay(alignment: .topTrailing) {
                if let onClose {
                    CloseButton(action: onClose)
                        .padding(.top, CardChrome.closeBorderInset)
                        .padding(.trailing, CardChrome.closeBorderInset)
                }
            }
            .accessibilityAction(named: "Dismiss") {
                onDragDismiss?()
            }
    }
}

// MARK: - LED Dot-Matrix Label
// FitLED: self-sizing — fits ANY width by scaling dotPt down automatically.
// Use this everywhere so text NEVER overflows on any device.
struct LEDLabel: View {
    let text:String; let dotPt:CGFloat; let color:Color; let dimmed:Bool; let topAligned:Bool
    init(_ t:String, dotPt:CGFloat, color:Color = .white, dimmed:Bool = true, topAligned:Bool = false) {
        text=t; self.dotPt=dotPt; self.color=color; self.dimmed=dimmed; self.topAligned=topAligned
    }
    var body: some View {
        // GeometryReader measures available width, scales dotPt so text always fits
        GeometryReader { geo in
            let chars   = max(1, text.count)
            let maxFit  = geo.size.width / CGFloat(chars * 6)
            let pt      = min(dotPt, maxFit)            // never exceed available space
            let h       = 7 * pt
            let yOff    = topAligned ? 0 : (geo.size.height - h) / 2
            Canvas { ctx, _ in
                let r = pt * 0.38
                var cx: CGFloat = 0
                for ch in text {
                    let g = FONT[ch] ?? FONT[Character(ch.uppercased())] ?? [0,0,0,0,0,0,0]
                    for row in 0..<7 {
                        for col in 0..<5 {
                            let x = cx + CGFloat(col)*pt + r
                            let y = yOff + CGFloat(row)*pt + r
                            if g[row] & (1<<(4-col)) != 0 {
                                ctx.fill(Path(ellipseIn:CGRect(x:x-r,y:y-r,width:r*2,height:r*2)),
                                         with:.color(color))
                            } else if dimmed {
                                let d = r * 0.52
                                ctx.fill(Path(ellipseIn:CGRect(x:x-d,y:y-d,width:d*2,height:d*2)),
                                         with:.color(color.opacity(0.07)))
                            }
                        }
                    }
                    cx += pt * 6
                }
            }
            .shadow(color:color.opacity(0.45), radius:pt*0.55)
        }
        .frame(height: 7 * dotPt)   // height from max dotPt; actual render scales to fit
    }
}

func airlineICAO(_ callsign: String) -> String {
    String(callsign.prefix(3)).uppercased()
}

/// Best available flight identifier for LED / list display.
func displayCallsign(for flight: Flight, maxLength: Int = 6) -> String {
    let trimmed = flight.callsign.trimmingCharacters(in: .whitespaces).uppercased()
    if !trimmed.isEmpty { return String(trimmed.prefix(maxLength)) }
    let reg = flight.registration.trimmingCharacters(in: .whitespaces).uppercased()
    if !reg.isEmpty { return String(reg.prefix(maxLength)) }
    let icao = flight.icao24.trimmingCharacters(in: .whitespaces).uppercased()
    if !icao.isEmpty { return String(icao.prefix(maxLength)) }
    return "N/A"
}

func airlineLEDColor(_ callsign: String) -> Color {
    let rgb = AirlineLEDCache.accessibleBrandRGB(callsign: callsign)
    return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
}

func seedAeroInfo(from flight: Flight) -> AeroInfo {
    var info = AeroInfo()
    info.reg = flight.registration.uppercased()
    info.icaoType = flight.type.uppercased()
    if let s = AIRCRAFT_DB[info.icaoType] {
        if info.typeName.isEmpty { info.typeName = s.name }
        info.wing = s.wing
        info.range = s.range
        info.speed = s.speed
        info.cat = s.cat
    }
    return info
}

// MARK: - AeroDataBox service
struct AeroInfo {
    var reg=""; var typeName=""; var icaoType=""
    var seats:Int?; var engines:Int?; var firstFlight:String?
    var wing:String?; var range:String?; var speed:String?; var cat:String?
}
// Aircraft fetch state — lets UI distinguish loading vs done-but-empty
enum AcState { case loading, done }

@MainActor class AircraftService: ObservableObject {
    @Published var data:  [String: AeroInfo]  = [:]   // nil = not started
    @Published var state: [String: AcState]   = [:]   // nil = not started

    func fetch(_ flight: Flight) {
        let id = flight.icao24
        if state[id] == .done { return }

        // Show local + ADS-B data immediately (no blank sheet while API runs).
        data[id] = seedAeroInfo(from: flight)
        state[id] = .loading

        Task {
            var info = data[id] ?? seedAeroInfo(from: flight)

            if !APIConfiguration.aeroDataBoxKey.isEmpty {
                var req = URLRequest(
                    url: URL(string: "https://aerodatabox.p.rapidapi.com/aircrafts/icao24/\(id.lowercased())")!,
                    timeoutInterval: 6)
                req.setValue(APIConfiguration.aeroDataBoxKey, forHTTPHeaderField: "X-RapidAPI-Key")
                req.setValue("aerodatabox.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
                if let (d, resp) = try? await URLSession.shared.data(for: req),
                   (resp as? HTTPURLResponse)?.statusCode == 200,
                   let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
                    let reg  = (j["registration"] as? String ?? "").uppercased()
                    let tn   = (j["typeName"]     as? String ?? "").uppercased()
                    let it   = (j["icaoTypeCode"] as? String ?? "").uppercased()
                    if !reg.isEmpty { info.reg = reg }
                    if !tn.isEmpty  { info.typeName = tn }
                    if !it.isEmpty  { info.icaoType = it }
                    info.seats       = j["numberSeats"]      as? Int
                    info.engines     = j["numberEngines"]    as? Int
                    info.firstFlight = (j["firstFlightDate"] as? String ?? "").uppercased()
                }
            }
            if let s = AIRCRAFT_DB[info.icaoType] {
                if info.typeName.isEmpty { info.typeName = s.name }
                info.wing  = s.wing
                info.range = s.range
                info.speed = s.speed
                info.cat   = s.cat
            }
            data[id]  = info
            state[id] = .done
        }
    }
}

// MARK: - Pulsing ring (onAppear-driven, iOS 15+ compatible)
struct PulsingRing:View {
    @State private var big=false
    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.06)).frame(width:big ? 50:34,height:big ? 50:34)
            Circle().stroke(Color.white.opacity(0.20),lineWidth:0.8).frame(width:big ? 50:34,height:big ? 50:34)
        }
        .animation(.easeInOut(duration:1.05).repeatForever(autoreverses:true),value:big)
        .onAppear { big=true }
    }
}

// MARK: - Image padding trim

private extension UIImage {
    /// Crops fully/near-transparent margins so the opaque artwork fills the
    /// result. Lets icons with different amounts of built-in padding all scale
    /// to the same on-screen size.
    func trimmingTransparentBorder(alphaThreshold: UInt8 = 12) -> UIImage {
        guard let cg = cgImage, cg.width > 0, cg.height > 0 else { return self }
        let w = cg.width, h = cg.height
        let bytesPerRow = w * 4
        var data = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &data, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return self }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        var minX = w, minY = h, maxX = -1, maxY = -1
        for y in 0..<h {
            let row = y * bytesPerRow
            for x in 0..<w where data[row + x * 4 + 3] > alphaThreshold {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
        guard maxX >= minX, maxY >= minY,
              let cropped = cg.cropping(to: CGRect(x: minX, y: minY,
                                                   width: maxX - minX + 1,
                                                   height: maxY - minY + 1))
        else { return self }
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
    }
}

// MARK: - Plane pin (clean white icon)
struct FlightPin:View {
    let flight:Flight; let selected:Bool
    var body: some View {
        Group {
            if let asset = AircraftIcon.assetName(for: flight.type),
               let ui = UIImage(named: asset) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(width: selected ? 34 : 26, height: selected ? 34 : 26)
                    // Asset icons are drawn nose-up (north = 0°): rotate by heading directly.
                    .rotationEffect(.degrees(flight.heading))
            } else {
                Image(uiImage: AircraftIcon.genericOutlinedPinImage(
                    tint: AircraftIcon.mapPinUIColor(for: flight.type)))
                    .resizable()
                    .scaledToFit()
                    .frame(width: selected ? 34 : 26, height: selected ? 34 : 26)
                    .rotationEffect(.degrees(flight.heading))
            }
        }
        .shadow(color: Color.black.opacity(selected ? 0.55 : 0.35),
                radius: selected ? 6 : 3)
        .animation(.spring(response:0.3,dampingFraction:0.72),value:selected)
    }
}

// MARK: - Reusable glass panel background
struct GlassBg: View {
    var radius: CGFloat = 32

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            }
    }
}

/// Nested control fill — avoids stacking a second material layer on glass cards.
struct GlassInsetFill: View {
    var radius: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color.white.opacity(0.07))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            }
    }
}

extension View {
    func glassCard(radius: CGFloat = 32) -> some View {
        background { GlassBg(radius: radius) }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func cardDragFade(_ offset: CGFloat) -> some View {
        opacity(1 - min(offset / 280, 0.22))
    }
}

/// Apple-style circular dismiss control — deprecated alias; use CloseButton.
typealias GlassCloseButton = CloseButton

/// Toolbar icon — pure white, no background or border.
struct GlassIconButton: View {
    let systemName: String
    let action: () -> Void
    var accessibilityLabel: String = ""

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color.white)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel.isEmpty ? systemName : accessibilityLabel)
    }
}

/// Capsule glass bar (bottom map controls).
struct GlassCapsule: View {
    var body: some View {
        Capsule().fill(.ultraThinMaterial)
    }
}

// MARK: - Detail CTA footer — inset pill with concentric corners
struct DetailAnimButton: View {
    let onDetails: () -> Void
    @State private var flying = false

    private let insetFromCard = CardChrome.detailFooterInsetFromCard
    private let minTapHeight: CGFloat = 54
    private let hPad: CGFloat = 24
    private let iconSize: CGFloat = 18
    private let iconHalf: CGFloat = 11
    /// Matches the plane's spring so details open as it arrives on the right.
    private let flightDuration: TimeInterval = 0.55

    @available(iOS 16.0, *)
    private var footerShape: UnevenRoundedRectangle {
        CardCornerMetrics.detailFooterShape(insetFromCard: insetFromCard)
    }

    var body: some View {
        Button(action: playFlightThenOpen) {
            ZStack {
                Text("See Airplane Details")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(C.t1)
                    .frame(maxWidth: .infinity)
                    .opacity(flying ? 0 : 1)
                    .animation(.easeInOut(duration: 0.13), value: flying)
            }
            .overlay {
                GeometryReader { geo in
                    let startX = hPad + iconHalf
                    let endX = geo.size.width - hPad - iconHalf
                    Image(systemName: "airplane")
                        .font(.system(size: iconSize, weight: .medium))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(AircraftIcon.mapPinColor(for: ""))
                        .position(
                            x: flying ? endX : startX,
                            y: geo.size.height / 2
                        )
                        .animation(
                            .spring(response: flightDuration, dampingFraction: 0.7),
                            value: flying
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: minTapHeight)
            .background {
                if #available(iOS 16.0, *) {
                    footerShape
                        .fill(Color.white.opacity(0.07))
                        .overlay {
                            footerShape.stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        }
                } else {
                    GlassInsetFill(radius: 12)
                }
            }
            .modifier(DetailFooterClipModifier(insetFromCard: insetFromCard))
        }
        .buttonStyle(.plain)
        .disabled(flying)
        .accessibilityLabel("See Airplane Details")
    }

    private func playFlightThenOpen() {
        flying = true
        Task { @MainActor in
            let nanos = UInt64(flightDuration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            onDetails()
        }
    }
}

private struct DetailFooterClipModifier: ViewModifier {
    let insetFromCard: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            let shape = CardCornerMetrics.detailFooterShape(insetFromCard: insetFromCard)
            content
                .clipShape(shape)
                .contentShape(shape)
        } else {
            content
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Quick Card (exact match Image 1)
struct QuickCard: View {
    let flight: Flight
    let onDismiss: () -> Void
    let onDetails: () -> Void

    @State private var dragOffset: CGFloat = 0

    var cs: String { displayCallsign(for: flight) }

    var body: some View {
        VStack(spacing: 0) {
            CardGrabber(onClose: onDismiss, onDragDismiss: onDismiss, dragOffset: $dragOffset)

            // ── Callsign in LED ──
            LEDLabel(cs, dotPt: LEDSize.cardCallsign, dimmed: false, topAligned: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
                .padding(.trailing, 56)
                .padding(.top, CardChrome.grabberToContentCompact)
                .padding(.bottom, 14)
                .accessibilityLabel("Flight \(cs)")

            div

            // ── Airline ──
            HStack {
                Text(airlineName(flight.callsign))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(C.coral)
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 10)

            div

            // ── Live flight data rows ──
            qRow("ALTITUDE", "\(max(0,flight.altitudeInFeet)) FT")
            qRow("SPEED",    "\(flight.velocityInKnots) KT")
            qRow("HEADING",  "\(Int(flight.heading))° \(flight.headingDirection)")
            qRow("STATUS", flight.phase.displayName,
                 valueColor: boardStatusColor(flight.phase))

            div

            // ── CTA footer: equal gap above and below the pill ──
            DetailAnimButton(onDetails: onDetails)
                .padding(.horizontal, CardChrome.detailFooterInsetFromCard)
                .padding(.top, CardChrome.detailFooterVerticalGap)
                .padding(.bottom, CardChrome.detailFooterVerticalGap)
                .safeAreaPadding(.bottom)
        }
        .frame(maxWidth: .infinity)
        .glassPopupCard(anchorsFooter: true)
        .offset(y: dragOffset)
        .cardDragFade(dragOffset)
    }

    var div: some View {
        Rectangle().fill(C.sep).frame(height:0.5).padding(.horizontal,20)
    }

    func qRow(_ label: String, _ value: String, valueColor: Color = C.t1) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(C.t2)
                .textCase(.uppercase)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 20).padding(.vertical, 9)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }
}

// MARK: - Spec row (Image 2: blue LED label LEFT, white value RIGHT)
// Pulsing placeholder while AeroDataBox enrichment runs
struct SpecRowSkeleton: View {
    let label: String
    @State private var pulse = false
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(C.t2)
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(pulse ? 0.14 : 0.06))
                    .frame(width: 88, height: 12)
            }
            .padding(.vertical, 15)
            Rectangle().fill(C.sep).frame(height: 0.5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

struct SpecRow: View {
    let label: String
    let value: String
    var showsDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                LEDLabel(label, dotPt: LEDSize.specLabel, color: C.ledBlue)
                Spacer(minLength: 6)
                Text(value)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(C.t1)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 15)
            if showsDivider {
                Rectangle().fill(C.sep).frame(height: 0.5)
            }
        }
    }
}

// MARK: - Flight Detail View — aircraft build info (Image 2 style)
// Shows: airline header + TYPE, REGISTRATION, CAPACITY, WINGSPAN etc.
// Does NOT show speed/altitude (those are in the quick card)
struct FlightDetailView: View {
    let flight: Flight
    let route: RouteData?
    @ObservedObject var aircraft: AircraftService
    let onDismiss: () -> Void
    var maxScrollHeight: CGFloat = 420

    @State private var dragOffset: CGFloat = 0

    var airline: String { airlineName(flight.callsign) }
    var info: AeroInfo { aircraft.data[flight.icao24] ?? seedAeroInfo(from: flight) }
    var enriching: Bool { aircraft.state[flight.icao24] == .loading }

    var body: some View {
        VStack(spacing: 0) {
            CardGrabber(onClose: onDismiss, onDragDismiss: onDismiss, dragOffset: $dragOffset)

            HStack(spacing: 14) {
                AirlineLogoView(callsign: flight.callsign, size: 56)
                    .accessibilityLabel("\(airline) logo")
                VStack(alignment: .leading, spacing: 4) {
                    Text(airline)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(C.t1)
                    if enriching {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.65).tint(C.ledBlue)
                            Text("Loading more specs…")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(C.t2)
                        }
                    }
                }
                Spacer()
            }
            .padding(.leading, 20)
            .padding(.trailing, 56)
            .padding(.top, CardChrome.grabberToContentCompact)
            .padding(.bottom, 14)

            Rectangle().fill(C.sep).frame(height: 0.5).padding(.horizontal, 20)

            specsBody
        }
        .frame(maxWidth: .infinity)
        .glassPopupCard()
        .offset(y: dragOffset)
        .cardDragFade(dragOffset)
        .onAppear { aircraft.fetch(flight) }
    }

    @ViewBuilder
    private var specsBody: some View {
        let rows = specEntries
        if rows.count > 7 {
            ScrollView(showsIndicators: false) {
                specRowsView(rows)
            }
            .frame(maxHeight: maxScrollHeight)
        } else {
            specRowsView(rows)
        }
    }

    private func specRowsView(_ rows: [(label: String, value: String)]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                SpecRow(
                    label: row.label,
                    value: row.value,
                    showsDivider: index < rows.count - 1
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var specEntries: [(label: String, value: String)] {
        var rows: [(String, String)] = []
        let typeValue = !info.typeName.isEmpty ? info.typeName : info.icaoType
        if !typeValue.isEmpty { rows.append(("Type", typeValue)) }
        if !info.reg.isEmpty { rows.append(("Registration", info.reg)) }
        if let v = info.firstFlight, !v.isEmpty { rows.append(("First Flight", v)) }
        if let n = info.seats { rows.append(("Capacity", "\(n) passengers")) }
        if let n = info.engines { rows.append(("Engines", "\(n) engines")) }
        if let v = info.wing { rows.append(("Wingspan", v)) }
        if let v = info.range { rows.append(("Range", v)) }
        if let v = info.speed { rows.append(("Max Speed", v)) }
        if let v = info.cat { rows.append(("Category", v)) }

        if enriching {
            if info.seats == nil { rows.append(("Capacity", "…")) }
            if info.engines == nil { rows.append(("Engines", "…")) }
            if info.firstFlight == nil || info.firstFlight?.isEmpty == true {
                rows.append(("First Flight", "…"))
            }
        }

        if rows.isEmpty && !enriching {
            rows.append(("Callsign", flight.callsign.uppercased()))
            rows.append(("ICAO 24", flight.icao24.uppercased()))
        }
        return rows
    }
}

// MARK: - Split-flap tile + row (board list)
struct FlapTile:View {
    let ch:Character; let sz:CGFloat; let delay:Double
    @State private var on=false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius:3).fill(Color(red:0.09,green:0.12,blue:0.16))
                .overlay(alignment:.center){ Rectangle().fill(Color.black.opacity(0.4)).frame(height:0.7) }
                .overlay{ RoundedRectangle(cornerRadius:3).stroke(C.sep.opacity(0.5),lineWidth:0.4) }
            Text(String(ch)).font(.system(size:sz,weight:.bold,design:.monospaced))
                .foregroundColor(on ? .white:.clear)
                .rotation3DEffect(.degrees(on ? 0:-80),axis:(x:1,y:0,z:0),anchor:.bottom,perspective:0.7)
        }
        .frame(width:sz*0.82,height:sz*1.35)
        .onAppear { withAnimation(.spring(response:0.22,dampingFraction:0.55).delay(delay)){ on=true } }
    }
}
struct FlapRow:View {
    let text:String; let sz:CGFloat; let t0:Double
    var body: some View {
        HStack(spacing:2){
            ForEach(Array(text.enumerated()),id:\.offset){ i,c in
                FlapTile(ch:c,sz:sz,delay:t0+Double(i)*0.016)
            }
        }
    }
}

/// Compact glass control for the flights board toolbar (inline with title).
struct BoardRefreshButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 15, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color.white)
                .frame(width: 34, height: 34)
                .background { GlassInsetFill(radius: 10) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Refresh flights")
    }
}

func boardStatusColor(_ phase: FlightPhase) -> Color {
    switch phase {
    case .takingOff: return C.climb
    case .landing: return C.coral
    case .onLand: return C.t2
    case .cruise: return C.t1
    }
}

// MARK: - Board Overlay (map always visible above)
struct BoardOverlay: View {
    let flights: [Flight]
    let routes: [String: RouteData]
    let onClose: () -> Void
    let onRefresh: () -> Void
    let onDetail: (Flight) -> Void
    var maxListHeight: CGFloat = 420

    @State private var dragOffset: CGFloat = 0

    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 52

    private let hPad: CGFloat = 20
    private let altColWidth: CGFloat = 52
    private let statusColWidth: CGFloat = 76
    private let actionColWidth: CGFloat = 48

    var body: some View {
        VStack(spacing: 0) {
            CardGrabber(onDragDismiss: onClose, dragOffset: $dragOffset)

            toolbar
                .padding(.top, CardChrome.listTitleTopGap)

            boardHeader
            boardDivider

            flightList
        }
        .glassPopupCard()
        .offset(y: dragOffset)
        .cardDragFade(dragOffset)
    }

    private var toolbar: some View {
        HStack(alignment: .center, spacing: 12) {
            LEDLabel("FLIGHTS", dotPt: LEDSize.boardTitle, color: .white, dimmed: false)
                .frame(height: 7 * LEDSize.boardTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Flights")

            BoardRefreshButton(action: onRefresh)
        }
        .padding(.horizontal, hPad)
        .padding(.bottom, 4)
    }

    private var boardHeader: some View {
        boardGridRow(
            flight: headerCell("FLIGHT", width: nil, align: .leading),
            alt: headerCell("ALT", width: altColWidth, align: .leading),
            status: headerCell("STATUS", width: statusColWidth, align: .leading),
            action: Color.clear.frame(width: actionColWidth, height: 1)
        )
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Column headers: flight, altitude, status")
    }

    @ViewBuilder
    private var flightList: some View {
        if flights.isEmpty {
            Text("No flights nearby")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(C.t2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, hPad)
                .padding(.vertical, 24)
                .accessibilityLabel("No flights nearby")
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(flights.enumerated()), id: \.element.id) { i, f in
                        boardRow(f, index: i)
                        if i < flights.count - 1 {
                            boardDivider
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .frame(maxHeight: flights.count > 8 ? maxListHeight : nil)
            .padding(.bottom, 12)
        }
    }

    private var boardDivider: some View {
        Rectangle()
            .fill(C.sep)
            .frame(height: 0.5)
            .padding(.horizontal, hPad)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func headerCell(_ title: String, width: CGFloat?, align: Alignment) -> some View {
        let label = Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(C.t2)
            .textCase(.uppercase)
            .lineLimit(1)
            .accessibilityHidden(true)

        if let width {
            label.frame(width: width, alignment: align)
        } else {
            label.frame(maxWidth: .infinity, alignment: align)
        }
    }

    private func boardGridRow(
        flight: some View,
        alt: some View,
        status: some View,
        action: some View
    ) -> some View {
        HStack(spacing: 8) {
            flight
                .frame(maxWidth: .infinity, alignment: .leading)
            alt
                .frame(width: altColWidth, alignment: .leading)
            status
                .frame(width: statusColWidth, alignment: .leading)
            action
                .frame(width: actionColWidth, alignment: .center)
        }
        .padding(.horizontal, hPad)
    }

    private func boardRow(_ f: Flight, index i: Int) -> some View {
        let statusColor = boardStatusColor(f.phase)
        let statusShort = f.phase.compactName
        let altStr = "\(max(1, f.altitudeInFeet / 1000))K"
        let callsign = displayCallsign(for: f, maxLength: 12)
        let displayCallsign = callsign == "N/A" ? "—" : callsign

        return Button(action: { onDetail(f) }) {
            boardGridRow(
                flight: LEDLabel(displayCallsign, dotPt: LEDSize.boardCallsign, color: C.ledBlue, dimmed: false)
                    .frame(height: 7 * LEDSize.boardCallsign),
                alt: Text(altStr)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(C.t1)
                    .lineLimit(1)
                    .frame(width: altColWidth, alignment: .leading),
                status: Text(statusShort)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: statusColWidth, alignment: .leading),
                action: Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(Color.white)
                    .frame(width: actionColWidth, height: 20)
                    .accessibilityHidden(true)
            )
            .frame(minHeight: rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(boardRowAccessibilityLabel(flight: f, altFeet: f.altitudeInFeet, status: f.phase.displayName))
        .accessibilityHint("Opens flight details")
    }

    private func boardRowAccessibilityLabel(flight f: Flight, altFeet: Int, status: String) -> String {
        let cs = f.callsign.trimmingCharacters(in: .whitespaces)
        let airline = airlineName(f.callsign)
        return "\(airline), flight \(cs), \(altFeet) feet, \(status)"
    }
}


// MARK: - FlightAnnotation

/// Expands the tap target to at least 44 pt without changing the drawn icon size.
private final class FlightPinAnnotationView: MKAnnotationView {
    private static let minHitSize: CGFloat = 44

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let hit = bounds.insetBy(
            dx: -max(0, (Self.minHitSize - bounds.width) / 2),
            dy: -max(0, (Self.minHitSize - bounds.height) / 2)
        )
        return hit.contains(point)
    }
}

final class FlightAnnotation: NSObject, MKAnnotation {
    var flight: Flight
    @objc dynamic var coordinate: CLLocationCoordinate2D
    init(_ f: Flight) {
        flight = f
        coordinate = CLLocationCoordinate2D(latitude: f.latitude, longitude: f.longitude)
    }
}

// MARK: - LiveMap (UIViewRepresentable for native animated zoom)
struct LiveMap: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let flights: [Flight]
    let selectedId: String?
    let onSelect: (Flight) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let m = MKMapView()
        m.delegate = context.coordinator
        m.showsUserLocation = true
        Self.applyMapAppearance(m)
        m.setRegion(region, animated: false)
        return m
    }

    func updateUIView(_ m: MKMapView, context: Context) {
        Self.applyMapAppearance(m)
        let eps = 0.0005
        let cur = m.region
        if abs(cur.center.latitude  - region.center.latitude)  > eps ||
           abs(cur.center.longitude - region.center.longitude) > eps ||
           abs(cur.span.latitudeDelta - region.span.latitudeDelta) > eps {
            m.setRegion(region, animated: true)
        }
        let existing = Dictionary(uniqueKeysWithValues:
            m.annotations.compactMap { $0 as? FlightAnnotation }.map { ($0.flight.id, $0) })
        let newIds = Set(flights.map(\.id))
        m.removeAnnotations(existing.filter { !newIds.contains($0.key) }.map(\.value))
        for f in flights {
            if let ann = existing[f.id] {
                ann.flight = f
                ann.coordinate = CLLocationCoordinate2D(latitude: f.latitude, longitude: f.longitude)
            } else {
                m.addAnnotation(FlightAnnotation(f))
            }
        }
        for ann in m.annotations {
            guard let fa = ann as? FlightAnnotation, let v = m.view(for: fa) else { continue }
            applyPinStyle(v, fa: fa)
        }
    }

    /// How much to darken the map tiles (0 = off, 0.4 = very dark). Planes are unaffected.
    private static let mapDarkenAmount: CGFloat = 0.32
    private static let mapTintLayerName = "overhead.mapDarken"

    /// Native dark-map styling on the MKMapView itself (not a SwiftUI overlay).
    private static func applyMapAppearance(_ m: MKMapView) {
        m.overrideUserInterfaceStyle = .dark
        m.backgroundColor = UIColor(red: 0.02, green: 0.025, blue: 0.035, alpha: 1)
        let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        config.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
        m.preferredConfiguration = config
        syncMapDarkenLayer(on: m)
    }

    /// Uniform multiply tint on the map layer — darkens tiles, not annotation views.
    private static func syncMapDarkenLayer(on m: MKMapView) {
        if mapDarkenAmount <= 0 {
            m.layer.sublayers?.first { $0.name == mapTintLayerName }?.removeFromSuperlayer()
            return
        }
        let layer: CALayer
        if let existing = m.layer.sublayers?.first(where: { $0.name == mapTintLayerName }) {
            layer = existing
        } else {
            let l = CALayer()
            l.name = mapTintLayerName
            l.compositingFilter = "multiplyBlendMode"
            m.layer.insertSublayer(l, at: 0)
            layer = l
        }
        layer.frame = m.bounds
        let multiplyWhite = max(0.45, 1 - mapDarkenAmount)
        layer.backgroundColor = UIColor(white: multiplyWhite, alpha: 1).cgColor
    }

    // MARK: - Aircraft icon rendering

    /// Baseline on-screen size (points) for **Large** (narrow-body) aircraft — the
    /// longest *content* edge after transparent PNG borders are trimmed. Smaller and
    /// larger tiers multiply this via `AircraftIcon.mapScale(for:)`.
    private static let normalSize:   CGFloat = 23
    private static let selectedSize: CGFloat = 32

    /// Final scaled icons cached by "asset|size".
    private static var iconCache: [String: UIImage] = [:]
    /// Padding-trimmed base images cached by asset name (trim once, reuse).
    private static var trimmedBaseCache: [String: UIImage] = [:]

    /// Generic outlined SF Symbol icons tinted per aircraft family.
    private static func genericIcon(tint: UIColor) -> UIImage {
        AircraftIcon.genericOutlinedPinImage(tint: tint)
    }

    /// Returns a cached, padding-trimmed, aspect-scaled icon for an ICAO type.
    private static func icon(forType type: String, target: CGFloat) -> UIImage {
        let asset = AircraftIcon.assetName(for: type)
        let tone = AircraftIcon.mapPinUIColor(for: type)
        let cacheName = asset ?? "_generic|\(tone.description)"
        let scaledTarget = target * AircraftIcon.mapScale(for: type)
        let key = "\(cacheName)|\(Int(scaledTarget))"
        if let cached = iconCache[key] { return cached }

        let trimmed: UIImage
        if let t = trimmedBaseCache[cacheName] {
            trimmed = t
        } else if let asset, let raw = UIImage(named: asset) {
            let t = raw.trimmingTransparentBorder()
            trimmedBaseCache[cacheName] = t
            trimmed = t
        } else {
            let t = genericIcon(tint: tone)
            trimmedBaseCache[cacheName] = t
            trimmed = t
        }

        let longest = max(trimmed.size.width, trimmed.size.height)
        let scale = longest > 0 ? scaledTarget / longest : 1
        let newSize = CGSize(width: trimmed.size.width * scale, height: trimmed.size.height * scale)
        let rendered = UIGraphicsImageRenderer(size: newSize).image { _ in
            trimmed.draw(in: CGRect(origin: .zero, size: newSize))
        }
        iconCache[key] = rendered
        return rendered
    }

    private func applyPinStyle(_ v: MKAnnotationView, fa: FlightAnnotation) {
        let sel = fa.flight.id == selectedId
        let target = sel ? LiveMap.selectedSize : LiveMap.normalSize
        v.image = LiveMap.icon(forType: fa.flight.type, target: target)
        v.layer.contentsGravity = .resizeAspect
        // Asset icons are drawn nose-up (north = 0°): rotate by heading directly.
        let angle = CGFloat(fa.flight.heading * .pi / 180)
        v.transform = CGAffineTransform(rotationAngle: angle)
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowRadius  = sel ? 6 : 3
        v.layer.shadowOpacity = sel ? 0.55 : 0.40
        v.layer.shadowOffset  = .zero
        v.layer.zPosition     = sel ? 1 : 0
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: LiveMap
        init(_ p: LiveMap) { parent = p }

        func mapView(_ m: MKMapView, viewFor ann: MKAnnotation) -> MKAnnotationView? {
            guard let fa = ann as? FlightAnnotation else { return nil }
            let v = m.dequeueReusableAnnotationView(withIdentifier: "fp") as? FlightPinAnnotationView
                ?? FlightPinAnnotationView(annotation: ann, reuseIdentifier: "fp")
            v.annotation = ann
            v.canShowCallout = false
            parent.applyPinStyle(v, fa: fa)
            return v
        }

        func mapView(_ m: MKMapView, didSelect ann: MKAnnotation) {
            guard let fa = ann as? FlightAnnotation else { return }
            m.deselectAnnotation(ann, animated: false)
            parent.onSelect(fa.flight)
        }

        func mapView(_ m: MKMapView, regionDidChangeAnimated _: Bool) {
            DispatchQueue.main.async { self.parent.region = m.region }
        }
    }
}

// MARK: - Root ContentView
struct ContentView:View {
    @StateObject private var service  = FlightService()
    @StateObject private var location = LocationManager()
    @StateObject private var aircraft = AircraftService()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120))
    @State private var userCoord:   CLLocationCoordinate2D? = nil
    @State private var quickFlight: Flight?  = nil
    @State private var detailFlight:Flight?  = nil
    @State private var showBoard     = false
    @State private var hasZoomedOnce = false    // prevents re-zoom on each refresh
    @State private var didCenterOnUser = false  // ensures first GPS fix centers the map
    @State private var awaitingLocation = true
    @State private var routes:       [String:RouteData] = [:]
    @State private var pendingFlightIcao: String? = nil
    @Environment(\.scenePhase) private var scenePhase

    let timer = Timer.publish(every:60,on:.main,in:.common).autoconnect()

    private var showScanningOverlay: Bool {
        service.flights.isEmpty
            && service.errorMessage == nil
            && (service.isLoading || awaitingLocation)
    }

    var body: some View {
        GeometryReader { geo in
        ZStack {
            // ── FULL-SCREEN DARK MAP (native animated zoom via setRegion) ──
            LiveMap(region:     $region,
                    flights:    service.flights,
                    selectedId: quickFlight?.id,
                    onSelect:   tapPin)
                .ignoresSafeArea()

            // ── BOTTOM PILL: list toggle + refresh (map only — hidden when any card is open) ──
            VStack {
                Spacer()
                if quickFlight == nil && !showBoard && detailFlight == nil {
                    bottomPill
                        .padding(.bottom, 34)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .zIndex(0)
            .animation(.spring(response: 0.38, dampingFraction: 0.82),
                       value: quickFlight == nil && !showBoard && detailFlight == nil)

            // ── FLOATING CARDS (pinned to bottom) ──
            ZStack(alignment: .bottom) {
                if showBoard {
                    BoardOverlay(flights: service.flights, routes: routes,
                        onClose: { withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { showBoard = false } },
                        onRefresh: { refresh() },
                        onDetail: { f in
                            showBoard = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { openDetail(f) }
                        },
                        maxListHeight: geo.size.height * 0.48)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
                }

                if let f = quickFlight, !showBoard, detailFlight == nil {
                    QuickCard(flight: f,
                        onDismiss: { dismissFlightSelection() },
                        onDetails: { openDetail(f) })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
                }

                if let f = detailFlight {
                    FlightDetailView(
                        flight: f,
                        route: routes[f.icao24],
                        aircraft: aircraft,
                        onDismiss: { dismissFlightSelection() },
                        maxScrollHeight: geo.size.height * 0.42
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, CardLayout.screenMargin)
            .padding(.bottom, CardLayout.bottomMargin)
            .ignoresSafeArea(edges: .bottom)
            .zIndex(5)
            .animation(.spring(response: 0.42, dampingFraction: 0.82), value: showBoard)
            .animation(.spring(response: 0.42, dampingFraction: 0.82), value: quickFlight?.id)
            .animation(.spring(response: 0.42, dampingFraction: 0.82), value: detailFlight?.id)

            // ── Scanning overlay (first load only) ──
            if showScanningOverlay {
                VStack(spacing: 16) {
                    LEDLabel("SCANNING AIRSPACE", dotPt: LEDSize.scanChip, color: C.ledBlue)
                        .frame(height: 7 * LEDSize.scanChip)
                    ProgressView()
                        .scaleEffect(1.0)
                        .tint(.white)
                }
                .frame(width: 152)
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
                .background { GlassBg(radius: 20) }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .allowsHitTesting(false)
            }

            // ── Error banner ──
            if let message = service.errorMessage, !service.isLoading {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(C.coral)
                        Text(message)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(C.t1)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Button("Retry") { refresh() }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(C.ledBlue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background { GlassBg(radius: 16) }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.top, 56)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(3)
            }

        }
        } // GeometryReader
        .preferredColorScheme(.dark)
        .onOpenURL { url in
            if let icao = FlightDeepLink.icao24(from: url) {
                openFlightFromDeepLink(icao24: icao)
            }
        }
        .onAppear {
            awaitingLocation = true
            service.errorMessage = nil
            Task { _ = try? await OpenSkyAuth.shared.bearerToken() }
            bootstrapFromCachedLocation()
            location.requestOnce(
                onLocation: { loc in
                    awaitingLocation = false
                    applyUserLocation(loc)
                },
                onError: { message in
                    awaitingLocation = false
                    if userCoord == nil {
                        service.errorMessage = message
                    }
                }
            )
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                publishWidgetBoard(reload: true)
            }
        }
        .onReceive(service.$flights) { fl in
            if !service.isLoading {
                publishWidgetBoard(reload: false)
            }
            guard !fl.isEmpty else { return }
            for f in fl.prefix(4) {
                fetchRoute(f)
                aircraft.fetch(f)
            }
            resolvePendingFlightDeepLink(in: fl)
            if !hasZoomedOnce, let coord = userCoord ?? location.recentLocation()?.coordinate {
                // Only auto-frame when the loaded flights are actually near the user,
                // so a stale default-region (Vancouver) batch never hijacks the view.
                let ul = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                let nearest = fl.map {
                    CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: ul)
                }.min() ?? .infinity
                if nearest < 300_000 {
                    hasZoomedOnce = true
                    zoomToClosest5(coord)
                }
            }
        }
        .onChange(of: quickFlight?.id) { _, _ in
            if let f = quickFlight {
                fetchRoute(f)
                aircraft.fetch(f)
            }
        }
        .onChange(of: showBoard) { _, open in
            guard open else { return }
            for f in service.flights.prefix(8) {
                fetchRoute(f)
                aircraft.fetch(f)
            }
        }
        .onReceive(timer) { _ in
            guard !service.isLoading,
                  let c = userCoord ?? location.recentLocation()?.coordinate ?? SharedWidgetLocation.coordinate()
            else { return }
            service.fetchFlights(latitude: c.latitude, longitude: c.longitude)
        }
    }

    /// Open the aircraft-detail card for a flight.
    func openDetail(_ f: Flight) {
        fetchRoute(f)
        aircraft.fetch(f)
        detailFlight = f
    }

    var bottomPill: some View {
        HStack(spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { showBoard = true } }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 17, weight: .medium))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(Color.white)
                    .frame(width: 66, height: 52)
            }
            .accessibilityLabel("Flight list")
            .accessibilityHint("Shows nearby flights")
            Rectangle().fill(Color.white.opacity(0.18)).frame(width: 0.5, height: 22)
                .accessibilityHidden(true)
            Button(action: refresh) {
                Group {
                    if service.isLoading {
                        ProgressView().scaleEffect(0.7).tint(C.t1)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 17, weight: .medium))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(Color.white)
                    }
                }
                .frame(width: 66, height: 52)
            }
            .accessibilityLabel(service.isLoading ? "Refreshing flights" : "Refresh flights near you")
        }
        .background { GlassCapsule() }
        .clipShape(Capsule())
    }



    // MARK: Actions

    func openFlightFromDeepLink(icao24: String) {
        let key = icao24.lowercased()
        showBoard = false
        if let match = service.flights.first(where: { $0.icao24.lowercased() == key }) {
            pendingFlightIcao = nil
            tapPin(match)
            return
        }
        pendingFlightIcao = key
        refresh()
    }

    func resolvePendingFlightDeepLink(in flights: [Flight]) {
        guard let key = pendingFlightIcao else { return }
        guard let match = flights.first(where: { $0.icao24.lowercased() == key }) else { return }
        pendingFlightIcao = nil
        tapPin(match)
    }

    func tapPin(_ f:Flight) {
        if quickFlight?.id == f.id, !showBoard, detailFlight == nil {
            dismissFlightSelection()
            return
        }
        // Zoom in so plane is visible in top portion of map (above the quick card)
        let span = 0.22
        let latShift = span * 0.30   // shift center south → plane appears in upper 60%
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude:  f.latitude  - latShift,
                    longitude: f.longitude),
                span: MKCoordinateSpan(latitudeDelta:span, longitudeDelta:span))
        }
        withAnimation(.spring(response:0.42,dampingFraction:0.82)) {
            showBoard = false
            detailFlight = nil
            quickFlight = f
        }
        fetchRoute(f)
        aircraft.fetch(f)
        AirlineLogo.prefetch(callsign: f.callsign)
    }

    /// Close quick card / detail and zoom back out to show nearby traffic.
    func dismissFlightSelection() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            quickFlight = nil
        }
        detailFlight = nil
        zoomOutToOverview()
    }

    func zoomOutToOverview() {
        let center = userCoord
            ?? location.recentLocation()?.coordinate
            ?? region.center
        if service.flights.isEmpty {
            withAnimation(.easeInOut(duration: 0.5)) {
                region = MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 1.4, longitudeDelta: 1.4))
            }
            return
        }
        zoomToClosest5(center)
    }

    func refresh() {
        quickFlight = nil
        service.errorMessage = nil
        awaitingLocation = userCoord == nil
        fetchFlightsNearUser()
        location.requestOnce(
            onLocation: { loc in
                awaitingLocation = false
                applyUserLocation(loc)
            },
            onError: { message in
                awaitingLocation = false
                if userCoord == nil {
                    service.errorMessage = message
                }
            }
        )
    }

    private func bootstrapFromCachedLocation() {
        if let recent = location.recentLocation() {
            SharedWidgetLocation.save(recent, reloadWidget: false)
            beginFlightScan(at: recent.coordinate, animateMap: true)
            awaitingLocation = false
            return
        }
        if let coord = SharedWidgetLocation.coordinate() {
            beginFlightScan(at: coord, animateMap: true)
            awaitingLocation = false
        }
    }

    private func beginFlightScan(at coord: CLLocationCoordinate2D, animateMap: Bool) {
        userCoord = coord
        if animateMap {
            withAnimation(.easeInOut(duration: 0.4)) {
                region = MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 1.4, longitudeDelta: 1.4))
            }
        }
        service.fetchFlights(latitude: coord.latitude, longitude: coord.longitude)
    }

    /// Centers the map on a fresh GPS fix and reloads flights around it.
    private func applyUserLocation(_ loc: CLLocation) {
        SharedWidgetLocation.save(loc)
        userCoord = loc.coordinate
        service.fetchFlights(latitude: loc.coordinate.latitude,
                             longitude: loc.coordinate.longitude)

        let previous = region.center
        let movedFar = CLLocation(latitude: previous.latitude, longitude: previous.longitude)
            .distance(from: loc) > 1500
        guard movedFar || !didCenterOnUser else { return }
        didCenterOnUser = true
        hasZoomedOnce = false
        withAnimation(.easeInOut(duration: 0.4)) {
            region = MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.4, longitudeDelta: 1.4))
        }
    }

    /// Flights at cached GPS / map center — does not wait for a new GPS fix.
    /// Never claims the default map center as the user's real location.
    private func fetchFlightsNearUser() {
        if let coord = userCoord ?? location.recentLocation()?.coordinate ?? SharedWidgetLocation.coordinate() {
            beginFlightScan(at: coord, animateMap: false)
        }
    }

    func zoomToClosest5(_ coord:CLLocationCoordinate2D) {
        let ul=CLLocation(latitude:coord.latitude,longitude:coord.longitude)
        let top=Array(service.flights.sorted {
            CLLocation(latitude:$0.latitude,longitude:$0.longitude).distance(from:ul) <
            CLLocation(latitude:$1.latitude,longitude:$1.longitude).distance(from:ul)
        }.prefix(5))
        guard !top.isEmpty else { return }
        let lats=top.map(\.latitude)+[coord.latitude]
        let lons=top.map(\.longitude)+[coord.longitude]
        withAnimation(.easeInOut(duration: 0.55)) {
            region=MKCoordinateRegion(
                center:CLLocationCoordinate2D(latitude:(lats.min()!+lats.max()!)/2,
                                              longitude:(lons.min()!+lons.max()!)/2),
                span:MKCoordinateSpan(
                    latitudeDelta:max((lats.max()!-lats.min()!)*1.6,0.3),
                    longitudeDelta:max((lons.max()!-lons.min()!)*1.6,0.3)))
        }
    }

    func fetchRoute(_ f: Flight) {
        let icao = f.icao24
        if let existing = routes[icao], knownRouteEnds(existing) != nil { return }

        Task {
            guard let airports = await RouteLookupService.fetch(icao24: icao, callsign: f.callsign) else { return }
            let d = displayAP(airports.departure).code
            let a = displayAP(airports.arrival).code
            guard isKnownAirportCode(d), isKnownAirportCode(a) else { return }
            await MainActor.run {
                routes[icao] = RouteData(dep: d, arr: a)
                publishWidgetBoard(reload: false)
            }
        }
    }

    /// Keep the Home Screen board populated while the app is closed.
    private func publishWidgetBoard(reload: Bool) {
        if service.isLoading { return }
        if service.errorMessage != nil, service.flights.isEmpty {
            if reload { WidgetBoardStore.reloadTimelines() }
            return
        }
        guard service.lastUpdate != nil || !service.flights.isEmpty else {
            if reload { WidgetBoardStore.reloadTimelines() }
            return
        }
        guard let coord = userCoord
            ?? location.recentLocation()?.coordinate
            ?? SharedWidgetLocation.coordinate(maxAge: .infinity)
        else {
            if reload { WidgetBoardStore.reloadTimelines() }
            return
        }
        WidgetBoardStore.publish(
            flights: service.flights,
            routes: routes,
            near: coord,
            reload: reload
        )
    }
}

#Preview { ContentView() }
