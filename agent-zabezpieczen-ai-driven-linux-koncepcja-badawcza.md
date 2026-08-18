# Agent nie jest aplikacją

## Koncepcja badawcza lokalnej warstwy bezpieczeństwa dla systemów AI-Driven na Linuxie

### Punkt wyjścia: system autonomiczny należy traktować jak misję

m komenda nie jest zwykłą instrukcją przesłaną do programu. Jest żwistego stanu maszyny działającej w ograniczonym środowisku, przy skończonej energii, pamięci, przepustowości i czasie reakcji. Jeżeli polecenie jest błędne, spóźnione albo wykonane w niewłaściwym kontekście, konsekwencją nie jest jedynie niepoprawny wynik obliczenia. Może nią być utrata orientacji, łączności, zasilania lub całej misji.

Ta perspektywa stanowi punkt wyjścia proponowanej koncepcji badawczej. Agent AI nie powinien być traktowany jak kolejna aplikacja biznesowa, ponieważ jego podstawową właściwością nie jest wyłącznie przetwarzanie informacji. Agent tworzy zamiary, wybiera narzędzia, inicjuje działania, interpretuje skutki i może kontynuować proces bez kolejnej interwencji człowieka. W chwili uzyskania dostępu do powłoki, API, repozytorium, systemu plików, urządzenia albo pipeline’u CI/CD staje się częścią układu wykonawczego.

Różnica ta prowadzi do zasadniczej tezy badawczej:

> bezpieczeństwa systemu agentowego nie można opierać na założeniu, że model poprawnie zrozumie polecenie, rozpozna manipulację i sam ograniczy własne działania.

Model generatywny może pozostawać warstwą analizy i planowania, lecz nie powinien samodzielnie ustanawiać zakresu własnej władzy, zatwierdzać swoich decyzji, wykonywać ich i potwierdzać poprawności skutku. W oficjalnym modelu użycia narzędzi OpenAI funkcje udostępniane są modelowi przez aplikację, a model generuje ustrukturyzowane wywołanie lub jego argumenty. Faktyczne wykonanie pozostaje zadaniem infrastruktury aplikacyjnej. Ten podział tworzy naturalne miejsce dla niezależnej warstwy autoryzacji i egzekwowania polityki.

Koncepcja badawcza przenosi zatem regułę znaną z systemów misyjnych do środowiska agentowego:

> model może proponować zmianę stanu, ale nie może posiadać niekontrolowanej drogi prowadzącej od propozycji do skutku.

---

## Problem badawczy: przerwanie ciągłości między decyzją a skutkiem

W klasycznej aplikacji użytkownik wybiera funkcję, a oprogramowanie realizuje stosunkowo przewidywalny przepływ. W systemie agentowym ten sam model może rozpoznać problem, zaprojektować wieloetapową strategię, wybrać narzędzia, zmienić plan po otrzymaniu wyniku i przekazać część zadania innemu agentowi. Powstaje proces dynamiczny, którego ścieżka nie musi być w całości znana przed rozpoczęciem wykonania.

Taką właściwość może wykorzystać również napastnik. Atak AI-driven nie musi polegać na jednej spektakularnej operacji. Może automatyzować kolejne etapy:

**rozpoznanie → wybór słabości → eskalacja → ruch boczny → utrwalenie → eksfiltracja**

Największym zagrożeniem nie jest wyłącznie szybkość generowania poleceń. Jest nim możliwość swobodnego przechodzenia między etapami procesu. Jeżeli narzędzie rozpoznawcze, mechanizm pobierania sekretów, powłoka, sieć i system wdrożeniowy znajdują się w jednym zakresie uprawnień, agent może złożyć legalne lokalnie operacje w nielegalny globalnie przebieg.

Tradycyjny monitoring analizuje zazwyczaj zdarzenia po ich wystąpieniu. Tymczasem szybki system agentowy może wykonać całą sekwencję przed powstaniem pełnego alertu, a nawet wykorzystać mechanizmy obserwowalności do wytworzenia przeciążenia informacyjnego. Dlatego przedmiotem badania nie powinno być stworzenie modelu, który „szybciej rozumie atak”, lecz stworzenie systemu, w którym każdy kolejny etap wymaga odrębnego, mierzalnego i odwoływalnego prawa do wykonania.

