# Badania — katalog badawczy i drzewo nawigacji

[← Główny katalog](../README.MD)

`badania/` jest głównym archiwum **living research** repozytorium. Zawiera raporty PDF, wyniki eksperymentów, pakiety reprodukcyjne, kod oraz wyspecjalizowane poddrzewa. Ten README jest **indeksem nawigacyjnym**: krótkie opisy wynikają z tytułów i roli plików w repo; status dowodowy znajduje się w samych badaniach.

## Drzewo

```text
badania/
├── README.md                      ← ten indeks
├── LOCI/                          ← pipeline 27D→9R, sample, testy, wyniki
├── conditional_decision_theory/   ← raport + wyniki JSON
├── MQL5Market/                    ← eksperymentalny szkielet rynku
├── *.pdf                          ← raporty badawcze
├── *.zip                          ← pakiety reprodukcyjne / artefakty
└── ...
```

### Podkatalogi

- [`LOCI/`](LOCI/README.MD) — kanoniczny pipeline parsowania, normalizacji, cech 27D, wizualizacji 27D→9R, testów i raportów.
- [`conditional_decision_theory/`](conditional_decision_theory/README.md) — badanie decyzji warunkowej, ekspozycji, closure i adaptacji.
- [`MQL5Market/`](MQL5Market/README.md) — mały eksperymentalny szkielet badawczy rynku.

---

## 1. AI, SaaS, Cloud, architektura i bezpieczeństwo systemowe

### Najnowsza linia: AI-Driven Security / Security Model Boundary

- [`Strategia bezpieczeństwa wobec AI-Driven Attacks pod presją wdrażania AI — badanie falsyfikacyjne Mo.pdf`](<Strategia bezpieczeństwa wobec AI-Driven Attacks pod presją wdrażania AI — badanie falsyfikacyjne Mo.pdf>) — pełne badanie falsyfikacyjne strategii bezpieczeństwa agentowego AI; obejmuje Security Model Boundary, Probabilistic–Deterministic Boundary, 1 000 000 realizacji Monte Carlo, 36 strategii, Pareto/tail-risk optimization, kontrfaktyczną falsyfikację, stress testing, adversarial search oraz model GREEN / AMBER / RED.
- [`../AI_Driven_Security_Research_Package_2026-08-18.zip`](../AI_Driven_Security_Research_Package_2026-08-18.zip) — pakiet materiałów badawczych powiązany z raportem i write-upem.
- [`../ai_security_model_boundary_strategy_writeup.md`](../ai_security_model_boundary_strategy_writeup.md) — publikacyjny write-up wyprowadzający z badania docelową strategię: federated enforcement, provenance, capability control, observability, deterministic execution boundary i ciągły RED/BLUE/PURPLE model expansion.

