# Hybrydowy AI Governance Proxy jako warstwa kontroli decyzji, procesu i zaufania

## Enterprise Architecture Blueprint dla organizacji używających modeli lokalnych, chmurowych i specjalizowanych

## Abstrakt

Organizacja, która dopuszcza użycie modeli AI bez warstwy kontroli przepływu danych, buduje system generowania odpowiedzi, ale nie buduje systemu zaufanych decyzji. Organizacja, która zakazuje AI bez dostarczenia kanału kontrolowanego, przesuwa użycie do Shadow AI: prywatnych kont, prywatnych urządzeń, nieautoryzowanych modeli i nieaudytowalnych przepływów danych. W obu przypadkach brakuje najważniejszego elementu: deterministycznej, odtwarzalnej i ograniczonej polityką kontroli nad tym, co model może zobaczyć, jak dane zostały przekształcone, dlaczego wybrano dany model, kto zaakceptował ryzyko i jaki dowód procesu trafił do audytu.

Ten artykuł opisuje architekturę hybrydowego AI Governance Proxy jako techniczny wzorzec kontroli logiki decyzji, procesów i zaufania. Rdzeń architektury tworzą trzy współpracujące komponenty: lokalny agent endpointowy, centralny AI Governance Gateway oraz dedykowany Token Vault. Agent widzi kontekst lokalny i przechwytuje treść przed wysłaniem do kanału TLS lub warstwy API. Gateway wykonuje głębszą klasyfikację, egzekwuje polityki, wybiera model i generuje manifest decyzji. Token Vault przechowuje mapy tokenów, dowody transformacji oraz materiał kryptograficzny potrzebny do bezpiecznej rekontekstualizacji. System nie loguje surowych promptów ani pełnych odpowiedzi do SIEM/SOAR. Loguje dowód decyzji: hash transakcji, identyfikator polityki, wersje komponentów, typ akcji, skróty HMAC wykrytych spanów, routing, decyzję modelową, wynik filtracji i atestację wykonania polityki.

Architektura jest hybrydowa nie z powodów marketingowych, lecz dlatego, że żaden pojedynczy komponent nie ma pełnej widoczności. Endpoint widzi clipboard, pliki lokalne, aplikację źródłową, DOM przeglądarki, okno edytora, ścieżkę dokumentu i lokalny kontekst użytkownika. Gateway widzi ruch aplikacyjny, identyfikację SSO, model target, rate limiting, wersje polityk i centralną telemetrię. Token Vault utrzymuje odwracalność tylko tam, gdzie jest potrzebna, i nie powinien być mieszany z logami SIEM. SIEM/SOAR dostaje dowód procesu, a nie dane, które miał chronić.

## 1. Teza architektoniczna

System AI Governance nie jest filtrem promptów. Filtr promptów jest pojedynczym punktem kontroli syntaktycznej. AI Governance Proxy jest warstwą sterowania przepływem informacji, decyzji i odpowiedzialności. Jego funkcją nie jest proste pytanie „czy wolno wysłać prompt?”, ale wykonanie pełnej procedury:

```text
capture
→ normalize
→ classify
→ decide
→ transform
→ tokenize
→ route
→ evaluate
→ filter
→ recontextualize
→ attest
→ audit
```

Dopiero taki łańcuch tworzy system decyzji. Model LLM jest w nim jednym z wykonawców, nie centrum zaufania. Centrum zaufania znajduje się w kontrolowanej sekwencji: klasyfikator danych, policy engine, transformation engine, Token Vault, model router, response filter, lokalna rekontekstualizacja i audit fabric.

Kluczowy podział jest następujący:

```text
LLM odpowiada na pytanie:
„jaka odpowiedź jest najbardziej użyteczna dla danego zadania?”

AI Governance Proxy odpowiada na pytania:
„czy model może zobaczyć te dane?”
„w jakiej reprezentacji może je zobaczyć?”
„który model może je przetwarzać?”
„czy potrzebna jest zgoda człowieka?”
„jak udowodnić, że decyzja była zgodna z polityką?”
```

W tym ujęciu governance nie jest dekoracją. Jest warstwą sterowania. Bez niej model AI jest narzędziem generowania treści. Z nią staje się częścią kontrolowanego procesu organizacyjnego.

## 2. Shadow AI jako awaria architektury, nie problem dyscypliny użytkownika

Shadow AI nie powstaje dlatego, że użytkownicy są z natury nieposłuszni. Powstaje wtedy, gdy organizacja ma realną potrzebę użycia AI, ale nie dostarcza kanału o odpowiedniej użyteczności, jakości i dostępności. Zakaz bez alternatywy tworzy presję obejścia. Użytkownik nie przestaje potrzebować streszczenia kontraktu, analizy logów, pomocy przy kodzie, klasyfikacji incydentu lub weryfikacji dokumentacji. Zmienia tylko kanał: prywatne konto, prywatne urządzenie, niezarządzany chatbot, niekontrolowany upload.

Z punktu widzenia bezpieczeństwa to jest utrata telemetryki. Organizacja traci odpowiedź na podstawowe pytania:

```text
kto wysłał dane?
jakie dane wysłał?
czy dane zawierały PII, tajemnice, sekrety, kod, dane infrastrukturalne?
do jakiego modelu trafiły?
czy zostały przekształcone?
czy odpowiedź została potem użyta w decyzji?
czy proces da się odtworzyć?
```

Zakaz AI bez kanału kontrolowanego zamienia ryzyko jawne w ryzyko ukryte. Dlatego celem architektury nie jest „pozwolić na wszystko”, ale zbudować kanał, który jest wystarczająco wygodny, aby użytkownicy nie musieli go obchodzić, i wystarczająco restrykcyjny, aby dane wysokiego ryzyka nie trafiały do modeli w postaci surowej.

W praktyce oznacza to model kontroli warstwowej, a nie model binarny. Dane publiczne mogą przejść bez zmian. Dane wewnętrzne mogą zostać zmaskowane. Dane infrastrukturalne mogą zostać tokenizowane. Dane kontraktowe mogą zostać streszczone. Kod może zostać przekształcony do AST, call graph i wyników SAST. Prywatny klucz musi zostać zablokowany. Sporny dokument prawny lub incydent M&A musi trafić do human approval.

## 3. Analogia techniczna: AI Factory i Governance Factory

W architekturze obliczeniowej AI surowe TFLOPS nie determinują samodzielnie wydajności LLM. Model treningowy lub inferencyjny jest ograniczony przez pamięć HBM, przepustowość interconnectu, topologię NVLink/NVSwitch lub odpowiedników, komunikację między węzłami, runtime, compiler, biblioteki kernelowe, scheduler, collective operations, storage feed, observability i narzut orchestration. GPU bez szybkiej pamięci, interconnectu i dojrzałego software stacku jest tylko akceleratorem, nie fabryką AI.

