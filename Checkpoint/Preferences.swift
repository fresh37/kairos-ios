//
//  Preferences.swift
//  Checkpoint
//

import Foundation

// MARK: - BreathingPattern

struct BreathingPattern: Codable, Equatable {
    var id: String
    var name: String
    var inhale: Int       // seconds, 1–12
    var holdIn: Int       // seconds, 0–12 (0 = skip phase)
    var exhale: Int       // seconds, 1–12
    var holdOut: Int      // seconds, 0–12 (0 = skip phase)

    var ratio: String {
        let parts = [inhale, holdIn, exhale, holdOut]
        if id == "custom" {
            return parts.map { "\($0)" }.joined(separator: "-")
        }
        return parts.filter { $0 > 0 }.map { "\($0)" }.joined(separator: "-")
    }

    static let box         = BreathingPattern(id: "box",        name: "Box",        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4)
    static let relaxing478 = BreathingPattern(id: "478",        name: "4-7-8",      inhale: 4, holdIn: 7, exhale: 8, holdOut: 0)
    static let coherent    = BreathingPattern(id: "coherent",   name: "Coherent",   inhale: 5, holdIn: 0, exhale: 5, holdOut: 0)
    static let energizing  = BreathingPattern(id: "energizing", name: "Energizing", inhale: 6, holdIn: 2, exhale: 2, holdOut: 0)

    static let presets: [BreathingPattern] = [.box, .relaxing478, .coherent, .energizing]

    static var custom: BreathingPattern {
        BreathingPattern(id: "custom", name: "Custom", inhale: 4, holdIn: 0, exhale: 4, holdOut: 0)
    }

    var isPreset: Bool { id != "custom" }
}

// MARK: - Preferences

struct Preferences: Codable, Equatable {
    var remindersPerDay: Int = 3
    var startHour: Int = 9
    var endHour: Int = 21
    var gratitude: Bool = true
    var bodyAwareness: Bool = true
    var presentMoment: Bool = true
    var hapticFeedback: Bool = true
    var notificationsEnabled: Bool = true
    var breathingPattern: BreathingPattern = .box
    var meditationEnabled: Bool = false
    var meditationRemindersPerDay: Int = 2
    var meditationStartHour: Int = 9
    var meditationEndHour: Int = 21
    var activeDays: Set<Int> = Set(1...7)
    var themeID: String = "midnight"
    var customMessages: [String] = []
    var customMessagesEnabled: Bool = false

    // MARK: - Validation

    /// Returns true if the current values satisfy all constraints.
    var isValid: Bool {
        guard (1...50).contains(remindersPerDay) else { return false }
        guard (5...23).contains(startHour) else { return false }
        guard (6...24).contains(endHour) else { return false }
        guard endHour > startHour else { return false }
        let windowMinutes = (endHour - startHour) * 60
        guard windowMinutes / remindersPerDay >= 15 else { return false }
        if meditationEnabled {
            guard (1...50).contains(meditationRemindersPerDay) else { return false }
            guard (0...23).contains(meditationStartHour) else { return false }
            guard (1...24).contains(meditationEndHour) else { return false }
            guard meditationEndHour > meditationStartHour else { return false }
            let medWindow = (meditationEndHour - meditationStartHour) * 60
            guard medWindow / meditationRemindersPerDay >= 15 else { return false }
        }
        return true
    }

    /// Returns a validated copy, falling back to defaults for any field that
    /// would make the struct invalid.
    func validated() -> Preferences {
        var p = self
        if !(1...50).contains(p.remindersPerDay) { p.remindersPerDay = 3 }
        if !(5...23).contains(p.startHour)       { p.startHour = 9 }
        if !(6...24).contains(p.endHour)         { p.endHour = 21 }
        if p.endHour <= p.startHour              { p.endHour = p.startHour + 1 }
        let windowMinutes = (p.endHour - p.startHour) * 60
        while windowMinutes / p.remindersPerDay < 15, p.remindersPerDay > 1 {
            p.remindersPerDay -= 1
        }
        if p.activeDays.isEmpty { p.activeDays = Set(1...7) }
        if p.meditationEnabled {
            let medOk = (1...50).contains(p.meditationRemindersPerDay)
                && (0...23).contains(p.meditationStartHour)
                && (1...24).contains(p.meditationEndHour)
                && p.meditationEndHour > p.meditationStartHour
                && (p.meditationEndHour - p.meditationStartHour) * 60 / p.meditationRemindersPerDay >= 15
            if !medOk { p.meditationEnabled = false }
        }
        return p
    }
}

// MARK: - UserDefaults persistence

extension Preferences {
    private static let key = "checkpoint.preferences"

    static func load() -> Preferences {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode(Preferences.self, from: data)
        else {
            return Preferences()
        }
        return decoded.validated()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Preferences.key)
    }
}
