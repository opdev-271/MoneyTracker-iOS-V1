//
//  AccountChip.swift
//  Tracki
//

import SwiftUI

/// Account filter chip (Analytics). An unselected chip is never outlined —
/// it's a tonal fill, because a full-strength outline on a dark account
/// color read as a black ring (B7.8).
struct AccountChip: View {
    let label: String
    /// `nil` = the neutral "All" chip.
    let color: Color?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(fill.contrastingForeground)
        .background(Capsule(style: .continuous).fill(fill))
    }

    private var fill: Color {
        guard let color else {
            return isSelected ? Tokens.accent : Tokens.surfaceSunken
        }
        return isSelected ? color : Tokens.surfaceSunken.mixed(with: color, by: 0.25)
    }
}