Ten sam wzorzec obowiązuje w AI Governance. Pojedynczy filtr promptów jest odpowiednikiem pojedynczego rdzenia obliczeniowego bez pamięci, magistrali i runtime’u. Może wykonać lokalną operację, ale nie zarządza przepływem całego systemu. Nie widzi kontekstu endpointu, nie posiada lokalnej mapy tokenów, nie rozumie właściciela danych, nie wykonuje rekontekstualizacji, nie generuje wystarczającego dowodu audytowego, nie wie, czy dane powinny trafić do modelu lokalnego, czy chmurowego.

Porównanie jest techniczne, nie ozdobne:

```text
AI Factory:
GPU/NPU/ASIC
+ HBM
+ NVLink / interconnect
+ runtime
+ CUDA / ROCm / XLA / Neuron
+ scheduler
+ telemetry
+ cloud fabric

Governance Factory:
local agent
+ data classifier
+ policy engine
+ transformation engine
+ Token Vault
+ model router
+ response filter
+ local recontextualization
+ audit fabric
+ SIEM/SOAR
```

W AI Factory bottleneckiem bywa nie sam rdzeń, lecz ruch danych między pamięcią, akceleratorami i siecią. W Governance Factory bottleneckiem nie jest samo wykrycie słowa „PESEL” albo „api_key”, lecz utrzymanie użyteczności po transformacji danych, zachowanie korelacji między tokenami, odtworzenie decyzji, redukcja false positives, kontrola egress oraz brak kopiowania danych do logów.

Wdrożenie oparte wyłącznie o prompt filtering ma trzy typowe skutki. Po pierwsze, tworzy latency bottleneck, bo każda decyzja jest serializowana przez jeden centralny filtr, często bez lokalnego kontekstu. Po drugie, powoduje overblocking, ponieważ filtr nie potrafi odróżnić danych potrzebnych do rekontekstualizacji od danych faktycznie zbędnych. Po trzecie, wypycha użytkowników poza system, bo praca staje się wolna, nieprzewidywalna i nieużyteczna.

Dojrzała architektura rozkłada obciążenie: agent lokalny wykonuje szybkie rozpoznanie i przechwyt kontekstu, gateway wykonuje decyzję centralną, Token Vault obsługuje odwracalność, a SIEM dostaje wyłącznie dowód, nie payload. To jest odpowiednik przejścia z pojedynczego chipa do pełnego rack-scale systemu.

## 4. Architektura hybrydowa: Agent + Gateway + Token Vault

### 4.1. Widok logiczny

```text
[USER / APPLICATION]
        |
        v
[LOCAL AGENT / BROWSER EXTENSION / SDK WRAPPER]
        |
        |  capture, local context, shallow classification,
        |  local token hints, pre-TLS interception in managed path
        v
[AI GOVERNANCE GATEWAY]
        |
        |  canonicalization, deep classification, policy evaluation,
        |  transformation orchestration, routing, response policy
        v
[TOKEN VAULT]
        |
        |  entity-token mapping, transaction-token mapping,
        |  envelope encryption, TTL, detokenization authorization
        v
[MODEL ROUTER]
   |          |             |
   v          v             v
[LOCAL]   [CLOUD LLM]   [SPECIALIZED MODEL]
   |          |             |
   +----------+-------------+
              |
              v
[RESPONSE FILTER]
              |
              v
[LOCAL RECONTEXTUALIZATION]
              |
              v
[USER OUTPUT]
              |
              v
[AUDIT FABRIC → SIEM/SOAR]
```

Architektura rozdziela widoczność i odpowiedzialność. Agent endpointowy nie powinien być miniaturowym SIEM-em. Gateway nie powinien udawać, że widzi kontekst lokalny. Token Vault nie powinien być logiem. SIEM/SOAR nie powinien otrzymywać surowych promptów. Każdy komponent ma wąską, precyzyjną funkcję.

### 4.2. Rola lokalnego agenta

Lokalny agent działa na granicy użytkownika, aplikacji i systemu operacyjnego. Jego zadaniem jest przechwycenie intencji i danych przed ich wysłaniem do modelu. Nie chodzi o niekontrolowany man-in-the-middle na cudzym TLS, lecz o kontrolowany punkt wejścia w zarządzanym środowisku: rozszerzenie przeglądarki, desktop agent, firmowy portal, SDK wrapper, local proxy dla zatwierdzonych aplikacji lub plugin do edytora.

Agent lokalny wykonuje następujące funkcje:

```text
1. capture
   przechwytuje prompt z portalu, przeglądarki, SDK, edytora, pliku lub clipboardu

2. context binding
   wiąże prompt z użytkownikiem, aplikacją, dokumentem, ścieżką pliku, repozytorium,
   ticketem, klasyfikacją dokumentu lub kontekstem biznesowym

3. shallow classification
   wykonuje szybkie reguły lokalne: regex, entropy check, secret patterns,
   wykrywanie PII, hostnames, IP, PESEL, NIP, IBAN, kluczy API, nazw repozytoriów

4. pre-normalization
   normalizuje format wejścia, separuje instrukcję użytkownika od danych,
   wyodrębnia bloki kodu, logi, tabele, załączniki i metadane

5. local token hinting
   oznacza span jako kandydat do tokenizacji, maskowania, streszczenia lub blokady

6. policy pre-check
   blokuje oczywiste przypadki: prywatne klucze, hasła, pełne bazy klientów,
   sekrety produkcyjne, pliki niezgodne z polityką

7. secure envelope
   pakuje żądanie do struktury zawierającej kontekst, wstępną klasyfikację,
   hashe spanów i identyfikator sesji

8. local recontextualization
   po odpowiedzi modelu odtwarza tokeny tylko w zakresie uprawnień użytkownika
```

Agent jest miejscem, gdzie można zachować użyteczność. Jeżeli użytkownik pracuje w SOC, agent wie, że tekst pochodzi z ticketu incydentowego, z konsoli EDR albo z pliku logów. Jeżeli użytkownik pracuje w AppSec, agent może rozpoznać repozytorium, branch, wynik SAST i fragment AST. Jeżeli użytkownik analizuje umowę, agent może rozpoznać typ dokumentu, klasyfikację poufności i źródło pliku.

Bez tej warstwy centralny gateway widzi tylko tekst. Tekst bez kontekstu jest podatny na dwie skrajności: zbyt luźne przepuszczanie albo zbyt agresywną blokadę.

### 4.3. Rola centralnego AI Governance Gateway

Centralny gateway jest punktem egzekucji polityki. Przyjmuje envelope od agenta, wykonuje głębszą analizę, podejmuje decyzję transformacyjną i wybiera model. To gateway powinien być miejscem wersjonowania polityk, integracji z IAM/SSO, rate limitingiem, routingiem modeli, approval workflow, response filteringiem i eksportem zdarzeń do SIEM/SOAR.

Gateway wykonuje następujące funkcje:

```text
1. canonicalization
   sprowadza request do deterministycznej reprezentacji decyzyjnej

2. deep classification
   łączy sygnały lokalne z klasyfikatorami centralnymi:
   DLP, NER, słowniki domenowe, CMDB, repo metadata, SAST, MITRE/CVE ontology

3. policy evaluation
   ocenia request względem polityk organizacyjnych:
   data class, user role, use case, model target, region, provider, risk score

4. transformation orchestration
   wybiera akcje: ALLOW, REDACT, MASK, TOKENIZE, SUMMARIZE, ABSTRACT, BLOCK, ESCALATE

5. tokenization orchestration
   zleca Token Vault utworzenie tokenów referencyjnych i zapis mapy

6. safe prompt construction
   buduje prompt bezpieczny: oddziela instrukcję od danych, usuwa raw secrets,
   zastępuje encje tokenami, streszcza albo abstrahuje załączniki

7. model routing
   wybiera local model, cloud model, specialized model albo human approval

8. response filtering
   analizuje odpowiedź pod kątem wycieku tokenów, danych wrażliwych,
   prompt injection continuation, tool escape, unsafe instructions

9. attestation
   generuje deterministyczny dowód decyzji i manifest transformacji

10. audit export
   wysyła do SIEM/SOAR wyłącznie event dowodowy, bez raw promptu i bez raw response
```

Gateway nie powinien być jedynie reverse proxy do API modeli. Reverse proxy kontroluje transport. AI Governance Gateway kontroluje semantykę procesu. To różnica zasadnicza.

### 4.4. Rola Token Vault

Token Vault jest komponentem odpowiedzialnym za odwracalną pseudonimizację i separację danych od logiki modelowej. Jego zadanie nie polega tylko na zamianie `Jan Kowalski` na `USER_TOKEN_18`. Token Vault musi utrzymywać relacje między tokenami, kontekstem, sesją, polityką, właścicielem danych, TTL, uprawnieniami do detokenizacji i audytem dostępu.

Token Vault powinien przechowywać:

```text
token_id
tenant_id
domain_id
case_id
session_id
original_value_encrypted
value_type
classification_level
reversibility_flag
created_by_component
created_at
ttl
detokenization_policy
key_reference
span_hmac
transformation_id
```

Token Vault nie powinien wysyłać map tokenów do SIEM. SIEM dostaje `token_id`, `span_hmac`, typ transformacji i dowód polityki. Oryginalna wartość pozostaje zaszyfrowana w vault, najlepiej z envelope encryption, kluczami domenowymi i kontrolą dostępu opartą o IAM, role biznesowe oraz kontekst sprawy.

Token Vault jest krytyczny, ponieważ rozwiązuje sprzeczność między minimalizacją danych a użytecznością. Model może pracować na `ASSET_TOKEN_41`, ale SOC po uzyskaniu odpowiedzi musi wiedzieć, że chodzi o konkretny serwer. Model może pracować na `CLIENT_TOKEN_07`, ale dział prawny musi umieć odtworzyć nazwę klienta w dokumencie końcowym. Model może widzieć `LIB_TOKEN_11`, ale AppSec musi wiedzieć, do której biblioteki wewnętrznej odnosi się rekomendacja.

## 5. Dual-Tokenization: tokenizacja treści i tokenizacja decyzji

Jednowarstwowa tokenizacja nie wystarcza. System potrzebuje dwóch niezależnych warstw tokenów:

```text
Content Tokens
  tokeny zastępujące encje w treści promptu

Decision Tokens
  tokeny/dowody opisujące decyzję, span, politykę i transformację
```

### 5.1. Content Tokens

Content Tokens zastępują wartości, których model nie powinien widzieć w postaci surowej. Przykłady:

```text
SRV-FIN-02               → ASSET_TOKEN_41
jan.kowalski             → USER_TOKEN_18
185.203.x.x              → ENDPOINT_TOKEN_04
payments-core            → REPO_TOKEN_09
ABC Sp. z o.o.           → CLIENT_TOKEN_12
/api/v2/payouts/export   → API_ROUTE_TOKEN_31
INC-94822                → CASE_TOKEN_94822
```

Tokeny te są semantyczne. Ich prefiks informuje model o klasie obiektu, ale nie ujawnia wartości. To ważne: `ASSET_TOKEN_41` niesie informację, że chodzi o zasób techniczny, a `USER_TOKEN_18` — że chodzi o użytkownika. Model zachowuje możliwość rozumowania o relacjach, ale nie widzi danych identyfikujących.

### 5.2. Decision Tokens

Decision Tokens nie służą modelowi. Służą audytowi, atestacji i odtwarzalności procesu. Są to identyfikatory i skróty powiązane z decyzją:

```text
request_hash
safe_prompt_hash
policy_bundle_hash
classifier_version
gateway_version
transformation_manifest_hash
span_hmac
decision_proof_id
attestation_report_id
```

Content Token odpowiada na pytanie: „czym zastąpiono wrażliwą wartość?”.
Decision Token odpowiada na pytanie: „jak udowodnić, że zastąpienie wykonano zgodnie z polityką?”.

### 5.3. Sekwencja Dual-Tokenization

```text
[1] User prompt:
    "Przeanalizuj incydent na SRV-FIN-02.
     jan.kowalski wykonał transfer 14 GB do 185.203.x.x.
     Ticket INC-94822."

[2] Local Agent:
    - wykrywa hostname, user identifier, external endpoint, ticket ID
    - wylicza HMAC spanów
    - oznacza kandydatów do tokenizacji
    - dołącza kontekst: SOC-L2, incident_triage, restricted

[3] Gateway:
    - kanonikalizuje request
    - potwierdza klasyfikację
    - wybiera decyzję TOKENIZE
    - żąda tokenów od Token Vault

[4] Token Vault:
    - tworzy Content Tokens:
      SRV-FIN-02     → ASSET_TOKEN_41
      jan.kowalski   → USER_TOKEN_18
      185.203.x.x    → ENDPOINT_TOKEN_04
      INC-94822      → CASE_TOKEN_94822
    - zapisuje mapę pod encryption envelope
    - zwraca tokeny i transformation_id

[5] Gateway:
    - buduje safe prompt:
      "Przeanalizuj incydent na zasobie klasy serwer finansowy
       [ASSET_TOKEN_41]. Użytkownik [USER_TOKEN_18]
       wykonał transfer 14 GB do zewnętrznego punktu
       [ENDPOINT_TOKEN_04]. Sprawa [CASE_TOKEN_94822]."

[6] Cloud LLM:
    - widzi tokeny, nie widzi wartości oryginalnych
    - generuje hipotezy, triage, containment

[7] Response Filter:
    - sprawdza, czy odpowiedź nie próbuje odwracać tokenów
    - wykrywa niepożądane instrukcje lub ujawnienia
    - zatwierdza odpowiedź

[8] Local Recontextualization:
    - użytkownik z uprawnieniem SOC-L2 widzi odpowiedź z przywróconymi encjami
    - użytkownik bez uprawnienia widzi odpowiedź z tokenami lub klasami obiektów

[9] Audit:
    - SIEM dostaje policy proof, nie prompt
    - SOAR może uruchomić workflow containment, jeśli polityka na to pozwala
```

