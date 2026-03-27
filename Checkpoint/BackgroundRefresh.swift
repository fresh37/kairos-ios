//
//  BackgroundRefresh.swift
//  Checkpoint
//
//  Manages the BGAppRefreshTask that tops up the notification queue
//  every ~12 hours while the app is in the background.
//
//  Registration flow (think of it like an event listener):
//    1. CheckpointApp registers a handler for `taskIdentifier` at launch.
//    2. iOS calls that handler when it decides to run the refresh.
//    3. The handler does its work, calls task.setTaskCompleted(), and
//       immediately schedules the *next* refresh so the cycle continues.
//
//  Note: iOS decides *when* to actually run the task based on usage patterns.
//  The earliestBeginDate is a minimum delay, not a guaranteed fire time.
//

import BackgroundTasks
import Foundation

enum BackgroundRefresh {
    static let taskIdentifier = "com.kevinfish.Checkpoint.refresh"

    // Call once from CheckpointApp.init() — before the first scene is created.
    static func registerHandler() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil                          // nil = run on main queue
        ) { task in
            handle(task: task as! BGAppRefreshTask)
        }
    }

    // Submit the next refresh request to the OS.
    // Call this: on launch, and at the end of every handled task.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        // Ask iOS not to wake us sooner than 12 hours from now.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 3600)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Checkpoint: could not schedule background refresh: \(error)")
        }
    }

    // MARK: - Private

    private static func handle(task: BGAppRefreshTask) {
        // Schedule the *next* refresh before doing any work, so the chain
        // continues even if this execution is interrupted.
        schedule()

        let prefs = Preferences.load()

        // Give the task a cancellation handler — iOS calls this if it needs
        // to reclaim resources before we're done.
        let workTask = Task {
            await NotificationScheduler.scheduleNotificationsAsync(prefs: prefs)
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            workTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
