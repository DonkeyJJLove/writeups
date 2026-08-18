# LOCI Results — generowane artefakty analityczne

[← LOCI](../README.MD)

Katalog `results/` jest warstwą **wyjściową** pipeline’u LOCI. Zawartość powinna być generowana przez narzędzia i testy, a nie ręcznie edytowana jako źródło systemu.

## Główne gałęzie

- `Sample_0001/`, `Sample_0002/`, `Sample_0003/` — wyniki per próbka: raporty, metadane, FIG/PNG/JSON/TXT/MD.
- `_aggregate/` — raporty agregujące wiele próbek.
- `_reports/` — gotowe raporty publikacyjne/statyczne.

## Aktualny raport statyczny

`_reports/static_recursive_report_2026-03-23_174020/` zawiera m.in.:

- `index.html` — statyczny raport przeglądowy,
- `summary.json` — podsumowanie maszynowo czytelne,
- `analysis.txt` — skrót analityczny,
- `assets/` — lokalne kopie wykresów i danych wymaganych przez raport.

## Provenance

```text
sample/
→ parsers / adapters / features / visualizers
→ results/Sample_*
→ _aggregate
→ _reports
```

Kod generujący raporty znajduje się w [`../raports/`](../raports/README.md); walidacja w [`../tests/`](../tests/README.md).
