import SwiftUI
import UIKit

// MARK: - Step 1: Hardware display corner radius

extension UIScreen {
    /// Squircle corner radius of the physical display panel.
    /// Returns `0` on rectangular screens (e.g. iPhone SE) or when the private key is unavailable.
    ///
    /// Note: `_displayCornerRadius` is undocumented. It is widely used for concentric UI
    /// but may require review for App Store submission.
    var displayCornerRadius: CGFloat {
        guard responds(to: Selector(("_displayCornerRadius"))) else { return 0 }
        guard let value = value(forKey: "_displayCornerRadius") as? CGFloat, value > 0 else {
            return 0
        }
        return value
    }
}

// MARK: - Concentric radius math

enum CardCornerMetrics {
    /// [Card radius] = [Screen radius] − [Side padding]
    static func concentricRadius(
        sidePadding: CGFloat,
        screenRadius: CGFloat = UIScreen.main.displayCornerRadius
    ) -> CGFloat {
        max(0, screenRadius - sidePadding)
    }

    /// Radii for a bottom-anchored glass popup inset from the screen sides.
    static func popupRadii(
        sidePadding: CGFloat,
        screenRadius: CGFloat = UIScreen.main.displayCornerRadius
    ) -> (top: CGFloat, bottom: CGFloat) {
        let bottom = concentricRadius(sidePadding: sidePadding, screenRadius: screenRadius)
        // Bottom follows the display curve; top uses a modest radius so headings aren't clipped.
        let top: CGFloat = bottom > 0 ? 28 : 16
        return (top, bottom)
    }

    @available(iOS 16.0, *)
    static func popupShape(
        sidePadding: CGFloat,
        screenRadius: CGFloat = UIScreen.main.displayCornerRadius
    ) -> UnevenRoundedRectangle {
        let r = popupRadii(sidePadding: sidePadding, screenRadius: screenRadius)
        return UnevenRoundedRectangle(
            topLeadingRadius: r.top,
            bottomLeadingRadius: r.bottom,
            bottomTrailingRadius: r.bottom,
            topTrailingRadius: r.top,
            style: .continuous
        )
    }

    /// [Nested radius] = [Parent radius] − [Inset from parent edge]
    static func nestedRadius(parentRadius: CGFloat, inset: CGFloat) -> CGFloat {
        max(0, parentRadius - inset)
    }

    /// Uniform corner radius for the quick-card swipe footer (all edges match the card bottom arc).
    static func detailFooterCornerRadius(
        cardSidePadding: CGFloat = CardLayout.screenMargin,
        insetFromCard: CGFloat = 0,
        screenRadius: CGFloat = UIScreen.main.displayCornerRadius
    ) -> CGFloat {
        let cardBottom = popupRadii(sidePadding: cardSidePadding, screenRadius: screenRadius).bottom
        return nestedRadius(parentRadius: cardBottom, inset: insetFromCard)
    }

    @available(iOS 16.0, *)
    static func detailFooterShape(
        cardSidePadding: CGFloat = CardLayout.screenMargin,
        insetFromCard: CGFloat = 0,
        screenRadius: CGFloat = UIScreen.main.displayCornerRadius
    ) -> UnevenRoundedRectangle {
        let r = detailFooterCornerRadius(
            cardSidePadding: cardSidePadding,
            insetFromCard: insetFromCard,
            screenRadius: screenRadius
        )
        return UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: r,
                bottomLeading: r,
                bottomTrailing: r,
                topTrailing: r
            ),
            style: .continuous
        )
    }
}

// MARK: - Step 2: SwiftUI glass popup card

struct GlassPopupBackground: View {
    var sidePadding: CGFloat = CardLayout.screenMargin

    var body: some View {
        if #available(iOS 16.0, *) {
            let shape = CardCornerMetrics.popupShape(sidePadding: sidePadding)
            shape
                .fill(.ultraThinMaterial)
                .overlay {
                    shape.stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                }
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }
}

