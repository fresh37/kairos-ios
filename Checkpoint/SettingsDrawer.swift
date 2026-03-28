//
//  SettingsDrawer.swift
//  Checkpoint
//
//  Slide-up sheet for editing preferences.
//  Works on a local `draft` copy; validates and writes back to the
//  binding on every change — ContentView's onChange then saves + reschedules.
//

import SwiftUI
import UserNotifications
import UIKit

// MARK: - View

struct SettingsDrawer: View {
    @Binding var prefs: Preferences
    @State private var draft: Preferences
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    @Environment(\.openURL) private var openURL

    init(prefs: Binding<Preferences>) {
        _prefs = prefs
        _draft = State(initialValue: prefs.wrappedValue)
    }

    private var maxReminders: Int {
        guard draft.endHour > draft.startHour else { return 1 }
        return min(50, max(1, (draft.endHour - draft.startHour) * 60 / 15))
    }

    private var maxMeditationReminders: Int {
        guard draft.meditationEndHour > draft.meditationStartHour else { return 1 }
        return min(50, max(1, (draft.meditationEndHour - draft.meditationStartHour) * 60 / 15))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {

                        // Reminders
                        SettingsGroup(label: "Reminders") {
                            stepperRow(
                                label: "\(draft.remindersPerDay) \(draft.remindersPerDay == 1 ? "reminder" : "reminders") per day",
                                value: $draft.remindersPerDay,
                                range: 1...maxReminders
                            )
                        }

                        // Schedule
                        SettingsGroup(label: "Schedule") {
                            pickerRow(label: "Start",
                                      selection: $draft.startHour,
                                      values: Array(5...23))
                            rowDivider
                            pickerRow(label: "End",
                                      selection: $draft.endHour,
                                      values: Array(6...24))
                            rowDivider
                            daysRow
                        }

                        // Categories
                        SettingsGroup(label: "Categories") {
                            toggleRow(label: "Gratitude",      isOn: $draft.gratitude)
                            rowDivider
                            toggleRow(label: "Body Awareness", isOn: $draft.bodyAwareness)
                            rowDivider
                            toggleRow(label: "Present Moment", isOn: $draft.presentMoment)
                        }

                        // Meditation
                        SettingsGroup(label: "Meditation") {
                            toggleRow(label: "Enable", isOn: $draft.meditationEnabled)
                            if draft.meditationEnabled {
                                rowDivider
                                stepperRow(
                                    label: "\(draft.meditationRemindersPerDay) per day",
                                    value: $draft.meditationRemindersPerDay,
                                    range: 1...maxMeditationReminders
                                )
                                rowDivider
                                pickerRow(label: "Start",
                                          selection: $draft.meditationStartHour,
                                          values: Array(0...23))
                                rowDivider
                                pickerRow(label: "End",
                                          selection: $draft.meditationEndHour,
                                          values: Array(1...24))
                            }
                        }

                        // System
                        SettingsGroup(label: "System") {
                            toggleRow(label: "Haptic Feedback", isOn: $draft.hapticFeedback)
                            rowDivider
                            notificationsRow
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .colorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
        .task {
            let s = await UNUserNotificationCenter.current().notificationSettings()
            notifStatus = s.authorizationStatus
        }
        // Validate and sync to parent binding on every draft change.
        .onChange(of: draft) { _, _ in
            let validated = draft.validated()
            // Only write back to draft if validation corrected something,
            // to avoid a redundant onChange re-fire.
            if validated != draft { draft = validated }
            prefs = validated
        }
    }

    // MARK: - Row types

    @ViewBuilder
    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.appTextPrimary)
        }
        .tint(Color.appAccent)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    @ViewBuilder
    private func stepperRow(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.appTextPrimary)
            Spacer()
            Stepper("", value: value, in: range)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    @ViewBuilder
    private func pickerRow(label: String, selection: Binding<Int>, values: [Int]) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.appTextPrimary)
            Spacer()
            Picker("", selection: selection) {
                ForEach(values, id: \.self) { hour in
                    Text(hourLabel(hour)).tag(hour)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.appAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    // MARK: - Days row

    private var daysRow: some View {
        HStack(spacing: 0) {
            ForEach([1, 2, 3, 4, 5, 6, 7], id: \.self) { day in
                let isOn = draft.activeDays.contains(day)
                Button {
                    if isOn && draft.activeDays.count > 1 {
                        draft.activeDays.remove(day)
                    } else if !isOn {
                        draft.activeDays.insert(day)
                    }
                } label: {
                    Text(dayLetter(day))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isOn ? Color.appAccent : Color.appTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            isOn
                                ? Color.appAccent.opacity(0.12)
                                : Color.clear
                        )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: isOn)
            }
        }
    }

    private func dayLetter(_ weekday: Int) -> String {
        ["S", "M", "T", "W", "T", "F", "S"][weekday - 1]
    }

    // MARK: - Divider

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.appDivider)
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    // MARK: - Notifications row

    private var notificationsRow: some View {
        Button {
            handleNotificationsTap()
        } label: {
            HStack {
                Text(notificationsLabel)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }

    private var notificationsLabel: String {
        switch notifStatus {
        case .authorized, .provisional, .ephemeral:
            return draft.notificationsEnabled ? "Disable Notifications" : "Enable Notifications"
        default:
            return "Enable Notifications"
        }
    }

    private func handleNotificationsTap() {
        switch notifStatus {
        case .authorized, .provisional, .ephemeral:
            draft.notificationsEnabled.toggle()
        case .denied:
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                openURL(url)
            }
        default: // .notDetermined
            Task {
                let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
                notifStatus = granted ? .authorized : .denied
                if granted {
                    draft.notificationsEnabled = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0:  return "12 AM"
        case 12: return "12 PM"
        case 24: return "12 AM"
        default:
            let suffix = hour < 12 ? "AM" : "PM"
            let h = hour > 12 ? hour - 12 : hour
            return "\(h) \(suffix)"
        }
    }
}

#Preview {
    SettingsDrawer(prefs: .constant(Preferences()))
}
