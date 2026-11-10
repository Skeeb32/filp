import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let user: Bool
}
@Observable @MainActor final class AssistantModel {
    var messages: [ChatMessage] = []
    var loading = false
    var error: String?
    private let service: any AIService
    init(service: any AIService = DemoAIService()) { self.service = service }
    func send(_ text: String, context: AssistantContext?) async {
        guard !loading, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        messages.append(ChatMessage(text: text, user: true)); loading = true; error = nil
        defer { loading = false }
        do { messages.append(ChatMessage(text: try await service.reply(to: text, context: context), user: false)) }
        catch { self.error = error.localizedDescription }
    }
}
struct AssistantView: View {
    let items: [LifeItem]
    @Bindable var model: AssistantModel
    @State private var prompt = ""
    @AppStorage("shareAIContext") private var share = false
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(Palette.purple).padding(.top, 12)
            Text("A clearer headspace.").font(.largeTitle.bold())
            Text("Think out loud. Find your next step.").foregroundStyle(Palette.muted)
            Surface {
                VStack(alignment: .leading, spacing: 12) {
                    Label("LOCAL DEVELOPMENT DEMO", systemImage: "lock.shield").font(.caption.bold()).foregroundStyle(Palette.purple)
                    Text("No AI provider is connected. Replies are labeled, rule-based examples. Nothing leaves your device.").font(.subheadline).foregroundStyle(Palette.muted)
                    Toggle("Include today’s task & event titles", isOn: $share).font(.subheadline)
                    if share { Text("Only titles are included. Notes, locations, and attendees stay private.").font(.caption).foregroundStyle(Palette.muted) }
                }
            }
            if model.messages.isEmpty {
                ForEach(["Organize my day.", "What should I focus on?", "Plan my week.", "Break this project into tasks.", "Find time for the gym.", "Summarize my upcoming week."], id: \.self) { suggestion in
                    Button { send(suggestion) } label: { HStack { Text(suggestion); Spacer(); Image(systemName: "arrow.up.right") }.padding(16).background(Palette.surface, in: RoundedRectangle(cornerRadius: 18)) }.foregroundStyle(Palette.white).disabled(model.loading)
                }
            }
            ForEach(model.messages) { message in
                Surface { VStack(alignment: .leading, spacing: 8) { Text(message.user ? "YOU" : "FLIP · DEMO").font(.caption.bold()).foregroundStyle(message.user ? Palette.lime : Palette.purple); Text(message.text).textSelection(.enabled) } }
            }
            if model.loading { ProgressView("Making room for a thought…").tint(Palette.purple) }
            if let error = model.error { Text(error).foregroundStyle(.red) }
            HStack(alignment: .bottom) {
                TextField("What’s on your mind?", text: $prompt, axis: .vertical).lineLimit(1...5).padding(16).background(Palette.elevated, in: RoundedRectangle(cornerRadius: 20))
                Button { let text = prompt; prompt = ""; send(text) } label: { Image(systemName: "arrow.up").bold().frame(width: 48, height: 48).background(Palette.purple, in: Circle()).foregroundStyle(Palette.white) }.accessibilityLabel("Send message").disabled(model.loading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if !model.messages.isEmpty { Button("Clear conversation") { model.messages = [] }.font(.caption).disabled(model.loading) }
        }
    }
    private func send(_ text: String) {
        let today = DayLogic.items(items, on: .now)
        let context = share ? AssistantContext(taskTitles: today.filter { $0.kind == .task && !$0.completed }.map(\.title), eventTitles: today.filter { $0.kind == .event }.map(\.title)) : nil
        Task { await model.send(text, context: context) }
    }
}
