//
//  AddTransactionScreen.swift
//  Tracki
//

import SwiftUI
import SwiftData

/// Add or edit a transaction (A6.4). Validation order: amount > 0 → account
/// picked → category picked, surfaced inline (not as three sequential
/// toasts like Android) plus `Haptics.error()`.
struct AddTransactionScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.sortOrder) private var allAccounts: [Account]

    let request: AddTransactionRequest
    var transactionToEdit: Transaction?

    @State private var type: TransactionType
    @State private var amountText: String
    @State private var selectedAccountID: UUID?
    @State private var selectedCategory: Category?
    @State private var date: Date
    @State private var note: String
    @State private var showAccountPicker = false
    @State private var showCategoryPicker = false
    @State private var errorMessage: String?

    init(request: AddTransactionRequest, transactionToEdit: Transaction? = nil) {
        self.request = request
        self.transactionToEdit = transactionToEdit
        _type = State(initialValue: transactionToEdit?.type ?? request.type)
        _amountText = State(initialValue: transactionToEdit.map { formatEditableAmount($0.amount) } ?? "")
        _selectedAccountID = State(initialValue: transactionToEdit?.account?.id ?? request.accountID)
        _selectedCategory = State(initialValue: transactionToEdit?.category)
        _date = State(initialValue: transactionToEdit?.date ?? .now)
        _note = State(initialValue: transactionToEdit?.note ?? "")
    }

    private var selectedAccount: Account? {
        allAccounts.first { $0.id == selectedAccountID } ?? allAccounts.first
    }

    private var amountValue: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()

                ScrollView {
                    VStack(spacing: Space.l) {
                        GlassSegmentedPicker(
                            options: [(TransactionType.expense, "Expense"), (TransactionType.income, "Income")],
                            selection: Binding(
                                get: { type },
                                set: { newValue in
                                    type = newValue
                                    selectedCategory = nil // A6.4: switching type clears category
                                }
                            )
                        )

                        amountField

                        ContentCard {
                            VStack(spacing: 0) {
                                row(title: "Account", value: selectedAccount.map(accountLabel) ?? "Select an account") {
                                    showAccountPicker = true
                                }
                                Divider().overlay(Tokens.hairline)
                                row(title: "Category", value: selectedCategory.map(categoryLabel) ?? "Select a category") {
                                    showCategoryPicker = true
                                }
                                Divider().overlay(Tokens.hairline)
                                DatePicker("Date", selection: $date, displayedComponents: .date)
                                    .font(.subheadline)
                                    .tint(Tokens.accentOnSurface)
                                    .padding(.vertical, 14)
                            }
                        }

                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Description").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            TextField("Optional", text: $note, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(16)
                                .background {
                                    RoundedRectangle(cornerRadius: Radius.inner, style: .continuous)
                                        .fill(Tokens.surfaceRaised)
                                }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(Tokens.expense)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(Space.screen)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle(transactionToEdit == nil ? "Add transaction" : "Edit transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    save()
                } label: {
                    Text("Save")
                        .font(.headline)
                        .foregroundStyle(Tokens.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .liquidGlass(Capsule(style: .continuous), tint: Tokens.accent.opacity(0.7), interactive: true)
                .padding(.horizontal, Space.screen)
                .padding(.bottom, Space.s)
            }
        }
        .sheet(isPresented: $showAccountPicker) {
            AccountPickerSheet(accounts: allAccounts, selection: $selectedAccountID)
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(type: type, selection: $selectedCategory)
        }
    }

    private var amountField: some View {
        HStack {
            Text(CurrencyFormatter.symbol(for: selectedAccount?.currencyCode))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Tokens.textSecondary)
            TextField("0", text: $amountText)
                .keyboardType(.decimalPad)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Tokens.textPrimary)
        }
    }

    private func row(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(.subheadline).foregroundStyle(Tokens.textSecondary)
                Spacer()
                Text(value).font(.subheadline.weight(.medium)).foregroundStyle(Tokens.textPrimary)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Tokens.textTertiary)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func accountLabel(_ account: Account) -> String {
        DisplayNameResolver.resolve(account.name, language: appSettings.language)
    }

    private func categoryLabel(_ category: Category) -> String {
        DisplayNameResolver.resolve(category.name, language: appSettings.language)
    }

    private func save() {
        guard let amount = amountValue, amount > 0 else {
            errorMessage = "Enter an amount"
            Haptics.error()
            return
        }
        guard let account = selectedAccount else {
            errorMessage = "Select an account"
            Haptics.error()
            return
        }
        guard let category = selectedCategory else {
            errorMessage = "Select a category"
            Haptics.error()
            return
        }

        if let transaction = transactionToEdit {
            transaction.type = type
            transaction.amount = amount
            transaction.account = account
            transaction.category = category
            transaction.date = date
            transaction.note = note.isEmpty ? nil : note
        } else {
            let transaction = Transaction(
                type: type,
                amount: amount,
                note: note.isEmpty ? nil : note,
                date: date,
                account: account,
                category: category
            )
            modelContext.insert(transaction)
        }
        try? modelContext.save()
        Haptics.success()
        dismiss()
    }
}

private func formatEditableAmount(_ value: Double) -> String {
    value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
}

private struct AccountPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    let accounts: [Account]
    @Binding var selection: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(spacing: Space.s) {
                        ForEach(accounts) { account in
                            Button {
                                Haptics.selection()
                                selection = account.id
                                dismiss()
                            } label: {
                                HStack(spacing: Space.m) {
                                    Circle().fill(Color(hex: account.colorHex)).frame(width: 12, height: 12)
                                    Text(DisplayNameResolver.resolve(account.name, language: appSettings.language))
                                        .font(.subheadline)
                                        .foregroundStyle(Tokens.textPrimary)
                                    Spacer()
                                    Text(account.currencyCode)
                                        .font(.caption)
                                        .foregroundStyle(Tokens.textSecondary)
                                    if selection == account.id {
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
                        }
                    }
                    .padding(Space.screen)
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
