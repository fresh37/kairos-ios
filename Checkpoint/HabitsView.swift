//
//  HabitsView.swift
//  Checkpoint
//
//  Root view for the Habits tab. Three states:
//    - No active goal → empty state with "Create Goal" prompt
//    - Active goal → progress card + habit list + completion buttons
//    - Goal completed → celebration overlay
//

import SwiftData
import SwiftUI
import UIKit

struct HabitsView: View {
    @Query(filter: #Predicate<HabitGoal> { $0.isActive })
    private var activeGoals: [HabitGoal]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme)     private var theme

    @State private var showCreateGoal = false
    @State private var showAddHabit = false
    @State private var showResetConfirmation = false
    @State private var showHistory = false
    @State private var habitToEdit: Habit?
    @State private var completingHabitID: UUID?
    @State private var progressPulse = false
    @State private var shimmerPhase: CGFloat = 0

    private var activeGoal: HabitGoal? { activeGoals.first }

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            if let goal = activeGoal {
                if goal.isCompleted {
                    GoalCompletedView(goal: goal)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.04, anchor: .center)),
                            removal: .opacity
                        ))
                } else {
                    activeGoalContent(goal)
                        .transition(.opacity)
                }
            } else {
                emptyState
            }
        }
        .sheet(isPresented: $showCreateGoal) {
            CreateGoalView()
        }
        .sheet(isPresented: $showAddHabit) {
            if let goal = activeGoal {
                AddHabitView(goal: goal)
            }
        }
        .sheet(item: $habitToEdit) { habit in
            EditHabitView(habit: habit)
        }
        .sheet(isPresented: $showHistory) {
            if let goal = activeGoal {
                HabitHistoryView(goal: goal)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.3))

            Text("Set a goal and build habits\nto earn toward it.")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button {
                showCreateGoal = true
            } label: {
                Text("Create Goal")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Active goal

    private func activeGoalContent(_ goal: HabitGoal) -> some View {
        VStack(spacing: 0) {
            progressCard(goal)
                .padding(.horizontal, 20)
                .padding(.top, 24)
            habitListContent(goal)
            goalBottomButtons(goal)
        }
    }

    @ViewBuilder
    private func habitListContent(_ goal: HabitGoal) -> some View {
        if goal.habits.isEmpty {
            Spacer()
            Text("Add your first habit below.")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.white.opacity(0.4))
            Spacer()
        } else {
            List {
                ForEach(sorted(goal.habits)) { habit in
                    habitRow(habit, goal: goal)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(completingHabitID == habit.id
                                    ? theme.accent.opacity(0.18)
                                    : .white.opacity(0.05))
                                .padding(.vertical, 0.5)
                                .animation(.easeOut(duration: 0.15), value: completingHabitID)
                        )
                        .listRowInsets(EdgeInsets(top: 0.5, leading: 20, bottom: 0.5, trailing: 20))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(habit)
                                renumberOrder(goal: goal)
                            } label: {
                                Image(systemName: "trash")
                            }
                            Button { habitToEdit = habit } label: {
                                Image(systemName: "pencil")
                            }
                            .tint(theme.accent)
                        }
                }
                .onMove { from, destination in
                    var reordered = sorted(goal.habits)
                    reordered.move(fromOffsets: from, toOffset: destination)
                    for (index, habit) in reordered.enumerated() { habit.order = index }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.top, 16)
        }
    }

    private func goalBottomButtons(_ goal: HabitGoal) -> some View {
        VStack(spacing: 12) {
            Button {
                showAddHabit = true
            } label: {
                Label("Add Habit", systemImage: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Button("Reset Goal") { showResetConfirmation = true }
                Spacer()
                Button("History") { showHistory = true }
            }
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.25))
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .confirmationDialog(
            "Reset this goal? Progress will be archived.",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Goal", role: .destructive) { goal.isActive = false }
        }
    }

    // MARK: - Progress card

    private func progressCard(_ goal: HabitGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(goal.name)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            ProgressBarTrack(goal: goal, theme: theme, progressPulse: progressPulse, shimmerPhase: shimmerPhase)
            HStack {
                Text(goal.formattedCurrent)
                    .contentTransition(.numericText())
                    .animation(.default, value: goal.currentCents)
                Spacer()
                Text(goal.formattedTarget)
            }
            .font(.system(size: 14, weight: .light))
            .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Habit row

    private func habitRow(_ habit: Habit, goal: HabitGoal) -> some View {
        Button {
            completeHabit(habit, goal: goal)
        } label: {
            HStack {
                Text(habit.name)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Text("+\(habit.formattedReward)")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(completingHabitID == habit.id ? .white : theme.accent)
                    .scaleEffect(completingHabitID == habit.id ? 1.1 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.55), value: completingHabitID)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .buttonStyle(HabitRowButtonStyle())
    }

    // MARK: - Completion

    private func completeHabit(_ habit: Habit, goal: HabitGoal) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.easeOut(duration: 0.12)) {
            completingHabitID = habit.id
        }

        let completion = HabitCompletion(amountCents: habit.rewardCents, habit: habit)
        modelContext.insert(completion)

        withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
            progressPulse = true
        }

        shimmerPhase = 0
        withAnimation(.easeOut(duration: 0.65).delay(0.08)) {
            shimmerPhase = 1.2
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                completingHabitID = nil
                progressPulse = false
            }
        }

        if goal.currentCents >= goal.targetCents {
            withAnimation(.easeInOut(duration: 0.55)) {
                goal.isCompleted = true
                goal.completedAt = Date()
            }
        }
    }

    // MARK: - Helpers

    private func sorted(_ habits: [Habit]) -> [Habit] {
        habits.sorted { $0.order < $1.order }
    }

    private func renumberOrder(goal: HabitGoal) {
        for (index, habit) in sorted(goal.habits).enumerated() { habit.order = index }
    }
}

// MARK: - Supporting types

private struct ProgressBarTrack: View {
    let goal: HabitGoal
    let theme: AppTheme
    let progressPulse: Bool
    let shimmerPhase: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.1))
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [theme.accent, theme.accentDeep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * goal.progress)
                    .animation(.spring(response: 0.45, dampingFraction: 0.62), value: goal.currentCents)
                    .shadow(color: theme.glowColor.opacity(progressPulse ? 0.55 : 0), radius: 6, x: 0, y: 0)
                    .animation(.easeOut(duration: 0.5), value: progressPulse)
                    .overlay(
                        GeometryReader { fillGeo in
                            let shimmerWidth: CGFloat = 50
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.45), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: shimmerWidth)
                                .offset(x: (shimmerPhase * (fillGeo.size.width + shimmerWidth)) - shimmerWidth)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    )
            }
        }
        .frame(height: 10)
    }
}

private struct HabitRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
