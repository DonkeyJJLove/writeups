# Linux Multi-Agent Control Mesh: od jądra systemu do SOC

## Architektura programowo definiowanej domeny bezpieczeństwa dla populacji agentów AI

### Streszczenie

Rozwój systemów agentowych zmienia podstawowy problem bezpieczeństwa AI. W systemie wykorzystującym pojedynczy model głównym przedmiotem kontroli jest interakcja człowiek–model oraz wykonywane przez model wywołania narzędzi. W systemie wieloagentowym powstaje jednak dodatkowa warstwa: populacja autonomicznych lub częściowo autonomicznych procesów wymienia informacje, deleguje zadania, uruchamia narzędzia, korzysta z poświadczeń, tworzy procesy potomne i powoduje skutki poza własnym środowiskiem wykonawczym. Bez dodatkowej warstwy kontroli sieć agentów zaczyna przypominać rozproszony system komputerowy, w którym semantyczna decyzja modelu może zostać przekształcona w deterministyczny skutek bez wystarczającego związania jej z tożsamością, autoryzacją i rzeczywistym wykonaniem.

W tej pracy proponowany jest **Linux Multi-Agent Control Mesh** — rozproszona, programowo definiowana domena bezpieczeństwa dla systemów agentowych. Mesh nie jest klasycznym service mesh. Obejmuje endpoint, lokalną domenę wykonawczą, domenowy control plane, komunikację między domenami, federacyjny trust plane oraz integrację z SOC/SIEM/SOAR. Jego podstawowym elementem pozostaje **Observability-Conditioned Reference Monitor**, czyli monitor referencyjny, w którym aktualny zakres autoryzowanego działania zależy od integralności platformy, jakości obserwowalności i ciągłości provenance. Koncepcja wyjściowa definiuje właśnie takie przejście od pojedynczej domeny wykonawczej do sieci logicznej osadzonej na hostach Linux.

Stan techniczny został zweryfikowany na 12 sierpnia 2026 r. Aktualną stabilną wersją upstream Linux pozostaje **7.1.8**, mainline to **7.2-rc7**, a najnowszą linią longterm jest **6.18.44**. Po stronie OpenAI aktualną rodzinę stanowi GPT-5.6, a Responses API jest rekomendowanym interfejsem dla nowych agentowych implementacji i umożliwia wieloetapowe wykonywanie narzędzi w obrębie jednego przepływu.

---

# 1. Od zabezpieczania modelu do zabezpieczania przestrzeni wykonania

Fundamentalnym błędem w projektowaniu bezpieczeństwa agentowego byłoby utożsamienie modelu z podmiotem posiadającym uprawnienia systemowe. Model językowy powinien być traktowany jako mniej zaufany komponent decyzyjny generujący **action proposals**. Dopiero zaufany komponent wykonawczy może przekształcić propozycję w działanie. W materiale bazowym przyjęto dokładnie takie rozdzielenie: model proponuje, harness zarządza przebiegiem, Policy Decision Point podejmuje decyzję, Policy Enforcement Point wraz z kernelem egzekwuje ją, a osobny Verifier ocenia wynik.

Takie podejście pozostaje zgodne z klasycznym modelem **reference monitor** oraz zasadą **complete mediation**. W architekturze Zero Trust NIST zasób nie powinien ufać podmiotowi wyłącznie ze względu na jego położenie w sieci; dostęp jest wynikiem jawnej decyzji polityki, natomiast PEP znajduje się na granicy chronionego zasobu i egzekwuje decyzję Policy Engine/Policy Administrator.

Dla systemu agentowego oznacza to przejście:

```text
MODEL
→ ACTION PROPOSAL
→ POLICY DECISION
→ SCOPED CAPABILITY
→ POLICY ENFORCEMENT
→ PROCESS
→ RESOURCE
→ EFFECT
```

Zasadniczą innowacją proponowanej architektury nie jest jednak sam PEP. Jest nią uzależnienie zbioru osiągalnych działań od aktualnego stanu obserwowalności. Koncepcja źródłowa formalizuje to przez:

```text
S_agent ⊆ S_domain
```

oraz:

```text
OBSERVABILITY ↓
→ AUTHORIZED STATE SPACE ↓
```

aż do przejścia w `READ_ONLY` lub całkowitego odebrania możliwości działania.

Można to zapisać bardziej ogólnie:

```text
H1 ≼ H2
⇒
Allowed(H1) ⊆ Allowed(H2)
```

gdzie `H` opisuje jakość stanu bezpieczeństwa i obserwowalności. Pogorszenie wiedzy systemu o rzeczywistym wykonaniu nigdy nie może zwiększyć zakresu autoryzacji.

Stąd cztery podstawowe reguły mesha:

```text
NO REQUIRED OBSERVATION
→ NO NEW AUTHORITY

NO VALID PRE-EXECUTION PROVENANCE
→ NO COMMIT

LOSS OF EVIDENCE CONTINUITY
→ DEGRADE / FREEZE / REVOKE

NO COMPLETE MEDIATION
→ NO CLAIM OF CONTROL
```