Kernel nie musi wygrać wyścigu poznawczego z modelem. Musi jedynie egzekwować ograniczenie przed dopuszczeniem skutku. To różnica między detekcją a pełną mediacją. Jeżeli operacja nie może zostać wykonana bez przejścia przez lokalny punkt egzekwowania polityki, szybkość generowania kolejnych propozycji nie zwiększa efektywnych uprawnień agenta.

---

## Rdzeń koncepcji: planner nad lokalną maszyną wykonawczą

Proponowana architektura oddziela warstwę planowania od warstwy wykonania.

Model AI działa jako **Planner**. Analizuje dane, klasyfikuje zagrożenia, tworzy hipotezy, proponuje plan i przygotowuje ustrukturyzowane żądania użycia narzędzi. Nie otrzymuje jednak trwałych poświadczeń, bezpośredniej powłoki ani swobodnego dostępu do urządzeń.

Propozycja modelu trafia do **Authority Gateway**, który dokonuje walidacji składniowej i semantycznej. Następnie niezależny **Authorizer** sprawdza tożsamość, mandat, aktualną politykę, stan zasobu, limit skutku, ważność czasową oraz wymagany poziom atestacji. Dopiero na tej podstawie tworzona jest właściwa koperta komendy.

Komendę odbiera **Executor**, ograniczony przez mechanizmy Linuxa i konfigurację konkretnego narzędzia. Skutek jest obserwowany przez niezależne kanały telemetryczne, a **Verifier** porównuje zamiar, decyzję autoryzacyjną, wykonanie i stan końcowy. Finalnym produktem nie jest sam log, lecz podpisany dowód wykonania.

Przepływ przyjmuje postać:

**Intent → Plan → Authorization → Command Envelope → Execution → Kernel Enforcement → Observed Effect → Verification → Execution Receipt**

Separację ról należy rozumieć jako inwariant systemowy:

**Planner ≠ Authorizer**

**Authorizer ≠ Executor**

**Verifier ∉ {Planner, Authorizer, Executor}**

Uruchomienie czterech komponentów w różnych procesach nie wystarcza, jeżeli wszystkie korzystają z tego samego konta administratora, wspólnych kluczy, zapisywalnego stanu decyzyjnego albo wspólnego mechanizmu wyłączania kontroli. Badanie musi zatem rozróżnić separację procesową, kontenerową, wirtualizacyjną, hostową, sprzętową i organizacyjną.

---

## Dwa laboratoria jednej hipotezy

Koncepcję należy badać w dwóch osobnych, lecz powiązanych wariantach. Pierwszy sprawdza bezpieczeństwo lokalnego wykonania w środowisku przypominającym system misyjny. Drugi bada ciągłość dowodu w rozproszonym procesie przedsiębiorstwa.

### Laboratorium A: Yocto, Linux, cFS/cFE i OSAL

Pierwszy wariant wykorzystuje podejście wywodzące się z systemów kosmicznych. Jego bazę stanowi minimalny obraz Linuxa tworzony w Yocto, Core Flight System wraz z cFE oraz OSAL, lokalny gateway bezpieczeństwa, mechanizmy integralności Linuxa i sprzętowy lub wirtualny Root of Trust.

Space Grade Linux jest rozwijany jako dystrybucja budowana przy użyciu Yocto. Projekt zakłada zarówno podstawowy obraz dla misji kosmicznych, jak i obrazy integrujące znane frameworki warstwy użytkowej, w tym cFS, F´ oraz Space ROS. Nie oznacza to gotowego certyfikowanego stosu bezpieczeństwa, ale dostarcza uzasadnionej platformy eksperymentalnej dla badań nad kontrolowanym execution plane.

