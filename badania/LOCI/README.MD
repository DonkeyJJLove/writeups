# LOCI — analiza lokalnych przejść, struktury iteracji i metaprzestrzeni tekstu Human–AI

Repozytorium zawiera zestaw skryptów MATLAB do analizy iteracyjnych sampli tekstowych: od detekcji lokalnego przejścia LOCI, przez statystyki strukturalne, po osadzenie trajektorii w metaprzestrzeni cech i pomocnicze klasyfikatory trybu pracy tekstu.

Ten plik opisuje **rolę każdego skryptu**, **dokładny sens testów**, **kolejność uruchamiania**, a także **sposób interpretacji wyników**.  
Szczegółowy raport dla konkretnego sampla powinien trafiać do osobnego pliku w `results/<Sample>/`, np. `results/Sample_0001/Sample_0001.md`.

---

## 1. Co ten pakiet robi

Pakiet bada tekst nie jako pojedynczy dokument, ale jako **ciąg kolejnych generacji / edycji**.  
Interesuje nas przede wszystkim:

- gdzie pojawia się **prekursor zmiany**,  
- gdzie występuje **lokalne przejście strukturalne** (`LOCI`),  
- czy zmiana jest **stabilna statystycznie**,  
- czy trajektoria tekstu **eksploruje nowe regiony metaprzestrzeni**, czy raczej **zagęszcza już osiągnięty stan**,  
- czy dominują procesy **kompresyjne / redakcyjne**, czy **eksploracyjne / generatywne**.

W praktyce repo rozdziela analizę na cztery warstwy:

1. **detekcja sygnału LOCI**,  
2. **statystyki struktury sampla**,  
3. **geometria trajektorii w metaprzestrzeni**,  
4. **pomocnicze klasyfikatory trybu i złożoności**.

---

## 2. Dane wejściowe

### Zalecany format

Aktualny pipeline najlepiej działa na plikach znormalizowanych:

```text
sample/norm/Sample_0001n.m
```

To jest format, w którym generacje są już poprawnie rozdzielone i parser widzi pełną sekwencję.

### Format surowy

Pliki typu:

```text
sample/raw/Sample_0001.m
```

mogą wymagać dodatkowego parsowania lub normalizacji. Jeśli parser nie potrafi wiarygodnie wydzielić generacji, analiza zostanie przerwana.

### Minimalny warunek

Główna analiza LOCI wymaga co najmniej:

- **12 generacji** do uruchomienia,
- sensownej jakości segmentacji,
- najlepiej jednej, uporządkowanej sekwencji zmian tego samego artefaktu tekstowego.

---

## 3. Mapa skryptów i ich rola

| Skrypt | Rola w pipeline | Co zwraca | Status interpretacyjny |
|---|---|---|---|
| `loci_sample_text_all_in_one.m` | główny detektor LOCI | onset, max slope, max curvature, score, raport dowodowy, werdykt | **rdzeń dowodowy** |
| `sample_structure_stats.m` | opisuje czystą strukturę iteracji | znaki, tokeny, Jaccard, plateau, slope/curvature | diagnostyka strukturalna |
| `build_metaspace_map.m` | buduje przestrzeń cech / punktów odniesienia | mapa cech, dystanse, pokrycie, gęstość | warstwa geometryczna |
| `run_loci_sample_metaspace.m` | launcher end-to-end dla LOCI + metaprzestrzeni | wynik LOCI + trajektoria + statystyki meta | wrapper operacyjny |
| `loci_27D_9R_visualizer.m` | wizualizacja geometrii 27D/9R | trajektoria 3D/2D, dynamika kroku, lokalna gęstość | wizualizacja pomocnicza |
| `loci_dual_mode_model.m` | porównanie kompresji i eksploracji przed/po LOCI | compression, exploration, balance, entropia 9R, coverage vs ref | klasyfikator pomocniczy |
| `loci_mode_classifier.m` | klasyfikator trybu pracy tekstu | procedur./przejściowy/generatywny + score/confidence | klasyfikator pomocniczy |
| `loci_thought_stream_complexity_index.m` | syntetyczny indeks złożoności strumienia | TSCI 0–100 + klasa | wskaźnik pomocniczy |

