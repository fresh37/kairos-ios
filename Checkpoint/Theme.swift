//
//  Theme.swift
//  Checkpoint
//
//  App theme definitions, environment injection, and shared UI components.
//

import SwiftUI

// MARK: - AppTheme

struct AppTheme: Equatable, Sendable {
    let id: String
    let name: String
    let background: Color
    let surface: Color
    let accent: Color
    let accentLight: Color
    let accentDeep: Color
    let muted: Color
    let textPrimary: Color
    let textMuted: Color
    let divider: Color
    // Orb-specific
    let orbHighlight: Color  // soft diffuse highlight at gradient center
    let orbRim: Color        // subtle deep rim color
    let glowColor: Color     // shadow/glow color for orb and rings

    // MARK: Built-in themes

    static let midnight = AppTheme(
        id: "midnight",
        name: "Midnight",
        background: Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255),
        surface: Color(red: 0x18/255, green: 0x21/255, blue: 0x30/255),
        accent: Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255),
        accentLight: Color(red: 0xa0/255, green: 0xd0/255, blue: 0xee/255),
        accentDeep: Color(red: 0x4a/255, green: 0x94/255, blue: 0xd0/255),
        muted: Color(red: 0x6c/255, green: 0x7a/255, blue: 0x8d/255),
        textPrimary: .white.opacity(0.88),
        textMuted: .white.opacity(0.38),
        divider: .white.opacity(0.07),
        orbHighlight: Color(red: 0xd8/255, green: 0xec/255, blue: 0xfa/255),
        orbRim: Color(red: 0x38/255, green: 0x80/255, blue: 0xc0/255),
        glowColor: Color(red: 137/255, green: 180/255, blue: 250/255),
    )

    static let dusk = AppTheme(
        id: "dusk",
        name: "Dusk",
        background: Color(red: 0x1a/255, green: 0x12/255, blue: 0x08/255),
        surface: Color(red: 0x26/255, green: 0x1c/255, blue: 0x0f/255),
        accent: Color(red: 0xe0/255, green: 0xa4/255, blue: 0x4a/255),
        accentLight: Color(red: 0xee/255, green: 0xc4/255, blue: 0x80/255),
        accentDeep: Color(red: 0xc4/255, green: 0x88/255, blue: 0x30/255),
        muted: Color(red: 0x8d/255, green: 0x7a/255, blue: 0x6c/255),
        textPrimary: .white.opacity(0.88),
        textMuted: .white.opacity(0.38),
        divider: .white.opacity(0.07),
        orbHighlight: Color(red: 0xfa/255, green: 0xec/255, blue: 0xd8/255),
        orbRim: Color(red: 0xa8/255, green: 0x60/255, blue: 0x20/255),
        glowColor: Color(red: 0xe0/255, green: 0xa4/255, blue: 0x4a/255),
    )

    static let ink = AppTheme(
        id: "ink",
        name: "Ink",
        background: Color(red: 0x0e/255, green: 0x0d/255, blue: 0x14/255),
        surface: Color(red: 0x16/255, green: 0x15/255, blue: 0x20/255),
        accent: Color(red: 0x9b/255, green: 0x8f/255, blue: 0xcc/255),
        accentLight: Color(red: 0xb8/255, green: 0xb0/255, blue: 0xe0/255),
        accentDeep: Color(red: 0x78/255, green: 0x70/255, blue: 0xb0/255),
        muted: Color(red: 0x6c/255, green: 0x6a/255, blue: 0x7d/255),
        textPrimary: .white.opacity(0.88),
        textMuted: .white.opacity(0.38),
        divider: .white.opacity(0.07),
        orbHighlight: Color(red: 0xe0/255, green: 0xde/255, blue: 0xf8/255),
        orbRim: Color(red: 0x50/255, green: 0x48/255, blue: 0x80/255),
        glowColor: Color(red: 0x9b/255, green: 0x8f/255, blue: 0xcc/255),
    )

    static let ember = AppTheme(
        id: "ember",
        name: "Ember",
        background: Color(red: 0x14/255, green: 0x0a/255, blue: 0x08/255),
        surface: Color(red: 0x20/255, green: 0x10/255, blue: 0x0c/255),
        accent: Color(red: 0xc0/255, green: 0x40/255, blue: 0x28/255),
        accentLight: Color(red: 0xd8/255, green: 0x6a/255, blue: 0x48/255),
        accentDeep: Color(red: 0x98/255, green: 0x28/255, blue: 0x14/255),
        muted: Color(red: 0x80/255, green: 0x60/255, blue: 0x58/255),
        textPrimary: .white.opacity(0.88),
        textMuted: .white.opacity(0.38),
        divider: .white.opacity(0.07),
        orbHighlight: Color(red: 0xf8/255, green: 0xd8/255, blue: 0xcc/255),
        orbRim: Color(red: 0x78/255, green: 0x18/255, blue: 0x08/255),
        glowColor: Color(red: 0xc0/255, green: 0x40/255, blue: 0x28/255)
    )

    static let forest = AppTheme(
        id: "forest",
        name: "Forest",
        background: Color(red: 0x09/255, green: 0x10/255, blue: 0x0c/255),
        surface: Color(red: 0x10/255, green: 0x1a/255, blue: 0x13/255),
        accent: Color(red: 0x5a/255, green: 0x98/255, blue: 0x68/255),
        accentLight: Color(red: 0x82/255, green: 0xb8/255, blue: 0x90/255),
        accentDeep: Color(red: 0x3c/255, green: 0x78/255, blue: 0x4c/255),
        muted: Color(red: 0x5a/255, green: 0x6e/255, blue: 0x5e/255),
        textPrimary: .white.opacity(0.88),
        textMuted: .white.opacity(0.38),
        divider: .white.opacity(0.07),
        orbHighlight: Color(red: 0xd4/255, green: 0xec/255, blue: 0xda/255),
        orbRim: Color(red: 0x28/255, green: 0x58/255, blue: 0x38/255),
        glowColor: Color(red: 0x5a/255, green: 0x98/255, blue: 0x68/255)
    )

    static let slate = AppTheme(
        id: "slate",
        name: "Slate",
        background: Color(red: 0x0c/255, green: 0x0e/255, blue: 0x10/255),
        surface: Color(red: 0x14/255, green: 0x18/255, blue: 0x1c/255),
        accent: Color(red: 0x88/255, green: 0x9a/255, blue: 0xac/255),
        accentLight: Color(red: 0xa8/255, green: 0xb8/255, blue: 0xc4/255),
        accentDeep: Color(red: 0x60/255, green: 0x78/255, blue: 0x90/255),
        muted: Color(red: 0x60/255, green: 0x6c/255, blue: 0x78/255),
        textPrimary: .white.opacity(0.88),
        textMuted: .white.opacity(0.38),
        divider: .white.opacity(0.07),
        orbHighlight: Color(red: 0xe0/255, green: 0xe8/255, blue: 0xf0/255),
        orbRim: Color(red: 0x40/255, green: 0x54/255, blue: 0x68/255),
        glowColor: Color(red: 0x88/255, green: 0x9a/255, blue: 0xac/255)
    )

    static let rose = AppTheme(
        id: "rose",
        name: "Rose",
        background: Color(red: 0x12/255, green: 0x0c/255, blue: 0x10/255),
        surface: Color(red: 0x1e/255, green: 0x14/255, blue: 0x1a/255),
        accent: Color(red: 0xb0/255, green: 0x68/255, blue: 0x88/255),
        accentLight: Color(red: 0xcc/255, green: 0x90/255, blue: 0xa8/255),
        accentDeep: Color(red: 0x8c/255, green: 0x48/255, blue: 0x68/255),
        muted: Color(red: 0x78/255, green: 0x60/255, blue: 0x6c/255),
        textPrimary: .white.opacity(0.88),
        textMuted: .white.opacity(0.38),
        divider: .white.opacity(0.07),
        orbHighlight: Color(red: 0xf4/255, green: 0xe0/255, blue: 0xe8/255),
        orbRim: Color(red: 0x78/255, green: 0x38/255, blue: 0x54/255),
        glowColor: Color(red: 0xb0/255, green: 0x68/255, blue: 0x88/255)
    )

    static let all: [AppTheme] = [.midnight, .dusk, .ink, .ember, .forest, .slate, .rose]

    static func theme(for id: String) -> AppTheme {
        all.first { $0.id == id } ?? .midnight
    }
}

extension AppTheme: Identifiable {}

// MARK: - Environment

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .midnight
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// MARK: - Legacy Color aliases (Midnight values; used by previews and any remaining static callsites)

extension Color {
    static let appBackground  = AppTheme.midnight.background
    static let appSurface     = AppTheme.midnight.surface
    static let appAccent      = AppTheme.midnight.accent
    static let appAccentLight = AppTheme.midnight.accentLight
    static let appAccentDeep  = AppTheme.midnight.accentDeep
    static let appMuted       = AppTheme.midnight.muted
    static let appTextPrimary = AppTheme.midnight.textPrimary
    static let appTextMuted   = AppTheme.midnight.textMuted
    static let appDivider     = AppTheme.midnight.divider
}

// MARK: - Reusable Components

struct SettingsGroup<Content: View>: View {
    @Environment(\.appTheme) private var theme
    let label: String
    var infoAction: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(theme.textMuted)
                if let infoAction {
                    Button(action: infoAction) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