Nie są one twierdzeniem o istniejącym standardzie Linux. Są **propozycją architektoniczną** składającą istniejące mechanizmy Mandatory Access Control, Zero Trust, runtime assurance, attestation i provenance w jeden model sterowania.

---

# 2. Mesh jako „sieć w sieci”

W klasycznej sieci komputerowej relacja dwóch procesów jest w dużym stopniu opisywana przez adresację, routing i transport:

```text
IP_A → IP_B
```

W domenie agentowej nie jest to wystarczające. NIST SP 800-207A wskazuje już dla systemów cloud-native, że polityka powinna przesuwać się z parametrów sieciowych, takich jak adres IP czy subnet, w kierunku tożsamości użytkownika, aplikacji i usługi. Dokument wskazuje service mesh, API gateways i workload identity jako mechanizmy umożliwiające granularną autoryzację niezależną od lokalizacji workloadu.

W systemie wieloagentowym potrzebny jest jeszcze jeden poziom. Agent A nie komunikuje się z Agentem B dlatego, że istnieje trasa IP. Komunikacja powinna istnieć dlatego, że istnieje autoryzowana relacja:

```text
AGENT_A
→ authenticated identity
→ authorized relation
→ AGENT_B
```

Materiał źródłowy określa tę różnicę jednoznacznie:

```text
network address
≠ identity
≠ authority
```

**Linux Multi-Agent Control Mesh** można zatem rozłożyć na sześć logicznych płaszczyzn:

```text
CONTROL PLANE
DATA PLANE
EXECUTION PLANE
OBSERVABILITY PLANE
TRUST PLANE
SOC PLANE
```

Architektura globalna przyjmuje postać:

```text
                     ENTERPRISE CONTROL PLANE
                              │
              ┌───────────────┼────────────────┐
              │               │                │
        POLICY FEDERATION   TRUST PLANE       SOC
              │               │                │
              │        ATTESTATION / ID        │
              │               │                │
              └───────────────┼────────────────┘
                              │
              ┌───────────────┼────────────────┐
              │               │                │
           DOMAIN A        DOMAIN B         DOMAIN C
              │               │                │
          ENDPOINTS        ENDPOINTS      KVM/microVM
              │
           AGENTS
              │
           WORKERS
              │
          RESOURCES
              │
           EFFECTS
```

Ta struktura odpowiada projektowi domenowego control plane’u obejmującego między innymi rejestr agentów, Identity Service, PDP, Capability Broker, Provenance Service, Attestation Verifier i State Reconstruction Engine.

Klasyczny service mesh może zostać wykorzystany jako warstwa transportowa, szczególnie do workload identity, mTLS oraz polityki L4/L7. Nie powinien jednak być utożsamiany z Agent Control Mesh. Nie rekonstruuje automatycznie związku:

```text
model output
→ decision
→ delegated authority
→ tool invocation
→ process
→ syscall
→ external effect
```

To właśnie ten brak pełnego przypisania wykonania jest zasadniczym problemem architektury agentowej.

---

# 3. Endpoint Linux jako najmniejsza komórka mesha

Endpoint nie powinien być hostem, na którym po prostu uruchomiono proces `agent.py`. Powinien być samodzielnym **enforcement node** posiadającym lokalną tożsamość, politykę, telemetrię, mechanizmy izolacji i możliwość natychmiastowego cofnięcia działania.

Tożsamość jednej instancji agenta można reprezentować przez powiązanie:

```text
agent_instance_id
↔ run_id
↔ action_id
↔ process
↔ pidfd
↔ cgroup_id
↔ namespace_ids
↔ LSM label
↔ workload identity
↔ capability set
```

Pierwotny projekt wymaga właśnie związania logicznego agenta z procesem, cgroup, namespace, tożsamością sieciową i capability zamiast traktowania PID lub IP jako tożsamości.

Na poziomie jądra istnieje obecnie wystarczająco dużo prymitywów do zbudowania pierwszej wersji takiego węzła. **cgroup v2** organizuje procesy hierarchicznie i pozwala sterować przydziałem zasobów. **seccomp** ogranicza dostępną powierzchnię syscalli, przy czym dokumentacja kernela podkreśla wprost, że seccomp sam w sobie nie jest sandboxem i powinien być łączony z innymi mechanizmami hardeningu i LSM.

**Linux Security Modules**, w tym klasyczny MAC oraz BPF LSM, mogą wykonywać kontrolę na hookach bezpieczeństwa. BPF LSM umożliwia uprzywilejowanemu control plane’owi implementowanie polityk MAC i audit poprzez programy eBPF podłączone do hooków LSM.

**Landlock** dostarcza dodatkowego, addytywnego ograniczenia procesu. W dokumentacji Linux 7.1 jego odmowy mogą być raportowane przez Audit wraz z identyfikatorem domeny, procesem tworzącym domenę i informacją o blokowanym rodzaju dostępu do systemu plików, TCP lub IPC.

