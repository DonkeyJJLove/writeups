# LLM Trust Boundary Collapse: załamanie granic zaufania jako wspólny rdzeń prompt injection, RAG injection i agent abuse

## Abstrakt

[FACT] Systemy oparte na dużych modelach językowych przestały być wyłącznie interfejsami tekstowymi i coraz częściej pełnią funkcję warstwy decyzyjnej, pośredniczącej między użytkownikiem, kontekstem, pamięcią, narzędziami i wykonaniem operacji. Wraz z tym przesunięciem rośnie znaczenie problemu, który w niniejszym artykule określamy jako LLM Trust Boundary Collapse, czyli załamanie granicy zaufania w systemach LLM. Hipoteza badawcza zakłada, że wiele pozornie odrębnych klas ryzyka, takich jak prompt injection, RAG injection, memory poisoning, goal hijacking, tool injection i agent abuse, może mieć wspólny rdzeń architektoniczny: brak trwałej, egzekwowalnej separacji między danymi, instrukcjami, kontekstem, autorytetem, pamięcią i wykonaniem. Metoda artykułu polega na analizie pojęciowej, mapowaniu do OWASP LLM Top 10, MITRE ATLAS, CWE i znanych przypadków CVE oraz na próbie falsyfikacji tezy. Wynik analizy jest ostrożny: LLM Trust Boundary Collapse nie powinien być traktowany jako CVE ani samodzielnie dowiedziona nowa podatność, ale jako użyteczny model wyjaśniający, który pozwala spójnie opisać wiele obserwowanych awarii bezpieczeństwa w systemach agentowych. Znaczenie praktyczne modelu polega na przesunięciu obrony z poziomu „lepszego promptu” na poziom architektury: provenance, separacji uprawnień, kontroli narzędzi, higieny pamięci, walidacji wyjścia i audytu granic zaufania.

## Słowa kluczowe

LLM security, prompt injection, RAG injection, agent abuse, trust boundary, memory poisoning, authority provenance, decision provenance, LBOM, OWASP LLM, MITRE ATLAS, CWE-1427, AI governance, agentic AI security.

## 1. Wprowadzenie

[FACT] Wczesne wdrożenia LLM były zwykle traktowane jako systemy generujące tekst: model otrzymywał pytanie i zwracał odpowiedź. Ryzyko bezpieczeństwa ograniczano wtedy głównie do niepożądanej treści, halucynacji, ujawnienia promptu systemowego albo obejścia filtrów. Ta perspektywa jest dziś niewystarczająca, ponieważ współczesne aplikacje LLM coraz częściej otrzymują dostęp do repozytoriów kodu, skrzynek e-mail, dokumentów, baz wektorowych, systemów ticketowych, interfejsów API, przeglądarek, terminali, interpreterów kodu i narzędzi administracyjnych.

[FACT] W takim układzie LLM nie jest tylko generatorem odpowiedzi, lecz komponentem pośredniczącym w decyzji: wybiera dane, interpretuje cel, rekonstruuje kontekst, kwalifikuje autorytet, decyduje o użyciu narzędzia i może inicjować skutek operacyjny. Właśnie w tym przejściu od odpowiedzi do działania powstaje nowy problem bezpieczeństwa: granice zaufania, które w klasycznej architekturze systemowej były rozdzielane przez typy, protokoły, uprawnienia, procesy, podpisy, ACL-e i transakcje, w systemach LLM są często reprezentowane jako tekst lub jako kontekst semantyczny.

[LIKELY] Autorska heurystyka LLM Trust Boundary Collapse opisuje to zjawisko jako awarię separacji warstw. Jeżeli model otrzymuje instrukcje systemowe, dane użytkownika, wyniki RAG, pamięć długoterminową, wynik narzędzia i politykę bezpieczeństwa w przestrzeni, która dla modelu jest wspólną sekwencją tokenów, to system może utracić stabilną zdolność rozróżnienia, co jest danymi, co instrukcją, co źródłem prawdy, co tylko kontekstem, a co autoryzowanym poleceniem wykonawczym.

[FACT] Ten problem nie jest równoważny z klasycznym CVE. CVE opisuje konkretną, publicznie ujawnioną podatność w konkretnym produkcie, wersji lub komponencie. Heurystyka LLM Trust Boundary Collapse nie spełnia tego kryterium sama z siebie. Może natomiast służyć jako model wyjaśniający mechanizm, który pojawia się w różnych podatnościach i klasach ryzyka.

## 2. Definicja problemu

[LIKELY] LLM Trust Boundary Collapse to stan architektoniczny, w którym system LLM nie utrzymuje egzekwowalnej, trwałej i audytowalnej separacji między sześcioma warstwami:

DATA — dane wejściowe, dokumenty, strony, e-maile, logi, wyniki RAG, komentarze w kodzie, treść użytkownika.

INSTRUCTION — polecenia użytkownika, instrukcje systemowe, polityki aplikacji, instrukcje deweloperskie, reguły działania agenta.

CONTEXT — informacje pomocnicze, historia rozmowy, opis środowiska, stan zadania, wynik poprzednich kroków.

AUTHORITY — źródło uprawnienia, tożsamość aktora, zakres delegacji, polityka organizacyjna, signed instruction, rola użytkownika.

MEMORY — pamięć sesji, pamięć długoterminowa, preferencje, zapamiętane reguły, embeddingi, stan agenta.

ACTION — wywołanie narzędzia, wykonanie kodu, zapis pliku, wysłanie e-maila, modyfikacja rekordu, użycie API, wykonanie komendy.

[FACT] W klasycznym modelu bezpieczeństwa dane i instrukcje powinny być traktowane jako różne kategorie semantyczne i wykonawcze. Dane mogą być przetwarzane, ale nie powinny samodzielnie przejmować roli instrukcji. Instrukcja może inicjować proces, ale powinna mieć źródło autorytetu. Pamięć może wspierać kontekst, ale nie powinna automatycznie stać się źródłem prawdy. Narzędzie może wykonać działanie, ale wyłącznie w granicach jawnej polityki wykonania.

[LIKELY] LLM Trust Boundary Collapse występuje wtedy, gdy te separacje nie są wymuszone technicznie, lecz pozostają jedynie konwencją językową wewnątrz promptu. Wtedy treść z dokumentu może zostać potraktowana jako instrukcja, wynik narzędzia jako autorytet, pamięć jako prawda, a wygenerowana odpowiedź jako podstawa wykonania operacji.

## 3. Model formalny

[FACT] Dla potrzeb modelu przyjmujemy sześć klas semantyczno-operacyjnych:

D = Data
I = Instruction
C = Context
A = Authority
M = Memory
X = Execution

Stan pożądany można zapisać jako:

D ≠ I ≠ C ≠ A ≠ M ≠ X

Nie oznacza to, że warstwy nie mogą się komunikować. Oznacza to, że przejście między nimi wymaga bramki: walidacji, provenance, podpisu, autoryzacji, polityki narzędziowej, audytu albo zatwierdzenia człowieka.

Stan błędny można opisać jako serię niekontrolowanych rzutowań:

D → I
C → A
M → Truth
I → X

Pierwsze przejście, D → I, oznacza, że dane zewnętrzne są interpretowane jako instrukcja. Jest to rdzeń prompt injection i RAG injection.

Drugie przejście, C → A, oznacza, że sam fakt obecności informacji w kontekście nadaje jej fałszywy autorytet. Przykładem jest sytuacja, w której wynik wyszukania, treść dokumentu albo log techniczny zaczyna sterować celem agenta.

Trzecie przejście, M → Truth, oznacza, że zapamiętana informacja zostaje uznana za źródło prawdy, mimo że mogła pochodzić z niezweryfikowanego wejścia. Jest to rdzeń memory poisoning i recursive ontology drift.

Czwarte przejście, I → X, oznacza, że wygenerowana lub zreinterpretowana instrukcja przechodzi do wykonania bez niezależnej kontroli. W systemach agentowych jest to najbardziej krytyczny moment, ponieważ skutkiem nie jest już niepoprawna odpowiedź, lecz operacja na realnym systemie.

[LIKELY] LLM Trust Boundary Collapse można więc rozumieć jako błąd nie tyle w samym modelu językowym, ile w całej architekturze orkiestracji: prompt construction, RAG, memory layer, tool routing, authorization, execution policy i audit trail.

## 4. Mechanizm ataku

[FACT] Mechanizm należy opisywać abstrakcyjnie, bez instrukcji exploitacyjnych. Typowy łańcuch wygląda następująco:

niezaufane dane
→ interpretacja jako instrukcja
→ zmiana celu lub priorytetu zadania
→ wykorzystanie kontekstu i pamięci
→ decyzja modelu
→ wywołanie narzędzia
→ skutek bezpieczeństwa

[FACT] W prompt injection atakujący próbuje wpłynąć na zachowanie modelu przez treść wejściową. W indirect prompt injection treść ta nie musi być wpisana bezpośrednio przez użytkownika; może pochodzić z dokumentu, strony internetowej, wiadomości e-mail, komentarza w repozytorium, rekordu bazy wiedzy, logu lub wyniku narzędzia.

