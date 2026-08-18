# LOCI MATLAB — mapa warstwy obliczeniowej

[← LOCI](../README.MD)

Katalog `matlab/` zawiera aktywną warstwę przekształcania kanonicznych rekordów LOCI w serię analityczną, cechy 27D i wizualizacje 27D→9R.

## Podkatalogi

- [`adapters/`](adapters/README.md) — ładowanie `sample_norm`, konwersja rekordów na serię i interoperacyjność.
- [`features/`](features/README.md) — budowa i rozwój reprezentacji cech.
- [`visualizers/`](visualizers/README.md) — mapowanie, metryki trajektorii i wizualizacja.
- [`compat/`](compat/README.md) — pliki historyczne / kompatybilność wsteczna; nie są osią kanonicznego pipeline’u.

## Kanoniczna ścieżka

```text
sample_norm.json / sample_norm.mat
→ adapters
→ analytical series
→ 27D feature matrix
→ visualizers
→ results/
```

Nie należy dodawać całego poddrzewa MATLAB rekurencyjnie do `path`, jeśli prowadzi to do kolizji nazw pomiędzy warstwą aktywną i kompatybilnościową.
