//
//  HomeScreen.swift
//  Tracki
//

import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(ExchangeRateService.self) private var exchangeRates
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Profile.sortOrder) private var profiles: [Profile]
    @Query(sort: \Account.sortOrder) private var allAccounts: [Account]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @Binding var addTransactionRequest: AddTransactionRequest?

    @State private var showProfileSwitcher = false
    @State private var showAccountsPicker = false
    @State private var editingAccount: Account?
    @State private var addingAccount = false
    @State private var showAllTransactions = false
    @State private var showSavings: Account?

    private var currentProfile: Profile? {
        profiles.first { $0.id == appSettings.activeProfileID } ?? profiles.first
    }

    private var profileAccounts: [Account] {
        guard let pid = currentProfile?.id else { return [] }
        return allAccounts.filter { $0.profile?.id == pid }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var selectedBalanceAccounts: [Account] {
        guard let pid = currentProfile?.id else { return [] }
        guard let ids = appSettings.balanceAccountSelection(profileID: pid) else { return profileAccounts }
        let subset = profileAccounts.filter { ids.contains($0.id) }
        return subset.isEmpty ? profileAccounts : subset
    }

    private var isAllAccountsSelected: Bool {
        selectedBalanceAccounts.count == profileAccounts.count
    }

    private var balanceLabel: String {
        if isAllAccountsSelected { return "Balance on all accounts" }
        if selectedBalanceAccounts.count == 1 { return "Balance on account:" }
        return "Balance on accounts:"
    }

    private var totalBalance: Double {
        BalanceService.totalBalance(
            accounts: selectedBalanceAccounts,
            preferredCurrency: appSettings.preferredCurrency,
            rates: exchangeRates
        )
    }

    private var balanceCurrency: String {
        selectedBalanceAccounts.count == 1
            ? (selectedBalanceAccounts.first?.currencyCode ?? appSettings.preferredCurrency)
            : appSettings.preferredCurrency
    }

    private var recentTransactions: [Transaction] {
        let ids = Set(profileAccounts.map(\.id))
        return Array(allTransactions.filter { tx in
            guard let aid = tx.account?.id else { return false }
            return ids.contains(aid)
        }.prefix(3))
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5...11: "Good morning,"
        case 12...17: "Good afternoon,"
        default: "Good evening,"
        }
    }

    var body: some View {
        ZStack {
            PageBackground()

            ScrollView {
                VStack(spacing: Space.l) {
                    header

                    if appSettings.homeShowBalance {
                        BalanceHero(
                            label: balanceLabel,
                            amount: totalBalance,
                            currency: balanceCurrency,
                            accountNames: isAllAccountsSelected ? [] : selectedBalanceAccounts.map(accountDisplayName),
                            isHidden: Binding(
                                get: { appSettings.hideBalance },
                                set: { appSettings.hideBalance = $0 }
                            ),
                            onPickAccounts: { showAccountsPicker = true }
                        )
                    }

                    if appSettings.homeShowActions {
                        actionPills
                            .padding(.horizontal, Space.screen)
                    }

                    if appSettings.homeShowAccounts {
                        accountsSection
                    }

                    if appSettings.homeShowTransactions {
                        transactionsSection
                    }
                }
                .padding(.top, Space.s)
                .padding(.bottom, Space.xl)
            }
            .scrollContentBackground(.hidden)
        }
        .addTransactionFAB {
            addTransactionRequest = AddTransactionRequest(type: .expense, accountID: selectedBalanceAccounts.first?.id ?? profileAccounts.first?.id)
        }
        .sheet(isPresented: $showProfileSwitcher) {
            ProfileSwitcherSheet()
        }
        .sheet(isPresented: $showAccountsPicker) {
            if let profile = currentProfile {
                BalanceAccountsPickerSheet(profile: profile, accounts: profileAccounts)
            }
        }
        .sheet(item: $editingAccount) { account in
            AccountEditorSheet(profile: currentProfile, accountToEdit: account)
        }
        .sheet(isPresented: $addingAccount) {
            AccountEditorSheet(profile: currentProfile, accountToEdit: nil)
        }
        .sheet(isPresented: $showAllTransactions) {
            AllTransactionsScreen(accounts: profileAccounts)
        }
        .sheet(item: $showSavings) { account in
            SavingsEnvelopesScreen(account: account)
        }
    }

    private func accountDisplayName(_ account: Account) -> String {
        DisplayNameResolver.resolve(account.name, language: appSettings.language)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.footnote)
                    .foregroundStyle(Tokens.textSecondary)
                Text(currentProfile?.name ?? "")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Tokens.textPrimary)
            }
            Spacer()
            Button {
                Haptics.impact(.light)
                showProfileSwitcher = true
            } label: {
                Image(systemName: (ProfileIconKey(rawValue: currentProfile?.pictogram ?? "") ?? .cat).symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Tokens.onAccent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Tokens.accent))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Space.screen)
    }

    private var actionPills: some View {
        HStack(spacing: Space.s) {
            Button {
                addTransactionRequest = AddTransactionRequest(type: .expense, accountID: selectedBalanceAccounts.first?.id ?? profileAccounts.first?.id)
            } label: {
                Label("Expense", systemImage: "arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Tokens.expense)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .liquidGlass(Capsule(style: .continuous), interactive: true)

            Button {
                addTransactionRequest = AddTransactionRequest(type: .income, accountID: selectedBalanceAccounts.first?.id ?? profileAccounts.first?.id)
            } label: {
                Label("Income", systemImage: "arrow.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Tokens.income)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .liquidGlass(Capsule(style: .continuous), interactive: true)
        }
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            HStack {
                Text("My accounts")
                    .font(.headline)
                    .foregroundStyle(Tokens.textPrimary)
                Spacer()
                Button {
                    Haptics.impact(.light)
                    addingAccount = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Tokens.accentOnSurface)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Space.screen)

            if profileAccounts.isEmpty {
                EmptyState(systemImage: "creditcard", text: "No accounts yet")
                    .padding(.horizontal, Space.screen)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Space.s) {
                        ForEach(profileAccounts) { account in
                            Button {
                                Haptics.impact(.light)
                                if account.accountType == .savings {
                                    showSavings = account
                                } else {
                                    editingAccount = account
                                }
                            } label: {
                                AccountCard(
                                    name: accountDisplayName(account),
                                    type: account.accountType,
                                    currencyCode: account.currencyCode,
                                    colorHex: account.colorHex,
                                    balance: BalanceService.balance(for: account),
                                    isHidden: appSettings.hideBalance
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Space.screen)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
            }
        }
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            HStack {
                Text("Recent transactions")
                    .font(.headline)
                    .foregroundStyle(Tokens.textPrimary)
                Spacer()
                Button("More") {
                    Haptics.impact(.light)
                    showAllTransactions = true
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Tokens.accentOnSurface)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Space.screen)

            if recentTransactions.isEmpty {
                EmptyState(systemImage: "tray", text: "No transactions yet")
                    .padding(.horizontal, Space.screen)
            } else {
                LazyVStack(spacing: Space.s) {
                    ForEach(recentTransactions) { tx in
                        TransactionRow(
                            transaction: tx,
                            language: appSettings.language,
                            colorCodeTransactions: appSettings.colorCodeTransactions
                        )
                    }
                }
                .padding(.horizontal, Space.screen)
            }
        }
    }
}
