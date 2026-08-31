//
//  Enums.swift
//  Tracki
//

import Foundation

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case income = "INCOME"
    case expense = "EXPENSE"

    var id: String { rawValue }
}

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case cash = "CASH"
    case bank = "BANK"
    case savings = "SAVINGS"

    var id: String { rawValue }

    /// SF Symbol shown as the account-type badge on account cards.
    var symbolName: String {
        switch self {
        case .cash: "banknote"
        case .bank: "building.columns.fill"
        case .savings: "percent"
        }
    }
}

/// 21 category icons (A7). SF Symbols cover this set well.
enum CategoryIconKey: String, Codable, CaseIterable, Identifiable {
    case food, transport, shopping, bills, entertainment, health, home, education,
         travel, pets, coffee, sport, fuel, phone, subscription, insurance,
         salary, gift, savings, investment, other

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .food: "fork.knife"
        case .transport: "tram.fill"
        case .shopping: "bag.fill"
        case .bills: "doc.text.fill"
        case .entertainment: "film.fill"
        case .health: "cross.case.fill"
        case .home: "house.fill"
        case .education: "graduationcap.fill"
        case .travel: "airplane"
        case .pets: "pawprint.fill"
        case .coffee: "cup.and.saucer.fill"
        case .sport: "figure.run"
        case .fuel: "fuelpump.fill"
        case .phone: "iphone"
        case .subscription: "arrow.trianglehead.2.clockwise"
        case .insurance: "shield.fill"
        case .salary: "banknote.fill"
        case .gift: "gift.fill"
        case .savings: "banknote.fill"
        case .investment: "chart.line.uptrend.xyaxis"
        case .other: "circle.grid.2x2.fill"
        }
    }
}

/// 8 profile pictograms (A7). SF Symbols doesn't have a complete matching animal
/// set, so `bear` and `fox` are placeholder glyphs pending real asset import.
enum ProfileIconKey: String, Codable, CaseIterable, Identifiable {
    case cat, dog, bear, fox, owl, rabbit, money, star

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .cat: "cat.fill"
        case .dog: "dog.fill"
        case .bear: "pawprint.fill"
        case .fox: "theatermasks.fill"
        case .owl: "bird.fill"
        case .rabbit: "hare.fill"
        case .money: "banknote.fill"
        case .star: "star.fill"
        }
    }
}
