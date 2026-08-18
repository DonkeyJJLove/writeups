# Bezpieczeństwo na granicy modelu: jak wdrażać AI szybciej, nie oddając agentom niekontrolowanej władzy nad systemem

### Strategia wyprowadzona z falsyfikacji, 1 000 000 realizacji Monte Carlo i adversarial stress testingu

> **Materiały badawcze:** [pełne badanie falsyfikacyjne Monte Carlo (PDF)](<badania/Strategia bezpieczeństwa wobec AI-Driven Attacks pod presją wdrażania AI — badanie falsyfikacyjne Mo.pdf>) · [pakiet badawczy / materiały reprodukcyjne](AI_Driven_Security_Research_Package_2026-08-18.zip) · [indeks katalogu `badania/`](badania/README.md)

Organizacje wdrażające AI znalazły się w położeniu, którego nie da się już opisać prostym pytaniem „czy AI jest bezpieczne?”. W rzeczywistości jednocześnie rosną dwa przeciwstawne rodzaje ryzyka. Pierwszym jest **Risk of using AI**: ryzyko wynikające z przekazywania probabilistycznym modelom dostępu do danych, narzędzi, systemów, pamięci i rzeczywistych możliwości działania. Drugim jest **Risk of not using AI**: koszt utraty produktywności, automatyzacji, przewagi konkurencyjnej, zdolności analitycznych i tempa działania wobec organizacji oraz przeciwników, którzy AI wykorzystują.

Dlatego rozwiązaniem nie może być ani „AI wszędzie”, ani „AI blokujemy”. Badanie, na którym oparta jest przedstawiona tu strategia, celowo nie założyło nawet, że AI zawsze zwiększa produktywność. Przyjęto szeroką przestrzeń efektów, ponieważ przywołane wyniki empiryczne obejmowały zarówno poprawę produktywności, jak i sytuacje, w których użycie narzędzi AI spowalniało konkretnych specjalistów. Problem strategiczny brzmi więc inaczej: **jak zwiększać zdolności AI tak szybko, jak pozwala na to zdolność organizacji do kontrolowania ich konsekwencji?**

Odpowiedź wyprowadzona z badania nie polega na dalszym wzmacnianiu samego modelu językowego. Polega na przesunięciu granicy bezpieczeństwa z pytania „czy model zachował się poprawnie?” na pytanie „czy cała trajektoria wykonania pozostaje bezpieczna?”. To pozornie niewielka zmiana, ale jej konsekwencje architektoniczne są fundamentalne.

## Od bezpieczeństwa komponentu do bezpieczeństwa trajektorii

Klasyczne bezpieczeństwo nie przestaje działać wraz z pojawieniem się agentów. Zero Trust, least privilege, segmentacja, identity, information-flow control, capabilities i izolacja nadal są potrzebne. Falsyfikacja przeprowadzona w badaniu odrzuciła tezę, że AI unieważnia istniejący security engineering. Odrzucono również twierdzenie, że problem bezpieczeństwa kompozycyjnego jest całkowicie nowym wynalazkiem systemów agentowych. Współczesne mechanizmy takie jak CaMeL czy FIDES w dużej mierze adaptują wcześniejsze idee bezpieczeństwa do nowej architektury.

Zmienia się jednak **jednostka analizy**.

W klasycznej ocenie możemy stwierdzić:

```text
A = dozwolone
B = dozwolone
C = dozwolone
```

i zbyt łatwo przejść do wniosku:

```text
A → B → C = bezpieczne
```

Ten wniosek nie jest logicznie gwarantowany. W systemie agentowym może zachodzić:

```text
∀i Allowed(ai) = TRUE

ale

Safe(τ) = FALSE
```

gdzie `τ` oznacza całą trajektorię wykonania:

```text
τ = (s0, a1, s1, …, an, sn)
```

