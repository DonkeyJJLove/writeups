# HCL — analiza rzeczywistej awarii runtime 7874acc6

## Podstawa i zakres

Odczyt offline `HCL_RUNTIME_FAILURE_7874acc6.zip`. Nie wykonano nowej inferencji.
Archwium zawiera 16 udanych żądań kwalifikacyjnych oraz jedno żądanie rozpoczętego
porównania: pierwsze w harmonogramie, `strong_control`, rodzina `lineage`, blok
20000, wariant 0, model_seed 9897863. Nie zawiera zakończonych plików w `study/trials`.
Nie ma odpowiedzi `author_raw` z tego porównania.

Dokładne ścieżki i sumy zapisano w `HCL_RUNTIME_7874_ANALYSIS.json`.

## Kontrola integralności

- 17 par HTTP: 34/34 sumy żądań i odpowiedzi zgodne z receiptami.
- 10 245/10 245 plików zadeklarowanych w manifeście: zgodne sumy.
- Hash manifestu, rejestracji i rekordu przerwanego epizodu: zgodne.
- 41/41 plików źródłowych/polityk w `source_manifest.json`: zgodne z rozpakowaną
  dostarczoną paczką `hcl-4.3-budget-fix.zip`.
- Wiadomości rzeczywistego HTTP są identyczne z `initial_messages` epizodu;
  pierwszy assignment jest identyczny z pierwszym assignmentem harmonogramu.

To potwierdza spójność przekazanych artefaktów, nie niezależną certyfikację
historycznego wykonania lub autentyczności procesu na komputerze użytkownika.

## Rzeczywista odpowiedź 17. żądania

Źródło: `transport_http/20261002T093249509540Z_d4e1681a52a0/response.raw`.

| Pole | Odczyt |
|---|---|
| HTTP | 200 |
| request.max_tokens | 768 |
| request.reasoning_budget_tokens | 769 |
| finish_reason | length |
| message.content | pusty string |
| message.reasoning_content | 3084 znaki |
| usage.prompt_tokens | 3636 |
| usage.completion_tokens | 768 |
| usage.total_tokens | 4404 |
| context z zamrożonych metadanych | 8192 |
| Znaczniki `<\|start\|>`, `<\|channel\|>`, `<\|message\|>`, `<\|end\|>` | brak w content i reasoning_content |
| native tool_calls | brak |
| response_truncated w receipcie | false |

To nie jest obserwowany wcześniej cykl pustych bloków kanałowych. Zapis wskazuje,
że model zużył dostępny limit, nie zwracając akcji w przewidzianym polu `content`.
Limit wejście+wyjście nie przekroczył raportowanego okna kontekstu. Nie ma tu
udokumentowanej odmowy połączenia ani wyjątku HTTP.

W `reasoning_content` występuje zapis zamiaru `read(packet)`, po którym model
dalej rozważa brak dokumentu i nieznane dowody. HCL nie otrzymało wyemitowanego
wywołania ani obserwacji narzędzia. Zamiaru w analizie nie wolno konwertować na
wykonaną akcję, odpowiedź albo źródło dowodu. Nie cytujemy całości analizy jako
uzasadnienia wyniku zadania.

## Błędy HCL odtworzone z kodu

`providers.py` w odczytanej wersji rzuca `STRUCTURED_TRANSPORT_LENGTH` zanim zwróci
`ProviderReply`. `engine.py` otrzymuje więc tylko wyjątek zamiast tekstu i usage.
W efekcie rekord epizodu ma:

```
failure = PROVIDER_ERROR
usage.prompt_tokens = 0
usage.completion_tokens = 0
usage.reported_usage_complete = true
score.protocol_success = true
score.generation_limit = false
```

Surowy HTTP zaprzecza temu zapisowi zużycia. W następnym kroku `execute_study`
przeklasyfikowuje to w `INVALID_INSTRUMENT`, przerywając cały harmonogram.

Normalny wynik wyczerpania zadanego limitu, bez wyemitowanej akcji, jest możliwym
niepowodzeniem badanego modelu pod danym tekstem sterującym. Nie należy usuwać go
z próby ani ponawiać aż do sukcesu. Jego wystąpienie samo w sobie nie dowodzi,
że interfejs lub cały instrument jest uszkodzony.

