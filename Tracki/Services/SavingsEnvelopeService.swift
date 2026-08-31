//
//  SavingsEnvelopeService.swift
//  Tracki
//

import Foundation
import SwiftData

/// Implements the envelope deposit business rule exactly as specified in A6.8.
enum SavingsEnvelopeService {
    /// Sends `amount` from `sourceAccount` into `envelope`.
    ///
    /// - When the source account differs from the envelope's own savings
    ///   account: creates a real transaction pair (an EXPENSE on the source,
    ///   an INCOME on the savings account), both uncategorized, dated now.
    /// - When the source **is** the envelope's own account: no transactions
    ///   are created — it's just money already there being earmarked.
    ///
    /// Either way, `envelope.currentAmount` increases by `amount`.
    @MainActor
    static func deposit(
        amount: Double,
        into envelope: SavingsEnvelope,
        from sourceAccount: Account,
        context: ModelContext
    ) {
        guard amount > 0 else { return }
        guard let envelopeAccount = envelope.account else { return }

        if sourceAccount.id != envelopeAccount.id {
            let expense = Transaction(
                type: .expense,
                amount: amount,
                note: envelope.name,
                date: .now,
                account: sourceAccount,
                category: nil
            )
            let income = Transaction(
                type: .income,
                amount: amount,
                note: envelope.name,
                date: .now,
                account: envelopeAccount,
                category: nil
            )
            context.insert(expense)
            context.insert(income)
        }

        envelope.currentAmount += amount
        try? context.save()
    }
}
