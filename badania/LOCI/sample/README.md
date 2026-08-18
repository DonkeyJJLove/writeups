# LOCI Samples — dane wejściowe i znormalizowane

[← LOCI](../README.MD)

Katalog `sample/` przechowuje próbki używane przez kanoniczny pipeline LOCI. Każdy `Sample_000X` rozdziela materiał surowy od warstwy znormalizowanej.

## Aktualne próbki

- `Sample_0001/` — największy historyczny korpus; `raw/` + `norm/`.
- `Sample_0002/` — kolejna próbka używana również przez testy pipeline’u.
- `Sample_0003/` — mniejsza próbka używana w aktualnym zestawie wyników.

## Typowa struktura

```text
Sample_000X/
├── manifest.json
├── raw/
│   ├── entries.jsonl
│   ├── manifest.json
│   ├── parse_report.json
│   └── warnings.json / revisions.jsonl
└── norm/
    ├── sample_norm.json
    ├── sample_norm.mat
    ├── aliases.json
    ├── author_map.json
    └── warnings.json
```

`sample_norm.json` jest kanonicznym znormalizowanym zapisem rekordów, **nie gotową macierzą 27D**. Konwersję do reprezentacji analitycznej wykonuje [`../matlab/adapters/`](../matlab/adapters/README.md).

Wyniki generowane z próbek znajdują się w [`../results/`](../results/README.md).
