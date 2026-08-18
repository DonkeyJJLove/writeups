# LOCI Tests — walidacja pipeline’u

[← LOCI](../README.MD)

Katalog `tests/` zawiera testy komponentowe, integracyjne oraz zachowane wyniki testów i eksperymentów HMK/27D.

## Aktywne entry points

- `run_all_loci_pipeline_tests.m` — pełny zestaw testów pipeline’u.
- `run_loci_aggregate_report.m` — agregacja raportów LOCI.
- `run_loci_cognitive_readiness_test.m` — LOCI Cognitive Readiness Test.
- `test_loci_pipeline_sample_0002.m` — test przepływu dla `Sample_0002`.
- `test_parser.py` — test parsera.
- `test_normalization.py` — test normalizacji.
- `test_matlab_export.py` — test eksportu do MATLAB.

## Artefakty testowe

- `results/` — zachowane wyniki uruchomień testów pipeline’u.
- `outputs_hmk27d/` — wyniki eksperymentów HMK 27D.
- `outputs_hmk27d_sch/` — wyniki wariantu dynamicznego / Schrödinger-like modelu HMK 27D.

## Zasada

Zmiana kontraktu w [`../spec/`](../spec/README.md), parserze, adapterze lub visualizerze powinna być odzwierciedlona w testach. Artefakty wynikowe dokumentują reprodukcję, ale nie zastępują testów źródłowych.