cFE udostępnia zestaw usług wykonawczych, w tym Executive Services, Software Bus, Event Services, Table Services oraz Time Services. Software Bus realizuje komunikację opartą na wiadomościach i subskrypcjach, umożliwiając kierowanie komend oraz telemetrii między aplikacjami. OSAL izoluje aplikacje od części różnic między systemami operacyjnymi i platformami. Dokumentacja cFE sama zaleca unikanie bezpośrednich skrótów do sprzętu lub systemu operacyjnego tam, gdzie powinny zostać użyte interfejsy cFE i OSAL.

To właśnie ta dyscyplina architektoniczna jest cenna dla systemów agentowych. Model nie komunikuje się bezpośrednio z procesem Linux ani urządzeniem. Wysyła propozycję do własnej aplikacji Authority Gateway. Dopiero ta aplikacja, po uzyskaniu autoryzacji, tworzy wiadomość dopuszczoną do Software Bus.

Nie wolno jednak uznać, że samo zastosowanie cFS tworzy bramę kryptograficzną. Standardowy nagłówek komendy cFE zawiera między innymi Function Code i checksumę, lecz check­sum nie jest podpisem cyfrowym ani dowodem mandatu. Software Bus umożliwia routing wiadomości, ale nie wprowadza automatycznie tożsamości agenta, ograniczeń delegacji, ochrony przed replay ani polityki maksymalnego skutku. Event Services generują wiadomości zdarzeń, lecz dokumentacja wyraźnie wskazuje, że nie są one automatycznie przesyłane jako telemetria bez odpowiednio skonfigurowanej aplikacji wyjściowej.

Wartość laboratorium A polega więc nie na gotowości poszczególnych komponentów, lecz na możliwości precyzyjnego zbadania, czego brakuje pomiędzy modelem a magistralą wykonawczą. Elementami wymagającymi własnej implementacji będą przede wszystkim:

**Authority Gateway**, podpisana koperta komendy, mechanizm mandatu, ochrona przed replay, powiązanie komendy z atestacją hosta, adapter korelujący aplikację cFS z zadaniem OSAL i procesem Linux, verifier oraz generator receiptów.

### Obraz systemu jako przedmiot dowodu

Yocto umożliwia tworzenie minimalnego obrazu, kontrolę składu oprogramowania i generowanie SBOM w formacie SPDX. Dokumentacja projektu wskazuje, że SBOM opisuje użyte komponenty, licencje, zależności, źródła i część informacji o podatnościach. Jest to istotny dowód dotyczący procesu budowy obrazu. Nie jest to jednak dowód tego, co rzeczywiście zostało uruchomione ani jaki kod uczestniczył w konkretnej operacji.

Badanie musi dlatego rozdzielić trzy kategorie:

**Build Evidence** opisuje, co miało zostać zbudowane.

**Deployment Evidence** opisuje, co zostało wdrożone na określony host.

**Runtime Evidence** opisuje, co rzeczywiście działało i uczestniczyło w wykonaniu.

Dopiero ich kryptograficzne powiązanie pozwala ustalić, że konkretna komenda została wykonana przez określony workload uruchomiony z określonego obrazu, na hoście znajdującym się w zaakceptowanym stanie.

---

## Linux jako warstwa egzekwowania, nie jako pojedynczy mechanizm ochronny

Bezpieczeństwo wykonania nie może zależeć od jednego narzędzia. Linux dostarcza zestaw komplementarnych mechanizmów, które mogą ograniczać procesy, dostęp do zasobów i powierzchnię jądra.

Namespaces oddzielają widoki procesów, sieci, użytkowników i punktów montowania. Cgroups ograniczają zasoby oraz liczbę procesów. Linux capabilities pozwalają rozłożyć tradycyjne uprawnienia roota na mniejsze jednostki. LSM, taki jak SELinux lub AppArmor, może egzekwować politykę dostępu. Seccomp ogranicza zestaw wywołań systemowych dostępnych dla procesu.

