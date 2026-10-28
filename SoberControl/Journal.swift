import Foundation
import Observation

enum DayStatus: String, Codable, CaseIterable, Identifiable {
    case sober, consumption
    var id: String { rawValue }
    var title: String { self == .sober ? "Bez alkoholu" : "Spożycie" }
    var symbol: String { self == .sober ? "checkmark" : "wineglass" }
}

struct JournalEntry: Codable, Equatable, Identifiable {
    let day: String
    var status: DayStatus
    var portions: Int
    var note: String
    var id: String { day }
}

struct JournalCalendar {
    var calendar: Calendar

    init(timeZone: TimeZone = .autoupdatingCurrent) {
        var value = Calendar(identifier: .gregorian)
        value.locale = Locale(identifier: "pl_PL")
        value.timeZone = timeZone
        value.firstWeekday = 2
        value.minimumDaysInFirstWeek = 4
        calendar = value
    }

    func key(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    func days(in component: Calendar.Component, containing date: Date) -> [Date] {
        guard let interval = calendar.dateInterval(of: component, for: date) else { return [] }
        var days: [Date] = []
        var cursor = interval.start
        while cursor < interval.end {
            days.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return days
    }

    func monthCells(_ date: Date) -> [Date?] {
        let dates = days(in: .month, containing: date)
        guard let first = dates.first else { return [] }
        let offset = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        var cells = Array<Date?>(repeating: nil, count: offset) + dates.map { Optional($0) }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    func isFuture(_ date: Date, now: Date = .now) -> Bool {
        calendar.startOfDay(for: date) > calendar.startOfDay(for: now)
    }

    func label(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

struct JournalSummary: Equatable {
    var sober = 0
    var consumption = 0
    var missing = 0
}

enum JournalError: LocalizedError {
    case future, invalidPortions, noteTooLong, damagedFile
    var errorDescription: String? {
        switch self {
        case .future: "Możesz zapisywać dzisiejszy dzień i dni wcześniejsze."
        case .invalidPortions: "Podaj liczbę porcji od 1 do 99."
        case .noteTooLong: "Notatka może mieć najwyżej 500 znaków."
        case .damagedFile: "Nie udało się odczytać dziennika. Oryginalny plik został zachowany. Zapis jest zablokowany, aby chronić dane."
        }
    }
}

@Observable @MainActor
final class JournalStore {
    private(set) var entries: [String: JournalEntry] = [:]
    private(set) var loadError: String?
    let fileURL: URL?
    let dates: JournalCalendar

    init(fileURL: URL?, dates: JournalCalendar = JournalCalendar(), seed: [JournalEntry] = []) {
        self.fileURL = fileURL
        self.dates = dates
        entries = Dictionary(seed.map { ($0.day, $0) }, uniquingKeysWith: { _, latest in latest })
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let saved = try JSONDecoder().decode([JournalEntry].self, from: Data(contentsOf: fileURL))
            let grouped = Dictionary(grouping: saved, by: \.day)
            guard grouped.values.allSatisfy({ $0.count == 1 }), saved.allSatisfy({
                Self.isValidKey($0.day, dates: dates) && $0.note.count <= 500 &&
                ($0.status == .sober ? $0.portions == 0 : (1...99).contains($0.portions))
            }) else { throw JournalError.damagedFile }
            entries = Dictionary(uniqueKeysWithValues: saved.map { ($0.day, $0) })
        } catch {
            entries = [:]
            loadError = JournalError.damagedFile.localizedDescription
        }
    }

    private static func isValidKey(_ key: String, dates: JournalCalendar) -> Bool {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = dates.calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
        else { return false }
        return dates.key(date) == key
    }

    func entry(on date: Date) -> JournalEntry? { entries[dates.key(date)] }

    func save(on date: Date, status: DayStatus, portions: Int = 0, note: String = "", now: Date = .now) throws {
        guard !dates.isFuture(date, now: now) else { throw JournalError.future }
        guard status == .sober || (1...99).contains(portions) else { throw JournalError.invalidPortions }
        guard note.count <= 500 else { throw JournalError.noteTooLong }
        let key = dates.key(date)
        var updated = entries
        updated[key] = JournalEntry(day: key, status: status, portions: status == .sober ? 0 : portions,
                                    note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        try persist(updated)
        entries = updated
    }

    func remove(on date: Date) throws {
        var updated = entries
        updated.removeValue(forKey: dates.key(date))
        try persist(updated)
        entries = updated
    }

    private func persist(_ updated: [String: JournalEntry]) throws {
        guard loadError == nil else { throw JournalError.damagedFile }
        guard let fileURL else { return }
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var protectedDirectory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try protectedDirectory.setResourceValues(values)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(updated.values.sorted { $0.day < $1.day })
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func summary(for days: [Date], now: Date = .now) -> JournalSummary {
        var result = JournalSummary()
        for day in days where !dates.isFuture(day, now: now) {
            switch entry(on: day)?.status {
            case .sober: result.sober += 1
            case .consumption: result.consumption += 1
            case nil: result.missing += 1
            }
        }
        return result
    }

    /// An unlogged today leaves yesterday's completed streak visible. Any earlier gap breaks it.
    func streak(now: Date = .now) -> Int {
        var day = dates.calendar.startOfDay(for: now)
        if entry(on: day) == nil { day = dates.calendar.date(byAdding: .day, value: -1, to: day)! }
        var count = 0
        while entry(on: day)?.status == .sober {
            count += 1
            day = dates.calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    static func demo(now: Date = .now) -> JournalStore {
        let dates = JournalCalendar()
        let seed = (1...150).compactMap { offset -> JournalEntry? in
            guard offset % 11 != 0 else { return nil }
            let date = dates.calendar.date(byAdding: .day, value: -offset, to: now)!
            let status: DayStatus = offset % 9 == 0 ? .consumption : .sober
            return JournalEntry(day: dates.key(date), status: status, portions: status == .sober ? 0 : 2,
                                note: offset == 9 ? "Przykładowy wpis" : "")
        }
        return JournalStore(fileURL: nil, dates: dates, seed: seed)
    }
}
