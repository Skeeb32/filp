import SwiftUI

enum Palette {
    static let background = Color(red: 9/255, green: 10/255, blue: 13/255)
    static let surface = Color(red: 17/255, green: 19/255, blue: 24/255)
    static let elevated = Color(red: 25/255, green: 28/255, blue: 36/255)
    static let purple = Color(red: 146/255, green: 117/255, blue: 1)
    static let lime = Color(red: 200/255, green: 243/255, blue: 106/255)
    static let white = Color(red: 245/255, green: 245/255, blue: 247/255)
    static let muted = Color(red: 133/255, green: 136/255, blue: 149/255)
}
struct Surface<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.06), lineWidth: 1))
    }
}
struct SectionLabel: View {
    let title: String
    var detail: String = ""
    var body: some View {
        HStack { Text(title).font(.title3.bold()); Spacer(); Text(detail).font(.caption).foregroundStyle(Palette.muted) }.padding(.top, 8)
    }
}
struct ProgressRing: View {
    @ScaledMetric(relativeTo: .title2) private var diameter = 88.0
    let value: Double
    var body: some View {
        ZStack {
            Circle().stroke(Palette.elevated, lineWidth: 9)
            Circle().trim(from: 0, to: min(1, max(0, value))).stroke(Palette.lime, style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90))
            Text(value, format: .percent.precision(.fractionLength(0))).font(.title2.bold().monospacedDigit())
        }.frame(width: diameter, height: diameter).accessibilityElement(children: .ignore).accessibilityLabel("Progress \(Int(value * 100)) percent")
    }
}
struct ItemRow: View {
    let item: LifeItem
    var select: () -> Void
    var toggle: () -> Void
    var body: some View {
        HStack(spacing: 14) {
            if item.kind == .task || item.kind == .habit {
                Button(action: toggle) {
                    Image(systemName: (item.kind == .habit ? item.checked() : item.completed) ? "checkmark.circle.fill" : "circle")
                        .font(.title2).foregroundStyle((item.kind == .habit ? item.checked() : item.completed) ? Palette.lime : Palette.muted)
                        .frame(width: 44, height: 44)
                }.buttonStyle(.plain).accessibilityLabel("Toggle \(item.title)")
            } else {
                Image(systemName: item.kind.icon).foregroundStyle(Palette.purple).frame(width: 44, height: 44)
            }
            Button(action: select) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title).font(.body.weight(.medium)).strikethrough(item.completed).foregroundStyle(item.completed ? Palette.muted : Palette.white)
                    HStack {
                        Text(item.kind.label)
                        if let date = item.date { Text(date, format: .dateTime.hour().minute()) }
                        if item.priority == 2 { Text("• Priority").foregroundStyle(Palette.purple) }
                    }.font(.caption).foregroundStyle(Palette.muted)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
            }.buttonStyle(.plain)
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Palette.muted).accessibilityHidden(true)
        }.draggable(item.id.uuidString)
    }
}
