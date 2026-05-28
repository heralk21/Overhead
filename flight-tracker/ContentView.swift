import SwiftUI
import MapKit
import CoreLocation
import Combine

let AERO_KEY = "d2a47f140cmsh45dfdd9c85ae915p118942jsn1eee16011b8d"   // ← rapidapi.com → search "aerodatabox" → free tier

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

struct RouteData { let dep:String; let arr:String }

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
}

// MARK: - LED Dot-Matrix Label
// FitLED: self-sizing — fits ANY width by scaling dotPt down automatically.
// Use this everywhere so text NEVER overflows on any device.
struct LEDLabel: View {
    let text:String; let dotPt:CGFloat; let color:Color; let dimmed:Bool
    init(_ t:String, dotPt:CGFloat, color:Color = .white, dimmed:Bool = true) {
        text=t; self.dotPt=dotPt; self.color=color; self.dimmed=dimmed
    }
    var body: some View {
        // GeometryReader measures available width, scales dotPt so text always fits
        GeometryReader { geo in
            let chars   = max(1, text.count)
            let maxFit  = geo.size.width / CGFloat(chars * 6)
            let pt      = min(dotPt, maxFit)            // never exceed available space
            let h       = 7 * pt
            let yOff    = (geo.size.height - h) / 2     // vertically center within frame
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

// MARK: - Aircraft DB
struct AircraftSpec { let name,wing,range,speed,cat:String }
let AIRCRAFT_DB:[String:AircraftSpec] = [
    "A319":.init(name:"AIRBUS A319",      wing:"34.1 M",range:"6,850 KM",speed:"833 KM/H",cat:"NARROW-BODY"),
    "A320":.init(name:"AIRBUS A320",      wing:"35.8 M",range:"6,150 KM",speed:"833 KM/H",cat:"NARROW-BODY"),
    "A321":.init(name:"AIRBUS A321",      wing:"35.8 M",range:"7,400 KM",speed:"833 KM/H",cat:"NARROW-BODY"),
    "A20N":.init(name:"AIRBUS A320NEO",   wing:"35.8 M",range:"6,300 KM",speed:"833 KM/H",cat:"NARROW-BODY"),
    "A21N":.init(name:"AIRBUS A321NEO",   wing:"35.8 M",range:"7,400 KM",speed:"833 KM/H",cat:"NARROW-BODY"),
    "A332":.init(name:"AIRBUS A330-200",  wing:"60.3 M",range:"13,450 KM",speed:"871 KM/H",cat:"WIDE-BODY"),
    "A333":.init(name:"AIRBUS A330-300",  wing:"60.3 M",range:"11,750 KM",speed:"871 KM/H",cat:"WIDE-BODY"),
    "A359":.init(name:"AIRBUS A350-900",  wing:"64.8 M",range:"15,000 KM",speed:"903 KM/H",cat:"WIDE-BODY"),
    "A388":.init(name:"AIRBUS A380-800",  wing:"79.8 M",range:"15,200 KM",speed:"903 KM/H",cat:"DOUBLE-DECK"),
    "BCS1":.init(name:"AIRBUS A220-100",  wing:"35.1 M",range:"5,740 KM",speed:"871 KM/H",cat:"NARROW-BODY"),
    "BCS3":.init(name:"AIRBUS A220-300",  wing:"35.1 M",range:"6,300 KM",speed:"871 KM/H",cat:"NARROW-BODY"),
    "B737":.init(name:"BOEING 737-700",   wing:"35.8 M",range:"6,370 KM",speed:"842 KM/H",cat:"NARROW-BODY"),
    "B738":.init(name:"BOEING 737-800",   wing:"35.8 M",range:"5,765 KM",speed:"842 KM/H",cat:"NARROW-BODY"),
    "B739":.init(name:"BOEING 737-900",   wing:"35.8 M",range:"6,045 KM",speed:"842 KM/H",cat:"NARROW-BODY"),
    "B38M":.init(name:"BOEING 737 MAX 8", wing:"35.9 M",range:"6,570 KM",speed:"842 KM/H",cat:"NARROW-BODY"),
    "B752":.init(name:"BOEING 757-200",   wing:"38.1 M",range:"7,225 KM",speed:"854 KM/H",cat:"NARROW-BODY"),
    "B763":.init(name:"BOEING 767-300",   wing:"47.6 M",range:"11,070 KM",speed:"851 KM/H",cat:"WIDE-BODY"),
    "B772":.init(name:"BOEING 777-200",   wing:"60.9 M",range:"9,700 KM",speed:"905 KM/H",cat:"WIDE-BODY"),
    "B77W":.init(name:"BOEING 777-300ER", wing:"64.8 M",range:"13,650 KM",speed:"950 KM/H",cat:"WIDE-BODY"),
    "B788":.init(name:"BOEING 787-8",     wing:"60.1 M",range:"13,530 KM",speed:"903 KM/H",cat:"WIDE-BODY"),
    "B789":.init(name:"BOEING 787-9",     wing:"60.1 M",range:"14,140 KM",speed:"903 KM/H",cat:"WIDE-BODY"),
    "DH8D":.init(name:"BOMBARDIER Q400",  wing:"28.4 M",range:"2,040 KM",speed:"667 KM/H",cat:"TURBOPROP"),
    "CRJ9":.init(name:"BOMBARDIER CRJ-900",wing:"24.9 M",range:"2,875 KM",speed:"830 KM/H",cat:"REGIONAL JET"),
    "E175":.init(name:"EMBRAER E175",     wing:"26.0 M",range:"3,735 KM",speed:"870 KM/H",cat:"REGIONAL JET"),
    "E190":.init(name:"EMBRAER E190",     wing:"28.7 M",range:"4,537 KM",speed:"870 KM/H",cat:"REGIONAL JET"),
]

// MARK: - Airport lookup
let AIRPORTS:[String:(code:String,city:String)] = [
    "CYVR":("YVR","VANCOUVER"),"CYYZ":("YYZ","TORONTO"),"CYUL":("YUL","MONTREAL"),
    "CYYC":("YYC","CALGARY"),"CYEG":("YEG","EDMONTON"),"CYOW":("YOW","OTTAWA"),
    "KLAX":("LAX","LOS ANGELES"),"KJFK":("JFK","NEW YORK"),"KORD":("ORD","CHICAGO"),
    "KATL":("ATL","ATLANTA"),"KSFO":("SFO","SAN FRANCISCO"),"KDFW":("DFW","DALLAS"),
    "KDEN":("DEN","DENVER"),"KSEA":("SEA","SEATTLE"),"KMIA":("MIA","MIAMI"),
    "KBOS":("BOS","BOSTON"),"KLAS":("LAS","LAS VEGAS"),"KPHX":("PHX","PHOENIX"),
    "EGLL":("LHR","LONDON"),"EGKK":("LGW","GATWICK"),
    "LFPG":("CDG","PARIS"),"EHAM":("AMS","AMSTERDAM"),"EDDF":("FRA","FRANKFURT"),
    "EDDM":("MUC","MUNICH"),"LEMD":("MAD","MADRID"),"LIRF":("FCO","ROME"),
    "LSZH":("ZRH","ZURICH"),"OMDB":("DXB","DUBAI"),"OTHH":("DOH","DOHA"),
    "VHHH":("HKG","HONG KONG"),"RJTT":("HND","TOKYO"),"RJAA":("NRT","NARITA"),
    "RKSI":("ICN","SEOUL"),"WSSS":("SIN","SINGAPORE"),
    "YMML":("MEL","MELBOURNE"),"YSSY":("SYD","SYDNEY"),
]
func displayAP(_ icao:String?)->(code:String,city:String) {
    guard let s=icao,!s.isEmpty else { return ("???","") }
    if let d=AIRPORTS[s] { return d }
    if s.count==4&&(s.hasPrefix("K")||s.hasPrefix("C")) { return (String(s.dropFirst()),"") }
    return (s.count>=3 ? String(s.suffix(3)):s,"")
}

// MARK: - Airline helpers
let AIRLINE_NAMES:[String:String] = [
    "ACA":"AIR CANADA","JZA":"AC EXPRES","ROU":"AIR CANADA ROUGE","WJA":"WESTJET",
    "WEN":"WESTJET EXP","UAL":"UNITED","DAL":"DELTA","AAL":"AMERICAN",
    "SWA":"SOUTHWEST","ASA":"ALASKA AIR","SKW":"SKYWEST","JBU":"JETBLUE",
    "BAW":"BRIT AIRWAYS","DLH":"LUFTHANSA","AFR":"AIR FRANCE","KLM":"KLM",
    "UAE":"EMIRATES","QFA":"QANTAS","CPA":"CATHAY PAC","TSC":"AIR TRANSAT",
    "RYR":"RYANAIR","EZY":"EASYJET","THY":"TURKISH AIR","FIN":"FINNAIR",
    "SAS":"SCANDINAVIAN","IBE":"IBERIA","TAP":"TAP PORTUGAL","AZU":"AZUL",
    "LAM":"LATAM","VOE":"VOLARIS","GLR":"AIR GLACIERS","PAL":"PHIL AIR",
    "FDX":"FEDEX","UPS":"UPS AIR","ATN":"AIR TRANSPORT",
]
func airlineName(_ cs: String) -> String {
    let prefix = String(cs.prefix(3)).uppercased()
    if let name = AIRLINE_NAMES[prefix] { return name }
    // Detect Canadian private registrations (C-FXXX, C-GXXX etc.)
    let c2 = String(cs.prefix(2)).uppercased()
    if c2 == "CF" || c2 == "CG" || c2 == "CI" { return "PRIVATE FLT" }
    return "CHARTER FLT"
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

    func fetch(_ id: String) {
        guard state[id] == nil else { return }   // already loading or done
        state[id] = .loading
        Task {
            var info = AeroInfo()
            if !AERO_KEY.isEmpty {
                var req = URLRequest(
                    url: URL(string: "https://aerodatabox.p.rapidapi.com/aircrafts/icao24/\(id.lowercased())")!,
                    timeoutInterval: 15)           // 15s timeout — fail fast
                req.setValue(AERO_KEY, forHTTPHeaderField: "X-RapidAPI-Key")
                req.setValue("aerodatabox.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
                if let (d, resp) = try? await URLSession.shared.data(for: req),
                   (resp as? HTTPURLResponse)?.statusCode == 200,
                   let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
                    info.reg         = (j["registration"]    as? String ?? "").uppercased()
                    info.typeName    = (j["typeName"]        as? String ?? "").uppercased()
                    info.icaoType    = (j["icaoTypeCode"]    as? String ?? "").uppercased()
                    info.seats       = j["numberSeats"]      as? Int
                    info.engines     = j["numberEngines"]    as? Int
                    info.firstFlight = (j["firstFlightDate"] as? String ?? "").uppercased()
                }
            }
            // Augment with local DB even when API fails
            if let s = AIRCRAFT_DB[info.icaoType] {
                if info.typeName.isEmpty { info.typeName = s.name }
                info.wing  = s.wing;  info.range = s.range
                info.speed = s.speed; info.cat   = s.cat
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

// MARK: - Plane pin (clean white icon)
struct FlightPin:View {
    let flight:Flight; let selected:Bool
    var body: some View {
        Image(systemName:"airplane")
            .font(.system(size:selected ? 20:13,weight:selected ? .semibold:.medium))
            .foregroundColor(.white)
            .rotationEffect(.degrees(flight.heading-45))
            .shadow(color:selected ? Color.white.opacity(0.55) : Color.black.opacity(0.35),
                    radius:selected ? 5:2)
            .scaleEffect(selected ? 1.3:1)
            .animation(.spring(response:0.3,dampingFraction:0.72),value:selected)
    }
}

// MARK: - Reusable glass panel background
struct GlassBg:View {
    var radius:CGFloat=36
    var body: some View {
        ZStack {
            // True liquid glass: heavy blur, very light dark tint
            RoundedRectangle(cornerRadius:radius).fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius:radius)
                .fill(Color.black.opacity(0.28))
            RoundedRectangle(cornerRadius:radius)
                .stroke(Color.white.opacity(0.18),lineWidth:0.5)
        }
    }
}

// MARK: - Detail CTA button
// Plane icon LEFT; long-press: text fades, plane flies to right, triggers action
struct DetailAnimButton:View {
    let onDetails:()->Void
    @GestureState private var pressing=false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                GlassBg(radius:16)
                HStack {
                    Image(systemName:"airplane")
                        .font(.system(size:18,weight:.semibold))
                        .foregroundColor(C.t1)
                        .shadow(color:C.ledBlue.opacity(0.5),radius:4)
                        .offset(x:pressing ? geo.size.width-54:0)
                        .animation(
                            pressing ? .spring(response:0.55,dampingFraction:0.7)
                                     : .spring(response:0.3,dampingFraction:0.85),
                            value:pressing)
                    Spacer()
                }
                .padding(.horizontal,20)
                Text("See Airplane Details")
                    .font(.system(size:16,weight:.semibold))
                    .foregroundColor(C.t1)
                    .opacity(pressing ? 0:1)
                    .animation(.easeInOut(duration:0.13),value:pressing)
            }
        }
        .frame(height:54)
        .clipShape(RoundedRectangle(cornerRadius:16))  // ← prevent plane escaping
        .gesture(
            LongPressGesture(minimumDuration:0.55)
                .updating($pressing) { v,s,_ in s=v }
                .onEnded { _ in onDetails() }
        )
    }
}

// MARK: - Quick Card (exact match Image 1)
struct QuickCard:View {
    let flight:Flight; let route:RouteData?
    let onDismiss:()->Void; let onDetails:()->Void

    var cs: String { String(flight.callsign.prefix(6)).uppercased() }

    var body: some View {
        VStack(spacing:0) {

            // ── Handle + close (NO plane icon per request) ──
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius:3).fill(C.t3).frame(width:36,height:4)
                Spacer()
            }
            .overlay(alignment:.topTrailing) {
                Button(action:onDismiss) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.14)).frame(width:32,height:32)
                            .overlay(Circle().stroke(Color.white.opacity(0.18),lineWidth:0.5))
                        Image(systemName:"xmark").font(.system(size:11,weight:.bold)).foregroundColor(C.t1)
                    }
                }
                .frame(width:44,height:44).accessibilityLabel("Dismiss")
                .padding(.trailing,8)
            }
            .padding(.top,10)

            // ── Callsign in LED ──
            LEDLabel(cs, dotPt:6.5)
                .frame(maxWidth:.infinity,alignment:.leading)
                .padding(.horizontal,20).padding(.top,10).padding(.bottom,14)

            div

            // ── Airline + route ──
            HStack {
                Text(airlineName(flight.callsign))
                    .font(.system(size:13,weight:.semibold,design:.monospaced))
                    .foregroundColor(C.coral)
                Spacer()
                if let rt=route {
                    HStack(spacing:4) {
                        Text(displayAP(rt.dep).code)
                        Image(systemName:"arrow.right").font(.system(size:8))
                        Text(displayAP(rt.arr).code)
                    }
                    .font(.system(size:11,weight:.medium,design:.monospaced))
                    .foregroundColor(C.t2)
                }
            }
            .padding(.horizontal,20).padding(.vertical,10)

            div

            // ── Live flight data rows ──
            qRow("ALTITUDE", "\(max(0,flight.altitudeInFeet)) FT")
            qRow("SPEED",    "\(flight.velocityInKnots) KT")
            qRow("HEADING",  "\(Int(flight.heading))° \(flight.headingDirection)")
            qRow("STATUS",   flight.altitudeStatus.uppercased())

            div

            // ── CTA: long press to see aircraft build details ──
            DetailAnimButton(onDetails:onDetails)
                .padding(.horizontal,18).padding(.top,12).padding(.bottom,20)
        }
        .frame(maxWidth:.infinity)
        .background(GlassBg(radius:32))
    }

    var div: some View {
        Rectangle().fill(C.sep).frame(height:0.5).padding(.horizontal,20)
    }

    func qRow(_ label:String, _ value:String) -> some View {
        HStack {
            Text(label)
                .font(.system(size:11,weight:.medium,design:.monospaced))
                .foregroundColor(C.t2)
            Spacer()
            Text(value)
                .font(.system(size:11,weight:.semibold,design:.monospaced))
                .foregroundColor(C.t1)
        }
        .padding(.horizontal,20).padding(.vertical,8)
    }
}

