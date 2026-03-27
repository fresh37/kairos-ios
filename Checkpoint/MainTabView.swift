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

struct MainTabView: View {
    @Binding var prefs: Preferences
    @Binding var showSettings: Bool
    @Binding var showWelcome: Bool

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL)    private var openURL

    // Persists whether the user has opened settings at least once.
    // Gear renders at higher opacity until first visit, then recedes.
    @AppStorage("hasOpenedSettings") private var hasOpenedSettings = false

    // Refreshed on appear and every foreground transition.
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    // Drives the fade in/out of the post-onboarding confirmation line.
    @State private var confirmationOpacity: Double = 0
    @State private var showPatternSheet = false

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
            Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                BreathingOrbView(pattern: prefs.breathingPattern)

                Button { showPatternSheet = true } label: {
                    HStack(spacing: 6) {
                        Text(prefs.breathingPattern.name)
                        Text("·")
                        Text(prefs.breathingPattern.ratio)
                    }
                    .font(.system(size: 13, weight: .regular))
                    .tracking(13 * 0.08)
                    .foregroundStyle(Color(red: 0x6c/255, green: 0x7a/255, blue: 0x8d/255))
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showPatternSheet) {
                BreathingPatternSheet(pattern: $prefs.breathingPattern)
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
                HStack {
                    // Denied state — quiet, tappable, positioned to mirror the gear
                    if notifStatus == .denied {
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
                            .padding(28)
                        }
                    }

                    Spacer()

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
                }
            }
        }
    }

    // MARK: - Helpers

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notifStatus = settings.authorizationStatus
            }
        }
    }
}

#Preview {
    MainTabView(
        prefs: .constant(Preferences()),
        showSettings: .constant(false),
        showWelcome: .constant(false)
    )
}
