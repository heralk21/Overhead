import CoreLocation
import SwiftUI
import UIKit

/// Camera sky scanner — Code Scanner–style frame, 1 km range only.
struct CameraScanView: View {
    let flights: [Flight]
    let userCoordinate: CLLocationCoordinate2D?
    let onClose: () -> Void
    let onIdentified: (Flight) -> Void

    @StateObject private var look = CameraLookTracker()
    @State private var fov: Double = 62
    @State private var cameraReady = false
    @State private var cameraError: String?
    @State private var trackingId: String?
    @State private var trackingSince: Date?
    @State private var didIdentify = false

    private let lockHold: TimeInterval = 0.7

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08, paused: didIdentify)) { timeline in
            GeometryReader { geo in
                let finder = Self.viewfinderRect(in: geo.size)
                let nearbyCount = nearbyFlights.count
                let targets = currentTargets(in: geo.size)
                let locked = SkyTargeting.lockCandidate(in: targets, viewfinder: finder)

                ZStack {
                    CameraPreviewView(
                        fieldOfView: $fov,
                        cameraReady: $cameraReady,
                        cameraError: $cameraError
                    )
                    .ignoresSafeArea()

                    ScannerOverlay(
                        viewfinder: finder,
                        locked: locked != nil,
                        scanning: cameraError == nil && nearbyCount > 0 && locked == nil,
                        date: timeline.date
                    )

                    VStack(spacing: 0) {
                        Spacer()
                        caption(locked: locked, nearbyCount: nearbyCount)
                            .padding(.bottom, 12)
                    }
                    .padding(.bottom, geo.safeAreaInsets.bottom)

                    CloseButton(action: onClose, overLivePreview: true)
                        .padding(
                            .top,
                            (geo.safeAreaInsets.top > 0 ? geo.safeAreaInsets.top : 54)
                                + CardChrome.closeBorderInset
                        )
                        .padding(.trailing, CardLayout.screenMargin + CardChrome.closeBorderInset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
                .onChange(of: timeline.date) { _, _ in
                    updateLock(locked)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { look.start() }
        .onDisappear { look.stop() }
    }

    private var nearbyFlights: [Flight] {
        guard let origin = userCoordinate else { return [] }
        let here = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        return flights.filter {
            here.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))
                <= SkyTargeting.scanRadiusMeters
        }
    }

    private func currentTargets(in size: CGSize) -> [SkyTarget] {
        guard let origin = userCoordinate,
              let az = look.azimuth,
              let el = look.elevation else { return [] }
        return SkyTargeting.targets(
            flights: flights,
            from: origin,
            lookAzimuth: az,
            lookElevation: el,
            viewSize: size,
            fovHorizontal: fov
        )
    }

    private static func viewfinderRect(in size: CGSize) -> CGRect {
        let side = min(size.width, size.height) * 0.62
        return CGRect(
            x: (size.width - side) / 2,
            y: (size.height - side) / 2 - 24,
            width: side,
            height: side
        )
    }

    @ViewBuilder
    private func caption(locked: SkyTarget?, nearbyCount: Int) -> some View {
        let text: String = {
            if cameraError != nil { return "Camera access is required to scan" }
            if userCoordinate == nil { return "Finding your location…" }
            if nearbyCount == 0 { return "No aircraft within 1 km" }
            if let locked {
                return "Identifying \(displayCallsign(for: locked.flight))"
            }
            return "Center an aircraft in the frame"
        }()

        Text(text)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Color.white.opacity(0.88))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .accessibilityLabel(text)
    }

    private func updateLock(_ locked: SkyTarget?) {
        guard !didIdentify else { return }
        let id = locked?.flight.id
        if id != trackingId {
            trackingId = id
            trackingSince = id == nil ? nil : Date()
            return
        }
        guard let locked, let start = trackingSince else { return }
        if Date().timeIntervalSince(start) >= lockHold {
            didIdentify = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onIdentified(locked.flight)
        }
    }
}

// MARK: - Overlay chrome (cutout + corners + sweep)

private struct ScannerOverlay: View {
    let viewfinder: CGRect
    let locked: Bool
    let scanning: Bool
    let date: Date

    private let cornerRadius: CGFloat = 22

    var body: some View {
        ZStack {
            DimmedCutout(rect: viewfinder, cornerRadius: cornerRadius)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(locked ? 0.42 : 0.16), lineWidth: 0.5)
                .frame(width: viewfinder.width, height: viewfinder.height)
                .position(x: viewfinder.midX, y: viewfinder.midY)
            ScannerCorners(rect: viewfinder, emphasized: locked)
            if scanning {
                ScanSweep(frame: viewfinder, date: date)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct DimmedCutout: View {
    let rect: CGRect
    let cornerRadius: CGFloat

    var body: some View {
        Canvas { ctx, size in
            var path = Path(CGRect(origin: .zero, size: size))
            path.addRoundedRect(
                in: rect,
                cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
            )
            ctx.fill(path, with: .color(Color.black.opacity(0.52)), style: FillStyle(eoFill: true))
        }
        .ignoresSafeArea()
    }
}

private struct ScannerCorners: View {
    let rect: CGRect
    let emphasized: Bool

    private let length: CGFloat = 28
    private let line: CGFloat = 3
    private let inset: CGFloat = 1.5

    var body: some View {
        let color = Color.white.opacity(emphasized ? 1 : 0.94)
        Canvas { ctx, _ in
            let r = rect.insetBy(dx: inset, dy: inset)
            let pts: [(CGPoint, CGPoint, CGPoint)] = [
                (CGPoint(x: r.minX, y: r.minY + length), CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.minX + length, y: r.minY)),
                (CGPoint(x: r.maxX - length, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.minY + length)),
                (CGPoint(x: r.maxX, y: r.maxY - length), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.maxX - length, y: r.maxY)),
                (CGPoint(x: r.minX + length, y: r.maxY), CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY - length)),
            ]
            for (a, b, c) in pts {
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                path.addLine(to: c)
                ctx.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: line, lineCap: .square, lineJoin: .miter)
                )
            }
        }
    }
}

private struct ScanSweep: View {
    let frame: CGRect
    let date: Date

    var body: some View {
        let period = 2.8
        let t = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period * 2)
        let linear = t < period ? t / period : 2 - t / period
        let p = CGFloat(0.5 - 0.5 * cos(linear * .pi))
        let y = frame.minY + 14 + p * max(frame.height - 28, 1)

        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.72),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: max(frame.width - 28, 0), height: 1)
            .shadow(color: Color.white.opacity(0.35), radius: 4, y: 0)
            .position(x: frame.midX, y: y)
    }
}
