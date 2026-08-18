# LOCI MATLAB Visualizers — projekcja trajektorii i raportowanie

[← MATLAB](../README.md) · [← LOCI](../../README.MD)

Warstwa `visualizers/` odpowiada za interpretację przygotowanej reprezentacji 27D, redukcję wymiarowości na potrzeby analizy trajektorii, obliczanie metryk oraz zapis artefaktów wynikowych.

## Pliki

- `loci_27D_9R_visualizer_canonical.m` — kanoniczny visualizer aktywnego pipeline’u.
- `loci_27D_9R_visualizer.m` — wcześniejszy / alternatywny visualizer; przed użyciem sprawdź status względem wersji kanonicznej.
- `build_metaspace_map.m` — pomocnicza budowa mapy metaspace; jej obecność nie ustanawia sama w sobie kanonicznej mapy 9R.

## Co wykonuje wersja kanoniczna

Aktualny przepływ obliczeniowy jest następujący:

```text
27D feature matrix X
→ bezpieczna standaryzacja z-score
→ PCA, jeśli dostępne
→ trzy pierwsze składowe jako coords3
→ fallback do maks. 3 pierwszych wymiarów, gdy PCA nie jest dostępne
→ metryki trajektorii
→ PNG / FIG / TXT / JSON / MD
```

Visualizer oblicza m.in. długość trajektorii, kroki pomiędzy kolejnymi punktami, przybliżony onset oraz dystanse nearest-neighbor. Trójwymiarowe współrzędne służą analizie i wizualizacji obserwowalnych artefaktów.

## Granica 9R

Historyczna nazwa `loci_27D_9R_visualizer_canonical.m` oraz linia badawcza 27D/9R **nie oznaczają**, że bieżący kod realizuje zwalidowane mapowanie:

```text
R_9 : R^27 → R^9
```

Taka implementacja wymagałaby jawnie zdefiniowanych dziewięciu osi, funkcji transformacji, procedury kalibracji/identyfikacji, testów stabilności i walidacji na danych niezależnych. Do czasu spełnienia tych warunków bieżący output należy nazywać **projekcją 3D / reprezentacją trajektorii**, a nie formalnym wynikiem 9R.

## Wyjście

Typowe artefakty trafiają do [`../../results/`](../../results/README.md) i mogą obejmować PNG, FIG, TXT, JSON i MD.

```text
27D feature matrix
→ 3D trajectory projection
→ dynamics / density / onset metrics
→ report artifacts
```
