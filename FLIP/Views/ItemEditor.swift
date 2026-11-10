import SwiftUI
import SwiftData

struct ItemEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let item: LifeItem?
    let allItems: [LifeItem]
    var onDeleted: () -> Void = {}
    var embedded = false
    @State private var title = ""
    @FocusState private var titleFocused: Bool
    @State private var notes = ""
    @State private var kind = ItemKind.task
    @State private var scheduled = false
    @State private var date = Date.now
    @State private var priority = 1
    @State private var projectID: UUID?
    @State private var progress = 0.0
    @State private var location = ""
    @State private var attendees = ""
    @State private var subtask = ""
    @State private var error: String?
    @State private var confirmDelete = false
    @State private var saved = false
    var body: some View {
        Form {
            Section(item == nil ? "Catch a thought" : "Details") {
                TextField("What’s on your mind?", text: $title).focused($titleFocused).font(.title3).accessibilityIdentifier("itemTitle")
                Picker("Type", selection: $kind) { ForEach(ItemKind.allCases) { Text($0.label).tag($0) } }
                TextField("Notes, ideas, a little context…", text: $notes, axis: .vertical).lineLimit(4...12)
            }
            Section("When & where") {
                Toggle("Add a date", isOn: $scheduled)
                if scheduled { DatePicker("Date", selection: $date) }
                if kind == .event { TextField("Location", text: $location); TextField("Attendees", text: $attendees) }
                if item == nil { Text("Capture keeps your words exactly as entered. Choose a date above; natural-language parsing is not connected.").font(.caption).foregroundStyle(.secondary) }
            }
            Section("Organization") {
                Picker("Priority", selection: $priority) { Text("Low").tag(0); Text("Normal").tag(1); Text("High").tag(2) }
                if kind != .project {
                    Picker("Project", selection: $projectID) {
                        Text("None").tag(nil as UUID?)
                        ForEach(allItems.filter { $0.kind == .project }) { Text($0.title).tag(Optional($0.id)) }
                    }
                }
                if kind == .project || kind == .goal || kind == .milestone {
                    LabeledContent("Progress", value: progress.formatted(.percent.precision(.fractionLength(0))))
                    Slider(value: $progress, in: 0...1, step: 0.05).accessibilityLabel("Progress")
                }
            }
            if let item {
                if item.kind == .project || item.kind == .task {
                    Section(item.kind == .project ? "Associated tasks" : "Subtasks") {
                        ForEach(allItems.filter { item.kind == .project ? $0.projectID == item.id : $0.parentID == item.id }) { child in
                            Button { child.completed.toggle(); persist() } label: { Label(child.title, systemImage: child.completed ? "checkmark.circle.fill" : "circle") }.tint(child.completed ? Palette.lime : Palette.white)
                        }
                        HStack {
                            TextField("New subtask", text: $subtask)
                            Button("Add") {
                                let child = LifeItem(subtask.trimmingCharacters(in: .whitespacesAndNewlines))
                                if item.kind == .project { child.projectID = item.id } else { child.parentID = item.id; child.projectID = item.projectID }
                                context.insert(child); persist(); subtask = ""
                            }.disabled(subtask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                if item.kind == .habit { Section("Habit history") { Text("\(item.checkIns.count) days checked in"); ForEach(item.checkIns.sorted(by: >), id: \.self) { Text($0, style: .date) } } }
                Section { Button("Delete \(item.kind.label.lowercased())", role: .destructive) { confirmDelete = true } }
            }
            if saved { Text("Saved on this device").foregroundStyle(Palette.lime).accessibilityIdentifier("savedMessage") }
        }
        .scrollContentBackground(.hidden).background(Palette.background)
        .navigationTitle(item == nil ? "Smart Capture" : "Make it yours").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { if !embedded { Button("Close") { dismiss() } } }
            ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).bold().disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveItem") }
        }
        .onAppear {
            guard let item else { titleFocused = true; return }
            title = item.title; notes = item.notes; kind = item.kind; scheduled = item.date != nil; date = item.date ?? .now
            priority = item.priority; projectID = item.projectID; progress = item.progress; location = item.location; attendees = item.attendees
        }
        .alert("Couldn’t save", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
        .confirmationDialog("Delete this item? This cannot be undone.", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                guard let item else { return }
                for child in allItems { if child.projectID == item.id { child.projectID = nil }; if child.parentID == item.id { child.parentID = nil } }
                context.delete(item)
                do { try context.save(); onDeleted(); dismiss() } catch { context.rollback(); self.error = error.localizedDescription }
            }
        }
    }
    private func persist() {
        do { try context.save() } catch { context.rollback(); self.error = error.localizedDescription }
    }
    private func save() {
        let target = item ?? LifeItem(LiteralCaptureParser().parse(title).title, kind: kind)
        if item == nil { context.insert(target) }
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines); target.notes = notes; target.kindRaw = kind.rawValue
        target.date = scheduled ? date : nil; target.priority = priority; target.projectID = kind == .project ? nil : projectID
        target.progress = progress; target.location = location; target.attendees = attendees
        do { try context.save(); saved = true; if item == nil { dismiss() } }
        catch { context.rollback(); self.error = error.localizedDescription }
    }
}
