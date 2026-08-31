//
//  ColorSwatchRow.swift
//  Tracki
//

import SwiftUI

/// Row/grid of pickable hex-color swatches (accounts, profiles, envelopes,
/// categories all use this).
struct ColorSwatchRow: View {
    let colors: [String]
    @Binding var selected: String
    var columns: Int = 7

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Space.s), count: columns), spacing: Space.s) {
            ForEach(colors, id: \.self) { hex in
                let isSelected = hex == selected
                Button {
                    Haptics.selection()
                    selected = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if isSelected {
                                Circle().strokeBorder(Tokens.textPrimary, lineWidth: 2).padding(-3)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