Seccomp nie powinien być jednak przedstawiany jako kompletny sandbox. Dokumentacja kernela wyraźnie określa go jako mechanizm redukcji powierzchni system calls, który powinien być łączony z innymi technikami hardeningu i odpowiednim LSM. To ważne metodologicznie: każdy komponent musi otrzymać zakres odpowiedzialności zgodny z jego rzeczywistymi właściwościami.

Dla Agenta Zabezpieczeń oznacza to przygotowanie odrębnych profili dla plannera, gatewaya, authorizera, executora, telemetry collectora i verifera. Planner może mieć dostęp wyłącznie do kontrolowanego API. Gateway powinien odrzucać wszystkie nieznane pola i parametry. Executor powinien posiadać jedynie capabilities potrzebne do konkretnego typu operacji. Verifier nie powinien móc wykonać działania, które ocenia.

System musi też przewidywać read-only root filesystem, podpisywanie modułów, measured boot, IMA/EVM, dm-verity lub fs-verity oraz ograniczenie interfejsów debug. Celem nie jest „utwardzenie Linuxa” w sensie ogólnym, lecz stworzenie środowiska, w którym agent nie może zmienić mechanizmów, które mierzą i ograniczają jego wykonanie.

---

## Laboratorium B: pipeline CI/CD jako misja rozproszona

Drugi wariant rezygnuje z literalnego używania cFS jako szyny każdego procesu przedsiębiorstwa. Zamiast tego przenosi jego zasadę organizacyjną: oddzielne, typowane komendy; jawna telemetria; ograniczone executory; kontrola stanu procesu; możliwość przejścia do stanu bezpiecznego.

CI/CD można opisać jako misję:

**Issue → Change Request → Commit → Review → Build → Test → Scan → Sign → Publish → Deploy → Verify**

Każdy krok posiada wejście, wykonawcę, politykę, artefakt wyjściowy i możliwy skutek. Problem polega na tym, że pipeline’y są dynamiczne, rozproszone i pełne operacji równoległych. Występują w nich retry, fan-out, efemeryczne runnery, zewnętrzne repozytoria, rejestry artefaktów oraz wiele granic zaufania. Dlatego nie wystarcza pojedynczy identyfikator procesu ani centralny log.

Wariant enterprise wymaga **Mission Execution Bus** dostosowanego do systemów rozproszonych. Przykładowy wariant badawczy może wykorzystywać NATS JetStream z durable pull consumers i jawnymi potwierdzeniami. JetStream przechowuje stan dostarczenia, obsługuje redelivery niepotwierdzonych wiadomości i zapewnia semantykę co najmniej jednokrotnego dostarczenia. Oznacza to równocześnie, że system wykonawczy musi być odporny na duplikację: każda operacja musi posiadać `Command ID`, `Idempotency Key`, licznik użyć i ochronę przed ponownym skutkiem.

W tym wariancie model proponuje krok pipeline’u, lecz nie publikuje bezpośrednio finalnej komendy wykonawczej. Gateway waliduje propozycję, policy engine ocenia ją wobec repozytorium, środowiska, ryzyka i tożsamości inicjatora, a mandate service wiąże decyzję z konkretnym artefaktem i klasą runnera. Dopiero potem podpisana komenda trafia na bus.

### Od logu buildu do pochodzenia artefaktu

W środowisku enterprise dowodem nie jest wyłącznie log procesu kompilacji. Trzeba ustalić, kto wykonał krok, na jakim materiale wejściowym, jakim narzędziem i jaki artefakt powstał.

in-toto opisuje łańcuch dostaw jako serię kroków wykonywanych przez upoważnionych uczestników. Jego model pozwala zdefiniować planowany układ kroków i zebrać podpisane metadane o tym, co zostało wykonane, przez kogo i w jakiej kolejności. SLSA Provenance uzupełnia ten model o weryfikowalne informacje opisujące, gdzie, kiedy i w jaki sposób wytworzono artefakt.