Integralność kodu można wzmacniać poprzez **IPE**, **IMA**, **fs-verity** i **dm-verity**. IPE może podejmować decyzję na podstawie niezmiennych właściwości komponentu, takich jak zabezpieczenie dm-verity albo digest lub podpis fs-verity. Jednocześnie dokumentacja IPE wskazuje ważne ograniczenia: nie potrafi zapewnić integralności anonimowej pamięci wykonywalnej lub kodu JIT, a skrypty interpretowane wymagają współpracy interpretera z `AT_EXECVE_CHECK`. fs-verity wykorzystuje drzewo Merkle’a i weryfikuje dane również podczas późniejszych odczytów z pliku.

Minimalny endpoint mesha powinien więc posiadać logicznie:

```text
Mesh Node Agent
Local PEP
Runtime Launcher
Sandbox Manager
Capability Client
Identity Client
Attestation Agent
Telemetry Collector
Provenance Collector
Local Event Buffer
Health Monitor
SOC Forwarder
```

Nie wszystkie muszą być osobnymi daemonami. To są **role architektoniczne**, nie wymaganie stworzenia kilkunastu procesów.

## Instalacja endpointu

Instalację trzeba podzielić na dwie fazy: **bootstrap trust** i **runtime trust**. Sam fakt zainstalowania pakietu nie może oznaczać uzyskania przynależności do domeny, co zostało już określone w modelu bazowym.

Praktyczny przebieg wygląda następująco:

```text
INSTALL
→ VERIFY PLATFORM
→ ENROLL IDENTITY
→ ATTEST
→ ASSIGN DOMAIN
→ APPLY BASE POLICY
→ REGISTER TELEMETRY
→ VERIFY ENFORCEMENT
→ ACTIVATE
```

W pierwszej fazie host sprawdza wymagane możliwości kernela, Secure Boot i dostępność TPM lub innego korzenia atestacji. Następnie generowana lub dostarczana jest bootstrap identity. Host przedstawia Evidence systemowi atestacyjnemu. W modelu IETF RATS **Attester** wytwarza Evidence, **Verifier** ocenia je według polityki, a **Relying Party** korzysta z Attestation Result przy podejmowaniu decyzji. RFC 9334 wskazuje wprost, że urządzeniu, którego nie można potwierdzić jako znajdującego się w wymaganym stanie, można ograniczyć dostęp albo całkowicie wycofać je z eksploatacji.

Dopiero pozytywny Attestation Result powinien pozwolić na wydanie właściwego credential domenowego.

Stan węzła jest następnie modelowany jako:

```text
UNENROLLED
→ BOOTSTRAPPING
→ ATTESTING
→ ACTIVE
→ DEGRADED
→ RESTRICTED
→ QUARANTINED
→ FROZEN
→ REVOKED
```

Przejścia w dół nie są wyłącznie alertami SOC. Powodują fizyczną zmianę dostępnej przestrzeni działania.

---

# 4. Domeny, polityka i delegacja

Najważniejszą jednostką zarządzania większego systemu nie powinien być pojedynczy agent, lecz **domena wykonawcza**.

Przykładowo:

```text
DOMAIN_RESEARCH
DOMAIN_CODE
DOMAIN_SECURITY
DOMAIN_OPERATIONS
DOMAIN_MEMORY
DOMAIN_EXTERNAL_IO
```

Każda domena określa własny `authority_ceiling`, dopuszczalne klasy agentów, narzędzi i danych, politykę egress, wymagany poziom obserwowalności oraz politykę atestacji. Taki model został zdefiniowany w źródłowej architekturze micro-domain jako połączenie identity namespace, process/network namespace, resource budget, allowed peers/tools/data oraz observability requirements.

Polityka powinna być hierarchiczna:

```text
GLOBAL POLICY
      ↓
DOMAIN POLICY
      ↓
HOST POLICY
      ↓
AGENT CLASS POLICY
      ↓
INSTANCE POLICY
      ↓
ACTION POLICY
```

Zasadą dziedziczenia jest monotoniczne ograniczanie:

```text
P_action
⊆ P_instance
⊆ P_agent_class
⊆ P_host
⊆ P_domain
⊆ P_global
```

Niższa warstwa może zawęzić zakres nadrzędny, ale nie może samodzielnie go rozszerzyć. Jest to centralny warunek modelu configuration-as-code przedstawionego w projekcie.

Konfiguracja może być reprezentowana deklaratywnie:

```yaml
domain:
  id: security-research
  authority_ceiling: R2

observability:
  audit_required: true
  bpf_required: true
  provenance_required: true

execution:
  isolation: namespace
  seccomp_profile: research-v3
  lsm_profile: agent-research
  egress_policy: controlled

authorization:
  delegation: explicit
  capability_ttl: 120s

soc:
  semantic_events: true
  high_impact_forwarding: immediate
```

Nie jest to proponowany standard. Jest to **ARCHITECTURE PROPOSAL** dla warstwy deklaratywnej.

Każda konfiguracja powinna posiadać:

```text
configuration_id
version
digest
signer
scope
parent_policy
deployment_time
```

oraz przechodzić przez walidację, testy polityki, canary deployment i możliwość rollbacku. IPE już dziś zawiera mechanizmy wersjonowania polityk i ochronę przed rollbackiem do starszej wersji podczas update’u polityki, co pokazuje, że podobna semantyka ma istniejący odpowiednik na poziomie kernela.

