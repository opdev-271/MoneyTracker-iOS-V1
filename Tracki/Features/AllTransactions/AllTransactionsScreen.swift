//
//  AllTransactionsScreen.swift
//  Tracki
//

import SwiftUI
import SwiftData

/// All transactions across the given accounts, grouped by day with a daily
/// saldo in each section header (A6.5). Swipe to delete, context menu to
/// duplicate, tap to edit — the iOS-native equivalent of Android's
/// long-press multi-select toolbar (A6.7).
struct AllTransactionsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    let accounts: [Account]

    @State private var searchText = ""
    @State private var editingTransaction: Transaction?

    private var accountIDs: Set<UUID> { Set(accounts.map(\.id)) }

    private var filtered: [Transaction] {
        allTransactions.filter { tx in
            guard let aid = tx.account?.id, accountIDs.contains(aid) else { return false }
            guard !searchText.isEmpty else { return true }
            let categoryName = tx.category.map { DisplayNameResolver.resolve($0.name, language: appSettings.language) } ?? ""
            return categoryName.localizedCaseInsensitiveContains(searchText)
                || (tx.note ?? "").localizedCaseInsensitiveContains(searchText)
                || (tx.counterparty ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedByDay: [(day: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        var groups: [Date: [Transaction]] = [:]
        var order: [Date] = []
        for tx in filtered {
            let day = calendar.startOfDay(for: tx.date)
            if groups[day] == nil { order.append(day) }
            groups[day, default: []].append(tx)
        }
        return order.map { (day: $0, transactions: groups[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()

                if groupedByDay.isEmpty {
                    EmptyState(systemImage: "tray", text: "No transactions yet")
                } else {
                    List {
                        ForEach(groupedByDay, id: \.day) { group in
                            Section {
                                ForEach(group.transactions) { tx in
                                    Button {
                                        editingTransaction = tx
                                    } label: {
                                        TransactionRow(
                                            transaction: tx,
                                            language: appSettings.language,
                                            colorCodeTransactions: appSettings.colorCodeTransactions
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) { delete(tx) } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .contextMenu {
                                        Button { duplicate(tx) } label: {
                                            Label("Duplicate", systemImage: "plus.square.on.square")
                                        }
                                        Button { editingTransaction = tx } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                    }
                                }
                            } header: {
                                dayHeader(group)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("All transactions")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(item: $editingTransaction) { tx in
            if let account = tx.account {
                AddTransactionScreen(
                    request: AddTransactionRequest(type: tx.type, accountID: account.id),
                    transactionToEdit: tx
                )
            }
        }
    }

    private func dayHeader(_ group: (day: Date, transactions: [Transaction])) -> some View {
        let saldo = group.transactions.reduce(0.0) { $0 + $1.signedAmount }
        let currency = group.transactions.first?.account?.currencyCode
        return HStack {
            Text(group.day.formatted(date: .abbreviated, time: .omitted))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Tokens.textSecondary)
            Spacer()
            Text(CurrencyFormatter.formatSigned(saldo, currency))
                .font(.caption.weight(.bold))
                .foregroundStyle(saldo < 0 ? Tokens.expense : Tokens.income)
        }
    }

    private func delete(_ tx: Transaction) {
        Haptics.impact(.rigid)
        modelContext.delete(tx)
        try? modelContext.save()
    }

    private func duplicate(_ tx: Transaction) {
        let copy = Transaction(
            type: tx.type, amount: tx.amount, counterparty: tx.counterparty,
            note: tx.note, date: tx.date, account: tx.account, category: tx.category
        )
        modelContext.insert(copy)
        try? modelContext.save()
        Haptics.success()
    }
}
