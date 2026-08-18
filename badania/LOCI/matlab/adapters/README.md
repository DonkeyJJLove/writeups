# LOCI MATLAB Adapters — kontrakt wejścia do analizy

[← MATLAB](../README.md) · [← LOCI](../../README.MD)

Adaptery stanowią kanoniczny most pomiędzy rekordowym `sample_norm` a reprezentacją używaną przez warstwę analityczną MATLAB.

## Pliki

- `load_sample_norm.m` — ładowanie kanonicznego JSON/MAT.
- `sample_norm_to_series.m` — konwersja rekordów do serii analitycznej `T`.
- `build_loci_feature_matrix.m` — budowa macierzy cech 27D dla aktywnego pipeline’u.
- `export_sample_norm_mat.m` — eksport interoperacyjny do MAT.
- `sample_to_27d_input.m` — adapter pomocniczy do reprezentacji 27D.

## Kontrakt

```text
sample_norm
→ load
→ series T
→ feature matrix X[n×27]
→ visualizer
```

Warstwa nie powinna zgadywać semantyki surowego wejścia; kontrakty rekordów opisuje [`../../spec/`](../../spec/README.md).
