//
//  AccountEditorSheet.swift
//  Tracki
//

import SwiftUI
import SwiftData

/// Add/Edit account (A6.3): name, type, currency, initial balance, optional
/// account number, color. Deleting cascades transactions + envelopes in the
/// database, but also has to clean up `AppSettings` — a stale
/// `activeAccountID` or leftover id in the balance-accounts selection isn't
/// reached by any foreign key and would keep silently affecting Home.
struct AccountEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext

    let profile: Profile?
    var accountToEdit: Account?

    @State private var name: String
    @State private var accountType: AccountType
    @State private var currencyCode: String
    @State private var initialBalanceText: String
    @State private var accountNumber: String
    @State private var colorHex: String
    @State private var showDeleteConfirmation = false

    init(profile: Profile?, accountToEdit: Account?) {
        self.profile = profile
        self.accountToEdit = accountToEdit
        _name = State(initialValue: accountToEdit?.name ?? "")
        _accountType = State(initialValue: accountToEdit?.accountType ?? .cash)
        _currencyCode = State(initialValue: accountToEdit?.currencyCode ?? "CZK")
        _initialBalanceText = State(initialValue: accountToEdit.map { String($0.initialBalance) } ?? "")
        _accountNumber = State(initialValue: accountToEdit?.accountNumber ?? "")
        _colorHex = State(initialValue: accountToEdit?.colorHex ?? Palette.accountColors[0])
    }

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var resolvedName: String {
        accountToEdit.map { DisplayNameResolver.resolve($0.name, language: appSettings.language) } ?? "New account"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.l) {
                        field("Name") {
                            TextField("e.g. Checking account", text: $name)
                        }

                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Type").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            GlassSegmentedPicker(
                                options: [(AccountType.cash, "Cash"), (AccountType.bank, "Bank"), (AccountType.savings, "Savings")],
                                selection: $accountType
                            )
                        }

                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Currency").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            GlassSegmentedPicker(
                                options: CurrencyFormatter.supportedCurrencyCodes.map { ($0, $0) },
                                selection: $currencyCode
                            )
                        }

                        field("Initial balance") {
                            TextField("0", text: $initialBalanceText)
                                .keyboardType(.decimalPad)
                        }

                        field("Account number (optional)") {
                            TextField("Optional", text: $accountNumber)
                        }

                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Color").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            ColorSwatchRow(colors: Palette.accountColors, selected: $colorHex)
                        }

                        if accountToEdit != nil {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Text("Delete account")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Tokens.expense)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Space.screen)
                }
            }
            .navigationTitle(resolvedName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!isValid)
                }
            }
        }
        .presentationDetents([.large])
        .confirmationDialog(
            "\"\(resolvedName)\" and all its transactions and savings envelopes will be permanently deleted.",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(title).font(.footnote).foregroundStyle(Tokens.textSecondary)
            content()
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background {
                    RoundedRectangle(cornerRadius: Radius.inner, style: .continuous)
                        .fill(Tokens.surfaceRaised)
                }
        }
    }

    private func save() {
        let initialBalance = Double(initialBalanceText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNumber = accountNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        if let account = accountToEdit {
            account.name = trimmedName
            account.accountType = accountType
            account.currencyCode = currencyCode
            account.initialBalance = initialBalance
            account.accountNumber = trimmedNumber.isEmpty ? nil : trimmedNumber
            account.colorHex = colorHex
        } else {
            let account = Account(
                name: trimmedName,
                accountType: accountType,
                currencyCode: currencyCode,
                initialBalance: initialBalance,
                accountNumber: trimmedNumber.isEmpty ? nil : trimmedNumber,
                colorHex: colorHex,
                sortOrder: (profile?.accounts?.count ?? 0),
                profile: profile
            )
            modelContext.insert(account)
        }
        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        guard let account = accountToEdit else { return }
        Haptics.impact(.rigid)

        if appSettings.activeAccountID == account.id {
            appSettings.activeAccountID = nil
        }
        if let profile, var selection = appSettings.balanceAccountSelection(profileID: profile.id) {
            selection.remove(account.id)
            appSettings.setBalanceAccountSelection(selection, profileID: profile.id)
        }

        modelContext.delete(account)
        try? modelContext.save()
        dismiss()
    }
}
