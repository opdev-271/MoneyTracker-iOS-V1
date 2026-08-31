//
//  LiquidGlass.swift
//  Tracki
//

import SwiftUI

/// Fallback glass recipe for iOS 17–25 (B4.2): system material backdrop, a
/// very faint tint (anything stronger and the blur reads as "mathematically
/// present, visually dead" — the same mistake the Android build made once),
/// a top-lit gloss, and a specular rim that's bright at the top and faint at
/// the bottom instead of a uniform border.
struct GlassSurface<S: InsettableShape>: ViewModifier {
    var shape: S
    var tint: Color = Tokens.glassTint

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background {
                if reduceTransparency {
                    // A11y: no transparency at all — opaque surface + hairline.
                    shape.fill(Tokens.surfaceRaised)
                        .overlay(shape.strokeBorder(Tokens.hairline, lineWidth: 1))
                } else {
                    ZStack {
                        shape.fill(.ultraThinMaterial)
                        shape.fill(tint)
                        shape.fill(
                            LinearGradient(
                                colors: [.white.opacity(scheme == .dark ? 0.10 : 0.28), .clear],
                                startPoint: .top, endPoint: .center
                            )
                        )
                    }
                }
            }
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Tokens.glassRimTop, Tokens.glassRimBottom],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 0.8
                )
                .blendMode(.plusLighter)
                .opacity(reduceTransparency ? 0 : 1)
            }
            .clipShape(shape)
    }
}

extension View {
    /// Single entry point for every glass surface in the app. Reaches for
    /// native Liquid Glass on iOS 26+, falls back to `GlassSurface` below it.
    /// Never build a one-off blur anywhere else (B4.3).
    @ViewBuilder
    func liquidGlass<S: InsettableShape>(
        _ shape: S,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(glassStyle(tint: tint, interactive: interactive), in: shape)
        } else {
            self.modifier(GlassSurface(shape: shape, tint: tint ?? Tokens.glassTint))
        }
    }

    @available(iOS 26.0, *)
    private func glassStyle(tint: Color?, interactive: Bool) -> Glass {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return glass
    }
}
