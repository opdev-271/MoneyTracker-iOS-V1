//
//  EmptyState.swift
//  Tracki
//

import SwiftUI

struct EmptyState: View {
    let systemImage: String
    let text: String

    var body: some View {
        VStack(spacing: Space.s) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(Tokens.textTertiary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Tokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Space.xl)
    }
}