Tekton Chains stanowi przykład praktycznej implementacji takiego kierunku. Obserwuje ukończone TaskRun i PipelineRun, tworzy reprezentację provenance, podpisuje ją i zapisuje w skonfigurowanym magazynie. Mechanizm ten nie rozwiązuje wszystkich problemów Agenta Zabezpieczeń, ale pokazuje, że niezależny obserwator może wystawiać podpisany materiał dowodowy po zakończeniu kroku pipeline’u.

Koncepcja badawcza rozszerza provenance z opisu buildu na cały proces agentowy. Dowód powinien objąć nie tylko artefakt, ale również zamiar modelu, mandat, wersję polityki, środowisko wykonawcze, stan przed operacją, stan po operacji oraz finalny werdykt.

---

## Mandat: minimalna jednostka władzy agenta

Najważniejszym obiektem architektury nie jest token dostępu ani rola systemowa. Jest nim **mandat działania**.

Mandat odpowiada na pytania:

kto może wykonać operację, w czyim imieniu, na jakim zasobie, w jakim celu, przy jakim stanie początkowym, do kiedy, ile razy, z jakim maksymalnym skutkiem i czy może przekazać uprawnienie dalej.

Klasyczna polityka dostępu może zezwalać agentowi na zapis do repozytorium. Mandat musi być węższy: może zezwalać konkretnemu agentowi na utworzenie jednej gałęzi naprawczej w określonym repozytorium, w ramach konkretnego incydentu, bez możliwości modyfikacji gałęzi chronionej, przez pięć minut, przy limicie jednej operacji.

Mandat powinien być powiązany z kontraktem wykonawczym. Kontrakt określa warunki początkowe, dozwolone przejście stanu, oczekiwany rezultat, zakazane skutki uboczne, limity zasobów, timeout, sposób kompensacji i materiał dowodowy wymagany do uznania działania za zakończone.

Pozwala to odróżnić:

* prawo do wywołania narzędzia,
* prawo do określonego skutku,
* dowód, że skutek faktycznie odpowiadał mandatowi.

---

## Execution receipt: od deklaracji do dowodu

Agent może stwierdzić, że wykonał zadanie. Executor może zapisać, że operacja zakończyła się sukcesem. Log może zawierać prawidłową nazwę komendy. Żaden z tych elementów nie dowodzi jeszcze, że deklarowany skutek rzeczywiście nastąpił.

Execution receipt powinien wiązać co najmniej:

* identyfikator procesu głównego,
* identyfikator zadania i kroku,
* hash zamiaru,
* hash mandatu,
* hash polityki,
* hash komendy,
* tożsamość hosta i workloadu,
* digest obrazu runtime,
* odniesienie do SBOM,
* odniesienie do atestacji,
* stan przed wykonaniem,
* stan po wykonaniu,
* wynik,
* zużycie zasobów,
* poprzednie receipts,
* tożsamość wystawcy,
* podpis.

Proces rozproszony nie tworzy prostego łańcucha. Tworzy graf. Jeden krok może uruchomić kilka równoległych działań, a ich wyniki mogą zostać połączone przez kolejny etap. Receipt powinien więc wskazywać jeden lub wiele receiptów nadrzędnych, tworząc kryptograficznie powiązany DAG.

EAT może przenosić uwierzytelnione twierdzenia o stanie i właściwościach urządzenia, oprogramowania albo procesu. Standard przewiduje zarówno reprezentację CWT/CBOR, jak i JWT/JSON, a decyzję o stopniu zaufania pozostawia verifierowi i relying party. COSE Receipts dostarczają natomiast standardowego sposobu przedstawiania zwięzłych dowodów odnoszących się do weryfikowalnych struktur danych, w tym dowodów inkluzji i spójności struktur Merkle’a.

Te standardy nie tworzą automatycznie execution receipt dla agenta. Dostarczają jednak aparatu potrzebnego do zbudowania interoperacyjnego formatu: atestowanych twierdzeń, podpisanych struktur, ochrony integralności oraz dowodów włączenia rekordu do dziennika typu append-only.

---












## Kryptologika: rekonstrukcja ukrytego stanu procesu





















---