- [`Agent silniejszy od modelu i pricing jako dźwignia topologii.pdf`](<Agent silniejszy od modelu i pricing jako dźwignia topologii.pdf>) — relacja możliwości agenta, topologii systemu i ekonomiki inferencji.
- [`Anty‑wzorzec wobec SaaS w Twoim kodzie.pdf`](<Anty‑wzorzec wobec SaaS w Twoim kodzie.pdf>) — analiza kontrwzorca architektonicznego wobec SaaS.
- [`Asymetria Twoich repozytoriów wobec ryzyk SaaS+AI w warunkach „Armageddon AI”.pdf`](<Asymetria Twoich repozytoriów wobec ryzyk SaaS+AI w warunkach „Armageddon AI”.pdf>) — scenariuszowa analiza asymetrii ryzyka.
- [`Asymetria Twojej platformy wobec ryzyk SaaS+AI na tle ocen ekspertów i mediów.pdf`](<Asymetria Twojej platformy wobec ryzyk SaaS+AI na tle ocen ekspertów i mediów.pdf>) — porównanie platformy z zewnętrznymi ocenami ryzyka.
- [`Asymetria i ryzyka SaaS+AI_ konfrontacja Twoich repozytoriów z najnowszą oceną ekspertów i mediów.pdf`](<Asymetria i ryzyka SaaS+AI_ konfrontacja Twoich repozytoriów z najnowszą oceną ekspertów i mediów.pdf>) — synteza ryzyk SaaS+AI.
- [`Ataki kaskadowe w systemach sieciowych i infrastrukturze krytycznej.pdf`](<Ataki kaskadowe w systemach sieciowych i infrastrukturze krytycznej.pdf>) — propagacja i kaskady w systemach sieciowych.
- [`Ekonomiczny dowód pętli w pętli w AI, Cloud i SaaS.pdf`](<Ekonomiczny dowód pętli w pętli w AI, Cloud i SaaS.pdf>) — ekonomiczny model sprzężeń AI/Cloud/SaaS.
- [`Krytyczność poznawcza_ czy AI jest „sztuczną inteligencją”, czym jest świadomość i jak pętle Cloud+A.pdf`](<Krytyczność poznawcza_ czy AI jest „sztuczną inteligencją”, czym jest świadomość i jak pętle Cloud+A.pdf>) — krytyczna analiza pojęć AI i sprzężeń Cloud+AI.
- [`Luka sterowania ekonomią agentowego AI w SaaS.pdf`](<Luka sterowania ekonomią agentowego AI w SaaS.pdf>) — ekonomiczna luka sterowania agentowym AI.
- [`Luka sterowania ekonomią inferencji agentowej w Twojej architekturze SaaS+AI.pdf`](<Luka sterowania ekonomią inferencji agentowej w Twojej architekturze SaaS+AI.pdf>) — sterowanie kosztami i inferencją w architekturze agentowej.
- [`Ocena naukowa tezy i planu testów amortyzacji kolapsu Cloud+AI.pdf`](<Ocena naukowa tezy i planu testów amortyzacji kolapsu Cloud+AI.pdf>) — falsyfikacyjna ocena odporności na kolaps Cloud+AI.
- [`Pętla w pętli w SaaS i AI jako źródło „wybuchu” tematu cloud pricing.pdf`](<Pętla w pętli w SaaS i AI jako źródło „wybuchu” tematu cloud pricing.pdf>) — dynamika pricingu w sprzężonych systemach.
- [`Ryzyka i złożoność w SaaS+AI_ synteza Twoich repozytoriów i badań z oceną mediów oraz obserwatorów.pdf`](<Ryzyka i złożoność w SaaS+AI_ synteza Twoich repozytoriów i badań z oceną mediów oraz obserwatorów.pdf>) — przekrojowa synteza złożoności i ryzyka.
- [`Softwaregedon_ teza o fazowym przejściu BigTech od SaaS do gospodarki mocy obliczeniowej.pdf`](<Softwaregedon_ teza o fazowym przejściu BigTech od SaaS do gospodarki mocy obliczeniowej.pdf>) — hipoteza przejścia od SaaS do gospodarki compute.
- [`Superteza o mechanice Projektu Manhattan jako modelu wyścigu, losowania i kaskad w AI, Cloud i SaaS.pdf`](<Superteza o mechanice Projektu Manhattan jako modelu wyścigu, losowania i kaskad w AI, Cloud i SaaS.pdf>) — model wyścigu technologicznego i kaskad.
- [`Synteza repozytoriów DonkeyJJLove z ocenami ryzyk SaaS+AI i testem hipotez asymetrii.pdf`](<Synteza repozytoriów DonkeyJJLove z ocenami ryzyk SaaS+AI i testem hipotez asymetrii.pdf>) — synteza architektur i hipotez asymetrii.
- [`Teza o „mnożeniu logik” w AI, Cloud i SaaS, która prowadzi do kaskad i zmiany pricingu.pdf`](<Teza o „mnożeniu logik” w AI, Cloud i SaaS, która prowadzi do kaskad i zmiany pricingu.pdf>) — analiza nakładania logik i skutków kaskadowych.
- [`Weryfikacja naukowa anty‑wzorca wobec SaaS na kodzie DonkeyJJLove i jego zdolności amortyzacji kolap.pdf`](<Weryfikacja naukowa anty‑wzorca wobec SaaS na kodzie DonkeyJJLove i jego zdolności amortyzacji kolap.pdf>) — sprawdzenie antywzorca na kodzie i scenariuszach.
- [`Weryfikacja naukowa tezy i planu testów w kontrapunkcie do rzeczywistości.pdf`](<Weryfikacja naukowa tezy i planu testów w kontrapunkcie do rzeczywistości.pdf>) — ogólny test tezy i planu badań.

