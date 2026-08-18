# LOCI Spec — kontrakty danych i kompatybilności

[← LOCI](../README.MD)

Katalog `spec/` jest warstwą kontraktów kanonicznego pipeline’u LOCI. To tutaj należy zaczynać przy zmianie formatu danych lub interoperacyjności.

## Pliki

- [`sample_contract.md`](sample_contract.md) — kontrakt próbki.
- `sample_schema_v1.json` — schema surowej / wejściowej próbki.
- `sample_norm_schema_v1.json` — schema znormalizowanej próbki.
- [`compatibility_matrix.md`](compatibility_matrix.md) — macierz kompatybilności.
- `refactor_manifest.json` — manifest refaktoryzacji i zgodności strukturalnej.

## Zasada

Zmiana parsera, adaptera albo visualizera, która zmienia kontrakt danych, powinna najpierw zostać odzwierciedlona w `spec/`, a następnie pokryta testem w [`../tests/`](../tests/README.md).
