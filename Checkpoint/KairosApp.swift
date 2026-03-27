//
//  CheckpointApp.swift
//  Checkpoint
//

import SwiftData
import SwiftUI

@main
struct CheckpointApp: App {
    init() {
        // Register the BGAppRefreshTask handler before any scene is created.
        // This must happen early — iOS requires handlers to be registered
        // synchronously during app launch, before the run loop starts.
        BackgroundRefresh.registerHandler()

        // Queue the first background refresh. Subsequent refreshes are
        // re-queued automatically at the end of each handled task.
        BackgroundRefresh.schedule()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: HabitGoal.self)
    }
}