[LIKELY] W RAG injection problem staje się trudniejszy, ponieważ system sam pobiera treści, które następnie przedstawia modelowi jako „kontekst”. Jeżeli RAG nie posiada etykiet źródła, zaufania, intencji i zakresu użycia, model może potraktować odzyskaną treść jako część instrukcji zadania. W ten sposób baza wiedzy przestaje być tylko magazynem danych, a staje się kanałem sterowania.

[LIKELY] W memory poisoning niebezpieczeństwo polega na tym, że jednorazowa manipulacja może zostać utrwalona w pamięci. System nie tylko odpowiada błędnie w jednej sesji, lecz może przenieść zmanipulowaną regułę, preferencję lub fałszywe założenie do kolejnych interakcji.

[LIKELY] W agent abuse punkt krytyczny pojawia się przy narzędziach. Model, który ma dostęp do funkcji wykonawczych, nie tylko generuje tekst, ale może pośrednio pisać pliki, uruchamiać kod, wysyłać wiadomości, odczytywać dane, modyfikować konfiguracje albo podejmować decyzje operacyjne. Wtedy prompt injection przestaje być problemem „treści”, a staje się problemem kontroli wykonania.

## 5. Mapowanie do OWASP LLM Top 10

[FACT] LLM Trust Boundary Collapse nie powinien być traktowany jako konkurencyjna lista wobec OWASP LLM Top 10. Bardziej precyzyjnie: może działać jako warstwa nadrzędna lub model przyczynowy, który tłumaczy, dlaczego kilka pozycji OWASP pojawia się często w tych samych architekturach.

| OWASP LLM Top 10                      | Relacja do LLM Trust Boundary Collapse                                                              | Status   |
| ------------------------------------- | --------------------------------------------------------------------------------------------------- | -------- |
| LLM01 Prompt Injection                | Bezpośredni przypadek D → I, czyli danych interpretowanych jako instrukcja.                         | FACT     |
| LLM04 Data and Model Poisoning        | Zatrucie danych, modeli lub embeddingów może prowadzić do C → A albo M → Truth.                     | LIKELY   |
| LLM05 Improper Output Handling        | Wyjście modelu przechodzi do downstream component bez walidacji; ryzyko I/X lub output → execution. | FACT     |
| LLM06 Excessive Agency                | Nadmierne uprawnienia agenta zwiększają skutki błędnego przejścia I → X.                            | FACT     |
| LLM07 System Prompt Leakage           | Ujawnienie instrukcji systemowych osłabia separację instrukcji, polityki i danych.                  | LIKELY   |
| LLM08 Vector and Embedding Weaknesses | Wektorowe źródła RAG mogą wprowadzać niezaufany kontekst jako pozornie autorytatywny materiał.      | LIKELY   |
| LLM09 Misinformation                  | M → Truth i C → A mogą utrwalać fałszywe informacje jako podstawę decyzji.                          | LIKELY   |
| LLM10 Unbounded Consumption           | Brak granic wykonania i kosztu może pozwolić zmanipulowanemu agentowi zużywać zasoby.               | POSSIBLE |

[FACT] Najsilniejsze powiązania dotyczą LLM01, LLM05 i LLM06. LLM01 opisuje samo pomieszanie danych i instrukcji. LLM05 opisuje ryzyko braku kontroli wyjścia modelu przed przekazaniem go dalej. LLM06 opisuje wzrost skutków, gdy model otrzymuje narzędzia, uprawnienia i autonomię.

## 6. Relacja do MITRE ATLAS

[FACT] MITRE ATLAS jest wiedzą bazową o taktykach, technikach i przypadkach ataków na systemy AI. LLM Trust Boundary Collapse nie jest techniką ATLAS, ale może pomóc grupować techniki dotyczące manipulacji zachowaniem modelu, zatrucia kontekstu, narzędzi agentowych i efektów wykonawczych.

[LIKELY] Najbliższe obszary ATLAS to:

prompt injection — manipulacja wejściem lub kontekstem LLM w celu zmiany zachowania systemu;

poisoning — zatrucie danych, modelu, pamięci, narzędzia lub źródła RAG;

evasion — obejście mechanizmów detekcji i klasyfikacji intencji;

exfiltration — doprowadzenie systemu do ujawnienia danych przez odpowiedź, link, narzędzie albo kanał pośredni;

command execution przez agenta — sytuacja, w której model pośredniczy w wykonaniu operacji przez narzędzie;

manipulation of AI system behavior — zmiana celu, priorytetu, tożsamości operacyjnej lub sposobu działania systemu.

