import UIKit

/// Shared LED logo raster cache (gstatic square symbols + brand tint). Used by widget; app uses `AirlineLogo`.
enum AirlineLEDCache {
    struct Grid {
        let cols: Int
        let rows: Int
        let lit: [Bool]
    }

    private static let iataMap: [String: String] = [
        "ACA": "AC", "JZA": "AC", "ROU": "AC", "WJA": "WS", "WEN": "WS",
        "UAL": "UA", "DAL": "DL", "AAL": "AA", "SWA": "WN", "ASA": "AS",
        "SKW": "OO", "JBU": "B6", "HAL": "HA", "FFT": "F9", "BAW": "BA",
        "DLH": "LH", "AFR": "AF", "KLM": "KL", "UAE": "EK", "QTR": "QR",
        "ETD": "EY", "QFA": "QF", "CPA": "CX", "ANA": "NH", "JAL": "JL",
        "SIA": "SQ", "PAL": "PR", "RYR": "FR", "EZY": "U2", "TSC": "TS",
        "THY": "TK", "FIN": "AY", "SAS": "SK", "IBE": "IB", "TAP": "TP",
    ]

    private static let textMarkIATA: Set<String> = ["WS"]
    private static var memory: [String: Grid] = [:]
    private static let cacheDir: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("overhead_led_logos")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func iata(from callsign: String) -> String? {
        guard callsign.count >= 3 else { return nil }
        return iataMap[String(callsign.prefix(3)).uppercased()]
    }

    static func prefersTextMark(callsign: String) -> Bool {
        guard let code = iata(from: callsign) else { return false }
        return textMarkIATA.contains(code)
    }

    static func brandRGB(callsign: String) -> (r: Double, g: Double, b: Double) {
        switch iata(from: callsign) {
        case "AC": return (0.90, 0.08, 0.10)
        case "WS": return (0.00, 0.65, 0.65)
        case "DL": return (0.10, 0.25, 0.70)
        case "UA": return (0.00, 0.25, 0.60)
        case "AA": return (0.00, 0.35, 0.80)
        case "WN": return (0.90, 0.45, 0.05)
        case "B6": return (0.00, 0.45, 0.85)
        case "BA": return (0.00, 0.25, 0.60)
        case "LH": return (0.95, 0.80, 0.00)
        case "AF": return (0.00, 0.20, 0.60)
        case "EK": return (0.70, 0.00, 0.00)
        case "QR": return (0.55, 0.00, 0.20)
        default:   return (0.40, 0.78, 0.98)
        }
    }

    /// Dark gaps between LED dots — contrast reference for flight-code text.
    static let ledMatrixBackground = (r: 0.06, g: 0.065, b: 0.08)
    static let minLEDTextContrast: Double = 4.5

    /// Brand hue with lightness raised until readable on the LED matrix.
    static func accessibleBrandRGB(
        callsign: String,
        background: (r: Double, g: Double, b: Double) = ledMatrixBackground,
        minContrast: Double = minLEDTextContrast
    ) -> (r: Double, g: Double, b: Double) {
        let brand = brandRGB(callsign: callsign)
        if contrastRatio(brand, background) >= minContrast { return brand }

        var (h, s, l) = rgbToHSL(brand)
        for _ in 0..<48 {
            let candidate = hslToRGB(h: h, s: s, l: l)
            if contrastRatio(candidate, background) >= minContrast {
                return candidate
            }
            l = min(0.93, l + 0.025)
            s = max(0.30, s * 0.985)
        }

        let readable = brandRGB(callsign: "ZZZ")
        return blendRGB(brand, readable, t: 0.45)
    }

