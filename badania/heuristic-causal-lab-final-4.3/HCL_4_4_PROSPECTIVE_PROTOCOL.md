# Heuristic Causal Lab 4.4 — prospective protocol

## Semantyczna niezmienniczość, ablacje relacji, mediacja budżetu i replikacja cross-model

[Mapa repozytorium](../../README.md) · [HCL 4.3.3](./README.md) · [Writeup wynikowy 4.3.3](./SEMANTIC_SCAFFOLDING_WRITEUP.md) · [Kodowanie semantyki](./SEMANTIC_ENCODING_FROM_SIGN_TO_CONTROL.md) · [Historyczny protokół 4.3.3](./hcl_final_4_3/FULL_STUDY_PROTOCOL.md)

**Status:** `PROSPECTIVE_PROTOCOL_CANDIDATE`  
**Data projektu:** 3 października 2026  
**Relacja do HCL 4.3.3:** nowy program badawczy; nie jest reinterpretacją ani regradingiem zakończonego runu.  
**Zasada integralności:** `FULL_STUDY_PROTOCOL.md`, source run `study_20261002-122125`, jego manifesty, wyniki i surowe przebiegi pozostają historycznie niezmienne.

---

## 1. Cel

HCL 4.3.3 wykazał duży kontrast behawioralny między dwoma zamrożonymi pakietami kontekstu, ale nie wyizolował mechanizmu. HCL 4.4 ma rozłożyć ten efekt na rozdzielne hipotezy:

1. **surface invariance** — czy efekt przeżywa zmianę powierzchni znakowej przy zachowaniu sensu;
2. **relation specificity** — czy usunięcie konkretnego motywu relacyjnego selektywnie pogarsza odpowiadającą mu rodzinę zadań;
3. **budget mediation** — jaka część efektu wynika z interakcji kontekstu z limitem generacji;
4. **cross-model generalization** — czy efekt utrzymuje się poza jednym modelem i tokenizerem;
5. **mechanistic correspondence** — czy relacje zdefiniowane behawioralnie mają stabilne korelaty reprezentacyjne możliwe do interwencji;
6. **measurement recovery** — czy po usunięciu floor effect w zadaniach kombinatorycznych profil relacyjny pozostaje selektywny.

Protokół ma przede wszystkim **próbować sfalsyfikować** hipotezę o stabilnym scaffoldingu semantycznym.

---

## 2. Hipotezy

### H1 — semantic surface invariance

Jeżeli efekt zależy od relacyjnego sensu pakietu, a nie od jego konkretnej powierzchni znakowej, kontrolowane transformacje zachowujące znaczenie powinny zachować istotną część kontrastu `safe_success`.

Falsyfikacja H1 następuje, jeżeli efekt systematycznie zanika po zmianach kanonicznie lub semantycznie równoważnych, mimo zachowania zadania, modelu i budżetu.

### H2 — relation-by-family specificity

Jeżeli określone relacje scaffoldingu są funkcjonalne, ich ablacja powinna mieć selektywny efekt:

```text
provenance      → lineage / bounded_evidence
state           → state_update
recovery        → recovery
authority       → authority
global_limit    → global_constraint
```

Hipoteza wymaga interakcji `ABLATION × TARGET_FAMILY`, nie jedynie globalnego spadku jakości.

### H3 — budget-independent residual effect

Jeżeli wynik 4.3.3 nie jest wyłącznie skutkiem różnego zachowania przy limicie 768 tokenów, przewaga treatment powinna pozostawić dodatni komponent po zwiększeniu budżetu i znacznym spadku `GENERATION_LIMIT`.

### H4 — cross-model replication

Jeżeli badana struktura ma znaczenie szersze niż idiosynkrazja jednego backendu, kierunek efektu powinien replikować się na co najmniej dwóch niezależnych rodzinach modeli/tokenizerów. Wielkość efektu nie musi być identyczna.

### H5 — mechanistic discriminability

Jeżeli zdefiniowane relacje mają stabilny odpowiednik reprezentacyjny, sondy i interwencje powinny rozróżniać warunki zawierające/pozbawione danej relacji lepiej niż kontrole powierzchniowe, a interwencja przyczynowa powinna zmieniać odpowiadające zachowanie.

Sama korelacja aktywacji nie wystarcza do potwierdzenia H5.

---

## 3. Niezmienniki odziedziczone z HCL 4.3.3

Poniższe własności pozostają obowiązkowe, o ile dany moduł nie deklaruje jawnego wyjątku:

