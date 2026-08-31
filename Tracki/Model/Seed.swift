//
//  Seed.swift
//  Tracki
//

import Foundation
import SwiftData

/// First-launch seed data. Only categories are seeded here — the first
/// profile and its default cash account are created by onboarding once the
/// user has picked a name/avatar (A2.8: seeding both here would race
/// onboarding's insert on the very first DB open).
enum Seed {
    struct CategorySeed {
        let key: String
        let type: TransactionType
        let icon: CategoryIconKey
        let colorHex: String
    }

    static let categories: [CategorySeed] = [
        CategorySeed(key: "category_food", type: .expense, icon: .food, colorHex: "F2907B"),
        CategorySeed(key: "category_transport", type: .expense, icon: .transport, colorHex: "8EC9F0"),
        CategorySeed(key: "category_shopping", type: .expense, icon: .shopping, colorHex: "B9B3F4"),
        CategorySeed(key: "category_bills", type: .expense, icon: .bills, colorHex: "E2674A"),
        CategorySeed(key: "category_entertainment", type: .expense, icon: .entertainment, colorHex: "9B8CE8"),
        CategorySeed(key: "category_health", type: .expense, icon: .health, colorHex: "7ED9A7"),
        CategorySeed(key: "category_other_expense", type: .expense, icon: .other, colorHex: "9AA091"),
        CategorySeed(key: "category_salary", type: .income, icon: .salary, colorHex: "A9C93F"),
        CategorySeed(key: "category_gift", type: .income, icon: .gift, colorHex: "F2C94C"),
        CategorySeed(key: "category_other_income", type: .income, icon: .other, colorHex: "8EC9F0"),
    ]

    /// The key used for the default cash account created by onboarding (A2.8).
    static let defaultCashAccountKey = "account_cash"

    @MainActor
    static func seedCategoriesIfNeeded(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        guard existing.isEmpty else { return }
        for seed in categories {
            context.insert(Category(name: seed.key, type: seed.type, icon: seed.icon.rawValue, colorHex: seed.colorHex))
        }
        try? context.save()
    }
}
