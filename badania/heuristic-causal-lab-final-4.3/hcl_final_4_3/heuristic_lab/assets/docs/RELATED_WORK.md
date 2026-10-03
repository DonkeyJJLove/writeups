# Źródła techniczne i związek z metodą

Stan weryfikacji dokumentacji: 2026-10-01. Poniższe źródła opisują interfejsy i pokrewne metody, a nie dowodzą skuteczności heurystyki autora.

- Ollama, native chat API: https://docs.ollama.com/api/chat — żądania `/api/chat`, format, opcje i liczniki odpowiedzi.
- Ollama, OpenAI compatibility: https://docs.ollama.com/api/openai-compatibility — zgodność lokalnego backendu z częścią interfejsu OpenAI.
- llama.cpp server: https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md — serwer oraz zgodny endpoint chat.
- SciPy, `binomtest`: https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.binomtest.html — dokumentacja dokładnego testu dwumianowego. Nasz kod podstawowych obliczeń jest w standardowym Pythonie, nie wymaga SciPy.
- Debenedetti et al., AgentDojo (2024): https://arxiv.org/abs/2406.13352 — przykład środowiska badania agentów wykonujących zadania w obecności niezaufanej treści. Ta aplikacja nie jest reprodukcją AgentDojo i nie używa jego wyników jako danych.

Własne decyzje projektowe: zestaw rodzin, progi praktycznego efektu, tekst aktywnej kontroli, kompilacja źródła, jednostka klastrowania i reguła werdyktu. Każda z nich jest jawnie opisana w kodzie/protokole. Ich wybór wymaga akceptacji przed fazą potwierdzającą. Wynik naszej implementacji nie może być cytowany jako niezależne potwierdzenie samych założeń.