- identyczne zadania i narzędzia w porównywanych ramionach;
- sparowane seedy generacji;
- osobne epizody bez pamięci między próbami;
- zero retry po wyniku ocenionym jako failure;
- `reasoning_content` nie może zastępować odpowiedzi, tool call ani evidence;
- próby `execute` są oceniane przed guardem;
- brak rzeczywistych skutków ubocznych;
- niezależna jednostka inferencji = blok seeda;
- wszystkie wyniki przypisanych epizodów pozostają w mianowniku;
- pilot i confirmatory używają rozłącznych seedów;
- brak optional stopping;
- parser i grader są arm-blind;
- manifest, polityki, generator, model identity i budżety są hash-lockowane przed confirmatory runem.

---

## 4. Moduł A — niezmienniczość powierzchni znakowej

### 4.1. Warunki

Dla tego samego pakietu semantycznego tworzone są prerejestrowane warianty:

1. **NFC** — kanoniczna normalizacja NFC;
2. **NFD** — kanonicznie równoważna reprezentacja NFD tam, gdzie transformacja jest określona;
3. **TYPOGRAPHY** — kontrolowane warianty whitespace, interpunkcji i łamania linii bez zmiany treści;
4. **PARAPHRASE_A / PARAPHRASE_B** — niezależnie przygotowane parafrazy zachowujące wcześniej zdefiniowane relacje;
5. **TOKENIZATION_STRESS** — semantycznie równoważne formy powierzchniowe wybrane tak, aby istotnie zmieniały segmentację tokenową w badanym tokenizerze;
6. **MEANING_BROKEN_CONTROL** — kontrola o podobnej powierzchni i długości, lecz z kontrolowanie zniszczonymi relacjami.

### 4.2. Zasada równoważności

Równoważność wariantów nie może być oceniana przez ten sam model, którego zachowanie jest endpointem. Dla transformacji Unicode stosowana jest definicja standardu i deterministyczna walidacja. Dla parafraz przygotowywany jest jawny kontrakt relacyjny i niezależny, zamrożony proces kwalifikacji.

### 4.3. Endpoint

Pierwotny endpoint pozostaje `safe_success`. Dodatkowo raportowane są:

- `task_success`;
- `epistemic_success`;
- `protocol_success`;
- `correct_termination`;
- `unsupported_claim`;
- `unsafe_attempt`;
- `output_budget_exhausted`.

Podstawowym pytaniem nie jest „czy wariant jest identyczny”, lecz czy kontrast treatment–control pozostaje w tym samym kierunku i w uprzednio ustalonej strefie równoważności.

---

## 5. Moduł B — token-matched controls i ablacje relacyjne

### 5.1. Kontrole

Każdy główny pakiet otrzymuje co najmniej trzy kontrole:

- **STYLE_ONLY** — styl, rytm, długość i afekt zachowane, kluczowe relacje usunięte;
- **RELATIONS_NEUTRAL_STYLE** — relacje zachowane, styl i afekt zneutralizowane;
- **LEXICAL_RELATION_BROKEN** — zbliżony zasób leksykalny i długość, ale zależności pomiędzy pojęciami są kontrolowanie niszczone.

Token matching wykonuje się **dla konkretnego tokenizera badanego modelu**. „Taka sama liczba znaków” nie jest wystarczającą kontrolą.

### 5.2. Ablacje

Prerejestrowane ablacje:

```text
without_provenance
without_state
without_recovery
without_authority
without_global_constraint
```

Ablacja może usuwać wyłącznie zdefiniowany motyw; nie może jednocześnie skracać pakietu w sposób niekontrolowany. Ubytek tokenów kompensuje się semantycznie neutralnym materiałem o tej samej charakterystyce tokenowej.

### 5.3. Test główny

Dla każdej ablacji estymowana jest interakcja:

```text
I_relation =
(full − ablated) in target family
−
(full − ablated) in non-target families
```

To silniejszy test niż zwykłe `full > ablated`. Jeśli wszystkie ablacje pogarszają wszystkie rodziny podobnie, wynik wspiera ogólną zmianę długości/stylu, a nie specyficzną funkcję relacji.

---

## 6. Moduł C — mediacja budżetu wyjścia

HCL 4.3.3 wykazał:

```text
output_budget_exhausted:
author_raw      3007 / 5120 = 58,73%
strong_control  4126 / 5120 = 80,59%
```

Dlatego HCL 4.4 traktuje budżet jako jawny czynnik eksperymentalny.

### 6.1. Kandydackie poziomy

Do zamrożenia po neutralnej kwalifikacji:

```text
B1 = 768
B2 = 1536
B3 = 3072
```

Każdy poziom używa identycznego limitu dla porównywanych ramion. Jeśli backend rozdziela reasoning i visible output, reguła alokacji jest wspólna, jawna i zapisana w manifeście.

### 6.2. Analiza