## 2. Human–AI, organizacja, dane i ekonomika

- [`Badania kontekstu dla produkcji AI jako wioski kosmicznej.pdf`](<Badania kontekstu dla produkcji AI jako wioski kosmicznej.pdf>) — kontekst jako element produkcji AI.
- [`Ekonomiczna falsyfikacja modelu „data-only” dla wioski kosmicznej jako centrum produkcji danych dla .pdf`](<Ekonomiczna falsyfikacja modelu „data-only” dla wioski kosmicznej jako centrum produkcji danych dla .pdf>) — test ekonomiczny modelu data-only.
- [`Ekonomiczna opłacalność „wioski kosmicznej” jako pasywnego, ekologicznego centrum produkcji produktó.pdf`](<Ekonomiczna opłacalność „wioski kosmicznej” jako pasywnego, ekologicznego centrum produkcji produktó.pdf>) — analiza opłacalności modelu Wioski Kosmicznej.
- [`Ekonomiczna „taśma prototypowa danych” poniżej progu startupu_ jak seryjnie przekuwać brakujące dane.pdf`](<Ekonomiczna „taśma prototypowa danych” poniżej progu startupu_ jak seryjnie przekuwać brakujące dane.pdf>) — prototypowanie danych przy niskim progu kapitałowym.
- [`Ekosystemy Human-AI w modelu „wioski kosmicznej” – analiza pięciu habitatów.pdf`](<Ekosystemy Human-AI w modelu „wioski kosmicznej” – analiza pięciu habitatów.pdf>) — porównanie pięciu habitatów Human–AI.
- [`Integralność i wiarygodność Big Data_ zasady naukowe, mechanizmy zniekształceń i kontrola jakości pr.pdf`](<Integralność i wiarygodność Big Data_ zasady naukowe, mechanizmy zniekształceń i kontrola jakości pr.pdf>) — integralność, zniekształcenia i jakość danych.
- [`Kompetencje AI jako rdzeń „organicznej” wioski kosmicznej_ model mrowiska, intuicja na metapoziomie .pdf`](<Kompetencje AI jako rdzeń „organicznej” wioski kosmicznej_ model mrowiska, intuicja na metapoziomie .pdf>) — kompetencje i organizacja rozproszona.
- [`Metadane w logice artefaktu i w tekście jako sygnał treningowy dla modelu językowego.pdf`](<Metadane w logice artefaktu i w tekście jako sygnał treningowy dla modelu językowego.pdf>) — metadane jako sygnał dla LLM.
- [`Metadane w logice artefaktu tekstowego jako „test intuicji” na dokumentach.pdf`](<Metadane w logice artefaktu tekstowego jako „test intuicji” na dokumentach.pdf>) — eksperyment nad rolą metadanych w interpretacji.
- [`Metodyka klasyfikacji i oceny opłacalności zbiorów danych dla AI.pdf`](<Metodyka klasyfikacji i oceny opłacalności zbiorów danych dla AI.pdf>) — klasyfikacja wartości zbiorów danych.
- [`Obieg wartości intelektualnej w topologiach LLM, sieci agentowej i BTC z uwzględnieniem złożoności o (1).pdf`](<Obieg wartości intelektualnej w topologiach LLM, sieci agentowej i BTC z uwzględnieniem złożoności o (1).pdf>) — przepływ wartości w topologiach AI i sieci.
- [`Opłacalność ekonomiczna i kreacja wartości w systemach Human‑AI In‑The‑Loop.pdf`](<Opłacalność ekonomiczna i kreacja wartości w systemach Human‑AI In‑The‑Loop.pdf>) — ekonomika HITL.
- [`Pięć racjonalnych modeli hybrydowej wioski kosmicznej Social‑AI_ rachunek opłacalności, heurystyki s.pdf`](<Pięć racjonalnych modeli hybrydowej wioski kosmicznej Social‑AI_ rachunek opłacalności, heurystyki s.pdf>) — porównanie modeli hybrydowych Social-AI.
- [`Pokolenie Kosmiczne_ naukowy projekt koncepcyjny sieci „wiosek kosmicznych” agentów AI jako infrastr.pdf`](<Pokolenie Kosmiczne_ naukowy projekt koncepcyjny sieci „wiosek kosmicznych” agentów AI jako infrastr.pdf>) — sieć agentowych habitatów jako infrastruktura.
- [`Produktywność „wioski kosmicznej” dla rozwoju AI_ ramy naukowe, mechaniki badawcze i modele ekonomic.pdf`](<Produktywność „wioski kosmicznej” dla rozwoju AI_ ramy naukowe, mechaniki badawcze i modele ekonomic.pdf>) — modele produktywności dla rozwoju AI.
- [`Wartość dodana tekstu generowanego przez AI jako dane do meta‑uczenia modeli językowego.pdf`](<Wartość dodana tekstu generowanego przez AI jako dane do meta‑uczenia modeli językowego.pdf>) — wartość generowanego tekstu jako danych.
- [`Wioska Kosmiczna_ naukowy i operacyjny model zarządzania granicą wykonalności.pdf`](<Wioska Kosmiczna_ naukowy i operacyjny model zarządzania granicą wykonalności.pdf>) — model operacyjny granicy wykonalności.

