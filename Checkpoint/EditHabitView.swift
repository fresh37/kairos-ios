//
//  EditHabitView.swift
//  Checkpoint
//
//  Sheet form for editing an existing habit's name and reward.
//

import SwiftData
import SwiftUI

private extension Color {
    static let eBackground  = Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255)
    static let eSurface     = Color(red: 0x18/255, green: 0x21/255, blue: 0x30/255)
    static let eAccent      = Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255)
    static let eTextPrimary = Color.white.opacity(0.88)
    static let eTextMuted   = Color.white.opacity(0.38)
    static let eDivider     = Color.white.opacity(0.07)
}

struct EditHabitView: View {
    let habit: Habit

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var amountText: String
    @State private var showHabitLoop = false
    @State private var cueText: String
    @State private var cravingText: String

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        let dollars = Double(habit.rewardCents) / 100.0
        _amountText = State(initialValue: String(format: "%.2f", dollars))
        _cueText = State(initialValue: habit.cue)
        _cravingText = State(initialValue: habit.craving)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.eBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        habitSection
                        rewardSection
                        habitLoopSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.eBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.eAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEdits() }
                        .foregroundStyle(isValid ? Color.eAccent : Color.eTextMuted)
                        .disabled(!isValid)
                }
            }
        }
        .colorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.eBackground)
    }

    // MARK: - Sections

    private var habitSection: some View {
        settingsGroup(label: "Habit") {
            TextField("e.g. Meditate 10 min", text: $name)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.eTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
        }
    }

    private var rewardSection: some View {
        settingsGroup(label: "Reward") {
            HStack {
                Text("$")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.eTextMuted)
                TextField("0.00", text: $amountText)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.eTextPrimary)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
    }

    private var habitLoopSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            settingsGroup(label: "Habit Loop") {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { showHabitLoop.toggle() }
                } label: {
                    HStack {
                        Text("Think it through")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color.eTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.eTextMuted)
                            .rotationEffect(.degrees(showHabitLoop ? 180 : 0))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }

                if showHabitLoop {
                    rowDivider

                    VStack(alignment: .leading, spacing: 4) {
                        Text("CUE")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.2)
                            .foregroundStyle(Color.eTextMuted)
                        TextField("After I ___", text: $cueText)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color.eTextPrimary)
                        Text("The trigger that reliably precedes this habit")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color.eTextMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)

                    rowDivider

                    VStack(alignment: .leading, spacing: 4) {
                        Text("CRAVING")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.2)
                            .foregroundStyle(Color.eTextMuted)
                        TextField("I want to feel ___", text: $cravingText)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color.eTextPrimary)
                        Text("The feeling or outcome that motivates this habit")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color.eTextMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }
            }

            Text("Optional. Mapping the cue and craving behind a habit helps it stick.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color.eTextMuted)
                .padding(.leading, 4)
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.eDivider)
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    // MARK: - Group container

    @ViewBuilder
    private func settingsGroup<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Color.eTextMuted)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.eSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Validation & save

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amountCents != nil
    }

    private var amountCents: Int? {
        guard let value = Double(amountText), value > 0 else { return nil }
        return Int((value * 100).rounded())
    }

    private func saveEdits() {
        guard let cents = amountCents,
              !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        habit.name = name.trimmingCharacters(in: .whitespaces)
        habit.rewardCents = cents
        habit.cue = cueText.trimmingCharacters(in: .whitespaces)
        habit.craving = cravingText.trimmingCharacters(in: .whitespaces)
        dismiss()
    }
}
