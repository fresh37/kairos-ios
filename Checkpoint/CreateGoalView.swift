//
//  CreateGoalView.swift
//  Checkpoint
//
//  Sheet form for creating a new purchase goal.
//

import SwiftData
import SwiftUI
import Foundation

// MARK: - Colors

private extension Color {
    static let kBackground  = Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255)
    static let kSurface     = Color(red: 0x18/255, green: 0x21/255, blue: 0x30/255)
    static let kAccent      = Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255)
    static let kTextPrimary = Color.white.opacity(0.88)
    static let kTextMuted   = Color.white.opacity(0.38)
    static let kDivider     = Color.white.opacity(0.07)
}

// MARK: - View

struct CreateGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amountText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.kBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        goalSection
                        amountSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.kBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.kAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { saveGoal() }
                        .foregroundStyle(isValid ? Color.kAccent : Color.kTextMuted)
                        .disabled(!isValid)
                }
            }
        }
        .colorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.kBackground)
    }

    // MARK: - Sections

    private var goalSection: some View {
        settingsGroup(label: "What are you saving for?") {
            TextField("e.g. New running shoes", text: $name)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.kTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
        }
    }

    private var amountSection: some View {
        settingsGroup(label: "Goal Amount") {
            HStack {
                Text("$")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.kTextMuted)
                TextField("0.00", text: $amountText)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.kTextPrimary)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
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
                .foregroundStyle(Color.kTextMuted)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.kSurface)
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

    private func saveGoal() {
        guard let cents = amountCents,
              !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let goal = HabitGoal(name: name.trimmingCharacters(in: .whitespaces), targetCents: cents)
        modelContext.insert(goal)

        // Clone habits from the most recent previous goal
        let descriptor = FetchDescriptor<HabitGoal>(
            predicate: #Predicate { !$0.isActive },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let previousGoal = try? modelContext.fetch(descriptor).first {
            let sorted = previousGoal.habits.sorted { $0.order < $1.order }
            for (i, habit) in sorted.enumerated() {
                let clone = Habit(name: habit.name, rewardCents: habit.rewardCents, goal: goal)
                clone.order = i
                modelContext.insert(clone)
            }
        }

        dismiss()
    }
}