[FACT] Nie należy przypisywać tu niezweryfikowanych identyfikatorów technik. Jeżeli publikacja ma wejść w reżim formalny, konieczne jest osobne, źródłowe mapowanie do aktualnej wersji ATLAS i jej identyfikatorów.

## 7. Relacja do CWE i CVE

### 7.1. CWE

[FACT] CWE nie jest tym samym co CVE. CWE opisuje typ słabości, natomiast CVE opisuje konkretną, publicznie ujawnioną podatność. LLM Trust Boundary Collapse można mapować do CWE tylko wtedy, gdy istnieje realna analogia przyczynowa.

Najsilniejsze mapowanie:

| CWE                                                                                         | Relacja                                                                                                                                                 | Status   |
| ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| CWE-1427 Improper Neutralization of Input Used for LLM Prompting                            | Najbliższe formalne ujęcie problemu: prompt zbudowany z danych zewnętrznych powoduje, że LLM nie rozróżnia wejścia użytkownika od dyrektyw systemowych. | FACT     |
| CWE-20 Improper Input Validation                                                            | Pomocnicze mapowanie, gdy problemem jest brak walidacji właściwości wejścia. Niewystarczające jako pełny opis prompt injection.                         | POSSIBLE |
| CWE-74 Improper Neutralization of Special Elements in Output Used by a Downstream Component | Użyteczne przy analizie injection jako zmiany przepływu procesu przez dane kontrolne.                                                                   | POSSIBLE |
| CWE-77 / CWE-78 Command / OS Command Injection                                              | Tylko gdy model lub jego wyjście wpływa na komendę lub argument wykonawczy.                                                                             | POSSIBLE |
| CWE-94 Code Injection                                                                       | Tylko gdy wyjście GenAI jest przekazywane do komponentu generującego lub wykonującego kod.                                                              | POSSIBLE |
| CWE-1426 Improper Validation of Generative AI Output                                        | Należy używać ostrożnie; może dotyczyć output handling, ale nie powinno automatycznie zastępować analizy root cause.                                    | POSSIBLE |
| CWE-200 Exposure of Sensitive Information                                                   | Dotyczy skutku ujawnienia informacji, nie rdzenia trust boundary collapse.                                                                              | POSSIBLE |
| CWE-269 Improper Privilege Management                                                       | Może być pomocne przy analizie agentów z nadmiernymi uprawnieniami.                                                                                     | POSSIBLE |

[FACT] Najważniejszym punktem jest CWE-1427. To formalny sygnał, że problem braku separacji danych i instrukcji w promptach został już ujęty w katalogu słabości. Nie oznacza to jednak, że każdy przypadek LLM Trust Boundary Collapse automatycznie mapuje się do CWE-1427. Trzeba badać root cause.

### 7.2. CVE

[FACT] Heurystyka LLM Trust Boundary Collapse nie jest CVE. CVE wymaga konkretnego produktu, konkretnej podatności, dotkniętej wersji i publicznej dokumentacji.

[FACT] Poprawna forma brzmi: „ta heurystyka przypomina mechanizm obserwowany w niektórych CVE dotyczących systemów LLM, RAG lub agentów”. Niepoprawna forma brzmi: „ta heurystyka ma CVE”.

Przykłady podobieństwa:

| Przypadek                                 | Interpretacja                                                                                                                                                              | Status   |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| CVE-2024-5565, Vanna.AI                   | Przykład podatności, w której techniki prompt injection prowadziły do remote code execution przez integrację LLM z generowaniem i wykonaniem kodu.                         | FACT     |
| CVE-2026-26030, Microsoft Semantic Kernel | Przykład, w którym prompt injection w warunkach narzędzi agentowych mógł prowadzić do RCE przez podatny mechanizm narzędziowy.                                             | FACT     |
| CVE-2026-25592, Microsoft Semantic Kernel | Przykład podatności agent framework, gdzie problemem jest nie tylko tekst, ale zaufanie do parametrów i narzędzi dostępnych modelowi.                                      | FACT     |
| EchoLeak / Microsoft 365 Copilot          | Przykład produkcyjnego zero-click prompt injection opisywanego jako naruszenie granic zaufania między zewnętrzną treścią, kontekstem przedsiębiorstwa i przepływem danych. | LIKELY   |
| Ogólne podatności MCP/coding agents       | Podobieństwo dotyczy tool poisoning, context poisoning i niekontrolowanego wykonania przez agentów, ale każdy przypadek wymaga odrębnej walidacji.                         | POSSIBLE |

