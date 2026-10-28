import SwiftUI
import Combine

enum Palette {
    static let teal = Color("JournalTeal")
    static let amber = Color("JournalAmber")
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
}

extension DayStatus {
    var color: Color { self == .sober ? Palette.teal : Palette.amber }
}

enum CalendarPeriod: String, CaseIterable, Identifiable {
    case week = "Tydzień", month = "Miesiąc", year = "Rok"
    var id: String { rawValue }
    var component: Calendar.Component {
        switch self { case .week: .weekOfYear; case .month: .month; case .year: .year }
    }
}

private struct SelectedDay: Identifiable {
    let date: Date
    var id: Date { date }
}

struct CalendarScreen: View {
    let store: JournalStore
    @State private var demoStore = JournalStore.demo()
    @State private var isDemo: Bool
    @State private var period: CalendarPeriod = .month
    @State private var cursor = Date.now
    @State private var selectedDay: SelectedDay?
    @Environment(\.scenePhase) private var scenePhase
    @State private var now = Date.now

    init(store: JournalStore, startInDemo: Bool = false) {
        self.store = store
        _isDemo = State(initialValue: startInDemo)
    }

    private var active: JournalStore { isDemo ? demoStore : store }
    private var dates: JournalCalendar { active.dates }
    private var summary: JournalSummary { active.summary(for: dates.days(in: period.component, containing: cursor), now: now) }
    private var periodTitle: String {
        if period == .week {
            let days = dates.days(in: .weekOfYear, containing: cursor)
            return "\(dates.label(days.first ?? cursor, format: "d MMM")) – \(dates.label(days.last ?? cursor, format: "d MMM yyyy"))"
        }
        return dates.label(cursor, format: period == .year ? "yyyy" : "LLLL yyyy").capitalized
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if isDemo { demoBanner }
                    if let error = active.loadError {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.callout).foregroundStyle(Palette.amber).padding().card()
                    }
                    todayCard
                    Picker("Widok kalendarza", selection: $period) {
                        ForEach(CalendarPeriod.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).accessibilityIdentifier("calendar-period")
                    VStack(spacing: 18) {
                        periodNavigation
                        switch period {
                        case .week: weekView
                        case .month: monthView(cursor)
                        case .year: yearView
                        }
                        legend
                    }
                    .padding(18).card()
                    summaryView
                    Text("Każdy wpis to informacja dla Ciebie. Dni bez wpisu pozostają nieuzupełnione.")
                        .font(.footnote).foregroundStyle(.secondary).padding(.horizontal, 4)
                    Label("Dane tylko na tym iPhonie", systemImage: "lock.shield")
                        .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
                .padding(20)
            }
            .background(Palette.background)
            .navigationTitle("SoberControl")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(isDemo ? "Wróć do mojego dziennika" : "Zobacz dane demonstracyjne", systemImage: "flask") {
                            isDemo.toggle()
                            cursor = .now
                        }
                    } label: { Image(systemName: "ellipsis.circle").accessibilityLabel("Opcje dziennika") }
                }
            }
            .sheet(item: $selectedDay) { day in
                EntryEditor(store: active, date: day.date, isDemo: isDemo)
            }
            .onChange(of: scenePhase) { _, value in if value == .active { now = .now } }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { now = $0 }
        }
    }

    private var demoBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tryb demonstracyjny", systemImage: "flask.fill").font(.subheadline.bold())
            Text("To przykładowe dane. Zmiany w tym trybie nie trafiają do Twojego dziennika.").font(.footnote)
            Button("Otwórz mój dziennik") { isDemo = false }.font(.footnote.bold())
        }
        .foregroundStyle(Palette.teal).padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.teal.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(dates.label(now, format: "EEEE, d MMMM").capitalized).font(.subheadline).foregroundStyle(.secondary)
                    Text("Dziś, krok po kroku").font(.title2.bold())
                }
                Spacer(minLength: 8)
                Image(systemName: "leaf").font(.title2).foregroundStyle(Palette.teal)
                    .padding(12).background(Palette.teal.opacity(0.09), in: Circle()).accessibilityHidden(true)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(active.streak(now: now))").font(.system(.largeTitle, design: .rounded, weight: .bold)).foregroundStyle(Palette.teal)
                Text("kolejnych zapisanych dni\nbez alkoholu").font(.subheadline).foregroundStyle(.secondary)
            }.accessibilityElement(children: .combine)
            Button {
                selectedDay = SelectedDay(date: now)
            } label: {
                Label(active.entry(on: now) == nil ? "Uzupełnij dzisiejszy dzień" : "Edytuj dzisiejszy wpis",
                      systemImage: active.entry(on: now)?.status.symbol ?? "plus")
                    .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent).accessibilityIdentifier("edit-today")
            .disabled(active.loadError != nil)
        }.padding(20).card()
    }

    private var periodNavigation: some View {
        VStack(spacing: 8) {
            HStack {
                Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Poprzedni okres")
                Spacer(minLength: 0)
                Text(periodTitle).font(.headline).multilineTextAlignment(.center).accessibilityIdentifier("period-title")
                Spacer(minLength: 0)
                Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .accessibilityLabel("Następny okres")
            }
            Button("Dzisiaj") { cursor = now }.font(.caption.bold()).accessibilityIdentifier("jump-today")
        }
    }

    private func move(_ value: Int) {
        // Anchor to the interval start so Jan 31 → Feb → Mar never drifts or skips months.
        let start = dates.calendar.dateInterval(of: period.component, for: cursor)?.start ?? cursor
        if let next = dates.calendar.date(byAdding: period.component, value: value, to: start) { cursor = next }
    }

    private var weekView: some View {
        VStack(spacing: 2) {
            ForEach(dates.days(in: .weekOfYear, containing: cursor), id: \.self) { day in
                Button { selectedDay = SelectedDay(date: day) } label: {
                    HStack(spacing: 14) {
                        Text(dates.label(day, format: "d")).font(.title3.bold()).frame(width: 36)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(dates.label(day, format: "EEEE").capitalized).font(.subheadline.bold())
                            Text(statusTitle(day)).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        statusIcon(day).frame(width: 32, height: 32)
                    }
                    .padding(.vertical, 10).padding(.horizontal, 8).contentShape(Rectangle())
                    .background(dates.calendar.isDate(day, inSameDayAs: now) ? Palette.teal.opacity(0.06) : .clear,
                                in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain).disabled(dates.isFuture(day, now: now) || active.loadError != nil)
                .accessibilityLabel("\(dates.label(day, format: "d MMMM yyyy")), \(statusTitle(day))")
            }
        }.accessibilityIdentifier("week-view")
    }

    private func monthView(_ month: Date) -> some View {
        VStack(spacing: 8) {
            weekdayHeader
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 6) {
                ForEach(Array(dates.monthCells(month).enumerated()), id: \.offset) { _, day in
                    if let day {
                        Button { selectedDay = SelectedDay(date: day) } label: {
                            VStack(spacing: 5) {
                                Text("\(dates.calendar.component(.day, from: day))").font(.subheadline.weight(.semibold))
                                statusIcon(day).font(.system(size: 11, weight: .bold)).frame(height: 13)
                            }
                            .frame(maxWidth: .infinity, minHeight: 49)
                            .foregroundStyle(dates.isFuture(day, now: now) ? Color.secondary.opacity(0.5) : .primary)
                            .background((active.entry(on: day)?.status.color ?? Color.secondary).opacity(dates.isFuture(day, now: now) ? 0.025 : 0.08),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                if dates.calendar.isDate(day, inSameDayAs: now) {
                                    RoundedRectangle(cornerRadius: 12).stroke(Palette.teal, lineWidth: 1.5)
                                }
                            }
                        }
                        .buttonStyle(.plain).disabled(dates.isFuture(day, now: now) || active.loadError != nil)
                        .accessibilityLabel("\(dates.label(day, format: "d MMMM yyyy")), \(statusTitle(day))")
                        .accessibilityIdentifier("day-\(dates.key(day))")
                    } else { Color.clear.frame(height: 49).accessibilityHidden(true) }
                }
            }
        }.accessibilityIdentifier("month-view")
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["Pn", "Wt", "Śr", "Cz", "Pt", "So", "Nd"], id: \.self) { day in
                Text(day).font(.caption2.weight(.semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
        }.accessibilityHidden(true)
    }

    private var yearView: some View {
        let start = dates.calendar.dateInterval(of: .year, for: cursor)!.start
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 22) {
            ForEach(0..<12) { offset in
                let month = dates.calendar.date(byAdding: .month, value: offset, to: start)!
                Button { cursor = month; period = .month } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dates.label(month, format: "LLLL").capitalized).font(.subheadline.bold())
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 3) {
                            ForEach(Array(dates.monthCells(month).enumerated()), id: \.offset) { _, day in
                                if let day {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill((active.entry(on: day)?.status.color ?? Color.secondary).opacity(dates.isFuture(day, now: now) ? 0.07 : active.entry(on: day) == nil ? 0.18 : 0.85))
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay {
                                            if active.entry(on: day)?.status == .consumption {
                                                Circle().stroke(.primary.opacity(0.7), lineWidth: 1).padding(2)
                                            }
                                        }
                                } else { Color.clear.aspectRatio(1, contentMode: .fit) }
                            }
                        }
                    }.foregroundStyle(.primary).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(dates.label(month, format: "LLLL yyyy")), otwórz miesiąc")
                .accessibilityIdentifier("year-month-\(offset + 1)")
            }
        }.accessibilityIdentifier("year-view")
    }

    private func statusTitle(_ day: Date) -> String {
        dates.isFuture(day, now: now) ? "Przyszły dzień" : active.entry(on: day)?.status.title ?? "Brak wpisu"
    }

    private func statusIcon(_ day: Date) -> some View {
        Image(systemName: dates.isFuture(day, now: now) ? "circle" : active.entry(on: day)?.status.symbol ?? "minus")
            .foregroundStyle(active.entry(on: day)?.status.color ?? Color.secondary.opacity(0.6))
            .accessibilityHidden(true)
    }

    private var legend: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { legendItems }
            VStack(alignment: .leading, spacing: 8) { legendItems }
        }.font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var legendItems: some View {
        Label("Bez alkoholu", systemImage: "checkmark").foregroundStyle(Palette.teal)
        Label("Spożycie", systemImage: "wineglass").foregroundStyle(Palette.amber)
        Label("Brak wpisu", systemImage: "minus")
    }

    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("W tym okresie").font(.headline)
            VStack(spacing: 12) {
                summaryRow("Bez alkoholu", count: summary.sober, symbol: "checkmark.circle.fill", color: Palette.teal)
                summaryRow("Ze spożyciem", count: summary.consumption, symbol: "wineglass", color: Palette.amber)
                summaryRow("Bez wpisu", count: summary.missing, symbol: "minus.circle", color: .secondary)
            }
            Text("Podsumowanie obejmuje dni do dzisiaj.").font(.caption).foregroundStyle(.secondary)
        }.padding(20).card()
    }

    private func summaryRow(_ title: String, count: Int, symbol: String, color: Color) -> some View {
        HStack {
            Label(title, systemImage: symbol).foregroundStyle(color)
            Spacer()
            Text("\(count)").font(.system(.body, design: .rounded, weight: .semibold))
        }.font(.subheadline).accessibilityElement(children: .combine)
    }
}

private extension View {
    func card() -> some View { background(Palette.card, in: RoundedRectangle(cornerRadius: 24)) }
}