To jest zasadnicza różnica między prostą anonimizacją a kontrolowaną pseudonimizacją. Anonimizacja usuwa znaczenie. Tokenizacja z rekontekstualizacją zachowuje znaczenie lokalnie, ale nie ujawnia go modelowi.

## 6. Logowanie bez kopiowania danych: dowód decyzji, nie kopia payloadu

Największym błędem w projektowaniu AI Governance jest przesunięcie problemu wycieku z modelu do SIEM. Jeżeli system, który ma chronić dane, loguje pełne prompty i pełne odpowiedzi, sam staje się centralnym repozytorium PII, sekretów, kodu, danych klientów, incydentów bezpieczeństwa i dokumentów prawnych. To tworzy wtórny, często bardziej niebezpieczny zbiór danych niż pierwotne źródła.

Zasada powinna brzmieć:

```text
Audit log must prove the decision,
not reproduce the data.
```

SIEM/SOAR nie potrzebuje surowego promptu, aby wykryć wzrost liczby blokad sekretów, nietypowy routing do modeli chmurowych, naruszenie polityki, powtarzalne próby wysyłki danych `restricted`, wzrost `ESCALATE` w konkretnym dziale albo anomalię egress. SIEM potrzebuje strukturalnego dowodu procesu.

### 6.1. Czego nie wolno logować do SIEM/SOAR

Do logów centralnych nie powinny trafiać:

```text
raw_prompt
raw_response
pełne dane osobowe
pełne identyfikatory klientów
sekrety API
hasła
private keys
pełne fragmenty kodu produkcyjnego
pełne dokumenty prawne
pełne logi incydentowe zawierające hosty, konta, IP i ścieżki
pełna mapa tokenów
```

Wyjątki powinny wymagać oddzielnej procedury dowodowej, ograniczonego repozytorium, krótkiej retencji i zatwierdzenia właściciela danych. Domyślny SIEM event nie jest miejscem na payload.

### 6.2. Struktura logu zgodna z zasadą minimalizacji

Log powinien wyglądać jak deterministyczny raport decyzji:

```json
{
  "event_type": "AI_GOVERNANCE_DECISION",
  "request_id": "req-2026-06-16-000918",
  "tenant_id": "tenant-01",
  "user_ref": "usr_hmac:7b1f...",
  "session_ref": "sess_hmac:29aa...",
  "device_ref": "dev_hmac:9c21...",
  "business_context": {
    "use_case": "soc_incident_triage",
    "owner": "SOC-L2",
    "data_owner": "Security Operations"
  },
  "classification": {
    "level": "restricted",
    "categories": [
      "incident",
      "infrastructure",
      "personal_data"
    ],
    "findings_summary": {
      "hostname": 1,
      "user_identifier": 1,
      "external_endpoint": 1,
      "case_identifier": 1
    },
    "max_confidence": 0.97
  },
  "policy": {
    "policy_id": "AI-POL-RESTRICTED-SOC-007",
    "policy_bundle_hash": "sha256:8ae1...",
    "decision": "TOKENIZE",
    "routing": "cloud_model_after_tokenization",
    "approval_required": false
  },
  "transformation": {
    "transformation_manifest_hash": "sha256:2fd9...",
    "actions": [
      {
        "action": "TOKENIZE",
        "entity_type": "hostname",
        "span_hmac": "hmac256:3d1f...",
        "token_ref": "ASSET_TOKEN_41",
        "reversible": true
      },
      {
        "action": "TOKENIZE",
        "entity_type": "user_identifier",
        "span_hmac": "hmac256:89aa...",
        "token_ref": "USER_TOKEN_18",
        "reversible": true
      }
    ]
  },
  "model": {
    "target": "cloud",
    "provider_alias": "approved-llm-01",
    "model_alias": "general-reasoning-approved",
    "region_policy": "EU_OR_APPROVED_SCC",
    "tool_access": "disabled"
  },
  "hashes": {
    "canonical_request_hash": "sha256:44b8...",
    "safe_prompt_hash": "sha256:99ce...",
    "response_hash": "sha256:aa91..."
  },
  "component_versions": {
    "agent_version": "agent-1.4.2",
    "classifier_version": "clf-0.14.2",
    "gateway_version": "gw-0.9.1",
    "policy_engine_version": "poleng-2.1.0"
  },
  "attestation": {
    "decision_proof_id": "proof-2026-06-16-000918",
    "canonical_policy_input_hash": "sha256:0e71...",
    "deterministic_policy_result_hash": "sha256:19ab...",
    "attestor": "ai-governance-gateway-prod",
    "signature": "jws:eyJhbGciOiJFUzI1NiIs..."
  },
  "outcome": {
    "response_filter": "pass",
    "recontextualization": "local",
    "siem_severity": "informational",
    "soar_action": "none"
  },
  "timestamp": "2026-06-16T12:00:00Z"
}
```

Ten log pozwala odpowiedzieć na pytanie, co zrobił system, bez odtwarzania danych. Można wykazać, że wykryto dane `restricted`, zastosowano `TOKENIZE`, użyto polityki `AI-POL-RESTRICTED-SOC-007`, routing był do zatwierdzonego modelu chmurowego po transformacji, odpowiedź przeszła filtr i lokalna rekontekstualizacja była wymagana. Nie ma tam nazwiska, hosta, adresu IP ani treści promptu.

### 6.3. Deterministic Policy Proof

Deterministic Policy Proof to kryptograficznie odtwarzalny dowód, że dla danego kanonicznego wejścia polityki system podjął określoną decyzję. Nie dowodzi, że klasyfikator był doskonały. Dowodzi, że przy zadanych wynikach klasyfikacji, kontekście, wersji polityki i wersji silnika decyzja została wykonana zgodnie z regułami.

Minimalny model:

```text
canonical_policy_input =
  canon({
    user_role,
    business_context,
    data_classification,
    findings_summary,
    model_target_candidates,
    policy_bundle_hash,
    classifier_version,
    gateway_version
  })

decision =
  policy_engine.evaluate(canonical_policy_input)

decision_proof =
  Sign_gateway_key(
    H(canonical_policy_input)
    || H(decision)
    || policy_bundle_hash
    || timestamp
    || request_id
  )
```

Wersja dojrzała powinna dodatkowo obsługiwać HMAC dla spanów, podpis polityki, wersjonowanie klasyfikatora, listę transformacji i dowód, że raw payload nie został przekazany do SIEM. Ważne jest rozróżnienie: hash zapewnia integralność odniesienia, ale nie autentyczność. Do autentyczności zdarzeń wewnętrznych potrzebny jest HMAC albo podpis cyfrowy. To jest ta sama zasada, która obowiązuje przy artefaktach łańcucha dostaw: samo wyliczenie skrótu nie wystarczy, jeżeli napastnik może podmienić zarówno dane, jak i skrót.

### 6.4. Kanonikalizacja jako warunek dowodu

