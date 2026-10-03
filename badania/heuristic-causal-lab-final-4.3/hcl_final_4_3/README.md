# HCL 4.3.3 — pełne badanie z poprawnym rozliczaniem limitu generacji

## Uruchomienie

Rozpakuj do NOWEGO katalogu `hcl_4_3_output_budget_fix`. Nie nadpisuj wcześniejszej
wersji, nie kopiuj STUDY_STATE.json ani manifestów przerwanego runu.

W cmd.exe:

```cmd
RUN_STUDY.cmd
```

W PowerShell:

```powershell
.\RUN_STUDY.cmd
```

Launcher ustawia katalog i prowadzi preflight, nowy seal, 10 240 prób, audyt i
raport. Nie dodano pilota. Postęp odczytuje `STUDY_STATUS.cmd`.

## Co zmienia się w tym wydaniu

Dotychczas odpowiedź HTTP 200, która zużyła 768 tokenów i nie zwróciła akcji,
była awarią całego badania i dostawała nieprawdziwe usage=0. Teraz taka odpowiedź
bez wycieku znaczników kończy konkretny epizod jako:

```
status=GENERATION_LIMIT completion_tokens=768 retained=1 retry=0
```

Wynik pozostaje niepowodzeniem, wchodzi do mianownika i nie jest ponawiany.
Pełny surowy HTTP jest zachowany. Nie pobieramy akcji z reasoning_content.
Kompletna akcja na granicy limitu musi przejść zwykły parser i grader.

Raport pokazuje output_budget_exhausted osobno, a replay sprawdza usage.
Nie zmieniono parametrów żądania 768/769, tekstu autora, kontroli, zadań,
parsera akcji, narzędzi, gradera ani sterowania serwerami.

## Nowy manifest, nie poprawianie starego wyniku

Nowy profil używa bloków 30000–30255 zamiast 20000–20255. To jawna zmiana seeda
po rozpoznaniu błędu instrumentu; próby z starego runu nie są włączane.
Nie wznawiaj starego manifestu nowym kodem. Normalne przerwanie NOWEGO badania
można wznowić RUN_STUDY.cmd bez zmiany konfiguracji; ukończone niepowodzenia
GENERATION_LIMIT również są pomijane przy wznowieniu, nie powtarzane.

## Granice poprawki

To naprawa rozliczania obserwowanych porażek, nie zwiększenie inteligencji.
Model nadal może nie wykonać zadania. Nie zwiększono czasu, tur ani tokenów.
Pozostały 16 kontroli kwalifikacji oraz konserwatywne blokady poważnych problemów
kanałowych i niepoprawnego HTTP/JSON niezwiązanego z limitem. Ten patch nie
obiecuje, że żadne inne nieprzetestowane zachowanie backendu już nie wystąpi.

Kontrola strong_control zawiera obszerne powtarzane wypełnienie długości; nie
zostało po cichu usunięte. Badanie porównuje dokładnie oba zamrożone pakiety,
nie wyizolowaną „czystą semantykę”. Szczegóły FULL_STUDY_PROTOCOL.md.

## LION

8772 nie jest restartowany ani rekonfigurowany przez tę poprawkę; kod runtime
pozostał identyczny. Research korzysta z 8773 i wspólnej karty graficznej.
Izolacja portów nie gwarantuje braku wpływu na produkcyjne opóźnienia.
Nie uruchamiaj równolegle innej wersji HCL, nie zabijaj procesów po starym PID,
nie zmieniaj aktywnego supervisora LION.

## Weryfikacja bez modelu

```cmd
python -m pytest -q
python -m heuristic_lab smoke --output results/my_selftest
```

Smoke korzysta z jawnych atrap; nie jest badaniem heurystyki. Testy regresyjne
z odpowiedzią użytkownika są odtwarzaniem offline, nie nową inferencją.
Dokładne wyniki testów znajdują się w BUILD_REPORT.md i evidence/.
