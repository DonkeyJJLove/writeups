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
- architektury relacji społeczno-technicznych,
- długoterminowej stabilności systemów Human-AI.

Celem README jest:
1. **uporządkowanie badań jako spójnych strumieni badawczych**,  
2. **rekonstrukcja Human-AI-In-The-Loop (HITL)** jako wspólnego wyniku tych badań,  
3. **integracja HITL z pięcioma modelami ekosystemów Human-AI**,  
4. **sformułowanie ogólnych wniosków ekonomicznych i projektowych**.

README **nie wprowadza nowych badań empirycznych** — pełni rolę warstwy integrującej,
syntetycznej i interpretacyjnej.

---

## Metodologia przeglądu

- **Źródło**: katalog `writeups/badania`
- **Charakter badań**: eksploracyjny, iteracyjny („living research”)
- **Metoda**:
  - analiza porównawcza strumieni badawczych,
  - synteza pojęciowa,
  - analiza ekonomiczna kosztu błędu i kosztu poznawczego,
  - rekonstrukcja architektur systemowych
- **Jednostka analizy**: strumień badawczy (nie pojedynczy plik)

> Repozytorium `badania/` pełni funkcję **indeksu, archiwum i dziennika badań**.  
> README opisuje **wyniki, relacje i kierunki**, a nie surowy materiał roboczy.

---

## Przegląd badań jako strumieni badawczych

### Strumień A  
### Ekonomika produkcji danych poniżej progu startupu

**Problem badawczy**  
Wysoki próg kapitałowy wejścia w produkcję danych i systemy AI.

**Pytania badawcze**
- Czy brak danych jest barierą, czy problemem organizacji procesu?
- Jaką rolę pełni człowiek w produkcji danych?

**Wkład do HITL**

| Element pętli | Rola |
|--------------|------|
| Człowiek | źródło intencji i semantyki |
| AI | akcelerator iteracji |
| Artefakty | dane prototypowe |
| Sprzężenie | szybka korekta znaczeń |

**Wynik**  
Produkcja danych wymaga **pętli Human-AI**, a nie skali infrastrukturalnej.

---

### Strumień B  
### Falsyfikacja modelu „data-only”

**Problem badawczy**  
Narastający koszt walidacji i błędów w systemach AI opartych wyłącznie na danych.

**Pytania badawcze**
- Jak rośnie koszt błędu w czasie?
- Gdzie pojawia się dryf semantyczny?

**Wkład do HITL**

| Element pętli | Rola |
|--------------|------|
| Człowiek | walidator semantyczny |
| AI | generator hipotez |
| Artefakty | decyzje, etykiety |
| Sprzężenie | redukcja dryfu |

**Wynik**  
Modele *data-only* są **ekonomicznie niestabilne długoterminowo**.

---

### Strumień C  
### Modele społeczno-techniczne Human-AI (Social-AI)

**Problem badawczy**  
Dlaczego część systemów Human-AI się rozpada mimo obecności człowieka?

**Pytania badawcze**
- Jak struktura relacji wpływa na stabilność?
- Czy relacje mogą zastąpić skalę?

**Wkład do HITL**

| Element pętli | Rola |
|--------------|------|
| Człowiek | węzeł koordynacji |
| AI | mediator informacji |
| Artefakty | reguły, procedury |
| Sprzężenie | stabilność relacji |

**Wynik**  
O opłacalności decyduje **architektura relacji**, nie sama automatyzacja.

---

### Strumień D  
### Koszt poznawczy człowieka w pętli AI

**Problem badawczy**  
Spadek jakości decyzji przy przeciążeniu informacyjnym.

**Pytania badawcze**
- Jak zmęczenie wpływa na walidację?
- Jakie są granice poznawcze HITL?

**Wkład do HITL**

| Element pętli | Rola |
|--------------|------|
| Człowiek | zasób ograniczony |
| AI | źródło presji informacyjnej |
| Artefakty | heurystyki |
| Sprzężenie | stabilizacja decyzji |

**Wynik**  
Koszt poznawczy jest **realnym składnikiem TCO** systemów AI.

---

### Strumień E  
### Rytuały, CBT i stabilizacja pętli HITL

**Problem badawczy**  
Zmienność człowieka destabilizuje systemy AI.

**Pytania badawcze**
- Jak ograniczyć losowość decyzji?
- Jak stabilizować pętlę Human-AI?

**Wkład do HITL**

| Element pętli | Rola |
|--------------|------|
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
H[Człowiek<br/>sens, walidacja, decyzja]
A[AI<br/>eksploracja, predykcja]
D[Artefakty<br/>dane, modele, procedury]

H --> A
A --> H
H --> D
D --> A