Bez kanonikalizacji nie ma stabilnego dowodu decyzji. Ten sam obiekt JSON może mieć inną kolejność pól, inne spacje, inne kodowanie znaków i inne reprezentacje wartości, mimo że semantycznie oznacza to samo. Jeżeli policy proof ma być odtwarzalny, wejście do silnika polityk musi zostać sprowadzone do deterministycznej reprezentacji.

Dlatego przed hashowaniem i podpisem należy wykonać:

```text
normalize encodings
sort object keys
normalize timestamps
normalize whitespace where applicable
separate instruction from data
normalize classification labels
canonicalize policy input
hash canonical form
sign / HMAC canonical hash
```

W praktyce oznacza to, że dowód decyzji nie powinien być liczony z dowolnego payloadu HTTP, ale z kanonicznego obiektu decyzyjnego. Raw prompt może nigdy nie zostać zapisany, ale jego bezpieczna reprezentacja decyzyjna musi zostać zhaszowana i powiązana z polityką.

## 7. Matryca decyzji: pełna semantyka ośmiu akcji

Matryca decyzji nie jest listą etykiet. To język wykonawczy systemu governance. Każda akcja określa, co stanie się z danymi, czy dane trafią do modelu, czy transformacja jest odwracalna, czy wymagana jest zgoda człowieka i co trafi do audytu.

| Akcja     | Warunek techniczny                                                 | Transformacja                                  | Routing                              | Przykład                                                     | Audyt                                                             |
| --------- | ------------------------------------------------------------------ | ---------------------------------------------- | ------------------------------------ | ------------------------------------------------------------ | ----------------------------------------------------------------- |
| ALLOW     | Dane publiczne, niska wrażliwość, zgodne z polityką                | Brak albo lekka normalizacja                   | Cloud/local                          | Użytkownik pyta o publiczne CVE albo dokumentację frameworka | Log: `decision=ALLOW`, `safe_prompt_hash`, brak spanów wrażliwych |
| REDACT    | Występuje fragment zbędny i niedopuszczalny, np. sekret            | Usunięcie wartości i zastąpienie placeholderem | Cloud/local po redakcji              | `api_key=sk-live-...` → `[REDACTED_SECRET]`                  | Log: typ sekretu, span_hmac, bez wartości                         |
| MASK      | Potrzebny jest format danych, ale nie pełna wartość                | Częściowe ukrycie                              | Cloud zwykle dopuszczalny            | `jan.kowalski@firma.pl` → `j***@firma.pl`                    | Log: `MASK`, typ encji, confidence                                |
| TOKENIZE  | Potrzebna korelacja i odwracalność                                 | Token referencyjny w Token Vault               | Cloud/local zależnie od klasy danych | `SRV-FIN-02` → `ASSET_TOKEN_41`                              | Log: token_ref, span_hmac, reversible=true                        |
| SUMMARIZE | Model potrzebuje sensu, nie pełnego tekstu                         | Streszczenie po lokalnej redukcji              | Cloud po redukcji albo local         | 50 stron dokumentu finansowego → streszczenie ryzyk i sekcji | Log: `source_hash`, `summary_hash`, klasy danych                  |
| ABSTRACT  | Wystarczy model logiczny lub metadane                              | Zamiana szczegółów na typy, grafy, AST, klasy  | Cloud zwykle dopuszczalny            | Kod → AST + SAST findings + call graph                       | Log: typ abstraktu, hash artefaktu logicznego                     |
| BLOCK     | Dane nie mogą opuścić środowiska lub intencja jest niedopuszczalna | Brak wysyłki                                   | Brak                                 | Private key, pełna baza klientów, żądanie eksfiltracji       | Log: `BLOCK`, policy_id, kategoria, brak payloadu                 |
| ESCALATE  | Niska pewność, wysoka krytyczność, konflikt polityki               | Wstrzymanie i workflow approval                | SOAR / human approval / local model  | Incydent M&A, sporna umowa, prompt graniczny AppSec          | Log: `ESCALATE`, approver role, reason_code                       |

### 7.1. ALLOW

ALLOW jest dopuszczalne, gdy dane są publiczne, nie zawierają identyfikatorów organizacyjnych, nie odnoszą się do infrastruktury wewnętrznej i nie powodują ryzyka prawnego. Nie oznacza to braku logu. Oznacza brak transformacji treści. System nadal powinien zapisać, że żądanie zostało sklasyfikowane jako publiczne i przeszło politykę.

Przykład:

```text
Prompt:
„Podsumuj publiczne informacje o CVE-2026-XXXX.”

Decyzja:
ALLOW

Do modelu:
prompt bez zmian

Do SIEM:
classification=public
decision=ALLOW
safe_prompt_hash=...
```

### 7.2. REDACT

REDACT usuwa wartość, która nie jest potrzebna do wykonania zadania. Jest właściwy dla sekretów, tokenów dostępowych, haseł, kluczy prywatnych, refresh tokenów i innych danych, których model nie powinien widzieć nawet w postaci częściowej.

Przykład:

```text
Raw:
„W kodzie znalazłem api_key=sk-live-9123... Czy to problem?”

Safe:
„W kodzie znaleziono [REDACTED_SECRET]. Czy to problem bezpieczeństwa?”

Decyzja:
REDACT

Uzasadnienie:
Model potrzebuje wiedzieć, że istnieje sekret, ale nie potrzebuje wartości sekretu.
```

### 7.3. MASK

MASK zachowuje kształt danych, ale usuwa identyfikowalność. Jest przydatny, gdy format ma znaczenie: e-mail, numer konta, numer dokumentu, zakres IP, ścieżka pliku, ale pełna wartość nie jest potrzebna.

Przykład:

```text
Raw:
jan.kowalski@firma.pl

Safe:
j***@firma.pl

Decyzja:
MASK

Uzasadnienie:
Model ma zrozumieć, że chodzi o adres e-mail w domenie organizacji,
ale nie powinien widzieć pełnego identyfikatora.
```

MASK jest mniej bezpieczny niż TOKENIZE, bo może ujawniać część struktury. Powinien być stosowany tam, gdzie częściowa struktura jest potrzebna i dopuszczona polityką.

### 7.4. TOKENIZE

TOKENIZE jest podstawową akcją dla danych strukturalnych, które muszą zachować korelację. Dotyczy hostów, użytkowników, numerów spraw, nazw repozytoriów, nazw klientów, identyfikatorów systemów i endpointów.

Przykład:

```text
Raw:
„SRV-FIN-02 komunikował się z 185.203.x.x po logowaniu jan.kowalski.”

Safe:
„[ASSET_TOKEN_41] komunikował się z [ENDPOINT_TOKEN_04]
po logowaniu [USER_TOKEN_18].”

Decyzja:
TOKENIZE

Vault:
ASSET_TOKEN_41 → SRV-FIN-02
ENDPOINT_TOKEN_04 → 185.203.x.x
USER_TOKEN_18 → jan.kowalski
```

