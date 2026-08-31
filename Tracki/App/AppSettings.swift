//
//  AppSettings.swift
//  Tracki
//

import Foundation
import SwiftUI
import Observation

enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case system, en, cs

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .en: "English"
        case .cs: "Čeština"
        }
    }

    /// `nil` for `.system` lets SwiftUI fall back to the device locale.
    var locale: Locale? {
        switch self {
        case .system: nil
        case .en: Locale(identifier: "en")
        case .cs: Locale(identifier: "cs")
        }
    }
}

enum ThemeMode: String, CaseIterable, Identifiable, Hashable {
    case light, dark, system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .system: "System"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

/// Single `@Observable` source of truth for every app-wide preference (A3).
/// `hideBalance` in particular is read/written from both the Home eye button
/// and the Settings switch — both must see the same value instantly, which a
/// shared observable object gives for free where two independent
/// `@AppStorage` copies would not.
@Observable
final class AppSettings {
    private let defaults: UserDefaults

    var hideBalance: Bool { didSet { defaults.set(hideBalance, forKey: Keys.hideBalance) } }
    var activeAccountID: UUID? { didSet { defaults.set(activeAccountID?.uuidString, forKey: Keys.activeAccountID) } }
    var activeProfileID: UUID? { didSet { defaults.set(activeProfileID?.uuidString, forKey: Keys.activeProfileID) } }
    var colorCodeTransactions: Bool { didSet { defaults.set(colorCodeTransactions, forKey: Keys.colorCodeTransactions) } }
    var animationsEnabled: Bool { didSet { defaults.set(animationsEnabled, forKey: Keys.animationsEnabled) } }

    var homeShowBalance: Bool { didSet { defaults.set(homeShowBalance, forKey: Keys.homeShowBalance) } }
    var homeShowActions: Bool { didSet { defaults.set(homeShowActions, forKey: Keys.homeShowActions) } }
    var homeShowAccounts: Bool { didSet { defaults.set(homeShowAccounts, forKey: Keys.homeShowAccounts) } }
    var homeShowTransactions: Bool { didSet { defaults.set(homeShowTransactions, forKey: Keys.homeShowTransactions) } }

    var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: Keys.language) } }
    var themeMode: ThemeMode { didSet { defaults.set(themeMode.rawValue, forKey: Keys.themeMode) } }
    var onboardingDone: Bool { didSet { defaults.set(onboardingDone, forKey: Keys.onboardingDone) } }
    var preferredCurrency: String { didSet { defaults.set(preferredCurrency, forKey: Keys.preferredCurrency) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hideBalance = defaults.bool(forKey: Keys.hideBalance)
        activeAccountID = defaults.string(forKey: Keys.activeAccountID).flatMap(UUID.init)
        activeProfileID = defaults.string(forKey: Keys.activeProfileID).flatMap(UUID.init)
        colorCodeTransactions = defaults.object(forKey: Keys.colorCodeTransactions) as? Bool ?? true
        animationsEnabled = defaults.object(forKey: Keys.animationsEnabled) as? Bool ?? true
        homeShowBalance = defaults.object(forKey: Keys.homeShowBalance) as? Bool ?? true
        homeShowActions = defaults.object(forKey: Keys.homeShowActions) as? Bool ?? true
        homeShowAccounts = defaults.object(forKey: Keys.homeShowAccounts) as? Bool ?? true
        homeShowTransactions = defaults.object(forKey: Keys.homeShowTransactions) as? Bool ?? true
        language = AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .system
        themeMode = ThemeMode(rawValue: defaults.string(forKey: Keys.themeMode) ?? "") ?? .system
        onboardingDone = defaults.bool(forKey: Keys.onboardingDone)
        preferredCurrency = defaults.string(forKey: Keys.preferredCurrency) ?? "CZK"
    }

    /// Which of a profile's accounts feed the Home balance card. `nil` means
    /// "all accounts" — also the default, and what a fresh account
    /// automatically falls into.
    func balanceAccountSelection(profileID: UUID) -> Set<UUID>? {
        let key = Keys.balanceAccountsPrefix + profileID.uuidString
        guard let stored = defaults.string(forKey: key), stored != "ALL", !stored.isEmpty else {
            return nil
        }
        return Set(stored.split(separator: ",").compactMap { UUID(uuidString: String($0)) })
    }

    /// Pass `nil` to mean "all accounts".
    func setBalanceAccountSelection(_ ids: Set<UUID>?, profileID: UUID) {
        let key = Keys.balanceAccountsPrefix + profileID.uuidString
        if let ids {
            defaults.set(ids.map(\.uuidString).joined(separator: ","), forKey: key)
        } else {
            defaults.set("ALL", forKey: key)
        }
    }

    /// Single source of truth for "should this thing animate right now" —
    /// combines the user's own toggle with the system's Reduce Motion (B10).
    func shouldAnimate(reduceMotion: Bool) -> Bool {
        animationsEnabled && !reduceMotion
    }

    private enum Keys {
        static let hideBalance = "hide_balance"
        static let activeAccountID = "active_account_id"
        static let activeProfileID = "active_profile_id"
        static let colorCodeTransactions = "color_code_transactions"
        static let animationsEnabled = "animations_enabled"
        static let balanceAccountsPrefix = "balance_accounts_"
        static let homeShowBalance = "home_show_balance"
        static let homeShowActions = "home_show_actions"
        static let homeShowAccounts = "home_show_accounts"
        static let homeShowTransactions = "home_show_transactions"
        static let language = "language"
        static let themeMode = "theme_mode"
        static let onboardingDone = "onboarding_done"
        static let preferredCurrency = "preferred_currency"
    }
}
