import Foundation
import UIKit
import SwiftUI

/// Maps an ICAO aircraft type designator (e.g. "A320", "B77W", "E75L", "DH8D")
/// to a top-down aircraft image asset in the catalog.
///
/// The asset set is intentionally small (one icon per visual family). Many ICAO
/// designators therefore collapse onto the same image — an A321neo ("A21N") and
/// an A321 both use `ac_a321`, every 737 variant uses `ac_b737`, and so on.
///
/// Lookup order:
///   1. Exact designator match (fast path for the common fleet).
///   2. Family fallback by leading characters (covers rare variants and any new
///      designators the data source emits without a code change).
/// Returns `nil` when nothing sensible matches, so callers can show a generic pin.
enum AircraftIcon {

    /// Resolve an ICAO type designator to an image asset name, or `nil`.
    static func assetName(for icaoType: String) -> String? {
        let code = icaoType.uppercased().trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return nil }
        if let exact = exact[code] { return exact }
        return familyFallback(code)
    }

    /// Bundled top-down model for the medium widget. Nose points north (up). `nil` when no art exists.
    static func widgetModelImage(for icaoType: String) -> UIImage? {
        guard let name = assetName(for: icaoType) else { return nil }
        return widgetModelImage(named: name)
    }

    static func widgetModelImage(named asset: String) -> UIImage? {
        guard let raw = UIImage(named: asset) else { return nil }
        return raw.trimmingTransparentBorder()
    }

    static func hasWidgetModel(for icaoType: String) -> Bool {
        assetName(for: icaoType) != nil
    }

    // MARK: - Map pin size (screen-space scale only; unrelated to AIRCRAFT_DB specs)

    /// Relative size tier for map pins — mirrors FlightRadar-style visual distinction.
    /// Scales are tuned for mobile: ~20 pt smallest / ~27 pt largest at the Large baseline.
    enum MapSizeCategory: CaseIterable {
        case small, medium, large, extraLarge

        var scale: CGFloat {
            switch self {
            case .small:      return 0.87   // ~20 pt — GA / bizjets
            case .medium:     return 0.94   // ~22 pt — regional & turboprop
            case .large:      return 1.00   //  23 pt — narrow-body baseline
            case .extraLarge: return 1.18   // ~27 pt — wide-body
            }
        }
    }

    /// Map pin scale multiplier for an ICAO type. Unknown types default to `.large`.
    static func mapScale(for icaoType: String) -> CGFloat {
        mapSizeCategory(for: icaoType).scale
    }

    static func mapSizeCategory(for icaoType: String) -> MapSizeCategory {
        guard let asset = assetName(for: icaoType) else { return .large }
        return sizeByAsset[asset] ?? .large
    }

    private static let sizeByAsset: [String: MapSizeCategory] = [
        // Small — GA / bizjets
        "ac_pipercub":   .small,
        "ac_cessna150":  .small,
        "ac_cessna152":  .small,
        "ac_cessna172":  .small,
        "ac_citation":   .small,
        // Medium — regional jets & turboprops
        "ac_erj135":     .medium,
        "ac_erj145":     .medium,
        "ac_e170":       .medium,
        "ac_e175":       .medium,
        "ac_e190":       .medium,
        "ac_e195":       .medium,
        "ac_atr42":      .medium,
        "ac_atr72":      .medium,
        "ac_dash8":      .medium,
        // Large — narrow-body (map baseline)
        "ac_a220":       .large,
        "ac_a320":       .large,
        "ac_a321":       .large,
        "ac_b707":       .large,
        "ac_b737":       .large,
        "ac_b757":       .large,
        // Extra-large — wide-body
        "ac_a310":       .extraLarge,
        "ac_a330":       .extraLarge,
        "ac_a340":       .extraLarge,
        "ac_a350":       .extraLarge,
        "ac_a380":       .extraLarge,
        "ac_b747":       .extraLarge,
        "ac_b767":       .extraLarge,
        "ac_b777":       .extraLarge,
        "ac_b787":       .extraLarge,
    ]

    // MARK: - Exact designators (real-world fleet)

    private static let exact: [String: String] = [
        // ── Airbus narrow-body ──
        "A318": "ac_a320", "A319": "ac_a320", "A320": "ac_a320",
        "A19N": "ac_a320", "A20N": "ac_a320",            // A319neo / A320neo
        "A321": "ac_a321", "A21N": "ac_a321",            // A321 / A321neo
        // ── Airbus A220 (ex-Bombardier C Series) ──
        "BCS1": "ac_a220", "BCS3": "ac_a220", "A220": "ac_a220",
        // ── Airbus wide-body ──
        "A306": "ac_a310", "A30B": "ac_a310", "A310": "ac_a310",
        "A332": "ac_a330", "A333": "ac_a330", "A337": "ac_a330",
        "A338": "ac_a330", "A339": "ac_a330",            // A330-800/900neo
        "A342": "ac_a340", "A343": "ac_a340", "A345": "ac_a340", "A346": "ac_a340",
        "A359": "ac_a350", "A35K": "ac_a350", "A351": "ac_a350",
        "A388": "ac_a380",

        // ── Boeing ──
        "B701": "ac_b707", "B703": "ac_b707",
        "B731": "ac_b737", "B732": "ac_b737", "B733": "ac_b737", "B734": "ac_b737",
        "B735": "ac_b737", "B736": "ac_b737", "B737": "ac_b737", "B738": "ac_b737",
        "B739": "ac_b737",
        "B37M": "ac_b737", "B38M": "ac_b737", "B39M": "ac_b737", "B3XM": "ac_b737", // 737 MAX
        "B741": "ac_b747", "B742": "ac_b747", "B743": "ac_b747", "B744": "ac_b747",
        "B748": "ac_b747", "B74S": "ac_b747", "BLCF": "ac_b747",
        "B752": "ac_b757", "B753": "ac_b757",
        "B762": "ac_b767", "B763": "ac_b767", "B764": "ac_b767",
        "B772": "ac_b777", "B773": "ac_b777", "B77L": "ac_b777", "B77W": "ac_b777",
        "B778": "ac_b777", "B779": "ac_b777",
        "B788": "ac_b787", "B789": "ac_b787", "B78X": "ac_b787",

        // ── Embraer ──
        "E170": "ac_e170", "E70": "ac_e170",
        "E175": "ac_e175", "E75L": "ac_e175", "E75S": "ac_e175",
        "E190": "ac_e190", "E290": "ac_e190", "E90": "ac_e190",  // E190 / E190-E2
        "E195": "ac_e195", "E295": "ac_e195", "E95": "ac_e195",  // E195 / E195-E2
        "E135": "ac_erj135", "E35L": "ac_erj135",
        "E145": "ac_erj145", "E45X": "ac_erj145", "E140": "ac_erj145",

        // ── Bombardier CRJ (rear-engine regional jet → closest is ERJ-145) ──
        "CRJ1": "ac_erj145", "CRJ2": "ac_erj145", "CRJ7": "ac_erj145",
        "CRJ9": "ac_erj145", "CRJX": "ac_erj145",

        // ── Turboprops ──
        "AT43": "ac_atr42", "AT44": "ac_atr42", "AT45": "ac_atr42", "AT46": "ac_atr42",
        "AT72": "ac_atr72", "AT73": "ac_atr72", "AT75": "ac_atr72", "AT76": "ac_atr72",
        "DH8A": "ac_dash8", "DH8B": "ac_dash8", "DH8C": "ac_dash8", "DH8D": "ac_dash8",

        // ── General aviation / bizjets ──
        "C150": "ac_cessna150",
        "C152": "ac_cessna152",
        "C172": "ac_cessna172", "C72R": "ac_cessna172",
        "C182": "ac_cessna172", "C206": "ac_cessna172", "C208": "ac_cessna172",
        "C25A": "ac_citation", "C25B": "ac_citation", "C25C": "ac_citation",
        "C56X": "ac_citation", "C680": "ac_citation", "C68A": "ac_citation",
        "C700": "ac_citation", "C750": "ac_citation",
        "PA18": "ac_pipercub", "J3":  "ac_pipercub",
    ]

    // MARK: - Family fallback

    /// Best-effort match for designators not in `exact`, using leading characters.
    private static func familyFallback(_ code: String) -> String? {
        // Airbus
        if code.hasPrefix("A38") { return "ac_a380" }
        if code.hasPrefix("A35") { return "ac_a350" }
        if code.hasPrefix("A34") { return "ac_a340" }
        if code.hasPrefix("A33") { return "ac_a330" }
        if code.hasPrefix("A31") || code.hasPrefix("A30") { return "ac_a310" }
        if code.hasPrefix("A32") || code.hasPrefix("A21") || code.hasPrefix("A20")
            || code.hasPrefix("A19") || code.hasPrefix("A18") {
            return code.contains("21") ? "ac_a321" : "ac_a320"
        }
        if code.hasPrefix("BCS") { return "ac_a220" }

        // Boeing
        if code.hasPrefix("B74") { return "ac_b747" }
        if code.hasPrefix("B78") { return "ac_b787" }
        if code.hasPrefix("B77") { return "ac_b777" }
        if code.hasPrefix("B76") { return "ac_b767" }
        if code.hasPrefix("B75") { return "ac_b757" }
        if code.hasPrefix("B73") || code.hasPrefix("B37") || code.hasPrefix("B38")
            || code.hasPrefix("B39") { return "ac_b737" }
        if code.hasPrefix("B70") { return "ac_b707" }

        // Embraer
        if code.hasPrefix("E19") || code.hasPrefix("E29") { return "ac_e190" }
        if code.hasPrefix("E17") || code.hasPrefix("E75") || code.hasPrefix("E70") { return "ac_e175" }
        if code.hasPrefix("E13") || code.hasPrefix("E35") { return "ac_erj135" }
        if code.hasPrefix("E14") || code.hasPrefix("E45") || code.hasPrefix("ERJ") { return "ac_erj145" }

        // Bombardier
        if code.hasPrefix("CRJ") { return "ac_erj145" }
        if code.hasPrefix("DH8") || code.hasPrefix("DHC8") { return "ac_dash8" }

        // ATR
        if code.hasPrefix("AT7") { return "ac_atr72" }
        if code.hasPrefix("AT4") || code.hasPrefix("AT5") { return "ac_atr42" }

        // GA / bizjets
        if code.hasPrefix("C15") { return "ac_cessna152" }
        if code.hasPrefix("C17") || code.hasPrefix("C18") || code.hasPrefix("C20") { return "ac_cessna172" }
        if code.hasPrefix("C25") || code.hasPrefix("C5") || code.hasPrefix("C6")
            || code.hasPrefix("C68") || code.hasPrefix("C70") || code.hasPrefix("C75") { return "ac_citation" }
        if code.hasPrefix("PA18") { return "ac_pipercub" }

        return nil
    }

    // MARK: - Map pin tone (sampled from bundled 3D top-down renders)

    private static var toneCache: [String: UIColor] = [:]
    private static let referenceAsset = "ac_b737"

    /// Fuselage tone for SF Symbol fallbacks — matches the paired 3D asset when known.
    static func mapPinUIColor(for icaoType: String) -> UIColor {
        let asset = assetName(for: icaoType) ?? referenceAsset
        return fuselageTone(forAsset: asset)
    }

    static func mapPinColor(for icaoType: String) -> Color {
        Color(mapPinUIColor(for: icaoType))
    }

    private static func fuselageTone(forAsset asset: String) -> UIColor {
        if let cached = toneCache[asset] { return cached }
        let raw = UIImage(named: asset) ?? UIImage(named: referenceAsset)
        let tone = raw?.trimmingTransparentBorder().highlightFuselageTone()
            ?? UIColor(white: 0.96, alpha: 1)
        toneCache[asset] = tone
        return tone
    }

    // MARK: - Outlined generic map pin (unknown / unmapped types)

    private static var outlinedGenericCache: [String: UIImage] = [:]
    private static let outlineStroke: CGFloat = 0.5
    /// Soft edge — matches the grey shadow lines on the 3D top-down renders.
    private static let outlineColor = UIColor(white: 0.30, alpha: 0.88)

    /// SF Symbol plane with a slim dark edge, tinted to match the reference 3D model family.
    static func genericOutlinedPinImage(tint: UIColor) -> UIImage {
        let key = tint.description
        if let cached = outlinedGenericCache[key] { return cached }
        let rendered = renderOutlinedAirplane(tint: tint)
        outlinedGenericCache[key] = rendered
        return rendered
    }

    private static func renderOutlinedAirplane(tint: UIColor) -> UIImage {
        let cfg = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        guard let sym = UIImage(systemName: "airplane", withConfiguration: cfg) else { return UIImage() }

        let outline = sym.withTintColor(outlineColor, renderingMode: .alwaysOriginal)
        let fill = sym.withTintColor(tint, renderingMode: .alwaysOriginal)
        let bleed = outlineStroke * 2 + 2
        let size = CGSize(width: sym.size.height + bleed, height: sym.size.width + bleed)

        return UIGraphicsImageRenderer(size: size).image { ctx in
            let c = ctx.cgContext
            c.translateBy(x: size.width / 2, y: size.height / 2)
            c.rotate(by: -.pi / 2)

            let rect = CGRect(x: -sym.size.width / 2, y: -sym.size.height / 2,
                              width: sym.size.width, height: sym.size.height)
            let offsets: [(CGFloat, CGFloat)] = [
                (-1, -1), (-1, 0), (-1, 1),
                (0, -1),           (0, 1),
                (1, -1),  (1, 0),  (1, 1),
            ]
            for (dx, dy) in offsets {
                c.saveGState()
                c.translateBy(x: dx * outlineStroke, y: dy * outlineStroke)
                outline.draw(in: rect)
                c.restoreGState()
            }
            // Subtle underside tint — echoes the soft grey shading on 3D models.
            let shade = sym.withTintColor(UIColor(white: 0.78, alpha: 0.55), renderingMode: .alwaysOriginal)
            c.saveGState()
            c.translateBy(x: 0.35, y: 0.45)
            shade.draw(in: rect)
            c.restoreGState()
            fill.draw(in: rect)
        }
    }
}

