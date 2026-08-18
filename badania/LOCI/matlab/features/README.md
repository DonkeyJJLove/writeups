# LOCI MATLAB Features — reprezentacja cech

[← MATLAB](../README.md) · [← LOCI](../../README.MD)

Warstwa `features/` przechowuje logikę budowy reprezentacji cech LOCI.

## Zawartość

- `build_loci_feature_matrix.m` — implementacja budowy macierzy 27D znajdująca się w warstwie cech.

W repo istnieje także wariant funkcji w `matlab/adapters/`; dlatego przy uruchamianiu kodu należy stosować ścieżki wskazane przez kanoniczny pipeline i unikać przypadkowego shadowingu funkcji.

## Relacja

```text
records / series
→ feature representation 27D
→ visualizers
```

Kontrakty danych: [`../../spec/README.md`](../../spec/README.md).
