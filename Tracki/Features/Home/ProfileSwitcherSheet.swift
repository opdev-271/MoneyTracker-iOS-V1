//
//  ProfileSwitcherSheet.swift
//  Tracki
//

import SwiftUI
import SwiftData

struct ProfileSwitcherSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.sortOrder) private var profiles: [Profile]

    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(spacing: Space.s) {
                        ForEach(profiles) { profile in
                            Button {
                                Haptics.selection()
                                appSettings.activeProfileID = profile.id
                                dismiss()
                            } label: {
                                row(profile)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Space.screen)
                }
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(Radius.sheet)
        .sheet(isPresented: $showAdd) {
            AddProfileSheet()
        }
    }

    private func row(_ profile: Profile) -> some View {
        HStack(spacing: Space.m) {
            Image(systemName: (ProfileIconKey(rawValue: profile.pictogram) ?? .cat).symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Tokens.onAccent)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Tokens.accent))

            Text(profile.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Tokens.textPrimary)

            Spacer()

            if profile.id == appSettings.activeProfileID {
                Image(systemName: "checkmark")
                    .foregroundStyle(Tokens.accentOnSurface)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: Radius.cardSmall, style: .continuous)
                .fill(Tokens.surfaceRaised)
        }
    }
}

private struct AddProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.modelContext) private var modelContext
    @Query private var existingProfiles: [Profile]

    @State private var name = ""
    @State private var pictogram: ProfileIconKey = .cat

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.l) {
                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Name").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            TextField("Name", text: $name)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background {
                                    RoundedRectangle(cornerRadius: Radius.inner, style: .continuous)
                                        .fill(Tokens.surfaceRaised)
                                }
                        }

                        VStack(alignment: .leading, spacing: Space.s) {
                            Text("Avatar").font(.footnote).foregroundStyle(Tokens.textSecondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Space.s), count: 4), spacing: Space.s) {
                                ForEach(ProfileIconKey.allCases) { icon in
                                    let selected = pictogram == icon
                                    Button {
                                        Haptics.selection()
                                        pictogram = icon
                                    } label: {
                                        Image(systemName: icon.symbolName)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundStyle(selected ? Tokens.onAccent : Tokens.textPrimary)
                                            .frame(width: 56, height: 56)
                                            .background(Circle().fill(selected ? Tokens.accent : Tokens.surfaceRaised))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(Space.screen)
                }
            }
            .navigationTitle("New profile")
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
    }

    private func save() {
        let profile = Profile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            pictogram: pictogram.rawValue,
            sortOrder: existingProfiles.count
        )
        modelContext.insert(profile)
        try? modelContext.save()
        appSettings.activeProfileID = profile.id
        dismiss()
    }
}