// MARK: - Spec row (Image 2: blue LED label LEFT, white value RIGHT)
struct SpecRow:View {
    let label:String; let value:String
    var body: some View {
        VStack(spacing:0) {
            HStack(alignment:.center,spacing:8) {
                // LED dot-matrix label (blue) — matches Image 3 exactly
                LEDLabel(label, dotPt:2.2, color:C.ledBlue)
                Spacer(minLength:6)
                // Right-aligned value in monospaced white
                Text(value)
                    .font(.system(size:12,weight:.regular,design:.monospaced))
                    .foregroundColor(C.t1).tracking(0.3)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .fixedSize(horizontal:false,vertical:true)
            }
            .padding(.vertical,15)
            Rectangle().fill(C.sep).frame(height:0.5)
        }
    }
}

// MARK: - Flight Detail View — aircraft build info (Image 2 style)
// Shows: airline header + TYPE, REGISTRATION, CAPACITY, WINGSPAN etc.
// Does NOT show speed/altitude (those are in the quick card)
struct FlightDetailView:View {
    let flight:Flight; let route:RouteData?
    @ObservedObject var aircraft:AircraftService
    @Environment(\.dismiss) private var dismiss

    var airline: String { airlineName(flight.callsign) }
    var acColor: Color   { AIRLINE_NAMES.keys.contains(String(flight.callsign.prefix(3)).uppercased())
                            ? .red : C.blue }

