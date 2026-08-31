//
//  SavingsEnvelope.swift
//  Tracki
//

import Foundation
import SwiftData

/// A named savings goal living inside one SAVINGS-type `Account`.
/// `currentAmount` is a *subset* of that account's own balance the user has
/// earmarked toward `goalAmount` — it never changes the account balance by
/// itself; money only moves in via a real transaction pair (see
/// `SavingsEnvelopeService`).
@Model
final class SavingsEnvelope: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var goalAmount: Double = 0
    var currentAmount: Double = 0
    var colorHex: String = "181A12"
    var sortOrder: Int = 0

    var account: Account?

    init(
        name: String,
        goalAmount: Double,
        currentAmount: Double = 0,
        colorHex: String = "181A12",
        sortOrder: Int = 0,
        account: Account? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.goalAmount = goalAmount
        self.currentAmount = currentAmount
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.account = account
    }
}
