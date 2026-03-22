# LOCI — analiza przejść w sekwencjach tekstowych Human–AI

> Analiza tekstu jako układu dynamicznego (LOCI, dual-mode, metaprzestrzeń)

---

## O projekcie

Repozytorium zawiera narzędzia do badania iteracyjnie generowanego tekstu w układzie:

> **Human–AI → sekwencja → dynamika → przejście (LOCI)**

Tekst traktowany jest jako trajektoria w przestrzeni cech, a nie tylko jako zapis językowy.

---

## Co robimy

Analizujemy:

- lokalne przejścia strukturalne (**LOCI**)
- dynamikę generacji (slope, curvature)
- tryby pracy:
  - kompresja (redakcja)
  - eksploracja (generacja)
- trajektorię w metaprzestrzeni (**27D / 9R**)
- złożoność strumienia myśli (**TSCI**)

---

## Pipeline

```text
TEXT
→ PARSING
→ FEATURE ENGINEERING
→ LOCI
→ DUAL-MODE
→ METASPACE (27D / 9R)
→ TSCI
→ WERDYKT
````

---

## Modele

### LOCI

Detekcja lokalnego przejścia:

* onset
* max slope
* max curvature

---

### Dual-mode

Balans:

* kompresja ↔ eksploracja

---

### Metaprzestrzeń (Sobol / Hypercube)

Ocena:

* pokrycia
* rozproszenia
* gęstości trajektorii

---

### TSCI

Złożoność strumienia:

* dynamika
* plateau
* zmienność
* przejścia

---

## ▶ Wyniki eksperymentów

Szczegółowe wyniki dla konkretnego sampla:

👉 **[Sample_0001 — raport analizy](results/Sample_0001/Sample_0001.md)**

Zawiera:

* wynik LOCI
* analizę faz (prekursor → przejście)
* dual-mode (kompresja vs eksploracja)
* metaprzestrzeń 27D / 9R
* TSCI
* interpretację poznawczą (Human–AI)

---

## Interpretacja systemowa

Kluczowa obserwacja:

> tekst nie zmienia się liniowo — przechodzi przez lokalne bifurkacje

Schemat:

```text
IMPULS (max slope)
↓
PROPAGACJA
↓
STABILIZACJA
↓
LOCI (onset)
↓
NOWY REŻIM
```

---

## Znaczenie dla Human–AI

Podejście umożliwia:

* wykrywanie momentu reorganizacji myśli
* rozróżnienie eksploracji vs stabilizacji
* analizę jakości procesu generowania
* ograniczanie dryfu i „halucynacyjności”

---

## Struktura repo

```text
sample/
  raw/
  norm/

results/
  Sample_0001.md

*.m (MATLAB)
```

---

## Jak uruchamiać

### LOCI

```matlab
R = loci_sample_text_all_in_one('sample/norm/Sample_0001n.m');
```

### Dual-mode

```matlab
R = loci_dual_mode_model_v2('sample/norm/Sample_0001n.m');
```

### TSCI

```matlab
R = loci_thought_stream_complexity('sample/norm/Sample_0001n.m');
```

### Metaprzestrzeń

```matlab
R = loci_27D_9R_visualizer('sample/norm/Sample_0001n.m');
```

---

## Skala epistemiczna

| Poziom | Znaczenie         |
| ------ | ----------------- |
| P0     | brak sygnału      |
| P1     | słaby             |
| P2     | lokalne przejście |
| P3     | brak dowodu       |
| P4     | silne             |
| P5     | globalne          |

---

## Meta-wniosek

> Tekst generowany iteracyjnie (Human–AI) zachowuje się jak układ dynamiczny,
> w którym przejścia są opóźnione względem impulsów.

---

## Status

* LOCI: ✔
* Dual-mode: ✔
* TSCI: ✔
* Metaprzestrzeń: rozwój

---

**TRYB:** badawczy
**REŻIM:** absolutny

```



