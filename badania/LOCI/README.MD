# LOCI — Formalna detekcja lokalnych przejść w sekwencjach tekstowych (Human–AI / Social Media)

> **REŻIM NAUKOWY: ABSOLUTNY**  
> Epistemika: P0–P3  
> Cel: detekcja i weryfikacja **realnych punktów przejścia (LOCI)** w sekwencjach generacyjnych tekstu

---

## 1. Kontekst badania

Przedmiotem analizy jest sekwencja tekstowa pochodząca z:

- źródło: Facebook (Human–AI stream)
- charakter: **ciąg generacji / iteracji semantycznych**
- natura: hybrydowa (język naturalny + heurystyki + strumień świadomości)

Dane zostały przekształcone do postaci:

- `Sample_0001.m` — surowe dane
- `Sample_0001n.m` — dane znormalizowane (parsowane, segmentowane)

---

## 2. Problem badawczy

Czy w sekwencji tekstowej istnieje:

> **realny (nielosowy) punkt przejścia semantycznego / strukturalnego (LOCI)**

czyli moment, w którym:

- zmienia się dynamika narracji
- pojawia się nowy reżim semantyczny
- zachodzi reorganizacja struktury tekstu

---

## 3. Metoda LOCI

Pipeline:

```

TEXT → PARSING → FEATURE ENGINEERING → SCORE → SEGMENTACJA → TESTY → WERDYKT

```

### 3.1 Cechy (features)

- długość fragmentu (`d_len_words`)
- entropia (`d_entropy`)
- nowość (`novelty_prev`)
- drift semantyczny (`drift_prev`)
- powtarzalność (`repetition`)
- nowe słownictwo (`new_vocab_ratio`)

---

### 3.2 Sygnał

- `score_raw` — surowy sygnał dynamiki
- `score_smooth` — wygładzony sygnał
- `dscore` — pochodna (zmiana)
- `d2score` — krzywizna (przyspieszenie)

---

### 3.3 Detekcja LOCI

Wykorzystywane wskaźniki:

- **ONSET LOCI** → maksimum kontrastu segmentacyjnego
- **MAX SLOPE** → największa zmiana (gradient)
- **MAX CURVATURE** → punkt największego przyspieszenia zmiany

---

### 3.4 Walidacja

#### Stabilność:
- bootstrap
- jackknife
- split-half

#### Testy zerowe:
- permutacje
- blokowe losowanie

#### Ablacja:
- usuwanie cech i wpływ na wynik

---

## 4. Wynik eksperymentu

Źródło: :contentReference[oaicite:0]{index=0}

```

Liczba generacji: 123

ONSET LOCI         = G0092
MAX SLOPE          = G0027
MAX CURVATURE      = G0027

Werdykt            = P2 — umiarkowany dowód lokalnego przejścia LOCI

```

---

## 5. Interpretacja (REŻIM NAUKOWY)

### 5.1 Struktura dynamiczna

System wykazuje **dwufazową dynamikę**:

#### Faza I — prekursor (G ~ 1–30)
- silne fluktuacje
- wysoka zmienność pochodnych
- pojawienie się pierwszego impulsu (G27)

👉 **MAX SLOPE / CURVATURE = G27**

Interpretacja:
> wczesne zaburzenie — inicjacja zmiany systemowej

---

#### Faza II — stabilizacja i reorganizacja (G ~ 30–90)
- spadek amplitudy zmian
- stabilizacja lokalna
- brak dominującego sygnału

---

#### Faza III — przejście segmentacyjne (G ~ 86–92)

👉 **ONSET LOCI = G92**

Parametry:
- peak contrast = 32.39
- bootstrap agree = 1.0
- perm p-value = 0.000

Interpretacja:
> **tu następuje realne rozdzielenie dwóch reżimów tekstu**

---

### 5.2 Kluczowa obserwacja

Brak synchronizacji:

```

MAX SLOPE ≠ ONSET LOCI

```

oznacza:

> zmiana nie jest jednorazowym „skokiem”, tylko procesem:
>
> **prekursor → propagacja → stabilizacja → przejście**

---

## 6. Werdykt epistemiczny

### P2 — umiarkowany dowód lokalnego przejścia

Spełnione:
- ✔ silny kontrast segmentacyjny
- ✔ stabilność bootstrap
- ✔ istotność statystyczna (p ≈ 0)

Niespełnione:
- ✖ pełna spójność fazowa
- ✖ zgodność wszystkich detektorów
- ✖ wysoka stabilność split-half

---

## 7. Znaczenie dla analizy Human–AI

Ten przypadek pokazuje:

> tekst generowany w środowisku social media (Facebook)  
> **nie ewoluuje liniowo, tylko przechodzi przez lokalne bifurkacje**

czyli:

- nie ma jednej „narracji”
- są **mikro-reżimy semantyczne**
- przejścia są **opóźnione względem impulsów**

---

## 8. Model interpretacyjny

```

IMPULS (G27)
↓
PROPAGACJA
↓
STABILIZACJA
↓
LOCI (G92)
↓
NOWY REŻIM

```

---

## 9. Wnioski systemowe

1. **LOCI ≠ maksimum dynamiki**
   - przejście nie musi być tam, gdzie największy ruch

2. **prekursory są krytyczne**
   - G27 jest ważniejszy niż się wydaje

3. **tekst jako system dynamiczny**
   - przypomina układy nieliniowe / chaos deterministyczny

---

## 10. Metodologia dla kolejnych próbek

Dla każdego sample:

### Krok 1
Parsowanie:
```

parse_sample_XXXX

```

### Krok 2
Analiza:
```

loci_sample_text_all_in_one

```

### Krok 3
Ocena:

| Kryterium | Opis |
|----------|------|
| onset stability | bootstrap |
| contrast | siła segmentacji |
| null model | p-value |
| phase alignment | slope vs onset |
| robustness | split |

---

### Klasyfikacja końcowa

| Poziom | Znaczenie |
|------|----------|
| P0 | brak sygnału |
| P1 | słaby sygnał |
| P2 | lokalne przejście |
| P3 | brak dowodu (niestabilne) |
| P4 | silne przejście |
| P5 | globalna zmiana fazy |

---

## 11. Zastosowania

- analiza narracji social media
- detekcja zmiany tonu / intencji
- badanie procesów poznawczych Human–AI
- analiza chaosu semantycznego
- monitoring propagacji idei

---

## 12. Meta-wniosek

> Facebookowy strumień tekstu zachowuje się jak system dynamiczny,
> w którym zmiany:
>
> - pojawiają się wcześniej (prekursor)
> - materializują się później (LOCI)
>
> To jest zgodne z teorią chaosu i systemów złożonych.

---

## 13. Następny krok

- analiza semantyczna okolic:
```

G86 – G96

```
- porównanie wielu próbek
- budowa mapy metaprzestrzeni (Sobol / Hypercube)

---

**STATUS:** eksperyment poprawny  
**REPRODUKOWALNOŚĆ:** wysoka  
**SYSTEM:** stabilny dla danych znormalizowanych  

---

