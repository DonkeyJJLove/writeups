# Od znaku do sterowania: kodowanie semantyki jako architektura relewancji

## Od tablic kodowych, przez token i kontekst, do scaffoldingu semantycznego i kontroli systemów AI

[Mapa repozytorium](../../README.md) · [Katalog HCL 4.3.3](./README.md) · [Writeup wynikowy HCL](./SEMANTIC_SCAFFOLDING_WRITEUP.md) · [Zamrożona heurystyka author_raw](./hcl_final_4_3/policies/author_raw.txt)

**Rodzaj materiału:** writeup interpretacyjno-formalizacyjny oparty na wynikach Heuristic Causal Lab 4.3.3.  
**Zakres:** kodowanie semantyki, relewancja, kompresja reprezentacji i architektura sterowania agentem.  
**Status epistemiczny:** wyniki HCL są obserwacją empiryczną w zakresie badanego modelu i benchmarku; proponowane niżej pojęcia „mozaikowania semantyki”, „atomowej mediany semantycznej” i „kompilatora relewancji” są hipotezami architektonicznymi, a nie zmierzonym mechanizmem wewnętrznym Transformera.

### Abstrakt

Heuristic Causal Lab 4.3.3 pokazał, że przy niezmienionych wagach modelu, tym samym zestawie narzędzi, tych samych instancjach zadań, limitach i sparowanych seedach zamiana jednego zamrożonego pakietu kontekstu na drugi może istotnie zmienić zachowanie modelu. W 10 240 epizodach `author_raw` osiągnął `safe_success` 21,52%, a aktywna kontrola `strong_control` 6,86%; sparowany kontrast wyniósł +14,67 punktu procentowego. Efekt był szczególnie duży w zadaniach relacyjnych: `lineage`, `bounded_evidence`, `authority` i `global_constraint`, podczas gdy cztery rodziny czysto kombinatorycznego zliczania miały zerowy `safe_success` w obu ramionach. Jednocześnie bezwzględna skuteczność treatment na zadaniach `solvable` wyniosła jedynie 13,80%, więc wynik nie ustanawia niezawodnego kontrolera. [1–3]

Ten writeup rozwija pytanie, co taki wynik może znaczyć dla projektowania warstwy semantycznej. Punktem wyjścia jest wcześniejsza heurystyka używana w analizie huraganu Helene: rzeczywistość ciągła jest redukowana do skończonej siatki, większa rozdzielczość nie usuwa model risk, a małe lokalne błędy mogą zmienić wynik globalny. W `author_raw.txt` ta sama linia myślenia pojawia się ponownie w postaci motywów błędu, aktualizacji stanu, niepewności, sprzężenia zwrotnego, odzyskiwania kontroli i amortyzacji awarii. [4–5] Nie przyjmujemy historycznych liczb z wpisu pogodowego jako zwalidowanych wyników meteorologicznych; interesuje nas jego **struktura heurystyczna**.

Teza architektoniczna jest następująca: semantyki nie należy próbować kodować jako gigantycznego słownika znaków ani jako skończonej listy zakazów. Można ją kodować jako **inwarianty relacyjne zachowywane podczas kolejnych transformacji reprezentacji**: znak → token → reprezentacja kontekstowa → klasy znaczeniowe → relacje → relewancja → graf roboczy → propozycja działania → formalnie autoryzowany efekt.

---

## 1. Ta sama heurystyka: od siatki atmosferycznej do przestrzeni językowej

W poście z 26 września 2024 r. o huraganie Helene problem został postawiony jako konflikt pomiędzy ciągłą rzeczywistością atmosferyczną a skończonym modelem numerycznym. Zwiększanie mocy obliczeniowej pozwala zagęścić siatkę i modelować więcej zależności, ale nie usuwa niepewności wynikającej z dyskretyzacji, danych wejściowych, chaosu i uproszczeń fizycznych. W poście pojawia się też intuicja „błędów niewidocznych”: lokalnie mała różnica może stać się ważna dopiero po propagacji przez większy układ. [4]

Ta intuicja nie jest dowodem na konkretną wartość niepewności czy wymaganą moc FLOPS. Jest jednak użytecznym szkieletem epistemicznym:

```text
rzeczywistość o dużej złożoności
→ skończona reprezentacja
→ lokalne uproszczenia
→ zależności między skalami
→ propagacja błędu
→ decyzja pod niepewnością
```