**Zasada interpretacji:**

- **pierwszeństwo ma `loci_sample_text_all_in_one.m`**,  
- pozostałe skrypty **nie obalają** wyniku LOCI, tylko go **uzupełniają** i rozkładają na dodatkowe osie opisu.

---

## 4. Główny test: `loci_sample_text_all_in_one.m`

To jest centralny skrypt repo. Jego zadanie to odpowiedzieć na pytanie:

> czy w sekwencji generacji istnieje lokalne, nielosowe przejście strukturalne?

### 4.1. Jakie cechy liczy

Skrypt buduje tabelę cech na poziomie generacji. W aktualnej implementacji obejmuje ona m.in.:

- `d_len_words` — przyrost długości,  
- `novelty_prev` — nowość względem poprzedniej generacji,  
- `drift_prev` — dryf względem poprzedniej generacji,  
- `new_vocab_ratio` — udział nowego słownictwa,  
- `d_entropy` — zmiana entropii,  
- `repetition` — powtarzalność,  
- `char_complexity` — złożoność znakowa,  
- `punct_ratio` — udział interpunkcji,  
- `avg_word_len` — średnia długość słowa,  
- `line_break_ratio` — udział łamań linii.

Część cech ma znak dodatni, a część ujemny.  
Na przykład `repetition` działa hamująco, więc w detektorze jest odwracana znakowo.

### 4.2. Jak powstaje sygnał LOCI

Dla każdej cechy wykonywane są:

1. **winsoryzacja** ekstremów,  
2. **lokalne robust-z** w przesuwającym się oknie,  
3. ważona agregacja wszystkich cech do jednego `score_raw`,  
4. wygładzenie do `score_smooth`,  
5. obliczenie pochodnych `dscore` i `d2score`,  
6. analiza **kontrastu segmentacyjnego** w wielu skalach.

Wynik to trzy punkty charakterystyczne:

- `MAX SLOPE` — najsilniejsza lokalna zmiana tempa,  
- `MAX CURVATURE` — najsilniejsze lokalne przyspieszenie zmiany,  
- `ONSET LOCI` — punkt o największym kontrastowym rozdzieleniu dwóch sąsiednich segmentów.

### 4.3. Jakie testy wykonuje

#### A. Test segmentacyjny

To nie jest jeszcze „statystyka”, tylko główny mechanizm wykrywania przejścia.

Mierzy:

- `peak contrast` — jak mocno różnią się mediany lewego i prawego segmentu,  
- `scale agreement` — czy różne skale lokalne wskazują podobny onset,  
- `cluster support` — ile skal rzeczywiście wspiera wykryty onset.

**Rola:**  
to podstawowy test istnienia lokalnego pęknięcia lub reorganizacji.

#### B. Bootstrap blokowy

Skrypt losuje bloki wierszy cech i wielokrotnie odtwarza cały detektor.

Raportuje:

- `bootstrap CI95`,  
- `bootstrap agree` — jaki odsetek replik trafia w okolice oryginalnego onsetu.

**Rola:**  
sprawdza, czy wynik jest stabilny na perturbacje sekwencji.

#### C. Split-half

Sekwencja dzielona jest na dwie połówki, a detektor uruchamiany osobno.

Raportuje:

- `split agreement`.

**Rola:**  
sprawdza, czy sygnał nie jest wyłącznie artefaktem jednej części sekwencji.

#### D. Permutacyjny model zerowy

Bloki są permutowane, a detektor liczony ponownie.

Raportuje:

- `perm p_peak`.

**Rola:**  
odpowiada na pytanie, czy wykryty kontrast jest lepszy niż kontrasty generowane przez sekwencję „rozsypaną”, czyli bez oryginalnego porządku.

