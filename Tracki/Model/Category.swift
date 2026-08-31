//
//  Category.swift
//  Tracki
//

import Foundation
import SwiftData

/// A transaction category. Global — shared across all profiles, not owned by
/// any single one. `name` is either free text or a resolver key (see
/// `DisplayNameResolver`); once a seeded category is renamed the key is
/// overwritten with literal text and it stops re-translating — intentional.
@Model
final class Category: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var typeRaw: String = TransactionType.expense.rawValue
    var icon: String?
    var colorHex: String = "F2907B"

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]? = []

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    init(name: String, type: TransactionType, icon: String? = nil, colorHex: String = "F2907B") {
        self.id = UUID()
        self.name = name
        self.typeRaw = type.rawValue
        self.icon = icon
        self.colorHex = colorHex
    }
}
