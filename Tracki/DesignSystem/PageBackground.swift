//
//  PageBackground.swift
//  Tracki
//

import SwiftUI

/// The page backdrop the whole app sits on — "what the glass has to bend"
/// (B3). Static (no animation, no parallax), lightness delta under 4%. Two
/// very soft accent-colored blooms give Liquid Glass surfaces above it
/// something to refract; a flat solid color would leave blur "mathematically
/// present, visually dead" (the same mistake the Android build once made
/// with 70%-white glass).
struct PageBackground: View {
    var body: some View {
        if #available(iOS 18.0, *) {
            MeshPageBackground()
        } else {
            LegacyPageBackground()
        }
    }
}

private struct LegacyPageBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Tokens.pageBase

            RadialGradient(
                colors: [Tokens.accent.opacity(scheme == .dark ? 0.10 : 0.16), .clear],
                center: UnitPoint(x: 0.08, y: 0.02),
                startRadius: 0, endRadius: 420
            )

            RadialGradient(
                colors: [Tokens.lavender.opacity(scheme == .dark ? 0.10 : 0.14), .clear],
                center: UnitPoint(x: 1.02, y: 0.92),
                startRadius: 0, endRadius: 460
            )
        }
        .ignoresSafeArea()
    }
}

@available(iOS 18.0, *)
private struct MeshPageBackground: View {
    @Environment(\.colorScheme) private var scheme
    private var base: Color { Tokens.pageBase }

    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                blend(Tokens.accent, 0.14), base, blend(Tokens.lavender, 0.06),
                base, base, base,
                blend(Tokens.coral, 0.05), base, blend(Tokens.lavender, 0.13),
            ]
        )
        .ignoresSafeArea()
    }

    private func blend(_ color: Color, _ amount: Double) -> Color {
        base.mix(with: color, by: scheme == .dark ? amount * 0.7 : amount)
    }
}
