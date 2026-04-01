//
//  MainTabView.swift
//  Checkpoint
//
//  Bottom tab bar wrapping the Breathe and Habits tabs.
//  iOS 26 TabView automatically renders Liquid Glass.
//

import SwiftUI
import UserNotifications
import UIKit
import AudioToolbox

struct MainTabView: View {
    @Binding var prefs: Preferences
    @Binding var showSettings: Bool
    @Binding var showWelcome: Bool

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL)    private var openURL
    @Environment(\.appTheme)   private var theme

    // Persists whether the user has opened settings at least once.
    // Gear renders at higher opacity until first visit, then recedes.
    @AppStorage("hasOpenedSettings") private var hasOpenedSettings = false

    // Refreshed on appear and every foreground transition.
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    // Drives the fade in/out of the post-onboarding confirmation line.
    @State private var confirmationOpacity: Double = 0
    @State private var showPatternSheet = false
    @State private var showTimerSheet = false

    // MARK: - Session state
    @State private var sessionActive = false
    @State private var sessionRemainingSeconds = 0
    @State private var sessionBellIntervalSeconds: Int? = nil
    @State private var sessionPatternOverride: BreathingPattern? = nil
    @State private var sessionTask: Task<Void, Never>? = nil
    @State private var secondsSinceLastBell = 0

    var body: some View {
        TabView {
            Tab("Breathe", systemImage: "wind") {
                breatheContent
            }
            Tab("Habits", systemImage: "star.fill") {
                HabitsView()
            }
        }
        .onAppear { checkNotificationStatus() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { checkNotificationStatus() }
        }
    }

    private var breatheContent: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            if !theme.backgroundImageNames.isEmpty {
                KittiesBackground(imageNames: theme.backgroundImageNames)
            }

            VStack(spacing: 16) {
                BreathingOrbView(pattern: activePattern, isRunning: orbIsRunning)

                Button { showPatternSheet = true } label: {
                    HStack(spacing: 6) {
                        Text(activePattern.name)
                        Text("·")
                        Text(activePattern.ratio)
                    }
                    .font(.system(size: 13, weight: .regular))
                    .tracking(13 * 0.08)
                    .foregroundStyle(theme.muted)
                }
                .buttonStyle(.plain)

                if sessionActive {
                    Text(formattedCountdown)
                        .font(.system(size: 13, weight: .light))
                        .tracking(0.1)
                        .foregroundStyle(Color.white.opacity(0.38))
                        .monospacedDigit()
                        .transition(.opacity.animation(.easeInOut(duration: 0.4)))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: sessionActive)
            .toolbar(sessionActive ? .hidden : .visible, for: .tabBar)
            .sheet(isPresented: $showPatternSheet) {
                BreathingPatternSheet(pattern: $prefs.breathingPattern)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showTimerSheet) {
                BreathingTimerSheet(initialPattern: prefs.breathingPattern) { duration, bellInterval, pattern in
                    startSession(durationSeconds: duration, bellIntervalSeconds: bellInterval, pattern: pattern)
                }
                .environment(\.appTheme, theme)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }

            // Post-onboarding confirmation — appears once, then fades away.
            // Positioned in the lower third, below the orb and its phase label.
            if showWelcome {
                VStack(spacing: 0) {
                    Spacer()
                    Spacer()
                    Spacer()
                    Text("Reminders scheduled.")
                        .font(.system(size: 13, weight: .light))
                        .tracking(0.25)
                        .foregroundStyle(Color.white.opacity(0.52))
                    Spacer()
                }
                .opacity(confirmationOpacity)
                .task(id: showWelcome) {
                    guard showWelcome else { confirmationOpacity = 0; return }
                    // Let the orb settle before the text appears.
                    try? await Task.sleep(for: .milliseconds(600))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.7)) { confirmationOpacity = 1 }
                    // Visible for 2 seconds.
                    try? await Task.sleep(for: .seconds(2))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.8)) { confirmationOpacity = 0 }
                    try? await Task.sleep(for: .milliseconds(850))
                    showWelcome = false
                }
            }

            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Denied state — quiet, tappable, stacked above timer button
                        if notifStatus == .denied && !sessionActive {
                            Button {
                                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                    openURL(url)
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "bell.slash")
                                        .font(.system(size: 13, weight: .light))
                                    Text("Notifications off")
                                        .font(.system(size: 13, weight: .light))
                                        .tracking(0.1)
                                }
                                .foregroundColor(.white.opacity(0.38))
                                .padding(.horizontal, 28)
                                .padding(.vertical, 6)
                            }
                        }

                        Button {
                            if sessionActive {
                                stopSession()
                            } else {
                                showTimerSheet = true
                            }
                        } label: {
                            Image(systemName: sessionActive ? "xmark" : "timer")
                                .contentTransition(.symbolEffect(.replace))
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(.white.opacity(sessionActive ? 0.65 : 0.45))
                                .padding(28)
                        }
                        .accessibilityLabel("Session Timer")
                        .animation(.easeInOut(duration: 0.4), value: sessionActive)
                    }

                    Spacer()

                    if !sessionActive {
                        Button {
                            showSettings = true
                            hasOpenedSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(.white.opacity(hasOpenedSettings ? 0.45 : 0.65))
                                .padding(28)
                        }
                        .accessibilityLabel("Settings")
                        .animation(.easeInOut(duration: 0.6), value: hasOpenedSettings)
                        .transition(.opacity)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func checkNotificationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notifStatus = settings.authorizationStatus
        }
    }

    // MARK: - Session

    private var activePattern: BreathingPattern {
        (sessionActive || sessionPatternOverride != nil) ? (sessionPatternOverride ?? prefs.breathingPattern) : prefs.breathingPattern
    }

    /// Orb runs normally, or runs during an active session, but stops briefly at session end.
    private var orbIsRunning: Bool {
        // No session: always running
        guard sessionPatternOverride != nil else { return true }
        // Session is live: orb runs
        return sessionActive
    }

    private var formattedCountdown: String {
        let m = sessionRemainingSeconds / 60
        let s = sessionRemainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func startSession(durationSeconds: Int, bellIntervalSeconds: Int?, pattern: BreathingPattern) {
        sessionTask?.cancel()
        sessionRemainingSeconds = durationSeconds
        sessionBellIntervalSeconds = bellIntervalSeconds
        sessionPatternOverride = pattern
        secondsSinceLastBell = 0
        sessionActive = true

        sessionTask = Task { @MainActor in
            while sessionRemainingSeconds > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                sessionRemainingSeconds -= 1
                secondsSinceLastBell += 1

                if let interval = sessionBellIntervalSeconds,
                   secondsSinceLastBell >= interval,
                   sessionRemainingSeconds > 0 {
                    playBell()
                    secondsSinceLastBell = 0
                }
            }
            guard !Task.isCancelled else { return }
            // Session complete: play bell and stop the orb
            playBell()
            sessionActive = false
            // Brief pause then resume with global pattern
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            sessionPatternOverride = nil
            sessionActive = true
        }
    }

    private func stopSession() {
        sessionTask?.cancel()
        sessionTask = nil
        sessionActive = false
        sessionPatternOverride = nil
        sessionRemainingSeconds = 0
        sessionBellIntervalSeconds = nil
        secondsSinceLastBell = 0
    }

    private func playBell() {
        AudioServicesPlaySystemSound(1013)
    }
}

#Preview {
    MainTabView(
        prefs: .constant(Preferences()),
        showSettings: .constant(false),
        showWelcome: .constant(false)
    )
}