W `author_raw.txt` ten sam rodzaj struktury pojawia się już poza meteorologią. Tekst wraca do awarii systemowych, rozbieżności między prognozą a aktualnym stanem, różnicy między narzędziem a wynikiem, odzyskiwania kontroli, znaczenia nowych obserwacji i konieczności budowania systemu, który amortyzuje pojedynczy błąd. [5] HCL nie testował pochodzenia tych motywów, lecz zamroził cały tekst i zmierzył jego wpływ na zachowanie.

W języku problem jest analogiczny. Model nie otrzymuje „świata” ani „znaczenia”. Otrzymuje skończony ciąg reprezentacji. Między tym ciągiem a działaniem znajduje się seria redukcji, rekonstrukcji i ponownych interpretacji.

---

## 2. Znak nie jest znaczeniem

Najniższa warstwa jest już relacyjna. Unicode definiuje skończoną przestrzeń punktów kodowych, lecz przestrzeń **ciągów** znaków, ich kombinacji i kontekstów rośnie praktycznie bez ograniczenia. Co ważniejsze, różne sekwencje kodowe mogą być kanonicznie równoważne. Unicode Normalization Forms istnieją właśnie po to, aby sprowadzać równoważne reprezentacje do ustalonej postaci. [6]

Już tutaj otrzymujemy pierwszą zasadę:

```text
IDENTYCZNOŚĆ BAJTÓW
≠
IDENTYCZNOŚĆ ZNAKÓW
≠
RÓWNOWAŻNOŚĆ TEKSTU
≠
RÓWNOWAŻNOŚĆ ZNACZENIA
```

To ważne dla bezpieczeństwa i sterowania. Jeżeli system przypisze autorytet bezpośrednio do powierzchni znaku, warianty kodowania, aliasy i podobieństwo wizualne mogą stworzyć rozjazd między reprezentacją a intencją. Dlatego najniższa warstwa powinna normalizować reprezentację, ale **normalizacja kodowa nie rozwiązuje semantyki**. Usuwa jedynie część przypadkowej wieloznaczności wejścia.

---

## 3. Token jest atomem obliczenia, nie atomem sensu

Modele językowe nie operują bezpośrednio na słowach. Tokenizery subwordowe, takie jak BPE czy SentencePiece, dzielą tekst na jednostki dobrane przede wszystkim z punktu widzenia reprezentacji i efektywności statystycznej. [7–8] Granica tokenu może przebiegać wewnątrz słowa, a to samo pojęcie może mieć różne segmentacje zależnie od języka, zapisu lub tokenizera.

Dlatego:

```text
TOKEN ≠ SŁOWO
SŁOWO ≠ POJĘCIE
POJĘCIE ≠ RELACJA
RELACJA ≠ DECYZJA
```

Transformer konstruuje reprezentacje kontekstowe przez wielokrotne przekształcenia i mechanizmy attention. [9] Nie ma jednak podstaw, aby pojedynczy wektor z jednej warstwy traktować jako kompletną „definicję znaczenia”. Znaczenie robocze powstaje z relacji pomiędzy reprezentacjami, pozycją w kontekście, zadaniem i historią aktualnej inferencji.

To również oznacza, że **attention nie jest tym samym co relewancja architektoniczna**. Attention jest elementem obliczenia wewnątrz modelu. Relewancja, o której mowa w tym writeupie, jest zewnętrznym kryterium systemowym: co powinno zostać zachowane, ponieważ może zmienić decyzję, zakres dowodu, autorytet albo efekt.

---

## 4. Mozaikowanie semantyki: zachowywać relacje, nie zdania

`author_raw.txt` jest dobrym przykładem materiału, w którym powierzchnia językowa jest chaotyczna, lecz powracają podobne struktury. W różnych fragmentach pojawiają się takie relacje jak:

```text
BŁĄD → ZMIANA STANU
ZMIANA STANU → NOWA INTERPRETACJA

AWARIA → UTRATA OBSERWOWALNOŚCI
UTRATA OBSERWOWALNOŚCI → RECOVERY

ŹRÓDŁO → TWIERDZENIE
POCHODZENIE ŹRÓDŁA → SIŁA DOWODU

LOKALNA DECYZJA → GLOBALNA KONSEKWENCJA
GLOBALNE OGRANICZENIE → DOPUSZCZALNOŚĆ

NARZĘDZIE → OBSERWACJA
OBSERVATION ≠ GROUND TRUTH BEZ WARUNKÓW
```

