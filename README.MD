# Writeups — mapa całego repozytorium

> 🛡️ **AI Security · Agentic Systems · Cybersecurity · Human–AI · LOCI · probabilistyka · epistemika LLM · OSINT**

**Indeks zaktualizowany: 18 sierpnia 2026**

`writeups` jest living research repository: przechowuje publikacyjne write-upy, architektury bezpieczeństwa, eksperymenty, raporty PDF, kod, dane, wyniki i materiały wizualne. Ten README jest **korzeniem drzewa nawigacji**. Każdy większy katalog posiada własny README z krótkimi opisami poddrzewa.

## Drzewo wejściowe

```text
writeups/
├── README.MD                         ← jesteś tutaj
├── ai_security_model_boundary_strategy_writeup.md
├── AI_Driven_Security_Research_Package_2026-08-18.zip
├── OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md
├── LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md
├── artykuły/
│   └── README.md                     ← publikacje
├── badania/
│   ├── README.md                     ← katalog raportów i pakietów
│   ├── Strategia bezpieczeństwa wobec AI-Driven Attacks...pdf
│   ├── conditional_decision_theory/
│   │   └── README.md
│   ├── MQL5Market/
│   │   └── README.md
│   └── LOCI/
│       ├── README.MD                 ← pipeline kanoniczny
│       ├── parsers/README.md
│       ├── sample/README.md
│       ├── matlab/README.md
│       ├── spec/README.md
│       ├── tests/README.md
│       ├── results/README.md
│       └── raports/README.md
├── OSINT/
│   └── README.md
└── images/
    └── README.md
```

## Najkrótsze ścieżki wyszukiwania