## 3. Percepcja, poznanie, epistemika i język

- [`Archetyp „Maga” a Instynkt Tropiciela w Ekosystemie Wioski Kosmicznej_ Połączenie Intuicji i Technol.pdf`](<Archetyp „Maga” a Instynkt Tropiciela w Ekosystemie Wioski Kosmicznej_ Połączenie Intuicji i Technol.pdf>) — intuicja, tropienie i technologia w modelu Human–AI.
- [`Emancypacja poznawcza ponad „sufit pamięciówki”_ formalny model kompresja–generowanie _ Cognitive em.pdf`](<Emancypacja poznawcza ponad „sufit pamięciówki”_ formalny model kompresja–generowanie _ Cognitive em.pdf>) — formalny model kompresji i generowania poznawczego.
- [`Inteligencja generatywna i inteligencja deklaratywno-poznawcza od 1920 roku w perspektywie antropolo.pdf`](<Inteligencja generatywna i inteligencja deklaratywno-poznawcza od 1920 roku w perspektywie antropolo.pdf>) — historyczno-antropologiczne ujęcie inteligencji.
- [`Kino, telewizja, internet i social network — od propagandy, przez sprzedaż do błędów postrzegania rz.pdf`](<Kino, telewizja, internet i social network — od propagandy, przez sprzedaż do błędów postrzegania rz.pdf>) — media i mechanizmy percepcji.
- [`Matematyczne podstawy i naukowa analiza metody „czukockiej” w zastosowaniach BCI.pdf`](<Matematyczne podstawy i naukowa analiza metody „czukockiej” w zastosowaniach BCI.pdf>) — analiza matematyczna metody w kontekście BCI.
- [`Od głośnego czytania do transformerów_ LLM, neuroplastyczność czytania i przemysłowa optymalizacja u.pdf`](<Od głośnego czytania do transformerów_ LLM, neuroplastyczność czytania i przemysłowa optymalizacja u.pdf>) — czytanie, neuroplastyczność i LLM.
- [`Oddychaj, kompromis pokorny i krzywa sensu w gospodarce mocy obliczeniowej.pdf`](<Oddychaj, kompromis pokorny i krzywa sensu w gospodarce mocy obliczeniowej.pdf>) — krzywa sensu i kompromisy compute.
- [`Ontologia emocji jako warstwa metaprogramowania dla systemów LLM w układach Human–AI.pdf`](<Ontologia emocji jako warstwa metaprogramowania dla systemów LLM w układach Human–AI.pdf>) — emocje jako warstwa metaprogramowania Human–AI.
- [`Ontologia percepcji i paradoks jako fundament w pełni naukowego escape roomu.pdf`](<Ontologia percepcji i paradoks jako fundament w pełni naukowego escape roomu.pdf>) — percepcja, paradoks i konstrukcja eksperymentalna.
- [`Pamięciówka, „sufit trudności” i emancypacja poznawcza_ artykuł syntetyczny w kontrapunkcie badań _ .pdf`](<Pamięciówka, „sufit trudności” i emancypacja poznawcza_ artykuł syntetyczny w kontrapunkcie badań _ .pdf>) — synteza badań nad pamięcią i poznaniem.
- [`Paradoks Księżniczki i Umysł Szympansa_ krytyczny przegląd dowodów naukowych oraz falsyfikowalna def.pdf`](<Paradoks Księżniczki i Umysł Szympansa_ krytyczny przegląd dowodów naukowych oraz falsyfikowalna def.pdf>) — krytyczny przegląd i falsyfikowalna definicja.
- [`Paradoks Marii_ udomowienie kobiecej sprawczości w środowiskach decyzyjnych o dużej złożoności.pdf`](<Paradoks Marii_ udomowienie kobiecej sprawczości w środowiskach decyzyjnych o dużej złożoności.pdf>) — sprawczość i złożone środowiska decyzyjne.
- [`Poezja tensorowa jako poezja cybernetyczna.pdf`](<Poezja tensorowa jako poezja cybernetyczna.pdf>) — formalno-koncepcyjne ujęcie poezji tensorowej.
- [`Rygorystyczne badanie zastosowań eksperymentu 20 000 iteracyjnych narracji Human+AI.pdf`](<Rygorystyczne badanie zastosowań eksperymentu 20 000 iteracyjnych narracji Human+AI.pdf>) — zastosowania dużego eksperymentu iteracyjnego Human+AI.

