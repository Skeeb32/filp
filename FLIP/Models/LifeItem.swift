import Foundation
import SwiftData

enum ItemKind: String, Codable, CaseIterable, Identifiable {
    case task, note, idea, reminder, event, goal, project, habit, milestone, routine
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .task: "checkmark.circle"
        case .note: "note.text"
        case .idea: "lightbulb"
        case .reminder: "bell"
        case .event: "calendar"
        case .goal: "scope"
        case .project: "square.stack.3d.up"
        case .habit: "leaf"
        case .milestone: "flag"
        case .routine: "repeat"
        }
    }
}

@Model final class LifeItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var kindRaw: String
    var notes: String
    var date: Date?
    var completed: Bool
    var priority: Int
    var projectID: UUID?
    var parentID: UUID?
    var progress: Double
    var location: String
    var attendees: String
    var checkIns: [Date]
    var createdAt: Date
    var kind: ItemKind { ItemKind(rawValue: kindRaw) ?? .task }
    init(_ title: String, kind: ItemKind = .task, date: Date? = nil, notes: String = "", priority: Int = 1) {
        id = UUID(); self.title = title; kindRaw = kind.rawValue; self.date = date
        self.notes = notes; completed = false; self.priority = priority
        progress = 0; location = ""; attendees = ""; checkIns = []; createdAt = .now
    }
    func checked(on day: Date = .now) -> Bool {
        checkIns.contains { Calendar.current.isDate($0, inSameDayAs: day) }
    }
    func toggleCheckIn(on day: Date = .now) {
        if checked(on: day) { checkIns.removeAll { Calendar.current.isDate($0, inSameDayAs: day) } }
        else { checkIns.append(day) }
    }
}

@Model final class FocusSession {
    var id: UUID
    var title: String
    var date: Date
    var seconds: Int
    init(title: String, seconds: Int) { id = UUID(); self.title = title; self.seconds = seconds; date = .now }
}

struct DayLogic {
    static func items(_ items: [LifeItem], on date: Date) -> [LifeItem] {
        items.filter { $0.date.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false }
            .sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
    }
    static func completion(_ items: [LifeItem]) -> Double {
        let tasks = items.filter { $0.kind == .task }
        return tasks.isEmpty ? 0 : Double(tasks.filter(\.completed).count) / Double(tasks.count)
    }
}
