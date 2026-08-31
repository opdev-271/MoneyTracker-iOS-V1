//
//  TrackiApp.swift
//  Tracki
//

import SwiftUI
import SwiftData

@main
struct TrackiApp: App {
    private let container: ModelContainer
    @State private var appSettings = AppSettings()
    @State private var exchangeRates = ExchangeRateService()

    init() {
        do {
            container = try ModelContainer(
                for: Schema(SchemaV1.models),
                migrationPlan: MoneyTrackerMigrationPlan.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appSettings)
                .environment(exchangeRates)
                .environment(\.locale, appSettings.language.locale ?? .autoupdatingCurrent)
                .preferredColorScheme(appSettings.themeMode.colorScheme)
                .task {
                    Seed.seedCategoriesIfNeeded(context: container.mainContext)
                    await exchangeRates.refresh()
                }
        }
        .modelContainer(container)
    }
}