### 4.4. Jak zapada werdykt

Skrypt liczy **7 kryteriów**:

1. wystarczająco wysoki `peak contrast`,  
2. wystarczający `scale agreement`,  
3. wystarczające `bootstrap agree`,  
4. odpowiednio wąski bootstrap CI,  
5. wystarczająco niski wynik modelu zerowego,  
6. zgodność `max_slope` z onsetem w sensownym zakresie,  
7. zgodność `max_curvature` z onsetem w sensownym zakresie.

Na tej podstawie skrypt nadaje werdykt:

- `P1` — silne lokalne przejście,  
- `P2` — umiarkowany dowód lokalnego przejścia,  
- `P3` — brak wystarczającego dowodu realności sygnału.

### 4.5. Co ten test **udowadnia**, a czego **nie udowadnia**

Udowadnia:

- że w sekwencji pojawił się **lokalny punkt reorganizacji**,  
- że reorganizacja ma **strukturę nielosową**,  
- że można rozdzielić **prekursor** od **właściwego przejścia**.

Nie udowadnia:

- że tekst „stał się inteligencją”,  
- że zmiana ma sens neurobiologiczny,  
- że sama geometria 27D jest już skalibrowana fizycznie.

---

## 5. Testy struktury sampla: `sample_structure_stats.m`

To jest warstwa opisowa, jeszcze przed geometrią i klasyfikacją.

### Co mierzy

Typowy zestaw:

- liczba generacji,  
- wzrost liczby znaków i tokenów,  
- średni przyrost znaków,  
- średni Jaccard między kolejnymi wersjami,  
- `plateau ratio`,  
- `longest plateau`,  
- `max slope`,  
- `max curvature`.

### Rola

Ten skrypt mówi, **jaki rodzaj iteracji dominuje**:

- szybka eksploracja,  
- powolna redakcja,  
- długie plateau,  
- gwałtowne przełamania.

### Czego używać do interpretacji

- wysoki `Jaccard` + wysoki `plateau ratio` → dominacja edycji/redakcji,  
- niski `Jaccard` + wysoki przyrost → agresywna eksploracja,  
- długie plateau → silna stabilizacja lokalna.

### Czego nie robić

Nie wolno traktować samych tych statystyk jako dowodu LOCI.  
To tylko **warstwa diagnostyczna**, a nie formalny test przejścia.

---

## 6. Geometria metaprzestrzeni: `build_metaspace_map.m` i `run_loci_sample_metaspace.m`

### `run_loci_sample_metaspace.m`

To jest najwygodniejszy punkt wejścia end-to-end.

Uruchamia:

1. `loci_sample_text_all_in_one.m`,  
2. konwersję tabeli cech do macierzy numerycznej,  
3. imputację braków,  
4. normalizację cech do `[0,1]`,  
5. generację syntetycznej chmury odniesienia (`Sobol` albo `LHS`),  
6. pomiar trajektorii sampla w tej przestrzeni.

### `build_metaspace_map.m`

Funkcyjnie odpowiada warstwie budowy przestrzeni referencyjnej i liczenia metryk geometrycznych.

### Jakie metryki liczy geometria

- `path length` — całkowita długość trajektorii,  
- `mean step`, `median step`, `max step`,  
- `mean NN` — średni dystans do najbliższego sąsiada,  
- `coverage mean / median / max` — jak daleko sample leży od syntetycznej chmury odniesienia,  
- `density mean / std` — lokalne zagęszczenie trajektorii,  
- `plateau ratio (geom)` i `longest plateau (geom)` — plateau definiowane geometrycznie jako bardzo małe kroki.

### Rola

Ta warstwa odpowiada na pytania:

- czy sample **eksploruje przestrzeń**,  
- czy tylko **krąży lokalnie**,  
- czy po przejściu LOCI pojawia się nowy region trajektorii,  
- czy ruch jest ciągły, skokowy, czy plateau.