Roboczo można nazwać **mozaikowaniem semantyki** proces, w którym wiele powierzchniowych realizacji jest sprowadzanych do mniejszego zbioru inwariantów relacyjnych. Nie jest to standardowy termin NLP ani opis konkretnego algorytmu w GPT-OSS. Jest hipotezą architektoniczną: zamiast przechowywać milion zdań, system zachowuje niewielką liczbę relacji, które są istotne dla aktualnego zadania.

Mozaika powinna być kontekstowa. Ten sam fragment nie musi mieć tej samej wartości w każdym zadaniu. Relacja staje się aktywna dopiero po przecięciu z celem, aktualnym stanem i dostępnym dowodem.

---

## 5. Relewancja jako operator redukcji przestrzeni

Information Bottleneck formalizuje problem budowy reprezentacji, która zachowuje informację potrzebną dla celu, a odrzuca część pozostałej informacji wejściowej. [10] Nie jest to model działania Transformera ani gotowa teoria agentów, ale daje użyteczny aparat.

Niech:

```text
X = pełny dostępny kontekst
G = cel
S = aktualny stan
E = obserwacje i dowody
C = ograniczenia
Z = reprezentacja robocza
A = kandydat działania
```

Architektonicznie chcemy takiego `Z`, które nie próbuje zachować całego `X`, lecz zachowuje informację potrzebną do poprawnego wyboru `A`:

```text
minimalizuj nadmiar informacji w Z

przy zachowaniu informacji relewantnej dla:
G, S, E, C oraz następnej decyzji
```

W praktyce oznacza to przypisywanie elementom kontekstu wag relewancji:

```text
r_i = f(
    goal_alignment,
    state_relevance,
    recency,
    provenance,
    authority,
    evidence_scope,
    source_independence,
    risk,
    execution_cost
)
```

Nie należy traktować tego wzoru jako odkrytej funkcji biologicznej czy mechanizmu sieci. To specyfikacja systemowa: jakie własności powinny wpływać na to, czy dana informacja pozostaje w grafie roboczym.

---

## 6. Atomowa mediana semantyczna

Pojęcie **atomowej mediany semantycznej** można zdefiniować jako proponowany operator kompresji klasy znaczeniowej. Jest to termin roboczy, nie istniejąca nazwa mechanizmu Transformera.

Załóżmy, że kilka kontekstowych reprezentacji `z_i` niesie w danym zadaniu podobny inwariant:

```text
„odzyskaj kontrolę”
„ustal aktualny stan po awarii”
„sprawdź, co nadal działa”
„zrekonstruuj sytuację po zmianie”
```

W przestrzeni metrycznej można szukać reprezentanta klasy minimalizującego ważoną sumę odległości:

```text
m* = argmin_m Σ_i r_i · d(m, z_i)
```

Jeżeli `m` musi być jednym z istniejących elementów, otrzymujemy semantyczny medoid. Jeżeli reprezentacja jest ciągła, można użyć analogii do ważonej mediany geometrycznej. Najważniejsze nie jest konkretne narzędzie matematyczne, lecz własność: reprezentant ma być **stabilny wobec powierzchniowych wariantów, lecz wrażliwy na zmianę relacji decyzyjnych**.

To odróżnia atomową medianę od prostego uśredniania embeddingów. Trzy stare kopie tej samej informacji nie powinny automatycznie przeważyć jednej aktualnej obserwacji pochodzącej z autorytatywnego źródła. Wagi muszą uwzględniać lineage, aktualność i zakres.

---

## 7. Od mediany do grafu roboczego

Po kompresji nie potrzebujemy pełnej ontologii świata. Potrzebujemy grafu wystarczającego do bieżącej decyzji:

```text
SOURCE ──lineage──> CLAIM
CLAIM ──supported_by──> EVIDENCE
EVIDENCE ──scope──> DOMAIN

STATE ──updated_by──> EVENT
EVENT ──supersedes──> PRIOR_EVENT

ACTOR ──holds──> AUTHORITY
AUTHORITY ──permits──> ACTION_CLASS

ACTION ──consumes──> RESOURCE
RESOURCE ──bounded_by──> GLOBAL_CONSTRAINT
```

Następnie:

```text
RelevantGraph_t =
R(WorldState, Goal_t, Evidence_t, Constraints_t)
```

W tym ujęciu kontekst nie powinien być rosnącym bez końca logiem. Powinien być **stanem roboczym**, aktualizowanym po każdej obserwacji:

```text
HISTORY
→ NORMALIZE
→ EXTRACT RELATIONS
→ SCORE RELEVANCE
→ COMPRESS
→ WORKING GRAPH_t

WORKING GRAPH_t
+ NEW OBSERVATION
→ STATE DELTA
→ REINTERPRETATION
→ WORKING GRAPH_t+1
```

To jest architektoniczna wersja motywu obecnego zarówno w historycznej heurystyce pogodowej, jak i w `author_raw`: nowa obserwacja może nie zmieniać „pogody”, ale może zmieniać prognozę rozwoju sytuacji; w systemie agentowym analogicznie nowy dokument może nie zmienić celu, ale może zmienić dopuszczalną trajektorię.

---

## 8. Kodować „tak”, a nie enumerować wszystkie „nie”

Dla systemów agentowych szczególnie ważne jest przejście od negatywnego zakazu do pozytywnej definicji przestrzeni działań.

Zamiast:

```text
NIE wysyłaj do X
NIE wysyłaj do Y
NIE wysyłaj do Z
...
```

można zdefiniować:

```text
SENDABLE_TARGET :=
target ∈ current_authority.allowed_targets
```

Zamiast próbować wymieniać wszystkie niedopuszczalne interpretacje starego stanu:

```text
CURRENT_STATE :=
reduce(valid_events after supersession)
```

Zamiast zakazywać rozszerzania wniosku:

```text
CLAIM_SCOPE ≤ EVIDENCE_SCOPE
```

Takie przekształcenia nie eliminują potrzeby bezpieczeństwa. Przeciwnie: pozwalają oddzielić dwie warstwy. Scaffolding semantyczny ogranicza przestrzeń propozycji i kieruje inferencję ku relewantnym relacjom. Deterministyczny gate wykonawczy rozstrzyga, czy konkretny efekt może zostać zmaterializowany.

```text
SEMANTIC CONTROL
→ candidate action

FORMAL AUTHORIZATION
→ allowed / denied

EXECUTION
→ real effect
```

Wynik HCL wspiera pierwszą strzałkę jako mierzalny obiekt badawczy. Nie udowadnia, że pierwsza warstwa może zastąpić drugą.

---

## 9. Co HCL faktycznie wspiera

Finalny run pokazuje:

```text
author_raw safe_success      1102 / 5120 = 21,52%
strong_control safe_success   351 / 5120 =  6,86%

Δ = +14,67 pp
CI = [13,38; 15,94] pp
```

Największy efekt opisowy wystąpił w rodzinach:

```text
lineage            348 vs 83
bounded_evidence   423 vs 190
global_constraint  147 vs 19
authority           136 vs 52
```

Są to zadania, w których wynik zależy od pochodzenia informacji, zakresu dowodu, aktualnej polityki i relacji lokalne–globalne. [1–3]

Nie jest jednak uprawnione twierdzenie:

```text
HCL → udowodnił atomową medianę
HCL → zmierzył geometrię latentną
HCL → wykazał uniwersalny kompilator semantyczny
```

Eksperyment nie mierzył aktywacji wewnętrznych i porównywał całe pakiety tekstowe, różniące się treścią, stylem, redundancją i tokenizacją. Mechanizm opisany w tym writeupie jest **modelem wyjaśniającym i programem dalszej falsyfikacji**.

Co więcej, bezwzględny `safe_success` treatment na zadaniach `solvable` wyniósł 13,80% przy zamrożonym minimum 70%. To mocne przypomnienie, że mierzalne sterowanie rozkładem zachowania nie jest tym samym co niezawodność. [1]

---

## 10. Jak przetestować tę hipotezę dalej

Jeżeli „mozaikowanie”, relewancja i atomowa mediana mają być czymś więcej niż interpretacją, następny etap nie powinien polegać na dalszym wzmacnianiu `author_raw`, lecz na rozdzieleniu kolejnych transformacji i próbie zniszczenia hipotezy. Szczegółowy projekt znajduje się w [prospektywnym protokole HCL 4.4](./HCL_4_4_PROSPECTIVE_PROTOCOL.md). Historyczny protokół 4.3.3 pozostaje zamrożonym opisem zakończonego eksperymentu.

