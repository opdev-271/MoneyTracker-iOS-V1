//
//  AddTransactionFAB.swift
//  Tracki
//

import SwiftUI

extension View {
    /// The floating "+" that opens Add Transaction, shown only on Home and
    /// Wallet (B7.6) — attach directly to those two screens, not globally.
    func addTransactionFAB(action: @escaping () -> Void) -> some View {
        safeAreaInset(edge: .bottom, alignment: .trailing) {
            Button(action: action) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Tokens.onAccent)
                    .frame(width: 58, height: 58)
            }
            .buttonStyle(.plain)
            .liquidGlass(Circle(), tint: Tokens.accent.opacity(0.65), interactive: true)
            .floatingShadow()
            .padding(.trailing, Space.screen)
            .padding(.bottom, Space.s)
        }
    }
}
