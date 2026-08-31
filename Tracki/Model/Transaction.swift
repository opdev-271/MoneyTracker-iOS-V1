//
//  Transaction.swift
//  Tracki
//

import Foundation
import SwiftData

/// A single income or expense entry, tied to one account and (optionally,
/// once its category is deleted) one category. `amount` is always stored
/// positive — `type` decides the sign.
@Model
final class Transaction: Identifiable {
    var id: UUID = UUID()
    var typeRaw: String = TransactionType.expense.rawValue
    var amount: Double = 0
    var counterparty: String?
    var note: String?
    var date: Date = Date.now

    var account: Account?
    var category: Category?

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    /// Negative for expenses, positive for income.
    var signedAmount: Double {
        type == .expense ? -amount : amount
    }

    init(
        type: TransactionType,
        amount: Double,
        counterparty: String? = nil,
        note: String? = nil,
        date: Date = .now,
        account: Account? = nil,
        category: Category? = nil
    ) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.amount = amount
        self.counterparty = counterparty
        self.note = note
        self.date = date
        self.account = account
        self.category = category
    }
}
