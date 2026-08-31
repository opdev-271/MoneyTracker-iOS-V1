//
//  CategoryEditorSheet.swift
//  Tracki
//

import SwiftUI
import SwiftData

/// Add/edit a category: name, icon (21-icon grid), color (20-color grid),
/// type. Shared between the category picker's "+ Add category" quick-add
/// (A6.4) and the full category management screen (A6.9).
struct CategoryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext

    var categoryToEdit: Category?
    var defaultType: TransactionType = .expense
    /// Called with the saved category so the caller (e.g. the picker) can
    /// select it immediately.
    var onSaved: ((Category) -> Void)?

    @State private var name: String
    @State private var type: TransactionType
    @State private var icon: CategoryIconKey
    @State private var colorHex: String

    init(categoryToEdit: Category? = nil, defaultType: TransactionType = .expense, onSaved: ((Category) -> Void)? = nil) {
        self.categoryToEdit = categoryToEdit
        self.defaultType = defaultType
        self.onSaved = onSaved
        _name = State(initialValue: "")
        _type = State(initialValue: categoryToEdit?.type ?? defaultType)
        _icon = State(initialValue: categoryToEdit.flatMap { $0.icon.flatMap(CategoryIconKey.init(rawValue:)) } ?? .other)
        _colorHex = State(initialValue: categoryToEdit?.colorHex ?? Palette.categoryColors[0])
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
                            TextField("e.g. Groceries", text: $name)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background {
                                    RoundedRectangle(cornerRadius: Radius.inner, style: .continuous)
                                        .fill(Tokens.surfaceRaised)
                                }
                        }

                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Type").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            GlassSegmentedPicker(
                                options: [(TransactionType.expense, "Expense"), (TransactionType.income, "Income")],
                                selection: $type
                            )
                        }

                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Icon").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Space.s), count: 5), spacing: Space.s) {
                                ForEach(CategoryIconKey.allCases) { key in
                                    let selected = icon == key
                                    Button {
                                        Haptics.selection()
                                        icon = key
                                    } label: {
                                        Image(systemName: key.symbolName)
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundStyle(selected ? Color(hex: colorHex).contrastingForeground : Tokens.textPrimary)
                                            .frame(width: 44, height: 44)
                                            .background(Circle().fill(selected ? Color(hex: colorHex) : Tokens.surfaceRaised))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Color").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            ColorSwatchRow(colors: Palette.categoryColors, selected: $colorHex, columns: 5)
                        }
                    }
                    .padding(Space.screen)
                }
            }
            .navigationTitle(categoryToEdit == nil ? "New category" : "Edit category")
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
        .onAppear {
            if let categoryToEdit {
                name = DisplayNameResolver.resolve(categoryToEdit.name, language: appSettings.language)
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let category: Category
        if let existing = categoryToEdit {
            existing.name = trimmed
            existing.type = type
            existing.icon = icon.rawValue
            existing.colorHex = colorHex
            category = existing
        } else {
            category = Category(name: trimmed, type: type, icon: icon.rawValue, colorHex: colorHex)
            modelContext.insert(category)
        }
        try? modelContext.save()
        onSaved?(category)
        dismiss()
    }
}