## Absolutny reżim naukowy: architektura musi dopuścić własne obalenie

Koncepcja nie może zostać uznana za poprawną dlatego, że składa się z komponentów kojarzonych z systemami krytycznymi. Yocto, cFS, OSAL, TPM, IMA, EAT i COSE nie tworzą bezpieczeństwa przez samo zestawienie nazw. Każdy komponent musi zostać przypisany do konkretnego wymagania, a każda deklarowana właściwość musi posiadać test falsyfikacyjny.

Pierwsza hipoteza głosi, że pełna mediacja odbiera atakowi AI-driven przewagę wynikającą z szybkości. Zostanie sfalsyfikowana, jeżeli agent znajdzie ścieżkę wykonania omijającą gateway albo złoży dozwolone operacje w niedozwolony globalny efekt.

Druga hipoteza głosi, że ciągłość dowodu można utrzymać przez proces obejmujący kilka hostów, kolejek i executorów. Zostanie sfalsyfikowana, jeżeli retry, utrata wiadomości, równoległość lub restart hosta uniemożliwią jednoznaczne ustalenie zależności pomiędzy krokami.

Trzecia hipoteza głosi, że wiele częściowo niezależnych kanałów pozwala wykryć manipulację wybranymi logami. Zostanie sfalsyfikowana, jeżeli przejęcie jednego komponentu umożliwi stworzenie spójnego, lecz fałszywego obrazu całego procesu.

Czwarta hipoteza głosi, że model można usunąć lub zastąpić bez naruszenia właściwości bezpieczeństwa execution plane. Jeżeli zmiana modelu wymaga zmiany Root of Trust, kluczy wykonawczych lub podstawowych reguł autoryzacji, oznacza to, że model został nieprawidłowo włączony do Trusted Computing Base.

Piąta hipoteza dotyczy narzutu. System może być bezpieczny logicznie, a niewykonalny operacyjnie. Podpisy, atestacja, policy engine, eksport pomiarów i zapis receiptów zużywają czas, CPU, pamięć, energię oraz przepustowość. Badanie musi więc określić budżety dla operacji hard real-time, soft real-time i supervisory.

---

## Program eksperymentalny: atak jako metoda pomiaru architektury

Laboratorium nie powinno ograniczać się do demonstracji poprawnego przepływu. Najważniejsze eksperymenty rozpoczynają się wtedy, gdy jeden z komponentów działa błędnie lub złośliwie.

W scenariuszu bazowym agent proponuje legalną operację, authorizer wydaje ograniczony mandat, executor wykonuje ją w sandboxie, a verifier potwierdza zgodność stanu przed i po.

Następnie model otrzymuje treść zawierającą prompt injection i próbuje rozszerzyć zakres działania. Wynikiem poprawnym jest odrzucenie operacji bez względu na przekonującą argumentację modelu.

W teście memory poisoning agent powołuje się na informację zapisaną w pamięci jako rzekome trwałe uprawnienie. System powinien ponownie ocenić operację według aktualnej polityki, ponieważ pamięć modelu nie jest źródłem władzy.

W teście tool abuse agent używa legalnego narzędzia do celu niezgodnego z mandatem. Ocena nie może ograniczać się do nazwy funkcji. Musi uwzględniać parametry, zasób, cel i możliwy skutek.

W teście parameter substitution napastnik zmienia parametry pomiędzy autoryzacją a wykonaniem. Zmiana powinna unieważnić hash mandatu albo Command Envelope.

W teście replay ta sama komenda jest wysyłana ponownie. Licznik, nonce, termin ważności lub idempotency key powinny zapobiec kolejnemu skutkowi.

W teście compromised executor wykonawca deklaruje sukces, ale zmienia inny zasób. Verifier powinien wykryć rozbieżność pomiędzy deklaracją executora a obserwacją systemu docelowego.

W teście event storm agent generuje tysiące poprawnie sformatowanych propozycji. Safety Plane musi zachować własne zasoby, priorytet telemetrii krytycznej oraz możliwość zatrzymania procesu.