## 4. LOCI, 9R–27D, metakod i metodologia

- [`Aula Leopoldina_,_wroclaw, poland_] jako architektura wejścia w LOCI.pdf`](<Aula Leopoldina_,_wroclaw, poland_] jako architektura wejścia w LOCI.pdf>) — architektura wejścia do LOCI.
- [`El Escorial jako architektura LOCI w Europie_ rygorystyczna analiza naukowa.pdf`](<El Escorial jako architektura LOCI w Europie_ rygorystyczna analiza naukowa.pdf>) — analiza architektury LOCI.
- [`Formalizacja 9R 27D_ 27‑wymiarowa semantyka poezji tensorowej dla tematu wywiad i PI.pdf`](<Formalizacja 9R 27D_ 27‑wymiarowa semantyka poezji tensorowej dla tematu wywiad i PI.pdf>) — formalizacja przestrzeni 27D/9R.
- [`Metodologia Symulacji.pdf`](<Metodologia Symulacji.pdf>) — materiał metodologiczny dotyczący symulacji.
- [`Mozaikowy program badawczy Human–AI_ od analiz czułości (Sobol_Ulam) i rewizyjności do architektur r.pdf`](<Mozaikowy program badawczy Human–AI_ od analiz czułości (Sobol_Ulam) i rewizyjności do architektur r.pdf>) — program łączący sensitivity, rewizyjność i architektury Human–AI.
- [`Organiczna modelowa analiza dynamiczna zdarzeń bezpieczeństwa w kontrapunkcie metody LOCI.pdf`](<Organiczna modelowa analiza dynamiczna zdarzeń bezpieczeństwa w kontrapunkcie metody LOCI.pdf>) — model dynamiczny zdarzeń bezpieczeństwa vs LOCI.
- [`RFC-LOCI-CS-1_ Sformalizowanie i rozwinięcie znaków sterujących jako DSL sterowania.pdf`](<RFC-LOCI-CS-1_ Sformalizowanie i rozwinięcie znaków sterujących jako DSL sterowania.pdf>) — formalizacja znaków sterujących jako DSL.
- [`Rygorystyczne obalenie błędu architektonicznego w torze ingestu danych.pdf`](<Rygorystyczne obalenie błędu architektonicznego w torze ingestu danych.pdf>) — falsyfikacja błędu w ingest pipeline.

Pełny kod i artefakty LOCI: [`LOCI/README.MD`](LOCI/README.MD).