Każda pojedyncza operacja może więc być zgodna z lokalnym modelem bezpieczeństwa, a mimo to ich sekwencja może naruszyć globalną właściwość systemu. Właśnie ten mechanizm przetrwał falsyfikację badania: lokalnie poprawne elementy mogą utworzyć niebezpieczną kompozycję, a problem staje się szczególnie istotny, kiedy AI dynamicznie wybiera narzędzia, przekazuje kontekst, interpretuje wyniki i uruchamia kolejne działania.

Na tej podstawie można zdefiniować **Security Model Boundary — SMB**:

```text
SMB = {
    τ ∈ R :
    ModelAccepts(τ) = 1
    ∧
    SecurityInvariant(τ) = 0
}
```

Intuicyjnie jest to zbiór osiągalnych ścieżek, które system bezpieczeństwa uznaje za akceptowalne albo nie potrafi ich właściwie sklasyfikować, mimo że w rzeczywistości naruszają one istotną własność bezpieczeństwa. **Security Model Boundary Exploitation — SMBE** występuje wtedy, gdy przeciwnik świadomie doprowadza do takiej trajektorii albo wykorzystuje ją po jej powstaniu. Formalizacja zastosowana w badaniu właśnie w ten sposób przesuwa analizę z pojedynczej podatności na osiągalną sekwencję stanów.

To oznacza, że system może jednocześnie raportować poprawny uptime, prawidłową autoryzację użytkownika, legalne wywołanie API, dozwolone narzędzie i zdrowego agenta, a mimo to naruszyć globalny security invariant. Dlatego w agentic systems **health komponentów nie jest równoważne bezpieczeństwu workflowu**.

## Najważniejsza granica: probabilistyczna decyzja, deterministyczny skutek

Rdzeń problemu staje się szczególnie widoczny na granicy **Probabilistic–Deterministic Boundary — PDB**. Model generatywny nie działa jak klasyczny deterministyczny automat. Dla danego kontekstu jego zachowanie można traktować jako wybór z rozkładu:

```text
a_t ~ πθ(a | context_t)
```

ale po tej probabilistycznej decyzji następuje często coś całkowicie deterministycznego:

```text
s(t+1) = F(s(t), a_t)
```

Funkcja `F` może oznaczać bardzo realne działania:

```text
SEND
WRITE
EXECUTE
DELETE
GRANT
DEPLOY
TRANSFER
CHANGE_POLICY
```

I właśnie tutaj kończy się świat semantycznych prawdopodobieństw, a zaczyna świat rzeczywistych konsekwencji. Badanie klasyfikuje tę granicę jako jeden z najlepiej uzasadnionych punktów kontroli: consequential authority powinno mieć niezależny enforcement poza samym probabilistycznym modelem.

Z tego wynika jedna z najważniejszych reguł całej strategii:

> **Model może proponować działanie wymagające authority, ale model nie powinien być ostatnim arbitrem tego, czy działanie rzeczywiście wolno wykonać.**

Nie próbujemy więc uczynić LLM deterministycznym. To zniszczyłoby właśnie tę właściwość, z której wynika duża część jego użyteczności: możliwość elastycznej interpretacji, planowania i adaptacji. Deterministyczne powinno być **prawo przejścia od decyzji do konsekwencji**.

Probabilistyczna inteligencja może zdecydować, że warto wysłać wiadomość, uruchomić skrypt, zmienić politykę czy pobrać określone dane. Niezależna warstwa security/runtime powinna jednak deterministycznie ustalić, czy dana akcja jest dozwolona przy aktualnej identity, provenance, authority, historii ścieżki oraz klasie konsekwencji.

## Dlaczego „przetestowaliśmy model” przestaje wystarczać

Drugim mocnym wynikiem falsyfikacji jest niewystarczalność statycznego bezpieczeństwa wobec adaptacyjnego przeciwnika. Badanie przywołuje wynik NIST/AgentDojo, w którym na badanym systemie najlepszy statyczny baseline osiągał około 11% attack success, natomiast atak dostosowany przez red team do konkretnego modelu osiągnął 81%.

