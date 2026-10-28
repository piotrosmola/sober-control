# SoberControl

- Aplikacja iPhone w SwiftUI / Swift 6, minimum iOS 17. Otwieraj `SoberControl.xcodeproj`, scheme `SoberControl`.
- Zachowaj polski interfejs i natywne wzorce iOS. Kolory jasne/ciemne są w Assets.xcassets.
- Brak wpisu to osobny stan, nigdy domyślna trzeźwość. Przyszłe dni nie przyjmują wpisów ani nie wpływają na podsumowania.
- Identyfikuj dni lokalnymi kluczami `YYYY-MM-DD`; przesuwaj dni przy użyciu Calendar, nie interwałów po 86400 sekund.
- Dane użytkownika pozostają w kontenerze aplikacji. Nigdy nie dodawaj dzienników, certyfikatów ani kluczy do Git.
- Demo używa osobnego magazynu w pamięci. Testy UI muszą używać `--ui-testing`, a reset wyłącznie testowego katalogu.
- Po istotnej zmianie logiki lub UI uruchom `./scripts/verify.sh`. Ustaw `SOBERCONTROL_DESTINATION`, jeśli wskazany symulator nie jest dostępny.
- Repozytorium `origin`: https://github.com/piotrosmola/sober-control.git (publiczne). Użytkownik zatwierdził podłączenie repozytorium i wysłanie projektu. Dalsze zmiany rozwijaj na gałęziach i przez PR do `main`; scalanie oraz aktywacja Xcode Cloud i dystrybucji wymagają decyzji użytkownika.
