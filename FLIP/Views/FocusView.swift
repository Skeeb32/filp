import SwiftUI
import SwiftData

struct FocusView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FocusSession.date, order: .reverse) private var sessions: [FocusSession]
    let items: [LifeItem]
    @AppStorage("focusMinutes") private var minutes = 25
    @AppStorage("focusDeadline") private var deadline = 0.0
    @AppStorage("focusRemaining") private var storedRemaining = 0
    @AppStorage("focusDuration") private var duration = 1500
    @AppStorage("focusTaskID") private var taskID = ""
    @AppStorage("focusTaskTitle") private var sessionTitle = "Open focus"
    @State private var error: String?
    private var task: LifeItem? { items.first { $0.id.uuidString == taskID } }
    private var active: Bool { deadline > 0 }
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("One thing at a time.").font(.largeTitle.bold())
            Text("Give your attention a place to land.").foregroundStyle(Palette.muted)
            Surface {
                VStack(spacing: 24) {
                    Label("YOUR QUIET SPACE", systemImage: "circle.dotted").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(Palette.purple)
                    Picker("Focus on", selection: $taskID) {
                        Text("Open focus").tag("")
                        ForEach(items.filter { $0.kind == .task && !$0.completed }) { Text($0.title).tag($0.id.uuidString) }
                    }.disabled(active || storedRemaining > 0)
                    TimelineView(.periodic(from: .now, by: 1)) { timeline in
                        let remaining = remaining(at: timeline.date)
                        VStack(spacing: 20) {
                            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60)).font(.system(size: 68, weight: .light, design: .rounded)).monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                                .accessibilityLabel("\(remaining / 60) minutes \(remaining % 60) seconds remaining")
                            ProgressView(value: 1 - Double(remaining) / Double(max(1, active || storedRemaining > 0 ? duration : minutes * 60))).tint(Palette.lime)
                        }.onChange(of: remaining) { _, value in if active && value == 0 { finish() } }
                    }
                    HStack(spacing: 16) {
                        Button(active ? "Pause" : storedRemaining > 0 ? "Resume" : "Begin focus") {
                            if active { storedRemaining = remaining(at: .now); deadline = 0 }
                            else {
                                if storedRemaining == 0 { duration = minutes * 60; sessionTitle = task?.title ?? "Open focus" }
                                deadline = Date.now.timeIntervalSince1970 + Double(storedRemaining > 0 ? storedRemaining : duration)
                            }
                        }.buttonStyle(.borderedProminent).tint(Palette.lime).foregroundStyle(Palette.background).controlSize(.large)
                        if active || storedRemaining > 0 { Button("End") { deadline = 0; storedRemaining = 0 }.buttonStyle(.bordered).controlSize(.large) }
                    }
                    Text("Silence is a feature. Take a breath.").font(.caption).foregroundStyle(Palette.muted)
                }.frame(maxWidth: .infinity).padding(.vertical, 16)
            }
            if let task {
                SectionLabel(title: "Keep the thought close")
                Surface { Text(task.notes.isEmpty ? "Add notes from the task’s details in Today or Life." : task.notes).foregroundStyle(Palette.muted) }
            }
            SectionLabel(title: "Time well spent", detail: "RECENT SESSIONS")
            if sessions.isEmpty { Text("Your completed focus sessions will live here.").font(.subheadline).foregroundStyle(Palette.muted) }
            ForEach(sessions.prefix(10)) { session in
                Surface { HStack { Image(systemName: "checkmark.seal").foregroundStyle(Palette.lime); VStack(alignment: .leading, spacing: 4) { Text(session.title); Text(session.date, style: .date).font(.caption).foregroundStyle(Palette.muted) }; Spacer(); Text("\(session.seconds / 60)m").foregroundStyle(Palette.lime) } }
            }
        }
        .onAppear { if active && remaining(at: .now) == 0 { finish() } }
        .alert("Couldn’t save session", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("Retry") { finish() } } message: { Text(error ?? "") }
    }
    private func remaining(at date: Date) -> Int { active ? max(0, Int(ceil(deadline - date.timeIntervalSince1970))) : storedRemaining > 0 ? storedRemaining : minutes * 60 }
    private func finish() {
        let session = FocusSession(title: sessionTitle, seconds: duration)
        context.insert(session)
        do { try context.save(); deadline = 0; storedRemaining = 0 } catch { context.rollback(); self.error = error.localizedDescription }
    }
}
