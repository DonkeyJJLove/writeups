# Oczy szeroko zamknięte są — kasyno wygrywa zawsze

## Warunkowa teoria asymetrycznej kumulacji ekspozycji, zamknięcia decyzyjnego i przewagi operatora

**Raport końcowy badania formalnego, obliczeniowego i przeglądowego**  
Wersja: 1.1.0  
Finalizacja: 2026-08-06T10:29:40.677648+00:00  
Preregistracja SHA-256: `5ff09e7c0cee6184dc82c65c4ea1c20ad2cf747d9b2063ae8feadaf91a88bbad`

---

# Abstrakt

Zbadano, czy dwa odrębne mechanizmy mogą tworzyć wspólną teorię warunkową: asymptotyczna przewaga operatora oraz zawężenie polityki decyzyjnej agenta. Protokół rozdzielił cztery moduły: `M0` — przewaga operatora, `M1` — liczba ekspozycji, `M2` — błędna koncentracja i adaptacja, `M3` — ich sprzężenie. Wykonano dowody formalne i kontrprzykłady, dokładne obliczenia dwumianowe i łańcuchy absorbujące, około **9,608,080** trajektorii symulacyjnych różnych klas, screening 2048 punktów Latin Hypercube, 24 scenariusze konfirmacyjne, niezależną adjudykację gry uczciwej po 131 072 replikacje na scenariusz oraz challenge set obejmujący 18 klas kontrprzykładów. Uzupełnieniem była ustrukturyzowana mapa 26 źródeł formalnych, neurobiologicznych, behawioralnych, hazardowych, platformowych i metodologicznych.

`M0` został potwierdzony formalnie: dodatni warunkowy dryf oraz rosnąca liczba ekspozycji prowadzą — przy warunkach prawa wielkich liczb — do dodatniego średniego wyniku operatora i `P(Sᴼ(T)>0)→1`. Nie oznacza to wygranej w każdej rundzie ani dowolnym skończonym szeregu. `M2` wykazał, że niska entropia jest nieswoista: może oznaczać optymalną specjalizację albo kosztowną bezwładność. `M3` przy stałej przewadze spełnia tożsamość `E[Sᴼ(T)]=μE[N(T)]`; mechanizmy zamknięcia wzmacniają operatora tylko wtedy, gdy zwiększają ekspozycję, opóźniają wyjście lub współzmieniają przewagę. Przy `μ=0` nie tworzą oczekiwanego zysku pieniężnego, a przy `μ<0` zwiększają oczekiwaną stratę operatora.

Nie znaleziono podstaw dla biologicznego progu 200 ekspozycji, nieodwracalnego „zamknięcia mózgu” ani utożsamienia dopaminy z prostym przyciskiem nagrody. Najwyższy uzasadniony wynik to **warunkowa teoria formalno-obliczeniowa o ograniczonym zakresie i częściowym wsparciu empirycznym**. Werdykt ogólny: **B**.

---

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

Dla `β=1/τ`, `π_i=e^(βQ_i)/Z` oraz entropii `H=log Z−βE_π[Q]`:

```text
dH/dβ = −β Var_π(Q) ≤ 0.
```

Przy stałych wartościach `Q` zwiększenie różnic wartości albo zmniejszenie temperatury obniża entropię. Powtarzalna nagroda obniża entropię tylko wtedy, gdy algorytm aktualizacji powiększa różnice wartości i nie utrzymuje wymuszonej eksploracji. Nie jest to prawo każdego agenta.

## 6.2. Specjalizacja a błędne zamknięcie

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