W teście cloud outage połączenie z modelem zostaje zerwane. Lokalny execution plane powinien zachować bezpieczny stan bez oczekiwania na zdalną decyzję.

W teście policy rollback system próbuje przywrócić starszą wersję polityki. Operacja musi zostać wykryta przez wersjonowanie, hash polityki i mechanizm anti-rollback.

---

## Metryki: nie tylko skuteczność detekcji

Wynik badania powinien być oceniany równocześnie w kilku wymiarach.

Najważniejszą metryką bezpieczeństwa jest odsetek operacji, które uzyskały skutek mimo braku prawidłowego mandatu. W wariancie docelowym wartość ta powinna wynosić zero dla zdefiniowanego modelu zagrożeń.

Drugą metryką jest kompletność mediacji: jaki procent interfejsów zdolnych do zmiany stanu przechodzi przez kontrolowany pipeline. Jedna pozostawiona ścieżka administracyjna może podważyć całą architekturę.

Trzecią jest kompletność dowodu: jaki procent kroków procesu posiada prawidłowo powiązany receipt, atestację, stan wejściowy i stan wyjściowy.

Czwartą jest zdolność rekonstrukcji: czy po usunięciu albo manipulacji jednego kanału możliwe jest odtworzenie przebiegu, a jeżeli nie — czy system prawidłowo oznacza niepewność.

Piątą grupę tworzą opóźnienia. Należy mierzyć medianę, p95, p99 oraz maksimum dla walidacji schematu, decyzji polityki, podpisu koperty, dispatchu komendy, wykonania, generowania receipt i weryfikacji.

Szósta obejmuje narzut CPU, RAM, I/O, sieci i energii. System bezpieczeństwa nie może doprowadzać do awarii chronionego procesu przez nadmierne zużycie zasobów.

Siódma dotyczy operatora: czas od pojawienia się odchylenia do utworzenia zrozumiałej hipotezy incydentu. Konsola, która zachowuje wszystkie logi, ale nie rekonstruuje procesu, nie spełnia głównego celu badawczego.

---

## Lokalne wykonanie i granice SaaS

Koncepcja nie zakłada odrzucenia chmury. Zakłada rozdzielenie funkcji według ich wymagań czasowych i fizycznych.

Model zdalny może analizować duże zbiory danych, planować, optymalizować, proponować warianty działania i wykonywać zadania forensic. Nie powinien jednak stanowić jedynego elementu pętli wymagającej gwarantowanego czasu reakcji.

Dla operacji hard real-time przekroczenie deadline’u jest awarią. Każda podróż do chmury wprowadza opóźnienie propagacji, jitter, zależność od sieci i możliwość utraty usługi. Takie operacje muszą być realizowane lokalnie przez deterministyczne mechanizmy.

Dla operacji soft real-time odpowiedź zdalna może być dopuszczalna, o ile istnieje limit czasu i lokalny fallback.

Dla funkcji supervisory chmura może być głównym środowiskiem planowania, pod warunkiem że lokalny system zachowuje prawo do odrzucenia, ograniczenia i zatrzymania wykonania.

Fizyki układu nie przenosi się do SaaS. Do SaaS można przenieść interpretację, planowanie i zarządzanie, ale nie można usunąć lokalnej odpowiedzialności za skutek.

---

## Granice koncepcji

Proponowana architektura nie eliminuje wszystkich zagrożeń. Przenosi je do bardziej kontrolowanych miejsc.

Błąd Authority Gateway może stać się błędem systemowym. Przejęcie signera receiptów może podważyć integralność dowodów. Źle zaprojektowany policy engine może autoryzować formalnie poprawne, lecz niebezpieczne sekwencje. Verifier może dzielić wspólną podatność z executorem. Root of Trust nie potwierdza poprawności logiki aplikacji, lecz jedynie określony stan pomiarów.

