# Checkpoint

A mindfulness and habit-tracking iOS app. Scheduled notifications deliver brief breathing moments throughout the day; a savings-based habit tracker helps build routines toward a personal goal.

*Brief pauses, delivered throughout your day. Nothing to remember. Nothing to open.*

## Features

### Breathing

- Animated breathing orb with real-time phase labels (inhale, hold, exhale)
- Preset patterns: Box (4-4-4-4), 4-7-8 Relaxation, Coherent (5-5), Energizing (6-2-2)
- Custom pattern editor with adjustable timing (1–12s per phase)
- Session timer with optional interval bell

### Notifications

- Configurable reminders per day with start/end time windows
- Day-of-week filtering
- Three mindfulness message categories: Gratitude, Body Awareness, Present Moment
- Custom message pool for user-defined notification messages
- Optional meditation reminders with separate scheduling
- Background refresh keeps notifications queued up to 6 days ahead

### Habit & Goal Tracking

- Set savings goals and attach habits with monetary rewards
- Log completions to earn progress toward the goal
- Habit Loop support (cue, craving) based on habit formation science
- Completion history grouped by day — makes accidental duplicates visible at a glance
- Goal completion celebration with animations
- Habits carry over automatically when starting a new goal

### Appearance

Seven built-in themes — Midnight, Dusk, Ink, Ember, Forest, Slate, Rose — each with a distinct palette applied across backgrounds, the breathing orb, and accent colors.

## Tech Stack

- **SwiftUI** — Declarative UI
- **SwiftData** — Persistent storage for habits, goals, and completions
- **UserNotifications** — Local notification scheduling
- **BackgroundTasks** — Background refresh for notification queuing
- **os.Logger** — System logging
- No external dependencies

## Requirements

- iOS 26.0+
- Xcode 26+

## Building

1. Clone the repository
2. Open `Checkpoint.xcodeproj` in Xcode
3. Select a target device or simulator
4. Build and run (⌘R)

No dependency installation needed — the project uses only Apple frameworks.

## Project Structure

```
Checkpoint/
  KairosApp.swift              App entry point
  ContentView.swift            Root navigation & onboarding router
  MainTabView.swift            Tab bar (Breathe + Habits)
  Theme.swift                  Theme definitions, environment injection, shared components
  Preferences.swift            Settings with validation & UserDefaults persistence
  NotificationScheduler.swift  Notification scheduling algorithm
  MessagePool.swift            Mindfulness message collections
  BackgroundRefresh.swift      BGAppRefreshTask management
  Models/
    HabitGoal.swift            Goal data model
    Habit.swift                Habit data model
    HabitCompletion.swift      Completion event model
  BreathingOrbView.swift       Animated breathing visualization
  BreathingPatternSheet.swift  Pattern selector & custom editor
  BreathingTimerSheet.swift    Session timer configuration
  HabitsView.swift             Habit list, progress card, completions
  HabitHistoryView.swift       Completion history grouped by day
  AppearanceSheet.swift        Theme picker
  SettingsDrawer.swift         Preferences editor
  CustomMessagesSheet.swift    Custom notification message editor
  EditMessageSheet.swift       Individual message editor
  OnboardingView.swift         First-launch flow & permission request
  AddHabitView.swift           Add habit form
  EditHabitView.swift          Edit habit form
  CreateGoalView.swift         Create goal form
  GoalCompletedView.swift      Goal completion celebration
  ParticleEmitterView.swift    Celebration particle effects
```

## License

MIT