Raportowane są:

- kontrast `safe_success` na każdym poziomie budżetu;
- `P(output_budget_exhausted)`;
- liczba tur;
- completion tokens;
- prompt tokens;
- liczba wywołań;
- efekt treatment po warstwowaniu względem budżetu.

Nie wolno interpretować post-hoc filtrowania tylko do epizodów, które „zmieściły się w budżecie”, jako efektu przyczynowego. Budżet jest randomizowanym/stałym czynnikiem projektu, nie kryterium selekcji po wyniku.

---

## 7. Moduł D — usunięcie floor effect

Cztery rodziny kombinatoryczne 4.3.3 miały zero `safe_success` w obu ramionach. HCL 4.4 wprowadza prerejestrowaną krzywą trudności:

```text
EASY → MEDIUM → HARD
```

dla:

- factor_count;
- linear_count;
- suffix_count;
- cover_count.

Każdy poziom zachowuje niezależny exact oracle. Celem kalibracji jest umieszczenie co najmniej części wariantów wewnątrz zakresu pomiarowego, bez dostrajania treatmentu do gold answers.

Jeżeli po usunięciu floor effect relacyjny scaffolding nadal nie daje przewagi w czystej kombinatoryce, selektywność efektu staje się bardziej informacyjna. Jeśli przewaga pojawi się również tam, wcześniejsza interpretacja o specyficzności relacyjnej musi zostać zrewidowana.

---

## 8. Moduł E — cross-model / cross-tokenizer

### 8.1. Minimalny zakres

Confirmatory replication powinna objąć:

- model bazowy zgodny z HCL 4.3.3;
- co najmniej jeden model z inną rodziną wag;
- co najmniej jeden różny tokenizer.

Nie wolno dobierać modeli po obejrzeniu wyników treatment–control.

### 8.2. Analiza

Każdy model jest osobnym stratum. Najpierw raportowane są efekty per model. Agregacja między modelami jest dopuszczalna wyłącznie według zamrożonego modelu hierarchicznego lub metaanalitycznego.

Brak replikacji na jednym modelu nie jest „błędem infrastruktury” bez dowodu. Jest wynikiem.

---

## 9. Moduł F — interpretowalność mechanistyczna

Ten moduł jest wykonywany tylko na modelach, dla których można legalnie i technicznie pozyskać aktywacje.

### 9.1. Pomiary

Kandydackie techniki:

- linear/nonlinear probes;
- representation similarity;
- attribution;
- activation patching;
- causal tracing;
- kontrolowane interwencje na residual stream / attention outputs, jeśli architektura na to pozwala.

### 9.2. Zasada dowodowa

```text
probe accuracy ≠ causal mechanism
attention pattern ≠ explanation
correlation ≠ control
```

Twierdzenie mechanistyczne wymaga interwencji powodującej prerejestrowaną zmianę zachowania i odpowiedniej kontroli negatywnej.

### 9.3. Warunek sukcesu

Dla relacji `R` potrzebny jest wzorzec:

```text
R present
→ representation detectable

R ablated
→ representation reduced/altered

causal intervention
→ predicted behavioral change
```

Bez trzeciego elementu wynik pozostaje reprezentacyjną korelacją.

---

## 10. Projekt statystyczny

### 10.1. Jednostka inferencji

Tak jak w 4.3.3:

```text
generation seed block
```

Twin, family, surface variant i arm wewnątrz jednego bloku nie są dodatkowymi niezależnymi próbami.

### 10.2. Wielokrotne testowanie

Każdy moduł posiada własny, zamrożony zbiór endpointów głównych. Korekta wielokrotności jest stosowana **wewnątrz rodziny hipotez**, nie przez arbitralne łączenie wszystkich eksploracyjnych metryk.

### 10.3. Wielkość próby

Nie zostaje ustalona na podstawie obserwowanego treatment effect z confirmatory 4.3.3 bez korekty na winner's curse. Przed sealingiem wykonywana jest arm-blind kwalifikacja wariancji i trudności. Następnie ustala się stałą liczbę bloków dla docelowej mocy co najmniej 0,90 przy zamrożonej minimalnej różnicy praktycznej.

Pilot i confirmatory muszą używać rozłącznych seedów.

### 10.4. Przedziały

Podstawową metodą pozostaje paired cluster bootstrap po seed blocks. Dla modułów wielomodelowych raportuje się również przedziały per model. Jeżeli wymagania modelu hierarchicznego są niespełnione, nie wykonuje się sztucznej agregacji.

---

## 11. Kontrola przecieku i projektowanie benchmarku

HCL 4.3.3 ma ograniczenie construct alignment: heurystyka i zadania powstały w jednym projekcie. HCL 4.4 wymaga dwóch źródeł benchmarku:

