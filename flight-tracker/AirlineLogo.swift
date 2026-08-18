import SwiftUI
import UIKit
import Combine

private let AIRLINE_IATA: [String: String] = [
    "ACA": "AC", "JZA": "AC", "ROU": "AC",
    "WJA": "WS", "WEN": "WS",
    "UAL": "UA", "DAL": "DL", "AAL": "AA", "SWA": "WN",
    "ASA": "AS", "SKW": "OO", "JBU": "B6", "HAL": "HA", "FFT": "F9",
    "BAW": "BA", "DLH": "LH", "AFR": "AF", "KLM": "KL",
    "UAE": "EK", "QTR": "QR", "ETD": "EY", "QFA": "QF", "CPA": "CX",
    "ANA": "NH", "JAL": "JL", "SIA": "SQ", "PAL": "PR",
    "RYR": "FR", "EZY": "U2", "TSC": "TS", "THY": "TK",
    "FIN": "AY", "SAS": "SK", "IBE": "IB", "TAP": "TP",
    "AZU": "AD", "LAM": "LA", "VOE": "Y4",
    "FDX": "FX", "UPS": "5X", "ANT": "4N", "PCO": "8P",
    "VOZ": "VA", "LAN": "LA", "CMP": "CM",
]

/// Lit / dim dots for LED-matrix logo rendering.
struct LEDDotGrid {
    let cols: Int
    let rows: Int
    let lit: [Bool]
}

enum AirlineLogo {
    /// Square airline symbols (Google Flights), not rectangular/wordmark art.
    static func urls(iata: String, displayPoints: CGFloat) -> [URL] {
        let code = iata.trimmingCharacters(in: .whitespaces).uppercased()
        guard code.count == 2 else { return [] }
        _ = displayPoints
        return [
            URL(string: "https://www.gstatic.com/flights/airline_logos/70px/\(code).png"),
            URL(string: "https://www.gstatic.com/flights/airline_logos/32px/\(code).png"),
            URL(string: "https://images.kiwi.com/airlines/128/\(code).png"),
        ].compactMap { $0 }
    }

    static func iataCode(from callsign: String) -> String? {
        let trimmed = callsign.trimmingCharacters(in: .whitespaces).uppercased()
        guard trimmed.count >= 3 else { return nil }
        return AIRLINE_IATA[String(trimmed.prefix(3))]
    }

    /// Carriers where the CDN symbol is poor at LED resolution — show IATA letters instead.
    private static let ledTextMarkIATA: Set<String> = ["WS"]

    static func prefersLEDTextMark(iata: String) -> Bool {
        ledTextMarkIATA.contains(iata.uppercased())
    }

    static func prefersLEDTextMark(callsign: String) -> Bool {
        guard let code = iataCode(from: callsign) else { return false }
        return prefersLEDTextMark(iata: code)
    }