    var body: some View {
        ZStack {
            Color(red:0.08,green:0.11,blue:0.16).ignoresSafeArea()
            VStack(spacing:0) {
                // System drag indicator space
                Spacer(minLength:6)

                // ── Close button (top-right, no plane icon) ──
                HStack {
                    Spacer()
                    Button(action:{ dismiss() }) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.14)).frame(width:38,height:38)
                                .overlay(Circle().stroke(Color.white.opacity(0.2),lineWidth:0.5))
                            Image(systemName:"xmark").font(.system(size:13,weight:.bold)).foregroundColor(C.t1)
                        }
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal,20).padding(.top,6).padding(.bottom,12)

                // ── Airline header (matches Image 2 style) ──
                HStack(spacing:14) {
                    ZStack {
                        Circle().fill(acColor.opacity(0.9)).frame(width:44,height:44)
                        Image(systemName:"airplane")
                            .font(.system(size:18,weight:.semibold))
                            .foregroundColor(.white)
                    }
                    Text(airline)
                        .font(.system(size:20,weight:.bold))
                        .foregroundColor(C.t1)
                    Spacer()
                }
                .padding(.horizontal,20).padding(.bottom,14)

                Rectangle().fill(C.sep).frame(height:0.5).padding(.horizontal,20)

                // ── Aircraft spec rows ──
                ScrollView(showsIndicators:false) {
                    VStack(spacing:0) {
                        if aircraft.state[flight.icao24] == .done,
                           let info = aircraft.data[flight.icao24],
                           (!info.typeName.isEmpty || info.seats != nil || info.wing != nil) {
                            if !info.typeName.isEmpty { SpecRow(label:"Type",           value:info.typeName) }
                            if !info.reg.isEmpty      { SpecRow(label:"Registration",   value:info.reg) }
                            if let v = info.firstFlight, !v.isEmpty {
                                                        SpecRow(label:"First Flight",   value:v) }
                            if let n = info.seats     { SpecRow(label:"Capacity",       value:"\(n) passengers") }
                            if let n = info.engines   { SpecRow(label:"Engines",        value:"\(n) engines") }
                            if let v = info.wing      { SpecRow(label:"Wingspan",       value:v) }
                            if let v = info.range     { SpecRow(label:"Range",          value:v) }
                            if let v = info.speed     { SpecRow(label:"Max Speed",      value:v) }
                            if let v = info.cat       { SpecRow(label:"Category",       value:v) }
                        } else if aircraft.state[flight.icao24] == .loading {
                            // Still fetching from AeroDataBox
                            HStack(spacing:10) {
                                ProgressView().scaleEffect(0.8).tint(C.ledBlue)
                                Text("Fetching aircraft data...")
                                    .font(.system(size:13)).foregroundColor(C.t2)
                            }.padding(24)
                        } else if !AERO_KEY.isEmpty {
                            // Fetch done but no data returned (private/unknown aircraft)
                            VStack(spacing:6) {
                                Text("No aircraft data found")
                                    .font(.system(size:13,weight:.semibold)).foregroundColor(C.t2)
                                Text("AeroDataBox has no record for this aircraft")
                                    .font(.system(size:11)).foregroundColor(C.t3)
                                    .multilineTextAlignment(.center)
                                // Show identifiers
                                SpecRow(label:"Callsign", value:flight.callsign.uppercased())
                                SpecRow(label:"ICAO 24",  value:flight.icao24.uppercased())
                            }.padding(.top,16)
                        } else {
                            VStack(spacing:8) {
                                Text("No aircraft data available")
                                    .font(.system(size:13,weight:.medium)).foregroundColor(C.t2)
                                Text("Add your AeroDataBox API key in ContentView.swift\nto see type, capacity, wingspan & more.")
                                    .font(.system(size:11)).foregroundColor(C.t3)
                                    .multilineTextAlignment(.center)
                            }.padding(24)
                            // Show basic identifiers as fallback
                            SpecRow(label:"Callsign",    value:flight.callsign.uppercased())
                            SpecRow(label:"ICAO 24",     value:flight.icao24.uppercased())
                            if let rt=route {
                                SpecRow(label:"From", value:"\(displayAP(rt.dep).code) \(displayAP(rt.dep).city)")
                                SpecRow(label:"To",   value:"\(displayAP(rt.arr).code) \(displayAP(rt.arr).city)")
                            }
                        }
                    }
                    .padding(.horizontal,20)
                    // Bottom safe area so last row doesn't touch screen edge
                    .padding(.bottom,40)
                }
            }
        }
        .onAppear { aircraft.fetch(flight.icao24) }
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

