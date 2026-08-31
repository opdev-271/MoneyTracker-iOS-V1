//
//  ContentCard.swift
//  Tracki
//

import SwiftUI

/// Basic building block for the whole app (L3). **Never** glass — content
/// cards (transaction rows, stat panels, settings rows) stay opaque so glass
/// keeps meaning as "the layer that floats and controls", not decoration.
struct ContentCard<Content: View>: View {
    var padding: CGFloat = 18
    var radius: CGFloat = Radius.card
    @ViewBuilder var content: Content

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: scheme == .dark
                                ? [Tokens.surfaceRaised, Tokens.surfaceRaised]
                                : [Color.white, Color(hex: 0xFCFCFC)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay {
                        // No stroke in light mode (A9.3) — a hairline is
                        // required in dark mode, where background == surface.
                        if scheme == .dark {
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .strokeBorder(Tokens.hairline, lineWidth: 1)
                        }
                    }
            }
            .cardShadow()
    }
}