TOKENIZE jest właściwe, gdy odpowiedź modelu ma później wrócić do kontekstu operacyjnego. Model nie zna wartości, ale zachowuje graf relacji.

### 7.5. SUMMARIZE

SUMMARIZE stosuje się, gdy źródło jest zbyt długie lub zbyt wrażliwe, a model zewnętrzny potrzebuje tylko sensu biznesowego. To typowe dla kontraktów, raportów finansowych, dokumentów audytowych i korespondencji.

Przykład:

```text
Raw:
50 stron dokumentu finansowego z nazwami klientów, kwotami, marżami i terminami.

Etap lokalny:
- ekstrakcja sekcji
- usunięcie nazw klientów
- agregacja kwot do przedziałów
- streszczenie ryzyk
- zachowanie odniesień do sekcji

Safe:
„Dokument finansowy zawiera trzy kategorie ryzyk:
1. koncentracja przychodu w jednym segmencie,
2. zależność od kontraktu klasy enterprise,
3. ekspozycja kosztowa na usługi cloud.
Oceń wpływ tych ryzyk na plan budżetowy.”

Decyzja:
SUMMARIZE
```

SUMMARIZE zmniejsza powierzchnię ujawnienia, ale może usuwać szczegóły istotne dla analizy. Dlatego powinno mieć `summary_hash`, źródłowy `source_hash` i możliwość powrotu do lokalnego dokumentu przez uprawnionego użytkownika.

### 7.6. ABSTRACT

ABSTRACT jest mocniejsze niż SUMMARIZE. Nie streszcza tekstu, lecz zamienia go na reprezentację wyższego rzędu: typy, role, relacje, grafy, AST, call graph, klasy podatności, kategorie prawne, kategorie danych.

Przykład osobowy:

```text
Raw:
„Jan Kowalski, PESEL 80010112345, mieszka w Warszawie i składa reklamację.”

Abstract:
„Obywatel kraju UE z krajowym identyfikatorem osoby fizycznej
składa reklamację konsumencką w jurysdykcji UE.”

Decyzja:
ABSTRACT
```

Przykład AppSec:

```text
Raw:
pełny fragment kodu z repozytorium payments-core

Abstract:
{
  "component_type": "financial_export_api",
  "language": "Java",
  "findings": ["hardcoded_secret", "dynamic_sql_concatenation"],
  "data_class": "financial",
  "call_graph": ["controller", "service", "repository"],
  "secret_value": "[REDACTED_SECRET]"
}
```

ABSTRACT jest najlepsze wtedy, gdy model ma rozwiązać problem logiczny, a nie pracować na oryginalnym materiale.

### 7.7. BLOCK

BLOCK zatrzymuje żądanie. Powinien być używany dla danych, których nie wolno przetwarzać w danym trybie, albo dla intencji naruszającej politykę.

Przykłady:

```text
private key w promptcie
pełna baza klientów
plik z hasłami
surowy eksport HR
żądanie obejścia DLP
próba wysyłki tajemnicy przedsiębiorstwa do modelu prywatnego
prompt nakłaniający agenta do wysłania danych na zewnętrzny endpoint
```

BLOCK nie powinien zwracać użytkownikowi wyłącznie komunikatu „zablokowano”. Powinien wskazać bezpieczną alternatywę:

```text
„Nie mogę wysłać prywatnego klucza do modelu.
Mogę natomiast pomóc sprawdzić procedurę rotacji klucza albo przeanalizować
komunikat błędu po usunięciu wartości sekretu.”
```

### 7.8. ESCALATE

ESCALATE uruchamia człowieka w pętli albo workflow w SOAR. To akcja dla sytuacji, w których automatyczna decyzja byłaby zbyt ryzykowna: niska pewność klasyfikacji, wysoka wrażliwość danych, konflikt polityk, niejasna intencja, materiał prawny, M&A, incydent krytyczny, dane regulowane.

Przykład:

```text
Prompt:
„Przeanalizuj plan przejęcia spółki X, oceń ryzyka prawne i przygotuj komunikację.”

Klasyfikacja:
confidential / legal / strategic / M&A

Decyzja:
ESCALATE

Workflow:
SOAR tworzy approval task dla Legal Owner + Data Owner.
Po zgodzie routing wyłącznie do modelu lokalnego albo zatwierdzonego modelu chmurowego
po SUMMARIZE/TOKENIZE.
```

ESCALATE jest niezbędne, ponieważ nie każdy przypadek powinien być rozwiązany automatycznie. W systemach wysokiego ryzyka brak ścieżki eskalacji prowadzi do dwóch patologii: blokowania wszystkiego albo przepuszczania wszystkiego.

## 8. Strategy Audit: SIEM/SOAR jako odbiorca dowodu, nie danych

Integracja z SIEM/SOAR powinna być projektowana jak warstwa dowodowa, nie jak warstwa archiwizacji treści. SIEM ma korelować zdarzenia, wykrywać anomalie, monitorować trendy i uruchamiać playbooki. Nie powinien być repozytorium promptów.

### 8.1. Kategorie zdarzeń

AI Governance Gateway powinien generować co najmniej następujące klasy zdarzeń:

```text
AI_REQUEST_CLASSIFIED
AI_POLICY_DECISION
AI_TRANSFORMATION_APPLIED
AI_TOKEN_CREATED
AI_MODEL_ROUTED
AI_RESPONSE_FILTERED
AI_RECONTEXTUALIZATION_PERFORMED
AI_POLICY_BLOCK
AI_HUMAN_ESCALATION
AI_DETOKENIZATION_REQUESTED
AI_DETOKENIZATION_DENIED
AI_EGRESS_ANOMALY
AI_POLICY_DRIFT_DETECTED
```

Każde zdarzenie powinno być skorelowane przez `request_id`, `session_ref`, `business_context`, `policy_id` i `decision_proof_id`. Nie przez raw prompt.

### 8.2. SOAR playbooki

SOAR powinien obsługiwać decyzje operacyjne:

```text
BLOCK private key
  → utwórz incydent sekretu
  → powiadom właściciela repo / systemu
  → uruchom rotację sekretu
  → oznacz użytkownikowi bezpieczną ścieżkę

ESCALATE legal / M&A
  → approval task dla data owner i legal owner
  → wymuś model lokalny lub zatwierdzony provider
  → zapisz decyzję zatwierdzającego bez payloadu

repeated restricted-data attempts
  → korelacja użytkownika / działu / aplikacji
  → analiza szkoleniowa albo incydent insider-risk
  → bez kopiowania treści promptów

unexpected cloud routing for restricted data
  → alert platform security
  → sprawdzenie policy bundle
  → blokada routingu do czasu wyjaśnienia
```

### 8.3. Retencja

Retencja powinna być rozdzielona:

```text
SIEM events:
  dłuższa retencja, brak raw danych, dowody decyzji

Token Vault mappings:
  krótsza albo domenowo zależna retencja, szyfrowanie, ścisłe ACL

Approval records:
  retencja zgodna z procesem prawnym / audytowym

Raw source documents:
  pozostają w systemach źródłowych, nie w governance log
```

