import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case today = "Today", focus = "Focus", life = "Life", calendar = "Calendar", ai = "AI"
    var icon: String { switch self { case .today: "square.grid.2x2"; case .focus: "circle.dotted"; case .life: "square.stack.3d.up"; case .calendar: "calendar"; case .ai: "sparkles" } }
}
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \LifeItem.createdAt) private var items: [LifeItem]
    @AppStorage("seeded") private var seeded = false
    @AppStorage("displayName") private var name = ""
    @AppStorage("haptics") private var haptics = true
    @State private var assistant = AssistantModel()
    @State private var tab = AppTab.today
    @State private var selectedID: UUID?
    @State private var capture = false
    @State private var settings = false
    @State private var notifications = false
    @State private var search = ""
    @State private var error: String?
    @State private var completionCount = 0
    private var selected: LifeItem? { items.first { $0.id == selectedID } }
    var body: some View {
        GeometryReader { geometry in
            let duo = WorkspaceLayout.usesTwoPanes(width: geometry.size.width)
            HStack(spacing: 0) {
                NavigationStack {
                    VStack(spacing: 0) {
                        if tab == .today || tab == .life {
                            HStack { Image(systemName: "magnifyingglass"); TextField("Find anything in your life", text: $search).accessibilityIdentifier("search") }
                                .foregroundStyle(Palette.muted).padding(14).background(Palette.surface, in: Capsule()).padding(.horizontal, 24)
                        }
                        ScrollView {
                            VStack(alignment: .leading, spacing: 22) {
                                if !search.isEmpty && (tab == .today || tab == .life) {
                                    SectionLabel(title: "Search results")
                                    rows(items.filter { $0.title.localizedCaseInsensitiveContains(search) || $0.notes.localizedCaseInsensitiveContains(search) })
                                } else {
                                    switch tab {
                                    case .today: today
                                    case .focus: FocusView(items: items)
                                    case .life: life
                                    case .calendar: CalendarScreen(items: items, select: { selectedID = $0.id }, toggle: toggle)
                                    case .ai:
                                        if duo { today } else { AssistantView(items: items, model: assistant) }
                                    }
                                }
                            }.padding(24).padding(.bottom, 80)
                        }.scrollIndicators(.hidden)
                    }
                    .background(Palette.background)
                    .navigationTitle("FLIP").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { notifications = true } label: {
                                Image(systemName: items.contains { $0.kind == .reminder && !$0.completed } ? "bell.badge" : "bell")
                            }.accessibilityLabel("Upcoming reminders")
                        }
                        ToolbarItem(placement: .topBarTrailing) { Button { settings = true } label: { Image(systemName: "person.crop.circle").font(.title2) }.accessibilityLabel("Profile and settings") }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) { navigation }
                    .overlay(alignment: .bottomTrailing) {
                        Button { capture = true } label: { Image(systemName: "plus").font(.title2.bold()).foregroundStyle(Palette.background).frame(width: 58, height: 58).background(Palette.lime, in: Circle()).shadow(color: .black.opacity(0.3), radius: 12, y: 6) }
                            .accessibilityLabel("Smart Capture").accessibilityIdentifier("capture").padding(.trailing, 24).padding(.bottom, 90)
                    }
                }.frame(maxWidth: duo ? 460 : .infinity)
                if duo {
                    Rectangle().fill(.white.opacity(0.08)).frame(width: 1)
                    NavigationStack {
                        Group {
                            if tab == .ai { ScrollView { AssistantView(items: items, model: assistant).padding(32) } }
                            else if let selected { ItemEditor(item: selected, allItems: items, onDeleted: { selectedID = nil }, embedded: true) .id(selected.id) }
                            else { ContentUnavailableView("Room to think.", systemImage: "rectangle.split.2x1", description: Text("Choose a task, event, or project from your command center. Your day stays in view.")) }
                        }.background(Palette.background).navigationTitle("Workspace").navigationBarTitleDisplayMode(.inline)
                    }.dropDestination(for: String.self) { values, _ in
                        guard let id = values.first.flatMap(UUID.init(uuidString:)), items.contains(where: { $0.id == id }) else { return false }
                        selectedID = id; return true
                    }
                }
            }
            .sheet(isPresented: Binding(get: { !duo && selectedID != nil }, set: { if !$0 { selectedID = nil } })) {
                if let selected { NavigationStack { ItemEditor(item: selected, allItems: items, onDeleted: { selectedID = nil }) }.presentationDragIndicator(.visible) }
            }
        }
        .foregroundStyle(Palette.white)
        .sheet(isPresented: $capture) { NavigationStack { ItemEditor(item: nil, allItems: items) }.presentationDragIndicator(.visible) }
        .sheet(isPresented: $settings) { SettingsView() }
        .sheet(isPresented: $notifications) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Your next little nudge.").font(.title.bold())
                        let reminders = items.filter { $0.kind == .reminder && !$0.completed }
                        if reminders.isEmpty { ContentUnavailableView("All clear", systemImage: "bell", description: Text("Capture a reminder with +.")) }
                        ForEach(reminders) { reminder in
                            NavigationLink { ItemEditor(item: reminder, allItems: items) } label: {
                                Surface { Label(reminder.title, systemImage: "bell") }
                            }
                        }
                        Text("Reminders live in FLIP. System notifications are not enabled.").font(.caption).foregroundStyle(Palette.muted)
                    }.padding(24)
                }.background(Palette.background).navigationTitle("Reminders")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { notifications = false } } }
            }.preferredColorScheme(.dark)
        }
        .alert("Couldn’t save changes", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
        .sensoryFeedback(.success, trigger: completionCount) { _, _ in haptics }
        .task {
            if !seeded {
                do { if items.isEmpty { try SampleData.insert(into: context) }; seeded = true }
                catch { self.error = error.localizedDescription }
            }
        }
    }
    private var navigation: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { destination in
                Button { withAnimation(reduceMotion ? nil : .snappy(duration: 0.2)) { tab = destination; search = "" } } label: {
                    VStack(spacing: 5) { Image(systemName: destination.icon).font(.title3); Text(destination.rawValue).font(.caption2.weight(.medium)) }
                        .foregroundStyle(tab == destination ? Palette.lime : Palette.muted).frame(maxWidth: .infinity).frame(minHeight: 56)
                }.accessibilityAddTraits(tab == destination ? .isSelected : []).accessibilityIdentifier("tab\(destination.rawValue)")
            }
        }.padding(.horizontal, 12).padding(.top, 8).background(.ultraThinMaterial)
    }
    private var today: some View {
        let todays = DayLogic.items(items, on: .now)
        return VStack(alignment: .leading, spacing: 22) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased()).font(.caption.weight(.medium)).tracking(2).foregroundStyle(Palette.muted)
            VStack(alignment: .leading, spacing: 8) {
                Text(greeting + (name.isEmpty ? "." : ", \(name).")).font(.largeTitle.bold())
                Text("Here’s your day, beautifully organized.").foregroundStyle(Palette.muted)
            }
            Surface {
                HStack(spacing: 24) {
                    ProgressRing(value: DayLogic.completion(todays))
                    VStack(alignment: .leading, spacing: 7) {
                        Text("A little progress.\nA lighter day.").font(.title3.bold())
                        Text("\(todays.filter { $0.kind == .task && $0.completed }.count) of \(todays.filter { $0.kind == .task }.count) tasks complete").font(.caption).foregroundStyle(Palette.muted)
                    }
                }
            }
            SectionLabel(title: "Make space for what matters", detail: "PRIORITIES")
            rows(todays.filter { $0.kind == .task }.sorted { $0.priority > $1.priority })
            if items.contains(where: { $0.kind == .task && $0.date == nil && $0.parentID == nil }) {
                SectionLabel(title: "On your mind", detail: "INBOX")
                rows(items.filter { $0.kind == .task && $0.date == nil && $0.parentID == nil })
            }
            SectionLabel(title: "The shape of your day", detail: "SCHEDULE")
            rows(todays.filter { $0.kind == .event || $0.kind == .reminder })
            Button { tab = .ai } label: {
                Surface { VStack(alignment: .leading, spacing: 12) {
                    Label("A little perspective", systemImage: "sparkles").font(.subheadline.bold()).foregroundStyle(Palette.purple)
                    Text("Make room for your next good idea.").font(.title3.weight(.medium)).foregroundStyle(Palette.white)
                    Text("Explore the assistant · Local demo").font(.caption).foregroundStyle(Palette.muted)
                } }
            }.buttonStyle(.plain)
            SectionLabel(title: "Small steps, every day")
            rows(items.filter { $0.kind == .habit || $0.kind == .goal })
            SectionLabel(title: "On the horizon")
            rows(Array(items.filter { $0.kind == .event && ($0.date ?? .distantPast) > Calendar.current.startOfDay(for: .now).addingTimeInterval(86400) }.prefix(3)))
        }
    }
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"
    }
    private var life: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("A life, well lived.").font(.largeTitle.bold())
            Text("Big ambitions. Small everyday rituals.").foregroundStyle(Palette.muted)
            ForEach([ItemKind.project, .goal, .habit, .routine, .milestone, .reminder, .note, .idea], id: \.self) { kind in
                SectionLabel(title: kind.label + "s", detail: "\(items.filter { $0.kind == kind }.count)")
                rows(items.filter { $0.kind == kind })
            }
        }
    }
    private func rows(_ entries: [LifeItem]) -> some View {
        Surface {
            VStack(spacing: 8) {
                if entries.isEmpty { Text("Nothing here yet. Make a little space with +.").font(.subheadline).foregroundStyle(Palette.muted).padding(.vertical, 8) }
                ForEach(entries) { item in
                    ItemRow(item: item, select: { notifications = false; selectedID = item.id }, toggle: { toggle(item) })
                    if item.kind == .goal || item.kind == .project { ProgressView(value: item.progress).tint(Palette.lime).accessibilityLabel("\(item.title) progress") }
                }
            }
        }
    }
    private func toggle(_ item: LifeItem) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
            if item.kind == .habit { item.toggleCheckIn() } else { item.completed.toggle() }
        }
        do { try context.save(); completionCount += 1 } catch { context.rollback(); self.error = error.localizedDescription }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("displayName") private var name = ""
    @AppStorage("haptics") private var haptics = true
    @AppStorage("focusMinutes") private var focusMinutes = 25
    @AppStorage("shareAIContext") private var share = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Make it yours") { TextField("Your first name", text: $name); Toggle("Haptic feedback", isOn: $haptics); Stepper("Focus session: \(focusMinutes) minutes", value: $focusMinutes, in: 5...120, step: 5) }
                Section("Assistant privacy") { Toggle("Share today’s task and event titles", isOn: $share); Text("Off by default. The current demo runs locally. No notes, attendees, or other personal details are shared. A real provider must add its own consent and privacy disclosure before use.").font(.caption) }
                Section("About FLIP") { Text("Everything in your life. One clear view."); Text("Your items stay on this device. Calendar entries are local to FLIP; system calendar and cloud sync are not connected.").font(.caption); Text("Duo is an adaptive workspace on wide windows, not a dependency on unannounced hardware.").font(.caption) }
            }.navigationTitle("Your FLIP").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
}
