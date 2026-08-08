# Oczy szeroko zamknięte są — kasyno wygrywa zawsze

## Repozytoryjny write-up wyników

> **Warunkowa teoria asymetrycznej kumulacji ekspozycji, zamknięcia decyzyjnego i przewagi operatora**

| Pole | Wartość |
|---|---|
| Wersja badania | `1.1.0` |
| Data finalizacji | `2026-08-06` |
| Werdykt ogólny | **B — warunkowa teoria formalno-obliczeniowa o ograniczonym zakresie i częściowym wsparciu empirycznym** |
| Przybliżona liczba trajektorii | **9,608,080** |
| Challenge set | **18/18 PASS** |
| Rejestr twierdzeń | **21 pozycji** |
| Mapa dowodów | **26 źródeł kotwiczących** |
| Nowe eksperymenty na ludziach lub zwierzętach | **nie** |
| Dowód biologiczny | **nie** |
| Preregistracja SHA-256 | `5ff09e7c0cee6184dc82c65c4ea1c20ad2cf747d9b2063ae8feadaf91a88bbad` |

---

<a id="status-dokumentu"></a>
## Status dokumentu

`WRITEUP.md` jest obszernym, repozytoryjnym punktem wejścia do wyników. Łączy warstwę wykonawczą, formalną, obliczeniową, empiryczną i audytową, a następnie prowadzi do konkretnych plików CSV, JSON, kodu, wykresów i dokumentacji ODD. Nie zastępuje zamrożonego [`report.md`](report.md); zachowuje jego ustalenia i rozszerza je o przewodnik po repozytorium, instrukcję reprodukcji, pełny rejestr twierdzeń, pełną mapę źródeł oraz checklistę recenzencką.

Dokument nie przedstawia metafory jako dowodu. Wyrażenie **„kasyno wygrywa zawsze”** jest tu skrótem dla asymptotycznej kumulacji dodatniej przewagi przy rosnącej liczbie rzeczywistych ekspozycji. Wyrażenie **„oczy szeroko zamknięte są”** oznacza operacyjnie sytuację, w której agent nadal otrzymuje informacje, lecz jego polityka działania pozostaje skoncentrowana w sposób generujący regret, nieadekwatną aktualizację lub opóźnienie adaptacji. Nie jest to rozpoznanie kliniczne, twierdzenie o trwałym „zamknięciu mózgu” ani biologiczny próg liczby prób.

<a id="werdykt-w-jednym-zdaniu"></a>
## Werdykt w jednym zdaniu

```text
Dodatnia przewaga operatora nie wymaga zamknięcia agenta.
Zamknięcie agenta nie gwarantuje przewagi operatora.
Jeżeli jednak zamknięcie zwiększa ekspozycję lub opóźnia wyjście,
a operator zachowuje dodatnią przewagę warunkową,
tempo kumulacji wyniku operatora rośnie zgodnie z E[Σ e_t μ_t].
```

To sformułowanie przeszło badanie jako **teoria warunkowa**, nie jako uniwersalne prawo psychologiczne albo biologiczne. Najsilniejszy status ma moduł formalny `M0`. Moduły `M1–M3` są wspierane w zdefiniowanych DGM, ale zakres ich uogólnienia musi być określany osobno dla każdej domeny.

<a id="najważniejsze-rozstrzygnięcia"></a>
## Najważniejsze rozstrzygnięcia

| Pytanie | Rozstrzygnięcie |
|---|---|
| Czy dodatnia przewaga oznacza wygraną w każdej grze? | **Nie.** Przy warunkach zbieżności oznacza dodatni wynik średni i `P(Sᴼ(T)>0)→1`, nie dodatni wynik każdej realizacji. |
| Czy większa liczba ekspozycji sama tworzy przewagę? | **Nie.** Przy `μ=0` nawet zmiana ekspozycji przekraczająca 407 interakcji nie stworzyła systematycznego oczekiwanego zysku pieniężnego. |
| Czy `T=200` jest progiem? | **Nie.** Jest wyłącznie kotwicą obserwacyjną. Wymagany horyzont zależy przede wszystkim od przewagi, wariancji i struktury zależności. |
| Czy niska entropia oznacza zamknięcie? | **Nie.** Może oznaczać optymalną specjalizację. Błędne zamknięcie wymaga kosztu/regretu i nieadekwatnej adaptacji. |
| Czy agent model-based jest zawsze odporniejszy? | **Nie.** Błędnie wyspecyfikowany model może adaptować się gorzej niż prostszy agent model-free. |
| Czy Martingale usuwa ujemną wartość oczekiwaną? | **Nie.** W badanym DGM zwiększał ryzyko ruiny względem stałej stawki. |
| Czy zysk operatora jest automatycznie stratą agenta? | **Nie.** Kontrprzykłady U3 i U5 pokazują obustronną korzyść lub wartość operatora bez wykazanej straty agenta. |
| Czy badanie dowodzi mechanizmu biologicznego? | **Nie.** Mosty `B1–B4` pozostają częściowe, a `B5` odrzucono jako twierdzenie uniwersalne. |

<a id="architektura-teorii"></a>
## Architektura teorii: M0–M3

Badanie celowo nie prowadziło jednego, z góry przyjętego łańcucha od nagrody do „zamknięcia”, a następnie do zysku operatora. Rozdzieliło cztery mechanizmy, aby każdy mógł zostać potwierdzony, zawężony albo obalony niezależnie.

```text
M0 — PRZEWAGA OPERATORA
Dodatnia warunkowa wartość oczekiwana operatora
+ rosnąca liczba rzeczywistych ekspozycji
→ kumulacja oczekiwanego wyniku operatora.
```

```text
M1 — EKSPOZYCJA
Lokalne nagrody lub bodźce kontynuacyjne
+ mechanizm decyzji o pozostaniu
+ ograniczona widoczność kosztów
→ wzrost oczekiwanej liczby dalszych ekspozycji.
```

```text
M2 — ZAMKNIĘCIE DECYZYJNE
Koncentracja polityki
+ dodatni regret lub koszt
+ nieadekwatna aktualizacja po wiarygodnej informacji
+ opóźnienie adaptacji po zmianie reżimu
→ zamknięcie decyzyjne.
```

```text
M3 — SPRZĘŻENIE
Jeżeli M1 zwiększa ekspozycję,
M2 opóźnia wycofanie lub zmianę polityki,
a M0 zapewnia dodatnią przewagę warunkową,
to M1 i M2 mogą zwiększać tempo kumulacji M0.
```

Wynik nie pozwala utożsamić tych modułów. `M0` może działać bez `M2`; `M2` może wystąpić bez dodatniej przewagi operatora; dopiero `M3` opisuje ich warunkowe sprzężenie.

<a id="statusy-modułów"></a>
## Statusy modułów

| Moduł | Werdykt | Status epistemiczny | Najważniejsza granica |
|---|---|---|---|
| `M0` | silnie wsparty formalnie i obliczeniowo | `P1/P3` | warunkowy dryf, rosnąca ekspozycja i warunki SLLN muszą być jawne |
| `M1` | warunkowo wsparty w syntetycznym DGM; częściowe wsparcie empiryczne | `P3`, miejscami `P3/P4` | efekt zależy od modelu kontynuacji, kosztu wyjścia, widoczności strat i domeny |
| `M2` | wsparty jako konstrukt algorytmiczny oparty na regrecie i adaptacji | `P1/P3` w modelach; `P5` biologicznie | entropia i proxy pewności nie są bezpośrednimi miarami biologicznymi |
| `M3` | wsparty jako warunkowe sprzężenie przez `N(T)`, przyszłą `μ_t` lub adaptację | `P1/P3` | zamknięcie nie jest źródłem przewagi i nie działa poza jawnie zdefiniowaną użytecznością |

<a id="co-jest-a-czego-nie-ma-w-wyniku"></a>
## Co jest, a czego nie ma w wyniku

### Wynik zawiera

- formalne twierdzenia z jawnymi założeniami i kontrprzykładami;
- dokładne obliczenia dwumianowe i wyniki łańcucha absorbującego;
- około 9,61 mln trajektorii w różnych klasach modeli;
- screening 2048 punktów Latin Hypercube;
- zamrożony plan 24 scenariuszy konfirmacyjnych;
- niezależną adjudykację gry uczciwej;
- challenge set 18 klas przypadków granicznych;
- wieloosiowy rejestr 21 twierdzeń;
- ustrukturyzowaną mapę 26 źródeł;
- kod, konfiguracje, manifest ziaren, dokumentację ODD, wyniki CSV/JSON i sumy kontrolne.

### Wynik nie zawiera

- nowych eksperymentów z ludźmi albo zwierzętami;
- dowodu, że entropia polityki syntetycznego agenta jest ludzką percepcją;
- dowodu, że value gap jest subiektywną pewnością człowieka;
- biologicznego albo psychologicznego progu `T=200`;
- podstaw dla nieodwracalnego „zamknięcia mózgu”;
- podstaw dla redukcji dopaminy do prostego mechanizmu nagrody;
- podstaw dla uniwersalnej tożsamości `zysk operatora = strata agenta`;
- pełnego statusu `P2`, ponieważ nie przeprowadzono reimplementacji przez drugi niezależny zespół w innym stosie programistycznym;
- pełnego przeglądu systematycznego PRISMA.

<a id="integralność-badania"></a>
## Integralność badania

Najważniejszym zdarzeniem audytowym był wynik gry uczciwej. W pierwszym przebiegu jedna różnica między scenariuszami wyglądała jak naruszenie przewidywania `ΔSᴼ≈0`. Wyniku nie usunięto ani nie przeformułowano hipotezy. Zamiast tego uruchomiono 16 nowych partii po 8192 trajektorie, czyli 131 072 replikacje na scenariusz. Wszystkie średnie scenariuszy i efekty parowane znalazły się w granicach `3 MCSE`. To rozstrzygnięcie jest ważniejsze niż sam napis `18/18 PASS`, ponieważ demonstruje procedurę obsługi pozornego kontrprzykładu bez dopasowania teorii po fakcie.

`PASS` oznacza wyłącznie, że **zawężona teoria nie została obalona w zdefiniowanej klasie formalnych i obliczeniowych testów**. Nie oznacza prawdy biologicznej, kompletności modelu ani trafności dla każdej platformy, rynku lub populacji.

<a id="szybka-nawigacja"></a>
## Szybka nawigacja

