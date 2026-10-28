# Workflow Codex → PR → build → test na iPhonie

Stan na 28 października 2026: użytkownik wskazał publiczne repozytorium [piotrosmola/sober-control](https://github.com/piotrosmola/sober-control). Lokalny projekt ma połączenie `origin` z tym repozytorium i gałąź `main`. Nie ma jeszcze PR, aktywnego workflow Xcode Cloud ani buildu TestFlight.
W Xcode Cloud otworzyło się okno logowania do Apple Account. Zapisane lokalnie ustawienia wskazują wyłącznie Personal Team.

## Elementy przygotowane

- Zwykły projekt Xcode obecny w repozytorium; brak generatora wymaganego przy budowaniu.
- Udostępniony schemat `SoberControl` z build, test, analyze i archive oraz targetami unit/UI tests.
- Automatyczne podpisywanie, jawny bundle ID `com.piotrosmola.SoberControl`, wersja `0.1.0`, build `1`.
- Ikona AppIcon 1024 × 1024; brak bibliotek zewnętrznych i sekretów wymaganych do kompilacji.
- `scripts/verify.sh` i `.github/pull_request_template.md`.
- `.gitignore` wyklucza dane dziennika, pliki kont użytkownika Xcode, klucze i produkty kompilacji.

## Aktywacja po decyzji użytkownika

1. Repozytorium docelowe to publiczne `piotrosmola/sober-control`; `origin` wskazuje `https://github.com/piotrosmola/sober-control.git`. Nie dodawać rzeczywistych wpisów dziennika do repo.
2. Dla każdego zadania Codex tworzy gałąź, wprowadza zmianę, uruchamia `scripts/verify.sh`, zapisuje commit i otwiera PR do `main`. Przejrzeć zmianę przed scaleniem.
3. Zalogować istniejące Apple Account w **Xcode → Settings → Accounts**. Wymagane jest członkostwo Apple Developer Program i uprawnienia do App Store Connect. Personal Team nie wystarcza do Xcode Cloud i TestFlight.
4. Wybrać właściwy płatny zespół w **Signing & Capabilities**. Jeśli różni się od obecnego, uaktualnić `DEVELOPMENT_TEAM` dla targetów. Potwierdzić docelowy bundle ID przed jego rejestracją.
5. W **Report navigator → Cloud → Get Started** wybrać SoberControl. Połączyć wyłącznie wskazane repozytorium GitHub z Xcode Cloud. Nadanie nowego dostępu aplikacji GitHub i ewentualne warunki usługi wymagają udziału użytkownika.
6. Utworzyć workflow **PR – build and test**: start dla PR do `main`, scheme SoberControl, Build + Analyze + Test na dostępnym iPhonie w symulatorze, oba targety testowe. Bez dystrybucji z gałęzi PR.
7. Utworzyć rekord aplikacji w App Store Connect po potwierdzeniu danych przez użytkownika. Utworzyć workflow **Main – TestFlight**: zmiany `main`, Test i Archive do dystrybucji iOS. Dodać postakcję TestFlight dla zatwierdzonej grupy testerów wewnętrznych.
8. Dopiero po pierwszym poprawnym buildzie ustawić jego rzeczywisty status jako wymagany w ochronie gałęzi na GitHub. Nie zgadywać nazwy checka.
9. Otworzyć otrzymany build w TestFlight na iPhonie. Sprawdzić: tydzień/miesiąc/rok, wszystkie stany, zapis po zamknięciu aplikacji, edycję, usunięcie i zmianę daty. Nie włączać publicznego linku ani publikacji w App Store bez osobnej decyzji.

Konfiguracje workflow Xcode Cloud zapisuje w usłudze Apple; plik Markdown w repozytorium nie aktywuje ich automatycznie. Nie dodano zastępczego workflow GitHub Actions ani płatnej usługi budowania.
W razie wyboru Apple-owego numerowania buildów w Xcode Cloud należy zweryfikować unikalny numer pierwszego archiwum przed kolejnymi wysyłkami.

## Oficjalne źródła Apple

- [Wymagania projektu i konta Xcode Cloud](https://developer.apple.com/documentation/xcode/setting-up-your-project-to-use-xcode-cloud)
- [Pierwszy workflow Xcode Cloud](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow)
- [Dystrybucja z Xcode Cloud przez TestFlight](https://developer.apple.com/documentation/xcode/distributing-your-xcode-cloud-builds-through-testflight)
