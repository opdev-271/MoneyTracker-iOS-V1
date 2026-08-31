//
//  WalletScreen.swift
//  Tracki
//

import SwiftUI
import SwiftData

/// All of the active profile's accounts with live balances (A6.3).
struct WalletScreen: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(ExchangeRateService.self) private var exchangeRates
    @Query(sort: \Profile.sortOrder) private var profiles: [Profile]
    @Query(sort: \Account.sortOrder) private var allAccounts: [Account]

    @Binding var addTransactionRequest: AddTransactionRequest?

    @State private var addingAccount = false
    @State private var editingAccount: Account?
    @State private var showSavings: Account?

    private var currentProfile: Profile? {
        profiles.first { $0.id == appSettings.activeProfileID } ?? profiles.first
    }

    private var accounts: [Account] {
        guard let pid = currentProfile?.id else { return [] }
        return allAccounts.filter { $0.profile?.id == pid }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()

                ScrollView {
                    if accounts.isEmpty {
                        EmptyState(systemImage: "creditcard", text: "No accounts yet")
                            .padding(.top, Space.xl)
                    } else {
                        LazyVStack(spacing: Space.s) {
                            ForEach(accounts) { account in
                                accountRow(account)
                            }
                        }
                        .padding(Space.screen)
                    }
                }
            }
            .navigationTitle("Wallet")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { addingAccount = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .addTransactionFAB {
            addTransactionRequest = AddTransactionRequest(type: .expense, accountID: accounts.first?.id)
        }
        .sheet(isPresented: $addingAccount) {
            AccountEditorSheet(profile: currentProfile, accountToEdit: nil)
        }
        .sheet(item: $editingAccount) { account in
            AccountEditorSheet(profile: currentProfile, accountToEdit: account)
        }
        .sheet(item: $showSavings) { account in
            SavingsEnvelopesScreen(account: account)
        }
    }

    private func accountRow(_ account: Account) -> some View {
        Button {
            Haptics.impact(.light)
            if account.accountType == .savings {
                showSavings = account
            } else {
                editingAccount = account
            }
        } label: {
            HStack(spacing: Space.m) {
                ZStack {
                    Circle().fill(Color(hex: account.colorHex))
                    Image(systemName: account.accountType.symbolName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: account.colorHex).contrastingForeground)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(DisplayNameResolver.resolve(account.name, language: appSettings.language))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Tokens.textPrimary)
                    Text(account.currencyCode)
                        .font(.caption)
                        .foregroundStyle(Tokens.textSecondary)
                }

                Spacer()

                Text(appSettings.hideBalance ? "••••" : CurrencyFormatter.format(BalanceService.balance(for: account), account.currencyCode))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Tokens.textPrimary)
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: Radius.cardSmall, style: .continuous)
                    .fill(Tokens.surfaceRaised)
            }
            .rowShadow()
        }
        .buttonStyle(.plain)
    }
}