### Uwaga interpretacyjna

Geometria metaprzestrzeni **nie zastępuje** werdyktu LOCI.  
Może natomiast pokazać, że:

- sygnał LOCI jest lokalnym przełamaniem w trajektorii,  
- mimo przełamania system pozostaje globalnie kompresyjny,  
- trajectory coverage względem Sobola jest małe, czyli system nie penetruje szeroko przestrzeni odniesienia.

---

## 7. Wizualizacja 27D → 9R: `loci_27D_9R_visualizer.m`

To jest skrypt wizualny.  
Jego zadaniem jest pokazać **geometrię artefaktu**, a nie wydać główny werdykt dowodowy.

### Typowe elementy wykresów

- trajektoria artefaktu w projekcji 3D / 2D,  
- dynamika długości kroku trajektorii,  
- lokalna gęstość / nearest-neighbor,  
- projekcje wybranych osi 9R.

### Co oznacza `Onset (LOCI approx)`

W tym skrypcie `onset` jest tylko **przybliżeniem geometrycznym** wynikającym z trajektorii w projekcji.

**Nie należy go utożsamiać** z głównym `ONSET LOCI` z `loci_sample_text_all_in_one.m`.

Jeśli np. wizualizator wskazuje `G0108`, a główny test `G0092`, to:

- `G0092` pozostaje wynikiem głównym,
- `G0108` oznacza tylko, że w projekcji geometrycznej maksimum reorganizacji wypada trochę później.

### Rola

- ilustracja trajektorii,  
- intuicja przestrzenna,  
- lokalizacja regionów zagęszczenia i skoków.

### Ograniczenie

Każda projekcja 27D → 9R lub 3D jest stratna.  
To narzędzie służy do **oglądu**, nie do rozstrzygania samoistnie.

---

## 8. Klasyfikacja trybu: `loci_dual_mode_model.m` i `loci_mode_classifier.m`

### `loci_dual_mode_model.m`

Ten skrypt porównuje dwa bieguny:

- **kompresję** — redakcję, dopracowanie, zagęszczanie,  
- **eksplorację** — ruch ku nowym regionom, nowym układom i większej zmienności.

Analiza odbywa się zwykle w dwóch oknach:

- **pre-window** przed onsetem,  
- **post-window** po onset.

### Typowe wskaźniki

- `compression mean`,  
- `exploration mean`,  
- `dual balance`,  
- `trajectory length 27D`, `mean step 27D`, `max step 27D`,  
- `plateau ratio 27D`,  
- `9R entropy`,  
- `coverage / dispersion / occupancy vs ref` (najczęściej względem Sobola).

### Rola

Skrypt odpowiada na pytanie:

> czy po LOCI sample rzeczywiście przechodzi w bardziej eksploracyjny tryb, czy tylko lekko przesuwa balans, pozostając w dominancie kompresyjnej?

### Krytyczna uwaga numeryczna

Jeżeli w raporcie 27D pojawiają się liczby rzędu:

```text
1.7998171737627778e+30
```

albo podobne ekstremalne wartości długości i kroków, to oznacza to **niestabilność skali / brak poprawnej normalizacji w tej gałęzi obliczeń**.

Takie liczby wolno interpretować wyłącznie jako:

- sygnał problemu numerycznego,  
- sygnał złej kondycji przestrzeni,  
- ostrzeżenie, że **porównania bez normalizacji nie mają sensu fizycznego**.

### `loci_mode_classifier.m`

To osobny, pomocniczy klasyfikator trybu pracy tekstu.  
Zwykle rozróżnia stany typu:

- proceduralny / deklaratywny,  
- przejściowy,  
- generatywny.

W praktyce używa lokalnych cech podobieństwa, dynamiki kroku, czasem balansu trybu oraz pozycji względem onsetu.

### Zasada interpretacji konfliktu między klasyfikatorami

Jeżeli `loci_mode_classifier.m` i `loci_dual_mode_model.m` dają różne etykiety, należy to traktować jako:

