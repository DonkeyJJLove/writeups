# Wynik reprodukcji i poprawka budżetu HCL

## Materiał

Źródło: przesłany diagnostic_result.zip. Analiza jest odczytem offline; nie wykonano
nowej inferencji. Zweryfikowano 5 hashy request.json i 5 response.raw. Oryginalne
żądanie A jest identyczne bajtowo z wcześniejszym transport_failure.zip. Request A
i powtórzony request A są identyczne; identyczna jest także treść message.content
odpowiedzi, choć identyfikatory i czas w pełnej odpowiedzi HTTP są różne.

## Wyniki

| Wariant | Zmiana | Tokeny generacji | Zakończenie | Poprawne read(packet) |
|---|---|---:|---|---|
| A | brak | 768 | length | nie, 64 puste bloki analysis |
| B | tylko reasoning_budget_tokens=769 | 55 | stop | tak |
| D | 769 i bez response_format | 55 | stop | tak |
| C | tylko bez response_format | 23 | stop | nie, znaczniki kanałów w content |
| A powtórzone | brak | 768 | length | nie, identyczna pętla |

W każdym wariancie: ten sam tekst messages, seed 980000, temperatura 0.2,
max_tokens=768, 2632 tokeny promptu raportowane przez serwer, cached_tokens=0,
fingerprint b10809-5266f24da. W argv procesu badawczego widnieje reasoning-budget 0.
Oba udane warianty zawierają oddzielne reasoning_content i czystą akcję w content.

## Wniosek

Dodanie jednego pola usunęło obserwowany błąd na tej instancji. Powrót do
oryginalnego requestu odtworzył identyczny błąd. Usunięcie wyłącznie JSON mode
przerwało długą pętlę, ale nie przywróciło prawidłowego kontraktu HCL.
To kontrolowana, lokalna przesłanka przyczynowa za zmianą licznika wymuszającego
koniec analysis, nie dowód uniwersalnej naprawy backendu ani jakości heurystyki.

To nadal jedna instancja i jeden seed; kolejność była ustalona, nie losowana.
Wynik nie uzasadnia p-value, ogólnego success rate ani szacowania czasu pełnego
badania. Taki sam PID i CreationDate produkcji przed/po oraz brak generacji
na 8772 wspierają deklarację braku bezpośredniej ingerencji, ale nie dowodzą
braku wpływu na współdzielone zasoby lub opóźnienia.

## Interwencja w nowej paczce

Zastosowano B, nie D: pozostaje json_object, a każde żądanie otrzymuje
reasoning_budget_tokens=max_tokens+1. Limit całej generacji nadal wynosi 768.
Wartość 769 nie jest dodatkowym przydziałem tokenów. Reguła, kod i profil są
zamrażane przed nowym porównaniem author_raw/strong_control. Nie zmienia się
tekstów, narzędzi, zadania, gradera ani liczebności 256 bloków / 10240 epizodów.

Nie można rzetelnie nazywać tego profilem bez rozumowania: dane B/D pokazują
reasoning_content mimo off/none. Zmienia się kontrola generacji stosowana jednakowo
w obu ramionach. Analiza ma pozostać poza ocenianą odpowiedzią i być objęta wspólnym
licznikiem completion_tokens.

Kod referencyjny wcześniej odczytany dla ref 5266f24da: tools/server/server-common.cpp
przekazuje jawny reasoning_budget_tokens, a -1 zastępuje ustawieniem serwera;
common/reasoning-budget.cpp wymusza zakończenie po wyczerpaniu tego licznika.
Główna przesłanka tej poprawki pochodzi jednak z przesłanego eksperymentu A/B/D/C/A.

## Co wykonano lokalnie, a czego nie

Regresje odtwarzają prawdziwe odpowiedzi A/B/C/A i porównują budowany przez nowy
provider request do dokładnego B. Nie uruchomiono nowego pełnego badania ani
16 kontroli na rzeczywistym modelu. Badanie uruchamia RUN_STUDY.cmd po przejściu
bramki technicznej; brak przejścia bramki nie jest zamieniany na sukces.