[FACT] Z punktu widzenia metodologii CVE, LLM Trust Boundary Collapse może być użyteczny jako język opisu przyczynowego, lecz nie zastępuje analizy produktu, wersji, ścieżki danych, sinka wykonawczego, uprawnień, konfiguracji i poprawek.

## 8. Falsyfikacja tezy

### Kontrargument 1: „To tylko rozszerzona prompt injection”

[FACT] To silny kontrargument. Wiele opisanych mechanizmów rzeczywiście mieści się w prompt injection, zwłaszcza wtedy, gdy istotą ataku jest doprowadzenie modelu do wykonania instrukcji zawartej w niezaufanej treści.

[LIKELY] Odpowiedź: LLM Trust Boundary Collapse nie musi być nową klasą konkurencyjną wobec prompt injection. Może być modelem wyższego poziomu, który pokazuje, dlaczego prompt injection staje się bardziej niebezpieczne w architekturach RAG, memory i tool-use. Innymi słowy, prompt injection jest techniką, a trust boundary collapse może być warunkiem architektonicznym zwiększającym jej skuteczność i skutek.

Ocena: kontrargument silny, ale nie obala użyteczności modelu.

### Kontrargument 2: „To nie nowa klasa, tylko suma istniejących klas”

[FACT] To również silny kontrargument. OWASP, MITRE ATLAS i CWE już opisują prompt injection, poisoning, excessive agency, output handling i błędy neutralizacji wejścia.

[LIKELY] Odpowiedź: model nie musi być taksonomią konkurencyjną. Jego wartość polega na integracji. W praktyce organizacyjnej problem polega często na tym, że zespoły osobno kontrolują RAG, osobno prompt, osobno narzędzia, osobno pamięć i osobno SOC. LLM Trust Boundary Collapse wskazuje, że ryzyko powstaje właśnie na styku tych warstw.

Ocena: kontrargument silny wobec twierdzenia o „nowej klasie”, słabszy wobec twierdzenia o „modelu interpretacyjnym”.

### Kontrargument 3: „Problem dotyczy implementacji, nie modeli”

[FACT] To częściowo prawda. Najcięższe skutki pojawiają się zwykle wtedy, gdy model zostaje podłączony do narzędzi, pamięci, RAG lub API bez odpowiednich bramek bezpieczeństwa.

[LIKELY] Odpowiedź: problem ma charakter hybrydowy. Sam model językowy ma ograniczoną separację semantyczną między danymi i instrukcjami, ale podatność bezpieczeństwa w sensie systemowym powstaje dopiero przez implementację: konstrukcję promptu, zaufanie do RAG, politykę narzędzi, brak sandboxingu, brak provenance i brak kontroli wykonania.

Ocena: kontrargument bardzo silny; powinien ograniczać zakres tezy.

### Kontrargument 4: „Klasyczne modele bezpieczeństwa już to opisują”

[FACT] Klasyczne modele opisują granice zaufania, confused deputy, injection, least privilege, separation of duties, access control i output validation.

[LIKELY] Odpowiedź: LLM Trust Boundary Collapse nie neguje klasycznych modeli, lecz pokazuje ich nowe miejsce zastosowania. Różnica polega na tym, że w systemach LLM granica danych i instrukcji bywa implementowana nie przez typy i parsery, lecz przez język naturalny, kontekst i embeddingi. To osłabia egzekwowalność granicy.

Ocena: kontrargument średnio silny; klasyczne modele są potrzebne, ale wymagają adaptacji do systemów agentowych.

### Kontrargument 5: „Brak formalnego CWE/CVE oznacza niedojrzałość tezy”

[FACT] Brak CVE nie obala modelu, ponieważ CVE dotyczy konkretnego produktu. Brak osobnego CWE mógłby wskazywać na niedojrzałość, ale obecność CWE-1427 wzmacnia tezę w zakresie separacji promptu i dyrektyw systemowych.

[LIKELY] Odpowiedź: model jest dojrzały jako hipoteza architektoniczna, lecz niedojrzały jako formalna kategoria taksonomiczna. Do uzyskania wyższego statusu potrzebne byłyby powtarzalne przypadki, testy porównawcze, definicje sinków, macierz preconditions i formalny opis relacji do istniejących CWE.

Ocena: kontrargument umiarkowany.

## 9. Model obrony

[FACT] Obrona przed LLM Trust Boundary Collapse nie może polegać wyłącznie na mocniejszym promptowaniu. Wymaga architektury, która traktuje model jako komponent zawodny i podatny na wpływ niezaufanej treści.

### 9.1. Separacja danych i instrukcji

