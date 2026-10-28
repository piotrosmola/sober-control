# Weryfikacja — 28 października 2026

## Środowisko

- Xcode 27.1, build 27A9275.
- Symulator iPhone 18 Pro, iOS 27.0.
- Swift 6, deployment target iOS 17, docelowa rodzina urządzeń: iPhone.

## Wyniki

| Sprawdzenie | Wynik |
| --- | --- |
| Kompilacja aplikacji i targetów testowych | Poprawna |
| Testy logiki | 10/10, bez błędów |
| Testy interfejsu | 2/2, bez błędów |
| Archiwum Release dla generic iOS | `ARCHIVE SUCCEEDED`, bez podpisu |
| Kontrola wyglądu na uruchomionym symulatorze | Widok miesiąca i roku, legenda trzech stanów, podsumowania, jasny i ciemny motyw |

Testy logiki obejmują tydzień od poniedziałku i zmianę czasu, rok przestępny, lokalne klucze dat, brak wpisu i przyszłe dni, przerywanie serii, zapis/edycję/usunięcie z ponownym odczytem, niepoprawne dane wejściowe, zachowanie uszkodzonego pliku, błąd zapisu i izolację danych demo.

Testy UI obejmują przełączanie tygodnia/miesiąca/roku i wejście z roku w miesiąc oraz dodanie spożycia z notatką, ponowne uruchomienie aplikacji i odczyt wpisu, zmianę na dzień bez alkoholu i usunięcie wpisu.

W pierwszym przebiegu test UI wykrył błąd w dynamicznym kolorze podczas prezentowania edytora. Kolory przeniesiono do katalogu zasobów z wariantami jasnym/ciemnym; pełny kolejny przebieg zakończył się powodzeniem.

Xcode wypisał ostrzeżenie o pominięciu ekstrakcji metadanych AppIntents (aplikacja nie używa tego frameworka) i komunikaty diagnostyczne środowiska symulatora. Nie wystąpiły błędy testów ani archiwizacji w końcowym przebiegu.

## Granice sprawdzenia

Nie wykonano podpisanej dystrybucji, testu na fizycznym iPhonie ani testów na iOS 17–26. Xcode Cloud i TestFlight pozostają nieaktywne. Po zakończeniu testów użytkownik zatwierdził podłączenie projektu do publicznego repozytorium `piotrosmola/sober-control`; ta zmiana dotyczy konfiguracji Git i dokumentacji, bez zmian w kodzie aplikacji. Archiwum bez podpisu potwierdza kompilację Release; nie jest pakietem gotowym do instalacji na iPhonie ani do wysłania do TestFlight.

Pełne logi kompilacji i wyniki `.xcresult` zachowano w roboczym katalogu tej rozmowy; nie są częścią repozytorium.
