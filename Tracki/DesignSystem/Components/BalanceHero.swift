//
//  BalanceHero.swift
//  Tracki
//

import SwiftUI

/// The most important element in the app. Sits directly on the page
/// background — no card underneath — because it's the largest typography on
/// the screen and a card would visually cap it (B7.2).
struct BalanceHero: View {
    let label: String
    let amount: Double
    let currency: String
    let accountNames: [String]
    @Binding var isHidden: Bool
    var onPickAccounts: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack {
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(Tokens.textSecondary)
                Spacer()
                GlassCircleButton(systemImage: isHidden ? "eye.slash" : "eye") {
                    withAnimation(Motion.smooth) { isHidden.toggle() }
                    Haptics.impact(.light)
                }
                GlassCircleButton(systemImage: "slider.horizontal.3", action: onPickAccounts)
            }

            Group {
                if isHidden {
                    Text("••••••")
                        .transition(.blurReplace)
                } else {
                    Text(CurrencyFormatter.format(amount, currency))
                        .contentTransition(.numericText(value: amount))
                        .transition(.blurReplace)
                }
            }
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(Tokens.textPrimary)
            .animation(Motion.smooth, value: amount)
            .animation(Motion.smooth, value: isHidden)

            if !accountNames.isEmpty {
                Label(accountNames.joined(separator: ", "), systemImage: "creditcard")
                    .font(.caption)
                    .foregroundStyle(Tokens.textSecondary)
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, Space.screen)
    }
}