// MARK: - UIImage helpers (map pin colour sampling)

private extension UIImage {
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

    /// Highlight fuselage tone — bright top surfaces only, not shadow averages.
    func highlightFuselageTone(alphaThreshold: UInt8 = 24, minLuminance: CGFloat = 0.68) -> UIColor {
        guard let cg = cgImage else { return UIColor(white: 0.96, alpha: 1) }
        let w = 32, h = 32
        let bytesPerRow = w * 4
        var data = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &data, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return UIColor(white: 0.96, alpha: 1)
        }
        ctx.interpolationQuality = .medium
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, bCount: CGFloat = 0
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aCount: CGFloat = 0

        for i in stride(from: 0, to: data.count, by: 4) where data[i + 3] > alphaThreshold {
            let r = CGFloat(data[i]) / 255
            let g = CGFloat(data[i + 1]) / 255
            let b = CGFloat(data[i + 2]) / 255
            let lum = 0.299 * r + 0.587 * g + 0.114 * b
            ar += r; ag += g; ab += b; aCount += 1
            if lum >= minLuminance {
                br += r; bg += g; bb += b; bCount += 1
            }
        }
        guard aCount > 0 else { return UIColor(white: 0.96, alpha: 1) }

        let base: UIColor
        if bCount > 0 {
            base = UIColor(red: br / bCount, green: bg / bCount, blue: bb / bCount, alpha: 1)
        } else {
            base = UIColor(red: ar / aCount, green: ag / aCount, blue: ab / aCount, alpha: 1)
        }
        return base.matchedToModelHighlight()
    }

    /// Average colour of opaque pixels.
    func averageVisibleColor(alphaThreshold: UInt8 = 24) -> UIColor {
        guard let cg = cgImage else {
            return UIColor(red: 0.86, green: 0.89, blue: 0.92, alpha: 1)
        }
        let w = 32, h = 32
        let bytesPerRow = w * 4
        var data = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &data, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return UIColor(red: 0.86, green: 0.89, blue: 0.92, alpha: 1)
        }
        ctx.interpolationQuality = .medium
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, count: CGFloat = 0
        for i in stride(from: 0, to: data.count, by: 4) where data[i + 3] > alphaThreshold {
            r += CGFloat(data[i]) / 255
            g += CGFloat(data[i + 1]) / 255
            b += CGFloat(data[i + 2]) / 255
            count += 1
        }
        guard count > 0 else {
            return UIColor(red: 0.86, green: 0.89, blue: 0.92, alpha: 1)
        }
        return UIColor(red: r / count, green: g / count, blue: b / count, alpha: 1)
    }
}

private extension UIColor {
    /// Pulls fill colour up to the bright fuselage read of the 3D map assets.
    func matchedToModelHighlight() -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        let lum = 0.299 * r + 0.587 * g + 0.114 * b
        let minLum: CGFloat = 0.90
        guard lum < minLum else { return UIColor(red: r, green: g, blue: b, alpha: 1) }

        let t = min(1, 0.45 + (minLum - lum) * 1.8)
        let tr: CGFloat = 0.96, tg: CGFloat = 0.96, tb: CGFloat = 0.96
        return UIColor(
            red: r + (tr - r) * t,
            green: g + (tg - g) * t,
            blue: b + (tb - b) * t,
            alpha: 1
        )
    }
}
