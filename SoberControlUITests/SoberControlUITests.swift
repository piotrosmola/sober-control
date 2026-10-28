import XCTest

@MainActor
final class SoberControlUITests: XCTestCase {
    func testCalendarPeriodsAndYearDrilldown() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-journal", "--demo"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Tryb demonstracyjny"].waitForExistence(timeout: 10))
        let picker = app.segmentedControls["calendar-period"]
        picker.buttons["Tydzień"].tap()
        XCTAssertTrue(app.otherElements["week-view"].exists || app.buttons.matching(NSPredicate(format: "label CONTAINS 'Brak wpisu'")).count > 0)
        picker.buttons["Rok"].tap()
        app.swipeUp()
        let january = app.buttons["year-month-1"]
        XCTAssertTrue(january.waitForExistence(timeout: 5))
        if !january.isHittable { app.swipeDown() }
        january.tap()
        XCTAssertTrue(picker.buttons["Miesiąc"].isSelected)
    }

    func testSaveRelaunchEditAndDelete() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-journal"]
        app.launch()
        app.buttons["edit-today"].tap()
        app.segmentedControls["entry-status"].buttons["Spożycie"].tap()
        XCTAssertTrue(app.steppers["entry-portions"].exists)
        let note = app.descendants(matching: .any).matching(identifier: "entry-note").firstMatch
        note.tap()
        note.typeText("Test lokalnego zapisu")
        app.buttons["save-entry"].tap()
        XCTAssertTrue(app.buttons["Edytuj dzisiejszy wpis"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        app.buttons["edit-today"].tap()
        XCTAssertTrue(app.segmentedControls["entry-status"].buttons["Spożycie"].isSelected)
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "entry-note").firstMatch.value as? String, "Test lokalnego zapisu")
        app.segmentedControls["entry-status"].buttons["Bez alkoholu"].tap()
        app.buttons["save-entry"].tap()
        app.buttons["edit-today"].tap()
        XCTAssertTrue(app.segmentedControls["entry-status"].buttons["Bez alkoholu"].isSelected)
        app.buttons["delete-entry"].tap()
        app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", "Usuń wpis", "delete-entry")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Uzupełnij dzisiejszy dzień"].waitForExistence(timeout: 5))
    }
}
