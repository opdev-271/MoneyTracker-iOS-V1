//
//  Account.swift
//  Tracki
//

import Foundation
import SwiftData

/// A single money account (cash, bank, savings...). Each account has its own
/// currency; the running balance is never stored — it's always
/// `initialBalance + sum of its transactions` (see `BalanceService`).
@Model
final class Account: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var accountTypeRaw: String = AccountType.cash.rawValue
    var currencyCode: String = "CZK"
    var initialBalance: Double = 0
    var accountNumber: String?
    var colorHex: String = "181A12"
    var sortOrder: Int = 0

    var profile: Profile?

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]? = []

    @Relationship(deleteRule: .cascade, inverse: \SavingsEnvelope.account)
    var envelopes: [SavingsEnvelope]? = []

    var accountType: AccountType {
        get { AccountType(rawValue: accountTypeRaw) ?? .cash }
        set { accountTypeRaw = newValue.rawValue }
    }

    init(
        name: String,
        accountType: AccountType = .cash,
        currencyCode: String = "CZK",
        initialBalance: Double = 0,
        accountNumber: String? = nil,
        colorHex: String = "181A12",
        sortOrder: Int = 0,
        profile: Profile? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.accountTypeRaw = accountType.rawValue
        self.currencyCode = currencyCode
        self.initialBalance = initialBalance
        self.accountNumber = accountNumber
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.profile = profile
    }
}
