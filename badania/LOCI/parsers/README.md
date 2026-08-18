# LOCI Parsers — wejście, redakcja i normalizacja

[← LOCI](../README.MD)

Warstwa `parsers/` zamienia materiał wejściowy na kanoniczne rekordy LOCI. To pierwszy etap aktywnego pipeline’u.

## Pliki

- [`parse_sandbox.py`](parse_sandbox.py) — główny parser wejścia `sandbox.txt`.
- `parse_core.py` — rdzeń parsowania.
- `normalize_core.py` — normalizacja rekordów.
- `redact_core.py` — redakcja / maskowanie.
- `diff_core.py` — pomocnicza logika różnic.
- `export_matlab.py` — eksport / interoperacyjność z MATLAB.
- `manifest.json` — manifest warstwy parserów.
- `sandbox.txt` — materiał wejściowy / roboczy.
- [`rules/`](rules) — reguły parsowania, normalizacji i redakcji w YAML.

## Przepływ

```text
sandbox.txt
→ parse
→ redact
→ normalize
→ sample_norm.json
→ matlab/adapters/
```

Nowe przepływy powinny prowadzić przez kanoniczny parser zamiast omijać kontrakty danych LOCI.