    static func brandColor(for callsign: String) -> Color {
        let rgb = AirlineLEDCache.accessibleBrandRGB(callsign: callsign)
        return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    static func prefetch(callsign: String) {
        guard !prefersLEDTextMark(callsign: callsign),
              let iata = iataCode(from: callsign),
              let url = urls(iata: iata, displayPoints: 48).first else { return }
        URLSession.shared.dataTask(with: url).resume()
    }

    /// Rejects full-width text wordmarks (e.g. Kiwi "WESTJET" in a square).
    static func looksLikeTextWordmark(_ image: UIImage) -> Bool {
        let trimmed = image.trimmedToContent(padding: 0)
        let w = 48, h = 48
        let samples = renderSamples(trimmed, width: w, height: h)
        guard samples.count == w * h else { return true }

        var rowFill = [Int](repeating: 0, count: h)
        var total = 0
        for y in 0..<h {
            for x in 0..<w {
                let p = samples[y * w + x]
                let peak = max(p.r, max(p.g, p.b))
                guard p.a > 44, peak > 48 else { continue }
                rowFill[y] += 1
                total += 1
            }
        }
        guard total > 60 else { return false }

        let wideRows = rowFill.filter { $0 >= Int(Double(w) * 0.72) }.count
        if wideRows >= 10 { return true }

        let grid = rasterize(image)
        let lit = grid.lit.filter { $0 }.count
        let f = Double(lit) / Double(grid.lit.count)
        return f > 0.84
    }

    @MainActor
    static func loadImage(callsign: String, displayPoints: CGFloat) async -> UIImage? {
        guard let iata = iataCode(from: callsign) else { return nil }
        for url in urls(iata: iata, displayPoints: displayPoints) {
            do {
                let (data, resp) = try await URLSession.shared.data(from: url)
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
                      let img = UIImage(data: data), img.size.width > 1 else { continue }
                return img
            } catch { continue }
        }
        return nil
    }

    /// Downsample logo → LED dot grid. Handles white-on-color, color-on-white, and dark-on-color marks.
    static func rasterize(_ image: UIImage, cols: Int = 32, rows: Int = 32) -> LEDDotGrid {
        let trimmed = image.trimmedToContent(padding: 2)
        let hi = 64
        let samples = renderSamples(trimmed, width: hi, height: hi)
        return downsampleMask(samples, sourceWidth: hi, sourceHeight: hi, cols: cols, rows: rows)
    }

    /// Pick the best LED mask among candidate square-symbol images.
    static func rasterizeBest(_ images: [UIImage], cols: Int = 32, rows: Int = 32) -> LEDDotGrid {
        var best: LEDDotGrid?
        var bestScore = -Double.infinity
        for img in images {
            if looksLikeTextWordmark(img) { continue }
            let grid = rasterize(img, cols: cols, rows: rows)
            let s = maskQualityScore(grid)
            if s > bestScore {
                bestScore = s
                best = grid
            }
        }
        return best ?? LEDDotGrid(cols: cols, rows: rows, lit: [Bool](repeating: false, count: cols * rows))
    }

    private static func maskQualityScore(_ grid: LEDDotGrid) -> Double {
        let lit = grid.lit.filter { $0 }.count
        let total = grid.lit.count
        guard total > 0 else { return -10 }
        let f = Double(lit) / Double(total)
        if f < 0.05 || f > 0.68 { return -10 }
        return -abs(f - 0.24)
    }

    static func isGoodSymbolMask(_ grid: LEDDotGrid) -> Bool {
        maskQualityScore(grid) > -5
    }

    // MARK: - Raster pipeline

    private struct PixelSample {
        var r: Int
        var g: Int
        var b: Int
        var a: Int
    }

    private static func renderSamples(_ image: UIImage, width: Int, height: Int) -> [PixelSample] {
        var out = [PixelSample](repeating: PixelSample(r: 0, g: 0, b: 0, a: 0), count: width * height)
        guard let cg = image.cgImage else { return out }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return out }

        ctx.interpolationQuality = .high
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1, y: -1)

        let aspect = CGFloat(cg.width) / CGFloat(cg.height)
        var draw = CGRect(x: 0, y: 0, width: width, height: height)
        if aspect > 1 {
            draw.size.height = CGFloat(width) / aspect
            draw.origin.y = (CGFloat(height) - draw.size.height) / 2
        } else {
            draw.size.width = CGFloat(height) * aspect
            draw.origin.x = (CGFloat(width) - draw.size.width) / 2
        }
        draw = draw.insetBy(dx: 1, dy: 1)
        ctx.draw(cg, in: draw)

