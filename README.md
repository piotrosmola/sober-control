# SoberControl

Natywna aplikacja iPhone w SwiftUI / Swift 6. Minimalny system: iOS 17.

## Uruchomienie

Otwórz `SoberControl.xcodeproj`, wybierz schemat **SoberControl** i symulator iPhone, a następnie **Product → Run**.
Projekt używa istniejącego zespołu `HM62L7YB7F` (Piotr Osmola, Personal Team), automatycznego podpisywania i identyfikatora `com.piotrosmola.SoberControl`.
Symulator nie wymaga konta Apple. Uruchomienie na fizycznym urządzeniu może wymagać ponownego logowania w Xcode i włączenia trybu deweloperskiego na iPhonie.

## Gotowe funkcje

- Widoki tygodnia (od poniedziałku), miesiąca i roku. Dotknięcie miesiąca w roku otwiera jego kalendarz.
- Trzy rozróżnione stany: **bez alkoholu**, **spożycie**, **brak wpisu**. Przyszłe dni mają oddzielne, nieaktywne oznaczenie.
- Dodawanie, edycja i usuwanie wpisu; liczba porcji przy spożyciu i opcjonalna notatka.
- Podsumowanie wybranego okresu do dzisiaj i seria kolejnych zapisanych dni bez alkoholu. Brak wpisu przerywa serię. Nieuzupełnione dzisiaj pozostawia widoczną serię zakończoną wczoraj.
- Polski interfejs, kolory dla jasnego i ciemnego motywu, etykiety VoiceOver, skalowana typografia i ikona aplikacji.
- Tryb demonstracyjny w menu **… → Zobacz dane demonstracyjne**. Przykłady są wyłącznie w pamięci, oddzielone od dziennika. Nowa instalacja zaczyna od pustego dziennika.

## Dane lokalne

Dziennik jest plikiem JSON w `Application Support/SoberControl/journal.json` w prywatnym kontenerze aplikacji.
Zapis jest atomowy; nieudany zapis nie zmienia stanu w pamięci. Uszkodzony plik blokuje dalszy zapis i pozostaje zachowany.
Pliki są chronione mechanizmem iOS Data Protection po pierwszym odblokowaniu urządzenia. To nie jest dodatkowe szyfrowanie hasłem aplikacji.
Katalog wpisów jest wykluczony z kopii zapasowej. Nie ma synchronizacji, serwera ani analityki. Usunięcie aplikacji usuwa dziennik; wersja początkowa nie ma eksportu ani odzyskiwania.
Zmiana strefy czasowej zachowuje przypisane daty: wpisy są identyfikowane jako lokalne dni `YYYY-MM-DD`.

Liczba porcji jest własną miarą użytkownika; aplikacja nie wylicza stężenia alkoholu ani standardowych jednostek.

## Testy

```sh
./scripts/verify.sh
```

Inny symulator:

```sh
SOBERCONTROL_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' ./scripts/verify.sh
```

W Xcode: **Product → Test**. Udostępniony schemat zawiera testy logiki i testy interfejsu.
Testy UI używają osobnego katalogu `SoberControl-UITests`; nie dotykają dziennika użytkownika.
Argumenty `--ui-testing` i `--reset-journal` działają tylko w konfiguracji Debug. `--demo` uruchamia widok demonstracyjny.

## Git, GitHub i dystrybucja

Repozytorium Git jest lokalne, z gałęzią `main`. Nie dodano zdalnego repozytorium ani nie wysłano kodu.
Zgodnie z decyzją użytkownika z 28 października 2026 dalsze działania pozostają lokalne.
Przygotowano schemat do build/test/archive, polecenie weryfikacji i szablon PR. Plan aktywacji GitHub → Xcode Cloud → TestFlight znajduje się w [docs/DELIVERY.md](docs/DELIVERY.md).
Zobacz też [wynik weryfikacji](docs/VERIFICATION.md).
