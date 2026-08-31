//
//  AccountCard.swift
//  Tracki
//

import SwiftUI

/// Colorful account card (L2), 208×132pt, horizontal-scrolled on Home/Wallet.
/// A diagonal gloss and a tiny glass "chip" in the corner are the one place
/// glass meets a saturated color directly (B7.3).
struct AccountCard: View {
    let name: String
    let type: AccountType
    let currencyCode: String
    let colorHex: String
    let balance: Double
    let isHidden: Bool

    private var color: Color { Color(hex: colorHex) }
    private var fg: Color { color.contrastingForeground }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: type.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Text(currencyCode)
                    .font(.caption.weight(.bold))
            }
            Spacer()
            Text(name)
                .font(.footnote)
                .opacity(0.75)
                .lineLimit(1)
            Group {
                if isHidden {
                    Text("••••")
                } else {
                    Text(CurrencyFormatter.format(balance, currencyCode))
                        .contentTransition(.numericText(value: balance))
                }
            }
            .font(.title3.weight(.bold))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .animation(Motion.smooth, value: balance)
        }
        .foregroundStyle(fg)
        .padding(18)
        .frame(width: 208, height: 132, alignment: .leading)
        .background {
            ZStack {
                color
                LinearGradient(
                    colors: [.white.opacity(0.22), .clear, .black.opacity(0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
        .overlay(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .frame(width: 34, height: 24)
                .liquidGlass(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .opacity(0.9)
                .padding(14)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.20), lineWidth: 1)
        }
        .cardShadow()
    }
}
