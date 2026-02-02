# Opłacalność Human-AI-In-The-Loop (HITL)  
## Przegląd i integracja badań empirycznych oraz koncepcyjnych

### Repozytorium badań (źródło pierwotne)
👉 https://github.com/DonkeyJJLove/writeups/tree/master/badania

---

## Abstrakt

Niniejszy README stanowi **zintegrowany artykuł przeglądowy (review + synthesis)**,
opisujący badania prowadzone w katalogu `writeups/badania`.

Badania te analizują opłacalność systemów opartych o sztuczną inteligencję
z perspektywy:
- ekonomii danych,
- kosztu błędu,
- kosztu poznawczego człowieka,
- architektury relacji społeczno-technicznych.

Celem README jest:
1. **uporządkowanie badań jako spójnych strumieni badawczych**,  
2. **rekonstrukcja Human-AI-In-The-Loop (HITL)** jako wspólnego wyniku tych badań,  
3. **sformułowanie ogólnych wniosków ekonomicznych**.

README **nie wprowadza nowych badań** — pełni rolę warstwy integrującej.

---

## Metodologia przeglądu

- **Źródło**: katalog `writeups/badania`
- **Charakter badań**: eksploracyjny, iteracyjny („living research”)
- **Metoda**:
  - analiza porównawcza strumieni badawczych,
  - synteza pojęciowa,
  - analiza ekonomiczna kosztu błędu i kosztu poznawczego
- **Jednostka analizy**: strumień badawczy (nie pojedynczy plik)

> Repozytorium `badania/` pełni funkcję **indeksu i dziennika badań**.
> Część materiałów roboczych istnieje poza repozytorium
> (np. dokumenty robocze), natomiast README opisuje **wyniki i kierunki badań**.

---

## Przegląd badań jako strumieni badawczych

### Strumień A  
### Ekonomika produkcji danych poniżej progu startupu

🔗 **Repo:**  
https://github.com/DonkeyJJLove/writeups/tree/master/badania

**Problem badawczy**  
Wysoki próg kapitałowy wejścia w produkcję danych i systemy AI.

**Pytania badawcze**
- Czy brak danych jest barierą, czy problemem organizacji procesu?
- Jaką rolę pełni człowiek w produkcji danych?

**Wkład do HITL**
| Element pętli | Identyfikowana rola |
|--------------|---------------------|
| Człowiek | źródło intencji i semantyki |
| AI | akcelerator iteracji |
| Artefakty | dane prototypowe |
| Sprzężenie | szybka korekta znaczeń |

**Wynik**  
Produkcja danych wymaga **pętli Human-AI**, nie skali infrastrukturalnej.

---

### Strumień B  
### Falsyfikacja modelu „data-only”

🔗 **Repo:**  
https://github.com/DonkeyJJLove/writeups/tree/master/badania

**Problem badawczy**  
Narastający koszt walidacji i błędów w systemach AI opartych wyłącznie na danych.

**Pytania badawcze**
- Jak rośnie koszt błędu w czasie?
- Gdzie pojawia się dryf semantyczny?

**Wkład do HITL**
| Element pętli | Identyfikowana rola |
|--------------|---------------------|
| Człowiek | walidator semantyczny |
| AI | generator hipotez |
| Artefakty | decyzje, etykiety |
| Sprzężenie | redukcja dryfu |

**Wynik**  
Modele *data-only* są **ekonomicznie niestabilne długoterminowo**.

---

### Strumień C  
### Modele społeczno-techniczne Human-AI (Social-AI)

🔗 **Repo:**  
https://github.com/DonkeyJJLove/writeups/tree/master/badania

**Problem badawczy**  
Dlaczego część systemów Human-AI się rozpada mimo obecności człowieka?

**Pytania badawcze**
- Jak struktura relacji wpływa na stabilność?
- Czy relacje mogą zastąpić skalę?

**Wkład do HITL**
| Element pętli | Identyfikowana rola |
|--------------|---------------------|
| Człowiek | węzeł koordynacji |
| AI | mediator informacji |
| Artefakty | reguły, procedury |
| Sprzężenie | stabilność relacji |

**Wynik**  
O opłacalności decyduje **architektura relacji**, nie sama automatyzacja.

---

### Strumień D  
### Koszt poznawczy człowieka w pętli AI

🔗 **Repo:**  
https://github.com/DonkeyJJLove/writeups/tree/master/badania

**Problem badawczy**  
Spadek jakości decyzji przy przeciążeniu informacyjnym.

**Pytania badawcze**
- Jak zmęczenie wpływa na walidację?
- Jakie są granice poznawcze HITL?

**Wkład do HITL**
| Element pętli | Identyfikowana rola |
|--------------|---------------------|
| Człowiek | zasób ograniczony |
| AI | źródło presji informacyjnej |
| Artefakty | heurystyki |
| Sprzężenie | stabilizacja decyzji |

**Wynik**  
Koszt poznawczy jest **realnym składnikiem TCO** systemów AI.

---

### Strumień E  
### Rytuały, CBT i stabilizacja pętli HITL

🔗 **Repo:**  
https://github.com/DonkeyJJLove/writeups/tree/master/badania

**Problem badawczy**  
Zmienność człowieka destabilizuje systemy AI.

**Pytania badawcze**
- Jak ograniczyć losowość decyzji?
- Jak stabilizować pętlę Human-AI?

**Wkład do HITL**
| Element pętli | Identyfikowana rola |
|--------------|---------------------|
| Człowiek | czynnik losowy |
| AI | wzmacniacz stanu |
| Artefakty | rytuały, procedury |
| Sprzężenie | redukcja fluktuacji |

**Wynik**  
Stabilny człowiek = stabilna pętla = stabilny koszt.

---

## Rekonstrukcja Human-AI-In-The-Loop (HITL)

Na podstawie wszystkich strumieni badawczych HITL wyłania się jako:

> **architektura społeczno-techniczna, w której człowiek pozostaje
> nieusuwalnym elementem pętli produkcji danych, walidacji znaczeń
> i korekty błędów, ponieważ bez tego pętla generuje narastające koszty.**

### Formalna pętla HITL

```mermaid
flowchart LR
H[Człowiek<br/>sens / walidacja] --> A[AI<br/>eksploracja]
A --> H
H --> D[Artefakty<br/>dane / decyzje]
D --> A
````

---

## Synteza ekonomiczna

### Kluczowe obserwacje

1. **Koszt błędu** dominuje nad kosztem interakcji z człowiekiem.
2. Modele *data-only* przenoszą koszt w przyszłość.
3. HITL:

   * redukuje koszt błędu,
   * stabilizuje znaczenie danych,
   * obniża długoterminowe TCO.

flowchart LR
DO[Data-only AI] -->|niski koszt startu| S1[Start]
S1 -->|eskalacja błędów| S2[Skalowanie]
S2 -->|wysoki koszt utrzymania| S3[Utrzymanie]

HITL[Human-AI-In-The-Loop] -->|wyższy koszt startu| H1[Start]
H1 -->|kontrola błędu| H2[Skalowanie]
H2 -->|stabilny koszt| H3[Utrzymanie]


---

## Wnioski końcowe

* HITL **nie jest kompromisem**, lecz wynikiem empirycznym badań.
* Opłacalność AI jest funkcją **relacji, kosztu błędu i kosztu poznawczego**.
* Człowiek w pętli nie jest kosztem ubocznym, lecz **elementem strukturalnym systemu**.

---

## Status badań

* charakter: **living research**
* repozytorium `badania/` jest źródłem pierwotnym
* README pełni rolę **warstwy integrującej i syntetycznej**

---
