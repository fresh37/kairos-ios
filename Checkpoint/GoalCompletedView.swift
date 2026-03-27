//
//  GoalCompletedView.swift
//  Checkpoint
//
//  Celebration overlay shown when a goal's target is reached.
//

import SwiftUI

struct GoalCompletedView: View {
    let goal: HabitGoal

    @Environment(\.modelContext) private var modelContext
    @State private var ringProgress: Double = 0
    @State private var showContent = false
    @State private var ringScale: CGFloat = 1.0
    @State private var ringGlowOpacity: Double = 0.0
    @State private var showParticles = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 6)
                    .frame(width: 120)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255),
                                Color(red: 0xa0/255, green: 0xd0/255, blue: 0xee/255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
            }
            .frame(width: 120, height: 120)
            .scaleEffect(ringScale)
            .shadow(
                color: Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255)
                    .opacity(ringGlowOpacity),
                radius: 20
            )
            .overlay(alignment: .center) {
                if showParticles {
                    ParticleEmitterView()
                        .frame(width: 220, height: 320)
                        .offset(y: -80)
                        .allowsHitTesting(false)
                }
            }

            VStack(spacing: 8) {
                Text("Goal Reached!")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)

                Text(goal.name)
                    .font(.system(size: 17, weight: .light))
                    .foregroundColor(.white.opacity(0.6))

                Text(goal.formattedTarget)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255))
                    .padding(.top, 4)
            }
            .opacity(showContent ? 1 : 0)

            Spacer()

            Button {
                goal.isActive = false
            } label: {
                Text("New Goal")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            // Ring fill animation
            withAnimation(.easeOut(duration: 1.0)) {
                ringProgress = 1.0
            }

            // Content fade-in (checkmark, text, button)
            withAnimation(.easeIn(duration: 0.4).delay(0.6)) {
                showContent = true
            }

            // Particles appear when ring is 40% filled
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                showParticles = true
            }

            // Ring pulse — spring expand at ring completion (t=1.0s from ring start)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(1.0)) {
                ringScale = 1.05
            }
            withAnimation(.easeOut(duration: 0.25).delay(1.0)) {
                ringGlowOpacity = 0.55
            }

            // Ring settle back to rest
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(1.35)) {
                ringScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.6).delay(1.35)) {
                ringGlowOpacity = 0.0
            }

            // Success haptic timed to ring completion
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1000))
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}
