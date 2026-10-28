import XCTest
@testable import SoberControl

@MainActor
final class JournalTests: XCTestCase {
    private var dates: JournalCalendar { JournalCalendar(timeZone: TimeZone(identifier: "Europe/Warsaw")!) }
    private func date(_ day: Int) -> Date { date(2026, 10, day) }
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        dates.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
    private func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString).appending(path: "journal.json")
    }

    func testWeekStartsMondayAndCrossesDST() {
        let days = dates.days(in: .weekOfYear, containing: date(2026, 10, 25))
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(dates.key(days.first!), "2026-10-19")
        XCTAssertEqual(dates.key(days.last!), "2026-10-25")
        XCTAssertEqual(dates.calendar.component(.weekday, from: days.first!), 2)
    }

    func testLeapMonthAndYear() {
        XCTAssertEqual(dates.days(in: .month, containing: date(2024, 2, 10)).count, 29)
        XCTAssertEqual(dates.days(in: .year, containing: date(2024, 2, 10)).count, 366)
        XCTAssertEqual(dates.days(in: .year, containing: date(2026, 1, 1)).count, 365)
        let cells = dates.monthCells(date(2024, 2, 10))
        XCTAssertEqual(cells.count % 7, 0)
        XCTAssertNil(cells[0])
        XCTAssertEqual(dates.key(cells[3]!), "2024-02-01")
    }

    func testKeysUseLocalDayRatherThanUTC() {
        let localMidnight = dates.calendar.startOfDay(for: date(28))
        XCTAssertEqual(dates.key(localMidnight), "2026-10-28")
        let utc = JournalCalendar(timeZone: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(utc.key(localMidnight), "2026-10-27")
    }

    func testSummaryDistinguishesMissingAndExcludesFuture() throws {
        let store = JournalStore(fileURL: nil, dates: dates)
        try store.save(on: date(26), status: .sober, now: date(28))
        try store.save(on: date(27), status: .consumption, portions: 2, now: date(28))
        let days = (26...30).map { date($0) }
        XCTAssertEqual(store.summary(for: days, now: date(28)), JournalSummary(sober: 1, consumption: 1, missing: 1))
        XCTAssertNil(store.entry(on: date(28)))
    }

    func testStreakBreaksOnGapAndConsumption() throws {
        let store = JournalStore(fileURL: nil, dates: dates)
        for day in [24, 26, 27] { try store.save(on: date(day), status: .sober, now: date(28)) }
        XCTAssertEqual(store.streak(now: date(28)), 2)
        try store.save(on: date(28), status: .sober, now: date(28))
        XCTAssertEqual(store.streak(now: date(28)), 3)
        try store.save(on: date(28), status: .consumption, portions: 1, now: date(28))
        XCTAssertEqual(store.streak(now: date(28)), 0)
    }

    func testPersistenceUpdatesAndDeletes() throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let store = JournalStore(fileURL: file, dates: dates)
        try store.save(on: date(28), status: .consumption, portions: 3, note: "  Wpis testowy  ", now: date(28))
        let restored = JournalStore(fileURL: file, dates: dates)
        XCTAssertEqual(restored.entry(on: date(28))?.portions, 3)
        XCTAssertEqual(restored.entry(on: date(28))?.note, "Wpis testowy")
        try restored.save(on: date(28), status: .sober, portions: 5, now: date(28))
        XCTAssertEqual(restored.entries.count, 1)
        XCTAssertEqual(restored.entry(on: date(28))?.portions, 0)
        try restored.remove(on: date(28))
        XCTAssertTrue(JournalStore(fileURL: file, dates: dates).entries.isEmpty)
    }

    func testCorruptedDataCannotBeOverwritten() throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let original = Data("broken-json".utf8)
        try original.write(to: file)
        let store = JournalStore(fileURL: file, dates: dates)
        XCTAssertNotNil(store.loadError)
        XCTAssertThrowsError(try store.save(on: date(28), status: .sober, now: date(28)))
        XCTAssertEqual(try Data(contentsOf: file), original)
    }

    func testInvalidEntryIsRejected() throws {
        let store = JournalStore(fileURL: nil, dates: dates)
        XCTAssertThrowsError(try store.save(on: date(29), status: .sober, now: date(28)))
        XCTAssertThrowsError(try store.save(on: date(28), status: .consumption, portions: 0, now: date(28)))
        XCTAssertThrowsError(try store.save(on: date(28), status: .consumption, portions: 100, now: date(28)))
        XCTAssertThrowsError(try store.save(on: date(28), status: .sober, note: String(repeating: "x", count: 501), now: date(28)))
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testFailedDiskWriteDoesNotChangeMemory() throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let store = JournalStore(fileURL: file, dates: dates)
        // A directory cannot be replaced by the journal's atomic file write.
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)
        XCTAssertThrowsError(try store.save(on: date(28), status: .sober, now: date(28)))
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testDemoIsInMemoryAndContainsAllThreeStates() {
        let store = JournalStore.demo(now: date(28))
        XCTAssertNil(store.fileURL)
        XCTAssertTrue(store.entries.values.contains { $0.status == .sober })
        XCTAssertTrue(store.entries.values.contains { $0.status == .consumption })
        XCTAssertNil(store.entry(on: date(17)))
    }
}
