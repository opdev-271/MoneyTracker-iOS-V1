//
//  Profile.swift
//  Tracki
//

import Foundation
import SwiftData

/// A user profile (e.g. a family member). Owns its own accounts and,
/// transitively, its own transactions; categories stay shared/global.
@Model
final class Profile: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var pictogram: String = ProfileIconKey.cat.rawValue
    var sortOrder: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \Account.profile)
    var accounts: [Account]? = []

    init(name: String, pictogram: String = ProfileIconKey.cat.rawValue, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.pictogram = pictogram
        self.sortOrder = sortOrder
    }
}