- **rozbieżność modeli pomocniczych**,  
- a nie jako unieważnienie wyniku LOCI.

Priorytet jest następujący:

1. główny wynik LOCI,  
2. geometria trajektorii,  
3. klasyfikatory trybu.

---

## 9. Indeks złożoności strumienia: `loci_thought_stream_complexity_index.m`

To skrypt syntetyczny, który redukuje wiele wymiarów zachowania do jednego indeksu `TSCI` w skali 0–100.

### Typowe składowe TSCI

- `step dynamics`,  
- `curvature dynamics`,  
- `entropy variability`,  
- `drift variability`,  
- `novelty variability`,  
- `lexical expansion`,  
- `char growth`, `token growth`, `word-length growth`,  
- `persistence optimum`,  
- `plateau-length optimum`,  
- `anti-repetition`,  
- `transition strength`.

### Rola

To jest odpowiedź na pytanie:

> jak bardzo złożony jest strumień iteracji jako obiekt dynamiczny?

### Jak czytać wynik

- niski TSCI → duża stabilizacja, dużo redakcji, dużo plateau, mało eksploracji,  
- średni TSCI → mieszany tryb,  
- wysoki TSCI → silna zmienność, wiele przejść, większa niejednorodność strumienia.

### Ważne zastrzeżenie

TSCI **nie jest miarą inteligencji**,  
**nie jest miarą mózgu**,  
**nie jest pomiarem neuronów**.

To jest wyłącznie **indeks złożoności zachowania tekstowego** w iteracji.

---

## 10. Zalecana kolejność uruchamiania

### Minimalna ścieżka

```matlab
R = loci_sample_text_all_in_one('sample/norm/Sample_0001n.m');
```

To daje główny werdykt dowodowy.

### Ścieżka pełna

```matlab
R1 = loci_sample_text_all_in_one('sample/norm/Sample_0001n.m');
R2 = sample_structure_stats('sample/norm/Sample_0001n.m');
R3 = run_loci_sample_metaspace('sample/norm/Sample_0001n.m', 'Method', 'sobol');
R4 = loci_27D_9R_visualizer('sample/norm/Sample_0001n.m');
R5 = loci_dual_mode_model('sample/norm/Sample_0001n.m');
R6 = loci_mode_classifier('sample/norm/Sample_0001n.m');
R7 = loci_thought_stream_complexity_index('sample/norm/Sample_0001n.m');
```

### Praktyka interpretacyjna

- `R1` = odpowiedź główna,  
- `R2` = opis strukturalny,  
- `R3` i `R4` = geometria / wizualizacja,  
- `R5` i `R6` = tryb pracy,  
- `R7` = złożoność strumienia.

---

## 11. Jak czytać rozbieżność: G27 vs G92

To jest jedna z najważniejszych własności tego pipeline’u.

Jeżeli otrzymujesz:

```text
MAX SLOPE      = G0027
MAX CURVATURE  = G0027
ONSET LOCI     = G0092
```

to znaczy, że:

- **G27** jest prekursorem,  
- **G92** jest właściwym lokalnym przejściem.

Interpretacja:

```text
impuls -> propagacja -> stabilizacja lokalna -> przejście
```

To oznacza procesowy, a nie punktowy charakter zmiany.

---

## 12. Wynik dla `Sample_0001n.m`

### Wynik główny LOCI

```text
Liczba generacji: 123
ONSET LOCI         = G0092
MAX SLOPE          = G0027
MAX CURVATURE      = G0027
Werdykt            = P2 — umiarkowany dowód lokalnego przejścia LOCI
```

### Raport dowodowy

```text
peak contrast    = 32.397421
scale agreement  = 1.000
cluster support  = 1
bootstrap CI95   = [86.00, 86.00, 86.00]
bootstrap agree  = 1.000
split agreement  = 0.500
perm p_peak      = 0.000000
score_criteria   = 5 / 7
```

### Interpretacja

