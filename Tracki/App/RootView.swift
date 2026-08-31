//
//  RootView.swift
//  Tracki
//

import SwiftUI

enum AppTab: String, CaseIterable {
    case home, wallet, analytics, settings
}

struct RootView: View {
    @Environment(AppSettings.self) private var appSettings
    @State private var tab: AppTab = .home
    @State private var addTransactionRequest: AddTransactionRequest?

    var body: some View {
        Group {
            if appSettings.onboardingDone {
                mainTabs
            } else {
                OnboardingScreen()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appSettings.onboardingDone)
    }

    private var mainTabs: some View {
        TabView(selection: $tab) {
            HomeScreen(addTransactionRequest: $addTransactionRequest)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            WalletScreen(addTransactionRequest: $addTransactionRequest)
                .tabItem { Label("Wallet", systemImage: "creditcard.fill") }
                .tag(AppTab.wallet)

            AnalyticsScreen()
                .tabItem { Label("Analytics", systemImage: "chart.pie.fill") }
                .tag(AppTab.analytics)

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(Tokens.accentOnSurface)
        .sheet(item: $addTransactionRequest) { request in
            AddTransactionScreen(request: request)
        }
    }
}

/// What the FAB / action pills pass to Add Transaction: which type to
/// preselect and, if the caller already knows it, which account.
struct AddTransactionRequest: Identifiable {
    let id = UUID()
    var type: TransactionType
    var accountID: UUID?
}
