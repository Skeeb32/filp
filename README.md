# FLIP

**Everything in your life. One clear view.**

A native SwiftUI personal organizer with a quiet, dark interface and a coordinated two-pane workspace. Supports iOS 17+, iPhone, and iPad. No third-party packages or credentials are needed.

## Run

Open `FLIP.xcodeproj`, choose the **FLIP** scheme and an iOS simulator, and Run. For a physical device, select your own signing team and a unique bundle identifier. The checked-in project is ready to use; `xcodegen generate` regenerates it from `project.yml` if needed.

## What works

- Today: date-aware greeting, daily completion, priority tasks, unscheduled inbox, schedule, goals, habits, and upcoming events.
- Focus: task selection, adjustable duration, pause/resume, persisted deadline across restarts, task notes, and completed session history. Ending early discards that session.
- Life: projects, goals, habits, routines, milestones, reminders, notes, and ideas.
- Calendar: month/week navigation, selected-day agenda, and local events.
- Assistant: conversational UI, loading/error states, suggestions, explicit opt-in for today’s task/event titles, and a clearly labeled local development provider.
- Smart Capture: create any item type; optional dates, notes, priority, project assignment, and event details. Edit/delete existing items and create subtasks.
- SwiftData persistence, persistent preferences, search across titles and notes, daily habit check-ins, haptic completion feedback, reduced-motion-aware navigation, native typography and accessibility labels.
- Wide windows: overview stays beside an editable workspace. Select an item or drag its row into the workspace. AI occupies the workspace while Today remains in view. Compact windows present the same editor in a sheet.

## Preview

![Today on iPhone](docs/iphone-today.png)

![Adaptive workspace](docs/duo-workspace.png)

See [verification results](docs/VERIFICATION.md) for tested behavior and remaining release checks.

## Architecture

`Models/LifeItem.swift` contains persisted domain models and date/progress calculations. A typed `ItemKind` shares capture/editor behavior across organizer entries; UUID references link projects and subtasks without coupling the store to a future sync provider. Deleting a parent preserves children and clears their references.

`Design/` contains palette tokens, reusable surfaces/rows/progress, and `WorkspaceLayout`, the capability boundary for wide layouts. It does not invent a dual-display API or depend on a device model name.

`Views/` contains the app shell and feature screens. Editor fields are drafts until Save. Save failures roll back the context and show an error. Store initialization failures show a recovery message without deleting user data. Sample data is inserted only once on the first launch of an empty store.

`Services/` defines `AIService`, a local demo provider, `CaptureParser`, and sample content. `AssistantModel` handles asynchronous requests and survives tab navigation. Implement `AIService` to connect a provider; add provider-specific consent and disclosure before transmitting data. Never embed provider secrets in the app binary. The current provider has no network access and receives only explicitly permitted task/event titles.

## Intentional integration boundaries

- **AI:** local rule-based demo, not a production intelligence service. No automated edits or generated plans are applied.
- **Natural language:** entered text is preserved literally. Dates must be chosen explicitly until a real parser is connected.
- **Calendar/reminders:** stored inside FLIP. EventKit, push/local notifications, and external calendar authorization are not wired up.
- **Duo:** adaptive two-pane layout using supported window sizing and drag/drop. Actual multi-display hardware coordination remains behind the layout boundary.
- **Sync:** device-local storage only. A production cloud integration needs account, conflict, migration, and deletion policies.
- **Release:** configure signing, production branding assets, App Store metadata, and provider/privacy policies before distribution. Ambient audio is not included.

## Verification

Run Product → Test or:

```sh
xcodebuild -scheme FLIP -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

Unit tests exercise daily habit toggling, date-scoped progress, literal capture behavior, a disk-backed persistence/reopen/delete round trip, and demo privacy behavior. UI tests exercise capture, relaunch persistence, five-tab navigation, and task-detail selection. On iPad, selection also checks that the command center remains visible.

Design and accessibility checks still require device/VoiceOver review before shipping. The foundation uses the documented [SwiftData model container](https://developer.apple.com/documentation/swiftdata/modelcontainer) lifecycle.