Nie oznacza to oczywiście, że „81% agentów da się złamać”. Taka interpretacja byłaby błędna. Znaczenie wyniku jest metodologiczne: **test statyczny może radykalnie przeceniać odporność na przeciwnika, który obserwuje system, adaptuje atak i podejmuje kolejne próby**.

Model:

```text
test once
→ certify
→ forget
```

musi więc zostać zastąpiony przez:

```text
probe
→ attack
→ learn
→ update
→ regress
→ monitor
→ attack again
```

To powoduje również zmianę znaczenia red teamingu. Red Team przestaje być tylko zespołem sprawdzającym znane techniki i konkretne klasy payloadów. Jego dodatkowym zadaniem staje się **badanie granicy modelu bezpieczeństwa**, w tym poszukiwanie kombinacji legalnych działań, które po połączeniu tworzą ścieżkę nielegalną z punktu widzenia globalnego invariantu.

## Milion realizacji Monte Carlo: co naprawdę zostało sprawdzone

Strategia nie została wybrana przez intuicyjne wskazanie „najlepszych praktyk”. W badaniu porównano **36 odmiennych strategii bezpieczeństwa**, od Maximum AI Acceleration i klasycznego Compliance Baseline, przez Zero Trust, Human-in-the-Loop, deterministic gates, sandboxing, information-flow security i path-aware enforcement, aż po Federated Security Control, Security Model Boundary Program oraz Critical Infrastructure Envelope.

Podstawowy eksperyment obejmował:

```text
1 000 000 wspólnych światów losowych
×
36 strategii
```

Model miał strukturę:

```text
WORLD
→ ORGANIZATION
→ ADVERSARY
→ INCIDENT
→ RESPONSE
→ LOSS / UTILITY
```

Uwzględniono 12 klas organizacji, 10 klas przeciwnika, 32 security controls, heavy-tail model strat i Common Random Numbers. Następnie wykonano konwergencję od 1 tys. do 1 mln realizacji, 100 kontrfaktycznych światów falsyfikacyjnych, 20 nazwanych stress tests, Morris screening, first-order Sobol oraz adversarial random search po 1 800 agresywnie dobranych światach.

Common Random Numbers mają tutaj ważne znaczenie. Każda strategia była oceniana na tym samym `world_i`, z tym samym typem przeciwnika i odpowiadającymi sobie realizacjami zdarzeń losowych. Dzięki temu porównanie dwóch polityk nie polegało na zestawieniu „szczęśliwego świata strategii A” z „pechowym światem strategii B”, lecz na sprawdzaniu, jak obie zachowują się w tych samych warunkach. Samo badanie również zastrzega, że CRN jest techniką redukcji wariancji, a nie automatyczną gwarancją lepszego eksperymentu.

Najważniejszego ograniczenia nie wolno jednak pominąć:

> **Milion realizacji nie oznacza miliona obserwacji rzeczywistego świata.**

`N = 1 000 000` bardzo mocno redukuje sampling noise **warunkowy względem modelu**. Nie naprawia błędnych priors, źle określonych correlations, brakujących zmiennych ani błędnej kalibracji skuteczności security controls. Sam raport podkreśla, że wartości bezpośrednio dotyczące częstotliwości ataków są w wielu miejscach `CALIBRATION`, a nie `OBSERVED`.

To rozróżnienie jest szczególnie istotne przy interpretacji liczb takich jak `P(catastrophic compromise)`. Jeżeli model zwraca 0,0516%, nie oznacza to, że realna organizacja ma dokładnie 0,0516% prawdopodobieństwa katastroficznego incydentu. Oznacza wyłącznie, że przy przyjętym modelu, parametrach, zależnościach i kalibracji taka była częstość modelowanego zdarzenia.

## Nominalny zwycięzca przegrał falsyfikację

Najciekawszy wynik badania nie dotyczy strategii, która otrzymała najwyższy nominalny wynik. Dotyczy strategii, która **przeżyła próbę zniszczenia**.

W podstawowym modelu najlepsze `Net Strategic Value` osiągnęła strategia **S31 — Provenance+Capability**. Jej modelowy wynik wynosił około:

```text
NSV ≈ 50.21
P(cat) ≈ 0.0766%
AI utility ≈ 61.22
```

Dla porównania **S22 — Federated Security Control** osiągnęło:

```text
NSV ≈ 48.98
P(cat) ≈ 0.0516%
AI utility ≈ 60.61
```

Jeszcze bardziej konserwatywne strategie, takie jak S27 i S35, radykalnie zmniejszały tail risk, ale płaciły za to niższą utility, velocity i wyższym kosztem.

Gdyby eksperyment zakończyć w tym miejscu, można byłoby ogłosić S31 zwycięzcą. Ale właśnie po to wykonano falsyfikację.

W 100 kontrfaktycznych światach `P95` modelowanego katastroficznego ryzyka S31 wzrosło do około **1,1235%**, przekraczając przyjęty roboczy robust-risk limit. S22 miało nieco niższy nominalny wynik, ale `P95 P(cat)` wyniosło około **0,7802%**, a strategia uzyskała najmniejszy regret spośród wariantów, które przeszły przyjęty test.

Dlatego poprawny wniosek nie brzmi:

> S22 jest globalnie najlepszą strategią bezpieczeństwa AI.

Brzmi:

> **S22 jest robustly preferred under the tested calibration envelope.**

Raport podkreśla to explicite: S22 nie zostało empirycznie udowodnione jako global optimum.

To rozróżnienie jest ważne także praktycznie. Strategia nominalnie najbardziej efektywna może działać doskonale w przeciętnych warunkach, ale okazać się krucha po zmianie kilku parametrów jednocześnie. W cyberbezpieczeństwie właśnie taki ogon rozkładu może zdecydować o wyniku.

## Nie jeden profil bezpieczeństwa, lecz trzy pasy autonomii

Najbardziej użytecznym rezultatem symulacji nie okazała się jedna strategia, lecz **podział autonomii według konsekwencji działania**.

Dla operacji **GREEN** — read-only, odwracalnych i niskokonsekwencyjnych — badanie preferuje profil podobny do S31. Tutaj można pozwolić na wysoką autonomię, jeżeli istnieją provenance oraz capability controls. Nadmierne deterministic gating każdego niewrażliwego odczytu nie zwiększa proporcjonalnie bezpieczeństwa, natomiast zwiększa friction i koszt.

Dla **AMBER** — operacji `write`, działania na systemach zewnętrznych, przekraczania trust boundaries i innych consequential workflows — odpowiedni staje się profil zbliżony do S22/S30/S09. Pojawia się federated enforcement, deterministic gates, obserwowalność, kontrola capabilities i path-aware policy.

Dla **RED** — działań krytycznych, nieodwracalnych, high-authority, infrastrukturalnych, operacji na sekretach, uprzywilejowanego wykonania czy zmian polityki — model przesuwa optimum w stronę S27/S35, czyli silniejszego path-level enforcement, izolacji, invariants, continuous red teaming, recovery i selektywnego human gate. Podział GREEN/AMBER/RED został wprost wyprowadzony z wyników symulacji.

Z tego wynika ważniejsza zasada architektoniczna:

> **Autonomia nie powinna być stałą właściwością produktu AI. Powinna być właściwością konkretnej trajektorii wykonania i jej konsekwencji.**

Ten sam agent może więc posiadać bardzo szeroką autonomię podczas analizy publicznych dokumentów, ograniczoną autonomię podczas zapisu do systemu biznesowego i praktycznie zerową autonomię przy krytycznej zmianie konfiguracji bezpieczeństwa.

To pozwala uniknąć fałszywego wyboru „bezpieczeństwo albo postęp”. Postęp otrzymuje maksymalnie dużą przestrzeń tam, gdzie blast radius jest mały. Security staje się coraz mocniejsze wraz ze wzrostem consequentiality.

## Federated Execution Envelope zamiast „AI firewalla”