To rozdzielenie jest kluczowe. Jeżeli token map trafia do SIEM, separacja zaufania zostaje złamana. Jeżeli raw prompt trafia do SIEM, system audytu staje się systemem eksfiltracji.

## 9. Klasyfikacja i policy engine: od tekstu do decyzji

Klasyfikator nie może opierać się na jednym mechanizmie. Pojedynczy regex wykryje część PESEL-i, ale nie wykryje kontekstu prawnego, intencji M&A, zależności między hostem a kontem uprzywilejowanym albo sekretu zakodowanego w nietypowym formacie. Warstwa klasyfikacji powinna być wielosygnałowa:

```text
regex
NER
entropy detection
secret scanning
checksum validation
domain dictionaries
CMDB lookup
IAM context
DLP labels
document classification
AST parser
SAST findings
CVE/MITRE ontology
legal clause classifier
financial data classifier
user role and business context
```

Wyniki klasyfikacji muszą być przetwarzane jako sygnały o różnej pewności. Przykładowo:

```json
{
  "level": "restricted",
  "categories": ["incident", "infrastructure", "personal_data"],
  "findings": [
    {
      "category": "hostname",
      "confidence": 0.97,
      "span_hmac": "hmac256:3d1f...",
      "recommended_action": "TOKENIZE"
    },
    {
      "category": "secret_candidate",
      "confidence": 0.88,
      "span_hmac": "hmac256:a71c...",
      "recommended_action": "REDACT"
    }
  ]
}
```

Policy engine nie powinien otrzymywać wyłącznie tekstu. Powinien otrzymywać kanoniczny obiekt decyzyjny:

```json
{
  "user_role": "SOC-L2",
  "business_context": "incident_triage",
  "data_level": "restricted",
  "categories": ["incident", "infrastructure", "personal_data"],
  "recommended_actions": ["TOKENIZE", "REDACT"],
  "model_candidates": ["local", "approved_cloud"],
  "tool_access_requested": false,
  "region_constraint": "EU_OR_APPROVED",
  "approval_context": {
    "required": false
  }
}
```

Wtedy decyzja nie jest wynikiem „intuicji modelu”, lecz deterministycznej polityki.

## 10. Routing modeli: lokalny, chmurowy, specjalizowany, human approval

Routing jest miejscem, gdzie governance łączy się z infrastrukturą. Organizacja, która ma tylko model chmurowy, ma mniej opcji dla danych wysokiego ryzyka. Organizacja, która ma lokalny model lub sidecar dla określonych domen, może kierować dane wrażliwe do środowiska kontrolowanego.

Minimalny model routingu:

```text
public/internal + low risk
  → approved cloud model

confidential + transformed
  → approved cloud model with no tools

restricted + tokenized
  → cloud only if policy allows and provider/region approved

restricted + raw required
  → local model

secret / private key / full customer database
  → block

strategic/legal/M&A or low classifier confidence
  → escalate
```

Routing musi uwzględniać nie tylko klasyfikację danych, ale też rodzaj zadania. Analiza ogólnego dokumentu może przejść po streszczeniu. Analiza incydentu bezpieczeństwa może przejść po tokenizacji. Analiza pełnego kodu źródłowego może wymagać modelu lokalnego albo abstrakcji do AST i wyników SAST. Agentic workflow z narzędziami wymaga ostrzejszych reguł niż zwykłe Q&A, ponieważ model może wykonywać działania.

## 11. Response Filter i Local Recontextualization

Filtr odpowiedzi jest równie ważny jak filtr wejścia. Model może zwrócić dane wrażliwe, próbować odtworzyć tokeny, wygenerować instrukcje niezgodne z polityką albo zasugerować działanie wymagające zatwierdzenia człowieka. Response Filter powinien wykonywać:

```text
sensitive output detection
token leakage detection
unsafe instruction detection
tool-call validation
policy consistency check
hallucinated identifier detection
reconstruction boundary check
```

Po filtrze następuje Local Recontextualization. To proces, w którym odpowiedź na tokenach zostaje przekształcona w odpowiedź użyteczną dla uprawnionego użytkownika.

Przykład:

```text
Model output:
„[ASSET_TOKEN_41] powinien zostać odizolowany od sieci,
a aktywność [USER_TOKEN_18] wymaga weryfikacji logów VPN.”

Local Recontextualization dla SOC-L2:
„SRV-FIN-02 powinien zostać odizolowany od sieci,
a aktywność jan.kowalski wymaga weryfikacji logów VPN.”

Local Recontextualization dla użytkownika bez uprawnień:
„Zasób finansowy powinien zostać odizolowany od sieci,
a aktywność użytkownika uprzywilejowanego wymaga weryfikacji logów VPN.”
```

Rekontekstualizacja nie jest prostym find-and-replace. Musi respektować uprawnienia, kontekst sprawy, TTL tokenów, klasyfikację danych i zasadę minimalnego ujawnienia.

## 12. Minimalny blueprint wdrożeniowy

### Faza 1: kontrolowany kanał

```text
centralny gateway
SSO/IAM
zatwierdzone modele
podstawowe DLP
policy_id
request_hash
safe_prompt_hash
brak raw promptów w SIEM
```

Celem fazy 1 jest wyciągnięcie użytkowników z Shadow AI, nie pełna automatyzacja governance.

### Faza 2: klasyfikacja i matryca decyzji

```text
data classifier
ALLOW/REDACT/MASK/TOKENIZE/SUMMARIZE/ABSTRACT/BLOCK/ESCALATE
transformation manifest
response filter
SIEM event schema
```

Celem fazy 2 jest wprowadzenie powtarzalnej semantyki decyzji.

### Faza 3: Token Vault i rekontekstualizacja

```text
Content Tokens
Decision Tokens
envelope encryption
TTL
detokenization policy
local recontextualization
```

Celem fazy 3 jest zachowanie użyteczności bez ujawniania danych modelowi.

### Faza 4: endpoint agent

```text
clipboard/file/browser/editor capture
local context binding
pre-TLS managed interception
local shallow classifier
local token map hints
offline/local mode for restricted workflows
```

Celem fazy 4 jest widoczność tego, czego gateway nie może zobaczyć.

### Faza 5: SOAR i high-risk workflows

```text
human approval
playbooki dla BLOCK/ESCALATE
policy drift detection
egress anomaly detection
red-team tests
continuous policy validation
```

Celem fazy 5 jest zamiana AI Governance z filtra w operacyjny system bezpieczeństwa.

## 13. Gdzie architektura realnie się psuje

Pierwszy punkt awarii to under-classification. Jeżeli klasyfikator nie rozpozna danych wrażliwych, cały system podejmie poprawną decyzję na błędnym wejściu decyzyjnym. To nie jest błąd LLM. To błąd warstwy klasyfikacji.

