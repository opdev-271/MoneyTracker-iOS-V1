//
//  BalanceAccountsPickerSheet.swift
//  Tracki
//

import SwiftUI

/// Multi-select of which accounts feed the Home balance card (A6.11). When
/// the selection ends up covering every account it's normalized back to
/// "ALL" so a newly added account automatically falls into the total.
struct BalanceAccountsPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings

    let profile: Profile
    let accounts: [Account]

    @State private var selected: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(spacing: Space.s) {
                        Button {
                            Haptics.selection()
                            selected = Set(accounts.map(\.id))
                        } label: {
                            HStack {
                                Text("Select all")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Tokens.textPrimary)
                                Spacer()
                                if selected.count == accounts.count {
                                    Image(systemName: "checkmark").foregroundStyle(Tokens.accentOnSurface)
                                }
                            }
                            .padding(14)
                            .background {
                                RoundedRectangle(cornerRadius: Radius.cardSmall, style: .continuous)
                                    .fill(Tokens.surfaceRaised)
                            }
                        }
                        .buttonStyle(.plain)

                        ForEach(accounts) { account in
                            let isOn = selected.contains(account.id)
                            Button {
                                Haptics.selection()
                                if isOn { selected.remove(account.id) } else { selected.insert(account.id) }
                            } label: {
                                HStack(spacing: Space.m) {
                                    Circle().fill(Color(hex: account.colorHex)).frame(width: 12, height: 12)
                                    Text(DisplayNameResolver.resolve(account.name, language: appSettings.language))
                                        .font(.subheadline)
                                        .foregroundStyle(Tokens.textPrimary)
                                    Spacer()
                                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isOn ? Tokens.accentOnSurface : Tokens.textTertiary)
                                }
                                .padding(14)
                                .background {
                                    RoundedRectangle(cornerRadius: Radius.cardSmall, style: .continuous)
                                        .fill(Tokens.surfaceRaised)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Space.screen)
                }
            }
            .navigationTitle("Balance from")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let normalized = selected.count == accounts.count ? nil : selected
                        appSettings.setBalanceAccountSelection(normalized, profileID: profile.id)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            if let stored = appSettings.balanceAccountSelection(profileID: profile.id) {
                selected = stored
            } else {
                selected = Set(accounts.map(\.id))
            }
        }
    }
}