## Najważniejsza reguła delegacji

W wieloagentowym systemie największym błędem byłoby zezwolenie agentowi A na przekazanie agentowi B własnego credential:

```text
A → "użyj mojego tokenu" → B
```

Powinna istnieć inna ścieżka:

```text
AGENT A
→ delegation request
→ PDP
→ Capability Broker
→ new scoped capability
→ AGENT B
```

Źródłowy model określa tę zasadę jako:

```text
DATA MAY FLOW
AUTHORITY MAY NOT FLOW IMPLICITLY
```

Capability musi być krótkotrwała, ograniczona do konkretnej operacji i zasobu, związana z odbiorcą i — gdzie to możliwe — niedelegowalna oraz wykorzystująca proof-of-possession.

Oznacza to, że komunikacja i delegacja tworzą dwa różne grafy.

---

# 5. Cztery grafy zamiast jednego logu

Pełna architektura wymaga utrzymywania co najmniej czterech logicznych struktur.

Pierwsza to **information provenance graph**:

```text
SOURCE
→ DOCUMENT
→ RETRIEVAL
→ MEMORY
→ AGENT
→ MODEL CONTEXT
→ RESULT
```

Druga to **authorization, delegation and capability graph**:

```text
PRINCIPAL
→ POLICY
→ CAPABILITY
→ AGENT
→ DELEGATION
→ CAPABILITY
→ ACTION
```

Trzecia to **runtime execution graph**:

```text
MODEL
→ AGENT
→ PROCESS
→ TOOL
→ SYSCALL
→ RESOURCE
→ EFFECT
```

Czwarta to **observability graph**:

```text
PROCESS
├── application trace
├── model/API trace
├── Audit
├── BPF
├── LSM
├── network
├── filesystem
└── attestation
```

Koncepcja czterech grafów jest bezpośrednim rozwinięciem wcześniejszego modelu, w którym informacja, autoryzacja i wykonanie pozostają oddzielone, a obserwacje z wielu sensorów składają się na estymację stanu.

W3C PROV dostarcza istniejącego, domenowo niezależnego modelu provenance, opierającego się między innymi na **Entity, Activity i Agent** oraz relacjach odpowiedzialności i derivation. PROV został celowo zaprojektowany jako rozszerzalny model wymiany informacji o pochodzeniu, dlatego nadaje się na rdzeń, ale nie definiuje natywnie wszystkich agentowych pojęć takich jak capability, PDP czy efekt autoryzacyjny.

Można więc tworzyć rozszerzenie:

```text
PROV Entity
→ input / context / artifact

PROV Activity
→ inference / tool execution / action

PROV Agent
→ principal / workload / model service

extension:
→ policy decision
→ capability
→ delegation
→ external effect
```

Każdy endpoint generuje lokalny **signed tamper-evident execution record**. Domena koreluje takie rekordy w **Domain Provenance Graph**, natomiast federacja nie musi zbierać wszystkich surowych eventów; może utrzymywać jedynie indeks pozwalający odnaleźć właściwy dowód. Taki trójpoziomowy podział `RAW TELEMETRY → LOCAL EVIDENCE → DOMAIN SUMMARY → GLOBAL INDEX` jest częścią projektowanego mesha.

---

# 6. Obserwowalność nie jest loggingiem

W tej architekturze obserwowalność nie oznacza „wysyłania wszystkiego do SIEM”.

Jądro może emitować bardzo dużą liczbę zdarzeń. Pełne rejestrowanie każdego syscalla każdego agenta szybko doprowadziłoby do znacznego narzutu i mogłoby paradoksalnie osłabić system przez przeciążenie kolektora.

Linux udostępnia **Pressure Stall Information**, które mierzy presję CPU, pamięci i I/O, również dla poszczególnych cgroups, oraz umożliwia budowę triggerów. Dokumentacja wskazuje możliwość dynamicznego reagowania na presję m.in. przez load shedding, migrację lub zatrzymywanie workloadów.

W mesh oznacza to możliwość wykrycia nie tylko zagrożenia bezpośredniego, ale również kaskady:

```text
RESOURCE PRESSURE
→ COLLECTOR DELAY
→ QUEUE GROWTH
→ EVENT LOSS
→ PROVENANCE UNCERTAINTY
→ AUTHORIZATION DEGRADATION
```

Obserwowalność powinna więc sama mieć obserwowalność.

Każdy sensor otrzymuje stan:

```text
health
coverage
confidence
drop_count
sequence
timestamp_quality
trust_class
```

a domenowy State Reconstruction Engine wykonuje:

```text
LOCAL OBSERVATIONS
→ CORRELATION
→ STATE ESTIMATION
→ CONFIDENCE
→ POLICY INPUT
```

To odpowiada technicznemu pojęciu **distributed multi-sensor telemetry fusion and state reconstruction**.

OpenAI Agents SDK dostarcza warstwę aplikacyjną: trace może zawierać cały run, model calls, tool calls, handoffs, guardrails i custom spans. Takiego trace’u nie należy jednak utożsamiać z obserwacją kernela. Jest to **provider/application telemetry**, a nie dowód, że konkretny lokalny proces wykonał określony efekt.

