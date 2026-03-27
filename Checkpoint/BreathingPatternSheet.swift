//
//  BreathingPatternSheet.swift
//  Checkpoint
//
//  Pattern selector sheet for the Breathe tab.
//  Presents preset patterns and a custom timing editor.
//

import SwiftUI

private let sheetBackground = Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255)
private let rowBackground   = Color(red: 0x17/255, green: 0x24/255, blue: 0x30/255)
private let separator       = Color(red: 0x2a/255, green: 0x38/255, blue: 0x4a/255)
private let mutedColor      = Color(red: 0x6c/255, green: 0x7a/255, blue: 0x8d/255)
private let primaryColor    = Color.white.opacity(0.88)

private let patternDescriptions: [String: String] = [
    "box":        "Focus & balance",
    "478":        "Relaxation & sleep",
    "coherent":   "Heart rate balance",
    "energizing": "Alertness & energy",
    "custom":     "Your own rhythm",
]

struct BreathingPatternSheet: View {
    @Binding var pattern: BreathingPattern
    @Environment(\.dismiss) private var dismiss

    // Local draft for custom pattern edits
    @State private var customDraft: BreathingPattern = .custom
    @State private var showCustomEditor = false

    var body: some View {
        NavigationView {
            ZStack {
                sheetBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        sectionHeader("PATTERN")

                        VStack(spacing: 0) {
                            ForEach(BreathingPattern.presets) { preset in
                                patternRow(preset)
                            }
                            customRow
                        }
                        .background(rowBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)

                        if showCustomEditor {
                            timingSection
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Breathing Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(primaryColor)
                }
            }
        }
        .onAppear {
            if !pattern.isPreset {
                customDraft = pattern
                showCustomEditor = true
            }
        }
    }

    // MARK: - Rows

    private func patternRow(_ p: BreathingPattern) -> some View {
        let isSelected = pattern.id == p.id
        return Button {
            pattern = p
            showCustomEditor = false
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(p.name)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(primaryColor)
                    Text(patternDescriptions[p.id] ?? "")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(mutedColor)
                }
                Spacer()
                Text(p.ratio)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(mutedColor)
                    .padding(.trailing, isSelected ? 8 : 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            separator.frame(height: 0.5).padding(.leading, 16)
        }
    }

    private var customRow: some View {
        let isSelected = pattern.id == "custom"
        return Button {
            if !isSelected {
                // Apply default custom or existing custom draft
                pattern = customDraft
            }
            withAnimation(.easeInOut(duration: 0.25)) {
                showCustomEditor.toggle()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Custom")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(primaryColor)
                    Text(patternDescriptions["custom"] ?? "")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(mutedColor)
                }
                Spacer()
                if isSelected {
                    Text(pattern.ratio)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(mutedColor)
                        .padding(.trailing, 8)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255))
                        .padding(.trailing, 8)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(mutedColor)
                    .rotationEffect(.degrees(showCustomEditor ? 180 : 0))
                    .animation(.easeInOut(duration: 0.25), value: showCustomEditor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Timing Editor

    private var timingSection: some View {
        VStack(spacing: 0) {
            sectionHeader("TIMING")

            VStack(spacing: 0) {
                stepperRow(label: "Inhale", value: $customDraft.inhale, range: 1...12)
                stepperRow(label: "Hold", value: $customDraft.holdIn, range: 0...12, zeroLabel: "skip")
                stepperRow(label: "Exhale", value: $customDraft.exhale, range: 1...12)
                stepperRow(label: "Hold", value: $customDraft.holdOut, range: 0...12, zeroLabel: "skip", isLast: true)
            }
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
        }
        .onChange(of: customDraft) {
            pattern = customDraft
        }
    }

    private func stepperRow(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        zeroLabel: String? = nil,
        isLast: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(primaryColor)
            Spacer()
            if let zeroLabel, value.wrappedValue == 0 {
                Text(zeroLabel)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(mutedColor)
                    .padding(.trailing, 6)
            } else {
                Text("\(value.wrappedValue)s")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(mutedColor)
                    .padding(.trailing, 6)
            }
            Stepper("", value: value, in: range)
                .labelsHidden()
                .tint(mutedColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if !isLast {
                separator.frame(height: 0.5).padding(.leading, 16)
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .regular))
                .tracking(11 * 0.08)
                .foregroundStyle(mutedColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            Spacer()
        }
    }
}

extension BreathingPattern: Identifiable {}

#Preview {
    BreathingPatternSheet(pattern: .constant(.box))
}