## 5. OSINT, geopolityka, kryptologia i rekonstrukcja

- [`Absolutna faktografia oraz struktura metakodu i kodu dla pracy „Iran — wojna asymetryczna”.pdf`](<Absolutna faktografia oraz struktura metakodu i kodu dla pracy „Iran — wojna asymetryczna”.pdf>) — faktografia i struktura materiału o wojnie asymetrycznej.
- [`CRYPTOANALIZA ODDZIAŁUJE NA STRUKTURĘ ARTEFAKTÓW (1).pdf`](<CRYPTOANALIZA ODDZIAŁUJE NA STRUKTURĘ ARTEFAKTÓW (1).pdf>) — relacja kryptoanalizy i struktury artefaktów.
- [`Dwanaście Trąb Jerycha_ relacje scenariuszy „Chaosu” z bieżącą dynamiką Iran–Izrael–USA.pdf`](<Dwanaście Trąb Jerycha_ relacje scenariuszy „Chaosu” z bieżącą dynamiką Iran–Izrael–USA.pdf>) — scenariusze geopolityczne i ich relacje.
- [`Wojna Iran–USA–Izrael_ rekonstrukcja, model ryzyka upadku reżimu i symulacja scenariuszowa.pdf`](<Wojna Iran–USA–Izrael_ rekonstrukcja, model ryzyka upadku reżimu i symulacja scenariuszowa.pdf>) — rekonstrukcja i model scenariuszowy.
- [`Wojna wywiadu jako opowieść skalująca się w czasie.pdf`](<Wojna wywiadu jako opowieść skalująca się w czasie.pdf>) — analiza skalowania narracji wywiadowczej w czasie.

Dodatkowe materiały OSINT: [`../OSINT/README.md`](../OSINT/README.md).

## 6. Finanse i decyzje

- [`Studium falsyfikacyjne procesu i plan implementacji algorytmu merger‑arbitrage dla case’u UHG.pdf`](<Studium falsyfikacyjne procesu i plan implementacji algorytmu merger‑arbitrage dla case’u UHG.pdf>) — badanie procesu merger-arbitrage dla konkretnego case’u.
- [`Ocena formalności i kompletności „dowodu” paradoksu księżniczki w załączonym dokumencie.pdf`](<Ocena formalności i kompletności „dowodu” paradoksu księżniczki w załączonym dokumencie.pdf>) — audyt formalności argumentacji/dowodu.

Kod eksperymentalny rynku: [`MQL5Market/README.md`](MQL5Market/README.md).

## 7. Pakiety reprodukcyjne

- [`../AI_Driven_Security_Research_Package_2026-08-18.zip`](../AI_Driven_Security_Research_Package_2026-08-18.zip) — pakiet materiałów do badania strategii bezpieczeństwa wobec AI-Driven Attacks; powiązany z raportem PDF i write-upem SMB.
- [`KPRR_wersja_ostateczna_20000_testow.zip`](KPRR_wersja_ostateczna_20000_testow.zip) — pakiet wyników / testów KPRR.
- [`oczy_kasyno_study_v1_with_writeup.zip`](oczy_kasyno_study_v1_with_writeup.zip) — pakiet badania wraz z write-upem i artefaktami.

---

## Jak przeszukiwać tę gałąź

Najpierw wybierz **temat**, potem przejdź do dokumentu, a dopiero następnie do kodu/wyników:

```text
README.MD
→ badania/README.md
→ temat
→ raport PDF / podkatalog badawczy
→ kod / dane / wyniki
→ publikacyjny write-up
```

Dla badań z kodem lub danymi za wiążący należy uważać kontrakt i artefakty opisane w lokalnym README, nie samą nazwę pliku.

## Status epistemiczny

Ten indeks **nie uznaje wszystkich tez zawartych w katalogu za potwierdzone**. `badania/` przechowuje również hipotezy, falsyfikacje, warianty odrzucone i materiały eksploracyjne. Czytaj deklaracje `FACT`, `OBSERVED`, `DERIVED`, `CALIBRATED`, `ASSUMED`, `HYPOTHESIS`, `SPECULATION` i ograniczenia w dokumentach źródłowych.