Rozdzielenie control plane i compute jest zresztą zgodne z aktualną dokumentacją OpenAI: harness jest opisany jako control plane właścicielsko zarządzający pętlą agenta, tool routingiem, approvals, tracingiem, recovery i run state, podczas gdy sandbox stanowi execution plane wykonujący komendy i operacje na plikach.

Mesh rozszerza tę zasadę poza jeden sandbox.

---

# 7. Granica efektu: jedyne miejsce, którego nie wolno ominąć

Najsilniejsza wersja domeny posiada właściwość:

```text
ALL MANAGED AGENT EFFECTS
∈
CONTROLLED EXECUTION DOMAIN
```

Nie może istnieć poprawna ścieżka:

```text
AGENT
→ unmanaged socket
→ Internet
```

ani:

```text
AGENT
→ inherited credential
→ production
```

ani:

```text
AGENT
→ uncontrolled helper
→ privileged shell
```

Źródłowa architektura określa w tym celu **External Effect Gateway**, który wiąże identity, policy, capability, data classification, transaction record oraz finalny rezultat operacji.

Jest to szczególnie istotne dla zaszyfrowanych protokołów aplikacyjnych. Kernel może kontrolować proces, socket, adres i port, ale z poziomu L3/L4 nie zna semantyki żądania HTTPS. Nie wie, czy agent pobiera rekord, czy usuwa konto.

Dlatego operacja wysokiego wpływu powinna wyglądać:

```text
MODEL INTENT
→ NORMALIZED ACTION
→ PDP
→ CAPABILITY
→ APPLICATION EFFECT GATEWAY
→ REMOTE SERVICE
```

Zewnętrzna brama jest zatem aplikacyjnym PEP.

Dla operacji nieodwracalnych należy dołożyć semantykę transakcyjną:

```text
INTENT
→ DURABLE PREPARE RECORD
→ AUTHORIZATION
→ STAGED EXECUTION
→ COMMIT GATE
→ EFFECT
→ ACKNOWLEDGEMENT
→ FINAL RECORD
```

Model ten został wcześniej wyprowadzony jako konieczne techniczne rozwinięcie reguły `NO PROVENANCE → NO EFFECT`.

Dopiero taki układ daje realną możliwość zatrzymania działania **przed** skutkiem.

---

# 8. Federacja domen

Przy większej skali pojedynczy control plane staje się niewystarczający. Powstaje:

```text
GLOBAL AGENT FABRIC
│
├── DOMAIN A
│   ├── endpoints
│   └── agents
│
├── DOMAIN B
│   ├── endpoints
│   └── agents
│
└── DOMAIN C
    └── high-risk KVM workers
```

Ponad nimi znajduje się **Federated Trust Plane**, który obsługuje domain identity, attestation, cross-domain delegation, policy federation, provenance exchange oraz degradację zaufania. Taka hierarchia została wyprowadzona już w modelu domenowym.

Federacja nie powinna jednak oznaczać federacji implicit trust.

```text
DOMAIN_A trusts AGENT_A
```

nie implikuje:

```text
DOMAIN_B trusts AGENT_A
```

Cross-domain operation powinna wyglądać:

```text
DOMAIN A
→ authenticated gateway
→ cross-domain policy evaluation
→ capability re-issuance
→ DOMAIN B
```

Każda domena zachowuje własny `authority_ceiling`.

Tutaj model zaczyna przypominać Zero Trust nie tylko na poziomie urządzeń i usług, ale na poziomie **społeczności procesów decyzyjnych**.

---

# 9. Integracja z SOC: od syscalla do zdarzenia semantycznego

SOC nie powinien otrzymywać miliona niezależnych syscalli i próbować z nich zgadywać, co robił agent.

Powinien dostawać dwie klasy danych.

Pierwsza to surowa lub częściowo zagregowana telemetryka techniczna potrzebna do dochodzeń:

```text
BPF
Audit
LSM
network
process
filesystem
API trace
```

Druga, znacznie ważniejsza operacyjnie, to **semantic security events**:

```text
AGENT_STARTED
TOOL_PROPOSED
TOOL_AUTHORIZED
TOOL_DENIED

CAPABILITY_ISSUED
CAPABILITY_USED
CAPABILITY_REVOKED

DELEGATION_REQUESTED
DELEGATION_DENIED

POLICY_VIOLATION

OBSERVABILITY_DEGRADED
OBSERVABILITY_FAILED

ATTESTATION_FAILED

UNEXPECTED_PROCESS
UNAUTHORIZED_EXEC
UNAUTHORIZED_NETWORK

HIGH_IMPACT_ACTION
HIGH_IMPACT_ACTION_BLOCKED

AGENT_FROZEN
DOMAIN_QUARANTINED
```

Taki podział jest przewidziany w modelu integracji SOC przygotowanym dla mesha.

Do transportu telemetryki można wykorzystać **OpenTelemetry**. Jego stabilny Logs Data Model posiada między innymi `Timestamp`, `ObservedTimestamp`, `TraceId`, `SpanId`, severity, resource oraz dowolne attributes. Jest więc dobrym nośnikiem do korelacji zdarzeń agentowych z istniejącym observability pipeline.

