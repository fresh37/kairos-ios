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

struct HabitsView: View {
    @Query(filter: #Predicate<HabitGoal> { $0.isActive })
    private var activeGoals: [HabitGoal]

    @Environment(\.modelContext) private var modelContext

    @State private var showCreateGoal = false
    @State private var showAddHabit = false
    @State private var showResetConfirmation = false
    @State private var habitToEdit: Habit? = nil

    private var activeGoal: HabitGoal? { activeGoals.first }

    var body: some View {
        ZStack {
            Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255)
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
            // Progress card
            progressCard(goal)
                .padding(.horizontal, 20)
                .padding(.top, 24)

            // Habit list
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
                                    .fill(.white.opacity(0.05))
                                    .padding(.vertical, 0.5)
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
                                .tint(Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255))
                            }
                    }
                    .onMove { from, to in
                        var reordered = sorted(goal.habits)
                        reordered.move(fromOffsets: from, toOffset: to)
                        for (i, h) in reordered.enumerated() { h.order = i }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(.top, 16)
            }

            // Bottom buttons
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
                    Button("Reset Goal") {
                        showResetConfirmation = true
                    }
                    Spacer()
                    Button("Undo") {
                        if let c = mostRecentCompletion(for: goal) {
                            modelContext.delete(c)
                        }
                    }
                    .disabled(goal.habits.flatMap(\.completions).isEmpty)
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
                Button("Reset Goal", role: .destructive) {
                    goal.isActive = false
                }
            }
        }
    }

    // MARK: - Progress card

    private func progressCard(_ goal: HabitGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(goal.name)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255),
                                    Color(red: 0x4a/255, green: 0x94/255, blue: 0xd0/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * goal.progress)
                        .animation(.spring(duration: 0.5), value: goal.currentCents)
                }
            }
            .frame(height: 10)

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
                    .foregroundColor(Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Completion

    private func completeHabit(_ habit: Habit, goal: HabitGoal) {
        let completion = HabitCompletion(amountCents: habit.rewardCents, habit: habit)
        modelContext.insert(completion)

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if goal.currentCents >= goal.targetCents {
            withAnimation(.easeInOut(duration: 0.55)) {
                goal.isCompleted = true
                goal.completedAt = Date()
            }
        }
    }

    private func mostRecentCompletion(for goal: HabitGoal) -> HabitCompletion? {
        goal.habits
            .flatMap { $0.completions }
            .max { $0.completedAt < $1.completedAt }
    }

    // MARK: - Helpers

    private func sorted(_ habits: [Habit]) -> [Habit] {
        habits.sorted { $0.order < $1.order }
    }

    private func renumberOrder(goal: HabitGoal) {
        for (i, h) in sorted(goal.habits).enumerated() { h.order = i }
    }
}
