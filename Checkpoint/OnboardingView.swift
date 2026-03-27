//
//  OnboardingView.swift
//  Checkpoint
//
//  Shown once on first launch. Requests notification permission, then
//  calls scheduleNotifications() before handing off to the main view.
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Binding var prefs: Preferences
    @Binding var isComplete: Bool
    @Binding var showWelcome: Bool

    @Environment(\.scenePhase) private var scenePhase

    @State private var isRequesting = false
    @State private var isExpanded   = false
    @State private var breathTask: Task<Void, Never>?
    @State private var appeared     = false

    // Glow colour — matches BreathingOrbView exactly
    private let glowColor = Color(red: 137/255, green: 180/255, blue: 250/255)

    var body: some View {
        ZStack {
            Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Animated orb — same cycle as BreathingOrbView
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: Color(red: 0xd8/255, green: 0xec/255, blue: 0xfa/255), location: 0.00),
                                .init(color: Color(red: 0xa0/255, green: 0xd0/255, blue: 0xee/255), location: 0.30),
                                .init(color: Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255), location: 0.60),
                                .init(color: Color(red: 0x4a/255, green: 0x94/255, blue: 0xd0/255), location: 0.85),
                                .init(color: Color(red: 0x38/255, green: 0x80/255, blue: 0xc0/255), location: 1.00),
                            ],
                            center: UnitPoint(x: 0.42, y: 0.36),
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: glowColor.opacity(isExpanded ? 0.40 : 0.25),
                            radius: isExpanded ? 28 : 19)
                    .shadow(color: glowColor.opacity(isExpanded ? 0.15 : 0.08),
                            radius: isExpanded ? 50 : 38)
                    .scaleEffect(isExpanded ? 1.2 : 1.0)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 1.0).delay(0.1), value: appeared)
                    .padding(.bottom, 48)

                // Title
                Text("Checkpoint")
                    .font(.system(size: 46, weight: .ultraLight))
                    .tracking(-0.5)
                    .foregroundColor(.white.opacity(0.92))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.8).delay(0.45), value: appeared)

                // Subtitle
                Text("Brief pauses, delivered throughout your day.\nNothing to remember. Nothing to open.")
                    .font(.system(size: 16, weight: .light))
                    .tracking(0.1)
                    .foregroundColor(.white.opacity(0.50))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 14)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.8).delay(0.65), value: appeared)

                Spacer()

                // Primary CTA
                Button {
                    requestPermissionAndFinish()
                } label: {
                    Group {
                        if isRequesting {
                            ProgressView()
                                .tint(Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255))
                        } else {
                            Text("Enable Reminders")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .disabled(isRequesting)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.easeOut(duration: 0.8).delay(0.9), value: appeared)

                // Skip link
                Button("Skip for now") {
                    isComplete = true
                }
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.38))
                .padding(.top, 18)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(1.05), value: appeared)
            }
        }
        .onAppear {
            startCycle()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.05))
                appeared = true
            }
        }
        .onDisappear { breathTask?.cancel() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { startCycle() } else { breathTask?.cancel(); breathTask = nil }
        }
    }

    // MARK: - Breathing cycle
    //
    // Simplified version of BreathingOrbView's cycle — same 4s/4s/4s/4s rhythm,
    // but without phase labels. Pairs inhale+hold and exhale+hold into two 8s sleeps.

    private func startCycle() {
        breathTask?.cancel()
        breathTask = Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.linear(duration: 4)) { isExpanded = true }
                try? await Task.sleep(for: .seconds(8))   // inhale 4s + hold 4s
                guard !Task.isCancelled else { return }
                withAnimation(.linear(duration: 4)) { isExpanded = false }
                try? await Task.sleep(for: .seconds(8))   // exhale 4s + hold 4s
                guard !Task.isCancelled else { return }
            }
        }
    }

    // MARK: - Permission request

    private func requestPermissionAndFinish() {
        isRequesting = true
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            // Fires on a background thread — hop back to main before touching state/UI.
            DispatchQueue.main.async {
                if granted {
                    NotificationScheduler.scheduleNotifications(prefs: prefs)
                    showWelcome = true
                }
                isComplete = true
            }
        }
    }
}

#Preview {
    OnboardingView(prefs: .constant(Preferences()), isComplete: .constant(false), showWelcome: .constant(false))
}
