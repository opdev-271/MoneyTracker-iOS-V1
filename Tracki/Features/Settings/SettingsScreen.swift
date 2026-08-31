//
//  SettingsScreen.swift
//  Tracki
//

import SwiftUI
import SwiftData

/// A6.10. Uses `GlassSegmentedPicker` for language/appearance instead of a
/// native `List` + `Picker(.segmented)` — the same control is used in
/// Analytics and Add Transaction, and that consistency wins (B8).
struct SettingsScreen: View {
    @Environment(AppSettings.self) private var appSettings
    @Query(sort: \Profile.sortOrder) private var profiles: [Profile]
    @State private var showCategories = false

    private var currentProfile: Profile? {
        profiles.first { $0.id == appSettings.activeProfileID } ?? profiles.first
    }

    /// A6.10's toggle is phrased as "disable animations", inverted from the
    /// underlying `animationsEnabled` flag.
    private var disableAnimations: Binding<Bool> {
        Binding(
            get: { !appSettings.animationsEnabled },
            set: { appSettings.animationsEnabled = !$0 }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(spacing: Space.l) {
                        if let name = currentProfile?.name, !name.isEmpty {
                            profileCard(name)
                        }

                        section("Language") {
                            GlassSegmentedPicker(
                                options: [(AppLanguage.en, "English"), (AppLanguage.cs, "Čeština")],
                                selection: Binding(get: { appSettings.language }, set: { appSettings.language = $0 })
                            )
                        }

                        section("Appearance") {
                            GlassSegmentedPicker(
                                options: [(ThemeMode.light, "Light"), (ThemeMode.dark, "Dark"), (ThemeMode.system, "System")],
                                selection: Binding(get: { appSettings.themeMode }, set: { appSettings.themeMode = $0 })
                            )
                        }

                        section("Home screen") {
                            ContentCard {
                                VStack(spacing: 0) {
                                    toggleRow("Balance", Binding(get: { appSettings.homeShowBalance }, set: { appSettings.homeShowBalance = $0 }))
                                    Divider().overlay(Tokens.hairline)
                                    toggleRow("Quick actions", Binding(get: { appSettings.homeShowActions }, set: { appSettings.homeShowActions = $0 }))
                                    Divider().overlay(Tokens.hairline)
                                    toggleRow("Accounts", Binding(get: { appSettings.homeShowAccounts }, set: { appSettings.homeShowAccounts = $0 }))
                                    Divider().overlay(Tokens.hairline)
                                    toggleRow("Recent transactions", Binding(get: { appSettings.homeShowTransactions }, set: { appSettings.homeShowTransactions = $0 }))
                                }
                            }
                        }

                        section("Display") {
                            ContentCard {
                                VStack(spacing: 0) {
                                    toggleRow("Hide balances", Binding(get: { appSettings.hideBalance }, set: { appSettings.hideBalance = $0 }))
                                    Divider().overlay(Tokens.hairline)
                                    toggleRow("Color-code income & expenses", Binding(get: { appSettings.colorCodeTransactions }, set: { appSettings.colorCodeTransactions = $0 }))
                                    Divider().overlay(Tokens.hairline)
                                    toggleRow("Disable animations", disableAnimations)
                                }
                            }
                        }

                        section("Categories") {
                            Button {
                                showCategories = true
                            } label: {
                                HStack {
                                    Text("Manage categories")
                                        .font(.subheadline)
                                        .foregroundStyle(Tokens.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Tokens.textTertiary)
                                }
                                .padding(16)
                                .background {
                                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Tokens.surfaceRaised)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        Text("Tracki · version 1.0")
                            .font(.caption)
                            .foregroundStyle(Tokens.textTertiary)
                            .padding(.top, Space.m)
                    }
                    .padding(Space.screen)
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(isPresented: $showCategories) {
                CategoriesScreen()
            }
        }
    }

    private func profileCard(_ name: String) -> some View {
        ContentCard {
            HStack(spacing: Space.m) {
                Image(systemName: (ProfileIconKey(rawValue: currentProfile?.pictogram ?? "") ?? .cat).symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Tokens.onAccent)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Tokens.accent))
                Text(name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Tokens.textPrimary)
                Spacer()
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(title).font(.footnote.weight(.medium)).foregroundStyle(Tokens.textSecondary)
            content()
        }
    }

    private func toggleRow(_ title: String, _ binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Text(title).font(.subheadline).foregroundStyle(Tokens.textPrimary)
        }
        .tint(Tokens.accentOnSurface)
        .padding(.vertical, 12)
        .onChange(of: binding.wrappedValue) { _, _ in Haptics.selection() }
    }
}