// MARK: - Board Overlay (map always visible above)
struct BoardOverlay:View {
    let flights:[Flight]; let routes:[String:RouteData]
    let onClose:()->Void; let onRefresh:()->Void; let onDetail:(Flight)->Void

    var body: some View {
        VStack(spacing:0) {
            Spacer()
            ZStack {
                GlassBg(radius:36)
                VStack(spacing:0) {
                    RoundedRectangle(cornerRadius:3).fill(C.t3)
                        .frame(width:44,height:4).padding(.top,14)
                    // Toolbar
                    HStack {
                        Button(action:onClose) {
                            Image(systemName:"map").font(.system(size:15,weight:.medium)).foregroundColor(C.t1)
                                .frame(width:42,height:42)
                                .background(Color.white.opacity(0.09)).clipShape(RoundedRectangle(cornerRadius:12))
                                .overlay(RoundedRectangle(cornerRadius:12).stroke(C.sep,lineWidth:0.5))
                        }
                        Spacer()
                        Text("FLIGHTS").font(.system(size:9,weight:.heavy,design:.monospaced))
                            .foregroundColor(C.ledBlue).tracking(4)
                        Spacer()
                        Button(action:onRefresh) {
                            Image(systemName:"arrow.clockwise").font(.system(size:15,weight:.medium)).foregroundColor(C.t1)
                                .frame(width:42,height:42)
                                .background(Color.white.opacity(0.09)).clipShape(RoundedRectangle(cornerRadius:12))
                                .overlay(RoundedRectangle(cornerRadius:12).stroke(C.sep,lineWidth:0.5))
                        }
                    }.padding(.horizontal,20).padding(.top,14)
                    // Column headers
                    Rectangle().fill(C.sep).frame(height:0.5).padding(.horizontal,20).padding(.top,12)
                    HStack(spacing:0) {
                        Text("FLIGHT").frame(width:95,alignment:.leading)
                        Text("TO").frame(maxWidth:.infinity,alignment:.leading)
                        Text("ALT").frame(width:52,alignment:.trailing)
                        Text("STATUS").frame(width:68,alignment:.trailing)
                    }
                    .font(.system(size:8,weight:.heavy,design:.monospaced))
                    .foregroundColor(C.ledBlue.opacity(0.65)).tracking(1.5)
                    .padding(.horizontal,20).padding(.vertical,9)
                    Rectangle().fill(C.sep).frame(height:0.5).padding(.horizontal,20)
                    ScrollView(showsIndicators:false) {
                        VStack(spacing:0){
                            ForEach(Array(flights.enumerated()),id:\.element.id){ i,f in
                                boardRow(f,i,onDetail:onDetail)
                                if i<flights.count-1 {
                                    Rectangle().fill(C.sep.opacity(0.55)).frame(height:0.5).padding(.leading,20)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight:580)
            .padding(.horizontal,10)
        }
        .padding(.bottom,0)
        .ignoresSafeArea(edges:.bottom)
    }

    func boardRow(_ f:Flight,_ i:Int, onDetail:@escaping (Flight)->Void)->some View {
        let sc:Color = { switch f.altitudeStatus {
            case "Takeoff","Climb": return .orange
            case "Cruise","High Alt": return C.cyan
            default: return C.ledBlue } }()
        let statusShort = f.altitudeStatus == "High Alt" ? "HI-ALT" :
                          f.altitudeStatus == "Takeoff"  ? "T/OFF"  :
                          String(f.altitudeStatus.prefix(6)).uppercased()
        let altStr = "\(f.altitudeInFeet/1000)K"
        return HStack(spacing:0) {
            // FLIGHT — split-flap animation
            FlapRow(text:f.callsign,sz:12,t0:Double(i)*0.04)
                .frame(width:90,alignment:.leading)
            // TO — LED dot-matrix
            if let rt=routes[f.icao24] {
                LEDLabel(displayAP(rt.arr).code, dotPt:2.8, color:.white)
                    .frame(maxWidth:.infinity,alignment:.leading)
            } else {
                LEDLabel(statusShort, dotPt:2.5, color:C.t3)
                    .frame(maxWidth:.infinity,alignment:.leading)
            }
            // ALT — LED dot-matrix cyan
            LEDLabel(altStr, dotPt:2.8, color:C.cyan)
                .frame(width:44,alignment:.trailing)
            // STATUS — LED dot-matrix color-coded
            LEDLabel(statusShort, dotPt:2.2, color:sc)
                .frame(width:62,alignment:.trailing)
            // Tap → detail
            Button(action:{ onDetail(f) }) {
                Image(systemName:"airplane.circle")
                    .font(.system(size:16,weight:.regular))
                    .foregroundColor(C.ledBlue.opacity(0.7))
                    .padding(.leading,8)
            }
        }
        .padding(.horizontal,16).padding(.vertical,12)
    }
}


// MARK: - FlightAnnotation
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
        m.setRegion(region, animated: false)
        return m
    }

    func updateUIView(_ m: MKMapView, context: Context) {
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

    // Renders a GUARANTEED white airplane using UIGraphicsImageRenderer
    // paletteColors is unreliable on iOS 15; this approach always works
    private static func whiteAirplane(size: CGFloat, weight: UIImage.SymbolWeight) -> UIImage {
        let cfg = UIImage.SymbolConfiguration(pointSize: size, weight: weight)
        guard let sym = UIImage(systemName: "airplane", withConfiguration: cfg) else { return UIImage() }
        // Draw white-tinted image into a new renderer to bake the color permanently
        let renderer = UIGraphicsImageRenderer(size: sym.size)
        return renderer.image { _ in
            sym.withTintColor(.white, renderingMode: .alwaysOriginal).draw(at: .zero)
        }
    }

    private func applyPinStyle(_ v: MKAnnotationView, fa: FlightAnnotation) {
        let sel = fa.flight.id == selectedId
        let sz: CGFloat = sel ? 20 : 13
        let wt: UIImage.SymbolWeight = sel ? .semibold : .regular
        // Use the renderer-baked white image (no tintColor / palette dependency)
        v.image = LiveMap.whiteAirplane(size: sz, weight: wt)
        v.layer.contentsGravity = .resizeAspect
        let angle = CGFloat((fa.flight.heading - 45) * .pi / 180)
        v.transform = CGAffineTransform(rotationAngle: angle)
        v.layer.shadowColor   = UIColor.white.cgColor
        v.layer.shadowRadius  = sel ? 5 : 1.5
        v.layer.shadowOpacity = sel ? 0.5 : 0.2
        v.layer.shadowOffset  = .zero
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: LiveMap
        init(_ p: LiveMap) { parent = p }

        func mapView(_ m: MKMapView, viewFor ann: MKAnnotation) -> MKAnnotationView? {
            guard let fa = ann as? FlightAnnotation else { return nil }
            let v = m.dequeueReusableAnnotationView(withIdentifier: "fp")
                ?? MKAnnotationView(annotation: ann, reuseIdentifier: "fp")
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
        center:CLLocationCoordinate2D(latitude:49.2827,longitude:-123.1207),
        span:MKCoordinateSpan(latitudeDelta:1.8,longitudeDelta:1.8))
    @State private var userCoord:   CLLocationCoordinate2D? = nil
    @State private var quickFlight: Flight?  = nil
    @State private var detailFlight:Flight?  = nil
    @State private var showDetail    = false
    @State private var showBoard     = false
    @State private var hasZoomedOnce = false    // prevents re-zoom on each refresh
    @State private var routes:       [String:RouteData] = [:]

    let timer = Timer.publish(every:60,on:.main,in:.common).autoconnect()

    var body: some View {
        GeometryReader { geo in
        ZStack {
            // ── FULL-SCREEN DARK MAP (native animated zoom via setRegion) ──
            LiveMap(region:     $region,
                    flights:    service.flights,
                    selectedId: quickFlight?.id,
                    onSelect:   tapPin)
                .ignoresSafeArea()



            // ── BOARD OVERLAY (map stays visible above) ──
            if showBoard {
                BoardOverlay(flights:service.flights, routes:routes,
                    onClose:  { withAnimation(.spring(response:0.42,dampingFraction:0.82)){ showBoard=false } },
                    onRefresh:{ refresh() },
                    onDetail: { f in
                        showBoard=false
                        detailFlight=f
                        DispatchQueue.main.asyncAfter(deadline:.now()+0.3){ showDetail=true }
                    })
                .transition(.move(edge:.bottom).combined(with:.opacity))
                .zIndex(1)
            }

            // ── QUICK CARD ──
            VStack {
                Spacer()
                if let f=quickFlight, !showBoard {
                    QuickCard(flight:f, route:routes[f.icao24],
                        onDismiss:{ withAnimation(.spring(response:0.38,dampingFraction:0.82)){ quickFlight=nil } },
                        onDetails:{ detailFlight=f; showDetail=true })
                    .frame(maxHeight: geo.size.height * 0.40)
                    .padding(.horizontal,10)
                    .transition(.move(edge:.bottom).combined(with:.opacity))
                    .zIndex(2)
                }
            }
            .animation(.spring(response:0.42,dampingFraction:0.82),value:quickFlight?.id)

            // ── BOTTOM PILL: list toggle + location/refresh ──
            VStack {
                Spacer()
                if quickFlight==nil && !showBoard {
                    bottomPill.padding(.bottom,34)
                        .transition(.move(edge:.bottom).combined(with:.opacity))
                }
            }
            .animation(.spring(response:0.38,dampingFraction:0.82),value:quickFlight==nil && !showBoard)
        }
        } // GeometryReader
        .preferredColorScheme(.dark)
        .sheet(isPresented:$showDetail) {
            sheetContent
        }
        .onAppear {
            // Auto-request location — NO welcome card per spec
            location.requestOnce { loc in
                userCoord=loc.coordinate
                withAnimation(.easeInOut(duration:1.2)) {
                    region=MKCoordinateRegion(
                        center:loc.coordinate,
                        span:MKCoordinateSpan(latitudeDelta:1.4,longitudeDelta:1.4))
                }
                service.fetchFlights(latitude:loc.coordinate.latitude,
                                     longitude:loc.coordinate.longitude)
                // zoom fires from onReceive when flights load (hasZoomedOnce flag)
            } onError: { _ in
                service.fetchFlights(latitude:region.center.latitude,longitude:region.center.longitude)
            }
        }
        .onReceive(service.$flights) { fl in
            guard !fl.isEmpty else { return }
            for f in fl.prefix(5) { fetchRoute(f) }
            if !hasZoomedOnce, let coord = userCoord {
                hasZoomedOnce = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    zoomToClosest5(coord)
                }
            }
        }
        .onReceive(timer) { _ in
            guard !service.isLoading else { return }
            let c=userCoord ?? region.center
            service.fetchFlights(latitude:c.latitude,longitude:c.longitude)
        }
    }

    @ViewBuilder
    var sheetContent: some View {
        if let f=detailFlight {
            if #available(iOS 16.0,*) {
                FlightDetailView(flight:f,route:routes[f.icao24],aircraft:aircraft)
                    // .fraction(0.60) keeps top ~40% of screen showing map — matches Image 4
                    .presentationDetents([.fraction(0.60), .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(C.panelBg)
            } else {
                FlightDetailView(flight:f,route:routes[f.icao24],aircraft:aircraft)
            }
        }
    }

    var bottomPill: some View {
        HStack(spacing:0) {
            Button(action:{ withAnimation(.spring(response:0.42,dampingFraction:0.82)){ showBoard=true }}) {
                Image(systemName:"list.bullet")
                    .font(.system(size:17,weight:.medium)).foregroundColor(C.t1)
                    .frame(width:66,height:52)
            }
            Rectangle().fill(Color.white.opacity(0.18)).frame(width:0.5,height:22)
            Button(action:refresh) {
                Group {
                    if service.isLoading {
                        ProgressView().scaleEffect(0.7).tint(C.t1)
                    } else {
                        Image(systemName:"location.circle")
                            .font(.system(size:17,weight:.medium)).foregroundColor(C.t1)
                    }
                }.frame(width:66,height:52)
            }.disabled(service.isLoading)
        }
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.15),lineWidth:0.5))
    }



    // MARK: Actions
    func tapPin(_ f:Flight) {
        // Zoom in so plane is visible in top portion of map (above the quick card)
        let span = 0.22
        let latShift = span * 0.30   // shift center south → plane appears in upper 60%
        withAnimation(.spring(response:1.4, dampingFraction:0.75)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude:  f.latitude  - latShift,
                    longitude: f.longitude),
                span: MKCoordinateSpan(latitudeDelta:span, longitudeDelta:span))
        }
        withAnimation(.spring(response:0.42,dampingFraction:0.82)) {
            quickFlight = (quickFlight?.id==f.id) ? nil : f
        }
        fetchRoute(f); aircraft.fetch(f.icao24)
    }

