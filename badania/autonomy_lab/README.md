# Eksperyment funkcjonalny scaffoldingu

Pakiet zawiera oryginalny tekst, zamrożony protokół, implementację lokalnego symulatora, pełne prompty i dane wejściowe oraz zarejestrowane przebiegi agentów. Wyniki nie są deklaracjami modelu: scoring odczytuje stan symulatora.

## Pliki

- `source_scaffolding.md`: dokładny badany blok, bez zewnętrznej instrukcji audytowej.
- `protocol.md`, `manifest.json`, `frozen_hashes.json`: reguły, przypisania i sumy kontrolne zamrożone przed uruchomieniem.
- `method_review.md`: podsumowanie niezależnego przeglądu projektu badania.
- `lab.py`, `client.py`: symulator i jego publiczny interfejs; brak dostępu do sieci lub API modelu.
- `fixtures.json`, `prompts/`: stany początkowe i pełne instrukcje badanych agentów.
- `runtime/`: końcowe stany JSON i dzienniki JSONL; w dziennikach zapisano także zdarzenia prywatne, niewidoczne dla wykonawców.
- `results/`: wyniki walidacji aparatury, grading, audyt odtworzenia i podsumowania.
- `audit_results.py`: odtworzenie dzienników i kontrola integralności; napisany po zamrożeniu protokołu, nie zmienia scoringu.

## Ponowne sprawdzenie zapisanych wyników

Wymagany Python 3.10+ na systemie z modułem fcntl, bez dodatkowych zależności. W rozpakowanym katalogu:

```sh
python lab.py grade
python audit_results.py
```

Oba polecenia odczytują zapisane przebiegi; nie uruchamiają modeli. Pierwsze odtwarza ocenę w `results/episode_scores.json`, drugie kontroluje hashe, odpowiedzi, zdarzenia i stany końcowe. Wyniki referencyjne `selfcheck` są testem aparatury, a nie próbami modelu.

Ponowne wykonanie samego eksperymentu wymaga nowych, odrębnych kontekstów agentowych i świeżej kopii środowiska. Pliki promptów zawierają ścieżkę oryginalnego wykonania. Zmiana ścieżki lub modelu oznacza nową konfigurację, którą trzeba osobno zamrozić. Nie uruchamiać `init` w katalogu z zachowanymi wynikami.

## Pochodzenie i ograniczenia

Każdy badany agent otrzymał pustą historię rozmowy (`fork_turns=none`) i odziedziczone ustawienia modelu/platformy. Nie przekazywano mu ocen rodzica, porównań warunków ani klucza scenariuszy. Pełna koperta startowa jest w `results/launch_record.json`.

Izolacja była proceduralna we wspólnym systemie plików. Dziennik umożliwia deterministyczne odtworzenie działań, lecz nie potwierdza braku wszystkich możliwych odczytów poza interfejsem. Mały pilot w jednej dziedzinie nie rozstrzyga uniwersalnej autonomii ani wewnętrznego mechanizmu modelu.
