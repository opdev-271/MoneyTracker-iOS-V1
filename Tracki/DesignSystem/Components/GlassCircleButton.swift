//
//  GlassCircleButton.swift
//  Tracki
//

import SwiftUI

struct GlassCircleButton: View {
    let systemImage: String
    let action: () -> Void
    var size: CGFloat = 34

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.41, weight: .semibold))
                .foregroundStyle(Tokens.textPrimary)
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .liquidGlass(Circle(), interactive: true)
    }
}
