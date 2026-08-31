//
//  OnboardingScreen.swift
//  Tracki
//

import SwiftUI
import SwiftData

/// First-run flow (A6.1): name + avatar → language + theme → currency →
/// done. On confirm: persists prefs, then inserts the `Profile`, then the
/// default cash `Account` — that order matters, the account needs the
/// profile's id (A2.8).
struct OnboardingScreen: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext

    @State private var step = 0
    @State private var name = ""
    @State private var pictogram: ProfileIconKey = .cat
    @State private var language: AppLanguage = .en
    @State private var themeMode: ThemeMode = .system
    @State private var currency = "CZK"

    private let totalSteps = 3
    private var isNameValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        ZStack {
            PageBackground()

            VStack(spacing: 0) {
                progressDots
                    .padding(.top, Space.m)

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: languageThemeStep
                    default: currencyStep
                    }
                }
                .padding(.horizontal, Space.screen)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step)

                Spacer()

                continueButton
                    .padding(.horizontal, Space.screen)
                    .padding(.bottom, Space.l)
            }
        }
        .animation(Motion.snappy, value: step)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == step ? Tokens.accentOnSurface : Tokens.surfaceSunken)
                    .frame(width: index == step ? 24 : 8, height: 8)
            }
        }
    }

    // MARK: Step 1 — welcome, name, avatar

    private var welcomeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.l) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("Welcome!")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(Tokens.textPrimary)
                    Text("Let's set up your Tracki.")
                        .font(.subheadline)
                        .foregroundStyle(Tokens.textSecondary)
                }
                .padding(.top, Space.l)

                VStack(alignment: .leading, spacing: Space.s) {
                    Text("Your name")
                        .font(.footnote)
                        .foregroundStyle(Tokens.textSecondary)
                    TextField("e.g. Oliver", text: $name)
                        .font(.system(size: 17, weight: .medium))
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.inner, style: .continuous)
                                .fill(Tokens.surfaceRaised)
                        }
                }

                VStack(alignment: .leading, spacing: Space.s) {
                    Text("Avatar")
                        .font(.footnote)
                        .foregroundStyle(Tokens.textSecondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Space.s), count: 4), spacing: Space.s) {
                        ForEach(ProfileIconKey.allCases) { icon in
                            avatarCell(icon)
                        }
                    }
                }
            }
        }
    }

    private func avatarCell(_ icon: ProfileIconKey) -> some View {
        let isSelected = pictogram == icon
        return Button {
            Haptics.selection()
            withAnimation(Motion.snappy) { pictogram = icon }
        } label: {
            Image(systemName: icon.symbolName)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isSelected ? Tokens.onAccent : Tokens.textPrimary)
                .frame(width: 64, height: 64)
                .background {
                    Circle().fill(isSelected ? Tokens.accent : Tokens.surfaceRaised)
                }
                .overlay {
                    if isSelected {
                        Circle().stroke(Tokens.accent, lineWidth: 2).padding(-3)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: Step 2 — language + theme

    private var languageThemeStep: some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Language & appearance")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Tokens.textPrimary)
                Text("You can change these later in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(Tokens.textSecondary)
            }
            .padding(.top, Space.l)

            VStack(alignment: .leading, spacing: Space.s) {
                Text("Language").font(.footnote).foregroundStyle(Tokens.textSecondary)
                GlassSegmentedPicker(
                    options: [(AppLanguage.en, "English"), (AppLanguage.cs, "Čeština")],
                    selection: $language
                )
            }

            VStack(alignment: .leading, spacing: Space.s) {
                Text("Appearance").font(.footnote).foregroundStyle(Tokens.textSecondary)
                GlassSegmentedPicker(
                    options: [(ThemeMode.light, "Light"), (ThemeMode.dark, "Dark"), (ThemeMode.system, "System")],
                    selection: $themeMode
                )
            }
        }
    }

    // MARK: Step 3 — currency

    private var currencyStep: some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Preferred currency")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Tokens.textPrimary)
                Text("Used to total up balances across accounts in different currencies.")
                    .font(.subheadline)
                    .foregroundStyle(Tokens.textSecondary)
            }
            .padding(.top, Space.l)

            GlassSegmentedPicker(
                options: CurrencyFormatter.supportedCurrencyCodes.map { ($0, $0) },
                selection: $currency
            )
        }
    }

    private var continueButton: some View {
        Button {
            if step < totalSteps - 1 {
                guard step != 0 || isNameValid else {
                    Haptics.error()
                    return
                }
                Haptics.impact(.light)
                step += 1
            } else {
                finish()
            }
        } label: {
            Text(step < totalSteps - 1 ? "Continue" : "Get started")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(Tokens.onAccent)
        }
        .buttonStyle(.plain)
        .liquidGlass(Capsule(style: .continuous), tint: Tokens.accent.opacity(0.7), interactive: true)
        .opacity(step == 0 && !isNameValid ? 0.5 : 1)
    }

    private func finish() {
        Haptics.success()

        appSettings.language = language
        appSettings.themeMode = themeMode
        appSettings.preferredCurrency = currency

        let profile = Profile(name: name.trimmingCharacters(in: .whitespacesAndNewlines), pictogram: pictogram.rawValue, sortOrder: 0)
        modelContext.insert(profile)

        let account = Account(
            name: Seed.defaultCashAccountKey,
            accountType: .cash,
            currencyCode: currency,
            initialBalance: 0,
            colorHex: Palette.accountColors[0],
            sortOrder: 0,
            profile: profile
        )
        modelContext.insert(account)
        try? modelContext.save()

        appSettings.activeProfileID = profile.id
        appSettings.activeAccountID = account.id
        appSettings.onboardingDone = true
    }
}
