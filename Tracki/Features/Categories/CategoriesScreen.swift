//
//  CategoriesScreen.swift
//  Tracki
//

import SwiftUI
import SwiftData

/// A6.9. Deleting is non-destructive to transactions (FK is nullify on the
/// model side) but the confirmation still counts and shows how many
/// transactions will lose their category — from the button alone that isn't
/// obvious, and uncategorized amounts silently vanish from the Analytics
/// breakdown.
struct CategoriesScreen: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext
    @Query private var allCategories: [Category]

    @State private var addingType: TransactionType?
    @State private var editingCategory: Category?
    @State private var pendingDeletion: Category?

    private func categories(_ type: TransactionType) -> [Category] {
        allCategories
            .filter { $0.type == type }
            .sorted {
                DisplayNameResolver.resolve($0.name, language: appSettings.language)
                    .localizedStandardCompare(DisplayNameResolver.resolve($1.name, language: appSettings.language)) == .orderedAscending
            }
    }

    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(spacing: Space.l) {
                    group(title: "Expense categories", type: .expense)
                    group(title: "Income categories", type: .income)
                }
                .padding(Space.screen)
            }
        }
        .navigationTitle("Categories")
        .sheet(item: Binding(
            get: { addingType.map { AddCategoryRequest(type: $0) } },
            set: { addingType = $0?.type }
        )) { request in
            CategoryEditorSheet(defaultType: request.type)
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorSheet(categoryToEdit: category)
        }
        .confirmationDialog(deletionMessage, isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) { confirmDelete() }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        }
    }

    private var deletionMessage: String {
        guard let category = pendingDeletion else { return "" }
        let count = category.transactions?.count ?? 0
        if count == 0 { return "Delete this category?" }
        let noun = count == 1 ? "transaction uses" : "transactions use"
        return "\(count) \(noun) this category. They'll stay, but without a category."
    }

    private func group(title: String, type: TransactionType) -> some View {
        VStack(alignment: .leading, spacing: Space.s) {
            HStack {
                Text(title).font(.headline).foregroundStyle(Tokens.textPrimary)
                Spacer()
                Button {
                    addingType = type
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Tokens.accentOnSurface)
                }
                .buttonStyle(.plain)
            }

            if categories(type).isEmpty {
                EmptyState(systemImage: "tag", text: "No categories yet")
            } else {
                VStack(spacing: Space.s) {
                    ForEach(categories(type)) { category in
                        row(category)
                    }
                }
            }
        }
    }

    private func row(_ category: Category) -> some View {
        let color = Color(hex: category.colorHex)
        return Button {
            editingCategory = category
        } label: {
            HStack(spacing: Space.m) {
                ZStack {
                    Circle().fill(color)
                    if let icon = category.icon, let key = CategoryIconKey(rawValue: icon) {
                        Image(systemName: key.symbolName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(color.contrastingForeground)
                    }
                }
                .frame(width: 36, height: 36)

                Text(DisplayNameResolver.resolve(category.name, language: appSettings.language))
                    .font(.subheadline)
                    .foregroundStyle(Tokens.textPrimary)

                Spacer()

                Button {
                    pendingDeletion = category
                } label: {
                    Image(systemName: "trash")
                        .font(.footnote)
                        .foregroundStyle(Tokens.expense)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: Radius.cardSmall, style: .continuous).fill(Tokens.surfaceRaised)
            }
        }
        .buttonStyle(.plain)
    }

    private func confirmDelete() {
        guard let category = pendingDeletion else { return }
        Haptics.impact(.rigid)
        modelContext.delete(category)
        try? modelContext.save()
        pendingDeletion = nil
    }
}

private struct AddCategoryRequest: Identifiable {
    let id = UUID()
    let type: TransactionType
}
