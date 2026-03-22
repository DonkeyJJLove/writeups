# LOCI — pipeline kanoniczny

## Status
Ten katalog zawiera **kanoniczny pipeline LOCI** dla przetwarzania, normalizacji, ekstrakcji cech 27D oraz wizualizacji 27D → 9R.

---

## Kanoniczny przepływ danych

```text
sandbox.txt
-> parser Python
-> sample_norm.json
-> adapter MATLAB
-> seria analityczna
-> macierz cech 27D
-> wizualizacja 27D -> 9R
-> results/
````

---

## Zasada główna

`sample_norm.json` **nie jest** bezpośrednią macierzą do wizualizacji.
Jest to **kanoniczny znormalizowany zapis rekordów wejściowych**.

Dopiero warstwa adapterów MATLAB wykonuje:

1. ładowanie danych,
2. zamianę rekordów na serię,
3. budowę macierzy cech 27D,
4. przekazanie danych do visualizera.

---

## Struktura katalogów

### `parsers/`

Warstwa wejściowa dla nowych sample.

Zakres:

* parsowanie `sandbox.txt`,
* maskowanie / redakcja,
* normalizacja,
* zapis `sample_norm.json`.

### `sample/`

Magazyn danych wejściowych i pośrednich.

Struktura jednego sampla:

```text
sample/
  Sample_000X/
    raw/
      sandbox.txt
      Sample_000X_raw.json
    norm/
      sample_norm.json
      sample_norm.mat
```

### `matlab/adapters/`

Warstwa interoperacyjności i przygotowania danych.

Zakres:

* `load_sample_norm.m`
* `sample_norm_to_series.m`
* `build_loci_feature_matrix.m`
* `export_sample_norm_mat.m`

### `matlab/visualizers/`

Warstwa wizualizacji i raportowania wyników.

Zakres:

* redukcja 27D -> 9R / 3D,
* obliczanie metryk trajektorii,
* zapis PNG / FIG / TXT / JSON / MD.

### `tests/`

Warstwa testów end-to-end i walidacji komponentów.

### `results/`

Wyłącznie artefakty wyjściowe generowane automatycznie przez pipeline.

### `spec/`

Specyfikacje kontraktów danych, cech i zasad kompatybilności.

---

## Pliki aktywne

### Python

* `parsers/parse_sandbox.py`

### MATLAB — adaptery

* `matlab/adapters/load_sample_norm.m`
* `matlab/adapters/sample_norm_to_series.m`
* `matlab/adapters/build_loci_feature_matrix.m`
* `matlab/adapters/export_sample_norm_mat.m`

### MATLAB — visualizer

* `matlab/visualizers/loci_27D_9R_visualizer_canonical.m`

### Testy

* `tests/run_all_loci_pipeline_tests.m`

---

## Pliki legacy

Do kompatybilności historycznej mogą pozostać starsze pliki związane z pierwszym workflow, ale nie stanowią już osi systemu.

Przykłady:

* `sample/Sample_0001/norm/parse_sample_0001n_fixed.m`
* starsze skrypty rootowe dublujące funkcje z `matlab/adapters/` i `matlab/visualizers/`

Każdy taki plik powinien mieć nagłówek:

```matlab
% LEGACY / COMPAT
% File kept for backward compatibility with early LOCI workflow.
% Not part of the canonical LOCI pipeline.
```

---

## Komendy kanoniczne

### Uruchomienie visualizera dla jednego sampla

```matlab
addpath('C:\Users\d2j3\PycharmProjects\writeups\badania\LOCI\matlab\adapters');
addpath('C:\Users\d2j3\PycharmProjects\writeups\badania\LOCI\matlab\visualizers');

out = loci_27D_9R_visualizer_canonical( ...
    'C:\Users\d2j3\PycharmProjects\writeups\badania\LOCI\sample\Sample_0002\norm\sample_norm.json');
```

lub

```matlab
out = loci_27D_9R_visualizer_canonical( ...
    'C:\Users\d2j3\PycharmProjects\writeups\badania\LOCI\sample\Sample_0002\norm\sample_norm.mat');
```

### Uruchomienie pełnych testów pipeline

```matlab
addpath('C:\Users\d2j3\PycharmProjects\writeups\badania\LOCI\matlab\adapters');
addpath('C:\Users\d2j3\PycharmProjects\writeups\badania\LOCI\matlab\visualizers');
cd('C:\Users\d2j3\PycharmProjects\writeups\badania\LOCI\tests');