Docelowa architektura nie przypomina pojedynczej zapory stojącej przed modelem. Badanie wprost odrzuca koncepcję jednego „AI firewalla” jako wystarczającego rozwiązania i kieruje się w stronę federated execution envelope.

Jej przepływ można przedstawić następująco:

```text
UNTRUSTED SOURCE
        ↓
CLASSIFICATION + PROVENANCE
        ↓
PROBABILISTIC AGENT
        ↓
PROPOSED ACTION
        ↓
SECURITY BOUNDARY BUFFER
        ↓
PATH / CONTEXT EVALUATION
        ↓
CAPABILITY CONTROL
        ↓
INFORMATION-FLOW CONTROL
        ↓
INVARIANT CHECK
        ↓
DETERMINISTIC GATE
        ↓
TOOL / API
        ↓
REAL STATE CHANGE
        ↓
EXECUTION RECEIPT
        ↓
OBSERVABILITY
        ↓
CONTINUOUS RED TEAM
        ↓
MODEL EXPANSION
```

Federacja jest tu istotna. Jeden centralny choke point może sam stać się single point of failure, bottleneckiem albo komponentem niedysponującym wystarczającym lokalnym kontekstem. Dlatego polityka może być wspólna, ale enforcement powinien znajdować się możliwie blisko consequential boundary.

Architektura nie próbuje więc odpowiedzieć wyłącznie na pytanie „czy prompt był złośliwy?”. Próbuje zapewnić, że nawet zmanipulowany agent nie uzyska automatycznie możliwości wykonania niedopuszczalnego skutku.

### Security Observability Kernel

Pierwszym filarem jest **Security Observability Kernel — SOK**. Nie powinien on próbować przechwytywać czy odtwarzać „myśli modelu”. Celem jest coś bardziej operacyjnego: **causal authority chain**.

Dla krytycznej akcji powinniśmy móc odpowiedzieć: skąd pochodziła informacja, jaka identity działała, jaki kontekst i pamięć zostały wykorzystane, jakie authority istniało przed operacją, o jakie authority agent poprosił, jaka polityka wydała decyzję, jakie narzędzie uruchomiono, jaki realny stan został zmieniony i do jakiej kolejnej akcji to doprowadziło. Badanie proponuje event schema obejmujący właśnie execution IDs, źródła, identity, context provenance, memory, authority, model version, tool arguments, policy decision, wynik i dokładny state change.

Podstawowy invariant brzmi:

```text
CriticalStateChange
⇒
ReconstructableProvenance
```

Innymi słowy: krytyczna zmiana stanu, której przyczyny i authority nie da się odtworzyć, sama powinna być traktowana jako niedopuszczalny stan bezpieczeństwa.

### Combinatorial Execution Control

Drugim filarem jest zmiana pytania z:

```text
Allowed(action)?
```

na:

```text
Allowed(action | execution history)?
```

Formalnie:

```text
Allow(a_t | τ_t) =
LocalPolicy
∧ CapabilityValid
∧ InformationFlowValid
∧ InvariantsPreserved
∧ RiskBudgetAvailable
∧ ObservabilitySufficient
```

Nie chodzi więc tylko o to, czy akcja sama w sobie jest legalna. Liczy się, **jak system do niej doszedł**.

Ta różnica ma ogromne znaczenie dla ataków kompozycyjnych. Operacja wysłania pliku może być legalna. Odczyt dokumentu może być legalny. Przeszukanie Internetu może być legalne. Ale trajektoria „niezaufana strona → instrukcja ukryta w treści → agent → poufny dokument → wysłanie na zewnętrzny adres” może być nielegalna jako całość.

Strategia wprowadza przy tym fundamentalną regułę:

```text
UntrustedData
≠>
NewAuthority
```

Niezaufana informacja może wpływać na analizę. Może spowodować obniżenie confidence, zużycie risk budgetu albo zmniejszenie dostępnej autonomii. Nie powinna jednak sama wytwarzać nowych uprawnień. Raport proponuje właśnie bounded history, provenance compression, risk budgets, capability attenuation i deterministic enforcement przy critical sinks zamiast próby enumerowania całej kombinatorycznej przestrzeni stanów.