struct GlassPopupCardModifier: ViewModifier {
    var horizontalMargin: CGFloat = CardLayout.screenMargin
    /// When true, bottom safe-area inset is owned by the swipe footer instead of the card shell.
    var anchorsFooter: Bool = false

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            let shape = CardCornerMetrics.popupShape(sidePadding: horizontalMargin)
            content
                .padding(.top, CardChrome.sheetContentTopInset)
                .modifier(PopupBottomInsetModifier(anchorsFooter: anchorsFooter))
                .background { GlassPopupBackground(sidePadding: horizontalMargin) }
                .clipShape(shape)
                .contentShape(shape)
                .shadow(color: Color.black.opacity(0.32), radius: 22, x: 0, y: -6)
        } else {
            content
                .padding(.top, CardChrome.sheetContentTopInset)
                .modifier(PopupBottomInsetModifier(anchorsFooter: anchorsFooter))
                .glassCard(radius: 16)
                .shadow(color: Color.black.opacity(0.32), radius: 22, x: 0, y: -6)
        }
    }
}

private struct PopupBottomInsetModifier: ViewModifier {
    let anchorsFooter: Bool

    func body(content: Content) -> some View {
        if anchorsFooter {
            content
        } else {
            content
                .safeAreaPadding(.bottom)
                .padding(.bottom, CardChrome.sheetContentBottomInset)
        }
    }
}

extension View {
    /// Glass popup styling with hardware-matched concentric bottom corners.
    func glassPopupCard(
        horizontalMargin: CGFloat = CardLayout.screenMargin,
        anchorsFooter: Bool = false
    ) -> some View {
        modifier(GlassPopupCardModifier(horizontalMargin: horizontalMargin, anchorsFooter: anchorsFooter))
    }
}

// MARK: - Step 2 (UIKit): concentric continuous corners

/// UIKit panel with squircle corners matched to the device display.
/// Bottom corners use [screen radius − horizontal inset]; top corners are slightly larger.
final class ConcentricGlassPanelView: UIView {
    var horizontalInset: CGFloat = CardLayout.screenMargin {
        didSet { setNeedsLayout() }
    }

    private let fillView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let borderLayer = CAShapeLayer()
    private let maskLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        addSubview(fillView)
        NSLayoutConstraint.activate([
            fillView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fillView.trailingAnchor.constraint(equalTo: trailingAnchor),
            fillView.topAnchor.constraint(equalTo: topAnchor),
            fillView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.32
        layer.shadowRadius = 22
        layer.shadowOffset = CGSize(width: 0, height: -6)
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.12).cgColor
        borderLayer.lineWidth = 0.5
        layer.addSublayer(borderLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radii = CardCornerMetrics.popupRadii(sidePadding: horizontalInset)
        let path = UIBezierPath.continuousRoundedRect(
            bounds,
            topLeadingRadius: radii.top,
            bottomLeadingRadius: radii.bottom,
            bottomTrailingRadius: radii.bottom,
            topTrailingRadius: radii.top
        )
        maskLayer.path = path.cgPath
        fillView.layer.mask = maskLayer
        borderLayer.path = path.cgPath
        borderLayer.frame = bounds
        layer.shadowPath = path.cgPath
    }
}

// MARK: - UIBezierPath helper (uneven continuous corners)

extension UIBezierPath {
    /// Approximates `UnevenRoundedRectangle(style: .continuous)` using arc segments.
    static func continuousRoundedRect(
        _ rect: CGRect,
        topLeadingRadius tl: CGFloat,
        bottomLeadingRadius bl: CGFloat,
        bottomTrailingRadius br: CGFloat,
        topTrailingRadius tr: CGFloat
    ) -> UIBezierPath {
        let tl = min(tl, rect.width / 2, rect.height / 2)
        let tr = min(tr, rect.width / 2, rect.height / 2)
        let bl = min(bl, rect.width / 2, rect.height / 2)
        let br = min(br, rect.width / 2, rect.height / 2)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
            radius: tr, startAngle: -.pi / 2, endAngle: 0, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
            radius: br, startAngle: 0, endAngle: .pi / 2, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
            radius: bl, startAngle: .pi / 2, endAngle: .pi, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
            radius: tl, startAngle: .pi, endAngle: -.pi / 2, clockwise: true
        )
        path.close()
        return path
    }
}