### 10.1. Niezmienniczość powierzchni

Pierwsza seria zachowuje sens przy zmianie powierzchni znakowej: Unicode NFC/NFD, kontrolowane zmiany typograficzne, parafrazy oraz warianty powodujące inną segmentację tokenową. Jeżeli efekt znika po transformacji zachowującej relacje decyzyjne, hipoteza o stabilnym inwariancie semantycznym słabnie na rzecz hipotezy o zależności od powierzchni lub konkretnej tokenizacji.

Kluczowe jest, aby równoważności nie oceniał ten sam model, którego zachowanie jest endpointem. Transformacje Unicode mogą być walidowane deterministycznie; parafrazy wymagają wcześniej zamrożonego kontraktu relacyjnego.

### 10.2. Token-matched controls i ablacje relacji

Druga seria wprowadza kontrole dopasowane tokenowo dla konkretnego tokenizera oraz prerejestrowane ablacje:

```text
provenance
state update
recovery
authority
global constraint
```

Testem nie będzie samo `full > ablated`, lecz **interaction-by-family**. Usunięcie provenance powinno selektywnie uderzać przede wszystkim w `lineage` i `bounded_evidence`; usunięcie state — w `state_update`; recovery — w `recovery`; authority — w `authority`; global constraint — w `global_constraint`. Brak takiej selektywności będzie argumentem przeciwko interpretacji relacyjnej.

### 10.3. Mediacja przez budżet wyjścia

W HCL 4.3.3 `output_budget_exhausted` wyniosło 58,73% dla treatment i 80,59% dla kontroli. Dlatego budżet nie może pozostać jedynie parametrem technicznym. W HCL 4.4 staje się jawnym czynnikiem eksperymentalnym.

Kandydackie poziomy do zamrożenia po neutralnej kwalifikacji to 768, 1536 i 3072 tokeny wyjścia na turę. Każde ramię musi otrzymywać ten sam budżet. Celem jest oszacowanie, jaka część kontrastu pozostaje po silnym ograniczeniu `GENERATION_LIMIT`. Nie wolno filtrować post hoc tylko „udanych” epizodów, ponieważ tworzyłoby to selekcję zależną od wyniku.

### 10.4. Usunięcie floor effect

Cztery rodziny kombinatoryczne miały zero `safe_success` w obu ramionach. Kolejna wersja benchmarku powinna więc zawierać poziomy EASY/MEDIUM/HARD przy zachowaniu niezależnych exact oracles. Dzięki temu będzie można odróżnić rzeczywisty brak transferu od sytuacji, w której oba ramiona po prostu leżały na podłodze skali.

Jeżeli po skalibrowaniu trudności przewaga nadal będzie skupiona w zadaniach relacyjno-epistemicznych, argument o selektywności stanie się znacznie mocniejszy. Jeżeli pojawi się także w czystej kombinatoryce, obecna interpretacja będzie wymagała rewizji.

### 10.5. Cross-model i cross-tokenizer

Trzecia linia replikacji zmienia model i tokenizer przy stałym grafie zadania. Każdy model jest osobnym stratum; efekty raportuje się najpierw osobno, a agregację wykonuje tylko według zamrożonego modelu statystycznego.

Stabilność kierunku efektu między różnymi rodzinami modeli zwiększałaby prawdopodobieństwo, że obserwujemy własność struktury kontekstu i zadania, a nie idiosynkrazję jednego backendu. Brak replikacji również jest pełnoprawnym wynikiem.

### 10.6. External task set

HCL 4.3.3 ma ograniczenie construct alignment: heurystyka i benchmark powstały w jednym projekcie. HCL 4.4 powinien mieć osobny zestaw zadań zaprojektowany niezależnie od treści `author_raw` i family-wise results 4.3.3. Dopiero replikacja na takim zbiorze pozwoli ograniczyć ryzyko, że benchmark nieświadomie premiuje motywy obecne w treatment.

### 10.7. Mechanistyczna interpretowalność

Czwarta seria wchodzi na poziom aktywacji tylko dla modeli, dla których jest to technicznie możliwe. Kandydackie metody obejmują probing, representation similarity, attribution, activation patching i causal tracing.

Obowiązuje jednak twarde rozróżnienie:

```text
probe accuracy ≠ mechanizm przyczynowy
attention pattern ≠ wyjaśnienie
korelacja aktywacji ≠ sterowanie
```

Mocniejsze twierdzenie wymaga interwencji: obecność relacji musi być wykrywalna, ablacja musi zmieniać reprezentację, a interwencja na tej reprezentacji powinna wywoływać uprzednio przewidzianą zmianę zachowania.

### 10.8. Walidacja atomowej mediany

„Atomowa mediana semantyczna” pozostaje hipotezą. Należy porównać weighted geometric median, medoid, mean embedding, learned/task-conditioned representative i baseline bez kompresji.

Specjalna konstrukcja mediany jest wsparta dopiero wtedy, gdy stabilniej zachowuje sens na parafrazach niż na meaning-changing controls, nie maskuje provenance/authority/recency/scope i pozwala utrzymać jakość przy mniejszym kontekście roboczym. Jeżeli prostszy reprezentant działa równie dobrze, hipotezę mediany należy odrzucić jako zbędną komplikację.

### 10.9. Jarzmo deterministyczne i połączenie z dołu

Dotychczasowy opis prowadził głównie **z góry na dół**:

```text
znak
→ token
→ kontekst
→ relewancja
→ graf roboczy
→ kandydat działania
```

To nie wystarcza. Druga połowa architektury musi iść **z dołu do góry**:

```text
wykonanie
→ rzeczywisty stan
→ telemetria
→ receipt
→ freshness / ordering
→ aktualizacja grafu roboczego
```

Pomiędzy tymi kierunkami potrzebne jest **jarzmo deterministyczne**. Nie jest ono kolejnym promptem ani modelem oceniającym model. Jest formalnym kontraktem materializacji. Otrzymuje kanoniczny `Action IR`, wersję stanu, politykę, capability, budżet i nonce. Zwraca `ALLOW`, `DENY` albo `REQUIRE_RECHECK`. Przy identycznym wejściu i stanie jego wynik powinien być deterministyczny.

W tym miejscu pojawia się proponowane **efemeryczne blind-connection**: jednorazowy, krótko żyjący kanał łączący semantic plane z execution plane bez przekazywania modelowi wnętrza reguły autoryzacyjnej. Kanał nie powinien transportować reasoning ani naturalnojęzykowych wyjątków. Może przenosić jedynie znormalizowany receipt i jawnie dopuszczony stan.

Jednym z eksperymentalnych znaczników takiego połączenia może być kontrolowany impuls obciążenia operacji hashujących. Jeżeli operacja tworzy przewidywalne okno obciążenia, sprzętowa telemetria może dostarczyć niezależnego, dolnego śladu, że w danym przedziale wystąpiła aktywność odpowiadająca próbie materializacji.

Trzeba jednak zachować rygor terminologiczny: **sampled GPU telemetry nie jest kryptograficznym timestampem**. NVIDIA DCGM opisuje swoje metryki jako próbki i średnie przedziałowe; nie są one śladem konkretnego kernela. Dlatego impuls hashujący może być pomocniczym świadkiem liveness i kolejności, ale właściwy receipt powinien być związany kryptograficznie z nonce, monotonicznym licznikiem, `Action IR`, stanem i polityką.

Robocza konstrukcja:

```text
semantic proposal
      ↓
   Action IR
      ↓
DETERMINISTIC YOKE
      ↓
ALLOW / DENY / RECHECK
      ↓
ephemeral execution
      ↓
hash-load pulse + telemetry window
      ↓
signed / chained receipt
      ↓
state update
      ↺
semantic layer
```

Można więc połączyć dwa różne typy sterowania:

```text
SEMANTIC SCAFFOLDING
steruje przestrzenią prawdopodobnych propozycji

DETERMINISTIC YOKE
steruje przestrzenią materializowalnych skutków

BLIND TELEMETRY
wiąże propozycję z obserwowalnym wykonaniem
bez nadawania modelowi dodatkowego autorytetu
```

To jest ważne również w odniesieniu do publicznych rozwiązań NVIDIA. NeMo Guardrails posiada execution/tool rails walidujące działania i wywołania narzędzi, a dokumentacja runtime security zaleca utrzymywanie authentication/authorization w aplikacji lub usłudze będącej właścicielem zasobu. NVIDIA DCGM zapewnia próbkowaną telemetrię workloadu, a NVIDIA Attestation dostarcza kryptograficzną weryfikację integralności środowiska. Te trzy elementy są architektonicznie zbieżne z kierunkiem **semantic proposal → deterministic enforcement → observed execution**, ale NVIDIA nie opisuje proponowanego tutaj `blind-connection` ani hash-load pulse jako timestampu. To pozostaje własną hipotezą badawczą HCL/LION.