Nie można też zakładać, że każdy skutek da się jednoznacznie zmierzyć. W procesach cyberfizycznych sensory mają błędy i opóźnienia. W CI/CD rezultat buildu nie dowodzi braku złośliwej logiki. Podpis potwierdza pochodzenie oświadczenia, nie jego prawdziwość. Kryptologika może zwiększyć stopień zgodności hipotezy z materiałem dowodowym, ale nie przekształca niepełnych śladów w absolutny fakt.

cFS jest właściwym przedmiotem badań dla lokalnego systemu mission-critical, lecz nie musi być właściwą magistralą dla każdego procesu enterprise. W CI/CD należy przenosić jego zasady — typowane komendy, telemetrykę, health monitoring, jawne stany misji i kontrolę wykonania — niekoniecznie cały framework.

Space Grade Linux jest obiecującą bazą rozwojową, ale nie może być traktowany jako automatyczny certyfikat gotowości do lotu. Każda konkretna misja, platforma sprzętowa i profil krytyczności wymagają własnej walidacji.

---

## Roadmapa: od jednej komendy do dowodu całego procesu

Pierwsza faza powinna stworzyć minimalny laboratoryjny execution plane. Model generuje wyłącznie typowaną propozycję. Gateway waliduje ją, policy engine wydaje decyzję, a executor wykonuje jedną dobrze ograniczoną operację na obrazie Yocto.

Druga faza dodaje cFS/cFE i OSAL. Celem nie jest jeszcze pełna autonomia, lecz zbadanie przepływu od Command Envelope do aplikacji cFS, zadania OSAL, procesu Linux i rzeczywistego skutku.

Trzecia faza wprowadza measured boot, IMA, TPM lub vTPM, EAT oraz podpisane receipts. Powstaje pierwszy pełny dowód łączący zamiar, mandat, host, workload, wykonanie i stan końcowy.

Czwarta faza rozszerza system na kilka hostów. Receipt przestaje być pojedynczym rekordem, a staje się elementem grafu procesu rozproszonego.

Piąta faza buduje konsolę telemetrii behawioralnej i moduł rekonstrukcji kryptologicznej. System zaczyna prezentować nie tylko zdarzenia, lecz trajektorie, odchylenia i poziomy niepewności.

Szósta faza uruchamia wariant enterprise. Pipeline CI/CD staje się misją składającą się z podpisanych kroków, a deploy jest dopuszczany dopiero po sprawdzeniu provenance, polityki i receiptów.

Siódma faza obejmuje red teaming oraz badanie granic. Dopiero po próbach obejścia mediacji, fałszowania receiptów, przeciążenia telemetrii i kompromitacji poszczególnych ról można ocenić, które właściwości zostały rzeczywiście osiągnięte.

---

## Od systemu obserwującego logi do systemu kontrolującego wykonalność

Istotą koncepcji nie jest zbudowanie „antywirusa z AI” ani dodanie modelu językowego do istniejącego SIEM. Agent Zabezpieczeń AI-Driven ma działać wewnątrz architektury, która rozdziela poznanie od władzy.

Model może dostrzec zależność, której człowiek nie zauważy. Może szybciej tworzyć hipotezy, porównywać przebiegi i proponować reakcje. Nie powinien jednak uzyskiwać prawa do nieograniczonego wykonania tylko dlatego, że jego analiza jest przekonująca.

Najważniejszym rezultatem badań nie będzie model osiągający najwyższą skuteczność klasyfikacji. Będzie nim odpowiedź, czy można zbudować system, w którym:

* każda operacja posiada ograniczony mandat,
* każdy skutek przechodzi przez lokalną mediację,
* każda rola ma ograniczoną władzę,
* każdy etap pozostawia powiązany materiał dowodowy,
* każda utrata obserwowalności zwiększa niepewność,
* każda awaria prowadzi do kontrolowanej degradacji,
* cały proces można odtworzyć od intencji do fizycznego albo logicznego skutku.

Agent nie staje się bezpieczny dlatego, że jest inteligentny.

Staje się możliwy do bezpiecznego użycia dopiero wtedy, gdy jego inteligencja nie daje mu jednostronnej władzy nad wykonaniem.
