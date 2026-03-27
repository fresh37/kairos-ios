//
//  Habit.swift
//  Checkpoint

import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var rewardCents: Int = 0
    var order: Int = 0
    var cue: String = ""
    var craving: String = ""
    var goal: HabitGoal?

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    var formattedReward: String {
        let dollars = Double(rewardCents) / 100.0
        return dollars.formatted(.currency(code: "USD"))
    }

    init(name: String, rewardCents: Int, goal: HabitGoal) {
        self.name = name
        self.rewardCents = rewardCents
        self.goal = goal
    }
}
