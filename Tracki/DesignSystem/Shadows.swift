//
//  Shadows.swift
//  Tracki
//

import SwiftUI

extension View {
    /// Content card (L3): a wide, faint ambient pass plus a narrower, slightly
    /// stronger key pass (B6).
    func cardShadow() -> some View {
        self
            .shadow(color: Tokens.shadowAmbient, radius: 12, x: 0, y: 6)
            .shadow(color: Tokens.shadowKey, radius: 3, x: 0, y: 1)
    }

    /// List row — half strength of `cardShadow`.
    func rowShadow() -> some View {
        self.shadow(color: Tokens.shadowAmbient.opacity(0.6), radius: 6, x: 0, y: 3)
    }

    /// Floating glass (L4) — clearly lifted, but not a cloud.
    func floatingShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
            .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)
    }
}