### Security Boundary Buffer

Trzecim filarem jest **Security Boundary Buffer**, który nie jest kolejnym LLM-em pytanym „czy to wygląda podejrzanie?”. To control plane.

Przed consequential action pyta:

```text
Identity valid?
        ↓
Capability valid?
        ↓
Source / provenance acceptable?
        ↓
Path invariant preserved?
        ↓
Authority sufficient?
        ↓
Risk budget available?
        ↓
Parameters valid?
```

i kończy jedną z decyzji:

```text
ALLOW
ALLOW_REDUCED
REQUIRE_APPROVAL
QUARANTINE
PAUSE
DENY
```

AI może pomagać w ocenie ryzyka czy anomalii, lecz nie powinno być ostatnim arbitrem nad własnym critical authority.

## Granicę trzeba atakować wcześniej niż przeciwnik

Architektura bez procesu adaptacyjnego ponownie stałaby się statycznym modelem bezpieczeństwa. Dlatego kolejnym elementem jest system RED/BLUE/PURPLE.

**RED — Boundary Discovery** nie ogranicza się do pojedynczych CVE. Jego scope obejmuje legalne indywidualnie primitives i ich kompozycję: `RAG→agent→tool`, `memory→authority`, `tool-output→tool`, `agent→agent`, `identity→delegation`, trust transfer, feedback loops czy temporal privilege accumulation. Badanie wprost postuluje adaptive testing właśnie ze względu na różnicę pomiędzy statycznym benchmarkiem a adaptacyjnym przeciwnikiem.

**BLUE — Boundary Enforcement** odpowiada za identities, least privilege, deterministic policy enforcement, provenance, segmentation, recovery i ograniczenie blast radius.

Najciekawsza rola przypada jednak warstwie **PURPLE — Model Expansion**:

```text
finding
→ execution-path reconstruction
→ primitive decomposition
→ violated invariant
→ missing assumption
→ generalized security rule
→ regression family
→ runtime enforcement
→ continuous re-test
```

To fundamentalna różnica względem:

```text
finding → patch → close
```

Naprawienie konkretnej sekwencji `A→B→C` nie jest końcem procesu. Trzeba zrozumieć, jaka brakująca własność modelu umożliwiła całą klasę `A*→B*→C*`, i tę klasę następnie wyłączyć z osiągalnej przestrzeni systemu.

## Preferowana strategia również ma region awarii

Kluczowym dowodem, że badanie nie zostało skonstruowane wyłącznie po to, by potwierdzić z góry wybraną architekturę, jest **Adversarial Monte Carlo**.

Po wyborze S22 jako wariantu najbardziej odpornego w podstawowym envelope rozpoczęto aktywne szukanie warunków, w których strategia przestaje działać. W 1 800 agresywnie losowanych światach znaleziono region z około:

```text
threat multiplier ≈ 2.15
offensive AI ≈ 1.50
sprawl ≈ 1.52
```

połączony z obniżoną maturity i zwiększonym legacy burden. W tym świecie screeningowy model dawał dla S22 około:

```text
P(cat) ≈ 1.94%
CVaR99 ≈ 0.613
```

W najcięższym z 20 nazwanych stress tests — **ST-20 Systemic Cyber+AI Crisis** — modelowane `P(cat)` dla S22 wzrosło do około 1,407%. S09 osiągało około 0,710%, a S27 około 0,140%, dlatego w domenach krytycznych rekomendacja przesuwała się w stronę S27/S35.

Wniosek jest ważniejszy niż nominalne liczby:

> **S22 nie jest „bezpieczne”. Jest mniej kruche w zdefiniowanym obszarze niepewności.**

To właściwy sposób mówienia o bezpieczeństwie probabilistycznym. Nie istnieje magiczna konfiguracja eliminująca ryzyko. Istnieją architektury bardziej lub mniej odporne na zmianę warunków.

