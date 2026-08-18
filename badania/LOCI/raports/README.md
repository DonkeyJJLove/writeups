# LOCI Reports — generowanie raportów rekurencyjnych

[← LOCI](../README.MD)

Katalog historycznie nazwany `raports/` zawiera kod odpowiedzialny za budowę statycznych raportów na podstawie **już obliczonych artefaktów LOCI**.

## Pliki

- `generate_recursive_loci_report.py` — generator raportu rekurencyjnego dla korpusu wyników.
- `sample_years.json` — opcjonalne mapowanie próbek na lata używane w interpretacji przekrojowej.

## Model publikacji

```text
results/Sample_*
+ results/_aggregate
→ generate_recursive_loci_report.py
→ results/_reports/<timestamp>/
```

Generator nie powinien wykonywać ukrytej ponownej analizy surowych danych; jego rolą jest deterministyczne złożenie istniejących wyników w warstwę prezentacyjną.
