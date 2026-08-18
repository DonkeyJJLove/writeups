# MATLAB compatibility layer

[← MATLAB](../README.md) · [← LOCI](../../README.MD)

Katalog `compat/` przechowuje **historyczne pliki kompatybilności wstecznej**. Nie jest częścią głównej ścieżki obliczeniowej LOCI i nie powinien być preferowany przy nowych sample.

## Zawartość

- `parse_sample_0001n_fixed.m` — parser specyficzny dla wczesnego workflow `Sample_0001`, zachowany dla kompatybilności i reprodukcji historii systemu.

## Reguła

```text
NEW WORK
→ parsers/
→ matlab/adapters/
→ matlab/features/
→ matlab/visualizers/

LEGACY REPRODUCTION
→ matlab/compat/
```

Nie dodawaj `compat/` przed aktywnymi katalogami w MATLAB `path`, ponieważ może to powodować niejawne użycie historycznej implementacji.
