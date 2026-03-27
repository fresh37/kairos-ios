//
//  HabitCompletion.swift
//  Checkpoint

import Foundation
import SwiftData

@Model
final class HabitCompletion {
    var id: UUID = UUID()
    var completedAt: Date = Date()
    var amountCents: Int = 0
    var habit: Habit?

    init(amountCents: Int, habit: Habit) {
        self.amountCents = amountCents
        self.habit = habit
    }
}