[FACT] Dane zewnętrzne powinny być oznaczone jako dane, nie jako instrukcje. System powinien używać struktur, schematów i metadanych, które wymuszają rozróżnienie: kto mówi, z jakim autorytetem, z jakiego źródła pochodzi treść, czy treść może wpływać na cel, czy tylko na odpowiedź.

### 9.2. Signed instructions

[LIKELY] Instrukcje systemowe, polityki i reguły wykonania powinny mieć źródło i integralność. „Signed instruction” nie musi oznaczać wyłącznie podpisu kryptograficznego w każdym wdrożeniu, ale musi oznaczać mechanizm, w którym model nie może przyjąć nowej reguły wykonawczej z dokumentu, e-maila lub wyniku RAG bez bramki autoryzacyjnej.

### 9.3. Authority provenance

[LIKELY] System musi wiedzieć, czy dana informacja pochodzi od użytkownika, administratora, zewnętrznego dokumentu, bazy wiedzy, narzędzia, pamięci czy niezweryfikowanego źródła. Brak authority provenance powoduje C → A, czyli zamianę kontekstu w autorytet.

### 9.4. Decision provenance

[LIKELY] Każda istotna decyzja agenta powinna mieć ślad: jakie dane wpłynęły na decyzję, które źródła były zaufane, które były niezaufane, jakie narzędzie zostało wybrane i dlaczego. Bez decision provenance SOC i audyt nie są w stanie odróżnić normalnej decyzji od przejęcia ścieżki decyzyjnej.

### 9.5. Memory hygiene

[FACT] Pamięć nie powinna być automatycznie źródłem prawdy. Zapisy do pamięci powinny mieć politykę: co wolno zapamiętać, kto może zmienić regułę, jak oznaczyć źródło, jak wygasić informację, jak cofnąć zatrucie pamięci i jak wykryć reguły pochodzące z niezaufanego wejścia.

### 9.6. RAG source labeling

[FACT] Każdy fragment pobrany z RAG powinien mieć etykiety: źródło, data, właściciel, poziom zaufania, zakres użycia, typ treści i dopuszczalny wpływ na decyzję. RAG bez etykietowania źródeł zamienia bazę wiedzy w kanał potencjalnego sterowania modelem.

### 9.7. Tool-use policy gates

[FACT] Wywołanie narzędzia powinno przechodzić przez deterministyczną bramkę polityki. Model może proponować działanie, ale polityka powinna decydować, czy działanie jest dopuszczalne. Szczególnie ważne są operacje zapisu, usuwania, wysyłki, wykonania kodu, zmiany konfiguracji, dostępu do sekretów i działań finansowych.

### 9.8. Sandboxing i least privilege

[FACT] Narzędzia dostępne agentowi powinny działać w minimalnym zakresie uprawnień. Jeżeli agent przetwarza dane od niezaufanej strony, jego uprawnienia powinny spaść do poziomu tej strony. To praktyczne przełożenie zasady least privilege na systemy LLM.

### 9.9. Human approval gates

[FACT] Dla działań wysokiego ryzyka wymagane powinno być zatwierdzenie człowieka. Nie chodzi o pozorny przycisk „OK”, lecz o zatwierdzenie z widocznym uzasadnieniem: źródła, dane wejściowe, planowane narzędzie, parametry, skutki i ryzyko.

### 9.10. Output validation

[FACT] Wyjście modelu nie powinno być traktowane jako bezpieczne tylko dlatego, że pochodzi z modelu. Jeżeli trafia do kodu, interpretera, API, SQL, systemu plików, pipeline’u CI/CD albo narzędzia administracyjnego, musi być walidowane tak jak wejście zewnętrzne.

### 9.11. LBOM jako Label/Logic Bill of Materials

[LIKELY] LBOM można zdefiniować jako warstwę inwentaryzacji logiki i etykiet zaufania w systemie LLM. SBOM mówi, jakie komponenty programowe są w systemie. LBOM powinien mówić, jakie źródła danych, etykiety zaufania, reguły decyzyjne, pamięci, narzędzia, role i przejścia semantyczne tworzą łańcuch działania agenta.

Minimalny LBOM powinien zawierać:

| Element       | Pytanie kontrolne                                       |
| ------------- | ------------------------------------------------------- |
| Źródła danych | Skąd pochodzi treść i jaki ma poziom zaufania?          |
| Instrukcje    | Kto może zmienić reguły działania?                      |
| Kontekst      | Co jest tylko kontekstem, a co może wpływać na decyzję? |
| Autorytet     | Jaki aktor nadaje uprawnienie?                          |
| Pamięć        | Co wolno utrwalić i jak to wycofać?                     |
| Narzędzia     | Jakie akcje może wykonać agent?                         |
| Decyzje       | Jak audytować przejście od odpowiedzi do działania?     |