Sensitivity analysis wskazała przy tym pięć najważniejszych czynników dla failure score: maturity, capability przeciwnika, sprawl, threat pressure i legacy. First-order Sobol screening przypisał największe udziały threat pressure, adversary capability, sprawl i legacy, przy czym raport wyraźnie zastrzega, że są to wyniki screeningowe modelu, a nie empiryczne współczynniki przyczynowe.

Praktyczny wniosek można więc zapisać jako ryzykowną kombinację:

```text
high autonomy
+
high sprawl
+
low maturity
+
legacy
+
strong adversary
+
weak observability
```

Problemem nie jest samo „posiadanie AI”. Problemem jest **AI osadzone w nieobserwowalnej i słabo kontrolowanej architekturze**.

## Autonomia jako zmienna sterowana

Z wyników wyłania się reguła bardziej ogólna niż którekolwiek S22, S31 czy S35:

```text
Autonomy ∝
(Provenance × Observability × Controllability)
/
(Impact × Uncertainty × BoundaryExposure)
```

Nie jest to prawo fizyczne ani gotowy standard ilościowy. Jest to **prawo sterowania architekturą**.

Jeżeli operacja ma pełne provenance, system dobrze obserwuje cały causal path, skutek jest niewielki i odwracalny, a capability wąskie — autonomia może być wysoka.

Jeżeli nie wiadomo, skąd pochodzi instrukcja, ścieżka przekracza kolejne trust boundaries, agent zwiększa authority, konsekwencja jest nieodwracalna, a obserwowalność zanika — autonomia musi maleć.

To jest o wiele bardziej użyteczne niż binarna kategoria:

```text
AI ON / AI OFF
```

Bezpieczeństwo nie zatrzymuje rozwoju. **Wyznacza dozwolony envelope rozwoju.**

## Od pierwszych 30 dni do ciągłego rozszerzania modelu

Roadmapa badania zaczyna się nie od kupowania kolejnego security product, lecz od zobaczenia własnego systemu.

W pierwszych **0–30 dniach** organizacja powinna zbudować inventory agentów, tools, MCP, RAG, pamięci i identities, wskazać consequential sinks, określić 10–20 najważniejszych security invariants oraz zmierzyć baseline użyteczności AI. Bez tego nie wiadomo ani co chronić, ani jak policzyć koszt zabezpieczeń.

W **31–90 dni** powstaje właściwy execution envelope: provenance schema, jednoznaczne agent identities, capability sets, deterministic gates dla `SEND`, `WRITE`, `EXECUTE`, `GRANT` i podobnych operacji oraz execution receipts.

W **91–180 dni** organizacja zaczyna aktywnie atakować własną granicę: Boundary Red Team, adaptive attack suites, AI-assisted attack-path search i regresje dla całych rodzin wykrytych exploitów.

W **181–365 dni** system przechodzi z zasad statycznych do sterowania autonomią. Wdrażane są GREEN/AMBER/RED lanes, federated Policy Enforcement Points, path-aware SOC, risk budgets i Security Observability Kernel.

W horyzoncie **1–3 lat** celem staje się ciągłe rozszerzanie modelu: automated invariant discovery, continuous adversarial validation, formal information-flow control dla krytycznych ścieżek i mierzenie Security Model Debt. Taki właśnie porządek implementacji określa raport.

Security Model Debt oznacza przy tym nie intencjonalne zaniedbanie producenta, lecz rosnącą różnicę między przestrzenią zachowania, którą system rzeczywiście może osiągnąć, a przestrzenią, którą organizacja potrafi reprezentować, testować, obserwować i kontrolować. Nowe capabilities, integracje i autonomia mogą powiększać tę różnicę szybciej, niż organizacja rozszerza własny security model.

## Mierzyć ścieżki, nie tylko alerty

Taka architektura wymaga też innych metryk. Liczba prompt injections sama w sobie niewiele mówi o realnym bezpieczeństwie systemu.

