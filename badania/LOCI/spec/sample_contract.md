# LOCI Sample Contract v1

## Cel
Kanoniczny kontrakt danych dla parserów, normalizacji i adapterów MATLAB.

## Warstwy
- `raw/` — zapis źródłowy bez ingerencji semantycznej.
- `norm/` — zapis po normalizacji technicznej, redakcji i mapowaniu autora/aliasów.

## Minimalne artefakty per sample
- `raw/entries.jsonl`
- `raw/revisions.jsonl`
- `raw/parse_report.json`
- `norm/sample_norm.json`
- `norm/aliases.json`
- `norm/author_map.json`
- `norm/warnings.json`

## Zasady
1. Nic w `raw/` nie jest nadpisywane semantycznie.
2. Normalizacja nie usuwa historii wersji.
3. Vizualizer MATLAB czyta wyłącznie kontrakt (`sample_norm.json` albo `sample_norm.mat`).
4. Parser sample-specific (`parse_sample_0001n_fixed.m`) traktujemy jako warstwę compatibility, nie jako źródło prawdy.
