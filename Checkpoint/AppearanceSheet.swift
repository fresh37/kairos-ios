//
//  AppearanceSheet.swift
//  Checkpoint
//
//  Full-screen theme picker. Presented from SettingsDrawer.
//  Selecting a theme applies immediately — the sheet re-themes itself live.
//

import SwiftUI

struct AppearanceSheet: View {
    @Binding var selectedThemeID: String
    @Environment(\.dismiss) private var dismiss

    private var selectedTheme: AppTheme { AppTheme.theme(for: selectedThemeID) }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                selectedTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AppTheme.all) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: theme.id == selectedThemeID
                            ) {
                                selectedThemeID = theme.id
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(selectedTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(selectedTheme.accent)
                }
            }
        }
        .colorScheme(.dark)
        .environment(\.appTheme, selectedTheme)
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void

    private var orbGradient: RadialGradient {
        RadialGradient(
            stops: [
                .init(color: theme.orbHighlight, location: 0.00),
                .init(color: theme.accentLight,  location: 0.30),
                .init(color: theme.accent,        location: 0.62),
                .init(color: theme.accentDeep,   location: 0.85),
                .init(color: theme.orbRim,        location: 1.00),
            ],
            center: UnitPoint(x: 0.42, y: 0.36),
            startRadius: 0,
            endRadius: 24
        )
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Mini orb
                HStack {
                    ZStack {
                        Circle()
                            .fill(orbGradient)
                            .frame(width: 48, height: 48)
                            .shadow(color: theme.glowColor.opacity(0.35), radius: 10)
                            .shadow(color: theme.glowColor.opacity(0.12), radius: 20)

                        if theme.yarnBall {
                            Image("yarn-ball")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .scaleEffect(1.45)
                                .clipShape(Circle())
                                .allowsHitTesting(false)
                        }
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(theme.accent)
                    }
                }
                .padding(.bottom, 20)

                Spacer()

                Text(theme.name)
                    .font(.system(size: 14, weight: .medium))
                    .tracking(0.1)
                    .foregroundStyle(.white.opacity(0.88))
            }
            .padding(16)
            .frame(height: 120)
            .background(theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? theme.accent : .white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    AppearanceSheet(selectedThemeID: .constant("midnight"))
}