Drugi punkt awarii to over-redaction. Jeżeli system zbyt agresywnie usuwa dane, odpowiedzi stają się bezużyteczne. Użytkownik wraca do Shadow AI. Dlatego potrzebne są TOKENIZE, SUMMARIZE i ABSTRACT, a nie tylko REDACT/BLOCK.

Trzeci punkt awarii to brak lokalnej rekontekstualizacji. Gateway może bezpiecznie wysłać tokeny do modelu, ale jeśli użytkownik nie otrzyma odpowiedzi osadzonej w lokalnym kontekście, workflow operacyjny się zatrzymuje.

Czwarty punkt awarii to logowanie payloadów. To najgroźniejszy błąd architektoniczny: system ochrony staje się repozytorium danych wrażliwych.

Piąty punkt awarii to brak kontroli agentic workflow. Prompt filtering nie wystarcza, jeśli model może wywoływać narzędzia, pobierać strony, wysyłać dane albo wykonywać akcje. Dla agentów potrzebna jest kontrola uprawnień narzędzi, egress, allowlisting i human approval.

Szósty punkt awarii to jeden dostawca i jeden model. Governance wymaga routingu. Jeżeli każda sprawa trafia do tego samego modelu, architektura nie jest hybrydowa, tylko tuneluje ryzyko do jednego punktu.

## 14. Metryki operacyjne

Metryki muszą mierzyć przepływ, a nie deklaracje. Minimalny zestaw:

| Metryka                       | Definicja                                                                            | Źródło                    | Cel                             |
| ----------------------------- | ------------------------------------------------------------------------------------ | ------------------------- | ------------------------------- |
| `raw_sensitive_transfer_rate` | odsetek żądań z raw restricted/confidential skierowanych do modelu                   | gateway + classifier      | spadek bez spadku użycia kanału |
| `tokenization_success_rate`   | odsetek żądań, w których tokenizacja zachowała użyteczność                           | gateway + feedback        | wzrost                          |
| `over_redaction_rate`         | odsetek przypadków, gdzie użytkownik nie mógł wykonać zadania przez nadmiar redakcji | feedback + retry patterns | spadek                          |
| `shadow_ai_reduction`         | spadek ruchu do nieautoryzowanych usług AI                                           | proxy/DNS/CASB/EDR        | spadek                          |
| `audit_completeness`          | odsetek decyzji z pełnym manifestem i proofem                                        | audit fabric              | blisko 100%                     |
| `policy_replayability`        | możliwość odtworzenia decyzji z logów bez payloadu                                   | audit tests               | wysoka                          |
| `escalation_precision`        | odsetek eskalacji faktycznie wymagających człowieka                                  | SOAR outcomes             | optymalizacja                   |
| `response_leakage_rate`       | odpowiedzi naruszające politykę po response filter                                   | response filter           | spadek                          |
| `detokenization_denied_rate`  | próby nieuprawnionej rekontekstualizacji                                             | Token Vault               | monitoring insider risk         |
| `latency_budget_violation`    | odsetek żądań przekraczających SLA governance                                        | gateway telemetry         | spadek                          |

Metryki powinny mieć baseline. Bez baseline’u „poprawa” jest narracją. Przykładowo `raw_sensitive_transfer_rate` trzeba mierzyć przed wdrożeniem, po wdrożeniu gatewaya, po wdrożeniu tokenizacji i po wdrożeniu agenta endpointowego.

## 15. Porównanie z prostszymi wariantami

Pełna hybryda nie zawsze jest pierwszym krokiem. Dla części organizacji zatwierdzony SaaS AI z SSO, DLP i enterprise logging może być właściwym MVP. Problem pojawia się, gdy organizacja ma dane `restricted`, SOC/AppSec/legal workflows, kod źródłowy, incydenty, sekrety, dane klientów albo potrzebę lokalnej rekontekstualizacji.

| Wariant                             | Zaleta                 | Ograniczenie                                     | Kiedy wystarcza                        |
| ----------------------------------- | ---------------------- | ------------------------------------------------ | -------------------------------------- |
| Approved SaaS AI + SSO              | szybkie wdrożenie      | słaba kontrola lokalnego kontekstu i token vault | dane publiczne/internal                |
| CASB/SASE + blokady                 | ogranicza Shadow AI    | może wypychać do obejść                          | organizacje o niskim użyciu AI         |
| Central API Gateway                 | dobry dla aplikacji    | nie widzi clipboardu, plików, prywatnych web UI  | aplikacje firmowe                      |
| Portal AI bez agenta                | dobry UX i szablony    | użytkownicy mogą omijać portal                   | powtarzalne use case’y                 |
| Gateway + Token Vault               | silna kontrola danych  | brak pełnej widoczności endpointu                | średnie/duże organizacje               |
| Agent + Gateway + Token Vault       | pełna kontrola procesu | koszt, utrzymanie endpointów, integracja         | SOC, AppSec, legal, finanse, regulated |
| Pełna hybryda + local models + SOAR | najwyższa kontrola     | największa złożoność                             | organizacje krytyczne                  |

To rozróżnienie jest ważne. Artykuł nie twierdzi, że każda organizacja musi natychmiast wdrożyć poziom maksymalny. Twierdzi, że dla przepływów wysokiego ryzyka prosty SaaS z DLP nie rozwiązuje problemu odwracalnej pseudonimizacji, lokalnej rekontekstualizacji i dowodu decyzji bez kopiowania danych.

## 16. Wniosek końcowy

AI Governance nie powinno być budowane jako lista zakazów ani jako pojedynczy filtr promptów. Dojrzała architektura musi działać jak system sterowania przepływem informacji: przechwycić kontekst lokalny, sklasyfikować dane, zastosować politykę, przekształcić payload, utworzyć tokeny, wybrać model, przefiltrować odpowiedź, odtworzyć znaczenie lokalnie i wygenerować dowód decyzji bez kopiowania danych.

Najważniejszym elementem tego wzorca jest rozdzielenie trzech rzeczy, które w prostych wdrożeniach są mylone:

```text
dane źródłowe
reprezentacja dla modelu
dowód audytowy
```

Dane źródłowe powinny pozostać w systemie źródłowym albo w Token Vault. Reprezentacja dla modelu powinna być minimalna: tokenizowana, maskowana, streszczona albo abstrahowana. Dowód audytowy powinien zawierać politykę, hashe, HMAC, wersje komponentów, decyzję i atestację, ale nie powinien zawierać surowych danych.

To jest właściwy sens hybrydowego AI Governance Proxy. Nie chodzi o dołożenie bramki do LLM. Chodzi o zbudowanie warstwy decyzyjnej, która pozwala organizacji używać AI bez utraty kontroli nad danymi, procesem i odpowiedzialnością.

Hybrydowy system AI Governance nie jest dodatkiem do modelu AI. Jest warstwą wykonawczą zaufania, która określa, kiedy model może widzieć dane, w jakiej reprezentacji może je przetwarzać, komu może zwrócić wynik i jak organizacja może później udowodnić, że cały proces był zgodny z polityką, minimalizacją danych i wymogami bezpieczeństwa.