Dla warstwy security normalization naturalnym kandydatem jest **OCSF**, który definiuje vendor-neutral kategorie, event classes, objects i attribute dictionary oraz jest przeznaczony do reprezentowania security events niezależnie od konkretnej implementacji czy storage.

Nie oznacza to jednak, że OCSF posiada obecnie natywne klasy odpowiadające pełnemu agentowemu provenance. Praktyczna implementacja będzie wymagała profilu lub rozszerzenia dla takich pól jak:

```text
domain_id
agent_instance_id
model_id
run_id
action_id
parent_action_id
policy_id
capability_id
delegation_id
observer_health
provenance_reference
attestation_reference
```

Najważniejszą jednostką korelacji staje się `action_id`.

Dzięki temu analityk SOC nie pyta:

> „Co robił proces PID 34821?”

ale:

> „Która decyzja modelu doprowadziła do tej operacji, z czyjego uprawnienia, przez którą capability i przy jakim stanie obserwowalności?”

---

# 10. Detection engineering dla agentów

Klasyczny zestaw detekcji EDR nadal pozostaje użyteczny, lecz nie obejmuje semantyki autoryzacji agentowej.

Powstają nowe rodziny detekcji.

### Authority escalation

```text
requested_authority
>
agent_authority_ceiling
```

Agent próbuje uzyskać operację przekraczającą klasę przypisaną jego domenie.

### Authority laundering

```text
Agent A
→ Agent B
→ EFFECT
```

bez:

```text
new capability issuance
```

Oznacza to, że delegacja została przeprowadzona poza kontrolowanym mechanizmem.

### Provenance break

```text
EFFECT EXISTS
AND
action_id IS UNKNOWN
```

W zarządzanej domenie wysokiego assurance jest to zdarzenie krytyczne.

### Unobserved execution

```text
PROCESS EXECUTES
AND
run_id IS UNKNOWN
```

Proces nie należy do żadnego zarejestrowanego przebiegu.

### Policy bypass

```text
EFFECT EXISTS
AND
NO PDP DECISION
```

### Egress bypass

```text
OUTBOUND CONNECTION
AND
NO AUTHORIZED EFFECT GATEWAY
```

### Execution substitution

```text
expected executable digest
≠
observed executable digest
```

### Observability failure under active authority

```text
observer_health = FAILED
AND
active_high_impact_capability = TRUE
```

To ostatnie zdarzenie jest szczególnie istotne. W klasycznym systemie oznaczałoby głównie awarię monitoringu. W Mesh jest jednocześnie **naruszeniem warunku autoryzacji**.

---

# 11. SOAR nie tylko odpowiada — zmienia topologię działania

SOAR może wykorzystać zdarzenia mesha do reakcji bezpośrednio na mechanizmach kernela i control plane’u.

Przykładowo:

```text
CAPABILITY_ABUSE
→ revoke capability
→ block egress
→ freeze worker cgroup
→ preserve evidence
→ alert SOC
```

Dla awarii atestacji:

```text
ATTESTATION_FAILED
→ stop new runs
→ revoke domain credential
→ quarantine endpoint
```

Dla utraty obserwowalności:

```text
OBSERVABILITY_FAILED
→ deny R3–R5 operations
→ restrict agents to read-only
→ freeze active high-impact workers
→ collect diagnostics
```

Dla kompromitacji całej domeny:

```text
DOMAIN_COMPROMISED
→ revoke inter-domain trust
→ isolate gateways
→ stop capability issuance
→ preserve provenance graph
```

Na Linux fizyczna reakcja może wykorzystywać między innymi cgroup, sieciowe PEP, mechanizmy MAC oraz unieważnianie poświadczeń. Nie każda reakcja powinna oznaczać zabicie procesu; degradacja powinna być proporcjonalna do znaczenia brakującego sygnału.

Kluczowy podział pozostaje następujący:

```text
DETECTION
→ DECISION
→ CONTAINMENT
→ ERADICATION
→ RECOVERY
```

SOC nie jest przy tym **root of trust**. SIEM może być niedostępny bez utraty lokalnej egzekucji. PEP musi działać również w warunkach zerwanej łączności z SIEM; w przeciwnym razie awaria narzędzia analitycznego stawałaby się awarią mechanizmu bezpieczeństwa.

---

# 12. Klasy ryzyka i różne poziomy assurance

Nie wszystkie działania wymagają microVM, zdalnej atestacji, podpisanego receipt i zatwierdzenia człowieka.

Można zastosować klasy:

```text
R0 — observation only
R1 — read
R2 — local modification
R3 — reversible external effect
R4 — high-impact external effect
R5 — critical / irreversible effect
```

Dla `R0–R1` wystarczający może być proces izolowany przez cgroup, namespaces, MAC i seccomp.

`R2` wymaga silnego związania `action_id` z procesem i kontrolowanego zapisu.

`R3` powinien przechodzić przez Effect Gateway.

`R4` wymaga pełnego provenance, zdrowej obserwowalności, silnego workload identity i zwykle dodatkowego approval.

