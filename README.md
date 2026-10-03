# Writeups — badania, semantyka i bezpieczeństwo systemów agentowych

**Mapa repozytorium · aktualizacja: 3 października 2026**

`writeups` jest korpusem badawczym i publikacyjnym łączącym cyberbezpieczeństwo, sterowanie agentami AI, semantykę kontekstu, obserwowalność, probabilistyczne modele ryzyka oraz organizację systemów Human–AI. Przechowuje nie tylko artykuły, lecz także protokoły, kod instrumentów, konfiguracje, raporty PDF, dane, surowe przebiegi, wyniki negatywne i materiały wizualne. Wspólnym pytaniem jest to, jak przejść od informacji i interpretacji do działania, którego podstawę, uprawnienia oraz skutki można odtworzyć i sprawdzić.

Repozytorium nie jest jednym produktem ani jednorodnym benchmarkiem. Są tu pomiary zachowania rzeczywistego modelu w syntetycznym środowisku, symulacje, analizy incydentów, projekty architektur i teksty koncepcyjne. Ten README porządkuje ich relacje i kieruje do właściwych źródeł. Opis działu nie podnosi statusu dowodowego wszystkich znajdujących się w nim materiałów.

W federacji **LION** `writeups` pełni role `ResearchCorpus`, `EvidenceSource` i `PublicationProvider`, określone w [cyber-lion.repository.json](./cyber-lion.repository.json). Jest źródłem badań, nie wykonawcą uprawnień ani bieżącym rejestrem całej platformy. Trasę do właściciela architektury opisuje [AGENTS.md](./AGENTS.md); prowadzi ona do [LION w repozytorium ai_platform](https://github.com/DonkeyJJLove/ai_platform/blob/master/LION/architecture/v1_5/README.md). Lokalne wyniki HCL, LOCI czy symulacji nie stanowią automatycznie walidacji całego LION.

## Wybierz ścieżkę czytania

| Cel | Punkt wejścia | Co znajduje się dalej |
|---|---|---|
| Zrozumieć zmierzony wpływ scaffolding semantycznego | [Nowy writeup HCL 4.3.3](./badania/heuristic-causal-lab-final-4.3/SEMANTIC_SCAFFOLDING_WRITEUP.md) | Wyniki, działanie warstwy kontekstu, granice sterowania i dowody |
| Sprawdzić protokół, kod i przebieg eksperymentu | [Heuristic Causal Lab](./badania/heuristic-causal-lab-final-4.3/README.md) | Konfiguracja finalnego runu, 10 240 epizodów, grader i surowy transport |
| Projektować granicę między modelem a skutkiem | [Security Model Boundary](./ai_security_model_boundary_strategy_writeup.md) | Strategia bezpieczeństwa, reference monitor, control mesh, autoryzacja |
| Analizować reprezentacje i trajektorie Human–AI | [LOCI](./badania/LOCI/README.md) | Ingest, normalizacja, cechy 27D, projekcja 3D, testy i raporty |
| Badać kaskady, retry i przeciążenia | [Symulacja_GITHUB](./badania/Symulacja_GITHUB/README.md) | Sandbox Monte Carlo, raport, kod i interpretacja zakresu modelu |
| Przejść od semantyki do teorii kontekstu | [Epistemika i microcode](#epistemika-llm-kontekst-i-microcode) | Znaki, operatory kontekstu, metrologia, instrumenty promptowe |
| Czytać o organizacji, ekonomice i Human–AI | [Organizacja i ekonomika](#humanai-społeczeństwo-ekonomia-i-percepcja) | AI-Native Enterprise, protokoły relacyjne, granica wykonalności |
| Znaleźć analizy malware, APT i rekonstrukcje | [Cyberbezpieczeństwo i OSINT](#cyber-i-osint) | Kampanie, techniki, scenariusze i źródła rekonstrukcyjne |
| Przeglądać pełny katalog publikacji i raportów | [Artykuły](./artykuły/README.md) · [Badania](./badania/README.md) | Lokalne indeksy, raporty PDF i pakiety reprodukcyjne |

## Jak zorganizowany jest korpus

```text
writeups/
├── README.md                         mapa tematów i ścieżek czytania
├── AGENTS.md                         reguły kierowania w federacji LION
├── cyber-lion.repository.json        maszynowy opis roli i granic repo
├── *.md / *.MD                       samodzielne writeupy i architektury
├── *.prompt / *.PROMPT               instrumenty kontekstowe
├── badania/
│   ├── README.md                     tematyczny katalog raportów
│   ├── heuristic-causal-lab-final-4.3/
│   │   ├── SEMANTIC_SCAFFOLDING_WRITEUP.md
│   │   ├── README.md                 pełny opis badania HCL 4.3.3
│   │   ├── artifacts/                eksporty publikacyjne
│   │   └── hcl_final_4_3/             instrument, kod i dane wykonania
│   │       ├── runs/                 pełny run, epizody, transport HTTP
│   │       ├── results/              pomocnicze wyniki selftestu
│   │       └── STUDY_STATE*.json      zapis stanu i archiwum badania
│   ├── LOCI/                         reprezentacje i analiza trajektorii
│   ├── Symulacja_GITHUB/              amplifikacja obciążenia agentowego
│   ├── conditional_decision_theory/   decyzje warunkowe
│   ├── MQL5Market/                    eksperymentalna gałąź rynkowa
│   └── *.pdf / *.zip                  raporty i pakiety badawcze
├── artykuły/                         dłuższe publikacje i syntezy
├── OSINT/                            wydzielone analizy rekonstrukcyjne
├── images/                           diagramy i ilustracje
└── .github/workflows/                kontrola higieny repozytorium
```

Drzewo pokazuje funkcje katalogów, nie każdą pozycję. Istotne teksty są także w katalogu głównym — nie należy szukać całej problematyki wyłącznie w `artykuły/`. Z kolei `runs/` w HCL jest celowo wersjonowanym materiałem badawczym, nie katalogiem przeznaczonym do automatycznego usuwania jako cache.

## 1. Scaffolding semantyczny i empiryczne sterowanie zachowaniem

### Heuristic Causal Lab 4.3.3

[**Scaffolding semantyczny jako warstwa sterowania agentem**](./badania/heuristic-causal-lab-final-4.3/SEMANTIC_SCAFFOLDING_WRITEUP.md) jest wynikowym punktem wejścia do badania pobocznego wobec LION. Opisuje konkretny mechanizm instrumentu: zamrożony tekst w bloku `<policy>`, wspólny kontrakt wiadomości systemowej, wybory modelu, obserwacje narzędzi i ocenę końcową. Oddziela pomiar efektu całego pakietu od hipotez o jego mechanizmie semantycznym.

W finalnym runie wykonano 10 240 epizodów: 256 bloków seeda, dziesięć rodzin, dwa warianty kontrfaktyczne i dwa ramiona. `author_raw` osiągnął `safe_success` 21,52%, a `strong_control` 6,86%; sparowana różnica wyniosła +14,67 pp. **Jednocześnie bezwzględna skuteczność na zadaniach oznaczonych `solvable` wyniosła 13,80% przy minimum 70%, więc formalny werdykt pozostaje negatywny.** Dane wspierają efekt kontekstowy w tym środowisku, nie gotowość niezawodnego kontrolera. Źródło: [końcowe podsumowanie](./badania/heuristic-causal-lab-final-4.3/hcl_final_4_3/runs/study_20261002-122125/study/summary.json).

Do pełnego audytu prowadzą [opis badania](./badania/heuristic-causal-lab-final-4.3/README.md), [protokół 4.3.3](./badania/heuristic-causal-lab-final-4.3/hcl_final_4_3/FULL_STUDY_PROTOCOL.md), [zastosowany profil](./badania/heuristic-causal-lab-final-4.3/hcl_final_4_3/runs/study_20261002-122125/profile.json) i [źródłowy katalog runu](./badania/heuristic-causal-lab-final-4.3/hcl_final_4_3/runs/study_20261002-122125/). Mechanikę można sprawdzić w [kodzie instrumentu](./badania/heuristic-causal-lab-final-4.3/hcl_final_4_3/heuristic_lab/) oraz [testach](./badania/heuristic-causal-lab-final-4.3/hcl_final_4_3/tests/).

[Pełna tabela epizodów](./badania/heuristic-causal-lab-final-4.3/hcl_final_4_3/runs/study_20261002-122125/study/trials.csv) i [transport HTTP](./badania/heuristic-causal-lab-final-4.3/hcl_final_4_3/runs/study_20261002-122125/transport_http/) dokumentują wykonanie. [Eksporty publikacyjne](./badania/heuristic-causal-lab-final-4.3/artifacts/README.md) ułatwiają czytanie; [nota integralności](./badania/heuristic-causal-lab-final-4.3/PUBLICATION_INTEGRITY.md) opisuje sprawdzenie zgodności i korektę separatorów kopii CSV. Katalog `results/` zawiera pomocniczy selftest i nie zastępuje pełnego `runs/.../study/`.

### Powiązane modele, nie dodatkowe wyniki HCL

[Między znakiem a decyzją: semantyczna kompresja jako metaarchitektura AGI](./artykuły/AGI_SEMANTIC_COMPLEXITY_CONTROL_MODEL.md) rozwija model kontroli złożoności przez reprezentację, relewancję i kompresję. [LOCI–Agent–LLM](./artykuły/loci-agent-llm-state-space-control.md) rozdziela obserwację, ograniczenia, politykę, autoryzację i dynamikę środowiska. Są to teksty formalno-koncepcyjne: wyniki HCL nie potwierdzają automatycznie wszystkich ich tez ani całej postulowanej architektury.

<a id="4-epistemika-llm-kontekst-i-microcode"></a>
<a id="epistemika-llm-kontekst-i-microcode"></a>
## 2. Epistemika LLM, kontekst i microcode

Ta linia bada przejście od zapisu do znaczenia i od znaczenia do decyzji. [Prawda kontra fikcja w LLM](./prawda-vs-fikcja-w-llm.md) dotyczy statusu informacji i walidacji; [P0–P3](./P0-P3_truth-vs-fiction_detector_v1d.prompt) jest instrumentem klasyfikacyjnym, nie samodzielnym gwarantem prawdy. [Magia embeddingu](./magia-embeddingu-llm-slowo-w-czyn.md), [przyciski semantyczne](./przyciski-semantyczne-llm.md), [protokoły chunk–chunk](./protokoly_kontekstu_chunk-chunk_facebook_case.md) i [operator `‡`](./double_dagger_operator_kontekstu.md) opisują różne sposoby organizowania i przełączania kontekstu.

Serię microcode można czytać kolejno: [fundament — znak i semantyka](./ascii-ontologiczny-microcode-ai_czesc1-fundament-znak-semantyka.md), [część II](./ascii-microcode-ai_part2.md), [część III](./ascii-microcode-ai_part3.md), a następnie [synteza od znaku do ontologicznego mikrokodu](./ascii-microcode-llm_od-znaku-do-ontologicznego-mikrokodu.md). Uzupełniają ją [specyfikacja mikrokodu daty](./2025-12-04_mikrokod-daty_ascii-specyfikacja-dowod-replikowalny-eksperyment.md) i [deterministyczna metrologia HMK9D](./writeup_ascii_microcode_hmk9d_deterministic_metrology_repo.md).

Osobną ścieżkę tworzą [eksperyment kontekstowy AISEC / ASCII_MC_9D](./AISec_ASCII_MC_9D_eksperyment_kontekstowy.md), jego [prompt](./ASCII_MC_9D_MC.PROMPT) i [notatka bezpieczeństwa](./ASCII_MC_9D_notatka_bezpieczenstwa.md). [PROMPT_MOZOWANIE_V1](./PROMPT_MOZOWANIE_V1.prompt), [inwarianty wątków konwersacyjnych](./inwariant_llm_analiza_watkow_konwersacyjnych.md) oraz [teoria pojemności modeli i obliczalności](./teoria-pojemnosci-modeli-obliczalnosc.md) rozszerzają zakres pytań. Nazwy operatorów i wymiarów należy odczytywać zgodnie z definicjami w konkretnym materiale, nie jako wspólny certyfikat wszystkich proponowanych mechanizmów.

## 3. Bezpieczeństwo agentowe: od propozycji do kontrolowanego skutku

[**AI Security Model Boundary**](./ai_security_model_boundary_strategy_writeup.md) stanowi wejście do strategii bezpieczeństwa trajektorii wykonania. Towarzyszą mu [pełny raport badania falsyfikacyjnego](<./badania/Strategia bezpieczeństwa wobec AI-Driven Attacks pod presją wdrażania AI — badanie falsyfikacyjne Mo.pdf>) i [pakiet materiałów](./AI_Driven_Security_Research_Package_2026-08-18.zip). Wyniki modelowania i symulacji w tej linii należy odróżniać od częstości zdarzeń zaobserwowanych w produkcji.

[Koncepcja lokalnej warstwy bezpieczeństwa agenta na Linuxie](./agent-zabezpieczen-ai-driven-linux-koncepcja-badawcza.md) prowadzi przez planowanie, bramkę uprawnień, autoryzację, wykonanie i weryfikację. [Observability-Conditioned Reference Monitor](./OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md) wiąże możliwość skutku z obserwowalnością, pochodzeniem i integralnością. [Linux Multi-Agent Control Mesh](./LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md) rozszerza ten problem na populację agentów i domen. Wspólne rozróżnienie brzmi: **propozycja modelu nie jest autoryzacją działania**.

[Deterministyczna obserwowalność warstwy wykonawczej](./deterministyczna_obserwowalnosc_warstwy_wykonawczej_ai.md) opisuje kontrolowany szkielet działania; [enterprise AI governance proxy](./artykuły/enterprise-ai-governance-proxy.md) — mediację w organizacji; [LLM Trust Boundary Collapse](./artykuły/llm-trust-boundary-collapse-publication.md) — problem zacierania granic zaufania. [SBOM jako Sigillum Relationis](./sbom-as-sigillum-relationis_systemic-risk-control.md) przenosi uwagę na zależności i pochodzenie, a [raport konwergencji architektur](./global_architecture_convergence_baseline_report.md) porównuje wzorce, odróżniając podobieństwo od dowodu wpływu przyczynowego.

Scaffolding semantyczny i formalne zabezpieczenia pełnią tu różne funkcje: pierwszy wpływa na generowanie propozycji, drugie rozstrzygają dopuszczalność skutku. Repozytorium dokumentuje obie warstwy, lecz nie utożsamia skuteczniejszego kontekstu z kompletnym systemem egzekwowania polityki.

## 4. Laboratoria, symulacje i materiał do odtworzenia

### LOCI: od artefaktu do reprezentacji trajektorii

[LOCI](./badania/LOCI/README.md) obejmuje parsowanie, normalizację rekordów, budowę cech 27D, analizę trajektorii, testy i statyczne raporty. Według lokalnej dokumentacji kanoniczny pipeline tworzy macierz 27D i **projekcję 3D**, przez PCA lub kontrolowany fallback. Nie należy opisywać jej jako gotowej, zwalidowanej mapy `R^27 → R^9` ani bezpośredniego pomiaru stanów latentnych transformera.

Praktyczne wejścia to [parsers](./badania/LOCI/parsers/README.md), [sample](./badania/LOCI/sample/README.md), [MATLAB](./badania/LOCI/matlab/README.md), [specyfikacje](./badania/LOCI/spec/README.md), [testy](./badania/LOCI/tests/README.md), [wyniki](./badania/LOCI/results/README.md) i [raports](./badania/LOCI/raports/README.md). Formalny kontekst relacji obserwacja–agent–środowisko znajduje się w [publikacji LOCI–Agent–LLM](./artykuły/loci-agent-llm-state-space-control.md).

### Symulacja_GITHUB: amplifikacja obciążenia

[Indeks Symulacja_GITHUB](./badania/Symulacja_GITHUB/README.md), [raport](./badania/Symulacja_GITHUB/agentic_amplification_report.md) i [artykuł](./badania/Symulacja_GITHUB/article.md) opisują sandbox 1000 miniagentów i 100 000 realizacji Monte Carlo. Badane relacje obejmują retry, fan-out, degradację i współdzielone zależności. To model klasy mechanizmów; sam wynik symulacji nie ustala przyczyny konkretnej awarii GitHuba.

### Decyzje warunkowe, testy narracji i eksperymenty rynkowe

[Conditional Decision Theory](./badania/conditional_decision_theory/README.md) łączy raport i wyniki JSON dotyczące decyzji, ekspozycji, closure i adaptacji. Rozbudowany tekst publikacyjny znajduje się w [„Oczy szeroko zamknięte”](./artykuły/RESEARCH_WRITEUP_OCZY_SZEROKO_ZAMKNIETE.md), a [pakiet badania](./badania/oczy_kasyno_study_v1_with_writeup.zip) zachowuje materiały do jego odtworzenia.

[Pakiet KPRR](./badania/KPRR_wersja_ostateczna_20000_testow.zip) należy do linii iteracyjnych testów Human–AI. [MQL5Market](./badania/MQL5Market/README.md) jest odrębną eksperymentalną gałęzią rynkową, nie częścią benchmarku HCL. Raporty dotyczące finansów i formalności argumentacji są zebrane w [katalogu badań](./badania/README.md).

### Raporty PDF i pakiety badawcze

[**badania/README.md**](./badania/README.md) grupuje raporty według obszarów: AI/SaaS/Cloud i bezpieczeństwo systemowe; Human–AI, dane i ekonomika; percepcja, poznanie i język; LOCI, 9R–27D i metakod; OSINT i rekonstrukcje; finanse i decyzje. W katalogu są również [raport o The Bean Factory i LION](<./badania/The Bean Factory dla LION — raport badawczy nad ewolucyjną metaarchitekturą samoorganizującego się k.pdf>) oraz [raport badawczy i plan komercjalizacji](<./badania/The Bean Factory i LION — raport badawczy, naukowy REŻIM oraz plan komercjalizacji.pdf>). Tytuł raportu nie przesądza o potwierdzeniu jego tezy; zakres i metodę trzeba odczytywać z samego dokumentu.

<a id="6-humanai-organizacja-ekonomia-i-percepcja"></a>
<a id="humanai-społeczeństwo-ekonomia-i-percepcja"></a>
## 5. Human–AI, organizacja i ekonomika wykonania

[AI-Native Enterprise R&D](./AI_NATIVE_ENTERPRISE_RND_WRITEUP.md) ujmuje organizację jako sieć capabilities, ról, pamięci, kontekstu, mandatów i obserwowalności. [Evolutionary Agent Systems Organization Framework](./evolutionary-agent-systems-organization-framework.md) rozwija problem współewolucji organizacji i agentów. [Relational-Perceptual Protocol Bootstrap Model](./relational-perceptual-protocol-bootstrap-model.md) dotyczy protokołów relacyjnych i percepcyjnych, a [Mental Matrix / Mega Brain Coop Linux](./mental-matrix-mega-brain-coop-linux.MD) — środowiska współpracy Human–AI. [AI-Native Roadmap](./AI_NATIVE_ROADMAP.md) wyznacza ścieżkę promocji lokalnych badań do szerszego ekosystemu, nie zastępuje dokumentacji wdrożenia.

Linia **Wioski Kosmicznej** łączy organizację, produkcję danych i wykonalność ekonomiczną. Punkty wejścia to [Social-AI i premia za kreację](./06_kosmiczne_wioski_social_ai_premia_za_kreacje.md), [produktywność dla rozwoju AI](./produktywnosc_wioski_kosmicznej_dla_rozwoju_ai.md), [granica wykonalności](./granica_wykonalnosci_wioska_kosmiczna_writeup_v1.md), [kod cywilizacji Human–AI](./kod-cywilizacji-human-ai-spoleczenstwo-kosmos.md) oraz [taśma prototypowa i figury epistemiczne](./epistemiczna_tasma_prototypowa_figury.md). Materiały te mają własne modele i założenia; nie są wynikami finalnego runu HCL.

Percepcję i interfejsy opisują [VR-first a biologia człowieka](./06_METAVERSE_BIOLOGIA_CZLOWIEKA_DLACZEGO_VR_FIRST_NIE_SKALUJE.md), [manipulacja masami i percepcja przedrozumowa](./manipulacja_masami_probabilistyczna_propaganda_i_przedrozumowa_percepcja.md), [media i potencjał badawczy](./mokey-bissnes_k-wave-media_potencjal-naukowy.md) oraz [Blackbox w kosmosie](./blackbox_w_kosmosie.md). Powiązane raporty ekonomiczne, poznawcze i scenariuszowe znajdują się w [badania/](./badania/README.md).

<a id="5-cyber-malware-apt-i-incydenty"></a>
<a id="cyber-i-osint"></a>
<a id="analiza-malware-asyncshell"></a>
<a id="kampania-yokai-backdoor"></a>
<a id="fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia"></a>
## 6. Cyberbezpieczeństwo, malware, APT i OSINT

Klasyczne analizy bezpieczeństwa są częścią tego samego korpusu, ale mają odrębną podstawę źródłową od eksperymentów agentowych. [Fileless malware](./fileless-malware.md) opisuje techniki bezplikowe w środowisku Windows; [APT-K-47 / AsyncShell](./APT-K-47-asyncshell.md), [kampania Yokai Backdoor](./campaign-yokai-backdoor.md) i [operacja Cobalt Kitty](./operacja-cobalt-kitty.md) prowadzą do analiz kampanii i sposobów działania. [Malware evolution](./malware-evolution.md) oraz [Cybersecurity evolusion](./cybersecurity-evolusion.md) zachowują szerszy kontekst rozwoju technik i obrony.

[Fire Sale](./fire-sale.md) oraz [zakłócanie protokołów czasu, AsyncShell i Fire Sale](./2025-04_zaklocanie_protokolow_czasu_asyncshel_fire-sale.md) rozwijają scenariusze wielowarstwowe i zależności infrastrukturalne. Należy odróżniać opis scenariusza od udokumentowania konkretnego incydentu.

[OSINT/README.md](./OSINT/README.md) kieruje do wydzielonej analizy rekonstrukcyjnej „Arctic Metagaz”. Dalsze materiały o geopolityce, wywiadzie, wojnie asymetrycznej i kryptoanalizie są w [tematycznym katalogu badań](./badania/README.md). Rekonstrukcja, hipoteza atrybucyjna i symulacja scenariusza nie są tym samym rodzajem dowodu.

Materiały dotyczące technik ofensywnych służą badaniom, edukacji i obronie. Testowanie należy ograniczać do systemów własnych, laboratoriów i środowisk objętych zgodą właściciela. Sama obecność opisu w repozytorium nie stanowi zgody na wykonanie go wobec obcej infrastruktury.

## 7. Dane, grafiki i rozróżnienie rodzajów artefaktów

[images/README.md](./images/README.md) grupuje diagramy habitatów, taśmy epistemicznej, wartości zależnej od czasu, portfela real options, progów HITL, infrastruktury społeczno-epistemicznej i protokołów percepcyjnych. Ilustracje przedstawiają koncepcje i wyniki; nie są samodzielnym dowodem architektury ani pomiarem stanu modelu.

W katalogu głównym są również [dane wykresu globalnej implementacji](./dane_wykresu_globalnej_implementacji_2026-08-04.csv) i [macierz luk architektonicznych](./macierz_luk_architektonicznych_2026-08-04.csv). To datowane artefakty pomocnicze. Nie należy traktować ich jako aktualizowanych na żywo wskaźników.

Sposób czytania zależy od typu materiału. Writeup przedstawia interpretację; protokół określa warunki testu; kod realizuje instrument; `summary.json` agreguje wynik; `trials.csv` pozwala sprawdzać rekordy; surowy przebieg dokumentuje wymianę z modelem i narzędziami. Raport selftestu sprawdza instrument w swoim zakresie, ale nie jest wynikiem badania z żywym modelem. Archiwum ZIP jest formatem dostarczenia materiałów, a nie odrębną kategorią potwierdzenia naukowego.

## 8. Jak odróżniać wynik od hipotezy

Repozytorium zachowuje rozróżnienia `OBSERVED`, `DERIVED`, `CALIBRATED`, `ASSUMED`, `HYPOTHESIS`, `SPECULATION` i `STRESS PARAMETER`, opisane m.in. w [Process Guard](./PROCESS_GUARD.md). Przy czytaniu konkretnego materiału trzeba ustalić, co zmierzono, co obliczono z danych, co przyjęto jako założenie oraz czego dotyczy formalny werdykt. Wynik negatywny nie jest nieudanym załącznikiem — może być głównym rezultatem badania.

W HCL pomiar dotyczy zachowania modelu w syntetycznym środowisku. W symulacji Monte Carlo wynik dotyczy przyjętego modelu i jego parametrów. W LOCI projekcja opisuje reprezentację artefaktów, nie bezpośrednio wnętrze transformera. W architekturach referencyjnych opis rozwiązania nie jest dowodem jego wdrożenia. Również liczba iteracji, wielkość katalogu czy liczba plików nie zastępują oceny metody i niezależności danych.

Dla pracy z materiałem dowodowym właściwa kolejność to: dokument wynikowy, zastosowany protokół i profil, źródłowy run, rekordy, kod gradera, audyt oraz ograniczenia. W HCL finalny profil jest zachowany w konkretnym runie; ogólny szablon konfiguracji nie powinien go zastępować. Przed ponownym wykonaniem trzeba przeczytać [dokumentację instrumentu](./badania/heuristic-causal-lab-final-4.3/hcl_final_4_3/README.md) i nie nadpisywać zakończonych przebiegów.

## 9. LION, utrzymanie korpusu i portfolio

[AGENTS.md](./AGENTS.md) i [cyber-lion.repository.json](./cyber-lion.repository.json) określają lokalną rolę, zależności i kierowanie do właściciela architektury. [LION Architecture Role v1.4](./LION_ARCHITECTURE_ROLE_v1_4.md) jest przez manifest oznaczony jako materiał historyczny. [REPOSITORY_STANDARDIZATION_R1.json](./REPOSITORY_STANDARDIZATION_R1.json) dokumentuje standardyzację repozytorium. Nie należy wnioskować o aktualnym stanie federacji wyłącznie z datowanej publikacji lub indeksu.

[Process Guard](./PROCESS_GUARD.md) opisuje kontrolę zmian: źródło, intencję, kontekst, różnicę, uprawnienie, wykonanie, obserwację i werdykt. [Audyt z 18 sierpnia 2026](./REPOSITORY_AUDIT_2026-08-18.md) jest punktem kontrolnym w historii, nie automatycznym poświadczeniem późniejszych commitów. [Workflow higieny](./.github/workflows/repository-hygiene.yml) wykonuje ograniczone sprawdzenia obecności README i wybranych klas śledzonych plików lokalnych; nie zastępuje testów instrumentów ani recenzji badania.

[.gitignore](./.gitignore) chroni przed przypadkowym wersjonowaniem środowisk lokalnych i cache. Nie oznacza to wykluczenia całego materiału wygenerowanego przez badanie: pełne `runs/`, `results/` i `STUDY_STATE*.json` HCL są świadomie zachowanymi dowodami wykonania. Przed publikacją nowych śladów należy sprawdzać je pod kątem sekretów, danych osobowych i informacji nieprzeznaczonych do udostępnienia.

[PROFILE_README.md](./PROFILE_README.md) jest mapą szerszego portfolio, a [PROFILE_ABOUT.md](./PROFILE_ABOUT.md) opisuje profil zawodowy i badawczy. Autor i pozostałe repozytoria: [DonkeyJJLove](https://github.com/DonkeyJJLove).

---

**Główne wejścia:** [scaffolding — wynik HCL](./badania/heuristic-causal-lab-final-4.3/SEMANTIC_SCAFFOLDING_WRITEUP.md) · [badania](./badania/README.md) · [publikacje](./artykuły/README.md) · [LOCI](./badania/LOCI/README.md) · [OSINT](./OSINT/README.md) · [grafiki](./images/README.md) · [rola w LION](./AGENTS.md).