- przejście lokalne jest realne i nielosowe,  
- onset jest bardzo stabilny w bootstrapie,  
- sygnał nie osiąga najwyższego poziomu pewności, bo nie ma pełnej zgodności wszystkich osi fazowych.

### TSCI dla tego sampla

```text
TSCI = 34.4507 / 100
Klasa = niska złożoność strumienia
```

Interpretacja:

- sample jest uporządkowany,  
- ma dużo plateau,  
- jest bardziej redakcyjny niż eksploracyjny.

### Dual-mode dla tego sampla

```text
PRE  compression mean = 0.8000
POST compression mean = 0.8174
PRE  exploration mean = 0.1838
POST exploration mean = 0.2084
Werdykt klasyfikatora V2 = deklaratywno-kompresyjny
```

Interpretacja:

- po LOCI rośnie lokalna eksploracja,  
- ale dominanta pozostaje kompresyjna.

### Wizualizator 27D/9R

```text
Onset (LOCI approx) = G0108
Mean step           = 0.4028
Max step            = 2.0208
Trajectory length   = 49.5439
```

Interpretacja:

- trajektoria geometryczna pokazuje reorganizację późniejszą niż onset formalny,  
- projekcja nie unieważnia głównego wyniku G92, tylko ujawnia bezwładność geometryczną po przejściu.

---

## 13. Pliki wynikowe i raportowanie

Zalecana struktura:

```text
results/
  Sample_0001/
    Sample_0001.md
    wyniki.txt
    wyniki1_sample_0001n.jpg
    wyniki2_sample_0001n.jpg
    wyniki3_sample_0001n.jpg
    wyniki4_sample_0001n.jpg
    wyniki5_sample_0001n.jpg
```

### Co powinno trafić do raportu per sample

1. dane wejściowe,  
2. wynik główny LOCI,  
3. raport dowodowy,  
4. TSCI,  
5. wynik dual-mode / mode classifier,  
6. interpretacja metaprzestrzeni,  
7. ograniczenia i uwagi numeryczne.

---

## 14. Ograniczenia pakietu

### 1. Raw vs norm

Główna analiza nie powinna być interpretowana na plikach, których parser nie rozdzielił wiarygodnie na generacje.

### 2. Projekcje są stratne

9R, 3D i 2D są tylko projekcjami przestrzeni wyższej.

### 3. 27D wymaga normalizacji

Jeżeli pojawiają się wartości ekstremalne, trzeba najpierw poprawić skalowanie przed interpretacją wielkości absolutnych.

### 4. TSCI i klasyfikatory są pomocnicze

Nie wolno nimi zastępować głównego testu LOCI.

### 5. Rozbieżność modeli jest informacją

Jeżeli moduły dają różne werdykty, należy to zapisać jawnie, a nie uśredniać bez komentarza.

---

## 15. Minimalny opis interpretacyjny do README / publikacji technicznej

> `loci_sample_text_all_in_one.m` jest głównym testem przejścia lokalnego.  
> `sample_structure_stats.m` opisuje edycyjną strukturę iteracji.  
> `run_loci_sample_metaspace.m` i `build_metaspace_map.m` badają geometrię trajektorii w przestrzeni cech.  
> `loci_27D_9R_visualizer.m` pokazuje projekcję trajektorii i jej lokalne zagęszczenia.  
> `loci_dual_mode_model.m` oraz `loci_mode_classifier.m` klasyfikują dominujący tryb pracy tekstu.  
> `loci_thought_stream_complexity_index.m` sprowadza dynamikę strumienia do jednego wskaźnika złożoności.  
> Główny werdykt dla sampla zawsze wydaje warstwa LOCI; pozostałe skrypty służą do jego objaśnienia.

---

## 16. Powiązane pliki

- raport konkretnego sampla: ["Sample_0001"](`https://github.com/DonkeyJJLove/writeups/blob/master/badania/LOCI/results/Sample_0001/Sample_0001.md`)

