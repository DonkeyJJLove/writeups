# Artefakty publikacyjne HCL 4.3.3

[Mapa repozytorium](../../../README.md) · [Opis badania](../README.md) · [Writeup wynikowy](../SEMANTIC_SCAFFOLDING_WRITEUP.md)

Ten katalog zawiera eksporty publikacyjne zakończonego runu `study_20261002-122125`. Źródłem wykonania jest wersjonowany katalog [runs/study_20261002-122125](../hcl_final_4_3/runs/study_20261002-122125/), nie pomocniczy selftest w `results/`.

[report.html](./report.html) jest raportem do czytania. [summary.json](./summary.json) zawiera agregaty, kontrasty i formalny werdykt. [trials.csv](./trials.csv) zawiera 10 240 rekordów epizodów, po 39 kolumn; jest kopią bajt w bajt [źródłowej tabeli](../hcl_final_4_3/runs/study_20261002-122125/study/trials.csv). [publication_validation.json](./publication_validation.json) zapisuje zakres i wynik kontroli spójności publikacji.

Surowe epizody, wymiany HTTP, profil, manifest i stan badania pozostają w historii Git. Są materiałem dowodowym, nie cache. Kod instrumentu i jego zamrożone źródła znajdują się w [hcl_final_4_3](../hcl_final_4_3/).

Korektę separatorów wcześniejszej kopii CSV opisuje [PUBLICATION_INTEGRITY.md](../PUBLICATION_INTEGRITY.md). Nie zmieniono źródłowego runu, ocen ani werdyktu. Kontrolę eksportu i agregatów można powtórzyć za pomocą [validate_publication.py](../validate_publication.py), bez uruchamiania modelu.
