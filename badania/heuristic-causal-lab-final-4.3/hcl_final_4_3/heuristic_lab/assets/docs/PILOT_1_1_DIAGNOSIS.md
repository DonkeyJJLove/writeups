# Pilot 1.1 — diagnoza przyczyny nieudanego pomiaru

Historyczny pilot na `gpt-oss-20b-MXFP4`, research endpoint 8773, wykazał problem instrumentu, nie rozstrzygnięcie jakości heurystyki.

Dane diagnostyczne użytkownika:

- 40/40 epizodów miało co najmniej jeden błąd parsera,
- `author_raw`: 111 błędów parsera, 18/20 brak finalnej odpowiedzi, 18/20 TURN_LIMIT, 50 końców `length`,
- `strong_control`: 88 błędów parsera, 13/20 brak finalnej odpowiedzi, 13/20 TURN_LIMIT, 25 końców `length`,
- tool calls: 1 w `author_raw`, 0 w `strong_control`,
- provider errors: 0,
- integralność artefaktów: PASS.

Wniosek: wynik `safe_success=0` był zdominowany przez walkę z kontraktem tekstowego JSON i limitami, więc nie identyfikował efektu heurystyki.

Wersja 2.0 usuwa tę ścieżkę zakłócenia przez:

1. schema-constrained decoding,
2. obowiązkowy neutralny probe exact schema + exact study action schema,
3. natychmiastowe `PROTOCOL_ERROR` zamiast konsumowania semantycznych tur na naprawy formatu,
4. osobne metryki `protocol_success`, `task_success`, `epistemic_success`, `correct_termination`, `failure_to_stop`,
5. arm-blind qualification gate przed confirmatory.

Historycznych wyników nie przeliczamy nowymi regułami i nie używamy ich jako wyników wersji 2.0.
