# Jak rozumieć wynik, nie nadinterpretując go

## Co jest wynikiem programu

`HARNESS_SELFTEST_ONLY`: poprawność narzędzi, parsowania, oceniania i audytu sprawdzono na skryptach znających klucz. Nie ma tu wyniku jakości heurystyki. `NOT_RUN`: brak danych modelu. `PILOT_ONLY`: rzeczywiste dane, ale przeznaczone do diagnostyki. `INCOMPLETE_RUN` albo `INVALID_EXPERIMENT`: brak pełnego dopuszczalnego eksperymentu.

## Co jest wynikiem operacyjnej hipotezy

- `SUPPORTED_IN_SCOPE`: wszystkie wcześniej ustalone warunki korzyści, bezpieczeństwa i użyteczności zostały spełnione przez oszacowania w danym modelu i dystrybucji.
- `PRACTICAL_EFFECT_REJECTED_IN_SCOPE`: przedział wyklucza przynajmniej tak dużą korzyść, jaką zadeklarowano. Nie jest to dowód dokładnie zerowego efektu ani braku wartości heurystyki gdziekolwiek.
- `CONTRADICTED_SAFETY_OR_UTILITY_IN_SCOPE`: oszacowanie wskazuje koszt niezgodny z deklarowanym bezpiecznym i użytecznym działaniem.
- `INCONCLUSIVE` / `INSUFFICIENT_PRECISION`: dane nie rozdzielają progów. To wynik dopuszczalny, którego nie wolno przestawiać na „udowodniono” albo „obalono”.

## Przykłady interpretacji bez wymyślonych liczb

Jeżeli kompilacja pomaga, a źródło literalne nie: jest wsparcie dla tej interpretacji operacyjnej, nie dowód, że każdy model sam poprawnie wydobędzie ją z narracji. Jeżeli oba przegrywają z mocną kontrolą: hipoteza przewagi w tym środowisku jest osłabiona; należy sprawdzić przedział, a nie samą średnią. Jeżeli spada liczba ryzykownych działań, ale model odmawia wszystkim: nie przechodzi warunku użyteczności. Jeżeli oba mają 100%: to może być pułap zadania, nie dowód równoważności wszystkich strategii.

Wyniku nie można wyjaśniać nowym sol­verem dostępnym tylko w jednym ramieniu, ponieważ portfolio jest wspólne. Nadal pozostają inne ograniczenia: dobór rodzin przez projektanta, jeden model/checkpoint, syntetyczna semantyka, tokenizacja, interfejs JSON, zakres generatorów oraz przybliżenia statystyki.

## Nie używamy starych procentów

Historyczne wartości „35/36”, „94,4%”, „85/85” nie są obserwacjami tej aplikacji. Nie zasilają etykiet, oczekiwanych wyników ani raportów. Ich nieuzasadnione przedstawianie w rozmowie nie może zostać naprawione przez wpisanie ich do nowego JSON-a.

## Kolejny niezależny krok

Po zaakceptowanym protokole i pilocie można przeprowadzić badanie na nowych ziarnach, a później niezależnie przygotowanych rodzinach i co najmniej jednym innym modelu. Nie wystarczy wielokrotnie powielać tej samej instancji, by zwiększyć pewność. Nie ma obietnicy, że każde poprawne badanie zakończy się rozstrzygnięciem.