Nie ustalono z tego jednego zapisu, dlaczego model nie przekazał sterowania.
Nie dowodzi on ani wyłącznej winy instrukcji, ani błędu backendu, ani wpływu
wypełnienia tekstu. Nie ma podstaw do estymacji efektu autor-minus-kontrola.

## Dodatkowy problem zakresu porównania

`study/policies/strong_control.txt` ma 9124 znaki. Właściwa instrukcja, po usunięciu
końcowych białych znaków przed markerem wypełnienia, ma 676 znaków. Po markerze
`[Neutralne wypełnienie długości]` znajduje się 8414 znaków, czyli 92,22% tekstu.
Zdanie zaczynające się od `Materiały pomocnicze laboratorium.` występuje 43 razy.

Natomiast kwalifikacja korzystała z odrębnej, zróżnicowanej shadow-policy.
`first_turn_lineage` w kwalifikacji miało 2639 tokenów wejścia, rzeczywista próba
3636. Różnią się też seed, dokładne zadanie i dopisana instrukcja kwalifikacyjna;
nie jest to kontrolowane porównanie wpływu samego paddingu.

Wypełnienie jest częścią badanego pakietu. Nie jest dowiedzione, że spowodowało
awarię, ale nie powinno być ukrywane pod określeniem „czysta jakość heurystyki”.
Dostarczona poprawka nie usuwa go po obejrzeniu niepowodzenia kontroli. Osobny
kompaktowy wariant kontroli wymaga odrębnego, prospektywnego kontrastu.

## Poprawka sposobu rozliczania wyniku — 4.3.3

- Odpowiedź HTTP zakończona `length`/`limit` bez wycieku znaczników jest zwracana
  do engine z niezmienionym content, usage i metadanymi.
- Jeśli nie ma kompletnej, poprawnej akcji w content, kończy epizod jako
  `GENERATION_LIMIT`, safe_success=false. Zużycie jest zapisane. Nie ma retry.
- Kompletny obiekt akcji przy granicy limitu przechodzi ten sam parser i grader;
  flaga osiągnięcia limitu nie jest ukrywana. Nie dopisuje się brakujących znaków.
- reasoning_content nie dostarcza akcji; metadane zachowują rozmiar i hash, pełna
  analiza pozostaje w response.raw.
- Audyt odtwarzania weryfikuje sumowanie usage i klasyfikację terminalnego błędu.
- Awaria sieci bez dostępnych liczników nie daje fałszywego zera zużycia.
- Nie zmieniono limitu 768, nadpisania 769, heurystyk, parsera akcji, generatorów,
  narzędzi, funkcji poprawności ani mechanizmu start/stop LION.
- Bramka neutralnej kwalifikacji nadal odrzuca limit; istniejące zabezpieczenia
  wycieku znaczników i błędów niezwiązanych z limitem nie zostały zniesione.
- Nowy pełny harmonogram ma bloki 30000–30255, poza wcześniejszym 20000–20255.
  Zmiana została jawnie wpisana do protokołu. Liczebność pozostaje 10 240.

To poprawka księgowania porażek, nie podniesienie możliwości modelu. Nadal może
on zawieść na wszystkich zadaniach. Taki wynik nie powinien być przerabiany w
sukces ani wykluczany dlatego, że nie jest korzystny dla hipotezy.

## Status historycznego runu

Oryginalne archiwum pozostało niezmienione. Jego manifest i scoring nie są
poprawiane w miejscu. Odtworzenie offline jest testem poprawki programu, a nie
nową próbą modelu ani podstawą do ogłoszenia wyniku badania.

## Pomocnicze źródło techniczne

Definicje pól budżetu wyjścia i analizy: oficjalny kod llama.cpp,
`tools/server/server-schema.cpp`:
https://github.com/ggml-org/llama.cpp/blob/master/tools/server/server-schema.cpp

Wniosek o tym konkretnym zdarzeniu pochodzi przede wszystkim z załączonych
request.json, response.raw i rekordu epizodu, nie z zachowania aktualnej gałęzi
master lub domniemanej wersji serwera.