summary = run_all_loci_pipeline_tests();
```

---

## Zasady techniczne

1. Nie dodawać całego `LOCI` rekurencyjnie do `path`, jeśli w repo istnieją dublety nazw.
2. Visualizer nie może zgadywać struktury surowego JSON-a.
3. Budowa macierzy 27D ma się odbywać wyłącznie w `build_loci_feature_matrix.m`.
4. `sample_norm.json` i `sample_norm.mat` są formatami wejściowymi, nie wynikami końcowymi.
5. `results/` nie jest miejscem ręcznej edycji.

---

## Stan docelowy

LOCI ma działać jako jeden, spójny system:

* parser tworzy dane,
* adapter przygotowuje serię,
* generator cech buduje 27D,
* visualizer analizuje i zapisuje wyniki,
* testy walidują całość.

---

## 2. Sekcja do `LOCI/spec/canonical_pipeline.md`

```md
# LOCI — specyfikacja pipeline kanonicznego

## 1. Cel
Ustalenie jednego, stabilnego pipeline’u dla pracy z próbkami LOCI:
- od tekstu źródłowego,
- przez normalizację i maskowanie,
- do macierzy 27D i wizualizacji trajektorii.

---

## 2. Kontrakt danych

### 2.1. `sample_norm.json`
Format rekordowy.

Każdy rekord może zawierać pola:
- `sample_id`
- `entry_id`
- `author_id`
- `author_role`
- `timestamp_text`
- `timestamp_iso`
- `content_norm`
- `content_display`
- `entry_type`
- `parent_entry_id`
- `similarity_score`
- `links`
- `entities_masked`
- `source`

Ten format **nie jest macierzą cech**.

---

### 2.2. `sample_norm.mat`
Format eksportowy MATLAB zawierający ustandaryzowaną reprezentację danych z `sample_norm.json`.

Ma być ładowany przez `load_sample_norm.m`.

---

### 2.3. Seria analityczna `T`
Obiekt pośredni produkowany przez `sample_norm_to_series.m`.

Pola oczekiwane:
- `T.sample_id`
- `T.count`
- `T.records`
- `T.entry_ids`
- `T.parent_entry_ids`
- `T.content_norm`
- `T.content_display`
- `T.entry_type`
- `T.author_role`

---

### 2.4. Macierz cech 27D
Produkt `build_loci_feature_matrix.m`.

Zwraca:
- `X` — macierz `n x 27`
- `featureNames`
- `meta`

To jest **jedyna kanoniczna warstwa cech wejściowych** dla visualizera.

---

## 3. Warstwy pipeline’u

### Warstwa A — parser
Wejście:
- `sandbox.txt`

Wyjście:
- `sample_norm.json`

### Warstwa B — adapter
Wejście:
- `sample_norm.json` lub `sample_norm.mat`

Wyjście:
- seria `T`

### Warstwa C — feature builder
Wejście:
- seria `T`

Wyjście:
- `X (n x 27)`

### Warstwa D — visualizer
Wejście:
- `sample_norm.json` lub `sample_norm.mat`

Wewnątrz:
- `load_sample_norm`
- `sample_norm_to_series`
- `build_loci_feature_matrix`

Wyjście:
- PNG
- FIG
- TXT
- JSON
- MD

---

## 4. Zasady kompatybilności

### Legacy
Stare pliki pozostają wyłącznie dla kompatybilności historycznej.

Nie mogą stanowić podstawy nowego pipeline’u.

### Kanon
Nowe sample muszą przechodzić wyłącznie przez:
- parser,
- adapter,
- feature builder,
- canonical visualizer.

---

## 5. Zasady organizacyjne

1. Jedna odpowiedzialność na plik.
2. Brak zgadywania formatu wejścia w visualizerze.
3. Brak duplikacji logiki budowy 27D.
4. Brak ręcznego zapisu wyników poza `results/`.
5. Wszystkie testy integracyjne uruchamiane z `tests/`.

---

## 6. Minimalny zestaw plików aktywnych

- `parsers/parse_sandbox.py`
- `matlab/adapters/load_sample_norm.m`
- `matlab/adapters/sample_norm_to_series.m`
- `matlab/adapters/build_loci_feature_matrix.m`
- `matlab/adapters/export_sample_norm_mat.m`
- `matlab/visualizers/loci_27D_9R_visualizer_canonical.m`
- `tests/run_all_loci_pipeline_tests.m`


---

## 3. Krótki blok `LEGACY` do starych plików

Wstaw na górę starych plików:

```matlab
% LEGACY / COMPAT
% Historical file preserved for backward compatibility.
% This file is not part of the canonical LOCI pipeline.
% Active pipeline lives in:
%   - matlab/adapters/
%   - matlab/visualizers/
%   - tests/
```