`R5` powinien być wykonywany w najmocniej izolowanym środowisku, przykładowo osobnej VM lub microVM, posiadać transakcyjny commit gate i często obowiązkowy human-in-the-loop.

To nie jest tylko model bezpieczeństwa. Jest to również mechanizm kontroli kosztu.

Pełne śledzenie wszystkiego byłoby niewykonalne. Projekt powinien znaleźć **minimal sufficient observability** dla każdej klasy operacji. To odpowiada źródłowemu wymaganiu, aby maksymalna obserwowalność nie niszczyła wykonalności systemu.

---

# 13. Wdrożenie organizacyjne

Najbezpieczniejsza implementacja nie zaczyna się od organizacji posiadającej tysiące agentów.

### Etap laboratoryjny

```text
1 host
1 domain
1 agent
read-only
```

Celem nie jest produktywność, lecz udowodnienie pełnego przypisania:

```text
MODEL
→ ACTION
→ PDP
→ CAPABILITY
→ PROCESS
→ EFFECT
```

### Controlled Endpoint Mesh

Kolejny etap może obejmować kilkadziesiąt hostów, centralny PDP, domenowy Provenance Service i integrację SOC. Tutaj badane są awarie, propagation policy oraz spójność identyfikatorów.

### Multi-Domain

Następnie oddzielane są funkcje:

```text
RESEARCH
CODE
SECURITY
OPERATIONS
```

i wprowadzany jest cross-domain gateway.

### High-Impact Execution

Dopiero tutaj pojawiają się production capabilities, KVM/microVM, human approval i transactional Effect Gateway.

### Federated Mesh

Ostatni etap obejmuje wiele lokalizacji lub chmur, lokalne domain control planes, federacyjny trust plane, regionalny SOC i globalny indeks provenance.

Taki progresywny model wdrożeniowy został przewidziany w specyfikacji mesha i pozwala mierzyć każdą zmianę przed zwiększeniem authority ceiling.

Lifecycle aktualizacji powinien natomiast wyglądać:

```text
ACTIVE
→ DRAIN
→ STOP NEW RUNS
→ UPDATE
→ RE-ATTEST
→ VALIDATE POLICY
→ CANARY RUN
→ ACTIVE
```

Kernel, BPF programs, LSM policies, seccomp profiles, agent runtimes, model identities, tool versions i schema versions muszą być elementami tego samego zarządzanego lifecycle.

---

# 14. Falsyfikacja: kiedy nie wolno twierdzić, że mesh działa

Najważniejszą częścią naukowego modelu bezpieczeństwa nie jest lista mechanizmów ochronnych, ale warunki obalenia hipotezy.

Hipoteza brzmi:

> Możliwe jest zbudowanie populacji agentów AI jako programowo definiowanej domeny bezpieczeństwa Linux, w której autonomia jest ograniczona przez topologię autoryzowanych relacji, egzekwowanie na poziomie systemu, obserwowalność i provenance.

Hipoteza zostaje sfalsyfikowana, jeśli istnieje powtarzalna sytuacja:

```text
HIGH_IMPACT_EFFECT
AND
NO AUTHORIZATION PATH
```

lub:

```text
HIGH_IMPACT_EFFECT
AND
NO PROVENANCE PATH
```

lub:

```text
HIGH_IMPACT_EFFECT
AND
OBSERVABILITY = FAILED
```

lub:

```text
REVOKE REQUESTED
AND
EFFECT STILL REACHABLE
```

Są to również warunki sukcesu przewidziane w bazowym modelu.

Najsilniejszym kontrprzykładem jest kompromitacja Trusted Computing Base. Jeżeli napastnik jednocześnie przejmie kernel, PEP, kolektor, Policy Decision Point i klucz podpisujący, może potencjalnie wytwarzać spójny fałszywy obraz własnego działania. Atestacja ogranicza to ryzyko, lecz nie eliminuje całkowicie problemu przejętego runtime’u. Dlatego zewnętrzny Verifier oraz separacja Attesting Environment od Target Environment są istotne; architektura RATS zwraca szczególną uwagę na ochronę tych granic.

Drugim fundamentalnym ograniczeniem jest granica dostawcy modelu. Lokalny kernel Linux nie może zaobserwować syscalli wykonywanych wewnątrz infrastruktury OpenAI. Może natomiast kontrolować dane wysyłane do tej domeny, lokalny harness, własne function tools, credentials, local shell oraz lokalne i zewnętrzne efekty przechodzące przez zarządzane bramy. Źródłowy model explicite rozdziela lokalny execution plane od OpenAI inference domain.

---

# Konkluzja: autonomia jako topologia, nie cecha modelu

Najważniejszym wnioskiem z przedstawionej architektury jest zmiana definicji autonomii.

W tradycyjnej narracji agent jest „bardziej autonomiczny”, kiedy model potrafi planować dłużej, korzystać z większej liczby narzędzi albo samodzielnie wykonywać więcej etapów zadania.

Z perspektywy systemowej jest to definicja niewystarczająca.

Autonomia operacyjna powinna być opisana jako:

```text
AUTONOMY
=
REACHABLE AUTHORIZED STATE SPACE
```

w warunkach:

```text
current identity
+ current policy
+ current platform integrity
+ current provenance
+ current observability
```

Koncepcja ta została pierwotnie sformułowana jako `S_agent ⊆ S_domain`: autonomia agenta wynika z przestrzeni stanów dopuszczonej przez domenę, a nie z deklaracji zapisanej w promptcie.

Właśnie tutaj Linux Multi-Agent Control Mesh wykracza poza tradycyjny service mesh.

Nie kontroluje wyłącznie:

```text
WHO MAY TALK TO WHOM
```

lecz:

```text
WHO
→ MAY REQUEST WHAT
→ USING WHICH AUTHORITY
→ THROUGH WHICH AGENT
→ WITH WHICH MODEL
→ IN WHICH PROCESS
→ AGAINST WHICH RESOURCE
→ UNDER WHICH OBSERVABILITY STATE
→ PRODUCING WHICH EFFECT
```

Ostateczna architektura przyjmuje więc formę:

```text
                         GLOBAL POLICY
                              │
                              ▼
                     FEDERATED TRUST PLANE
                              │
                 ┌────────────┼────────────┐
                 ▼            ▼            ▼
              DOMAIN A     DOMAIN B     DOMAIN C
                 │
                 ▼
              ENDPOINT
                 │
        ┌────────┼─────────┐
        ▼        ▼         ▼
      DATA    AUTHORITY  EXECUTION
      GRAPH     GRAPH      GRAPH
        └────────┬─────────┘
                 ▼
         OBSERVABILITY GRAPH
                 │
                 ▼
           STATE ESTIMATE
                 │
                 ▼
          POLICY DECISION
                 │
                 ▼
        AUTHORIZED STATE SPACE
                 │
                 ▼
              EFFECT
                 │
                 ▼
        PROVENANCE / ATTESTATION
                 │
                 ▼
             SOC / SIEM
                 │
                 ▼
               SOAR
                 │
                 └──────────────→ REVOKE / FREEZE / QUARANTINE
```

Nie jest to obecnie gotowy standard ani pojedynczy dostępny produkt. **Jest to propozycja architektury**, której zasadnicze elementy można jednak skonstruować już na Linux 7.1.8 z istniejących prymitywów kernela, mechanizmów Zero Trust, RATS, provenance i obserwowalności. Aktualny Linux dostarcza cgroups, namespaces, seccomp, LSM/BPF LSM, Landlock, IPE, mechanizmy integrity i telemetrykę niezbędną do silnej kontroli lokalnego execution plane.

Największa luka pozostaje natomiast na styku:

```text
REMOTE MODEL
↔ LOCAL HARNESS
↔ LOCAL EXECUTION
↔ EXTERNAL EFFECT
```

i właśnie tę lukę ma zamknąć mesh.

Jego ostateczna zasada nie brzmi zatem:

**„obserwujmy agentów”.**

Brzmi:

```text
IF THE SYSTEM CANNOT
IDENTIFY,
AUTHORIZE,
OBSERVE,
RECONSTRUCT
AND REVOKE
AN ACTION,

THEN THAT ACTION
MUST NOT POSSESS
HIGH-IMPACT AUTHORITY.
```

To przekształca obserwowalność z funkcji operacyjnej w **warunek sprawczości**, Linux z systemu hostującego agentów w **substrat ich topologii bezpieczeństwa**, a SOC z miejsca zbierania alertów w nadrzędną warstwę rekonstrukcji i reagowania — bez nadawania mu roli jedynego root of trust.

## Powiązane opracowanie: Observability-Conditioned Reference Monitor

Ten artykuł rozwija architekturę wieloagentową na poziomie domen, endpointów, federacji i integracji z SOC. Jego bezpośrednią podstawą jest wcześniejsze opracowanie **Observability-Conditioned Reference Monitor with Runtime Assurance and Execution Attestation**, które definiuje mechanizm kontroli pojedynczego lokalnego wykonania agenta na Linux.

W tamtym modelu obserwowalność nie jest traktowana jako warstwa telemetryczna dodawana po wykonaniu, lecz jako warunek dopuszczenia działania. Architektura łączy **reference monitor, complete mediation, Policy Decision Point / Policy Enforcement Point, runtime assurance, execution provenance oraz attestation**, a zdolność agenta do powodowania skutków jest uzależniona od aktualnego stanu obserwowalności, integralności platformy i możliwości rekonstrukcji wykonania.

Linux Multi-Agent Control Mesh opisany w niniejszym dokumencie należy traktować jako rozwinięcie tej koncepcji z poziomu:

```text
SINGLE AGENT
→ LOCAL EXECUTION
→ LOCAL REFERENCE MONITOR
```

do poziomu:

```text
ENDPOINT
→ AGENT DOMAIN
→ MULTI-AGENT CONTROL MESH
→ FEDERATED TRUST PLANE
→ SOC / SIEM / SOAR
```

Pełne opracowanie bazowe:

[**OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md — GitHub**](https://github.com/DonkeyJJLove/writeups/blob/master/OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md)