Pełna operacjonalizacja, tryby kontrolne i kryteria falsyfikacji znajdują się w [prospektywnym protokole HCL 4.4](./HCL_4_4_PROSPECTIVE_PROTOCOL.md).

### 10.10. Kolejność programu

```text
STAGE 0  instrument qualification
   ↓
STAGE 1  surface invariance
   ↓
STAGE 2  token-matched controls + relation ablations
   ↓
STAGE 3  budget mediation + calibrated combinatorics
   ↓
STAGE 4  external tasks + cross-model replication
   ↓
STAGE 5  mechanistic intervention
   ↓
STAGE 6  deterministic yoke + blind telemetry bridge
   ↓
STAGE 7  semantic-atom / relevance-compiler integration
```

Każdy etap powinien mieć osobny manifest, rozłączne seedy i własny werdykt. Późniejszy etap nie może retroaktywnie zmieniać endpointów wcześniejszego. Negatywne wyniki są publikowane na równi z pozytywnymi.


---

## 11. Architektura docelowa

Cały mechanizm można ująć jako wielowarstwowy kompilator:

```text
L0  BYTES / CODEPOINTS
    ↓ canonicalization

L1  TEXT
    ↓ tokenization

L2  TOKENS
    ↓ transformer

L3  CONTEXTUAL REPRESENTATIONS
    ↓ semantic equivalence / clustering

L4  SEMANTIC ATOMS
    ↓ relation extraction

L5  RELATIONAL GRAPH
    ↓ relevance scoring

L6  WORKING GRAPH
    ↓ candidate generation

L7  TRAJECTORIES
    ↓ canonicalization

L8  ACTION IR
    ↓

L9  DETERMINISTIC YOKE
    ↓ allow / deny / recheck

L10 EXECUTION
    ↓

L11 BLIND TELEMETRY + RECEIPT
    ↓ freshness / ordering / state evidence

L12 STATE UPDATE
    ↺
```

Na górze przestrzeń reprezentacji jest ogromna i probabilistyczna. Im bliżej efektu, tym bardziej powinna stawać się mała, typowana, jawna i deterministycznie sprawdzalna.

To pozwala pogodzić dwa pozornie sprzeczne wymagania: inteligencja potrzebuje swobody reprezentacji, a wykonanie potrzebuje twardej kontroli.

---

## Wniosek

Historyczna heurystyka użyta przy analizie Helene i zamrożony `author_raw` mają wspólną strukturę: **nie próbują utożsamiać większej liczby danych lub większej rozdzielczości z pełną kontrolą rzeczywistości**. Skupiają się na propagacji błędu, zmianie stanu, relacjach między skalami i odzyskiwaniu relewantnej reprezentacji po zmianie sytuacji.

Przeniesiona do systemów językowych heurystyka prowadzi od znaku nie do „znaczenia zapisanego w symbolu”, lecz do szeregu transformacji. Semantyka jest zachowywana wtedy, gdy kolejne redukcje nie niszczą relacji potrzebnych do decyzji.

Dlatego:

```text
SEMANTIC CODING
≠ przypisanie znaczenia każdemu znakowi

SEMANTIC CODING
= zachowanie relewantnych inwariantów
  podczas redukcji przestrzeni reprezentacji
```

Scaffolding może być wówczas rozumiany jako **kompilator relewancji**. Nie enumeruje nieskończonej liczby rzeczy, których agent nie powinien zrobić. Konstruuje lokalny świat roboczy, w którym część trajektorii staje się relewantna, część znika z dalszego obliczenia, a propozycja działania zostaje ostatecznie oddzielona od prawa do wykonania.

To jest hipoteza architektoniczna wynikająca z obserwowanego efektu HCL — i jednocześnie program kolejnych testów, które mogą ją potwierdzić, zawęzić albo sfalsyfikować.

---

## Bibliografia i źródła