- [Pełna część techniczna](#1-status-epistemiczny-i-zakres)
- [M0 — przewaga operatora](#4-wyniki-m0--przewaga-operatora)
- [M1 — mechanizm ekspozycji](#5-wyniki-m1--mechanizm-ekspozycji)
- [M2 — koncentracja i adaptacja](#6-wyniki-m2--koncentracja-kalibracja-i-zmiana-reżimu)
- [M3 — sprzężenie](#7-wyniki-m3--sprzężenie)
- [Challenge set](#75-challenge-set)
- [Mapa dowodów](#8-ustrukturyzowana-mapa-dowodów)
- [Ostateczna teoria](#10-ostateczna-teoria)
- [Reprodukcja](#reprodukcja-krok-po-kroku)
- [Pełny rejestr twierdzeń](#pełny-rejestr-twierdzeń)
- [Pełna inwentaryzacja źródeł](#pełna-inwentaryzacja-źródeł)
- [Checklista recenzencka](#checklista-recenzenta)

<a id="pliki-źródłowe-wyniku"></a>
## Pliki źródłowe wyniku

| Warstwa | Główny plik | Rola |
|---|---|---|
| Raport | [`report.md`](report.md) | zamrożony raport końcowy 1.1.0 |
| Wynik maszynowy | [`study_summary_final.json`](results/aggregated/study_summary_final.json) | skondensowany werdykt i kluczowe liczby |
| Rejestr twierdzeń | [`claim_registry.csv`](claims/claim_registry.csv) | status, domena, identyfikacja i ograniczenia każdej tezy |
| Challenge set | [`challenge_set_results_final.csv`](results/aggregated/challenge_set_results_final.csv) | 18 testów i decyzje |
| M0 | [`house_edge.csv`](results/aggregated/house_edge.csv), [`gambler_ruin.csv`](results/aggregated/gambler_ruin.csv) | przewaga, horyzont, ruina i strategie |
| M1 | [`exposure_screening_results.csv`](results/aggregated/exposure_screening_results.csv), [`exposure_confirmatory_results.csv`](results/aggregated/exposure_confirmatory_results.csv) | screening i plan konfirmacyjny |
| M2 | [`bandit_metrics.csv`](results/aggregated/bandit_metrics.csv), [`bandit_timeseries.csv`](results/aggregated/bandit_timeseries.csv) | regret, entropia, kalibracja i adaptacja |
| M3 | [`exposure_confirmatory_paired_effects.csv`](results/aggregated/exposure_confirmatory_paired_effects.csv), [`fair_game_adjudication_summary.json`](results/aggregated/fair_game_adjudication_summary.json) | sprzężenie i adjudykacja gry uczciwej |
| Literatura | [`evidence_map.csv`](literature/evidence_map.csv), [`search_log.md`](literature/search_log.md) | ustrukturyzowana mapa dowodów i log wyszukiwania |
| Metody | [`methodology.md`](docs/methodology.md), [`preregistration.md`](docs/preregistration.md), [`ODD/`](docs/ODD/) | metody, prerejestracja i specyfikacja modeli |

---

# Pełny zapis techniczny badania

Poniższa część zachowuje treść zamrożonego raportu końcowego, wzbogaconą wyłącznie o odnośniki do wykresów i plików wynikowych znajdujących się w repozytorium.

# 1. Status epistemiczny i zakres

Badanie realizuje źródłowy protokół V2.0: nie zakłada tożsamości mechanizmów, rozdziela je na M0–M3 i dopuszcza najwyżej teorię formalno-obliczeniową z empirycznie zakotwiczonymi mostami. Nie przeprowadzono nowych eksperymentów na ludziach ani zwierzętach. Symulacja służy do badania konsekwencji jawnych założeń, nie do dowodzenia biologii.

Rozróżnienie zastosowane w całym raporcie:

```text
P1 — dowód formalny przy jawnych założeniach,
P2 — niezmiennik potwierdzony w niezależnych implementacjach,
P3 — wynik symulacyjny odporny w zdefiniowanej przestrzeni modeli,
P4 — silna regularność empiryczna wsparta wieloma źródłami,
P5 — hipoteza pomostowa pozostająca otwarta,
P6 — twierdzenie niewspierane albo obalone jako uniwersalne.
```

Pełnego P2 nie przyznano żadnemu twierdzeniu: uzyskano zgodność rozwiązań analitycznych, symulacji i niezależnych strumieni losowych, ale nie wykonano reimplementacji przez niezależny zespół w drugim stosie programistycznym.

---

# 2. Operacjonalizacja metafor

```text
„Kasyno wygrywa zawsze”
=
operator nie musi wygrywać każdej interakcji,
jeżeli ma dodatnią warunkową przewagę,
a liczba rzeczywistych ekspozycji rośnie.
```

```text
„Oczy szeroko zamknięte są”
=
agent nadal otrzymuje informacje,
lecz jego polityka jest skoncentrowana w sposób,
który generuje regret, nieadekwatną aktualizację
lub ponadnormatywne opóźnienie adaptacji.
```

Samo powtarzanie działania, wysoka koncentracja albo niska entropia nie wystarczają. Wynik podstawowy M2 jest wektorem:

```text
ZPD⃗ = ⟨PC, HS, CAL, CR, AD, RD⟩
```

W wykonanej części obliczeniowej bezpośrednio oszacowano `PC` (koncentrację polityki), pakiet `CAL`, `AD` (czas adaptacji), dynamiczny regret oraz modelowy błąd aktualizacji. `HS` i pełne `CR` pozostają zależne od klasy agenta i nie zostały scalone w jeden indeks.

---

# 3. Metody

## 3.1. Preregistracja i bramki

Przed scenariuszami konfirmacyjnymi zamrożono hipotezy, DGM, parametry, główne wyniki, strumienie RNG i reguły challenge set. Rdzeń obejmował 24 scenariusze: `μ∈{0, 0.02, 0.05}`, pełną albo zaniżoną percepcję strat, szybkie albo wolne uczenie i zerowy albo dodatni koszt wyjścia. `T=200` traktowano wyłącznie jako jeden z horyzontów, nie jako próg.

## 3.2. ADEMP

**Aims.** Ustalić warunki kumulacji przewagi, mechanizmy zwiększania ekspozycji, kryteria błędnego zamknięcia oraz strukturę sprzężenia.

**Data-generating mechanisms.** Użyto gier iid `±1`, procesu kapitału z absorpcją, dwuakcyjnego bandyty Bernoulliego ze zmianą reżimu oraz modelu kontynuacja–wyjście. W tym ostatnim agent wygrywa `+1` z prawdopodobieństwem `(1-μ)/2`, operator otrzymuje wynik przeciwny, a agent aktualizuje wartość kontynuacji na podstawie postrzeganego sygnału `+1` po wygranej i `−loss_weight` po stracie. Prawdopodobieństwo kontynuacji jest logistyczną funkcją wartości, temperatury i kosztu wyjścia.

**Estimands.** `P(Sᴼ(T)>0)`, wynik na ekspozycję, `E[N(T)]`, prawdopodobieństwo i czas ruiny, statyczny/dynamiczny regret, entropia, kalibracja, czas adaptacji, efekt ujawnienia wartości oczekiwanej, `ΔSᴼ−μΔN`.

**Methods.** Rozwiązania dokładne, Monte Carlo, wspólne DGM, LHS, ExtraTrees jako eksploracyjny model zastępczy, porównania parowane, adjudykacja błędu Monte Carlo, testy graniczne i kontrprzykłady.

**Performance measures.** Bias, MCSE, dokładne prawdopodobieństwa, regret, czas adaptacji, kalibracja, zgodność z tożsamością ekspozycyjną i stabilność w challenge set.

## 3.3. Skala wykonania

Wykonano łącznie około **9,61 mln trajektorii** różnych klas:

```text
M0 house edge:                       7 000 000
ruina i strategie stawkowania:        450 000
bandyty stationary/reversal:           192 000
screening ekspozycji:                  262 144
plan konfirmacyjny:                    196 608
interwencja disclosure:                196 608
adjudykacja gry uczciwej:            1 048 576
ujemna przewaga operatora:             262 144
```

Liczby trajektorii nie są jednym wspólnym rozmiarem próby: każdy moduł ma inny DGM i estymand. Precyzję oceniano przez MCSE oraz rozwiązania dokładne.

## 3.4. Weryfikacja

Pakiet przeszedł `6/6` testów jednostkowych i właściwości. Symulacje gry `±1` odzyskały dokładne prawdopodobieństwa dwumianowe, a symulacja stałej stawki odzyskała wyniki łańcucha absorbującego. Początkowy pojedynczy wyjątek gry uczciwej został oznaczony, a następnie rozstrzygnięty niezależną adjudykacją zamiast usunięcia post hoc.

---

# 4. Wyniki M0 — przewaga operatora

## 4.1. Twierdzenie o dodatnim warunkowym dryfie

Niech `e_t∈{0,1}` będzie decyzją ekspozycyjną mierzalną względem historii `F_(t−1)`, `N_T=Σe_t`, a `X_t` wynikiem operatora przy ekspozycji. Załóżmy:

```text
E[X_t | F_(t−1), e_t=1] = m_t ≥ μ > 0,
N_T → ∞,
```

oraz warunki martyngałowego prawa wielkich liczb, na przykład kontrolę sumy warunkowych wariancji. Definiując `d_t=X_t−m_t`, otrzymujemy:

```text
Sᴼ_T / N_T
= Σ e_t m_t / N_T + Σ e_t d_t / N_T
≥ μ + o(1)        prawie na pewno.
```

Stąd średni wynik operatora na ekspozycję jest ostatecznie dodatni, a `P(Sᴼ_T>0)→1`. To jest twierdzenie **P1**, ale wyłącznie przy jawnych założeniach. Nie wynika z niego `Sᴼ_T>0` dla każdej realizacji.

## 4.2. Dlaczego bezwarunkowe `E[X]>0` nie wystarcza

Kontrprzykład selekcji:

```text
Z ~ Bernoulli(1/2),
X=2, gdy Z=1,
X=−1, gdy Z=0,
E[X]=0.5.

Operator/agent eksponuje się tylko, gdy e=1−Z.
Wtedy każdy obserwowany wynik przy e=1 wynosi −1.
```

Dodatnia średnia bezwarunkowa nie chroni przed selekcją warunków ekspozycji. W modelach adaptacyjnych trzeba kontrolować `E[X_t|F_(t−1),e_t=1]`, a nie jedynie średnią całej populacji zdarzeń.

## 4.3. Poziomy „wygrywania”

```text
E[S_T]>0
≠ P(S_T>0)>0.5
≠ P(S_T>0)→1
≠ P(S_T>0)=1
≠ S_T>0 w każdej realizacji.
```

Przykład `X=100` z prawdopodobieństwem 0,02 i `X=−1` w pozostałych przypadkach ma dodatnią wartość oczekiwaną, ale tylko 2% szansy dodatniego wyniku pojedynczej gry. Odwrotnie, `X=1` z prawdopodobieństwem 0,9 oraz `X=−100` z prawdopodobieństwem 0,1 ma 90% szansy lokalnej wygranej i silnie ujemną wartość oczekiwaną.

## 4.4. Dokładne wyniki gry iid

![Prawdopodobieństwo dodatniego wyniku operatora w zależności od przewagi i horyzontu](figures/house_edge_positive_probability.png)

*Rysunek 1. Dokładne i symulacyjne prawdopodobieństwo dodatniego bilansu operatora. Dane: [`house_edge.csv`](results/aggregated/house_edge.csv).*

|        μ |           T |   dokładne P(Sᴼ>0) |   MC średni wynik/eksp. |     MCSE |
|---------:|------------:|-------------------:|------------------------:|---------:|
| 0.000000 |  200.000000 |           0.471826 |                0.000068 | 0.000158 |
| 0.000000 | 1000.000000 |           0.487387 |               -0.000042 | 0.000071 |
| 0.000000 | 5000.000000 |           0.494358 |                0.000039 | 0.000032 |
| 0.005000 |  200.000000 |           0.500047 |                0.004866 | 0.000158 |
| 0.005000 | 1000.000000 |           0.550345 |                0.004935 | 0.000071 |
| 0.005000 | 5000.000000 |           0.632858 |                0.004972 | 0.000032 |
| 0.010000 |  200.000000 |           0.528269 |                0.010098 | 0.000158 |
| 0.010000 | 1000.000000 |           0.612061 |                0.009889 | 0.000071 |
| 0.010000 | 5000.000000 |           0.755851 |                0.009975 | 0.000032 |
| 0.020000 |  200.000000 |           0.584157 |                0.020099 | 0.000158 |
| 0.020000 | 1000.000000 |           0.726099 |                0.020072 | 0.000071 |
| 0.020000 | 5000.000000 |           0.919286 |                0.020009 | 0.000032 |
| 0.050000 |  200.000000 |           0.738178 |                0.050052 | 0.000158 |
| 0.050000 | 1000.000000 |           0.939537 |                0.050087 | 0.000071 |
| 0.050000 | 5000.000000 |           0.999787 |                0.049995 | 0.000032 |

Dla `μ=0` prawdopodobieństwo dodatniego wyniku zbliża się do `0,5`, a nie do `1`. Dla `μ=0,02` wzrasta płynnie z `0.540` przy `T=100`, przez `0.584` przy `T=200`, do `0.656` przy `T=500`. Nie występuje uprzywilejowanie liczby 200.

## 4.5. Ile ekspozycji potrzeba do wysokiego prawdopodobieństwa dodatniego bilansu

|        μ |   cel P(Sᴼ>0) |   minimalne nieparzyste T |   dokładne P przy progu |
|---------:|--------------:|--------------------------:|------------------------:|
| 0.005000 |      0.900000 |              65695.000000 |                0.900002 |
| 0.005000 |      0.950000 |             108221.000000 |                0.950001 |
| 0.005000 |      0.990000 |             216473.000000 |                0.990000 |
| 0.010000 |      0.900000 |              16423.000000 |                0.900004 |
| 0.010000 |      0.950000 |              27055.000000 |                0.950004 |
| 0.010000 |      0.990000 |              54117.000000 |                0.990001 |
| 0.020000 |      0.900000 |               4105.000000 |                0.900011 |
| 0.020000 |      0.950000 |               6763.000000 |                0.950012 |
| 0.020000 |      0.990000 |              13527.000000 |                0.990001 |
| 0.050000 |      0.900000 |                657.000000 |                0.900235 |
| 0.050000 |      0.950000 |               1081.000000 |                0.950050 |
| 0.050000 |      0.990000 |               2163.000000 |                0.990021 |

Dla przewagi 0,5% osiągnięcie 95% prawdopodobieństwa dodatniego bilansu wymaga co najmniej **108 221** nieparzystych ekspozycji w tym DGM; dla 1% — **27 055**; dla 2% — **6 763**; dla 5% — **1 081**. Jest to ilościowa treść „kasyno wygrywa w długim szeregu”, a nie magiczna granica biologiczna.

## 4.6. Ruina gracza

![Prawdopodobieństwo ruiny dla badanych strategii i horyzontów](figures/gambler_ruin_probability.png)

*Rysunek 2. Ruina literalna i praktyczna w zależności od strategii. Dane: [`gambler_ruin.csv`](results/aggregated/gambler_ruin.csv).*

Dla przewidywalnej dodatniej stawki `b_t` i prawdopodobieństwa wygranej gracza `p=0,49`:

```text
E[ΔW_t | F_(t−1)] = b_t(2p−1) < 0.
```

Zmiana rozmiaru stawki nie odwraca znaku dryfu. Może zmieniać wariancję, czas do wyjścia i sposób zbliżania się do zera. Literalna ruina z prawdopodobieństwem dążącym do 1 wymaga dodatkowo m.in. nieskończonej liczby zakładów, dodatniej minimalnej stawki, braku dopływów i braku dobrowolnego wyjścia.

| strategia          |   P(ruiny literalnej) |   P(ruiny praktycznej) |   średni kapitał |   mediana kapitału |   P(wyjścia) |   średnia ekspozycja |
|:-------------------|----------------------:|-----------------------:|-----------------:|-------------------:|-------------:|---------------------:|
| fixed_unit_exact   |              0.970871 |               0.970962 |         1.659327 |           0.000000 |     0.000000 |           nan        |
| no_play            |              0.000000 |               0.000000 |        20.000000 |          20.000000 |     1.000000 |             0.000000 |
| martingale_limit16 |              0.987467 |               0.987467 |         4.146833 |           0.000000 |     0.987467 |           267.335433 |
| stop_loss_20pct    |              0.000000 |               0.000000 |        16.220333 |          16.000000 |     0.996033 |           187.123733 |
| proportional_1pct  |              0.000000 |               0.068367 |         7.344673 |           5.729833 |     0.000000 |          5000.000000 |

Przy stałej stawce dokładne `P(ruiny do 5000)` wyniosło **0.9709**. Ograniczona strategia Martingale dała **0.9875**, a więc pogorszyła ryzyko ruiny. Strategia proporcjonalna nie osiągnęła literalnego zera, lecz średni kapitał spadł do **7.34**, mediana do **5.73**, a praktyczna ruina wystąpiła w **6.84%** trajektorii. Benchmark „nie gram” zachował kapitał i miał `P(ruiny)=0`.

**Werdykt M0:** formalnie silnie wsparty, z jasno wyznaczonymi warunkami. Status rdzenia: `P1`; odzyskanie przez obliczenia: `P3`.

---

# 5. Wyniki M1 — mechanizm ekspozycji

## 5.1. Screening globalny

![Liczba ekspozycji w warunkach modelu kontynuacja–wyjście](figures/exposure_count_conditions.png)

*Rysunek 3. Zmienność liczby ekspozycji w modelu M1. Dane: [`exposure_screening_results.csv`](results/aggregated/exposure_screening_results.csv).*

![Wynik operatora wobec wartości przewidywanej przez przewagę i ekspozycję — screening](figures/exposure_gain_vs_expected_screening.png)

*Rysunek 4. Screening globalny: obserwowany wynik operatora wobec `μE[N]`.*

Screening 2048 punktów LHS wykazał, że w zdefiniowanym modelu kontynuacji liczba ekspozycji była najbardziej czuła na temperaturę decyzji, wagę postrzeganej straty i tempo uczenia. Sama przewaga `μ` miała niewielką ważność dla liczby ekspozycji, lecz większą dla wyniku operatora. To rozróżnienie jest kluczowe: architektura utrzymująca agenta w interakcji i matematyczna przewaga jednostkowa są odrębnymi kanałami.

| wynik                     | parametr    |   ważność ExtraTrees |   R² treningowe |
|:--------------------------|:------------|---------------------:|----------------:|
| mean_exposures            | tau         |               0.4128 |          0.9845 |
| mean_exposures            | loss_weight |               0.3272 |          0.9845 |
| mean_exposures            | alpha       |               0.1747 |          0.9845 |
| mean_exposures            | exit_cost   |               0.0548 |          0.9845 |
| mean_operator_gain        | tau         |               0.3347 |          0.9777 |
| mean_operator_gain        | loss_weight |               0.2790 |          0.9777 |
| mean_operator_gain        | mu          |               0.1747 |          0.9777 |
| mean_operator_gain        | alpha       |               0.1612 |          0.9777 |
| mean_policy_concentration | tau         |               0.6565 |          0.9905 |
| mean_policy_concentration | q0          |               0.1824 |          0.9905 |
| mean_policy_concentration | exit_cost   |               0.0672 |          0.9905 |
| mean_policy_concentration | alpha       |               0.0464 |          0.9905 |
| mean_update_error         | loss_weight |               0.3443 |          0.9795 |
| mean_update_error         | tau         |               0.2239 |          0.9795 |
| mean_update_error         | alpha       |               0.2036 |          0.9795 |
| mean_update_error         | q0          |               0.1771 |          0.9795 |

Ważności ExtraTrees są wynikiem eksploracyjnym: model osiągał wysokie `R²` treningowe, ale wartości nie są uniwersalnymi efektami przyczynowymi ani rankingiem biologicznych mechanizmów.

## 5.2. Scenariusze konfirmacyjne

![Wynik operatora wobec wartości przewidywanej przez przewagę i ekspozycję — plan konfirmacyjny](figures/exposure_gain_vs_expected_confirmatory.png)

*Rysunek 5. Plan konfirmacyjny: zgodność wyniku z kanałem ekspozycyjnym. Dane: [`exposure_confirmatory_results.csv`](results/aggregated/exposure_confirmatory_results.csv).*

|   scenariusz |      μ |   waga straty |      α |   koszt wyjścia |     E[N] |   E[Sᴼ] |   μE[N] |   koncentracja |   błąd aktualizacji |
|-------------:|-------:|--------------:|-------:|----------------:|---------:|--------:|--------:|---------------:|--------------------:|
|       8.0000 | 0.0200 |        1.0000 | 0.2000 |          0.0000 |   5.4156 |  0.0680 |  0.1083 |         0.5799 |              0.0935 |
|      15.0000 | 0.0200 |        0.2500 | 0.0200 |          0.1000 | 471.8014 |  9.3383 |  9.4360 |         0.9970 |              0.3748 |
|      16.0000 | 0.0500 |        1.0000 | 0.2000 |          0.0000 |   4.9919 |  0.2620 |  0.2496 |         0.5670 |              0.0882 |
|      23.0000 | 0.0500 |        0.2500 | 0.0200 |          0.1000 | 462.5103 | 23.0649 | 23.1255 |         0.9961 |              0.3839 |

Przy `μ=0,02` przejście od pełnego ważenia strat i szybkiej aktualizacji do zaniżania strat, wolnej aktualizacji i kosztownego wyjścia zwiększyło `E[N]` z około **5,42** do **471,80**, a oczekiwany wynik operatora z około **0,07** do **9,34**. Przy `μ=0,05` analogiczny scenariusz osiągnął `E[N]=462,51` oraz `E[Sᴼ]=23,06`.

To nie dowodzi psychologicznej „ślepoty”; pokazuje mechanizm modelowy: jeżeli lokalny sygnał aktualizacji systematycznie niedoważa kosztów, a wyjście jest mniej atrakcyjne, polityka kontynuacji może pozostać skoncentrowana mimo ujemnej wartości pieniężnej agenta.

## 5.3. Ujawnienie wartości oczekiwanej

W kroku 50 część symulacji otrzymała doskonałą informację o jednostkowej wartości pieniężnej dalszej gry.

|      μ |   średnie ΔN po ujawnieniu |   średnie ΔSᴼ |   średnie Δ błędu aktualizacji |
|-------:|---------------------------:|--------------:|-------------------------------:|
| 0.0000 |                   -81.8253 |        0.0086 |                        -0.0733 |
| 0.0200 |                   -84.9065 |       -1.6861 |                        -0.0807 |
| 0.0500 |                   -85.2918 |       -4.2497 |                        -0.0897 |

Średnio ujawnienie ograniczało ekspozycję w warunkach bezwładności, a przy dodatniej `μ` redukowało wynik operatora. Nie był to efekt uniwersalny dla każdego scenariusza. Wynik jest zgodny z empirycznym obrazem interwencji: dłuższa obowiązkowa przerwa może wydłużyć pauzę, ale nie musi zmieniać kwot po powrocie [17].

**Werdykt M1:** wsparty warunkowo w modelu i częściowo w literaturze o nagrodach społecznych, opóźnionym feedbacku oraz hazardzie. Status: `P3` w DGM; uogólnienie empiryczne zależne od domeny.

---

# 6. Wyniki M2 — koncentracja, kalibracja i zmiana reżimu

## 6.1. Twierdzenie softmax

![Entropia polityki softmax w funkcji parametrów](figures/softmax_entropy.png)

*Rysunek 6. Entropia polityki softmax dla kontrolowanych różnic `Q` i temperatury. Dane: [`softmax_entropy.csv`](results/aggregated/softmax_entropy.csv).*

Dla `β=1/τ`, `π_i=e^(βQ_i)/Z` oraz entropii `H=log Z−βE_π[Q]`:

```text
dH/dβ = −β Var_π(Q) ≤ 0.
```

Przy stałych wartościach `Q` zwiększenie różnic wartości albo zmniejszenie temperatury obniża entropię. Powtarzalna nagroda obniża entropię tylko wtedy, gdy algorytm aktualizacji powiększa różnice wartości i nie utrzymuje wymuszonej eksploracji. Nie jest to prawo każdego agenta.

## 6.2. Specjalizacja a błędne zamknięcie

![Regret agentów po zmianie reżimu](figures/reversal_regret.png)

*Rysunek 7. Regret po odwróceniu wartości akcji. Dane: [`bandit_metrics.csv`](results/aggregated/bandit_metrics.csv).*

![Przebieg regretu w czasie w środowisku reversal](figures/reversal_regret_timeseries.png)

*Rysunek 8. Dynamika regretu przed i po zmianie reżimu. Dane: [`bandit_timeseries.csv`](results/aggregated/bandit_timeseries.csv).*

W środowisku stacjonarnym agent rigid-softmax miał niską entropię `0,0427` oraz niski regret `0,0090`. Była to poprawna specjalizacja. Po odwróceniu wartości akcji ta sama bezwładność stała się kosztowna.

| agent            |   regret po zmianie |   entropia |   proxy pewności |   Brier |   nachylenie kalibracji |     ECE |   opóźnienie adaptacji |   brak adaptacji |
|:-----------------|--------------------:|-----------:|-----------------:|--------:|------------------------:|--------:|-----------------------:|-----------------:|
| oracle           |             0.00000 |    0.00000 |          0.60000 | 0.16004 |               nan       | 0.00015 |               20.00000 |          0.00000 |
| cue_informed     |             0.00001 |    0.00012 |          0.60031 | 0.16203 |                 0.02246 | 0.03716 |               20.00000 |          0.00000 |
| softmax_flexible |             0.06365 |    0.23570 |          0.57834 | 0.18835 |                 0.37352 | 0.09553 |               28.15400 |          0.00000 |
| epsilon_q        |             0.07515 |    0.19852 |          0.47751 | 0.18477 |                 0.62447 | 0.05867 |               33.36858 |          0.00000 |
| softmax_rigid    |             0.08967 |    0.10371 |          0.27197 | 0.19795 |                 0.77649 | 0.02093 |               48.12117 |          0.00000 |
| bayes_discounted |             0.13175 |    0.11691 |          0.28935 | 0.20013 |                 1.36790 | 0.06237 |               57.49758 |          0.00000 |
| random           |             0.29998 |    0.69315 |          0.00000 | 0.25000 |               nan       | 0.00037 |              178.08583 |          0.76417 |
| bayes_stationary |             0.52875 |    0.11732 |          0.25496 | 0.33059 |                 0.27949 | 0.37173 |              186.45825 |          0.70350 |

Najważniejsze kontrprzykłady:

```text
niska entropia + niski regret  → specjalizacja adaptacyjna,
niska entropia + wysoki regret → błędna koncentracja,
wysoka entropia + wysoki regret → losowość bez skuteczności.
```

Agent z jawną informacją o zmianie osiągnął czas adaptacji `20,0`, rigid-softmax `48,1`, a błędnie stacjonarny agent bayesowski `186,5` i nie dostosował się w 70,35% trajektorii. Sama etykieta „model-based” nie zapewnia odporności; błędny model może utrwalić nieprawidłowy posterior.

## 6.3. Pewność i kalibracja

Dla flexible-softmax modelowy proxy pewności wzrósł z `0,5635` do `0,5783`, podczas gdy Brier pogorszył się z `0,1800` do `0,1884`, a nachylenie kalibracji po zmianie wyniosło `0,3735`. Pokazuje to modelową możliwość rozbieżności. Literatura ludzka również dokumentuje przypadki, w których trafność spada, a deklarowana pewność rośnie [12], oraz sytuacje, w których zachęty poprawiają wykonanie, ale przesuwają oceny pewności [13]. Nie wynika z tego, że value-gap jest tożsamy z ludzką pewnością.

## 6.4. Znaczenie biologiczne

Badania dopaminy wspierają wielomechanizmowy, a nie jednowymiarowy obraz. Klasyczny sygnał RPE ma silne wsparcie [4–5], lecz prace z 2025 r. pokazują także sygnał błędu predykcji działania wzmacniający powtórzenia [8] oraz dynamikę związaną z wykonaniem i motywacją, niekoniecznie uczeniem [9]. Badanie z 2026 r. wykazało nagłe przejście do nawyku w konkretnym paradygmacie u samców myszy, ale po tysiącach prób od uzyskania ekspertyzy i z możliwością powrotu do kontroli celowej [11]. To wspiera nieliniowość, lecz przeczy uniwersalnemu, trwałemu progowi 200.

**Werdykt M2:** konstrukcja algorytmiczna jest odporna, jeśli zamknięcie definiuje się przez regret i adaptację; most biologiczny pozostaje niepełny. Status: `P1/P3` dla modeli, `P5` dla bezpośredniej interpretacji biologicznej.

---

# 7. Wyniki M3 — sprzężenie

## 7.1. Tożsamość ekspozycyjna

Przy stałej warunkowej przewadze `μ`:

```text
E[Sᴼ(T)]
= E[Σ e_t X_t]
= E[Σ e_t E(X_t | F_(t−1), e_t=1)]
= μ E[N(T)].
```

Zamknięcie nie jest konieczne do dodatniego wyniku. Wpływa na operatora tylko wtedy, gdy zmienia `N(T)`, przyszłą `μ_t`, koszt lub inną składową użyteczności.

W dodatnich scenariuszach parowanych korelacja między obserwowanym `ΔSᴼ` i przewidywanym `μΔN` wyniosła **0.9997**, a średnia bezwzględna reszta sprzężenia **0.1243** jednostki. Nie jest to korelacja odkrywająca mechanizm — mechanizm wynika z DGM; wynik sprawdza poprawność implementacji.

## 7.2. Gra uczciwa i niezależna adjudykacja

Pierwszy przebieg 8192 replikacji dał w jednym porównaniu gry uczciwej różnicę wyglądającą na naruszenie `ΔSᴼ≈0`. Zamiast usunąć wynik, wykonano 16 nowych partii po 8192 replikacje, łącznie **131 072 trajektorie na scenariusz**.

```text
wszystkie średnie scenariuszy w granicach 3 MCSE:  TAK
wszystkie efekty parowane w granicach 3 MCSE:     TAK
maksymalne |z| średniej scenariusza:              2.238
maksymalne |z| efektu parowanego:                 1.780
maksymalne |średniego ΔSᴼ|:                       0.0585
maksymalne |ΔN|:                                  407.4
```

Agent mógł zwiększyć ekspozycję o ponad 407 interakcji, lecz bez dodatniej przewagi nie powstał systematyczny oczekiwany zysk pieniężny operatora.

## 7.3. Ujemna przewaga operatora

W ośmiu scenariuszach `μ=−0,02` liczba ekspozycji wahała się od **5.7** do **479.5**, a każdy średni wynik operatora był ujemny: od **-9.527** do **-0.098**. Większa ekspozycja szkodziła operatorowi zgodnie z `μE[N]`.

## 7.4. Niezerowa suma i dobrostan

Skonstruowano dwie klasy kontrprzykładów:

```text
U3 — obie strony otrzymują dodatnią użyteczność z ekspozycji;
U5 — operator monetyzuje uwagę, a użyteczność agenta jest neutralna.
```

Wszystkie scenariusze U3 dawały dodatnią użyteczność obu stron. W U5 wynik operatora był dodatni przy braku wykazanej ujemnej użyteczności agenta. Literatura platformowa dostarcza zgodnych kontrprzykładów: rekomendacje zgodne z preferencjami idealnymi dawały mniej kliknięć, lecz większy dobrostan użytkownika i wybrane korzyści firmowe [20].

## 7.5. Challenge set

| test                                                 | assumption_attacked                                                | observed                                                                                                | decision   |
|:-----------------------------------------------------|:-------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------|:-----------|
| C01_fair_game_exposure                               | większa ekspozycja sama tworzy zysk operatora                      | adaptive adjudication: 131072 reps/scenario; max|mean gain|=0.0422; max|z|=2.238                        | PASS       |
| C02_no_asymptotic_certain_profit_fair_game           | liczba prób wystarcza bez przewagi                                 | P at max T=0.4944                                                                                       | PASS       |
| C03_small_edge_not_every_short_run                   | dodatnia przewaga oznacza każdą wygraną                            | range P=0.4207-0.6329                                                                                   | PASS       |
| C04_no_play_avoids_ruin                              | ruina jest nieunikniona dla każdego agenta                         | max P=0.0000                                                                                            | PASS       |
| C05_stake_tends_to_zero                              | ujemny dryf zawsze daje literalną ruinę w skończonym czasie        | literal=0.0000; practical=0.0684                                                                        | PASS       |
| C06_low_entropy_adaptive_specialization              | niska entropia jest patologiczna                                   | entropy=0.0427; regret=0.0090                                                                           | PASS       |
| C07_low_entropy_can_be_costly_after_reversal         | koncentracja zawsze poprawia wynik                                 | regret=0.0897; delay=48.1                                                                               | PASS       |
| C08_high_entropy_not_sufficient_for_good_performance | wysoka entropia gwarantuje elastyczność                            | entropy=0.6931; regret=0.3000                                                                           | PASS       |
| C09_model_based_misspecification                     | model-based jest zawsze odporniejszy                               | delay stationary=186.5; discounted=57.5                                                                 | PASS       |
| C10_counterfactual_cue_reopens_policy                | utrwalona polityka jest praktycznie nieodwracalna                  | cue delay=20.0; rigid=48.1                                                                              | PASS       |
| C11_M3_exposure_mediation                            | zamknięcie działa niezależnie od ekspozycji w tym DGM              | corr=0.9997; mean abs residual=0.1243                                                                   | PASS       |
| C12_closure_without_edge                             | zamknięcie samo tworzy przewagę pieniężną                          | initial single-seed FAIL; independent adjudication: max|mean Δgain|=0.0585; max|ΔN|=407.4; max|z|=1.780 | PASS       |
| C13_negative_operator_edge                           | więcej ekspozycji zawsze pomaga operatorowi                        | all gains negative=True; range N=5.7-479.5; gain=-9.527..-0.098                                         | PASS       |
| C14_mutual_benefit_not_zero_sum                      | zysk operatora musi oznaczać stratę agenta                         | all both positive=True                                                                                  | PASS       |
| C15_operator_value_without_agent_loss                | wynik operatora i koszt agenta są tą samą zmienną                  | operator utility range=0.055-4.758; agent utility=0                                                     | PASS       |
| C16_selective_exposure_counterexample                | bezwarunkowe E[X]>0 wystarcza przy selekcji ekspozycji             | X=2 dla Z=1 i X=-1 dla Z=0, P(Z=1)=1/2 daje E[X]=0.5; e=1-Z daje każdy obserwowany X=-1                 | PASS       |
| C17_finite_horizon_ruin_not_one                      | ujemna przewaga oznacza pewną ruinę w każdym skończonym horyzoncie | fixed unit P_ruin(T=200)=0.2300; T=5000=0.9709                                                          | PASS       |
| C18_no_special_threshold_at_200                      | T=200 jest uniwersalnym punktem fazowym                            | dla μ=0.02 P(S>0): T=100:0.540, T=200:0.584, T=500:0.656                                                | PASS       |

Wszystkie **18/18 klas** przeszły według prerejestrowanych lub jawnie uzupełnionych kryteriów. „PASS” nie oznacza prawdziwości biologicznej; oznacza, że teoria po zawężeniu nie została obalona przez określone kontrprzykłady formalne i obliczeniowe.

**Werdykt M3:** wsparty jako teoria warunkowa: zamknięcie jest mechanizmem wzmacniającym, nie źródłem przewagi samym w sobie. Status: `P1/P3`; trafność zewnętrzna ograniczona.

---

# 8. Ustrukturyzowana mapa dowodów

Przegląd nie spełnia pełnego PRISMA i nie jest nazywany systematycznym. Zakodowano 26 źródeł kotwiczących.

| domena                     |   liczba źródeł | zakres lat   |
|:---------------------------|----------------:|:-------------|
| D1 formalna probabilistyka |               2 | 1956–1991    |
| D2 reinforcement learning  |               5 | 1997–2025    |
| D3 nawyk i kontrola celowa |               3 | 2010–2026    |
| D4 kalibracja              |               1 | 2019–2019    |
| D4 pewność i kalibracja    |               3 | 2012–2019    |
| D5 hazard i ekspozycja     |               1 | 2014–2014    |
| D5 hazard i interwencje    |               1 | 2022–2022    |
| D5 hazard i wzmocnienia    |               2 | 2009–2023    |
| D6 platformy i operator    |               4 | 2021–2026    |
| Metody                     |               4 | 2009–2021    |

## 8.1. Co literatura wspiera mocno

Po pierwsze, organizmy i ludzie aktualizują zachowanie na podstawie relacji między działaniem, wynikiem i sygnałami predykcyjnymi; kontrola model-free i model-based może współistnieć [3–10]. Po drugie, pewność i trafność są rozdzielne, dlatego wzrost proxy pewności nie dowodzi poprawy modelu [12–14]. Po trzecie, architektura wzmocnienia i czas informacji mogą zmieniać trwałość zachowania oraz kontrolę celową [10, 15–18]. Po czwarte, mechanizmy platform rzeczywiście mogą wpływać na częstotliwość działania i postawy, ale efekty są zależne od platformy, wyniku i interwencji [19–22].

## 8.2. Co literatura falsyfikuje jako prosty uniwersalny łańcuch

Redukcja ekspozycji na podobne źródła na Facebooku zmieniła skład feedu, lecz nie osiem prerejestrowanych postaw [21]. Na X włączenie algorytmicznego feedu zwiększyło zaangażowanie i zmieniło wybrane opinie, ale nie polaryzację afektywną ani deklarowaną partyjność [22]. Dłuższe przerwy w hazardzie wydłużały pauzę, lecz nie zmieniały kwot stawek po powrocie [17]. Oznacza to, że:

```text
zmiana ekspozycji ≠ automatyczna zmiana przekonań,
zmiana zachowania ≠ automatyczny spadek dobrostanu,
interwencja ≠ uniwersalne odwrócenie polityki.
```

## 8.3. Twierdzenia pomostowe B1–B5

**B1 — koncentracja polityki ↔ nawyk.** Zgodność kierunkowa istnieje, ale entropia softmax nie jest zwalidowaną miarą biologicznego nawyku. Status `P5`.

**B2 — proxy pewności ↔ pewność człowieka.** Literatura potwierdza dysocjację pewność–trafność, nie identyczność value-gap i raportu introspekcyjnego. Status `P5`.

**B3 — adaptation delay ↔ reversal learning/sztywność.** Konstrukty są funkcjonalnie podobne, lecz brak kalibracji skali i trafności różnicowej. Status `P5`.

**B4 — operator syntetyczny ↔ platforma lub kasyno.** Istnieją empiryczne odpowiedniki nagród, retencji, feedów i przerw, ale cele operatorów i funkcje użyteczności są heterogeniczne. Status `P5`, częściowe zakotwiczenie.

**B5 — wynik operatora ↔ strata agenta.** Twierdzenie uniwersalne jest fałszywe. Status `P6`; relację trzeba mierzyć domenowo.

---

# 9. Rejestr twierdzeń — synteza

Pełny rejestr znajduje się w `claims/claim_registry.csv`. Rozkład statusów:

| module   | status   |   liczba |
|:---------|:---------|---------:|
| M0       | P1       |        3 |
| M0       | P1/P3    |        2 |
| M1       | P3       |        1 |
| M1       | P3/P4    |        1 |
| M2       | P1/P3    |        1 |
| M2       | P3       |        2 |
| M2       | P3/P4    |        1 |
| M3       | P1/P3    |        4 |
| bridge   | P5       |        4 |
| bridge   | P6       |        2 |

Najsilniejszy rdzeń dotyczy matematyki przewagi, warunkowości ruiny, nieswoistości entropii i tożsamości `μE[N]`. Najsłabsza warstwa dotyczy bezpośredniego mapowania zmiennych syntetycznych na ludzką percepcję.

---

# 10. Ostateczna teoria

## Hipoteza

Lokalne wzmocnienia i architektura wyjścia mogą zwiększać liczbę ekspozycji oraz utrwalać politykę agenta; jeżeli operator zachowuje dodatnią przewagę warunkową, wzrost ekspozycji może zwiększać jego skumulowany wynik.

## Teza

```text
M0: μ_t>0 warunkowo + N(T) rośnie
    → kumulacja przewagi operatora.

M1: lokalny sygnał + reguła kontynuacji + koszt wyjścia
    → zmiana N(T).

M2: koncentracja + regret + błąd aktualizacji + opóźnienie
    → błędne zamknięcie decyzyjne.

M3: M2 wpływa na M0 tylko wtedy, gdy zmienia N(T), μ_t,
    czas adaptacji, koszt albo inną użyteczność operatora.
```

## Przewód formalny

```text
E[Sᴼ(T)] = E[Σ e_t μ_t].
```

Przy stałej `μ`:

```text
E[Sᴼ(T)] = μE[N(T)].
```

Stąd:

```text
μ>0: większa oczekiwana ekspozycja zwiększa E[Sᴼ],
μ=0: ekspozycja nie tworzy oczekiwanego zysku pieniężnego,
μ<0: ekspozycja zwiększa oczekiwaną stratę operatora.
```

## Dowody obliczeniowe

Dokładne rozkłady i Monte Carlo odzyskały asymptotyczną przewagę. Modele reversal wykazały odrębność koncentracji i kosztu. Plan konfirmacyjny oraz challenge set wykazały sprzężenie przez ekspozycję i niepowodzenie teorii poza warunkami dodatniej przewagi lub innej użyteczności operatora.

## Dowody empiryczne

Literatura wspiera uczenie przez wyniki, wpływ opóźnienia i nagród na zachowanie, możliwość nawykowej kontroli, rozbieżność pewności i trafności oraz wpływ operatorów platform. Nie wspiera uniwersalnego progu 200, nieodwracalności ani prostego determinizmu dopaminowego.

## Warunki brzegowe

Teoria nie obowiązuje bez zmian, gdy ekspozycja jest selektywna względem ukrytej przewagi, `μ_t` jest adaptacyjne, funkcje użyteczności są nieporównywalne, agent może bez kosztu odmówić, gra zmienia się wskutek uczenia gracza albo operator uzyskuje korzyść pozapieniężną.

## Falsyfikatory

Teoria M3 zostałaby obalona w deklarowanym zakresie, gdyby przy stałej `μ>0` i poprawnie mierzonej ekspozycji trwały efekt zamknięcia na wynik operatora pozostawał po pełnym kontrolowaniu `N(T)` i przyszłej `μ_t`; gdyby zamknięcie systematycznie nie wpływało na wyjście, ekspozycję ani adaptację; albo gdyby kluczowe twierdzenia były zależne od jednego algorytmu i znikały w zamrożonym challenge set.

## Wniosek

„Kasyno wygrywa zawsze” jest defensywnym skrótem asymptotycznej przewagi warunkowej, a nie literalnego zwycięstwa w każdym szeregu. „Oczy szeroko zamknięte są” jest nazwą dla kosztownej bezwładności aktualizacji, nie dla samej koncentracji. Ich połączenie jest prawdziwe warunkowo: zamknięcie może przedłużyć pobyt agenta w systemie, ale nie tworzy przewagi operatora z niczego.

---

# 11. Ograniczenia

Badanie jest syntetyczne. Model kontynuacji upraszcza informację, pamięć, dobrostan i interakcję społeczną. Parametry nie są estymatami populacji ludzkiej. ExtraTrees służy do screeningu, nie identyfikacji przyczynowej. Nie wykonano niezależnej implementacji drugiego zespołu. Przegląd literatury jest ustrukturyzowaną mapą, a nie pełnym PRISMA. Nie zwalidowano progów binarnego `CLOSE`. Nie wykonano nowych badań ludzi, neuroobrazowania ani pomiarów fizjologicznych. Z tego powodu teoria biologiczna pozostaje otwarta.

---

# 12. Program dalszych badań

Następny etap obliczeniowy powinien wprowadzić adaptacyjną przewagę `μ_t`, heterogeniczne funkcje użyteczności, operatora uczącego się cech agenta, jawny model hipotez `HS`, oddzielny kanał obserwacji kontrfaktu oraz niezależną reimplementację. Etap empiryczny wymaga prerejestrowanego eksperymentu ludzkiego ze zmianą reżimu, pomiarem deklarowanej pewności, testem dewaluacji wyniku, realną możliwością wyjścia i wcześniejszym ustaleniem progów `CLOSE`. Nie wolno wyznaczać 200 prób jako granicy; liczba ekspozycji powinna być zmienną ciągłą i podlegać analizie punktów zmiany.

---

# 13. Bibliografia

[1] Kelly JL. A New Interpretation of Information Rate. *Bell System Technical Journal*. 1956;35(4):917–926. DOI: https://doi.org/10.1002/j.1538-7305.1956.tb03809.x

[2] Williams D. *Probability with Martingales*. Cambridge University Press; 1991. ISBN 9780521406055.

[3] Sutton RS, Barto AG. *Reinforcement Learning: An Introduction*. 2nd ed. MIT Press; 2018.

[4] Schultz W, Dayan P, Montague PR. A Neural Substrate of Prediction and Reward. *Science*. 1997;275(5306):1593–1599. DOI: https://doi.org/10.1126/science.275.5306.1593

[5] Steinberg EE, Keiflin R, Boivin JR, Witten IB, Deisseroth K, Janak PH. A causal link between prediction errors, dopamine neurons and learning. *Nature Neuroscience*. 2013;16:966–973. DOI: https://doi.org/10.1038/nn.3413

[6] Daw ND, Gershman SJ, Seymour B, Dayan P, Dolan RJ. Model-Based Influences on Humans’ Choices and Striatal Prediction Errors. *Neuron*. 2011;69(6):1204–1215. DOI: https://doi.org/10.1016/j.neuron.2011.02.027

[7] Balleine BW, O’Doherty JP. Human and Rodent Homologies in Action Control. *Neuropsychopharmacology*. 2010;35:48–69. DOI: https://doi.org/10.1038/npp.2009.131

[8] Greenstreet F, Martinez Vergara H, Johansson Y, et al. Dopaminergic action prediction errors serve as a value-free teaching signal. *Nature*. 2025;643:1333–1342. DOI: https://doi.org/10.1038/s41586-025-09008-9

[9] Bakhurin KI, et al. Dopamine dynamics during stimulus-reward learning in mice can be explained by performance rather than learning. *Nature Communications*. 2025. DOI: https://doi.org/10.1038/s41467-025-64132-4

[10] Perez OD, Urcelay GP. Delayed rewards weaken human goal directed actions. *npj Science of Learning*. 2025;10:36. DOI: https://doi.org/10.1038/s41539-025-00325-2

[11] Moore S, Wang Z, Zhu Z, et al. Revealing abrupt transitions from goal-directed to habitual behavior. *Nature Communications*. 2026;17:4751. DOI: https://doi.org/10.1038/s41467-026-71048-0

[12] Rahnev DA, Maniscalco B, Luber B, Lau H, Lisanby SH. Direct injection of noise to the visual cortex decreases accuracy but increases decision confidence. *Journal of Neurophysiology*. 2012;107(6):1556–1563. DOI: https://doi.org/10.1152/jn.00985.2011

[13] Lebreton M, Bacily K, Palminteri S, Engelmann JB. Two sides of the same coin: monetary incentives concurrently improve and bias confidence judgments. *Science Advances*. 2018;4:eaaq0668. DOI: https://doi.org/10.1126/sciadv.aaq0668

[14] Lebreton M, Langdon S, Slieker MJ, Nooitgedacht JS, Goudriaan AE, Denys D, Holst RJ. Contextual influence on confidence judgments in human reinforcement learning. *PLOS Computational Biology*. 2019;15:e1006973. DOI: https://doi.org/10.1371/journal.pcbi.1006973

[15] Clark L, Lawrence AJ, Astley-Jones F, Gray N. Gambling near-misses enhance motivation to gamble and recruit win-related brain circuitry. *Neuron*. 2009;61(3):481–490. DOI: https://doi.org/10.1016/j.neuron.2008.12.031

[16] Thrailkill EA. Partial reinforcement extinction and omission effects in the rat. *Journal of Experimental Psychology: Animal Learning and Cognition*. 2023. DOI: https://doi.org/10.1037/xan0000354

[17] Hopfgartner N, Auer M, Santos T, Helic D, Griffiths MD. The Effect of Mandatory Play Breaks on Subsequent Gambling Behavior. *Journal of Gambling Studies*. 2022;38:737–752. DOI: https://doi.org/10.1007/s10899-021-10078-3

[18] Auer M, Griffiths MD. An Empirical Investigation of Theoretical Loss and Gambling Intensity. *Journal of Gambling Studies*. 2014. DOI: https://doi.org/10.1007/s10899-013-9376-7

[19] Lindström B, Bellander M, Schultner DT, et al. A computational reward learning account of social media engagement. *Nature Communications*. 2021;12:1311. DOI: https://doi.org/10.1038/s41467-020-19607-x

[20] Khambatta P, Mariadassou S, Morris J, Wheeler SC. Tailoring recommendation algorithms to ideal preferences makes users better off. *Scientific Reports*. 2023;13:9325. DOI: https://doi.org/10.1038/s41598-023-34192-x

[21] Nyhan B, Settle J, Thorson E, et al. Like-minded sources on Facebook are prevalent but not polarizing. *Nature*. 2023;620:137–144. DOI: https://doi.org/10.1038/s41586-023-06297-w

[22] Gauthier G, Hodler R, Widmer P, Zhuravskaya E. The political effects of X’s feed algorithm. *Nature*. 2026;652:416–423. DOI: https://doi.org/10.1038/s41586-026-10098-2

[23] Morris TP, White IR, Crowther MJ. Using simulation studies to evaluate statistical methods. *Statistics in Medicine*. 2019;38:2074–2102. DOI: https://doi.org/10.1002/sim.8086

[24] Grimm V, Railsback SF, Vincenot CE, et al. The ODD Protocol for Describing Agent-Based and Other Simulation Models. *JASSS*. 2020;23(2):7. DOI: https://doi.org/10.18564/jasss.4259

[25] Page MJ, McKenzie JE, Bossuyt PM, et al. The PRISMA 2020 statement. *BMJ*. 2021;372:n71. DOI: https://doi.org/10.1136/bmj.n71

[26] Koehler E, Brown E, Haneuse S. On the Assessment of Monte Carlo Error in Simulation-Based Statistical Analyses. *The American Statistician*. 2009;63(2):155–162. DOI: https://doi.org/10.1198/tast.2009.0030

[27] Van Calster B, McLernon DJ, van Smeden M, Wynants L, Steyerberg EW. Calibration: the Achilles heel of predictive analytics. *BMC Medicine*. 2019;17:230. DOI: https://doi.org/10.1186/s12916-019-1466-7

---

# 14. Ostateczny format wniosku

```text
PEWNIKI FORMALNE:
1. Przy dodatnim warunkowym dryfie, N(T)→∞ i warunkach SLLN
   średni wynik operatora na ekspozycję jest dodatni,
   a P(Sᴼ(T)>0)→1.
2. Bezwarunkowe E[X]>0 nie wystarcza przy selektywnej ekspozycji.
3. Żaden przewidywalny dodatni system stawkowania nie odwraca
   jednostkowego ujemnego dryfu gry.
4. Dla softmax przy stałych Q: dH/dβ=−βVarπ(Q)≤0.
5. Przy stałej przewadze: E[Sᴼ(T)]=μE[N(T)].

NIEZMIENNIKI MODELU:
Nie przyznano pełnego P2, ponieważ nie wykonano niezależnej
reimplementacji przez drugi zespół. Uzyskano zgodność rozwiązań
analitycznych, Monte Carlo, testów właściwości i niezależnych partii RNG.

WYNIKI ODPORNE SYMULACYJNIE:
1. 18/18 klas challenge set przeszło po adjudykacji.
2. Przy μ=0 nawet różnica ekspozycji >407 nie tworzyła
   systematycznego oczekiwanego zysku pieniężnego.
3. Przy μ<0 wszystkie scenariusze dawały ujemny średni wynik operatora.
4. Niska entropia była adaptacyjna w środowisku stacjonarnym,
   lecz mogła generować regret po zmianie reżimu.
5. Błędnie wyspecyfikowany agent model-based mógł adaptować się
   gorzej niż prostsze algorytmy.

NAJSILNIEJSZE REGULARNOŚCI EMPIRYCZNE:
1. Zachowanie może być aktualizowane przez sygnały wyniku,
   błędu predykcji oraz powtarzania działania.
2. Opóźnienie skutków może osłabiać kontrolę celową.
3. Pewność i trafność mogą się rozchodzić.
4. Nagrody społeczne i algorytmy mogą zmieniać zaangażowanie,
   lecz skutki dla przekonań i dobrostanu są heterogeniczne.

TWIERDZENIA POMOSTOWE:
B1 — częściowe wsparcie kierunkowe, brak mapowania jeden-do-jednego.
B2 — niewykazane: proxy modelowe ≠ subiektywna pewność.
B3 — częściowe wsparcie konstrukcyjne, brak kalibracji skali.
B4 — częściowe wsparcie domenowe, duża heterogeniczność operatorów.
B5 — odrzucone jako uniwersalne: zysk operatora ≠ zawsze strata agenta.

HIPOTEZY OTWARTE:
1. Czy zwalidowany wielowymiarowy CLOSE przewiduje zachowanie ludzi?
2. Czy adaptacyjny operator tworzy sprzężenie μ_t×N(T)
   silniejsze niż stała przewaga?
3. Jakie interwencje zmniejszają regret netto bez usuwania
   prawidłowej specjalizacji?

TWIERDZENIA ODRZUCONE:
1. T=200 jest uniwersalnym progiem biologicznym.
2. Zamknięcie samo tworzy przewagę operatora.
3. Niska entropia jest automatycznie patologiczna.
4. Model-based jest zawsze odporniejszy.
5. Martingale usuwa ujemną wartość oczekiwaną.
6. Dopamina jest prostym przyciskiem przyjemności lub nagrody.
7. Zysk operatora jest zawsze stratą agenta.

MODUŁ M0 — WERDYKT:
Silnie wsparty formalnie i obliczeniowo; P1/P3.

MODUŁ M1 — WERDYKT:
Warunkowo wsparty w DGM i częściowo empirycznie; P3 z ograniczoną
trafnością zewnętrzną.

MODUŁ M2 — WERDYKT:
Wsparty jako konstrukt algorytmiczny oparty na regrecie i adaptacji;
biologiczny most pozostaje P5.

MODUŁ M3 — WERDYKT:
Wsparty jako warunkowe sprzężenie przez ekspozycję, przyszłą przewagę
lub opóźnienie adaptacji; nie jako uniwersalne prawo psychologiczne.

OSTATECZNA TEORIA:
Dodatnia przewaga operatora nie wymaga zamknięcia agenta.
Zamknięcie agenta nie gwarantuje przewagi operatora.
Gdy jednak zamknięcie zwiększa ekspozycję lub opóźnia wyjście,
a operator zachowuje dodatnią przewagę warunkową,
tempo kumulacji wyniku operatora rośnie zgodnie z E[Σe_tμ_t].

WARUNKI OBOWIĄZYWANIA:
Jawna definicja ekspozycji, użyteczności i przewagi; poprawne
warunkowanie względem selekcji; rosnący horyzont; kontrola wyjścia,
stawkowania, zależności czasowej i zmiany reżimu.

WARUNKI FALSYFIKACJI:
Trwały efekt zamknięcia na wynik operatora po pełnym usunięciu wpływu
na N(T), μ_t, adaptację i inne użyteczności; brak wpływu M2 na wyjście
lub adaptację; niestabilność znaku w zamrożonym challenge set.

OGRANICZENIA UOGÓLNIENIA BIOLOGICZNEGO:
Brak nowych eksperymentów, brak walidacji entropii jako percepcji,
brak biologicznego progu 200, brak podstaw do różnic płciowych
lub nieodwracalnego zamknięcia mózgu.

WERDYKT OGÓLNY:
B — istnieje warunkowa teoria formalno-obliczeniowa o ograniczonym
zakresie i częściowym wsparciu empirycznym.
```

---

<a id="repozytorium-i-reprodukcja"></a>
# 15. Repozytorium i reprodukcja

<a id="struktura-repozytorium"></a>
## 15.1. Struktura repozytorium

```text
.
├── README.md
├── WRITEUP.md                         # ten dokument: narracyjny punkt wejścia
├── report.md                          # zamrożony raport techniczny 1.1.0
├── CHANGELOG.md
├── LICENSE
├── Dockerfile
├── pyproject.toml
├── requirements.txt
├── requirements-lock.txt
├── checksums.sha256                   # sumy kontrolne artefaktów źródłowych
├── WRITEUP.sha256                     # suma kontrolna niniejszego write-upu
├── experiment_manifest.json
├── seeds_manifest.csv
├── configs/
│   └── config.yaml
├── claims/
│   └── claim_registry.csv
├── data/
│   └── data_dictionary.md
├── docs/
│   ├── methodology.md
│   ├── preregistration.md
│   ├── preregistration.sha256
│   ├── source_prompt_v2.md
│   └── ODD/
│       ├── exposure_model.md
│       └── reversal_bandit.md
├── figures/
│   └── *.png                          # osiem wykresów wynikowych
├── literature/
│   ├── evidence_map.csv
│   ├── evidence_map.md
│   └── search_log.md
├── results/
│   ├── aggregated/                    # wyniki zagregowane CSV/JSON
│   └── audit_samples/                 # próbki audytowe i logi testów
├── src/
│   ├── models.py
│   ├── run_study.py
│   ├── adjudicate_fair_game.py
│   ├── run_supplemental_challenges.py
│   ├── independent_crosscheck.py
│   └── finalize_package.py
└── tests/
    └── test_models.py
```

Oryginalny plik [`checksums.sha256`](checksums.sha256) obejmuje artefakty pakietu badawczego 1.1.0. Dodanie `WRITEUP.md` nie zmienia żadnego z tych artefaktów. Osobny plik `WRITEUP.sha256` identyfikuje niniejszy dokument.

<a id="reprodukcja-krok-po-kroku"></a>
## 15.2. Reprodukcja krok po kroku

### Wariant lokalny

```bash
python -m venv .venv
source .venv/bin/activate            # Windows: .venv\Scripts\activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

python src/run_study.py --config configs/config.yaml
python src/adjudicate_fair_game.py
python src/run_supplemental_challenges.py
python src/finalize_package.py
pytest -q
sha256sum -c checksums.sha256
```

Kolejność ma znaczenie. `run_study.py` generuje rdzeń wyników, `adjudicate_fair_game.py` rozstrzyga grę uczciwą w niezależnych partiach, `run_supplemental_challenges.py` tworzy testy ujemnej przewagi i niezerowej sumy, a `finalize_package.py` scala werdykt i manifest. `pytest -q` sprawdza właściwości implementacji. Weryfikacja sum kontrolnych dotyczy zamrożonego pakietu źródłowego.

### Wariant kontenerowy

```bash
docker build -t oczy-kasyno-study:1.1.0 .
docker run --rm -it oczy-kasyno-study:1.1.0
```

Dokładne zachowanie obrazu zależy od zawartości `Dockerfile`; przed publikacją produkcyjną należy dodatkowo przypiąć digest obrazu bazowego. Pakiet zawiera wersje zależności w [`requirements-lock.txt`](requirements-lock.txt), lecz manifest nie przechowuje identyfikatora commitu Git. W tej wersji źródłem identyfikacji są wersja `1.1.0`, hashe prerejestracji, plik sum kontrolnych i manifest eksperymentu. Brak commitu jest luką metadanych, nie podstawą do unieważnienia uzyskanych rezultatów.

<a id="oczekiwane-artefakty"></a>
## 15.3. Oczekiwane artefakty po uruchomieniu

Po pełnym przebiegu powinny istnieć co najmniej:

```text
results/aggregated/study_summary_final.json
results/aggregated/challenge_set_results_final.csv
results/aggregated/house_edge.csv
results/aggregated/house_edge_thresholds.csv
results/aggregated/gambler_ruin.csv
results/aggregated/exposure_screening_results.csv
results/aggregated/exposure_confirmatory_results.csv
results/aggregated/fair_game_adjudication_summary.json
results/aggregated/negative_edge_challenge.csv
results/aggregated/utility_class_counterexamples.csv
results/aggregated/bandit_metrics.csv
results/aggregated/bandit_timeseries.csv
results/audit_samples/pytest_output_final.txt
experiment_manifest.json
figures/*.png
```

Za prawidłowy wynik nie należy uznawać wyłącznie zgodności końcowego werdyktu literowego. Należy sprawdzić liczby pośrednie, `MCSE`, znaki efektów, adjudykację gry uczciwej, status testów oraz zgodność sum kontrolnych.

<a id="środowisko-wykonawcze"></a>
## 15.4. Zarejestrowane środowisko wykonawcze

| Pole | Wartość |
|---|---|
| Python | `3.13.5` |
| Platforma | `Linux-6.18.35-x86_64-with-glibc2.41` |
| Master seed | `20260806` |
| Czas rdzeniowego wykonania | `19.926 s` |
| Testy początkowe | `6 passed in 0.69s` |
| Testy po finalizacji | `6 passed in 0.67s` |
| Finalizacja UTC | `2026-08-06T10:29:40.697070+00:00` |

Czas wykonania jest metryką maszyny i implementacji, nie właściwością teorii. Nie powinien być używany do porównania jakości metod bez kontroli sprzętu, wersji bibliotek i liczby wątków.

<a id="hierarchia-losowości"></a>
## 15.5. Losowość i identyfikowalność

Konfiguracja wykorzystuje master seed `20260806`; szczegółowe identyfikatory znajdują się w [`seeds_manifest.csv`](seeds_manifest.csv). W porównaniach parowanych stosowane są wspólne strumienie losowe, aby zmniejszyć wariancję różnic. Niezależna adjudykacja gry uczciwej używa nowych partii RNG i nie jest ponownym odczytaniem tego samego przebiegu.

Przy ponownej implementacji w innym języku nie należy oczekiwać identycznych bitowo trajektorii, chyba że zostanie odtworzony ten sam generator i sposób konsumowania strumienia. Kryterium niezależnej reimplementacji powinno dotyczyć odzyskania rozwiązań analitycznych, rozkładów i efektów w tolerancji statystycznej, nie identyczności każdej liczby pseudolosowej.

---

<a id="wyniki-w-formie-dashboardu"></a>
# 16. Wyniki w formie dashboardu audytowego

## 16.1. M0 — liczby kontrolne

| Test kontrolny | Wynik |
|---|---:|
| `P(Sᴼ>0)` dla `μ=0`, `T=5000` | `0.494358` |
| `P(Sᴼ>0)` dla `μ=0.005`, `T=200` | `0.500047` |
| `P(Sᴼ>0)` dla `μ=0.02`, `T=200` | `0.584157` |
| `P(Sᴼ>0)` dla `μ=0.05`, `T=200` | `0.738178` |
| Minimalne `T` dla `μ=0.005`, `P≥0.95` | `108221` |
| Minimalne `T` dla `μ=0.02`, `P≥0.95` | `6763` |
| Ruina stałej stawki do `T=5000` | `0.970871` |
| Ruina Martingale z limitem 16 do `T=5000` | `0.987467` |
| Ruina benchmarku „nie gram” | `0` |

Te liczby pełnią funkcję testów regresyjnych dla przyszłych wersji. Niewielkie różnice Monte Carlo są dopuszczalne w granicach zadeklarowanej precyzji; wartości dokładne powinny pozostać zgodne.

## 16.2. M1 — skrajne scenariusze konfirmacyjne

| `μ` | Warunek | `E[N]` | `E[Sᴼ]` | `μE[N]` | Koncentracja | Błąd aktualizacji |
|---:|---|---:|---:|---:|---:|---:|
| `0.02` | pełne ważenie strat, szybka aktualizacja, brak kosztu wyjścia | `5.4156` | `0.0680` | `0.1083` | `0.5799` | `0.0935` |
| `0.02` | niedoważanie strat, wolna aktualizacja, koszt wyjścia | `471.8014` | `9.3383` | `9.4360` | `0.9970` | `0.3748` |
| `0.05` | pełne ważenie strat, szybka aktualizacja, brak kosztu wyjścia | `4.9919` | `0.2620` | `0.2496` | `0.5670` | `0.0882` |
| `0.05` | niedoważanie strat, wolna aktualizacja, koszt wyjścia | `462.5103` | `23.0649` | `23.1255` | `0.9961` | `0.3839` |

Nie należy interpretować tych skrajności jako estymat populacyjnych dla ludzi. Są testami mechanizmu w jawnie zdefiniowanym DGM.

## 16.3. M2 — adaptacja po zmianie reżimu

| Agent | Regret po zmianie | Entropia | Brier | Opóźnienie adaptacji | Brak adaptacji |
|---|---:|---:|---:|---:|---:|
| `oracle` | `0.00000` | `0.00000` | `0.16004` | `20.00` | `0.00000` |
| `cue_informed` | `0.00001` | `0.00012` | `0.16203` | `20.00` | `0.00000` |
| `softmax_flexible` | `0.06365` | `0.23570` | `0.18835` | `28.15` | `0.00000` |
| `epsilon_q` | `0.07515` | `0.19852` | `0.18477` | `33.37` | `0.00000` |
| `softmax_rigid` | `0.08967` | `0.10371` | `0.19795` | `48.12` | `0.00000` |
| `bayes_discounted` | `0.13175` | `0.11691` | `0.20013` | `57.50` | `0.00000` |
| `random` | `0.29998` | `0.69315` | `0.25000` | `178.09` | `0.76417` |
| `bayes_stationary` | `0.52875` | `0.11732` | `0.33059` | `186.46` | `0.70350` |

Tabela pokazuje, dlaczego ani niska, ani wysoka entropia nie są samowystarczalną miarą elastyczności. `random` ma maksymalną entropię i słaby wynik; `oracle` ma minimalną entropię i wynik optymalny; `bayes_stationary` ma niską entropię, lecz ogromny koszt błędnej specyfikacji.

## 16.4. M3 — testy znaku przewagi

| Warunek | Zakres ekspozycji | Wynik operatora | Wniosek |
|---|---:|---:|---|
| `μ>0` | zmienny | dodatni średnio, zgodny z `μE[N]` | ekspozycja wzmacnia istniejącą przewagę |
| `μ=0` | różnice do `407.4` ekspozycji | brak systematycznego zysku | ekspozycja nie tworzy przewagi pieniężnej |
| `μ=-0.02` | `5.7–479.5` | `-9.527…-0.098` | ekspozycja pogarsza wynik operatora |
| U3 | zmienny | dodatnia użyteczność obu stron | zysk nie wymaga straty agenta |
| U5 | zmienny | wartość uwagi operatora, użyteczność agenta `0` | cele operatora i koszt agenta są odrębne |

---

<a id="pełny-rejestr-twierdzeń"></a>
# 17. Pełny rejestr twierdzeń

Poniższa tabela jest widokiem repozytoryjnego pliku [`claims/claim_registry.csv`](claims/claim_registry.csv). Status nie jest jednowymiarowym „wynikiem wiarygodności”. Twierdzenie może być formalnie `P1`, obliczeniowo `P3`, a jako opis człowieka nadal `P5`.

| Moduł   | Status   |   Liczba |
|:--------|:---------|---------:|
| M0      | P1       |        3 |
| M0      | P1/P3    |        2 |
| M1      | P3       |        1 |
| M1      | P3/P4    |        1 |
| M2      | P1/P3    |        1 |
| M2      | P3       |        2 |
| M2      | P3/P4    |        1 |
| M3      | P1/P3    |        4 |
| bridge  | P5       |        4 |
| bridge  | P6       |        2 |

<details>
<summary><strong>Rozwiń wszystkie 21 twierdzeń</strong></summary>

| ID        | Moduł   | Status   | Twierdzenie                                                                                                                                                    | Wynik                          | Odporność                 | Trafność zewnętrzna                       | Ograniczenia                                                                 |
|:----------|:--------|:---------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------|:--------------------------|:------------------------------------------|:-----------------------------------------------------------------------------|
| C-M0-1    | M0      | P1       | Przy dodatnim warunkowym dryfie, rosnącej liczbie ekspozycji i warunkach martyngałowego SLLN średni wynik operatora na ekspozycję jest asymptotycznie dodatni. | wsparty                        | wysoka przy założeniach   | zależna od spełnienia założeń             | nie oznacza wygranej w każdej rundzie ani każdym skończonym szeregu          |
| C-M0-2    | M0      | P1       | Sama bezwarunkowa dodatnia wartość oczekiwana nie wystarcza przy selektywnej ekspozycji.                                                                       | wsparty                        | wysoka                    | formalna                                  | kontrprzykład wyznacza granicę twierdzenia                                   |
| C-M0-3    | M0      | P1/P3    | Przy stałej dodatniej przewadze iid P(S_T>0) rośnie do 1, ale dla każdego skończonego T pozostaje mniejsze od 1.                                               | wsparty                        | wysoka                    | ograniczona do DGM                        | stała przewaga, niezależność                                                 |
| C-M0-4    | M0      | P1/P3    | Ruina jest twierdzeniem warunkowym: zależy od minimalnej stawki, nieskończonej ekspozycji, dopływów, wyjścia i definicji ruiny.                                | wsparty                        | wysoka w modelu           | ograniczona                               | strategie proporcjonalne mogą unikać literalnego zera przy spadku dobrostanu |
| C-M0-5    | M0      | P1       | Żaden przewidywalny dodatni system stawkowania nie odwraca znaku jednostkowego ujemnego dryfu gry.                                                             | wsparty                        | wysoka                    | formalna                                  | nie obejmuje zmiany samej gry lub informacji dającej przewagę graczowi       |
| C-M1-1    | M1      | P3       | W syntetycznym modelu lokalna percepcja strat, tempo aktualizacji, temperatura i koszt wyjścia silnie zmieniają liczbę ekspozycji.                             | wsparty                        | wysoka w badanym zakresie | ograniczona                               | ważności ExtraTrees są eksploracyjne i in-sample                             |
| C-M1-2    | M1      | P3/P4    | Ujawnienie wartości oczekiwanej może zmniejszać ekspozycję, lecz efekt jest heterogeniczny i zależy od DGM.                                                    | warunkowo wsparty              | średnia                   | częściowa                                 | nie jest uniwersalną gwarancją skuteczności                                  |
| C-M2-1    | M2      | P1/P3    | Niska entropia polityki nie jest ani konieczna, ani wystarczająca dla błędnego zamknięcia.                                                                     | wsparty                        | wysoka w DGM              | brak bez mostu B1                         | entropia nie jest biologiczną percepcją                                      |
| C-M2-2    | M2      | P3       | Błędne zamknięcie wymaga kosztu lub regretu oraz niewłaściwej aktualizacji/adaptacji, a nie samej koncentracji.                                                | wsparty                        | wysoka w DGM              | ograniczona                               | progi CLOSE nie zostały zwalidowane biologicznie                             |
| C-M2-3    | M2      | P3       | Model-based z błędnym modelem może adaptować się gorzej niż prostszy agent model-free.                                                                         | wsparty                        | wysoka w DGM              | ograniczona                               | wynik zależy od rodzaju błędnej specyfikacji                                 |
| C-M2-4    | M2      | P3/P4    | Modelowy proxy pewności może rosnąć, gdy jakość predykcji się pogarsza.                                                                                        | wsparty warunkowo              | średnio-wysoka            | częściowa                                 | value-gap nie jest deklarowaną pewnością człowieka                           |
| C-M3-1    | M3      | P1/P3    | W rdzeniowym DGM ze stałą przewagą E[S_O(T)]=μE[N(T)].                                                                                                         | wsparty                        | wysoka w DGM              | ograniczona                               | adaptacyjna μ_t i niezerowa suma wymagają rozszerzenia                       |
| C-M3-2    | M3      | P1/P3    | Zamknięcie nie jest konieczne do zysku operatora; może jedynie wzmacniać wynik, gdy zwiększa N(T), opóźnia wyjście lub koreluje z dodatnią μ_t.                | wsparty                        | wysoka w klasie modeli    | ograniczona                               | brak pełnej walidacji platformowej                                           |
| C-M3-3    | M3      | P1/P3    | Przy μ=0 sama ekspozycja nie tworzy oczekiwanego zysku pieniężnego; przy μ<0 większa ekspozycja pogarsza wynik operatora.                                      | wsparty                        | wysoka                    | ograniczona do zdefiniowanej użyteczności | operator może mieć inną dodatnią użyteczność z uwagi                         |
| C-U-1     | M3      | P1/P3    | Zysk operatora nie jest automatycznie stratą agenta.                                                                                                           | wsparty                        | wysoka formalnie          | szeroka konceptualnie                     | w realnej domenie użyteczności trzeba mierzyć osobno                         |
| C-B1      | bridge  | P5       | Koncentracja polityki syntetycznej odpowiada biologicznemu nawykowi.                                                                                           | częściowo wspierane kierunkowo | niska                     | ograniczona                               | wymaga walidacji zbieżnej, kryterialnej i różnicowej                         |
| C-B2      | bridge  | P5       | Value-gap lub entropia jest miarą subiektywnej pewności człowieka.                                                                                             | niewykazane                    | niska                     | brak                                      | literatura potwierdza jedynie możliwość dysocjacji pewność–trafność          |
| C-B3      | bridge  | P5       | Modelowe adaptation delay odpowiada empirycznej sztywności/reversal learning.                                                                                  | częściowo wspierane            | średnia                   | ograniczona                               | brak kalibracji skali kroków do zachowania ludzkiego                         |
| C-B4      | bridge  | P5       | Operator syntetyczny reprezentuje rzeczywiste platformy i gry.                                                                                                 | częściowo wspierane            | średnia                   | heterogeniczna                            | platformy różnią się celami, interfejsem i użytecznością                     |
| C-B5      | bridge  | P6       | Wynik operatora jest tożsamy ze spadkiem dobrostanu agenta.                                                                                                    | odrzucone jako uniwersalne     | wysoka                    | szeroka                                   | możliwe U3 i U5                                                              |
| C-BIO-200 | bridge  | P6       | Dwieście ekspozycji stanowi biologiczny próg nieodwracalnego zamknięcia.                                                                                       | odrzucone jako uniwersalne     | wysoka negatywna ocena    | nie dotyczy                               | T=200 jest wyłącznie kotwicą obserwacyjną                                    |

</details>

### Interpretacja statusów

```text
P1 — twierdzenie formalnie dowiedzione przy jawnych założeniach;
P2 — niezmiennik potwierdzony w niezależnych implementacjach;
P3 — wynik symulacyjny odporny na analizę wrażliwości;
P4 — silna regularność empiryczna wsparta wieloma źródłami;
P5 — hipoteza prawdopodobna, lecz otwarta;
P6 — metafora, analogia albo twierdzenie bez wystarczającego wsparcia.
```

Pełnego `P2` nie nadano, ponieważ skrypt [`independent_crosscheck.py`](src/independent_crosscheck.py) stanowi kontrolę wewnątrz tego samego pakietu, a nie niezależną reimplementację przez drugi zespół w innym stosie. To rozróżnienie jest celowe i powinno zostać zachowane w kolejnych wersjach.

---

<a id="pełna-inwentaryzacja-źródeł"></a>
# 18. Pełna inwentaryzacja źródeł

Mapa ma charakter **ustrukturyzowanego przeglądu zakresowego**, nie pełnego przeglądu systematycznego. Dane źródłowe znajdują się w [`literature/evidence_map.csv`](literature/evidence_map.csv), a procedura w [`literature/search_log.md`](literature/search_log.md).

| Domena                     |   Liczba źródeł |   Najwcześniejsze |   Najnowsze |
|:---------------------------|----------------:|------------------:|------------:|
| D1 formalna probabilistyka |               2 |              1956 |        1991 |
| D2 reinforcement learning  |               5 |              1997 |        2025 |
| D3 nawyk i kontrola celowa |               3 |              2010 |        2026 |
| D4 kalibracja              |               1 |              2019 |        2019 |
| D4 pewność i kalibracja    |               3 |              2012 |        2019 |
| D5 hazard i ekspozycja     |               1 |              2014 |        2014 |
| D5 hazard i interwencje    |               1 |              2022 |        2022 |
| D5 hazard i wzmocnienia    |               2 |              2009 |        2023 |
| D6 platformy i operator    |               4 |              2021 |        2026 |
| Metody                     |               4 |              2009 |        2021 |

<details>
<summary><strong>Rozwiń wszystkie 26 źródeł kotwiczących</strong></summary>

| ID      | Domena                     |   Rok | Źródło                                                                                                                             | Projekt                                             | Próba                                        | Rola w teorii                                                                                 | Siła                           | Ograniczenia                                                                 | DOI / identyfikator                |
|:--------|:---------------------------|------:|:-----------------------------------------------------------------------------------------------------------------------------------|:----------------------------------------------------|:---------------------------------------------|:----------------------------------------------------------------------------------------------|:-------------------------------|:-----------------------------------------------------------------------------|:-----------------------------------|
| D1-01   | D1 formalna probabilistyka |  1956 | Kelly JL. A New Interpretation of Information Rate.                                                                                | twierdzenie formalne / wzrost logarytmiczny         | nie dotyczy                                  | benchmark A0: nie uczestniczę                                                                 | wysoka formalnie               | nie jest teorią zachowania biologicznego                                     | 10.1002/j.1538-7305.1956.tb03809.x |
| D1-02   | D1 formalna probabilistyka |  1991 | Williams D. Probability with Martingales.                                                                                          | monografia formalna                                 | nie dotyczy                                  | podstawa twierdzenia M0                                                                       | wysoka formalnie               | prawdziwość w świecie zależy od spełnienia założeń                           | ISBN 9780521406055                 |
| D2-01   | D2 reinforcement learning  |  1997 | Schultz W, Dayan P, Montague PR. A Neural Substrate of Prediction and Reward.                                                      | neurofizjologia zwierząt                            | zadania warunkowania                         | kotwica dla modelu uczenia przez błąd predykcji                                               | wysoka, klasyczna              | nie redukuje całej funkcji dopaminy do jednego sygnału                       | 10.1126/science.275.5306.1593      |
| D2-02   | D2 reinforcement learning  |  2013 | Steinberg EE et al. A causal link between prediction errors, dopamine neurons and learning.                                        | manipulacja optogenetyczna                          | gryzonie                                     | wspiera przyczynową rolę sygnałów predykcyjnych                                               | wysoka w zadaniu               | specyficzne zadanie i gatunek                                                | 10.1038/nn.3413                    |
| D2-03   | D2 reinforcement learning  |  2011 | Daw ND et al. Model-Based Influences on Humans' Choices and Striatal Prediction Errors.                                            | eksperyment człowiek + fMRI + model obliczeniowy    | zadanie dwuetapowe                           | uzasadnia porównanie agentów o różnych reprezentacjach                                        | wysoka, wielokrotnie rozwijana | identyfikacja strategii zależy od modelu zadania                             | 10.1016/j.neuron.2011.02.027       |
| D2-04   | D2 reinforcement learning  |  2025 | Greenstreet F et al. Dopaminergic action prediction errors serve as a value-free teaching signal.                                  | myszy; modelowanie i manipulacje przyczynowe        | wiele kohort zadaniowych                     | wspiera rozdzielenie powtarzania od wartości                                                  | wysoka w zadaniu               | nie jest bezpośrednim modelem ludzkiej świadomości                           | 10.1038/s41586-025-09008-9         |
| D2-05   | D2 reinforcement learning  |  2025 | Bakhurin KI et al. Dopamine dynamics during stimulus-reward learning in mice can be explained by performance rather than learning. | myszy; optogenetyka i analiza dynamiki              | zadanie bodziec–nagroda                      | falsyfikator redukcji dopaminy do jednego mechanizmu                                          | wysoka w zadaniu               | spór interpretacyjny nie jest zamknięty                                      | 10.1038/s41467-025-64132-4         |
| D3-01   | D3 nawyk i kontrola celowa |  2010 | Balleine BW, O'Doherty JP. Human and Rodent Homologies in Action Control.                                                          | przegląd integracyjny                               | literatura ludzka i zwierzęca                | podstawa rozdzielenia specjalizacji od błędnego zamknięcia                                    | wysoka przeglądowo             | homologie nie są tożsamością mechanizmów                                     | 10.1038/npp.2009.131               |
| D3-02   | D3 nawyk i kontrola celowa |  2025 | Perez OD, Urcelay GP. Delayed rewards weaken human goal directed actions.                                                          | 3 eksperymenty ludzkie                              | N=290                                        | empiryczna kotwica opóźnionych kosztów M1/M2                                                  | średnio-wysoka                 | fiktcyjne inwestycje i krótki horyzont                                       | 10.1038/s41539-025-00325-2         |
| D3-03   | D3 nawyk i kontrola celowa |  2026 | Moore S et al. Revealing abrupt transitions from goal-directed to habitual behavior.                                               | samce myszy; HMM-GLM, dewaluacja, lezje, fotometria | wiele sesji; przejście po długim treningu    | wspiera możliwość nieliniowej zmiany, obala uniwersalną trwałość                              | wysoka w paradygmacie          | samce myszy; brak uniwersalnego progu liczby prób                            | 10.1038/s41467-026-71048-0         |
| D4-01   | D4 pewność i kalibracja    |  2012 | Rahnev DA et al. Direct injection of noise to the visual cortex decreases accuracy but increases decision confidence.              | eksperyment ludzki TMS                              | percepcja wzrokowa                           | dowód możliwości rozbieżności pewność–trafność                                                | wysoka dla zjawiska            | nie waliduje value-gap jako pewności                                         | 10.1152/jn.00985.2011              |
| D4-02   | D4 pewność i kalibracja    |  2018 | Lebreton M et al. Two sides of the same coin: monetary incentives concurrently improve and bias confidence judgments.              | eksperymenty ludzkie                                | decyzje percepcyjne                          | wspiera niezależne mierzenie CAL i proxy pewności                                             | średnio-wysoka                 | zadania laboratoryjne                                                        | 10.1126/sciadv.aaq0668             |
| D4-03   | D4 pewność i kalibracja    |  2019 | Lebreton M et al. Contextual influence on confidence judgments in human reinforcement learning.                                    | eksperymenty ludzkie + model RL                     | uczenie wyborów                              | ogranicza interpretację modelowego proxy pewności                                             | średnio-wysoka                 | zależność od modelu i zadania                                                | 10.1371/journal.pcbi.1006973       |
| D4-04   | D4 kalibracja              |  2019 | Van Calster B et al. Calibration: the Achilles heel of predictive analytics.                                                       | przegląd metodologiczny                             | modele prognostyczne                         | uzasadnia pakiet CAL zamiast samego Brier score                                               | wysoka metodologicznie         | dotyczy modeli predykcyjnych, nie subiektywnego doświadczenia                | 10.1186/s12916-019-1466-7          |
| D5-01   | D5 hazard i wzmocnienia    |  2009 | Clark L et al. Gambling near-misses enhance motivation to gamble and recruit win-related brain circuitry.                          | eksperyment ludzki + fMRI                           | symulowana maszyna losowa                    | kotwica bodźców kontynuacyjnych M1                                                            | wysoka dla zadania             | near-miss nie jest uniwersalnym mechanizmem każdej ekspozycji                | 10.1016/j.neuron.2008.12.031       |
| D5-02   | D5 hazard i wzmocnienia    |  2023 | Thrailkill EA. Partial reinforcement extinction and omission effects in the rat.                                                   | 3 eksperymenty zwierzęce                            | szczury                                      | wspiera warunkowość trwałości zachowania                                                      | średnia                        | wynik zależy od harmonogramu i kontekstu; brak prostego prawa variable-ratio | 10.1037/xan0000354                 |
| D5-03   | D5 hazard i interwencje    |  2022 | Hopfgartner N et al. The Effect of Mandatory Play Breaks on Subsequent Gambling Behavior.                                          | randomizowany eksperyment terenowy                  | 21 129 graczy; 156 989 przerw                | interwencje M1 są heterogeniczne i nie gwarantują redukcji kosztu                             | wysoka terenowo                | jeden operator, limity strat, selekcja aktywnych graczy                      | 10.1007/s10899-021-10078-3         |
| D5-04   | D5 hazard i ekspozycja     |  2014 | Auer M, Griffiths MD. An Empirical Investigation of Theoretical Loss and Gambling Intensity.                                       | dane rzeczywiste graczy online                      | 100 000 graczy                               | empiryczna analogia μ × ekspozycja                                                            | średnio-wysoka                 | obserwacyjne dane operatora                                                  | 10.1007/s10899-013-9376-7          |
| D6-01   | D6 platformy i operator    |  2021 | Lindström B et al. A computational reward learning account of social media engagement.                                             | duże dane + eksperyment online                      | >1 mln postów, >4000 osób; eksperyment N=176 | wspiera M1 poza hazardem                                                                      | wysoka wielometodowo           | zaangażowanie nie jest automatycznie szkodą ani zamknięciem                  | 10.1038/s41467-020-19607-x         |
| D6-02   | D6 platformy i operator    |  2023 | Khambatta P et al. Tailoring recommendation algorithms to ideal preferences makes users better off.                                | prerejestrowany eksperyment                         | N=6488                                       | kontrprzykład: mniej ekspozycji nie musi szkodzić operatorowi; zysk operatora ≠ strata agenta | wysoka w zadaniu               | krótkie środowisko eksperymentalne i miary deklaratywne                      | 10.1038/s41598-023-34192-x         |
| D6-03   | D6 platformy i operator    |  2023 | Nyhan B et al. Like-minded sources on Facebook are prevalent but not polarizing.                                                   | wielofalowy eksperyment terenowy                    | N=23 377                                     | falsyfikator prostego łańcucha ekspozycja→zmiana przekonań                                    | wysoka terenowo                | Facebook 2020, ograniczone rezultaty i horyzont                              | 10.1038/s41586-023-06297-w         |
| D6-04   | D6 platformy i operator    |  2026 | Gauthier G et al. The political effects of X's feed algorithm.                                                                     | 7-tygodniowy randomizowany eksperyment terenowy     | do N=4965 zależnie od wyniku                 | pokazuje efekty operatora zależne od platformy i wyniku                                       | wysoka terenowo                | asymetria przełączeń, jedna platforma i okres polityczny                     | 10.1038/s41586-026-10098-2         |
| METH-01 | Metody                     |  2019 | Morris TP, White IR, Crowther MJ. Using simulation studies to evaluate statistical methods.                                        | standard metodologiczny ADEMP                       | nie dotyczy                                  | szkielet projektu                                                                             | wysoka metodologicznie         | nie waliduje konkretnego DGM                                                 | 10.1002/sim.8086                   |
| METH-02 | Metody                     |  2020 | Grimm V et al. The ODD Protocol for Describing Agent-Based and Other Simulation Models.                                            | standard ODD                                        | nie dotyczy                                  | dokumentacja agentów i środowisk                                                              | wysoka metodologicznie         | opis nie zastępuje walidacji                                                 | 10.18564/jasss.4259                |
| METH-03 | Metody                     |  2021 | Page MJ et al. The PRISMA 2020 statement.                                                                                          | wytyczne raportowania przeglądów                    | nie dotyczy                                  | uzasadnia nazwę: ustrukturyzowana mapa dowodów, nie pełny PRISMA                              | wysoka metodologicznie         | nie jest narzędziem oceny jakości pojedynczego badania                       | 10.1136/bmj.n71                    |
| METH-04 | Metody                     |  2009 | Koehler E, Brown E, Haneuse S. On the Assessment of Monte Carlo Error.                                                             | metody błędu Monte Carlo                            | nie dotyczy                                  | MCSE i adjudykacja C12                                                                        | wysoka metodologicznie         | MCSE nie obejmuje błędu specyfikacji modelu                                  | 10.1198/tast.2009.0030             |

</details>

### Jak czytać mapę

Źródła formalne wspierają warunki matematyczne, nie biologiczną trafność DGM. Badania neurobiologiczne i behawioralne wspierają wybrane mechanizmy, ale nie tworzą automatycznie jednego łańcucha przyczynowego. Eksperymenty platformowe pokazują heterogeniczne skutki ekspozycji i algorytmów. Źródła metodologiczne uzasadniają ADEMP, ODD, MCSE i ostrożne nazwanie przeglądu. Żaden z tych bloków nie zastępuje twierdzeń pomostowych `B1–B5`.

---

<a id="zagrożenia-dla-trafności"></a>
# 19. Zagrożenia dla trafności

## 19.1. Trafność formalna

Twierdzenia `M0` są silne wyłącznie przy jawnych warunkach: właściwym warunkowaniu względem historii i ekspozycji, kontroli zależności, skończonych momentach tam, gdzie są wymagane, oraz rosnącej liczbie rzeczywistych ekspozycji. Zastąpienie warunkowego dryfu średnią bezwarunkową może odwrócić wniosek, co pokazuje kontrprzykład selektywnej ekspozycji.

## 19.2. Trafność implementacyjna

Kod przeszedł testy i odzyskał rozwiązania referencyjne, ale pojedyncza implementacja może współdzielić błędy koncepcyjne między modułami. Brak niezależnego portu do drugiego języka lub biblioteki uniemożliwia pełny status `P2`. Najważniejszym krokiem kolejnej wersji powinien być niezależny port minimalnych modeli `M0`, `M1` i reversal bandit.

## 19.3. Trafność konstruktu

`PC`, `CAL`, `AD`, dynamiczny regret i błąd aktualizacji są mierzalne w modelu. Nie są jednak równoznaczne z percepcją, świadomością, wolą, tożsamością ani diagnozą kliniczną. Wektor `ZPD⃗` nie został zredukowany do jednego indeksu, ponieważ jego składniki mogą nie reprezentować jednej zmiennej ukrytej. To jest zaleta metodologiczna, nie brak domknięcia dokumentu.

## 19.4. Trafność zewnętrzna

Model kontynuacja–wyjście, gra `±1` i dwuakcyjny bandyta nie odtwarzają pełnej struktury kasyna, platformy społecznościowej, rynku, relacji społecznej ani biologicznego układu uczenia. Są minimalnymi DGM służącymi identyfikacji mechanizmu. Każda realna aplikacja wymaga osobnego modelu operatora, kosztów, czasu, selekcji, użyteczności i informacji.

## 19.5. Trafność empiryczna

Mapa 26 źródeł jest kotwicą, a nie pełną syntezą całej literatury. Nie wykonano pełnego screeningu PRISMA, oceny ryzyka błędu przez dwóch niezależnych recenzentów ani metaanalizy. Z tego powodu `P4` jest stosowane oszczędnie i warunkowo.

## 19.6. Ryzyko nadinterpretacji metafory

Największym ryzykiem komunikacyjnym jest ponowne przekształcenie warunkowej teorii w twierdzenie absolutne. Poprawna relacja brzmi:

```text
przewaga × ekspozycja → kumulacja oczekiwanego wyniku;
zamknięcie → możliwa zmiana ekspozycji lub adaptacji;
sprzężenie zachodzi tylko przy jawnych warunkach.
```

Niepoprawne skróty to m.in. „dopamina zamyka mózg”, „200 prób wystarcza zawsze”, „każda koncentracja jest patologią”, „operator zawsze krzywdzi agenta” albo „kasyno wygrywa każdą serię”.

---

<a id="program-dalszych-badań-repo"></a>
# 20. Program dalszych badań

## 20.1. Niezależna reimplementacja

Minimalny port powinien objąć:

```text
1. dokładny i symulacyjny model house edge;
2. ruinę gracza z akcją „nie gram”;
3. model kontynuacja–wyjście;
4. reversal bandit;
5. adjudykację gry uczciwej;
6. trzy klasy użyteczności: zerową sumę, U3 i U5.
```

Port należy wykonać bez kopiowania kodu źródłowego, korzystając wyłącznie ze specyfikacji ODD i równań. Dopiero zgodność niezależnych implementacji uzasadnia rozważenie `P2`.

## 20.2. Adaptacyjny operator

Obecny rdzeń wykorzystuje głównie stałą przewagę `μ`. Kolejna wersja powinna badać `μ_t` zależne od historii, selekcję agentów, koszt personalizacji i sprzężenie zwrotne operator–agent. Wtedy podstawowym estymandem pozostaje:

```text
E[Sᴼ(T)] = E[Σ e_t μ_t],
```

ale konieczna staje się dekompozycja efektu na zmianę `N(T)`, zmianę `μ_t`, selekcję pozostających agentów i koszty operatora.

## 20.3. Walidacja pomostów B1–B4

Potrzebne są badania, które jawnie mapują:

```text
B1: koncentrację polityki modelowej ↔ nawyk i kontrolę celową;
B2: value gap / posterior concentration ↔ raportowaną pewność;
B3: adaptation delay ↔ behawioralne reversal learning;
B4: operatora syntetycznego ↔ konkretny mechanizm platformy lub gry.
```

Nie należy walidować wszystkich mostów w jednym eksperymencie. Każdy wymaga osobnej manipulacji, miary kryterialnej i testu różnicowego.

## 20.4. Użyteczność i dobrostan

Najważniejszy program empiryczny nie powinien pytać wyłącznie, ile interakcji wygenerował operator. Powinien mierzyć osobno pieniądze, czas, koszt alternatywny, deklarowany dobrostan, kontrolę, prywatność, jakość decyzji i trwałość skutków. Dopiero wtedy można rozstrzygnąć, czy wynik operatora jest transferem, korzyścią obustronną, kosztem zewnętrznym czy wielokryterialnym kompromisem.

## 20.5. Konstrukcja `CLOSE`

Przed zastosowaniem binarnego `CLOSE` u ludzi trzeba ustalić progi niezależnie od wyników głównych i wykazać, że konstrukt rozróżnia:

```text
adaptacyjną specjalizację,
błędną koncentrację,
losowość,
racjonalną ostrożność,
koszt przełączenia,
błędną specyfikację modelu,
brak wystarczającego dowodu do zmiany.
```

---

<a id="checklista-recenzenta"></a>
# 21. Checklista recenzenta

## 21.1. Warstwa formalna

- [ ] Czy `μ` jest średnią warunkową względem historii i faktycznej ekspozycji?
- [ ] Czy `N(T)→∞` jest założeniem, wynikiem czy tylko intuicją?
- [ ] Czy zależność czasowa i stopping są jawne?
- [ ] Czy odróżniono wartość oczekiwaną od prawdopodobieństwa dodatniego wyniku?
- [ ] Czy twierdzenie o ruinie zawiera minimalną stawkę, wyjście, dopływy i horyzont?
- [ ] Czy podano kontrprzykład dla zbyt silnej wersji twierdzenia?

## 21.2. Warstwa obliczeniowa

- [ ] Czy kod odzyskuje wynik dokładny?
- [ ] Czy `MCSE` jest raportowane dla głównych estymandów?
- [ ] Czy porównania parowane używają wspólnych strumieni losowych?
- [ ] Czy challenge set był odseparowany od strojenia?
- [ ] Czy pozorne niepowodzenia zostały rozstrzygnięte, a nie usunięte?
- [ ] Czy wyniki eksploracyjne ExtraTrees nie są interpretowane przyczynowo?

## 21.3. Warstwa konstruktu

- [ ] Czy niska entropia jest oceniana razem z regretem i adaptacją?
- [ ] Czy proxy pewności jest nazwane proxy, a nie ludzką pewnością?
- [ ] Czy `ZPD⃗` pozostaje wektorem, dopóki nie zostanie zwalidowany indeks?
- [ ] Czy model-based jest oceniany także przy błędnej specyfikacji?
- [ ] Czy informacja dostarczona została odróżniona od informacji zakodowanej i użytej?

## 21.4. Warstwa zewnętrzna

- [ ] Czy zysk operatora i strata agenta są mierzone osobno?
- [ ] Czy domena jest zerowej sumy, transferowa, obustronnie korzystna czy wielokryterialna?
- [ ] Czy wniosek platformowy nie jest przenoszony automatycznie na człowieka?
- [ ] Czy przegląd jest nazywany zakresowym, jeśli nie wykonano pełnego PRISMA?
- [ ] Czy twierdzenia pomostowe mają własny status i ograniczenia?

## 21.5. Warstwa reprodukcyjna

- [ ] Czy wersje środowiska i zależności są przypięte?
- [ ] Czy prerejestracja i jej hash są zgodne?
- [ ] Czy oryginalne sumy kontrolne przechodzą?
- [ ] Czy manifest zawiera seed, parametry i wyniki końcowe?
- [ ] Czy drugi zespół może odtworzyć DGM wyłącznie z ODD i metodologii?
- [ ] Czy brak identyfikatora commitu został jawnie odnotowany?

---

<a id="cytowanie-i-licencja"></a>
# 22. Cytowanie, integralność i licencja

## 22.1. Sugerowany opis cytowania

```text
Oczy szeroko zamknięte są — kasyno wygrywa zawsze:
Warunkowa teoria asymetrycznej kumulacji ekspozycji,
zamknięcia decyzyjnego i przewagi operatora.
Reprodukowalny pakiet badania formalno-obliczeniowego,
wersja 1.1.0, 6 sierpnia 2026.
Preregistracja SHA-256:
5ff09e7c0cee6184dc82c65c4ea1c20ad2cf747d9b2063ae8feadaf91a88bbad.
```

Pakiet nie wskazuje w metadanych kompletnej listy autorów ani identyfikatora repozytorium publicznego, dlatego nie należy ich dopisywać bez aktualizacji źródłowych metadanych.

## 22.2. Integralność artefaktów

```bash
sha256sum -c checksums.sha256
sha256sum -c WRITEUP.sha256
```

Pierwsze polecenie weryfikuje oryginalny pakiet 1.1.0. Drugie weryfikuje wyłącznie niniejszy write-up.

## 22.3. Licencja

Plik [`LICENSE`](LICENSE) stanowi, że pakiet jest udostępniany do celów analitycznych i reprodukcyjnych, bez gwarancji. Nie zawiera standardowego identyfikatora SPDX ani szczegółowych warunków redystrybucji. Przed publikacją zewnętrzną należy doprecyzować licencję, jeżeli repo ma umożliwiać kopiowanie, modyfikowanie lub redystrybucję na warunkach szerszych niż samo udostępnienie do analizy.

---

<a id="finalny-skrót"></a>
# 23. Finalny skrót repozytoryjny

```text
PEWNIK FORMALNY:
Dodatni warunkowy dryf i rosnąca ekspozycja,
przy warunkach zbieżności, kumulują wynik operatora.

KOREKTA ABSOLUTYZMU:
Nie oznacza to wygranej każdej gry, każdego gracza
ani dowolnego skończonego szeregu.

PEWNIK O EKSPOZYCJI:
Przy stałej przewadze E[Sᴼ(T)] = μE[N(T)].

FALSYFIKACJA ŹRÓDŁA PRZEWAGI:
Przy μ=0 sama ekspozycja nie tworzy oczekiwanego
zysku pieniężnego; przy μ<0 szkodzi operatorowi.

DEFINICJA ZAMKNIĘCIA:
Koncentracja jest błędnym zamknięciem dopiero wtedy,
gdy współwystępuje z regretem, nieadekwatną aktualizacją
lub ponadnormatywnym opóźnieniem adaptacji.

SPRZĘŻENIE:
Jeżeli zamknięcie zwiększa N(T), opóźnia wyjście
albo pozwala utrzymać dodatnią μ_t, może wzmacniać M0.

GRANICA BIOLOGICZNA:
Badanie nie dowodzi progu 200, nieodwracalnego zamknięcia
ani równoważności miar modelowych z ludzką percepcją.

WERDYKT:
B — warunkowa teoria formalno-obliczeniowa
o ograniczonym zakresie i częściowym wsparciu empirycznym.
```
