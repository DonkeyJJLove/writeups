# LOCI — kanoniczny pipeline i drzewo nawigacji

[← Badania](../README.md) · [← Główny katalog](../../README.MD)

`badania/LOCI/` jest technicznym podsystemem repozytorium do przetwarzania iteracyjnych artefaktów Human–AI: parsowania, normalizacji, budowy cech 27D, analizy trajektorii, projekcji wizualizacyjnej, testów i statycznego raportowania.

**Ważne rozróżnienie implementacyjne:** aktualny kanoniczny kod buduje rzeczywistą macierz cech 27D, następnie standaryzuje ją i tworzy **3-wymiarową projekcję trajektorii** — przez PCA, gdy jest dostępne, albo przez kontrolowany fallback. Nazwa `9R` pozostaje częścią linii badawczej, nazewnictwa metaspace i docelowej formalizacji; bieżący visualizer **nie implementuje jeszcze jawnej, zwalidowanej funkcji** `R^27 → R^9` o zdefiniowanej semantyce dziewięciu osi.

## Drzewo

```text
LOCI/
├── README.MD              ← ten indeks
├── parsers/               ← ingest, redakcja, normalizacja
├── sample/                ← raw + norm dla Sample_000X
├── matlab/
│   ├── adapters/          ← sample_norm → seria → 27D
│   ├── features/          ← reprezentacja cech 27D
│   ├── visualizers/       ← projekcja trajektorii / metaspace / raporty
│   └── compat/            ← legacy / backward compatibility
├── spec/                  ← kontrakty i schematy danych
├── tests/                 ← testy + zachowane outputs
├── results/               ← wygenerowane artefakty
└── raports/               ← generator raportów rekurencyjnych
```

## Kanoniczny przepływ

```text
sandbox / entries
→ parsers/
→ sample/Sample_000X/norm/sample_norm.json
→ matlab/adapters/
→ analytical series T
→ 27D feature matrix X
→ standaryzacja
→ projekcja 3D + metryki trajektorii
→ results/Sample_000X/
→ results/_aggregate/
→ raports/
→ results/_reports/
```

### Fundamentalny kontrakt

`sample_norm.json` jest **znormalizowanym zapisem rekordów**, a nie macierzą cech. Reprezentacja 27D powstaje dopiero w warstwie adapterów/features. Visualizer nie powinien zgadywać semantyki surowego JSON-a.

Trajektoria uzyskana z projekcji jest **operacyjną reprezentacją obserwowalnych artefaktów**, a nie bezpośrednim pomiarem stanu latentnego transformera, intencji człowieka ani prawdziwości treści.

### Status 9R

Materiały badawcze repozytorium rozwijają relację 27D/9R, ale implementację należy opisywać zgodnie ze stanem kodu. Aby `9R` stało się formalnym wyjściem kanonicznego pipeline’u, potrzebne są co najmniej:

```text
jawna mapa R_9 : R^27 → R^9
+ semantyka dziewięciu wymiarów
+ procedura identyfikacji / kalibracji
+ test stabilności
+ walidacja na danych niezależnych
+ regresja implementacyjna
```

Do tego czasu `9R` nie może być używane w README jako synonim aktualnej projekcji PCA 3D.

---

## Gałęzie

- [`parsers/README.md`](parsers/README.md) — parsing, masking/redaction, normalization i reguły ingestu.
- [`sample/README.md`](sample/README.md) — Sample_0001–0003, podział `raw/` / `norm/`, manifesty i canonical `sample_norm`.
- [`matlab/README.md`](matlab/README.md) — mapa warstwy MATLAB.
  - [`matlab/adapters/README.md`](matlab/adapters/README.md) — ładowanie i konwersja danych.
  - [`matlab/features/README.md`](matlab/features/README.md) — reprezentacja cech 27D.
  - [`matlab/visualizers/README.md`](matlab/visualizers/README.md) — projekcja, metryki trajektorii i wizualizacja.
  - [`matlab/compat/README.md`](matlab/compat/README.md) — warstwa historyczna, niekanoniczna.
