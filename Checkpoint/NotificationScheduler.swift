//
//  NotificationScheduler.swift
//  Checkpoint
//
//  Core logic ported from presence/lib/scheduleForUser.js:
//    generateTimes()    → generateOffsets(count:windowMinutes:)
//    buildMessagePool() → buildMessagePool(prefs:count:)
//

import Foundation
import UserNotifications

enum NotificationScheduler {

    // MARK: - generateOffsets
    //
    // Returns `count` random minute-offsets within [0, windowMinutes], each
    // at least `minGap` minutes apart.  Mirrors generateTimes() from the PWA.

    static func generateOffsets(count: Int, windowMinutes: Int) -> [Int] {
        guard count > 0, windowMinutes > 0 else { return [] }
        if count == 1 {
            return [Int.random(in: 0...windowMinutes)]
        }
        let minGap = max(15, windowMinutes / (count + 1))
        let slack   = windowMinutes - (count - 1) * minGap
        guard slack >= 0 else { return [] }

        var breaks = (0..<count).map { _ in Double.random(in: 0...Double(slack)) }
        breaks.sort()

        var cursor = 0.0
        return breaks.enumerated().map { index, breakPoint in
            let gap     = index == 0 ? 0.0 : Double(minGap)
            let segment = breakPoint - (index == 0 ? 0.0 : breaks[index - 1])
            cursor += gap + segment
            return Int(cursor.rounded())
        }
    }

    // MARK: - buildMessagePool
    //
    // Returns a shuffled pool of `count` messages drawn proportionally from
    // whichever categories are enabled.  Falls back to all categories if none
    // are enabled.  Mirrors buildMessagePool() from the PWA.

    static func buildMeditationPool(count: Int) -> [String] {
        Array(MessagePool.meditation.shuffled().prefix(count))
    }

    static func buildMessagePool(prefs: Preferences, count: Int) -> [String] {
        var buckets: [String: [String]] = [
            "gratitude": MessagePool.gratitude,
            "bodyAwareness": MessagePool.bodyAwareness,
            "presentMoment": MessagePool.presentMoment
        ]

        if prefs.customMessagesEnabled, !prefs.customMessages.isEmpty {
            buckets["custom"] = prefs.customMessages
        }

        var active: [String] = []
        if prefs.gratitude { active.append("gratitude") }
        if prefs.bodyAwareness { active.append("bodyAwareness") }
        if prefs.presentMoment { active.append("presentMoment") }
        if prefs.customMessagesEnabled, !prefs.customMessages.isEmpty {
            active.append("custom")
        }
        // Fallback: all built-in buckets if nothing is active
        if active.isEmpty { active = ["gratitude", "bodyAwareness", "presentMoment"] }

        let perCategory = Int(ceil(Double(count) / Double(active.count)))
        var pool: [String] = []
        for cat in active {
            let shuffled = (buckets[cat] ?? []).shuffled()
            pool.append(contentsOf: shuffled.prefix(perCategory))
        }
        return pool.shuffled()
    }

    // MARK: - scheduleNotifications  (fire-and-forget, for use from UI code)
    //
    // Wraps the async implementation in a Task so callers don't need to be async.
    // ContentView, OnboardingView, and SettingsDrawer all use this entry point.

    static func scheduleNotifications(prefs: Preferences) {
        Task { await scheduleNotificationsAsync(prefs: prefs) }
    }

    // MARK: - scheduleNotificationsAsync  (awaitable, for use from background tasks)
    //
    // Cancels all pending Checkpoint notifications, then fills 6 days ahead
    // (≤ 60 notifications, well within the iOS 64-notification limit).
    // Using the async UNUserNotificationCenter APIs (iOS 14+) means the
    // background task closure can await this and know the work is truly done
    // before iOS reclaims the execution window.

    static func scheduleNotificationsAsync(prefs: Preferences) async {
        let center = UNUserNotificationCenter.current()

        guard prefs.notificationsEnabled else {
            center.removeAllPendingNotificationRequests()
            return
        }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let pending = await center.pendingNotificationRequests()
        let checkpointIds = pending.map(\.identifier).filter { $0.hasPrefix("checkpoint.") }
        center.removePendingNotificationRequests(withIdentifiers: checkpointIds)

        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: Date())
        var count    = await scheduleDailyNotifications(
            prefs: prefs, center: center, calendar: calendar, today: today)

        if prefs.meditationEnabled && count < 60 {
            count = await scheduleMeditationNotifications(
                prefs: prefs, center: center, calendar: calendar, today: today, startCount: count)
        }
    }

    private static func scheduleDailyNotifications(
        prefs: Preferences,
        center: UNUserNotificationCenter,
        calendar: Calendar,
        today: Date
    ) async -> Int {
        let windowMinutes = (prefs.endHour - prefs.startHour) * 60
        var requestCount  = 0

        outer: for dayOffset in 0..<6 {
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: dayStart)
            guard prefs.activeDays.contains(weekday) else { continue }

            let offsets  = generateOffsets(count: prefs.remindersPerDay, windowMinutes: windowMinutes)
            let messages = buildMessagePool(prefs: prefs, count: prefs.remindersPerDay)

            for (index, offsetMinutes) in offsets.enumerated() {
                let fireMinute = prefs.startHour * 60 + offsetMinutes
                guard let fireDate = calendar.date(
                    byAdding: .minute, value: fireMinute, to: dayStart
                ) else { continue }
                if fireDate <= Date() { continue }

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger    = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let content    = UNMutableNotificationContent()
                content.body   = messages[index % messages.count]
                content.sound  = .default

                let request = UNNotificationRequest(
                    identifier: "checkpoint.\(dayOffset).\(index).\(UUID().uuidString)",
                    content: content, trigger: trigger)
                try? await center.add(request)
                requestCount += 1
                if requestCount >= 60 { break outer }
            }
        }
        return requestCount
    }

    private static func scheduleMeditationNotifications(
        prefs: Preferences,
        center: UNUserNotificationCenter,
        calendar: Calendar,
        today: Date,
        startCount: Int
    ) async -> Int {
        let medWindow = (prefs.meditationEndHour - prefs.meditationStartHour) * 60
        var requestCount = startCount

        medOuter: for dayOffset in 0..<6 {
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: dayStart)
            guard prefs.meditationActiveDays.contains(weekday) else { continue }
            let offsets  = generateOffsets(count: prefs.meditationRemindersPerDay, windowMinutes: medWindow)
            let messages = buildMeditationPool(count: prefs.meditationRemindersPerDay)

            for (index, offsetMinutes) in offsets.enumerated() {
                let fireMinute = prefs.meditationStartHour * 60 + offsetMinutes
                guard let fireDate = calendar.date(
                    byAdding: .minute, value: fireMinute, to: dayStart
                ) else { continue }
                if fireDate <= Date() { continue }

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger    = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let content    = UNMutableNotificationContent()
                content.body   = "🧘 \(messages[index % messages.count])"
                content.sound  = .default

                let request = UNNotificationRequest(
                    identifier: "checkpoint.med.\(dayOffset).\(index).\(UUID().uuidString)",
                    content: content, trigger: trigger)
                try? await center.add(request)
                requestCount += 1
                if requestCount >= 60 { break medOuter }
            }
        }
        return requestCount
    }
}