| Szukasz | Zacznij tutaj |
|---|---|
| AI-Driven Attacks / Security Model Boundary | [`ai_security_model_boundary_strategy_writeup.md`](ai_security_model_boundary_strategy_writeup.md) |
| pełne badanie Monte Carlo AI-Driven Security | [`badania/Strategia bezpieczeństwa wobec AI-Driven Attacks pod presją wdrażania AI — badanie falsyfikacyjne Mo.pdf`](<badania/Strategia bezpieczeństwa wobec AI-Driven Attacks pod presją wdrażania AI — badanie falsyfikacyjne Mo.pdf>) |
| pakiet materiałów AI-Driven Security | [`AI_Driven_Security_Research_Package_2026-08-18.zip`](AI_Driven_Security_Research_Package_2026-08-18.zip) |
| runtime security / observability / Linux | [`OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md`](OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md) |
| multi-agent security / federated control / SOC | [`LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md`](LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md) |
| publikacje | [`artykuły/README.md`](artykuły/README.md) |
| pełny korpus badań | [`badania/README.md`](badania/README.md) |
| LOCI / 27D→9R / pipeline / testy | [`badania/LOCI/README.MD`](badania/LOCI/README.MD) |
| epistemika LLM / microcode / kontekst | [sekcja Epistemika](#epistemika-llm-kontekst-i-microcode) |
| malware / APT / incydenty | [sekcja Cyber](#cyber-malware-apt-i-incydenty) |
| Human–AI / organizacja / percepcja | [sekcja Human–AI](#humanai-organizacja-ekonomia-i-percepcja) |
| OSINT | [`OSINT/README.md`](OSINT/README.md) |
| grafiki / diagramy | [`images/README.md`](images/README.md) |

---

# 1. Aktualny rdzeń: bezpieczeństwo agentowego AI

Repozytorium rozwija obecnie linię, w której jednostką bezpieczeństwa nie jest wyłącznie komponent, lecz **trajektoria wykonania**. Lokalnie dozwolone prymitywy nie gwarantują bezpieczeństwa ich kompozycji:

```text
A = allowed
B = allowed
C = allowed

A → B → C ≠ automatically safe
```

### [`ai_security_model_boundary_strategy_writeup.md`](ai_security_model_boundary_strategy_writeup.md)

Nadrzędny write-up strategii **Security Model Boundary**. Obejmuje falsyfikację hipotezy, Probabilistic–Deterministic Boundary, 1 000 000 realizacji Monte Carlo, porównanie 36 strategii, tail risk, adversarial stress testing, Security Observability Kernel, Security Boundary Buffer oraz GREEN / AMBER / RED autonomy lanes.

Materiały źródłowe tej linii są spięte bezpośrednio:

- [`badania/Strategia bezpieczeństwa wobec AI-Driven Attacks pod presją wdrażania AI — badanie falsyfikacyjne Mo.pdf`](<badania/Strategia bezpieczeństwa wobec AI-Driven Attacks pod presją wdrażania AI — badanie falsyfikacyjne Mo.pdf>) — pełny raport badawczy;
- [`AI_Driven_Security_Research_Package_2026-08-18.zip`](AI_Driven_Security_Research_Package_2026-08-18.zip) — pakiet materiałów badawczych/reprodukcyjnych;
- [`badania/README.md`](badania/README.md) — indeks badania w całym korpusie.

### [`OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md`](OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md)

Referencyjna architektura Linux, w której zdolność agenta do powodowania skutków jest uzależniona od observability, provenance, platform integrity i complete mediation. Model oddziela **action proposal** od rzeczywistego authority.

### [`LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md`](LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md)

Rozszerzenie reference monitora na populację agentów i domen: control, execution, observability, trust i SOC planes, workload identity, federacja polityk, scoped capabilities, cross-domain communication oraz containment.

### [`deterministyczna_obserwowalnosc_warstwy_wykonawczej_ai.md`](deterministyczna_obserwowalnosc_warstwy_wykonawczej_ai.md)

Tekst o deterministycznej warstwie obserwowalności i wykonania jako szkielecie kontroli nad probabilistycznym AI.

### [`global_architecture_convergence_baseline_report.md`](global_architecture_convergence_baseline_report.md)

Porównanie rozwijanych w repo wzorców z publicznymi architekturami agentic runtime, tracingu, approvals, identity, policy gates i execution control; rozróżnia konwergencję od wpływu przyczynowego.

### [`sbom-as-sigillum-relationis_systemic-risk-control.md`](sbom-as-sigillum-relationis_systemic-risk-control.md)

SBOM jako element szerszej kontroli relacji, provenance i ryzyka systemowego.

### [`inwariant_llm_analiza_watkow_konwersacyjnych.md`](inwariant_llm_analiza_watkow_konwersacyjnych.md)

Analiza inwariantów, ciągłości i zmian w wątkach LLM.

---

# 2. Publikacje

Pełny indeks: [`artykuły/README.md`](artykuły/README.md).

- [`artykuły/RESEARCH_WRITEUP_OCZY_SZEROKO_ZAMKNIETE.md`](artykuły/RESEARCH_WRITEUP_OCZY_SZEROKO_ZAMKNIETE.md) — duży write-up teorii decyzji warunkowej i falsyfikacji.
- [`artykuły/enterprise-ai-governance-proxy.md`](artykuły/enterprise-ai-governance-proxy.md) — enterprise AI governance/proxy i kontrola wykonania.
- [`artykuły/llm-trust-boundary-collapse-publication.md`](artykuły/llm-trust-boundary-collapse-publication.md) — LLM Trust Boundary Collapse (LTBC).
- [`artykuły/loci-agent-llm-state-space-control.md`](artykuły/loci-agent-llm-state-space-control.md) — LOCI, agenci i kontrola state-space.

---

# 3. Badania i reprodukowalność

Pełny katalog raportów: [`badania/README.md`](badania/README.md).

Gałąź obejmuje raporty z obszarów: AI/SaaS/Cloud, Human–AI, ekonomika danych, perception/cognition, LOCI/9R–27D, OSINT/geopolityka, finanse, symulacje i pakiety reprodukcyjne.

### AI-Driven Security — badanie i pakiet

- [`badania/Strategia bezpieczeństwa wobec AI-Driven Attacks pod presją wdrażania AI — badanie falsyfikacyjne Mo.pdf`](<badania/Strategia bezpieczeństwa wobec AI-Driven Attacks pod presją wdrażania AI — badanie falsyfikacyjne Mo.pdf>) — pełne badanie Monte Carlo i falsyfikacji strategii.
- [`AI_Driven_Security_Research_Package_2026-08-18.zip`](AI_Driven_Security_Research_Package_2026-08-18.zip) — pakiet materiałów powiązanych z badaniem.
- [`ai_security_model_boundary_strategy_writeup.md`](ai_security_model_boundary_strategy_writeup.md) — wynik publikacyjny i architektoniczny badania.

### [`badania/conditional_decision_theory/README.md`](badania/conditional_decision_theory/README.md)

Raport i wynik JSON dla badania teorii decyzji warunkowej.

### [`badania/MQL5Market/README.md`](badania/MQL5Market/README.md)

Mała gałąź kodu eksperymentalnego dla researchu rynkowego.

### [`badania/LOCI/README.MD`](badania/LOCI/README.MD)

Kanoniczny system LOCI:

```text
input
→ parser
→ sample_norm
→ analytical series
→ 27D
→ 9R / metaspace
→ tests
→ results
→ static reports
```

LOCI ma lokalne indeksy dla `parsers`, `sample`, `matlab`, `spec`, `tests`, `results` i `raports`, dzięki czemu nie trzeba przeszukiwać ręcznie dużego poddrzewa wyników.

---

# 4. Epistemika LLM, kontekst i microcode

### [`prawda-vs-fikcja-w-llm.md`](prawda-vs-fikcja-w-llm.md)

Epistemiczny rdzeń: fakt, fikcja, kontekst i problem walidacji w systemach generatywnych.

### [`P0-P3_truth-vs-fiction_detector_v1d.prompt`](P0-P3_truth-vs-fiction_detector_v1d.prompt)

Instrument klasyfikacyjny P0–P3 do oddzielania faktów, interpretacji i fikcji.

### [`magia-embeddingu-llm-slowo-w-czyn.md`](magia-embeddingu-llm-slowo-w-czyn.md)

Od reprezentacji semantycznej i embeddingu do konsekwencji operacyjnej.

### [`przyciski-semantyczne-llm.md`](przyciski-semantyczne-llm.md)

Wzorce tekstowe jako semantyczne przełączniki prowadzące do klas działań.

### [`protokoly_kontekstu_chunk-chunk_facebook_case.md`](protokoly_kontekstu_chunk-chunk_facebook_case.md)

Case study protokołów kontekstu i mikrojęzyków.

### [`double_dagger_operator_kontekstu.md`](double_dagger_operator_kontekstu.md)

Operator `‡` jako przełącznik warstwy kontekstowej.

### [`AISec_ASCII_MC_9D_eksperyment_kontekstowy.md`](AISec_ASCII_MC_9D_eksperyment_kontekstowy.md)

Eksperyment kontekstowy AISEC / ASCII_MC_9D.

### Seria ASCII microcode

- [`ascii-ontologiczny-microcode-ai_czesc1-fundament-znak-semantyka.md`](ascii-ontologiczny-microcode-ai_czesc1-fundament-znak-semantyka.md) — fundament: znak i semantyka.
- [`ascii-microcode-ai_part2.md`](ascii-microcode-ai_part2.md) — druga część serii.
- [`ascii-microcode-ai_part3.md`](ascii-microcode-ai_part3.md) — trzecia część serii.
- [`ascii-microcode-llm_od-znaku-do-ontologicznego-mikrokodu.md`](ascii-microcode-llm_od-znaku-do-ontologicznego-mikrokodu.md) — synteza od znaku do microcode.
- [`2025-12-04_mikrokod-daty_ascii-specyfikacja-dowod-replikowalny-eksperyment.md`](2025-12-04_mikrokod-daty_ascii-specyfikacja-dowod-replikowalny-eksperyment.md) — format daty i eksperyment replikowalny.
- [`writeup_ascii_microcode_hmk9d_deterministic_metrology_repo.md`](writeup_ascii_microcode_hmk9d_deterministic_metrology_repo.md) — deterministyczna metrologia strukturalna.
- [`ASCII_MC_9D_MC.PROMPT`](ASCII_MC_9D_MC.PROMPT) — prompt/instrument eksperymentalny.
- [`ASCII_MC_9D_notatka_bezpieczenstwa.md`](ASCII_MC_9D_notatka_bezpieczenstwa.md) — notatka bezpieczeństwa.

### [`mental-matrix-mega-brain-coop-linux.MD`](mental-matrix-mega-brain-coop-linux.MD)

Linux jako środowisko współpracy i eksperymentów Human–AI.

### [`PROMPT_MOZOWANIE_V1.prompt`](PROMPT_MOZOWANIE_V1.prompt)

Instrument promptowy związany z metodami badawczymi repozytorium.

---

# 5. Cyber, malware, APT i incydenty

- [`fileless-malware.md`](fileless-malware.md) — fileless malware, Windows i living-off-the-land.
- [`APT-K-47-asyncshell.md`](APT-K-47-asyncshell.md) — asynchroniczne powłoki i długie operacje APT.
- [`campaign-yokai-backdoor.md`](campaign-yokai-backdoor.md) — studium kampanii backdoora.
- [`operacja-cobalt-kitty.md`](operacja-cobalt-kitty.md) — analiza kampanii APT.
- [`fire-sale.md`](fire-sale.md) — wielowarstwowy incydent infrastrukturalno-ekonomiczny.
- [`2025-04_zaklocanie_protokolow_czasu_asyncshel_fire-sale.md`](2025-04_zaklocanie_protokolow_czasu_asyncshel_fire-sale.md) — protokoły czasu, NTP/PTP i async shell.
- [`malware-evolution.md`](malware-evolution.md) — ewolucja malware.
- [`cybersecurity-evolusion.md`](cybersecurity-evolusion.md) — ewolucja cyberbezpieczeństwa.

OSINT i rekonstrukcje mają osobny indeks: [`OSINT/README.md`](OSINT/README.md).

---

# 6. Human–AI, organizacja, ekonomia i percepcja

- [`evolutionary-agent-systems-organization-framework.md`](evolutionary-agent-systems-organization-framework.md) — ewolucyjne wdrażanie agentów i współewolucja organizacji.
- [`relational-perceptual-protocol-bootstrap-model.md`](relational-perceptual-protocol-bootstrap-model.md) — relacyjne protokoły percepcyjne / bootstrap.
- [`06_kosmiczne_wioski_social_ai_premia_za_kreacje.md`](06_kosmiczne_wioski_social_ai_premia_za_kreacje.md) — Social-AI i premia za kreację.
- [`produktywnosc_wioski_kosmicznej_dla_rozwoju_ai.md`](produktywnosc_wioski_kosmicznej_dla_rozwoju_ai.md) — produktywność modelu Wioski Kosmicznej.
- [`granica_wykonalnosci_wioska_kosmiczna_writeup_v1.md`](granica_wykonalnosci_wioska_kosmiczna_writeup_v1.md) — operacyjna granica wykonalności.
- [`06_METAVERSE_BIOLOGIA_CZLOWIEKA_DLACZEGO_VR_FIRST_NIE_SKALUJE.md`](06_METAVERSE_BIOLOGIA_CZLOWIEKA_DLACZEGO_VR_FIRST_NIE_SKALUJE.md) — VR-first i biologiczne ograniczenia interfejsu.
- [`manipulacja_masami_probabilistyczna_propaganda_i_przedrozumowa_percepcja.md`](manipulacja_masami_probabilistyczna_propaganda_i_przedrozumowa_percepcja.md) — percepcja przedrozumowa i probabilistyczna propaganda.
- [`mokey-bissnes_k-wave-media_potencjal-naukowy.md`](mokey-bissnes_k-wave-media_potencjal-naukowy.md) — media, ekonomia i potencjał badawczy.
- [`kod-cywilizacji-human-ai-spoleczenstwo-kosmos.md`](kod-cywilizacji-human-ai-spoleczenstwo-kosmos.md) — synteza Human–AI–społeczeństwo–infrastruktura.
- [`epistemiczna_tasma_prototypowa_figury.md`](epistemiczna_tasma_prototypowa_figury.md) — prototypowanie jako pętla falsyfikacji.
- [`blackbox_w_kosmosie.md`](blackbox_w_kosmosie.md) — black-box w kontekście systemowym.
- [`teoria-pojemnosci-modeli-obliczalnosc.md`](teoria-pojemnosci-modeli-obliczalnosc.md) — pojemność modeli i obliczalność.

Pełny korpus badań tej linii: [`badania/README.md`](badania/README.md).

---

# 7. Dane pomocnicze

- [`dane_wykresu_globalnej_implementacji_2026-08-04.csv`](dane_wykresu_globalnej_implementacji_2026-08-04.csv) — dane do wykresu globalnej implementacji.
- [`macierz_luk_architektonicznych_2026-08-04.csv`](macierz_luk_architektonicznych_2026-08-04.csv) — macierz luk architektonicznych.
- [`.gitignore`](.gitignore) — wykluczenia repozytorium.

Materiały graficzne: [`images/README.md`](images/README.md).

---

# 8. Metodyka czytania

Repo przechowuje różne klasy artefaktów i **nie każdy dokument jest finalnym twierdzeniem**. W badaniach stosowane są m.in. statusy:

```text
FACT / OBSERVED
DERIVED
CALIBRATED
ASSUMED
HYPOTHESIS
SPECULATION
STRESS PARAMETER
```

Przy materiałach probabilistycznych obowiązuje zasada: duża liczba realizacji Monte Carlo redukuje **sampling noise danego modelu**, ale nie usuwa model risk, złej kalibracji ani brakujących danych empirycznych.

Przy analizach architektonicznych podobieństwo lub konwergencja nie są automatycznie dowodem wpływu przyczynowego.

## Kanoniczne drzewo wyszukiwania

```text
ROOT README
│
├─ ai_security_model_boundary_strategy_writeup.md
│  ├─ pełny raport PDF w badania/
│  └─ AI_Driven_Security_Research_Package_2026-08-18.zip
│
├─ konkretny write-up rootowy
│
├─ artykuły/README.md
│  └─ publikacja
│
├─ badania/README.md
│  ├─ raport PDF
│  ├─ conditional_decision_theory/README.md
│  ├─ MQL5Market/README.md
│  └─ LOCI/README.MD
│     ├─ parsers/README.md
│     ├─ sample/README.md
│     ├─ matlab/README.md
│     ├─ spec/README.md
│     ├─ tests/README.md
│     ├─ results/README.md
│     └─ raports/README.md
│
├─ OSINT/README.md
└─ images/README.md
```

---

# 9. Bezpieczeństwo i zakres użycia

Materiały ofensywne mają charakter edukacyjny, badawczy i defensywny. Scenariusze testowe należy stosować wyłącznie w środowiskach własnych, laboratoryjnych, autoryzowanych lub zgodnych z zasadami właściwego programu bug bounty. Repozytorium nie zachęca do nieautoryzowanego dostępu ani zakłócania cudzych systemów.

---

# 10. Kontakt

GitHub: [@DonkeyJJLove](https://github.com/DonkeyJJLove)

---

## CHUNKS FILTER — mosty semantyczne 9D

`Plan–Pauza · Rdzeń–Peryferia · Cisza–Wydech · Wioska–Miasto · Ostrze–Cierpliwość · Locus–Medium–Mandat · Human–AI · Próg–Przejście · Semantyka–Energia`
