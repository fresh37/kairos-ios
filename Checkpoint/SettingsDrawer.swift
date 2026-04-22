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
    @State private var showAppearance = false
    @State private var showCustomMessages = false
    @State private var showScheduleInfo = false
    @Environment(\.appTheme) private var theme
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
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {

                        // Appearance
                        SettingsGroup(label: "Appearance") {
                            Button {
                                showAppearance = true
                            } label: {
                                HStack {
                                    Text("Theme")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundStyle(theme.textPrimary)
                                    Spacer()
                                    Text(AppTheme.theme(for: draft.themeID).name)
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundStyle(theme.textMuted)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(theme.textMuted)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                            }
                            .buttonStyle(.plain)
                        }

                        // Reminders
                        SettingsGroup(label: "Reminders") {
                            let unit = draft.remindersPerDay == 1 ? "reminder" : "reminders"
                            stepperRow(
                                label: "\(draft.remindersPerDay) \(unit) per day",
                                value: $draft.remindersPerDay,
                                range: 1...maxReminders
                            )
                        }

                        // Schedule
                        SettingsGroup(label: "Schedule", infoAction: { showScheduleInfo = true }, content: {
                            pickerRow(label: "Start",
                                      selection: $draft.startHour,
                                      values: Array(1...23))
                            rowDivider
                            pickerRow(label: "End",
                                      selection: $draft.endHour,
                                      values: Array(2...24))
                            rowDivider
                            daysRow(activeDays: $draft.activeDays)
                        })

                        // Categories
                        SettingsGroup(label: "Categories") {
                            toggleRow(label: "Gratitude", isOn: $draft.gratitude)
                            rowDivider
                            toggleRow(label: "Body Awareness", isOn: $draft.bodyAwareness)
                            rowDivider
                            toggleRow(label: "Present Moment", isOn: $draft.presentMoment)
                        }

                        // Custom Messages
                        SettingsGroup(label: "Custom Messages") {
                            Button {
                                showCustomMessages = true
                            } label: {
                                HStack {
                                    Text("My Messages")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundStyle(theme.textPrimary)
                                    Spacer()
                                    Text(draft.customMessages.isEmpty ? "None" : "\(draft.customMessages.count)")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundStyle(theme.textMuted)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(theme.textMuted)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                            }
                            .buttonStyle(.plain)
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
                                rowDivider
                                daysRow(activeDays: $draft.meditationActiveDays)
                            }
                        }

                        // System
                        SettingsGroup(label: "System") {
                            notificationsRow
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .alert("About Your Schedule", isPresented: $showScheduleInfo) {
                Button("Got it") { }
            } message: {
                Text(
                    "Notifications are spread naturally across your schedule window, " +
                    "so they arrive at varied times rather than all at once."
                )
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .colorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(theme.background)
        .sheet(isPresented: $showAppearance) {
            AppearanceSheet(selectedThemeID: $draft.themeID)
        }
        .sheet(isPresented: $showCustomMessages) {
            CustomMessagesSheet(
                messages: $draft.customMessages,
                isEnabled: $draft.customMessagesEnabled
            )
            .environment(\.appTheme, AppTheme.theme(for: draft.themeID))
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notifStatus = settings.authorizationStatus
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

}

// MARK: - Row helpers

private extension SettingsDrawer {
    @ViewBuilder
    func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(theme.textPrimary)
        }
        .tint(theme.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    @ViewBuilder
    func stepperRow(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Stepper("", value: value, in: range)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    @ViewBuilder
    func pickerRow(label: String, selection: Binding<Int>, values: [Int]) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Picker("", selection: selection) {
                ForEach(values, id: \.self) { hour in
                    Text(hourLabel(hour)).tag(hour)
                }
            }
            .pickerStyle(.menu)
            .tint(theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    func daysRow(activeDays: Binding<Set<Int>>) -> some View {
        HStack(spacing: 0) {
            ForEach([1, 2, 3, 4, 5, 6, 7], id: \.self) { day in
                let isOn = activeDays.wrappedValue.contains(day)
                Button {
                    if isOn && activeDays.wrappedValue.count > 1 {
                        activeDays.wrappedValue.remove(day)
                    } else if !isOn {
                        activeDays.wrappedValue.insert(day)
                    }
                } label: {
                    Text(dayLetter(day))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isOn ? theme.accent : theme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isOn ? theme.accent.opacity(0.12) : Color.clear)
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: isOn)
            }
        }
    }

    func dayLetter(_ weekday: Int) -> String {
        ["S", "M", "T", "W", "T", "F", "S"][weekday - 1]
    }

    var rowDivider: some View {
        Rectangle()
            .fill(theme.divider)
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    var notificationsRow: some View {
        Button {
            handleNotificationsTap()
        } label: {
            HStack {
                Text(notificationsLabel)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }

    var notificationsLabel: String {
        switch notifStatus {
        case .authorized, .provisional, .ephemeral:
            return draft.notificationsEnabled ? "Disable Notifications" : "Enable Notifications"
        default:
            return "Enable Notifications"
        }
    }

    func handleNotificationsTap() {
        switch notifStatus {
        case .authorized, .provisional, .ephemeral:
            draft.notificationsEnabled.toggle()
        case .denied:
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                openURL(url)
            }
        default: // .notDetermined
            Task {
                let granted = (try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
                notifStatus = granted ? .authorized : .denied
                if granted {
                    draft.notificationsEnabled = true
                }
            }
        }
    }

    func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0:  return "12 AM"
        case 12: return "12 PM"
        case 24: return "12 AM"
        default:
            let suffix = hour < 12 ? "AM" : "PM"
            let displayHour = hour > 12 ? hour - 12 : hour
            return "\(displayHour) \(suffix)"
        }
    }
}

#Preview {
    SettingsDrawer(prefs: .constant(Preferences()))
}
