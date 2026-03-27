//
//  HabitGoal.swift
//  Checkpoint

import Foundation
import SwiftData

@Model
final class HabitGoal {
    var id: UUID = UUID()
    var name: String = ""
    var targetCents: Int = 0
    var isActive: Bool = false
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Habit.goal)
    var habits: [Habit] = []

    var currentCents: Int {
        habits.flatMap(\.completions).reduce(0) { $0 + $1.amountCents }
    }

    var progress: Double {
        guard targetCents > 0 else { return 0 }
        return min(1.0, Double(currentCents) / Double(targetCents))
    }

    var formattedCurrent: String {
        formatCents(currentCents)
    }

    var formattedTarget: String {
        formatCents(targetCents)
    }

    private func formatCents(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        return dollars.formatted(.currency(code: "USD"))
    }

    init(name: String, targetCents: Int) {
        self.name = name
        self.targetCents = targetCents
        self.isActive = true
    }
}
