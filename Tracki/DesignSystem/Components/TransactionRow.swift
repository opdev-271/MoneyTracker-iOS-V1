//
//  TransactionRow.swift
//  Tracki
//

import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    let language: AppLanguage
    let colorCodeTransactions: Bool

    private var categoryColor: Color? {
        transaction.category.map { Color(hex: $0.colorHex) }
    }

    private var badgeColor: Color { categoryColor ?? Tokens.surfaceSunken }

    private var symbolName: String {
        if let icon = transaction.category?.icon, let key = CategoryIconKey(rawValue: icon) {
            return key.symbolName
        }
        return transaction.type == .expense ? "arrow.up" : "arrow.down"
    }

    private var title: String {
        if let counterparty = transaction.counterparty, !counterparty.isEmpty {
            return counterparty
        }
        if let category = transaction.category {
            return DisplayNameResolver.resolve(category.name, language: language)
        }
        return "Uncategorized"
    }

    private var subtitle: String {
        let verb = transaction.type == .expense ? "Sent by you" : "Received by you"
        let time = transaction.date.formatted(date: .omitted, time: .shortened)
        return "\(verb) • \(time)"
    }

    private var amountColor: Color {
        if transaction.type == .income { return Tokens.income }
        return colorCodeTransactions ? Tokens.expense : Tokens.textPrimary
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(badgeColor)
                Image(systemName: symbolName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(badgeColor.contrastingForeground)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Tokens.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Tokens.textSecondary)
            }
            Spacer(minLength: 8)

            Text(CurrencyFormatter.formatSigned(transaction.signedAmount, transaction.account?.currencyCode))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(amountColor)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: Radius.cardSmall, style: .continuous)
                .fill(Tokens.surfaceRaised)
        }
        .rowShadow()
    }
}