    private static func contrastRatio(
        _ fg: (r: Double, g: Double, b: Double),
        _ bg: (r: Double, g: Double, b: Double)
    ) -> Double {
        let l1 = relativeLuminance(fg)
        let l2 = relativeLuminance(bg)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(_ c: (r: Double, g: Double, b: Double)) -> Double {
        func channel(_ v: Double) -> Double {
            let clamped = min(1, max(0, v))
            return clamped <= 0.03928
                ? clamped / 12.92
                : pow((clamped + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b)
    }

    private static func rgbToHSL(_ c: (r: Double, g: Double, b: Double)) -> (h: Double, s: Double, l: Double) {
        let maxC = max(c.r, c.g, c.b)
        let minC = min(c.r, c.g, c.b)
        let l = (maxC + minC) / 2
        guard maxC > minC else { return (0, 0, l) }

        let d = maxC - minC
        let s = l > 0.5 ? d / (2 - maxC - minC) : d / (maxC + minC)
        let h: Double
        if maxC == c.r {
            h = (c.g - c.b) / d + (c.g < c.b ? 6 : 0)
        } else if maxC == c.g {
            h = (c.b - c.r) / d + 2
        } else {
            h = (c.r - c.g) / d + 4
        }
        return (h / 6, s, l)
    }

    private static func hslToRGB(h: Double, s: Double, l: Double) -> (r: Double, g: Double, b: Double) {
        guard s > 0 else { return (l, l, l) }

        func hue2rgb(_ p: Double, _ q: Double, _ t: Double) -> Double {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1 / 6 { return p + (q - p) * 6 * t }
            if t < 1 / 2 { return q }
            if t < 2 / 3 { return p + (q - p) * (2 / 3 - t) * 6 }
            return p
        }

        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q
        return (
            hue2rgb(p, q, h + 1 / 3),
            hue2rgb(p, q, h),
            hue2rgb(p, q, h - 1 / 3)
        )
    }

    private static func blendRGB(
        _ a: (r: Double, g: Double, b: Double),
        _ b: (r: Double, g: Double, b: Double),
        t: Double
    ) -> (r: Double, g: Double, b: Double) {
        let t = min(1, max(0, t))
        return (
            a.r + (b.r - a.r) * t,
            a.g + (b.g - a.g) * t,
            a.b + (b.b - a.b) * t
        )
    }

    static func prefetch(callsign: String) async {
        guard !prefersTextMark(callsign: callsign),
              let iata = iata(from: callsign) else { return }
        let path = cacheDir.appendingPathComponent("\(iata).png")
        if FileManager.default.fileExists(atPath: path.path) { return }
        for url in logoURLs(iata: iata) {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = UIImage(data: data), img.size.width > 1 {
                try? data.write(to: path)
                return
            }
        }
    }

    static func cachedGrid(callsign: String, size: Int = 16) -> Grid? {
        if prefersTextMark(callsign: callsign) { return nil }
        let icao = String(callsign.prefix(3)).uppercased()
        if let g = memory[icao] { return g }

        guard let iata = iata(from: callsign) else { return nil }
        let path = cacheDir.appendingPathComponent("\(iata).png")
        guard let data = try? Data(contentsOf: path),
              let img = UIImage(data: data),
              let grid = rasterize(img, cols: size, rows: size) else { return nil }
        memory[icao] = grid
        return grid
    }

    private static func logoURLs(iata: String) -> [URL] {
        [
            URL(string: "https://www.gstatic.com/flights/airline_logos/70px/\(iata).png"),
            URL(string: "https://www.gstatic.com/flights/airline_logos/32px/\(iata).png"),
        ].compactMap { $0 }
    }

    private struct Sample {
        var r = 0, g = 0, b = 0, a = 0
        var peak = 0
    }

    private static func rasterize(_ image: UIImage, cols: Int, rows: Int) -> Grid? {
        let trimmed = image.preparedAirlineLogo(padding: 2)
        let hi = 64
        var samples = [Sample](repeating: Sample(r: 0, g: 0, b: 0, a: 0), count: hi * hi)
        guard let cg = trimmed.cgImage else { return nil }

        var pixels = [UInt8](repeating: 0, count: hi * hi * 4)
        guard let ctx = CGContext(
            data: &pixels, width: hi, height: hi, bitsPerComponent: 8, bytesPerRow: hi * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: hi, height: hi))
        ctx.translateBy(x: 0, y: CGFloat(hi))
        ctx.scaleBy(x: 1, y: -1)
        let aspect = CGFloat(cg.width) / CGFloat(cg.height)
        var draw = CGRect(x: 0, y: 0, width: hi, height: hi)
        if aspect > 1 {
            draw.size.height = CGFloat(hi) / aspect
            draw.origin.y = (CGFloat(hi) - draw.size.height) / 2
        } else {
            draw.size.width = CGFloat(hi) * aspect
            draw.origin.x = (CGFloat(hi) - draw.size.width) / 2
        }
        ctx.draw(cg, in: draw.insetBy(dx: 1, dy: 1))

        for row in 0..<hi {
            for col in 0..<hi {
                let dst = row * hi + col
                let srcRow = hi - 1 - row
                let o = (srcRow * hi + col) * 4
                let a = Int(pixels[o + 3])
                if a < 8 { continue }
                let af = CGFloat(a) / 255
                let r = min(255, Int(CGFloat(pixels[o]) / af))
                let g = min(255, Int(CGFloat(pixels[o + 1]) / af))
                let b = min(255, Int(CGFloat(pixels[o + 2]) / af))
                let peak = max(r, max(g, b))
                var s = Sample()
                s.r = r; s.g = g; s.b = b; s.a = a; s.peak = peak
                samples[dst] = s
            }
        }

        var lit = [Bool](repeating: false, count: cols * rows)
        for row in 0..<rows {
            for col in 0..<cols {
                let x0 = col * hi / cols, x1 = max(x0 + 1, (col + 1) * hi / cols)
                let y0 = row * hi / rows, y1 = max(y0 + 1, (row + 1) * hi / rows)
                for y in y0..<y1 {
                    for x in x0..<x1 {
                        let s = samples[y * hi + x]
                        if s.a > 44 && s.peak > 72 { lit[row * cols + col] = true; break }
                    }
                    if lit[row * cols + col] { break }
                }
            }
        }
        return Grid(cols: cols, rows: rows, lit: lit)
    }
}