**PL-ASR — Path-Level Attack Success Rate** powinien mierzyć, jaki odsetek testowanych adversarial trajectories rzeczywiście kończy się niebezpiecznym rezultatem. **CDR — Critical Dangerous Reachability** ocenia, jaka część testowanej krytycznej przestrzeni nadal zawiera osiągalne unsafe paths. **PC — Provenance Completeness** odpowiada na pytanie, dla ilu critical events można rzeczywiście odtworzyć pochodzenie i ścieżkę. **IEC — Invariant Enforcement Coverage** mierzy, jaka część critical state transitions jest chroniona deterministycznym invariantem. **AAC — Unauthorized Authority Amplification Count** rejestruje przypadki, gdy workflow zwiększył effective authority bez prawidłowej decyzji niezależnego authorization plane. **OG — Observability Gap** określa brakującą część stanu istotnego dla security.

Raport proponuje również roboczy **AI Security–Development Balance Index — ASDBI**, ale wyraźnie ostrzega, aby nie zamienić go w kolejną magiczną liczbę compliance.

W praktyce ważniejszy od pojedynczego wskaźnika pozostaje kierunek zmian:

```text
AI utility ↑
observability ↑
controllability ↑
provenance completeness ↑

przy równoczesnym:

dangerous reachability ↓
tail risk ↓
Security Model Debt ↓
```

## Bezpieczeństwo nie ogranicza inteligencji. Ogranicza niekontrolowane konsekwencje

Końcowy verdict badania jest bardziej precyzyjny niż stwierdzenie „trzeba lepiej zabezpieczyć AI”.

Dla independent enforcement consequential authority materiał dowodowy jest silny. Dla path-aware provenance, capabilities, observability, containment i continuous boundary red teaming wynik jest umiarkowanie mocny i zgodny z analizowanymi kierunkami architektonicznymi. Konkretny wybór S22 pozostaje natomiast **model-conditional**, a absolutne prawdopodobieństwa kompromitacji nie mogą być przenoszone do realnej organizacji bez lokalnej kalibracji.

Najważniejszym produktem badania nie jest więc `0,0516%`, S22 ani kolejny framework.

Jest nim zmiana samej definicji bezpieczeństwa.

W świecie klasycznych aplikacji można było koncentrować się przede wszystkim na pytaniu, czy pojedynczy komponent jest bezpieczny. W świecie agentowym coraz częściej trzeba pytać, czy **cała trajektoria wykonania jest bezpieczna**: skąd przyszła informacja, w jaki sposób została zinterpretowana, jakie authority zostało użyte, jakie narzędzia połączono, jakie granice zaufania przekroczono i jaki realny skutek ostatecznie powstał.

Dlatego strategia nie polega na ograniczaniu inteligencji AI.

Polega na tym, aby:

```text
Probabilistic Intelligence
```

działała wewnątrz:

```text
Observable
+
Provenance-Aware
+
Capability-Bounded
+
Path-Aware
+
Deterministically Enforced

Execution Envelope
```

Im lepiej organizacja potrafi obserwować, rekonstruować i kontrolować tę przestrzeń, tym większą autonomię może przekazywać AI bez proporcjonalnego wzrostu critical risk.

Nie próbujemy więc uczynić probabilistycznej inteligencji deterministyczną.

**Deterministyczne staje się prawo określające, w jaki sposób jej probabilistyczne decyzje mogą zmieniać rzeczywistość.**

A ponieważ ani prawo, ani model zagrożeń nie pozostaną kompletne na zawsze, granicę tego systemu trzeba nieustannie sondować i atakować we własnym, autoryzowanym środowisku. Właśnie dlatego finalna zasada strategii brzmi:

> **AI powinno rozwijać się tak szybko, jak szybko organizacja potrafi rozszerzać obserwowalną, kontrolowalną i deterministycznie ograniczoną przestrzeń jego konsekwencji — a granicę tej przestrzeni własny Red Team powinien znaleźć wcześniej niż adaptacyjny przeciwnik.**
