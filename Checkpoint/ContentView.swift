//
//  ContentView.swift
//  Checkpoint
//
//  Entry point. Routes to OnboardingView on first launch, otherwise
//  shows the main view (breathing orb + gear button).
//  Also re-schedules notifications every time the app comes to the foreground.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var prefs = Preferences.load()
    @State private var showSettings = false
    @State private var showWelcome = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView(prefs: $prefs, showSettings: $showSettings, showWelcome: $showWelcome)
                    .sheet(isPresented: $showSettings) {
                        SettingsDrawer(prefs: $prefs)
                    }
                    .onChange(of: prefs) { _, newPrefs in
                        newPrefs.save()
                        NotificationScheduler.scheduleNotifications(prefs: newPrefs)
                    }
            } else {
                OnboardingView(prefs: $prefs, isComplete: $hasCompletedOnboarding, showWelcome: $showWelcome)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, hasCompletedOnboarding {
                NotificationScheduler.scheduleNotifications(prefs: prefs)
            }
        }
    }
}

#Preview {
    ContentView()
}
