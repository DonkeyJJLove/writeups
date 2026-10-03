# Oddzielenie starego projektu od nowego badania

Nie nadpisano wcześniejszego ZIP ani katalogu `semantic-mutation-benchmark`. Nie wykonano żadnego commitu w repozytorium `writeups` i nie użyto jego zdalnego połączenia.

Nowy katalog: `heuristic-causal-lab`. Stary raport można zachować jako pilotaż porównania algorytmów, wyraźnie oznaczony jako inny eksperyment. Nie importuj dawnych opisowych JSON-ów Benchmark I/II jako danych z modelu.

W `sources/legacy_exclusion.json` zapisano powód przebudowy i identyfikację sprawdzonej paczki. Nowy eksperyment ma osobny manifest, źródła strategii, klasę modelu, protokół i katalog wyników.

Przed opublikowaniem: usuń z materiałów twierdzenia o nieprzeprowadzonych pomiarach; zachowaj wyłącznie wyniki, które mają odpowiadający transcript, zadanie i ocenę. W raporcie bieżącego narzędzia `HARNESS_SELFTEST_ONLY` nie może zostać przemianowane na skuteczność heurystyki.