        // Bitmap context rows are bottom-up; normalize so out[row] is top-down.
        for row in 0..<height {
            for col in 0..<width {
                let dst = row * width + col
                let srcRow = height - 1 - row
                let o = (srcRow * width + col) * 4
                let a = Int(pixels[o + 3])
                if a < 8 {
                    out[dst] = PixelSample(r: 0, g: 0, b: 0, a: 0)
                    continue
                }
                let af = CGFloat(a) / 255
                out[dst] = PixelSample(
                    r: min(255, Int(CGFloat(pixels[o]) / af)),
                    g: min(255, Int(CGFloat(pixels[o + 1]) / af)),
                    b: min(255, Int(CGFloat(pixels[o + 2]) / af)),
                    a: a
                )
            }
        }
        return out
    }

    private static func downsampleMask(
        _ samples: [PixelSample],
        sourceWidth sw: Int,
        sourceHeight sh: Int,
        cols: Int,
        rows: Int
    ) -> LEDDotGrid {
        guard sw > 0, sh > 0, samples.count == sw * sh else {
            return LEDDotGrid(cols: cols, rows: rows, lit: [Bool](repeating: false, count: cols * rows))
        }

        let hiMask = extractForegroundMask(samples: samples, width: sw, height: sh)
        var lit = [Bool](repeating: false, count: cols * rows)
        for row in 0..<rows {
            for col in 0..<cols {
                let x0 = col * sw / cols
                let x1 = max(x0 + 1, (col + 1) * sw / cols)
                let y0 = row * sh / rows
                let y1 = max(y0 + 1, (row + 1) * sh / rows)
                var any = false
                for y in y0..<y1 {
                    for x in x0..<x1 {
                        if hiMask[y * sw + x] { any = true; break }
                    }
                    if any { break }
                }
                lit[row * cols + col] = any
            }
        }
        lit = pruneIsolatedDots(lit, cols: cols, rows: rows)
        return LEDDotGrid(cols: cols, rows: rows, lit: lit)
    }

    /// Symbol drawn on black (Google Flights style): use alpha + brightness.
    private static func extractForegroundMask(samples: [PixelSample], width: Int, height: Int) -> [Bool] {
        var mask = [Bool](repeating: false, count: width * height)
        for i in 0..<samples.count {
            let p = samples[i]
            let peak = max(p.r, max(p.g, p.b))
            mask[i] = p.a > 44 && peak > 72
        }
        return mask
    }

    private static func pruneIsolatedDots(_ lit: [Bool], cols: Int, rows: Int) -> [Bool] {
        var out = lit
        for row in 0..<rows {
            for col in 0..<cols {
                let i = row * cols + col
                guard lit[i] else { continue }
                var neighbors = 0
                for dy in -1...1 {
                    for dx in -1...1 where dx != 0 || dy != 0 {
                        let nr = row + dy, nc = col + dx
                        guard nr >= 0, nc >= 0, nr < rows, nc < cols else { continue }
                        if lit[nr * cols + nc] { neighbors += 1 }
                    }
                }
                if neighbors == 0 { out[i] = false }
            }
        }
        return out
    }

}

// MARK: - Trim transparent margins

private extension UIImage {
    func trimmedToContent(padding: CGFloat = 0) -> UIImage {
        preparedAirlineLogo(padding: padding)
    }
}

// MARK: - LED IATA text mark (e.g. WestJet → WS)

struct LEDAirlineTextMarkView: View {
    let iata: String
    let color: Color
    let size: CGFloat

    var body: some View {
        LEDLabel(iata, dotPt: size / 7.2, color: color)
            .frame(width: size, height: size)
    }
}

// MARK: - LED dot-matrix logo (airport board style)

struct LEDMatrixLogoView: View {
    let grid: LEDDotGrid?
    let color: Color
    let size: CGFloat
    var showDimDots: Bool = true

    var body: some View {
        Canvas { ctx, canvasSize in
            let cols = CGFloat(grid?.cols ?? 1)
            let rows = CGFloat(grid?.rows ?? 1)
            let pitch = min(canvasSize.width / cols, canvasSize.height / rows)
            let dotR = pitch * 0.38
            let dimR = pitch * 0.20
            let x0 = (canvasSize.width - cols * pitch) / 2 + pitch * 0.5
            let y0 = (canvasSize.height - rows * pitch) / 2 + pitch * 0.5

            if let grid {
                for row in 0..<grid.rows {
                    for col in 0..<grid.cols {
                        let cx = x0 + CGFloat(col) * pitch
                        let cy = y0 + CGFloat(row) * pitch
                        let on = grid.lit[row * grid.cols + col]
                        if on {
                            let glow = Path(ellipseIn: CGRect(
                                x: cx - dotR * 1.35, y: cy - dotR * 1.35,
                                width: dotR * 2.7, height: dotR * 2.7))
                            ctx.fill(glow, with: .color(color.opacity(0.22)))
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2)),
                                with: .color(color))
                        } else if showDimDots {
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: cx - dimR, y: cy - dimR, width: dimR * 2, height: dimR * 2)),
                                with: .color(color.opacity(0.06)))
                        }
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

