# Audyt błędów HCL 4.3 i zakres hotfixu

## Materiał

Analiza dotyczy faktycznie rozpakowanego `heuristic-causal-lab-final-4.3.zip` oraz logu użytkownika z 13. żądaniem kończącym się `GPT_OSS_CHANNEL_LEAK`. Nie dysponujemy pełnym raw HTTP z tego konkretnego uruchomienia. Nie rekonstruujemy go z fragmentu `tail` jako kompletnej odpowiedzi.

## Obserwacje z logu

Wśród 10 wierszy `first_turn_*` dziewięć zawiera `tool_name_to_none`; jeden `tool_name_from_name`. Następnie dwa wiersze `post_observation_*` parsują się jako final. Trzynasta generacja kończy się wyciekiem tokenów kanałowych. 12 zapisanych wierszy nie oznacza 12 poprawnych wywołań narzędzi. `finish_reason=stop` nie gwarantuje poprawnego kontraktu interfejsu.

## Wykryte w źródle

- `research_runtime._clone_research_command` dodawał `--no-jinja`, `--chat-template gpt-oss`, `--reasoning-format none`.
- `lion_setup.create_profile` dodatkowo wysyłał `reasoning_format="none"` na poziomie żądania.
- `grading._canonical_json_object` nadawał brakującej nazwie narzędzia wartość `none`, zmieniał błędne decyzje na answer/abstain, obcinał confidence.
- `grading.parse_response_audited` usuwał nieznane klucze z interpretacji, zapisując `ignored_extra_keys`.
- `lion_setup._qualify_transports` nie sprawdzał, czy wybrane narzędzie istnieje i czy otrzymało poprawne argumenty; dla bezpośrednich kontroli sprawdzał jedynie kind.
- Cztery post-observation probes wstawiały to samo fikcyjne value=7, zamiast rzeczywistych danych danej instancji.
- `HTTPProvider.complete` rzucał wyjątek przed zwróceniem ProviderReply. Pełna odpowiedź HTTP była tracona w tym torze; zostawał fragment tekstu błędu.

## Reprodukcja kodu, nie generacja modelu

Na oryginalnym parserze wykonano lokalny test syntetyczny:

```json
{"kind":"tool","request":{"name":"read","args":{"id":"packet"}}}
```

Został zamieniony na `{"kind":"tool","name":"none","args":{}}`. To NIE jest twierdzenie, że użytkownik otrzymał dokładnie ten JSON; jest to kontrprzykład dla deklaracji o bezstratnej normalizacji.

Drugi test syntetyczny: `decision="not_authorized"`, `answer=7`, `confidence=2` stawał się `decision="answer"`, `confidence=1`. Trzeci: `answer=7` wraz z `response=8` nie był odrzucany. Hotfix zawiera regresje dla tych nieprawidłowości.

## Źródła techniczne

Oficjalna dokumentacja llama.cpp określa `reasoning_format=none` jako zwracanie raw generated text, a nie wyłączenie reasoning. Dyskusja z udziałem współtwórcy integracji GPT-OSS zaleca `--jinja` i niewłączanie `--reasoning-format none`, gdy reasoning nie ma trafiać do assistant response.

- https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md
- https://github.com/ggml-org/llama.cpp/discussions/12204
- https://github.com/ggml-org/llama.cpp/discussions/15333

To uzasadnia korektę naszego profilu. NIE dowodzi, że jest ona wystarczająca dla każdej odpowiedzi na buildzie b10809. Nie powielamy wcześniejszego wniosku, że wszystkie problemy GPT-OSS wynikają wyłącznie z jednej flagi.

## Zakres naukowy

Nie uzyskano nowego wyniku skuteczności heurystyki. Text policies, generatory, oracles, narzędzia i grader merytoryczny nie zmieniają się. Parser wejścia do gradera i kwalifikacja zostały poprawione, dlatego wynik nowego runu wymaga nowego hasha kodu i nowego manifestu. 10 240 zaplanowanych prób to plan, nie pomiar. 256 seedów nie oznacza niezależności od wspólnych szablonów i nie ustanawia uniwersalnej jakości heurystyki.
