# Symulacja_GITHUB — sandbox amplifikacji workloadu agentowego

[← Badania](../README.md) · [← Główny katalog](../../README.MD)

`badania/Symulacja_GITHUB/` zawiera izolowane badanie symulacyjne klasy architektur, w których wiele agentów generuje intencje przechodzące przez gateway, wspólną warstwę auth/token i współdzielony backend. Celem jest zbadanie, kiedy retry, fan-out, concurrency, degradacja usług i współdzielone zależności mogą wytwarzać **wtórną pracę infrastrukturalną** oraz dodatnie sprzężenie zwrotne przy stałej liczbie pierwotnych intencji.

To jest **sandbox modelowy, nie rekonstrukcja produkcyjnego GitHuba 1:1**. Wyniki pokazują techniczną możliwość i zależności przyczynowe wewnątrz przyjętego modelu; nie ustanawiają przyczyny awarii GitHuba z 17 sierpnia 2026 bez niezależnych danych produkcyjnych.

## Zawartość

```text
Symulacja_GITHUB/
├── README.md                              ← ten indeks
├── article.md                             ← artykuł syntetyczny
├── agentic_amplification_report.md        ← raport eksperymentu i 20 hipotez
├── agentic_amplification_hypotheses_20.csv← hipotezy / statusy / wyniki
└── sandbox_agentic_amplification_mc.py    ← źródło modelu Monte Carlo
```

## Zalecana kolejność czytania

1. [`article.md`](article.md) — narracyjna interpretacja mechanizmu amplifikacji i jego znaczenia architektonicznego.
2. [`agentic_amplification_report.md`](agentic_amplification_report.md) — zakres eksperymentu, parametry, wyniki, test 20 hipotez i granica ważności.
3. [`agentic_amplification_hypotheses_20.csv`](agentic_amplification_hypotheses_20.csv) — kompaktowy artefakt wynikowy hipotez.
4. [`sandbox_agentic_amplification_mc.py`](sandbox_agentic_amplification_mc.py) — implementacja modelu do audytu założeń i dalszej reprodukcji.

## Kontrakt epistemiczny

Badanie rozdziela trzy poziomy, których nie wolno utożsamiać:

```text
wynik symulacji
≠ częstość empiryczna w produkcji
≠ dowód przyczyny konkretnej awarii
```

W badaniu wykonano 100 000 realizacji Monte Carlo po 1 000 pierwotnych intencji, co reprezentuje 100 000 000 instancji agent-intent wewnątrz modelu. Taka skala ogranicza sampling noise dla zadanej konstrukcji eksperymentalnej, ale nie usuwa model risk, błędu kalibracji ani braku telemetrii z systemu produkcyjnego.

Raport traktuje jako sygnał architektoniczny kombinację amplifikacji workloadu i niestabilności kolejki. Wyniki wspierają tezę klasową: retry i fan-out przy spadającym marginesie pojemności mogą tworzyć wtórną pracę, natomiast mechanizmy takie jak retry budget, backoff/jitter i circuit breaker redukują ten efekt przy określonych trade-offach.

## Relacja do reszty repozytorium

- [`../LOCI/README.MD`](../LOCI/README.MD) — analiza trajektorii i reprezentacja obserwowalnych artefaktów Human–AI.
- [`../../ai_security_model_boundary_strategy_writeup.md`](../../ai_security_model_boundary_strategy_writeup.md) — execution-path security, consequentiality i kontrola skutku.
- [`../../PROCESS_GUARD.md`](../../PROCESS_GUARD.md) — reguły utrzymania procesu badawczego, provenance i statusów epistemicznych.

---

**Status:** badanie symulacyjne / model klasowy. Każde twierdzenie o realnym incydencie wymaga niezależnego źródła empirycznego poza tym sandboxem.