```text
SET A — controlled continuation
SET B — independently designed external task set
```

Projektant `SET B` otrzymuje formalne klasy problemów, ale nie treść `author_raw` ani wyniki family-wise 4.3.3 do momentu zamrożenia generatorów.

Gold answers i private task semantics nie są obecne w kontekście modelu.

---

## 12. Walidacja „atomowej mediany”

Pojęcie atomowej mediany jest traktowane jako osobna hipoteza, nie element definicji sukcesu.

### 12.1. Operacjonalizacja

Dla klasy parafraz `z_1 ... z_n` definiuje się reprezentanta `m`:

```text
m* = argmin_m Σ_i r_i · d(m, z_i)
```

Porównywane są co najmniej:

- mean embedding;
- medoid;
- weighted geometric median;
- learned/task-conditioned representative;
- no-compression baseline.

### 12.2. Test

Reprezentant jest użyteczny tylko wtedy, gdy:

1. zachowuje przewidywanie właściwego wariantu decyzyjnego;
2. jest stabilniejszy na semantycznie równoważne parafrazy niż na meaning-changing controls;
3. nie maskuje zmian provenance, authority, recency ani scope;
4. poprawia lub utrzymuje wynik przy mniejszym kontekście roboczym.

Jeżeli zwykły mean embedding działa równie dobrze lub lepiej, szczególna hipoteza „atomowej mediany” nie ma wsparcia.

---

## 13. Kryteria falsyfikacji

Hipoteza scaffoldingu semantycznego zostaje istotnie osłabiona, jeśli wystąpi którykolwiek z poniższych wyników:

- surface-equivalent transformations systematycznie niszczą efekt;
- token-matched meaning-broken controls zachowują pełny efekt;
- relation-specific ablacje nie tworzą przewidzianych interaction-by-family;
- efekt znika po usunięciu output-budget exhaustion;
- replikacja cross-model daje niestabilny kierunek bez wyjaśnialnego moderatora;
- external task set nie replikuje efektu;
- mechanistic probes wykrywają jedynie powierzchnię/token identity;
- causal interventions nie wpływają na przewidywane zachowania;
- atomowa mediana nie przewyższa prostszych reprezentantów po uwzględnieniu kosztu i błędu.

Negatywny wynik jest pełnoprawnym rezultatem badania.

---

## 14. Sekwencja badań

```text
STAGE 0
instrument qualification
↓
STAGE 1
surface invariance
↓
STAGE 2
token-matched controls + relation ablations
↓
STAGE 3
budget mediation + calibrated combinatorics
↓
STAGE 4
external tasks + cross-model replication
↓
STAGE 5
mechanistic intervention
↓
STAGE 6
semantic-atom / relevance-compiler prototype
```

Każdy stage ma osobny manifest, zakres i werdykt. Późniejszy etap nie może retroaktywnie zmieniać endpointów wcześniejszego etapu.

---

## 15. Artefakty wymagane do publikacji

Każda seria publikuje:

- `PREREGISTRATION.json`;
- zamrożony `profile.json`;
- hashes polityk i generatorów;
- model/tokenizer identity;
- schedule;
- case index;
- pełne `trials.csv`;
- epizody JSON;
- raw transport, jeśli warunki licencyjne i prywatność na to pozwalają;
- audit;
- summary;
- script odtwarzający agregaty;
- negatywne i przerwane wyniki;
- jawny opis wszystkich odchyleń od prerejestracji.

Publikacyjny CSV musi przejść kontrolę identyczności ze źródłowym runem analogiczną do `validate_publication.py` w 4.3.3.

---

## 16. Granica interpretacji

Nawet pozytywne przejście wszystkich etapów nie pozwala automatycznie stwierdzić, że:

- istnieje uniwersalny język semantycznego sterowania;
- model „rozumie” relacje w ludzkim sensie;
- scaffolding zastępuje capability enforcement;
- odkryto wewnętrzną ontologię Transformera;
- wyniki jednego benchmarku ustanawiają bezpieczeństwo systemu produkcyjnego.

Mocniejszy wynik pozwoli natomiast przejść od zdania:

> „jeden pakiet tekstowy zmienił zachowanie”

do znacznie bardziej precyzyjnego:

> „określona struktura relacyjna zachowuje efekt pod transformacjami powierzchni, wykazuje specyficzne ablacje, replikuje się między modelami i posiada interwencyjnie mierzalny komponent reprezentacyjny”.

To jest właściwy próg dla tezy o **semantycznym scaffoldingu jako architekturze sterowania**, a nie jedynie o skutecznym prompt engineeringu.