### 9.12. Audyt granic zaufania

[FACT] Organizacje powinny audytować nie tylko model, ale przejścia między warstwami: dane → prompt, RAG → kontekst, pamięć → decyzja, odpowiedź → narzędzie, narzędzie → wykonanie, wykonanie → log. To tam najczęściej pojawia się realne ryzyko.

## 10. Implikacje dla organizacji

### CISO

[FACT] Dla CISO kluczowy wniosek brzmi: LLM nie jest samodzielną granicą bezpieczeństwa. Jeżeli model ma dostęp do danych i narzędzi, zakres skutku ataku jest równy zakresowi narzędzi, do których model może pośrednio wpływać. Program bezpieczeństwa powinien więc obejmować threat modeling agentów, kontrolę uprawnień, polityki tool-use, audyt decyzji i incident response dla AI.

### Architekci bezpieczeństwa

[LIKELY] Architekci powinni projektować LLM jako komponent w zerotrustowej architekturze sterowania, nie jako zaufany mózg systemu. Najważniejsze wzorce to separacja warstw, provenance, signed instructions, policy-as-code, izolacja narzędzi, redukcja uprawnień zależna od źródła danych i jawne ścieżki zatwierdzenia.

### SOC

[LIKELY] SOC musi nauczyć się wykrywać nie tylko IOC, ale również anomalie decyzyjne: nietypowe wywołania narzędzi, zmianę celu agenta, odwołania do niezaufanych źródeł, nienaturalne zapisy do pamięci, nieoczekiwane sekwencje RAG → tool call i działania ukryte za poprawną odpowiedzią użytkownikowi.

### AI governance

[FACT] AI governance powinien obejmować nie tylko politykę użycia modeli, lecz także rejestr zastosowań, klasyfikację ryzyka, dane wejściowe, pamięć, narzędzia, przepływy decyzyjne, właścicieli odpowiedzialności i procedury wyłączenia agenta.

### DevSecOps

[LIKELY] Dla DevSecOps oznacza to konieczność rozszerzenia pipeline’u o testy prompt injection, testy RAG poisoning, walidację narzędzi, scanning konfiguracji agentów, testy permission boundary, symulacje indirect injection i analizę ścieżki od model output do execution sink.

### Dostawcy copilots

[FACT] Dostawcy copilots muszą traktować repozytoria, dokumenty, pull requesty, issue, komentarze, e-maile i wyniki wyszukiwania jako potencjalnie niezaufane dane sterujące. Copilot z dostępem do kodu, terminala, IDE lub systemu plików powinien mieć silniejsze bramki niż chatbot bez narzędzi.

### Organizacje publiczne

[FACT] W administracji publicznej i sektorze regulowanym ryzyko jest wyższe ze względu na dane wrażliwe, obowiązki audytowe, odpowiedzialność proceduralną i możliwość wpływu na decyzje administracyjne. System LLM wspierający urzędnika nie może zamieniać kontekstu w autorytet ani pamięci w źródło prawa.

## 11. Wnioski

[FACT] Pewne jest, że prompt injection i jego warianty są uznanym ryzykiem aplikacji LLM. Pewne jest również, że CVE nie przysługuje heurystyce, lecz konkretnym podatnościom w produktach. Pewne jest wreszcie, że istnieją formalne pozycje OWASP i CWE opisujące istotne fragmenty problemu.

[LIKELY] Prawdopodobne jest, że LLM Trust Boundary Collapse stanowi użyteczny model interpretacyjny dla wielu ryzyk agentowych, ponieważ scala prompt injection, RAG injection, memory poisoning, tool misuse i excessive agency w jeden język architektoniczny: język granic zaufania.

[POSSIBLE] Możliwe jest, że w przyszłości podobny model zostanie rozwinięty jako formalna klasa ryzyka lub profil kontrolny dla agentic AI security, zwłaszcza jeżeli praktyka CVE/CWE będzie dalej adaptowana do systemów LLM.

[SPECULATIVE] Spekulacyjne byłoby twierdzenie, że LLM Trust Boundary Collapse jest nową, samodzielną rodziną exploitów albo że autorska heurystyka sama w sobie ma status podatności. Tego nie da się dziś udowodnić bez zbioru przypadków, formalnej metodologii testowej, precyzyjnych kryteriów odróżnienia od istniejących klas i niezależnej walidacji.

