//
//  ParticleEmitterView.swift
//  Checkpoint
//
//  Floating particles that drift upward and fade, used for goal completion celebrations.
//

import SwiftUI

private struct Particle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let diameter: CGFloat
    let color: Color
    let opacity: Double
    let delay: Double
    let duration: Double
}

struct ParticleEmitterView: View {
    @State private var particles: [Particle] = []
    @State private var animate = false

    private static let palette: [Color] = [
        Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255),
        Color(red: 0xa0/255, green: 0xd0/255, blue: 0xee/255),
        .white
    ]

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2

            ForEach(particles) { p in
                Circle()
                    .fill(p.color.opacity(animate ? 0 : p.opacity))
                    .frame(width: p.diameter, height: p.diameter)
                    .position(
                        x: cx + p.startX + (animate ? p.endX : 0),
                        y: cy + (animate ? p.endY : 0)
                    )
                    .animation(
                        .easeOut(duration: p.duration).delay(p.delay),
                        value: animate
                    )
            }
        }
        .onAppear {
            particles = Self.makeParticles()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                animate = true
            }
        }
    }

    private static func makeParticles() -> [Particle] {
        (0..<18).map { _ in
            Particle(
                startX: .random(in: -30...30),
                endX: .random(in: -60...60),
                endY: .random(in: -130...(-80)),
                diameter: .random(in: 3...5),
                color: palette.randomElement() ?? palette[0],
                opacity: .random(in: 0.45...0.80),
                delay: .random(in: 0...1.8),
                duration: .random(in: 3.0...4.2)
            )
        }
    }
}
