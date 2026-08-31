//
//  DisplayNameResolver.swift
//  Tracki
//

import Foundation

/// Seed accounts/categories are stored under a stable key (e.g.
/// "category_food") instead of free text so their label can be re-localized
/// after a language switch. User-created accounts/categories have arbitrary
/// free text names and are returned as-is (A4).
enum DisplayNameResolver {
    private static let table: [String: [AppLanguage: String]] = [
        "account_cash": [.en: "Cash", .cs: "Hotovost"],
        "category_food": [.en: "Food", .cs: "Jídlo"],
        "category_transport": [.en: "Transport", .cs: "Doprava"],
        "category_shopping": [.en: "Shopping", .cs: "Nákupy"],
        "category_bills": [.en: "Bills", .cs: "Účty"],
        "category_entertainment": [.en: "Entertainment", .cs: "Zábava"],
        "category_health": [.en: "Health", .cs: "Zdraví"],
        "category_other_expense": [.en: "Other", .cs: "Ostatní"],
        "category_salary": [.en: "Salary", .cs: "Výplata"],
        "category_gift": [.en: "Gift", .cs: "Dar"],
        "category_other_income": [.en: "Other", .cs: "Ostatní"],
    ]

    static func resolve(_ rawNameOrKey: String, language: AppLanguage) -> String {
        guard let entry = table[rawNameOrKey] else { return rawNameOrKey }
        let effective = language == .system ? systemLanguage() : language
        return entry[effective] ?? entry[.en] ?? rawNameOrKey
    }

    private static func systemLanguage() -> AppLanguage {
        let code = Locale.preferredLanguages.first?.prefix(2) ?? "en"
        return code == "cs" ? .cs : .en
    }
}

/// Orders categories/accounts the way the user reads them: by their
/// *resolved, locale-collated* label — never by the raw stored key/text,
/// which would sort seeded keys alphabetically by key and jumble as soon as
/// one item is renamed to literal text (A4.2).
enum DisplayNameSorter {
    static func sorted(_ names: [(id: UUID, name: String)], language: AppLanguage) -> [UUID] {
        names
            .map { (id: $0.id, label: DisplayNameResolver.resolve($0.name, language: language)) }
            .sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }
            .map(\.id)
    }
}
