# LOCI MATLAB — mapa warstwy obliczeniowej

[← LOCI](../README.MD)

Katalog `matlab/` zawiera aktywną warstwę przekształcania kanonicznych rekordów LOCI w serię analityczną, cechy 27D oraz projekcje i metryki trajektorii.

**Stan implementacji:** kanoniczny visualizer standaryzuje macierz 27D i redukuje ją do 3 współrzędnych używanych do analizy i prezentacji trajektorii. Gdy dostępne jest PCA, używane są trzy pierwsze składowe; w przeciwnym razie działa fallback do pierwszych maksymalnie trzech wymiarów. Aktualny kod nie implementuje jeszcze jawnej, semantycznie zdefiniowanej i zwalidowanej mapy `R^27 → R^9`.

## Podkatalogi

- [`adapters/`](adapters/README.md) — ładowanie `sample_norm`, konwersja rekordów na serię i interoperacyjność.
- [`features/`](features/README.md) — budowa i rozwój reprezentacji cech 27D.
- [`visualizers/`](visualizers/README.md) — projekcja, metryki trajektorii i wizualizacja.
- [`compat/`](compat/README.md) — pliki historyczne / kompatybilność wsteczna; nie są osią kanonicznego pipeline’u.

## Kanoniczna ścieżka

```text
sample_norm.json / sample_norm.mat
→ adapters
→ analytical series
→ 27D feature matrix
→ z-score / bezpieczna standaryzacja
→ PCA/fallback → coords3
→ trajectory metrics + visualization
→ results/
```

Nazwa pliku `visualizers/loci_27D_9R_visualizer_canonical.m` zachowuje historyczną nazwę linii badawczej. Dokumentacja powinna jednak opisywać **rzeczywiste obliczenie**, a nie wnioskować z nazwy pliku, że istnieje zaimplementowane mapowanie 9R.

Nie należy dodawać całego poddrzewa MATLAB rekurencyjnie do `path`, jeśli prowadzi to do kolizji nazw pomiędzy warstwą aktywną i kompatybilnościową.
