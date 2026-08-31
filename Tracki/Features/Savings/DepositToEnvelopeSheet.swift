//
//  DepositToEnvelopeSheet.swift
//  Tracki
//

import SwiftUI
import SwiftData

/// "Send money to %s" (A6.8). Picking the envelope's own account as the
/// source just earmarks money already there; picking any other account
/// creates a real expense/income transaction pair — all handled by
/// `SavingsEnvelopeService`.
struct DepositToEnvelopeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.sortOrder) private var allAccounts: [Account]

    let envelope: SavingsEnvelope

    @State private var sourceAccountID: UUID?
    @State private var amountText = ""

    private var profileAccounts: [Account] {
        guard let profile = envelope.account?.profile else { return [] }
        return allAccounts.filter { $0.profile?.id == profile.id }
    }

    private var sourceAccount: Account? {
        allAccounts.first { $0.id == sourceAccountID } ?? envelope.account
    }

    private var amountValue: Double? { Double(amountText.replacingOccurrences(of: ",", with: ".")) }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                VStack(alignment: .leading, spacing: Space.l) {
                    VStack(alignment: .leading, spacing: Space.s) {
                        Text("From account").font(.footnote).foregroundStyle(Tokens.textSecondary)
                        ForEach(profileAccounts) { account in
                            Button {
                                Haptics.selection()
                                sourceAccountID = account.id
                            } label: {
                                HStack {
                                    Circle().fill(Color(hex: account.colorHex)).frame(width: 12, height: 12)
                                    Text(DisplayNameResolver.resolve(account.name, language: appSettings.language))
                                        .font(.subheadline)
                                        .foregroundStyle(Tokens.textPrimary)
                                    Spacer()
                                    if (sourceAccountID ?? envelope.account?.id) == account.id {
                                        Image(systemName: "checkmark").foregroundStyle(Tokens.accentOnSurface)
                                    }
                                }
                                .padding(14)
                                .background {
                                    RoundedRectangle(cornerRadius: Radius.cardSmall, style: .continuous).fill(Tokens.surfaceRaised)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: Space.s) {
                        Text("Amount").font(.footnote).foregroundStyle(Tokens.textSecondary)
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background {
                                RoundedRectangle(cornerRadius: Radius.inner, style: .continuous).fill(Tokens.surfaceRaised)
                            }
                    }

                    Spacer()

                    Button {
                        send()
                    } label: {
                        Text("Send")
                            .font(.headline)
                            .foregroundStyle(Tokens.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    .liquidGlass(Capsule(style: .continuous), tint: Tokens.accent.opacity(0.7), interactive: true)
                    .disabled((amountValue ?? 0) <= 0)
                    .opacity((amountValue ?? 0) > 0 ? 1 : 0.5)
                }
                .padding(Space.screen)
            }
            .navigationTitle("Send to \(envelope.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }

    private func send() {
        guard let amount = amountValue, amount > 0, let source = sourceAccount else { return }
        SavingsEnvelopeService.deposit(amount: amount, into: envelope, from: source, context: modelContext)
        Haptics.success()
        dismiss()
    }
}
