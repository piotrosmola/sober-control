import SwiftUI

@main
struct SoberControlApp: App {
    @State private var store: JournalStore
    private let startInDemo: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        var directory = URL.applicationSupportDirectory.appending(path: "SoberControl", directoryHint: .isDirectory)
        #if DEBUG
        if arguments.contains("--ui-testing") {
            directory = URL.applicationSupportDirectory.appending(path: "SoberControl-UITests", directoryHint: .isDirectory)
            if arguments.contains("--reset-journal") {
                try? FileManager.default.removeItem(at: directory.appending(path: "journal.json"))
            }
        }
        #endif
        _store = State(initialValue: JournalStore(fileURL: directory.appending(path: "journal.json")))
        startInDemo = arguments.contains("--demo")
    }

    var body: some Scene {
        WindowGroup {
            CalendarScreen(store: store, startInDemo: startInDemo)
                .environment(\.locale, Locale(identifier: "pl_PL"))
                .tint(Palette.teal)
        }
    }
}
