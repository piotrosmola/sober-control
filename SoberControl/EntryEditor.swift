import SwiftUI

struct EntryEditor: View {
    let store: JournalStore
    let date: Date
    let isDemo: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var status: DayStatus
    @State private var portions: Int
    @State private var note: String
    @State private var error: String?
    @State private var confirmDelete = false

    init(store: JournalStore, date: Date, isDemo: Bool) {
        self.store = store
        self.date = date
        self.isDemo = isDemo
        let entry = store.entry(on: date)
        _status = State(initialValue: entry?.status ?? .sober)
        _portions = State(initialValue: max(1, entry?.portions ?? 1))
        _note = State(initialValue: entry?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(store.dates.label(date, format: "EEEE, d MMMM yyyy").capitalized).font(.headline)
                    if isDemo { Label("Wpis demonstracyjny", systemImage: "flask").foregroundStyle(Palette.teal) }
                }
                Section("Jak wyglądał ten dzień?") {
                    Picker("Status dnia", selection: $status) {
                        ForEach(DayStatus.allCases) { item in Label(item.title, systemImage: item.symbol).tag(item) }
                    }.pickerStyle(.segmented).accessibilityIdentifier("entry-status")
                    if status == .consumption {
                        Stepper("Liczba porcji: \(portions)", value: $portions, in: 1...99)
                            .accessibilityIdentifier("entry-portions")
                        Text("Porcja to Twoja własna miara. Aplikacja nie przelicza ilości alkoholu.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section {
                    TextField("Co chcesz zapamiętać?", text: $note, axis: .vertical)
                        .lineLimit(3...6).accessibilityIdentifier("entry-note")
                    Text("\(note.count)/500 znaków").font(.caption).foregroundStyle(note.count > 500 ? Palette.amber : .secondary)
                } header: { Text("Notatka (opcjonalna)") }
                footer: { Text("Dziennik jest zapisany lokalnie i nie jest synchronizowany ani dołączany do kopii iCloud. Usunięcie aplikacji usuwa także wpisy.") }
                if store.entry(on: date) != nil {
                    Section {
                        Button("Usuń wpis", role: .destructive) { confirmDelete = true }.accessibilityIdentifier("delete-entry")
                    }
                }
            }
            .navigationTitle("Wpis dnia").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Anuluj") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") {
                        do { try store.save(on: date, status: status, portions: portions, note: note); dismiss() }
                        catch { self.error = error.localizedDescription }
                    }
                    .fontWeight(.semibold).disabled(note.count > 500 || store.loadError != nil)
                    .accessibilityIdentifier("save-entry")
                }
            }
            .alert("Nie udało się zapisać", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
            .confirmationDialog("Usunąć wpis? Ten dzień ponownie będzie oznaczony jako brak wpisu.", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Usuń wpis", role: .destructive) {
                    do { try store.remove(on: date); dismiss() }
                    catch { self.error = error.localizedDescription }
                }
            }
        }
    }
}
