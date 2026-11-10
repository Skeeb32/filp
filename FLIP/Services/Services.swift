import Foundation
import SwiftData

struct AssistantContext: Sendable {
    let taskTitles: [String]
    let eventTitles: [String]
}
protocol AIService: Sendable {
    var name: String { get }
    func reply(to prompt: String, context: AssistantContext?) async throws -> String
}
struct DemoAIService: AIService {
    let name = "Local demo · no network"
    func reply(to prompt: String, context: AssistantContext?) async throws -> String {
        try await Task.sleep(for: .milliseconds(350))
        if let context, let first = context.taskTitles.first {
            return "Development demo: try a 25-minute focus block for ‘\(first)’. You have \(context.eventTitles.count) scheduled events in today’s shared context. This is a local rule-based example, not an AI-generated plan."
        }
        return "Development demo: choose one meaningful task, reserve a focus block, and leave space between commitments. Connect an AIService implementation for personalized responses. No information has left this device."
    }
}
struct CaptureResult { var title: String; var date: Date? }
protocol CaptureParser { func parse(_ text: String) -> CaptureResult }
struct LiteralCaptureParser: CaptureParser {
    func parse(_ text: String) -> CaptureResult { CaptureResult(title: text.trimmingCharacters(in: .whitespacesAndNewlines), date: nil) }
}

@MainActor enum SampleData {
    static func insert(into context: ModelContext) throws {
        let calendar = Calendar.current
        func time(_ hour: Int, _ minute: Int = 0) -> Date { calendar.date(bySettingHour: hour, minute: minute, second: 0, of: .now)! }
        let project = LifeItem("A little more intentional", kind: .project, notes: "A personal reset. Make room for the things that matter.")
        project.progress = 0.35
        let task = LifeItem("Shape the next chapter", date: time(10), notes: "Sketch three directions for the personal website. Keep it simple.", priority: 2)
        task.projectID = project.id
        let done = LifeItem("A quiet start, no screens", date: time(7, 30)); done.completed = true
        let event = LifeItem("Design catch-up", kind: .event, date: time(11), notes: "Bring the latest sketches and a fresh perspective.")
        event.location = "Studio / video call"; event.attendees = "Alex, Jordan"
        let gym = LifeItem("Move your body", kind: .event, date: time(17, 30))
        let goal = LifeItem("Read 12 books", kind: .goal, notes: "A few pages, every day."); goal.progress = 0.42
        let items = [project, task, done, event, gym, goal,
                     LifeItem("Plan a weekend outside", date: time(16), priority: 1),
                     LifeItem("Ten minutes of reading", kind: .habit),
                     LifeItem("Morning reset", kind: .routine, notes: "Water. Stretch. Set one intention."),
                     LifeItem("Launch the new portfolio", kind: .milestone),
                     LifeItem("A place for small thoughts", kind: .note, notes: "What would a calmer week look like?")]
        items.forEach { context.insert($0) }; try context.save()
    }
}