    func refresh() {
        quickFlight   = nil
        hasZoomedOnce = false   // re-triggers zoom-to-5 on next flight load
        // Get fresh location first so userCoord is set before flights arrive
        location.requestOnce { loc in
            userCoord = loc.coordinate
            service.fetchFlights(latitude: loc.coordinate.latitude,
                                 longitude: loc.coordinate.longitude)
        } onError: { _ in
            let c = userCoord ?? region.center
            service.fetchFlights(latitude: c.latitude, longitude: c.longitude)
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
        withAnimation(.easeInOut(duration:1.9)) {
            region=MKCoordinateRegion(
                center:CLLocationCoordinate2D(latitude:(lats.min()!+lats.max()!)/2,
                                              longitude:(lons.min()!+lons.max()!)/2),
                span:MKCoordinateSpan(
                    latitudeDelta:max((lats.max()!-lats.min()!)*1.6,0.3),
                    longitudeDelta:max((lons.max()!-lons.min()!)*1.6,0.3)))
        }
    }

    func fetchRoute(_ f:Flight) {
        guard routes[f.icao24]==nil else { return }
        let end=Int(Date().timeIntervalSince1970), begin=end-86400
        guard let url=URL(string:"https://opensky-network.org/api/flights/aircraft?icao24=\(f.icao24)&begin=\(begin)&end=\(end)")
        else { return }
        URLSession.shared.dataTask(with:url) { data,resp,_ in
            guard let data=data,(resp as? HTTPURLResponse)?.statusCode==200,
                  let arr=try? JSONSerialization.jsonObject(with:data) as? [[String:Any]],
                  let last=arr.last else { return }
            let d=displayAP(last["estDepartureAirport"] as? String).code
            let a=displayAP(last["estArrivalAirport"]   as? String).code
            guard d != "???" || a != "???" else { return }
            DispatchQueue.main.async { self.routes[f.icao24]=RouteData(dep:d,arr:a) }
        }.resume()
    }
}

#Preview { ContentView() }
