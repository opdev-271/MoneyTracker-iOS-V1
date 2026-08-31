//
//  EnvelopeEditorSheet.swift
//  Tracki
//

import SwiftUI
import SwiftData

struct EnvelopeEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let account: Account
    var envelopeToEdit: SavingsEnvelope?

    @State private var name: String
    @State private var goalText: String
    @State private var colorHex: String

    init(account: Account, envelopeToEdit: SavingsEnvelope?) {
        self.account = account
        self.envelopeToEdit = envelopeToEdit
        _name = State(initialValue: envelopeToEdit?.name ?? "")
        _goalText = State(initialValue: envelopeToEdit.map { String($0.goalAmount) } ?? "")
        _colorHex = State(initialValue: envelopeToEdit?.colorHex ?? Palette.accountColors[0])
    }

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.l) {
                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Name").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            TextField("e.g. New laptop", text: $name)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background {
                                    RoundedRectangle(cornerRadius: Radius.inner, style: .continuous).fill(Tokens.surfaceRaised)
                                }
                        }
                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Goal amount").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            TextField("0", text: $goalText)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background {
                                    RoundedRectangle(cornerRadius: Radius.inner, style: .continuous).fill(Tokens.surfaceRaised)
                                }
                        }
                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Color").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            ColorSwatchRow(colors: Palette.accountColors, selected: $colorHex)
                        }
                    }
                    .padding(Space.screen)
                }
            }
            .navigationTitle(envelopeToEdit == nil ? "New envelope" : "Edit envelope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid) }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let goal = Double(goalText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let envelope = envelopeToEdit {
            envelope.name = trimmed
            envelope.goalAmount = goal
            envelope.colorHex = colorHex
        } else {
            let envelope = SavingsEnvelope(
                name: trimmed, goalAmount: goal, currentAmount: 0, colorHex: colorHex,
                sortOrder: account.envelopes?.count ?? 0, account: account
            )
            modelContext.insert(envelope)
        }
        try? modelContext.save()
        dismiss()
    }
}
