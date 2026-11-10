import XCTest
import SwiftData
@testable import FLIP

@MainActor final class FLIPTests: XCTestCase {
    func testHabitCheckInIsUniquePerDayAndReversible() {
        let habit = LifeItem("Read", kind: .habit)
        let morning = Calendar.current.startOfDay(for: .now).addingTimeInterval(3600)
        habit.toggleCheckIn(on: morning)
        XCTAssertTrue(habit.checked(on: morning.addingTimeInterval(7200)))
        habit.toggleCheckIn(on: morning.addingTimeInterval(7200))
        XCTAssertTrue(habit.checkIns.isEmpty)
    }
    func testDailyProgressExcludesEventsAndOtherDays() {
        let task = LifeItem("Today", date: .now); task.completed = true
        let tomorrow = LifeItem("Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: .now))
        let event = LifeItem("Meeting", kind: .event, date: .now)
        XCTAssertEqual(DayLogic.completion(DayLogic.items([task, tomorrow, event], on: .now)), 1)
        XCTAssertEqual(DayLogic.completion([]), 0)
    }
    func testCaptureDoesNotInventParsedDate() {
        let result = LiteralCaptureParser().parse(" Gym tomorrow at 7 AM. ")
        XCTAssertEqual(result.title, "Gym tomorrow at 7 AM.")
        XCTAssertNil(result.date)
    }
    func testPersistenceRoundTripAndDeletion() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".store")
        let schema = Schema([LifeItem.self, FocusSession.self])
        let configuration = ModelConfiguration(schema: schema, url: url)
        var id: UUID!
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            let project = LifeItem("Project", kind: .project)
            let task = LifeItem("Persist me"); task.projectID = project.id; task.notes = "Keep these notes"; id = task.id
            context.insert(project); context.insert(task); try context.save()
        }
        let reopened = try ModelContainer(for: schema, configurations: configuration)
        let context = ModelContext(reopened)
        let all = try context.fetch(FetchDescriptor<LifeItem>())
        let task = try XCTUnwrap(all.first { $0.id == id })
        XCTAssertEqual(task.notes, "Keep these notes")
        XCTAssertNotNil(task.projectID)
        task.completed = true; try context.save()
        context.delete(task); try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<LifeItem>()), 1)
    }
    func testDemoDisclosesModeAndUsesOnlyProvidedContext() async throws {
        let reply = try await DemoAIService().reply(to: "Plan", context: AssistantContext(taskTitles: ["Read"], eventTitles: []))
        XCTAssertTrue(reply.contains("Development demo"))
        XCTAssertTrue(reply.contains("Read"))
        let privateReply = try await DemoAIService().reply(to: "Plan", context: nil)
        XCTAssertFalse(privateReply.contains("Read"))
    }
}