- [`spec/README.md`](spec/README.md) — schemas, sample contract, compatibility matrix i refactor manifest.
- [`tests/README.md`](tests/README.md) — testy end-to-end, cognitive readiness, aggregate reporting i outputs HMK27D.
- [`results/README.md`](results/README.md) — artefakty per sample, agregaty i statyczne raporty.
- [`raports/README.md`](raports/README.md) — generator raportu rekurencyjnego.

## Aktywne entry points

### Python

- `parsers/parse_sandbox.py`
- `raports/generate_recursive_loci_report.py`

### MATLAB

- `matlab/adapters/load_sample_norm.m`
- `matlab/adapters/sample_norm_to_series.m`
- `matlab/adapters/build_loci_feature_matrix.m`
- `matlab/adapters/export_sample_norm_mat.m`
- `matlab/visualizers/loci_27D_9R_visualizer_canonical.m`

Nazwa ostatniego pliku zachowuje historyczne `27D_9R`, ale jego aktualne wyjście obliczeniowe należy interpretować zgodnie z implementacją: 27D → standaryzacja → projekcja 3D / metryki trajektorii.

### Testy

- `tests/run_all_loci_pipeline_tests.m`
- `tests/run_loci_aggregate_report.m`
- `tests/run_loci_cognitive_readiness_test.m`

## Warstwa kompatybilności

Pliki w `matlab/compat/` zachowują historyczny workflow wyłącznie dla reprodukcji i kompatybilności. Nie powinny przejmować nazw/funkcji aktywnej ścieżki przez kolejność MATLAB `path`.

## Dane i wyniki

- `sample/` = wejście i reprezentacje pośrednie;
- `results/` = wyjście generowane;
- `tests/outputs_*` = artefakty testowe/eksperymentalne;
- `results/_reports/` = gotowa warstwa publikacyjna.

Aktualny statyczny raport rekurencyjny znajduje się pod `results/_reports/static_recursive_report_2026-03-23_174020/` i zawiera `index.html`, `summary.json`, `analysis.txt` oraz lokalne assets.

## Zasady techniczne

1. Jedna warstwa = jedna odpowiedzialność: ingest, adapter, features, visualization, tests, reports.
2. Zmiana kontraktu danych zaczyna się od `spec/`.
3. `sample_norm` nie jest macierzą cech.
4. Nie duplikować logiki 27D bez jawnego statusu implementacji.
5. Nie opisywać projekcji PCA 3D jako wdrożonego mapowania 27D→9R.
6. Nie edytować ręcznie `results/` jako źródła systemu.
7. Nie mieszać `compat/` z aktywnym `path`.
8. Zmiana kanonicznego pipeline’u wymaga testu regresyjnego i aktualizacji lokalnych README.

## Powiązane dokumenty repozytorium

- [`../../artykuły/loci-agent-llm-state-space-control.md`](../../artykuły/loci-agent-llm-state-space-control.md) — formalny model LOCI–Agent–LLM, granice aktualnej implementacji i warunki przejścia do zwalidowanego 9R.
- [`../../ai_security_model_boundary_strategy_writeup.md`](../../ai_security_model_boundary_strategy_writeup.md) — execution-path security i Security Model Boundary.
- [`../Organiczna modelowa analiza dynamiczna zdarzeń bezpieczeństwa w kontrapunkcie metody LOCI.pdf`](<../Organiczna modelowa analiza dynamiczna zdarzeń bezpieczeństwa w kontrapunkcie metody LOCI.pdf>) — kontrapunkt systemowy do metody LOCI.
- [`../Formalizacja 9R 27D_ 27‑wymiarowa semantyka poezji tensorowej dla tematu wywiad i PI.pdf`](<../Formalizacja 9R 27D_ 27‑wymiarowa semantyka poezji tensorowej dla tematu wywiad i PI.pdf>) — materiał badawczy formalizacji 9R/27D; nie jest to automatycznie dowód implementacji mapy 9R w aktualnym visualizerze.

---

**Nawigacja kanoniczna:** `README.MD → badania/README.md → LOCI/README.MD → warstwa → plik → wynik`.
