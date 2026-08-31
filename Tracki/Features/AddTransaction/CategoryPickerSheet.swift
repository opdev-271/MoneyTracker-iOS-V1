//
//  CategoryPickerSheet.swift
//  Tracki
//

import SwiftUI
import SwiftData

/// Category picker filtered to the current transaction type, plus a
/// "+ Add category" row that opens the editor and immediately selects the
/// new category on save (A6.4).
struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Query private var allCategories: [Category]

    let type: TransactionType
    @Binding var selection: Category?

    @State private var showEditor = false

    private var categories: [Category] {
        allCategories
            .filter { $0.type == type }
            .sorted {
                DisplayNameResolver.resolve($0.name, language: appSettings.language)
                    .localizedStandardCompare(DisplayNameResolver.resolve($1.name, language: appSettings.language)) == .orderedAscending
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(spacing: Space.s) {
                        Button {
                            showEditor = true
                        } label: {
                            HStack(spacing: Space.m) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Tokens.accentOnSurface)
                                Text("Add category")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Tokens.accentOnSurface)
                                Spacer()
                            }
                            .padding(14)
                            .background {
                                RoundedRectangle(cornerRadius: Radius.cardSmall, style: .continuous)
                                    .fill(Tokens.surfaceRaised)
                            }
                        }
                        .buttonStyle(.plain)

                        ForEach(categories) { category in
                            Button {
                                Haptics.selection()
                                selection = category
                                dismiss()
                            } label: {
                                row(category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Space.screen)
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showEditor) {
            CategoryEditorSheet(defaultType: type) { saved in
                selection = saved
                dismiss()
            }
        }
    }

    private func row(_ category: Category) -> some View {
        let color = Color(hex: category.colorHex)
        return HStack(spacing: Space.m) {
            ZStack {
                Circle().fill(color)
                if let icon = category.icon, let key = CategoryIconKey(rawValue: icon) {
                    Image(systemName: key.symbolName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(color.contrastingForeground)
                }
            }
            .frame(width: 36, height: 36)

            Text(DisplayNameResolver.resolve(category.name, language: appSettings.language))
                .font(.subheadline)
                .foregroundStyle(Tokens.textPrimary)

            Spacer()

            if selection?.id == category.id {
                Image(systemName: "checkmark").foregroundStyle(Tokens.accentOnSurface)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: Radius.cardSmall, style: .continuous)
                .fill(Tokens.surfaceRaised)
        }
    }
}
