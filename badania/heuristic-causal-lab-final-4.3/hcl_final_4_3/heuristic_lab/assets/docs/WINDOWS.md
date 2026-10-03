# Windows — uruchomienie bez przebudowy istniejącego repo

1. Rozpakuj `heuristic-causal-lab.zip` do **nowego** katalogu obok starej aplikacji.
2. Otwórz terminal w katalogu zawierającym `heuristic_lab/` i `configs/`.
3. Sprawdź `python --version`. Potrzebny Python 3.11 lub nowszy.
4. `python -m heuristic_lab smoke --output results/selftest_001` działa bez pakietów zewnętrznych i bez modelu. To wyłącznie test oprogramowania.
5. Dla prawdziwego pomiaru uruchom wybrany, już zainstalowany model lokalny jako serwer Ollama lub zgodny z `/v1/chat/completions`.

Nie ma zależności od WSL, Dockera, Outlook COM, GPU ani polityki wykonywania skryptów PowerShell. GPU może skrócić czas modelu, ale nie jest wymogiem kodu. Nie obiecujemy wydajności konkretnego modelu na CPU.

## Ollama

Domyślny adres: `http://127.0.0.1:11434`. `doctor` odczytuje listę modeli. Przy dokładnie jednym modelu `AUTO` wybierze jego faktyczne ID. Przy kilku modelach trzeba użyć `configure --model ID`. Program nie zmieni modelu na inny, kiedy pojawi się błąd.

## Zgodny serwer lokalny

```powershell
python -m heuristic_lab configure --backend openai_compatible --url http://127.0.0.1:8001/v1 --model "FAKTYCZNE_ID" --output configs/local.json
```

Przykładowy port nie jest informacją, że taki serwer już masz. Ten adapter nie jest zależnością od usługi OpenAI. Wymaga `/models`, `/chat/completions`, odpowiedzi tekstowej i obsługi JSON. Część serwerów może wymagać `send_seed: false`; trzeba to ustawić **przed** zamrożeniem projektu i podać jako ograniczenie powtarzalności.

## Gdy pojawia się błąd

`Connection refused`: brak dostępnego serwera, nie zły wynik heurystyki. `AUTO requires exactly one ...`: wybierz jawne ID. HTTP 400 dotyczące parametru modelu: wykonaj diagnostyczny pilot po zmianie konfiguracji; nie zmieniaj parametrów w środku badania potwierdzającego. `CONTEXT_LIMIT`: nie wystarczy miejsca na historię. `TURN_LIMIT`: agent nie domknął zadania w limicie; to normalny nieudany epizod.

Nie uruchamiaj dwóch instancji `run` na tym samym katalogu. Procesy konkurowałyby o te same pliki i zasoby serwera. Wersja 1.0 realizuje sekwencyjny harmonogram.

## Instalacja opcjonalna

Z katalogu projektu można wykonać `python -m pip install .`, ale uruchomienie `python -m heuristic_lab ...` nie wymaga instalacji. Wyłącznie testy potrzebują `python -m pip install -r requirements-dev.txt`.

## Potwierdzone środowisko testów

Patrz BUILD_REPORT.md. Natywne uruchomienie na Windows nie zostało wykonane przez autora paczki w tej sesji. Kod nie używa linuksowych sygnałów, powłoki ani twardo wpisanych ścieżek, ale to nie zastępuje testu na Twoim komputerze.