@MainActor
private final class AirlineLogoModel: ObservableObject {
    @Published var grid: LEDDotGrid?
    @Published var isLoading = false

    private var task: Task<Void, Never>?

    func load(callsign: String, size: CGFloat) {
        task?.cancel()
        grid = nil
        guard AirlineLogo.iataCode(from: callsign) != nil else { return }
        isLoading = true
        task = Task {
            var images: [UIImage] = []
            if let iata = AirlineLogo.iataCode(from: callsign) {
                for url in AirlineLogo.urls(iata: iata, displayPoints: size) {
                    guard !Task.isCancelled else { return }
                    guard let img = await loadOne(url: url) else { continue }
                    guard !AirlineLogo.looksLikeTextWordmark(img) else { continue }
                    images.append(img)
                    // Google Flights square symbol is first URL; stop if it rasterizes well.
                    if url.host?.contains("gstatic") == true {
                        let trial = AirlineLogo.rasterize(img)
                        if AirlineLogo.isGoodSymbolMask(trial) { break }
                    }
                }
            }
            guard !Task.isCancelled else { return }
            if !images.isEmpty {
                grid = AirlineLogo.rasterizeBest(images)
            }
            isLoading = false
        }
    }

    private func loadOne(url: URL) async -> UIImage? {
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let img = UIImage(data: data), img.size.width > 1 else { return nil }
            return img
        } catch {
            return nil
        }
    }

    deinit { task?.cancel() }
}

/// Airline logo rendered as an LED matrix (shape from CDN, color = brand).
struct AirlineLogoView: View {
    let callsign: String
    var size: CGFloat = 48

    @StateObject private var model = AirlineLogoModel()

    private var brand: Color { AirlineLogo.brandColor(for: callsign) }
    private var iata: String? { AirlineLogo.iataCode(from: callsign) }
    private var useTextMark: Bool { AirlineLogo.prefersLEDTextMark(callsign: callsign) }
    private var bundledLogo: UIImage? {
        AirlineLogoAsset.preparedImage(forCallsign: callsign)
    }

    var body: some View {
        ZStack {
            if let logo = bundledLogo {
                Image(uiImage: logo)
                    .resizable()
                    .interpolation(.medium)
                    .scaledToFit()
                    .padding(size * 0.06)
                    .frame(width: size, height: size)
            } else if useTextMark, let code = iata {
                LEDAirlineTextMarkView(iata: code, color: brand, size: size)
            } else if let grid = model.grid {
                LEDMatrixLogoView(grid: grid, color: brand, size: size)
            } else if model.isLoading {
                LEDMatrixLogoView(grid: nil, color: brand, size: size)
                    .overlay {
                        ProgressView().scaleEffect(0.55).tint(brand)
                    }
            } else if let code = AirlineLogo.iataCode(from: callsign) {
                LEDLabel(code, dotPt: size / 9, color: brand)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: "airplane")
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(AircraftIcon.mapPinColor(for: ""))
                    .frame(width: size, height: size)
            }
        }
        .onAppear {
            guard bundledLogo == nil, !useTextMark else { return }
            model.load(callsign: callsign, size: size)
        }
        .onChange(of: callsign) { _, new in
            guard AirlineLogoAsset.assetName(forCallsign: new) == nil,
                  !AirlineLogo.prefersLEDTextMark(callsign: new) else { return }
            model.load(callsign: new, size: size)
        }
    }
}
