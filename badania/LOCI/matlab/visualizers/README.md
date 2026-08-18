# LOCI MATLAB Visualizers — 27D → 9R i raportowanie

[← MATLAB](../README.md) · [← LOCI](../../README.MD)

Warstwa `visualizers/` odpowiada za interpretację przygotowanej reprezentacji, metryki trajektorii, mapowanie przestrzeni i zapis artefaktów wynikowych.

## Pliki

- `loci_27D_9R_visualizer_canonical.m` — kanoniczny visualizer aktywnego pipeline’u.
- `loci_27D_9R_visualizer.m` — wcześniejszy / alternatywny visualizer; przed użyciem sprawdź status względem wersji kanonicznej.
- `build_metaspace_map.m` — budowa mapy metaspace.

## Wyjście

Typowe artefakty trafiają do [`../../results/`](../../results/README.md) i mogą obejmować PNG, FIG, TXT, JSON i MD.

```text
27D feature matrix
→ trajectory / metaspace analysis
→ 9R / 3D representation
→ report artifacts
```