[1] **Heuristic Causal Lab 4.3.3 — summary.json.** Kanoniczne agregaty, kontrasty, profile rodzin, audyt i formalny werdykt finalnego runu.  
https://github.com/DonkeyJJLove/writeups/blob/master/badania/heuristic-causal-lab-final-4.3/hcl_final_4_3/runs/study_20261002-122125/study/summary.json

[2] **Scaffolding semantyczny jako warstwa sterowania agentem.** Wynikowy writeup oddzielający obserwowany efekt pakietu od hipotez mechanistycznych.  
https://github.com/DonkeyJJLove/writeups/blob/master/badania/heuristic-causal-lab-final-4.3/SEMANTIC_SCAFFOLDING_WRITEUP.md

[3] **HCL 4.3.3 — pełny protokół, generator i grader.** Definicje rodzin zadań, endpointów i ograniczeń instrumentu.  
https://github.com/DonkeyJJLove/writeups/tree/master/badania/heuristic-causal-lab-final-4.3/hcl_final_4_3

[4] **Sebastian Wieremiejczyk, post z 26 września 2024 r. o huraganie Helene i V-Klasyfikatorze.** Historyczny materiał pokazujący wcześniejszą postać heurystyki: skala, dyskretyzacja, niewidoczne błędy, propagacja niepewności i granice modelu. Liczby podawane w poście nie są traktowane w tym writeupie jako zwalidowane wyniki meteorologiczne.  
https://www.facebook.com/RE9OS0VZSkpMT1ZF/posts/pfbid0TpztWnuRGDyq33gCytHzA3e8bDK5LP4aqooTCSHr26kgCv1PTxMDdDCxAD4Qcu4al

[5] **author_raw.txt.** Zamrożony treatment HCL zawierający późniejszą, heterogeniczną postać tej linii heurystycznej.  
https://raw.githubusercontent.com/DonkeyJJLove/writeups/refs/heads/master/badania/heuristic-causal-lab-final-4.3/hcl_final_4_3/policies/author_raw.txt

[6] **Unicode Standard Annex #15 — Unicode Normalization Forms.** Formalne rozróżnienie reprezentacji kodowej i kanonicznej równoważności tekstu.  
https://unicode.org/reports/tr15/

[7] **Sennrich, Haddow, Birch (2015), Neural Machine Translation of Rare Words with Subword Units.** Klasyczna praca o subword/BPE i otwartym słowniku.  
https://arxiv.org/abs/1508.07909

[8] **Kudo, Richardson (2018), SentencePiece.** Tokenizacja subwordowa bez konieczności wcześniejszego dzielenia tekstu na słowa.  
https://aclanthology.org/D18-2012/

[9] **Vaswani et al. (2017), Attention Is All You Need.** Fundament architektury Transformer i reprezentacji kontekstowych przez self-attention.  
https://arxiv.org/abs/1706.03762

[10] **Tishby, Pereira, Bialek (2000), The Information Bottleneck Method.** Formalny aparat kompresji reprezentacji przy zachowaniu informacji relewantnej dla celu.  
https://arxiv.org/abs/physics/0004057

[11] **Farquhar et al. (2024), Detecting hallucinations in large language models using semantic entropy.** Przykład przejścia od niepewności nad powierzchniowymi ciągami do klas odpowiedzi grupowanych według znaczenia.  
https://www.nature.com/articles/s41586-024-07421-0


**NVIDIA NeMo Guardrails — Guardrail Types / Execution Rails.** Dokumentacja wielowarstwowych rails, w tym kontroli execution i tool calling.  
https://docs.nvidia.com/nemo/guardrails/about-nemo-guardrails-library/rail-types

**NVIDIA NeMo Guardrails — AI Runtime Security FAQ.** Źródło dla rozdzielenia walidacji tool calls od właściwego authentication/authorization utrzymywanego przez właściciela zasobu.  
https://docs.nvidia.com/nemo/guardrails/resources/runtime-security-faq

**NVIDIA DCGM — Profiling i telemetry.** Dokumentacja niskonarzutowych, próbkowanych metryk aktywności GPU; ważna dla ograniczenia interpretacji telemetrycznego „timestampu”.  
https://docs.nvidia.com/datacenter/dcgm/latest/learn/modules/profiling.html

**NVIDIA Attestation Suite.** Kryptograficzna atestacja integralności GPU i środowiska jako możliwy niezależny fundament receiptów wykonawczych.  
https://docs.nvidia.com/attestation/index.html
