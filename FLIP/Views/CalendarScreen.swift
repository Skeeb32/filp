import SwiftUI

struct CalendarScreen: View {
    let items: [LifeItem]
    let select: (LifeItem) -> Void
    let toggle: (LifeItem) -> Void
    @State private var selected = Date.now
    @State private var week = false
    private let calendar = Calendar.current
    private var days: [Date] {
        let interval = calendar.dateInterval(of: week ? .weekOfYear : .month, for: selected)!
        let count = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 7
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }
    private var leading: Int {
        guard !week, let first = days.first else { return 0 }
        return (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Time, on your terms.").font(.largeTitle.bold())
            Picker("Calendar view", selection: $week) { Text("Month").tag(false); Text("Week").tag(true) }.pickerStyle(.segmented)
            Surface {
                VStack(spacing: 20) {
                    HStack {
                        Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.accessibilityLabel("Previous period")
                        Spacer(); Text(selected.formatted(.dateTime.month(.wide).year())).font(.headline); Spacer()
                        Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }.accessibilityLabel("Next period")
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 12) {
                        ForEach(0..<7, id: \.self) { index in
                            Text(calendar.veryShortStandaloneWeekdaySymbols[(index + calendar.firstWeekday - 1) % 7]).font(.caption).foregroundStyle(Palette.muted)
                        }
                        ForEach(0..<leading, id: \.self) { _ in Color.clear.frame(height: 44) }
                        ForEach(days, id: \.self) { day in
                            Button { selected = day } label: {
                                VStack(spacing: 4) {
                                    Text(day.formatted(.dateTime.day())).font(.callout.weight(.medium))
                                    Circle().fill(DayLogic.items(items, on: day).isEmpty ? .clear : Palette.purple).frame(width: 4, height: 4)
                                }.frame(maxWidth: .infinity).frame(minHeight: 44)
                                    .background(calendar.isDate(day, inSameDayAs: selected) ? Palette.lime : .clear, in: RoundedRectangle(cornerRadius: 14))
                                    .foregroundStyle(calendar.isDate(day, inSameDayAs: selected) ? Palette.background : Palette.white)
                            }.accessibilityLabel(day.formatted(date: .complete, time: .omitted)).accessibilityAddTraits(calendar.isDate(day, inSameDayAs: selected) ? .isSelected : [])
                        }
                    }
                    Button("Back to today") { selected = .now }.font(.caption.bold())
                }
            }
            SectionLabel(title: selected.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)), detail: "AGENDA")
            let agenda = DayLogic.items(items, on: selected)
            if agenda.isEmpty { ContentUnavailableView("A little breathing room", systemImage: "sun.max", description: Text("No plans for this day. Capture something with +.")) }
            else { Surface { VStack(spacing: 12) { ForEach(agenda) { item in ItemRow(item: item, select: { select(item) }, toggle: { toggle(item) }) } } } }
        }
    }
    private func move(_ direction: Int) { selected = calendar.date(byAdding: week ? .weekOfYear : .month, value: direction, to: selected) ?? selected }
}
