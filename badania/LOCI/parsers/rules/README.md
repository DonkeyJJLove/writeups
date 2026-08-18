# LOCI Parser Rules — reguły wejścia

[← Parsers](../README.md) · [← LOCI](../../README.MD)

Katalog `rules/` przechowuje deklaratywne reguły używane przez warstwę ingestu LOCI.

- `parsing_rules.yaml` — reguły parsowania.
- `normalization_rules.yaml` — reguły normalizacji.
- `redaction_rules.yaml` — reguły redakcji / maskowania.

Zmiany tutaj powinny być walidowane testami parsera i normalizacji w [`../../tests/`](../../tests/README.md), ponieważ wpływają na kanoniczny `sample_norm`.