Najbezpieczniejsza konkluzja brzmi: LLM Trust Boundary Collapse jest kandydatem na warstwę wyjaśniającą i narzędzie architektonicznego audytu systemów LLM. Nie zastępuje OWASP, MITRE ATLAS, CWE ani CVE, lecz może pomóc lepiej rozumieć, dlaczego te same systemy są jednocześnie podatne na prompt injection, RAG poisoning, memory drift, nadmierną agencję i niekontrolowane wykonanie.

## 12. Bibliografia

OWASP GenAI Security Project. OWASP Top 10 for LLM Applications 2025.

OWASP Cheat Sheet Series. LLM Prompt Injection Prevention Cheat Sheet.

MITRE. ATLAS: Adversarial Threat Landscape for Artificial-Intelligence Systems.

NIST. Artificial Intelligence Risk Management Framework 1.0.

NIST. Artificial Intelligence Risk Management Framework: Generative Artificial Intelligence Profile, NIST AI 600-1.

CVE Program. CVE Record Format and CVE Program Documentation.

MITRE CWE. CWE-1427: Improper Neutralization of Input Used for LLM Prompting.

MITRE CWE. CWE-1426: Improper Validation of Generative AI Output.

MITRE CWE. CWE-20: Improper Input Validation.

MITRE CWE. CWE-74: Improper Neutralization of Special Elements in Output Used by a Downstream Component.

MITRE CWE. CWE-94: Improper Control of Generation of Code.

NCSC. Prompt injection is not SQL injection (it may be worse).

Microsoft Security Blog. When prompts become shells: RCE vulnerabilities in AI agent frameworks.

JFrog Security Research. When Prompts Go Rogue: Analyzing a Prompt Injection Code Execution in Vanna.AI.

Research literature on indirect prompt injection, RAG poisoning, agentic AI security, provenance-aware decision auditing, prompt injection defenses and software supply-chain security.

## 13. Krótka tabela statusu twierdzeń

| Twierdzenie                                                                                    | Status               | Uzasadnienie                                                                                                             |
| ---------------------------------------------------------------------------------------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| LLM Trust Boundary Collapse jest CVE.                                                          | ODRZUCONE / FACT     | CVE dotyczy konkretnej podatności w produkcie, nie heurystyki.                                                           |
| LLM Trust Boundary Collapse może być modelem interpretacyjnym.                                 | LIKELY               | Spójnie wyjaśnia wspólny mechanizm kilku klas ryzyka LLM.                                                                |
| Rdzeniem problemu jest brak separacji danych i instrukcji.                                     | FACT                 | Potwierdzają to OWASP, NCSC i CWE-1427.                                                                                  |
| Prompt injection, RAG injection i memory poisoning mogą mieć wspólną warstwę architektoniczną. | LIKELY               | Wszystkie mogą wynikać z błędnego przejścia między danymi, kontekstem, pamięcią i instrukcją.                            |
| Każdy przypadek prompt injection jest trust boundary collapse.                                 | ODRZUCONE / POSSIBLE | Nie każdy przypadek wymaga załamania pełnej granicy danych, autorytetu, pamięci i wykonania.                             |
| Największy wzrost ryzyka pojawia się przy narzędziach agentowych.                              | FACT                 | Połączenie LLM z narzędziami zmienia błąd tekstowy w potencjalny błąd wykonawczy.                                        |
| CWE-1427 jest najbliższym formalnym mapowaniem.                                                | FACT                 | CWE-1427 opisuje problem nierozróżnienia danych zewnętrznych od dyrektyw systemowych w promptach.                        |
| CWE-94 można stosować zawsze przy prompt injection.                                            | ODRZUCONE / FACT     | CWE-94 ma sens tylko wtedy, gdy dochodzi do generowania lub wykonania kodu przez podatny komponent.                      |
| OWASP LLM Top 10 zostaje zastąpiony przez ten model.                                           | ODRZUCONE / FACT     | Model jest warstwą interpretacyjną, nie konkurencyjną taksonomią.                                                        |
| LBOM może pomóc w audycie granic zaufania.                                                     | LIKELY               | Uzupełnia SBOM o logikę, etykiety, źródła, pamięć, narzędzia i decyzje.                                                  |
| Pełna eliminacja prompt injection jest obecnie realistyczna.                                   | ODRZUCONE / LIKELY   | Aktualne źródła wskazują raczej na redukcję prawdopodobieństwa i skutku niż całkowite usunięcie ryzyka.                  |
| Teza wymaga dalszej walidacji eksperymentalnej.                                                | FACT                 | Aby stała się formalną klasą ryzyka, potrzebuje testów, zbioru przypadków i kryteriów rozróżnienia od istniejących klas. |
