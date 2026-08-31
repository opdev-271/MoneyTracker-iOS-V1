//
//  SavingsEnvelopesScreen.swift
//  Tracki
//

import SwiftUI
import SwiftData

/// Opens from tapping a SAVINGS-type account card (A6.8). Header shows the
/// account's total balance, how much is earmarked into envelopes, and what's
/// left unallocated.
struct SavingsEnvelopesScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext

    let account: Account

    @State private var showAdd = false
    @State private var editingEnvelope: SavingsEnvelope?
    @State private var depositingEnvelope: SavingsEnvelope?

    private var envelopes: [SavingsEnvelope] {
        (account.envelopes ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    private var totalBalance: Double { BalanceService.balance(for: account) }
    private var envelopedTotal: Double { BalanceService.envelopedTotal(for: account) }
    private var unallocated: Double { totalBalance - envelopedTotal }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(spacing: Space.l) {
                        header
                        if envelopes.isEmpty {
                            EmptyState(systemImage: "banknote", text: "No envelopes yet")
                        } else {
                            VStack(spacing: Space.s) {
                                ForEach(envelopes) { envelope in
                                    envelopeRow(envelope)
                                }
                            }
                        }
                    }
                    .padding(Space.screen)
                }
            }
            .navigationTitle(DisplayNameResolver.resolve(account.name, language: appSettings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            EnvelopeEditorSheet(account: account, envelopeToEdit: nil)
        }
        .sheet(item: $editingEnvelope) { envelope in
            EnvelopeEditorSheet(account: account, envelopeToEdit: envelope)
        }
        .sheet(item: $depositingEnvelope) { envelope in
            DepositToEnvelopeSheet(envelope: envelope)
        }
    }

    private var header: some View {
        ContentCard {
            HStack {
                statColumn(title: "Total balance", value: totalBalance)
                Divider().frame(height: 40).overlay(Tokens.hairline)
                statColumn(title: "In envelopes", value: envelopedTotal)
                Divider().frame(height: 40).overlay(Tokens.hairline)
                statColumn(title: "Unallocated", value: unallocated)
            }
        }
    }

    private func statColumn(title: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(Tokens.textSecondary).multilineTextAlignment(.center)
            Text(CurrencyFormatter.format(value, account.currencyCode))
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Tokens.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func envelopeRow(_ envelope: SavingsEnvelope) -> some View {
        let progress = envelope.goalAmount > 0 ? min(envelope.currentAmount / envelope.goalAmount, 1) : 0
        return Button {
            depositingEnvelope = envelope
        } label: {
            VStack(alignment: .leading, spacing: Space.s) {
                HStack {
                    Text(envelope.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Tokens.textPrimary)
                    Spacer()
                    Text("\(CurrencyFormatter.format(envelope.currentAmount, account.currencyCode)) / \(CurrencyFormatter.format(envelope.goalAmount, account.currencyCode))")
                        .font(.caption)
                        .foregroundStyle(Tokens.textSecondary)
                }
                ProgressView(value: progress)
                    .tint(Color(hex: envelope.colorHex))
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: Radius.cardSmall, style: .continuous)
                    .fill(Tokens.surfaceRaised)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { editingEnvelope = envelope } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { delete(envelope) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func delete(_ envelope: SavingsEnvelope) {
        Haptics.impact(.rigid)
        modelContext.delete(envelope)
        try? modelContext.save()
    }
}
