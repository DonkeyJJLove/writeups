# Writeups — AI Security, Agentic Systems, Cyber, Human–AI, LOCI i epistemika

> 🛡️ **Living research repository** łączące bezpieczeństwo systemów agentowych, klasyczne cyberbezpieczeństwo, obserwowalność wykonania, Human–AI, probabilistyczne modelowanie ryzyka, LOCI, epistemikę LLM i badania nad systemami społeczno-technicznymi.

**Stan mapy repozytorium: 18 sierpnia 2026**

Repozytorium nie jest pojedynczym projektem ani katalogiem luźnych artykułów. To rozwijana warstwa badawcza, w której write-upy techniczne, specyfikacje architektoniczne, eksperymenty, modele probabilistyczne, pipeline’y analityczne i teksty syntetyczne dokumentują zarówno **wyniki**, jak i **proces dochodzenia do wyników**.

---

## Spis treści

- [O repozytorium](#o-repozytorium)
- [Aktualny rdzeń badawczy: bezpieczeństwo AI na granicy wykonania](#aktualny-rdzeń-badawczy-bezpieczeństwo-ai-na-granicy-wykonania)
- [Mapa repozytorium](#mapa-repozytorium)
- [Ścieżki czytania](#ścieżki-czytania)
- [AI Security i architektura wykonawcza](#ai-security-i-architektura-wykonawcza)
- [Systemy agentowe, organizacja i kontrola](#systemy-agentowe-organizacja-i-kontrola)
- [LOCI i badania reprodukowalne](#loci-i-badania-reprodukowalne)
- [Epistemika LLM, kontekst i microcode](#epistemika-llm-kontekst-i-microcode)
- [Cyber, malware, APT i incydenty](#cyber-malware-apt-i-incydenty)
- [Human–AI, społeczeństwo, ekonomia i percepcja](#humanai-społeczeństwo-ekonomia-i-percepcja)
- [Metodyka i status dowodowy](#metodyka-i-status-dowodowy)
- [Konwencje artefaktów](#konwencje-artefaktów)
- [Bezpieczeństwo i zakres użycia](#bezpieczeństwo-i-zakres-użycia)
- [Kontakt](#kontakt)

---

## O repozytorium

`writeups` gromadzi analizy na styku kilku domen, które w praktycznych systemach coraz częściej przestają być rozłączne:

- **AI Security / Agentic Security** — granice zaufania, capabilities, provenance, tool use, runtime enforcement, obserwowalność i autonomia;
- **Cybersecurity** — malware, fileless techniques, APT, incydenty infrastrukturalne, supply chain, odporność i detekcja;
- **Human–AI** — HITL, organizacja pracy, ekonomia błędu, poznawcze ograniczenia operatora i delegacja decyzji;
- **Epistemika LLM** — prawda vs fikcja, kontekst, semantyka, embedding, metakod i walidacja;
- **Probabilistic / systems research** — Monte Carlo, falsyfikacja, sensitivity analysis, trajektorie stanów, ryzyko ogonowe i systemy złożone;
- **LOCI** — kanoniczny pipeline normalizacji, ekstrakcji cech 27D, mapowania 27D→9R, testów i raportowania;
- **OSINT i analiza strategiczna** — przypadki geopolityczne, infrastrukturalne, ekonomiczne i systemowe.

Wspólna logika repozytorium prowadzi od **źródła i obserwacji**, przez **interpretację i decyzję**, do **wykonania, skutku, telemetrii i ponownej falsyfikacji modelu**.

---

## Aktualny rdzeń badawczy: bezpieczeństwo AI na granicy wykonania

Najświeższa oś repozytorium przesuwa bezpieczeństwo AI z oceny samego modelu na ocenę **całej trajektorii wykonania**. Punktem wyjścia jest przypadek, w którym poszczególne operacje są lokalnie dozwolone, lecz ich kompozycja może naruszyć globalny invariant:

```text
A = allowed
B = allowed
C = allowed

nie implikuje

A → B → C = safe
```

Kanonicznym wejściem do tej linii jest:

- [`ai_security_model_boundary_strategy_writeup.md`](ai_security_model_boundary_strategy_writeup.md) — strategia bezpieczeństwa na **Security Model Boundary**, wyprowadzona z falsyfikacji, 1 000 000 realizacji Monte Carlo, porównania 36 strategii i adversarial stress testingu.

Badanie nie prowadzi do zasady „blokować AI”, lecz do sterowania autonomią zgodnie z consequentiality, provenance, obserwowalnością i kontrolowalnością. Praktyczny wynik rozdziela workflowy na trzy pasy:

- **GREEN** — read-only, reversible, low-impact: wysoka autonomia, provenance i capability control;
- **AMBER** — write/action/trust-boundary crossing: federated enforcement i deterministic gates;
- **RED** — critical/irreversible/high-authority: path-aware enforcement, isolation, invariants, recovery i selektywny human gate.

Architektoniczny wzorzec tej linii można streścić jako:

```text
Probabilistic Intelligence
inside
Observable + Provenance-Aware + Capability-Bounded
+ Path-Aware + Deterministically Enforced Execution Envelope
```

Ten sam problem jest rozwijany od poziomu pojedynczego hosta do systemu wieloagentowego:

- [`OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md`](OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md) — **Observability-Conditioned Reference Monitor**: authority zależne od integralności platformy, kompletności provenance i ciągłości obserwacji;
- [`LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md`](LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md) — **Linux Multi-Agent Control Mesh**: control, data, execution, observability, trust i SOC planes dla populacji agentów;
- [`deterministyczna_obserwowalnosc_warstwy_wykonawczej_ai.md`](deterministyczna_obserwowalnosc_warstwy_wykonawczej_ai.md) — deterministyczna obserwowalność jako warstwa wykonawcza nad probabilistycznym AI;
- [`artykuły/llm-trust-boundary-collapse-publication.md`](artykuły/llm-trust-boundary-collapse-publication.md) — model **LLM Trust Boundary Collapse (LTBC)** i analiza załamania granic DATA / INSTRUCTION / CONTEXT / AUTHORITY / MEMORY / DECISION / ACTION;
- [`artykuły/enterprise-ai-governance-proxy.md`](artykuły/enterprise-ai-governance-proxy.md) — warstwa governance/proxy dla wdrożeń enterprise;
- [`global_architecture_convergence_baseline_report.md`](global_architecture_convergence_baseline_report.md) — badanie konwergencji architektur agentowych, runtime, tracingu, identity, gate’ów i execution control.

---

## Mapa repozytorium

| Lokalizacja | Rola |
|---|---|
| `/*.md`, `/*.MD` | główne write-upy, architektury i teksty syntetyczne |
| [`artykuły/`](artykuły) | teksty publikacyjne i rozbudowane opracowania tematyczne |
| [`badania/`](badania) | duży korpus badań, raportów, PDF, danych i pakietów reprodukcyjnych |
| [`badania/LOCI/`](badania/LOCI) | kanoniczny pipeline LOCI: parser → normalizacja → 27D → 9R → testy → raporty |
| [`badania/conditional_decision_theory/`](badania/conditional_decision_theory) | formalizacja i wyniki badań teorii decyzji warunkowej |
| [`OSINT/`](OSINT) | analizy OSINT i rekonstrukcje zdarzeń |
| [`images/`](images) | ilustracje, diagramy i materiały wizualne |
| `*.prompt` | instrumenty badawcze, epistemiczne i testowe |
| `*.csv`, `*.json` | dane, macierze, wyniki i rejestry pomocnicze |

`badania/` posiada własny [`README.md`](badania/README.md), który porządkuje część korpusu jako strumienie badawcze Human–AI / HITL. LOCI posiada osobny [`badania/LOCI/README.MD`](badania/LOCI/README.MD) opisujący aktywny pipeline i kontrakty danych.

---

## Ścieżki czytania

### 1. AI Security / Security Architecture

1. [`ai_security_model_boundary_strategy_writeup.md`](ai_security_model_boundary_strategy_writeup.md)
2. [`OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md`](OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md)
3. [`LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md`](LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md)
4. [`deterministyczna_obserwowalnosc_warstwy_wykonawczej_ai.md`](deterministyczna_obserwowalnosc_warstwy_wykonawczej_ai.md)
5. [`artykuły/llm-trust-boundary-collapse-publication.md`](artykuły/llm-trust-boundary-collapse-publication.md)
6. [`artykuły/enterprise-ai-governance-proxy.md`](artykuły/enterprise-ai-governance-proxy.md)

Ta ścieżka prowadzi od **modelu ryzyka**, przez **reference monitor**, do **wieloagentowego control mesh i governance**.

### 2. LOCI / falsyfikacja / analiza trajektorii

1. [`badania/LOCI/README.MD`](badania/LOCI/README.MD)
2. [`artykuły/loci-agent-llm-state-space-control.md`](artykuły/loci-agent-llm-state-space-control.md)
3. [`badania/conditional_decision_theory/raport_oczy_szeroko_zamkniete_badania.md`](badania/conditional_decision_theory/raport_oczy_szeroko_zamkniete_badania.md)
4. [`artykuły/RESEARCH_WRITEUP_OCZY_SZEROKO_ZAMKNIETE.md`](artykuły/RESEARCH_WRITEUP_OCZY_SZEROKO_ZAMKNIETE.md)

To najbardziej techniczna ścieżka dla osób zainteresowanych **stanem, trajektorią, normalizacją danych, Monte Carlo, sensitivity i reprodukowalnością**.

### 3. Epistemika i kontrola semantyczna

1. [`prawda-vs-fikcja-w-llm.md`](prawda-vs-fikcja-w-llm.md)
2. [`P0-P3_truth-vs-fiction_detector_v1d.prompt`](P0-P3_truth-vs-fiction_detector_v1d.prompt)
3. [`magia-embeddingu-llm-slowo-w-czyn.md`](magia-embeddingu-llm-slowo-w-czyn.md)
4. [`przyciski-semantyczne-llm.md`](przyciski-semantyczne-llm.md)
5. [`double_dagger_operator_kontekstu.md`](double_dagger_operator_kontekstu.md)
6. [`ascii-microcode-llm_od-znaku-do-ontologicznego-mikrokodu.md`](ascii-microcode-llm_od-znaku-do-ontologicznego-mikrokodu.md)
7. [`writeup_ascii_microcode_hmk9d_deterministic_metrology_repo.md`](writeup_ascii_microcode_hmk9d_deterministic_metrology_repo.md)

### 4. Klasyczny cyber / malware / incydenty

1. [`fileless-malware.md`](fileless-malware.md)
2. [`APT-K-47-asyncshell.md`](APT-K-47-asyncshell.md)
3. [`campaign-yokai-backdoor.md`](campaign-yokai-backdoor.md)
4. [`operacja-cobalt-kitty.md`](operacja-cobalt-kitty.md)
5. [`fire-sale.md`](fire-sale.md)
6. [`2025-04_zaklocanie_protokolow_czasu_asyncshel_fire-sale.md`](2025-04_zaklocanie_protokolow_czasu_asyncshel_fire-sale.md)
7. [`malware-evolution.md`](malware-evolution.md)
8. [`cybersecurity-evolusion.md`](cybersecurity-evolusion.md)

### 5. Human–AI / organizacja / systemy społeczne

1. [`badania/README.md`](badania/README.md)
2. [`evolutionary-agent-systems-organization-framework.md`](evolutionary-agent-systems-organization-framework.md)
3. [`relational-perceptual-protocol-bootstrap-model.md`](relational-perceptual-protocol-bootstrap-model.md)
4. [`06_kosmiczne_wioski_social_ai_premia_za_kreacje.md`](06_kosmiczne_wioski_social_ai_premia_za_kreacje.md)
5. [`produktywnosc_wioski_kosmicznej_dla_rozwoju_ai.md`](produktywnosc_wioski_kosmicznej_dla_rozwoju_ai.md)
6. [`kod-cywilizacji-human-ai-spoleczenstwo-kosmos.md`](kod-cywilizacji-human-ai-spoleczenstwo-kosmos.md)

---

## AI Security i architektura wykonawcza

### Security Model Boundary

[`ai_security_model_boundary_strategy_writeup.md`](ai_security_model_boundary_strategy_writeup.md) opisuje zmianę podstawowej jednostki bezpieczeństwa z komponentu na **execution path**. Materiał obejmuje model SMB / SMBE, Probabilistic–Deterministic Boundary, Security Observability Kernel, Combinatorial Execution Control, Security Boundary Buffer, trzy pasy autonomii oraz strategię RED / BLUE / PURPLE.

### Observability-Conditioned Reference Monitor

[`OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md`](OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md) formalizuje zasadę:

```text
OBSERVABILITY ↓
→ AUTHORIZED STATE SPACE ↓
```

Model językowy generuje **action proposal**; niezależny PDP/PEP i lokalna warstwa wykonawcza decydują, czy propozycja może zostać zamieniona w skutek.

### Linux Multi-Agent Control Mesh

[`LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md`](LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md) rozszerza kontrolę z pojedynczego agenta na populację agentów. Kluczowe rozróżnienie:

```text
network address
≠ identity
≠ authority
```

Mesh obejmuje płaszczyzny **CONTROL / DATA / EXECUTION / OBSERVABILITY / TRUST / SOC**, federację polityk, workload identity, provenance, effect gateways, containment i integrację SOC/SIEM/SOAR.

### LTBC i governance

- [`artykuły/llm-trust-boundary-collapse-publication.md`](artykuły/llm-trust-boundary-collapse-publication.md) — granice zaufania w LLM/agent workflows;
- [`artykuły/enterprise-ai-governance-proxy.md`](artykuły/enterprise-ai-governance-proxy.md) — governance i mediacja wykonania;
- [`sbom-as-sigillum-relationis_systemic-risk-control.md`](sbom-as-sigillum-relationis_systemic-risk-control.md) — SBOM / relacja / kontrola ryzyka systemowego;
- [`inwariant_llm_analiza_watkow_konwersacyjnych.md`](inwariant_llm_analiza_watkow_konwersacyjnych.md) — analiza inwariantów i ciągłości wątków LLM.

---

## Systemy agentowe, organizacja i kontrola

[`evolutionary-agent-systems-organization-framework.md`](evolutionary-agent-systems-organization-framework.md) traktuje wdrożenie agentów jako **kontrolowaną współewolucję organizacji i systemu**, a nie jednorazowy rollout technologii. Badanie łączy obserwowalność, odwracalność, ownership, governance, system safety, resilience oraz ograniczenia infrastrukturalne.

[`relational-perceptual-protocol-bootstrap-model.md`](relational-perceptual-protocol-bootstrap-model.md) rozwija relacyjny model protokołów percepcyjnych i bootstrapowania zachowania agentów.

[`global_architecture_convergence_baseline_report.md`](global_architecture_convergence_baseline_report.md) porównuje wzorce rozwijane w repozytoriach z publicznie dokumentowanymi architekturami agentic runtime, tracingu, approvals, identity i execution control. Raport jawnie rozróżnia **konwergencję funkcjonalną / architektoniczną** od twierdzenia o wpływie przyczynowym.

Pozostałe teksty tej linii obejmują m.in.:

- [`granica_wykonalnosci_wioska_kosmiczna_writeup_v1.md`](granica_wykonalnosci_wioska_kosmiczna_writeup_v1.md) — granice wykonalności i infrastrukturalny rachunek AI;
- [`produktywnosc_wioski_kosmicznej_dla_rozwoju_ai.md`](produktywnosc_wioski_kosmicznej_dla_rozwoju_ai.md) — produktywność i rozwój AI;
- [`blackbox_w_kosmosie.md`](blackbox_w_kosmosie.md) — problem black-box w szerszym kontekście systemowym;
- [`teoria-pojemnosci-modeli-obliczalnosc.md`](teoria-pojemnosci-modeli-obliczalnosc.md) — pojemność modeli i obliczalność.

---

## LOCI i badania reprodukowalne

### Kanoniczny pipeline LOCI

[`badania/LOCI/README.MD`](badania/LOCI/README.MD) definiuje aktywny przepływ:

```text
sandbox.txt
→ parser Python
→ sample_norm.json
→ adapter MATLAB
→ seria analityczna
→ macierz cech 27D
→ wizualizacja 27D → 9R
→ results/
```

W `badania/LOCI/` znajdują się m.in.:

- `parsers/` — parsing, redakcja i normalizacja;
- `matlab/adapters/` — interoperacyjność i budowa macierzy cech;
- `matlab/features/` — warstwa cech;
- `matlab/visualizers/` — redukcja 27D→9R/3D i wizualizacja;
- `spec/` — kontrakty danych i kompatybilność;
- `tests/` — testy end-to-end i komponentowe;
- `results/` — artefakty generowane przez pipeline;
- `raports/` — generatory i raporty rekurencyjne.

Repo zawiera także działające artefakty testowe dla wielu sample oraz statyczny raport rekurencyjny.

### Conditional Decision Theory / „Oczy szeroko zamknięte”

Korpus obejmuje raporty, wyniki JSON i pakiety reprodukcyjne dotyczące teorii decyzji warunkowej, ekspozycji, adaptacji, coupling i closure. Punkty wejścia:

- [`badania/conditional_decision_theory/`](badania/conditional_decision_theory)
- [`artykuły/RESEARCH_WRITEUP_OCZY_SZEROKO_ZAMKNIETE.md`](artykuły/RESEARCH_WRITEUP_OCZY_SZEROKO_ZAMKNIETE.md)

### Human–AI / HITL research corpus

[`badania/README.md`](badania/README.md) syntetyzuje badania nad:

- ekonomią danych i kosztu błędu,
- Human-AI-In-The-Loop,
- kosztem poznawczym,
- dryfem semantycznym,
- stabilnością systemów społeczno-technicznych,
- relacją automatyzacji, walidacji i TCO.

Katalog `badania/` jest **archiwum i dziennikiem badań**; nie każdy PDF lub pakiet jest finalną publikacją.

---

## Epistemika LLM, kontekst i microcode

Repozytorium od początku rozwijało również problem **walidacji sensu**: LLM może tworzyć spójną narrację szybciej, niż użytkownik jest w stanie ją zweryfikować. Dlatego warstwa epistemiczna jest traktowana jako element bezpieczeństwa, a nie jako temat poboczny.

Najważniejsze materiały:

- [`prawda-vs-fikcja-w-llm.md`](prawda-vs-fikcja-w-llm.md) — fakt, fikcja, kontekst i status epistemiczny w LLM;
- [`P0-P3_truth-vs-fiction_detector_v1d.prompt`](P0-P3_truth-vs-fiction_detector_v1d.prompt) — praktyczny detektor P0–P3;
- [`magia-embeddingu-llm-slowo-w-czyn.md`](magia-embeddingu-llm-slowo-w-czyn.md) — przejście od reprezentacji semantycznej do działania;
- [`przyciski-semantyczne-llm.md`](przyciski-semantyczne-llm.md) — wzorzec tekstowy → region embeddingów → akcja;
- [`protokoly_kontekstu_chunk-chunk_facebook_case.md`](protokoly_kontekstu_chunk-chunk_facebook_case.md) — protokoły kontekstu;
- [`double_dagger_operator_kontekstu.md`](double_dagger_operator_kontekstu.md) — operator `‡` i zmiana klasy kontekstu;
- [`AISec_ASCII_MC_9D_eksperyment_kontekstowy.md`](AISec_ASCII_MC_9D_eksperyment_kontekstowy.md) — AISEC / ASCII_MC_9D;
- [`ascii-ontologiczny-microcode-ai_czesc1-fundament-znak-semantyka.md`](ascii-ontologiczny-microcode-ai_czesc1-fundament-znak-semantyka.md), [`ascii-microcode-ai_part2.md`](ascii-microcode-ai_part2.md), [`ascii-microcode-ai_part3.md`](ascii-microcode-ai_part3.md) — seria microcode;
- [`writeup_ascii_microcode_hmk9d_deterministic_metrology_repo.md`](writeup_ascii_microcode_hmk9d_deterministic_metrology_repo.md) — deterministyczna metrologia strukturalna;
- [`mental-matrix-mega-brain-coop-linux.MD`](mental-matrix-mega-brain-coop-linux.MD) — Linux jako środowisko współpracy Human–AI.

---

## Cyber, malware, APT i incydenty

Klasyczny cyber pozostaje osobną i ważną warstwą repozytorium:

- [`fileless-malware.md`](fileless-malware.md) — Windows, living-off-the-land, PowerShell, WMI, injection i detekcja;
- [`APT-K-47-asyncshell.md`](APT-K-47-asyncshell.md) — asynchroniczne powłoki i operacje rozciągnięte w czasie;
- [`campaign-yokai-backdoor.md`](campaign-yokai-backdoor.md) — analiza kampanii backdoora;
- [`operacja-cobalt-kitty.md`](operacja-cobalt-kitty.md) — case-study kampanii APT;
- [`fire-sale.md`](fire-sale.md) — incydent wielowarstwowy na styku infrastruktury, rynków i geopolityki;
- [`2025-04_zaklocanie_protokolow_czasu_asyncshel_fire-sale.md`](2025-04_zaklocanie_protokolow_czasu_asyncshel_fire-sale.md) — czas systemowy, NTP/PTP i asynchroniczność;
- [`malware-evolution.md`](malware-evolution.md) i [`cybersecurity-evolusion.md`](cybersecurity-evolusion.md) — ewolucja ataku i obrony;
- [`OSINT/`](OSINT) — materiały OSINT i rekonstrukcje zdarzeń.

Celem tych materiałów nie jest wyłącznie opis technik. Są one często używane jako dane do pytań o **długie łańcuchy przyczynowe, propagację, obserwowalność, odporność i zmianę modelu bezpieczeństwa**.

---

## Human–AI, społeczeństwo, ekonomia i percepcja

Druga duża oś repozytorium dotyczy systemów, w których człowiek jest częścią pętli decyzyjnej, a nie zewnętrznym „użytkownikiem”.

Najważniejsze punkty wejścia:

- [`badania/README.md`](badania/README.md) — synteza badań HITL;
- [`evolutionary-agent-systems-organization-framework.md`](evolutionary-agent-systems-organization-framework.md) — ewolucyjne wdrażanie systemów agentowych;
- [`manipulacja_masami_probabilistyczna_propaganda_i_przedrozumowa_percepcja.md`](manipulacja_masami_probabilistyczna_propaganda_i_przedrozumowa_percepcja.md) — probabilistyczna propaganda i percepcja przedrozumowa;
- [`06_METAVERSE_BIOLOGIA_CZLOWIEKA_DLACZEGO_VR_FIRST_NIE_SKALUJE.md`](06_METAVERSE_BIOLOGIA_CZLOWIEKA_DLACZEGO_VR_FIRST_NIE_SKALUJE.md) — biologiczne granice interfejsów VR-first;
- [`06_kosmiczne_wioski_social_ai_premia_za_kreacje.md`](06_kosmiczne_wioski_social_ai_premia_za_kreacje.md) — Social-AI i ekonomia kreacji;
- [`mokey-bissnes_k-wave-media_potencjal-naukowy.md`](mokey-bissnes_k-wave-media_potencjal-naukowy.md) — media, memy, ekonomia i środowiska informacyjne;
- [`kod-cywilizacji-human-ai-spoleczenstwo-kosmos.md`](kod-cywilizacji-human-ai-spoleczenstwo-kosmos.md) — nadrzędna warstwa Human–AI–społeczeństwo–infrastruktura;
- [`epistemiczna_tasma_prototypowa_figury.md`](epistemiczna_tasma_prototypowa_figury.md) — falsyfikacja i prototypowanie jako proces epistemiczny.

---

## Metodyka i status dowodowy

Repozytorium celowo miesza **write-upy końcowe, modele formalne, badania eksploracyjne, symulacje i hipotezy**, dlatego status epistemiczny materiału jest ważniejszy niż jego stylistyczna pewność.

W dojrzałych badaniach stosowane są m.in. rozróżnienia:

```text
FACT / OBSERVED
DERIVED
CALIBRATED
ASSUMED
HYPOTHESIS
SPECULATION
STRESS PARAMETER
```

oraz praktyki:

- jawne oddzielanie danych empirycznych od kalibracji modelu;
- falsyfikacja hipotezy przed jej przyjęciem;
- Monte Carlo jako badanie konsekwencji modelu niepewności, **nie substytut danych empirycznych**;
- analiza wrażliwości, tail risk i scenariuszy kontrfaktycznych;
- rozdzielanie podobieństwa od dowodu wpływu przyczynowego;
- przechowywanie danych, skryptów, wyników i kontraktów umożliwiających replikację tam, gdzie jest to wykonalne;
- oznaczanie materiałów `NIEZWERYFIKOWANE`, roboczych albo eksploracyjnych, kiedy dowody nie wystarczają do mocniejszego wniosku.

Przykładem tej dyscypliny jest `ai_security_model_boundary_strategy_writeup.md`: 1 000 000 realizacji redukuje sampling noise **wewnątrz przyjętego modelu**, ale nie zamienia kalibrowanego prawdopodobieństwa kompromitacji w empiryczną częstość realnego świata.

---

## Konwencje artefaktów

W repozytorium występują przede wszystkim:

- `*.md`, `*.MD` — write-upy, specyfikacje, raporty i artykuły;
- `*.prompt` — instrumenty badawcze i epistemiczne;
- `*.pdf` — raporty źródłowe i pełne wyniki badań;
- `*.csv`, `*.json`, `*.mat` — dane, wyniki i formaty pośrednie;
- `*.py`, `*.m` — kod analityczny i pipeline’y reprodukcyjne;
- `*.zip` — pakiety badań / wyników / reprodukcji;
- [`images/`](images) — ilustracje i wizualizacje.

Nazwy plików zachowują zarówno styl publikacyjny, jak i historyczne nazwy eksperymentów. Starsze nazewnictwo jest utrzymywane tam, gdzie pełni funkcję provenance.

---

## Status repozytorium

Repozytorium ma charakter **living repository**:

- część dokumentów jest domknięta i referencyjna;
- część jest publikacyjnym write-upem wyników;
- część jest instrumentem badawczym albo specyfikacją;
- część dokumentuje hipotezę, proces lub etap falsyfikacji;
- katalogi `badania/` i `badania/LOCI/` zawierają również surowe i pośrednie artefakty niezbędne do replikacji.

Nie należy więc interpretować każdego pliku jako obowiązującego „stanowiska repozytorium”. W wielu przypadkach wartością jest właśnie zapis tego, **co zostało odrzucone, skorygowane albo zawężone**.

---

## Bezpieczeństwo i zakres użycia

> Wszystkie materiały dotyczące cyberbezpieczeństwa, ofensywnych technik i systemów agentowych mają charakter **edukacyjny, badawczy, defensywny i analityczny**.
>
> Scenariusze ofensywne należy odnosić wyłącznie do własnych środowisk, laboratoriów, sandboxów, autoryzowanych testów oraz działań zgodnych z zasadami właściwego programu bug bounty.
>
> Repozytorium nie zachęca do nieautoryzowanego dostępu, zakłócania cudzych systemów ani obchodzenia prawa.
>
> W materiałach AI/LLM należy odróżniać warstwę empiryczną, formalną, modelową i interpretacyjną. Symulacja, zgodność architektoniczna lub spójna narracja nie są automatycznie dowodem empirycznym.

---

## Kontakt

Uwagi, dane do replikacji, korekty metodologiczne i propozycje współpracy:

- GitHub: [@DonkeyJJLove](https://github.com/DonkeyJJLove)

---

## CHUNKS FILTER — mosty semantyczne 9D

`Plan–Pauza · Rdzeń–Peryferia · Cisza–Wydech · Wioska–Miasto · Ostrze–Cierpliwość · Locus–Medium–Mandat · Human–AI · Próg–Przejście · Semantyka–Energia`
