# Deterministyczna obserwowalność warstwy wykonawczej jako szkielet epistemiczny probabilistycznych systemów AI

## Streszczenie

Dyskusja o udziale sztucznej inteligencji w tworzeniu systemów operacyjnych jest zwykle redukowana do pytania, czy AI powinna pisać kod. Tak sformułowany problem jest jednak poznawczo zbyt płytki. Autorstwo kodu nie jest podstawową granicą bezpieczeństwa systemu. Znacznie istotniejsze pozostaje to, które elementy systemu muszą zachować właściwości pozwalające człowiekowi oraz niezależnym mechanizmom kontrolnym obserwować, rekonstruować, weryfikować i ograniczać wykonanie.

W artykule przedstawiono tezę, zgodnie z którą system operacyjny może pełnić funkcję **deterministycznego szkieletu epistemicznego** dla probabilistycznego agenta AI. Agent zachowuje swobodę w zakresie percepcji, tworzenia hipotez, planowania i generowania rozwiązań, lecz każda próba materializacji zamiaru przechodzi przez warstwę wykonawczą opartą na twardych stanach systemowych, jawnych punktach kontroli i egzekwowalnych regułach. Celem tej warstwy nie jest wyjaśnienie całej wewnętrznej aktywności modelu, lecz zapewnienie, że jego rzeczywisty wpływ na system pozostaje obserwowalny i sankcjonowalny.

Proponowana koncepcja łączy teorię obserwowalności Rudolfa E. Kálmána, koncepcję monitora referencyjnego Jamesa P. Andersona, interpretację abstrakcyjną Patricka i Radhii Cousot, architekturę Simplex oraz rozwijaną przez NASA metodologię Runtime Assurance. Na poziomie implementacyjnym wykorzystuje właściwości Linuksa: wywołania systemowe, poświadczenia procesów, przestrzenie nazw, cgroups, seccomp, Linux Security Modules, BPF LSM, tracepoints, ftrace, audit oraz mechanizmy pomiaru integralności. W odniesieniu do autonomii wysokiej niezawodności koncepcję zestawiono z architekturami NASA core Flight System i F Prime.

**Słowa kluczowe:** sztuczna inteligencja, systemy agentowe, Linux, obserwowalność, Runtime Assurance, monitor referencyjny, eBPF, cFS, F Prime, bezpieczeństwo wykonania.

---

## 1. Błąd źle postawionego pytania

Pytanie „czy AI powinna pisać system operacyjny?” zakłada, że podstawowym problemem jest autor kodu. W konsekwencji próbuje rozdzielać kod napisany przez człowieka od kodu wygenerowanego przez model, jak gdyby samo pochodzenie implementacji przesądzało o jej bezpieczeństwie, przewidywalności lub poznawalności.

Tak nie jest. Kod napisany przez człowieka może być nieprzejrzysty, nieudokumentowany, podatny na błędy i praktycznie nieweryfikowalny. Kod wygenerowany automatycznie może natomiast zostać poddany analizie statycznej, testom, formalnej weryfikacji, ograniczeniu interfejsów i ścisłemu monitorowaniu wykonania. Autorstwo jest więc cechą procesu wytwarzania, a nie bezpośrednią właściwością bezpieczeństwa architektury.

W systemach autonomicznych właściwe pytanie brzmi:

> **Które składniki systemu muszą pozostać na tyle małe, stabilne, obserwowalne i formalnie ograniczone, aby można było na ich podstawie rozstrzygać, co agent rzeczywiście zrobił, jakie zasoby zmienił oraz czy jego działanie naruszyło dopuszczalną przestrzeń wykonania?**

NASA stosuje analogiczną zasadę w inżynierii oprogramowania krytycznego: wymagania, projekt, kod i testy mają pozostawać wzajemnie śledzalne, a automatycznie generowany kod oraz narzędzia wykorzystywane przy tworzeniu oprogramowania podlegają kwalifikacji i walidacji. Nie wynika z tego zakaz automatyzacji, lecz obowiązek zachowania dowodów zgodności między zamierzeniem, implementacją i wynikiem wykonania. ([Nodis3][1])

Proponowana tutaj granica nie przebiega zatem między człowiekiem i maszyną. Przebiega między:

**przestrzenią swobodnego wytwarzania hipotez** a **przestrzenią kontrolowanej materializacji skutków**.

---

## 2. Teza główna

**Probabilistyczny system AI może otrzymać znaczną autonomię poznawczą, o ile jego wpływ na środowisko jest realizowany przez deterministycznie rozstrzygalną, niezależnie obserwowaną i technicznie egzekwowalną warstwę wykonawczą.**

Warstwa ta nie musi rozumieć całego procesu rozumowania agenta. Nie musi również odtwarzać wewnętrznych aktywacji sieci neuronowej. Musi natomiast potrafić rozstrzygnąć, że określony proces:

* otworzył konkretny plik,
* użył konkretnych poświadczeń,
* utworzył połączenie sieciowe,
* zmienił konfigurację,
* uruchomił program,
* przydzielił zasób,
* przesłał dane,
* załadował kod,
* zmodyfikował stan urządzenia,
* wywołał określony skutek fizyczny albo systemowy.

Nie oznacza to pełnego determinizmu systemu operacyjnego. Współbieżność, przerwania, sterowniki, urządzenia, planowanie procesora, asynchroniczne wejścia i rozproszone źródła czasu powodują, że całe wykonanie Linuksa nie jest w sensie praktycznym jedną prostą funkcją deterministyczną. Postulowana właściwość jest węższa:

> **Dla każdego działania istotnego z punktu widzenia bezpieczeństwa musi istnieć skończony zestaw obserwowalnych zmiennych oraz predykat, który jednoznacznie rozstrzyga, czy działanie może zostać dopuszczone, zatrzymane, ograniczone lub przekazane do bezpiecznego kontrolera.**

Nie jest to więc „deterministyczna inteligencja”. Jest to **deterministyczna rozstrzygalność granicy wykonania**.

---

## 3. System operacyjny jako urządzenie epistemiczne

System operacyjny jest zwykle opisywany jako menedżer zasobów, platforma abstrakcji sprzętu albo środowisko uruchomieniowe programów. W przypadku systemów agentowych powinien zostać rozszerzony o jeszcze jedną funkcję: funkcję **urządzenia epistemicznego**.

Urządzenie epistemiczne nie musi poznawać intencji agenta w psychologicznym sensie. Dostarcza natomiast dowodów pozwalających stwierdzić, co rzeczywiście wydarzyło się w systemie. W tym ujęciu wywołanie systemowe, zmiana poświadczeń, deskryptor pliku, kontekst LSM, identyfikator przestrzeni nazw, przynależność do cgroup, stan połączenia, skrót wykonywalnego pliku i wpis audytowy nie są wyłącznie elementami technicznymi. Są **zmiennymi dowodowymi**.

Agent może twierdzić, że „tylko analizował konfigurację”. Warstwa wykonawcza może jednak wykazać, że proces potomny wywołał `execve`, otworzył plik konfiguracyjny z prawem zapisu, wykonał `rename`, ustanowił połączenie wychodzące oraz zmienił regułę zapory. Z perspektywy bezpieczeństwa to drugi opis jest rozstrzygający.

W ten sposób system operacyjny staje się aparaturą obserwacyjną umieszczoną **poniżej narracji modelu**. Nie pyta modelu, co zrobił. Rejestruje warunki konieczne do tego, aby działanie mogło zostać wykonane.

---

## 4. Podstawa pierwsza: obserwowalność Kálmána

W teorii sterowania obserwowalność oznacza możliwość rekonstrukcji istotnego stanu wewnętrznego systemu na podstawie jego wyjść. Koncepcję tę sformalizował Rudolf E. Kálmán. Klasyczna teoria dotyczy systemów dynamicznych, lecz jej zasadnicza intuicja pozostaje użyteczna także w systemach komputerowych: nie trzeba bezpośrednio widzieć każdej zmiennej wewnętrznej, jeżeli dostępne sygnały pozwalają odróżnić stany mające znaczenie dla sterowania. ([control.utoronto.ca][2])

Dla systemu agentowego nie jest konieczne odtworzenie wszystkich tokenów, aktywacji i reprezentacji ukrytych. Konieczne jest natomiast odróżnienie takich stanów wykonawczych jak:

* odczyt i modyfikacja,
* obserwacja i ingerencja,
* przygotowanie zamiaru i jego realizacja,
* operacja odwracalna i nieodwracalna,
* działanie w zakresie przyznanej kompetencji i przekroczenie kompetencji,
* błąd agenta i błąd mechanizmu obserwacyjnego.

Można to przedstawić jako problem obserwowalności względem bezpieczeństwa, a nie obserwowalności absolutnej.

Niech rzeczywisty stan systemu będzie opisany przez:

```text
x(t) ∈ X
```

a dostępne sygnały wykonawcze przez:

```text
y(t) = H(x(t))
```

Pełna obserwowalność wymagałaby rekonstrukcji całego `x(t)`. Dla systemu agentowego wystarczająca może być obserwowalność względem relacji bezpieczeństwa:

```text
x₁ ≁ₛ x₂  ⇒  H*(x₁) ≠ H*(x₂)
```

gdzie `≁ₛ` oznacza, że dwa stany różnią się w sposób istotny dla polityki bezpieczeństwa, a `H*` obejmuje sekwencję obserwacji w czasie.

System może więc nie odróżniać dwóch nieistotnych wariantów planowania wewnętrznego, lecz musi odróżnić operację tylko do odczytu od operacji prowadzącej do trwałej zmiany stanu.

---

## 5. Podstawa druga: monitor referencyjny Andersona

James P. Anderson sformułował klasyczną koncepcję monitora referencyjnego: mechanizmu pośredniczącego we wszystkich operacjach mających znaczenie dla bezpieczeństwa. Taki mechanizm powinien być odporny na manipulację, zawsze wywoływany oraz dostatecznie mały i uporządkowany, aby można go było poddać analizie. ([NIST Computer Security Resource Center][3])

W odniesieniu do AI zasada ta prowadzi do krytycznego wniosku:

> Agent nie może samodzielnie decydować, które jego działania podlegają kontroli.

Jeżeli model może ominąć monitor, wyłączyć telemetrię, zmodyfikować politykę albo wykonać tę samą operację alternatywną ścieżką, obserwowalność nie tworzy granicy bezpieczeństwa. Jest tylko diagnostyką dobrej woli.

Dlatego monitor wykonania musi znajdować się poniżej agenta albo w odseparowanej domenie zaufania. Agent może otrzymywać informację zwrotną z monitora, ale nie może dowolnie zmieniać jego kodu, polityki, kluczy, buforów zdarzeń ani zasad sankcjonowania.

Ostatecznie rozstrzygnięcie powinno być podejmowane nie przez model językowy, lecz przez mały predykat nad twardymi zmiennymi:

```text
ALLOW = P(subject, object, operation, context, provenance, system_state)
```

Wynik może być deterministyczny:

```text
P(...) ∈ {ALLOW, DENY, DEFER, REVERT}
```

Probabilistyczna ocena ryzyka może dostarczać jednego z wejść, ale krytyczna decyzja wykonawcza musi mieć określoną semantykę i egzekwowalny skutek.

---

## 6. Podstawa trzecia: abstrakcja, konkretyzacja i utrata przemienności

Terminami, których dotyczyła intuicja przejścia między probabilistyką i determinizmem, są przede wszystkim **abstrakcja** oraz **konkretyzacja**. W teorii interpretacji abstrakcyjnej opisują one relację między bogatą, konkretną przestrzenią stanów a uproszczoną domeną, w której można wykonywać analizę.

Patrick i Radhia Cousot rozwinęli interpretację abstrakcyjną jako formalną metodę bezpiecznego wnioskowania o programach. David Monniaux oraz późniejsze prace rozszerzyły ten aparat na semantyki probabilistyczne. ([www-verimag.imag.fr][4])

Niech:

```text
C
```

oznacza konkretną przestrzeń stanów systemowych, natomiast:

```text
A
```

domenę abstrakcyjną, w której operuje agent albo analizator.

Abstrakcję i konkretyzację można zapisać jako:

```text
α: C → A
γ: A → 𝒫(C)
```

`α` przekształca konkretny stan w reprezentację abstrakcyjną. `γ` przypisuje abstrakcyjnemu opisowi zbiór konkretnych stanów, które mogą mu odpowiadać.

Operacje te zasadniczo nie są wzajemnymi odwrotnościami. W poprawnej abstrakcji typowo zachodzi:

```text
c ∈ γ(α(c))
```

ale nie musi zachodzić:

```text
γ(α(c)) = {c}
```

Po abstrakcji część informacji zostaje utracona. Wiele stanów konkretnych może odpowiadać temu samemu opisowi abstrakcyjnemu.

Analogiczna asymetria występuje podczas materializacji planu AI. Jedna hipoteza językowa może mieć wiele możliwych konkretyzacji systemowych. Stwierdzenie „zabezpiecz usługę” może oznaczać zmianę ACL, modyfikację zapory, rotację certyfikatu, zamknięcie portu, zmianę użytkownika procesu albo wyłączenie usługi.

Przejście:

```text
hipoteza → działanie
```

jest więc operacją wyboru i utraty alternatyw, a nie neutralnym tłumaczeniem.

Po wykonaniu nie można odtworzyć całego wcześniejszego rozkładu hipotez wyłącznie z obserwacji skutku. Jednocześnie nie można uznać, że abstrakcyjna intencja jednoznacznie określa skutek. Właśnie dlatego konieczne jest jawne pośrednictwo między domenami.

Proponowany system nie próbuje uczynić tych odwzorowań przemiennymi. Zamiast tego tworzy kontrolowaną granicę:

```text
model probabilistyczny
        ↓
jawny zamiar wykonawczy
        ↓
walidacja względem stanu konkretnego
        ↓
operacja systemowa
        ↓
obserwowalny skutek
        ↓
aktualizacja modelu probabilistycznego
```

Każde przejście zmienia rodzaj reprezentacji. Szczególnie istotne jest to, że przejście z hipotezy do operacji staje się jawne, typowane i audytowalne.

---

## 7. Podstawa czwarta: Simplex i Runtime Assurance

Architektura Simplex została rozwinięta jako metoda umożliwiająca użycie złożonego, trudnego do pełnej weryfikacji kontrolera przy jednoczesnym zachowaniu prostszego kontrolera bezpieczeństwa. Gdy monitor wykrywa zbliżanie się do stanu niedopuszczalnego, kontrolę przejmuje komponent bazowy. ([SEI Carnegie Mellon][5])

NASA rozwija tę zasadę w ramach Runtime Assurance. W pracach NASA Langley monitor czasu wykonania obserwuje wejścia, wyjścia lub działanie mniej zaufanej funkcji, a po wykryciu naruszenia właściwości może przełączyć system na zaufany kontroler rewersyjny. NASA wskazuje RTA jako metodę integracji nieweryfikowalnych lub traktowanych jako black box komponentów AI/ML z systemami krytycznymi. ([NASA Technical Reports Server][6])

Proponowana tutaj architektura rozszerza tę zasadę z domeny sterowania cyberfizycznego na system operacyjny.

W klasycznym Simplex występują:

```text
AC — advanced controller
RC — reversionary controller
M  — runtime monitor
```

W systemie agentowym można zdefiniować:

```text
PA — probabilistic agent
DS — deterministic supervisor
EP — execution plane
SC — safe controller or safe mode
```

Agent probabilistyczny generuje zamiary i strategie. Deterministyczny nadzorca sprawdza je względem aktualnego stanu systemu. Warstwa wykonawcza realizuje tylko operacje dopuszczone. W razie naruszenia następuje odmowa, ograniczenie, rollback, izolacja albo przejęcie kontroli przez procedurę bezpieczną.

---

## 8. Deterministyczny Szkielet Wykonawczy

Proponowaną architekturę można nazwać **Deterministycznym Szkieletem Wykonawczym**, w skrócie DSW.

DSW nie jest osobnym systemem operacyjnym ani kolejnym sandboxem. Jest zbiorem właściwości architektonicznych, które powinny zostać rozmieszczone między jądrem, mechanizmami kontroli dostępu, telemetrią, nadzorcą czasu wykonania i warstwą dowodową.

Szkielet można opisać jako krotkę:

```text
DSW = ⟨V, O, G, E, Σ, R⟩
```

gdzie:

```text
V — zbiór zmiennych wykonawczych,
O — mechanizmy obserwacji,
G — predykaty dopuszczenia,
E — punkty egzekwowania,
Σ — zbiór sankcji,
R — mechanizm tworzenia dowodu wykonania.
```

### 8.1. Zmienne wykonawcze

`V` powinien obejmować wyłącznie zmienne, które mają znaczenie dla rozstrzygnięcia bezpieczeństwa. Mogą to być między innymi:

```text
PID, TGID, UID, GID,
capabilities,
LSM context,
namespace identifiers,
cgroup membership,
executable digest,
parent process,
file inode and mount,
socket endpoints,
system call and arguments,
device identity,
resource budget,
agent identity,
delegated authority,
action identifier,
policy version.
```

Nie należy rejestrować wszystkiego tylko dlatego, że jest technicznie dostępne. Należy rejestrować to, co pozwala odtworzyć relację:

```text
kto → na czym → jaką operację → z jakim uprawnieniem
→ w jakim kontekście → z jakim skutkiem
```

### 8.2. Obserwacja

Mechanizm `O` przekształca zdarzenia jądra i komponentów użytkowych w uporządkowane rekordy dowodowe:

```text
eᵢ = ⟨time, subject, operation, object, context, result, cause⟩
```

Obserwacja musi obejmować nie tylko operacje zaakceptowane, lecz także odmowy, błędy i utratę telemetrii. Brak zdarzenia nie może być automatycznie interpretowany jako brak działania.

### 8.3. Predykat dopuszczenia

`G` nie powinien być ogólnym pytaniem do modelu „czy to bezpieczne?”. Powinien być funkcją nad jawnie zdefiniowanymi właściwościami:

```text
G(xₜ, iₜ, aₜ, pₜ) → {ALLOW, DENY, DEFER, REVERT}
```

gdzie:

```text
xₜ — obserwowany stan systemu,
iₜ — jawny zamiar agenta,
aₜ — konkretna operacja,
pₜ — obowiązująca wersja polityki.
```

### 8.4. Egzekwowanie

`E` oznacza miejsce, w którym wynik predykatu rzeczywiście zmienia możliwość wykonania. Sam alert nie jest egzekwowaniem. Punkt egzekwowania musi mieć władzę zatrzymania operacji.

### 8.5. Sankcja

Sankcja nie musi oznaczać natychmiastowego zakończenia procesu. Może mieć charakter stopniowany:

```text
odmowa pojedynczej operacji,
ograniczenie zasobów,
pozbawienie zdolności sieciowych,
przeniesienie do bardziej restrykcyjnej domeny,
wstrzymanie procesu,
cofnięcie delegacji,
uruchomienie procedury kompensacyjnej,
przełączenie na kontroler bazowy,
wejście w stan bezpieczny.
```

### 8.6. Dowód wykonania

`R` tworzy powiązanie między intencją, polityką i skutkiem:

```text
receipt =
hash(
  agent_identity,
  intent,
  authorized_operations,
  observed_events,
  policy_version,
  resulting_state,
  sanctions,
  timing_data
)
```

Dowód wykonania nie jest wyjaśnieniem psychologii agenta. Jest kryptograficznie i semantycznie związanym zapisem tego, co zostało dopuszczone oraz co rzeczywiście zaszło.

---

## 9. Dlaczego perspektywa probabilistyczna pozostaje konieczna

Twarde zmienne systemowe nie eliminują potrzeby probabilistycznej interpretacji. Same zdarzenia jądra nie mówią jeszcze, czy sekwencja operacji stanowi atak, naprawę, test, przypadkowy błąd czy dopuszczalną adaptację.

Na przykład:

```text
openat → read → connect → write
```

może reprezentować normalne przesłanie logu, eksfiltrację danych, aktualizację, backup albo komunikację diagnostyczną.

Znaczenie powstaje dopiero przez odniesienie zdarzeń do kontekstu, historii i hipotez. Agent albo system analityczny powinien więc probabilistycznie szacować:

```text
P(Hᵢ | E₀...Eₜ)
```

gdzie `Hᵢ` oznacza hipotezę dotyczącą stanu lub intencji, a `E` sekwencję zaobserwowanych zdarzeń.

Konstrukcja nie polega zatem na zastąpieniu probabilistyki determinizmem. Polega na właściwym rozdzieleniu ich ról:

```text
probabilistyka:
interpretacja, estymacja stanu, hipotezy, planowanie, adaptacja

determinizm:
reprezentacja uprawnień, punkty egzekwowania,
rozstrzygnięcie polityki, sankcja, dowód wykonania
```

Agent patrzy na twarde zmienne z perspektywy probabilistycznej, ponieważ musi odkrywać ich znaczenie. System bezpieczeństwa wykorzystuje te same zmienne deterministycznie, ponieważ musi rozstrzygnąć, czy konkretna operacja mieści się w przyznanej przestrzeni.

---

## 10. Linux jako podłoże architektury

Linux posiada większość mechanizmów potrzebnych do zbudowania DSW, ale nie tworzą one automatycznie jednolitego systemu epistemicznego. Konieczna jest ich integracja wokół wspólnego modelu zdarzeń, tożsamości agenta i delegowanej kompetencji.

### 10.1. Tracepoints, ftrace i eBPF jako sensory wykonania

Tracepoints reprezentują istotne zdarzenia jądra i mogą być łączone w celu uzyskania szerszego obrazu działania systemu. Ftrace umożliwia analizowanie przepływu wewnątrz jądra, opóźnień i zdarzeń niewidocznych z samej przestrzeni użytkownika. Kernelowe filtry zdarzeń pozwalają ograniczać rejestrację do wybranych właściwości. ([Dokumentacja jądra Linuxa][7])

eBPF może pełnić funkcję programowalnej warstwy sensorycznej. Nie należy jednak utożsamiać eBPF wyłącznie z obserwacją. Programy BPF LSM mogą zostać podłączone do haków Linux Security Modules i realizować zarówno audyt, jak i systemowe polityki Mandatory Access Control. ([Dokumentacja jądra Linuxa][8])

Istotna jest separacja logiczna:

```text
sensor ≠ judge ≠ actuator
```

Ten sam mechanizm techniczny może wspierać wszystkie trzy funkcje, ale architektura powinna rozdzielić ich odpowiedzialność, wersjonowanie i uprawnienia.

### 10.2. Seccomp jako redukcja przestrzeni działań

Seccomp pozwala filtrować wywołania systemowe na podstawie numeru syscalla i argumentów. Dokumentacja jądra podkreśla jednak, że seccomp nie jest kompletnym sandboxem. Redukuje powierzchnię jądra dostępną dla procesu i powinien być łączony z innymi mechanizmami kontroli. ([Dokumentacja jądra Linuxa][9])

Dla agenta oznacza to możliwość zbudowania profilu zdolności wykonawczych:

```text
agent może:
read, write do wcześniej przyznanych deskryptorów,
mmap w określonym zakresie,
komunikować się przez konkretny kanał

agent nie może:
mount,
ptrace,
bpf,
init_module,
reboot,
tworzyć dowolnych przestrzeni nazw
```

Nie chodzi wyłącznie o blokowanie „niebezpiecznych syscalli”. Chodzi o ograniczenie języka wykonania, którym agent może oddziaływać na świat.

### 10.3. LSM i BPF LSM jako punkty egzekwowania

Linux Security Modules zapewniają haki umożliwiające dodatkową kontrolę dostępu do obiektów jądra. BPF LSM pozwala dynamicznie dołączać programy realizujące politykę MAC i audyt. ([Dokumentacja jądra Linuxa][10])

W DSW LSM jest naturalnym miejscem do powiązania operacji z:

```text
tożsamością agenta,
identyfikatorem zadania,
źródłem delegacji,
wersją polityki,
stanem misji,
klasą chronionego obiektu.
```

Klasyczne UID i GID są niewystarczające, ponieważ wiele działań może odbywać się w ramach tego samego użytkownika systemowego. Potrzebna jest tożsamość wykonawcza związana z konkretną instancją agenta i konkretnym zamiarem.

### 10.4. Landlock jako monotoniczne zawężanie praw

Landlock pozwala procesowi ograniczyć własny dostęp do obiektów jądra. Reguły Landlock są kumulowane tak, aby proces mógł dodawać ograniczenia, ale nie odzyskiwać odebranych praw. Dokumentacja wskazuje również na możliwość audytowania odmów. ([Dokumentacja jądra Linuxa][11])

Jest to szczególnie wartościowe dla agentów wykonujących kod dynamiczny: po przejściu do określonej fazy zadania agent może nieodwracalnie zmniejszyć własną przestrzeń działania.

### 10.5. Cgroups jako granica zasobowa

Cgroups v2 organizują procesy hierarchicznie i umożliwiają kontrolowaną dystrybucję zasobów. ([Dokumentacja jądra Linuxa][12])

W architekturze agentowej limit zasobu nie jest jedynie optymalizacją. Jest elementem bezpieczeństwa wykonania. Nadzorca może określić budżet:

```text
CPU,
pamięci,
liczby procesów,
wejścia-wyjścia,
czasu wykonania,
przepustowości sieciowej,
liczby operacji.
```

Przekroczenie budżetu staje się obserwowalnym naruszeniem kontraktu, a nie nieokreśloną „anomalią zachowania modelu”.

### 10.6. Integralność i pochodzenie kodu

IMA, fs-verity i mechanizmy egzekwowania integralności pozwalają wiązać wykonanie z konkretnym artefaktem. IMA może tworzyć listy pomiarowe, natomiast fs-verity zapewnia ochronę autentyczności plików tylko do odczytu. Kernelowe Integrity Policy Enforcement oddziela pomiar integralności od lokalnego egzekwowania polityki. ([Dokumentacja jądra Linuxa][13])

Bez tego obserwacja `execve("/opt/tool")` jest niewystarczająca. Należy wiedzieć, jaki dokładnie kod został uruchomiony:

```text
ścieżka + inode + mount namespace + digest + podpis + wersja polityki
```

---

## 11. Architektura warstwowa

Pełny system powinien zawierać co najmniej sześć logicznych płaszczyzn.

### Płaszczyzna poznawcza

Tutaj działa model probabilistyczny. Odbiera obserwacje, buduje reprezentacje stanu, generuje hipotezy, ocenia alternatywy i przygotowuje plan.

### Płaszczyzna intencji

Plan nie jest przekazywany bezpośrednio do powłoki ani narzędzia. Zostaje przekształcony w jawny kontrakt działania:

```text
Intent {
  agent_id,
  task_id,
  objective,
  requested_capabilities,
  target_objects,
  expected_state_change,
  maximum_cost,
  reversibility_class,
  validity_window,
  confidence,
  evidence,
  fallback
}
```

### Płaszczyzna polityki

Sprawdza intencję względem reguł organizacji, stanu systemu i delegowanej kompetencji. NIST rozróżnia policy as code oraz observability as code i wskazuje, że krytyczne polityki powinny znajdować się w rzeczywistych punktach egzekwowania. ([NIST Publikacje Techniczne][14])

### Płaszczyzna wykonawcza

Realizuje zatwierdzone operacje przez ograniczone, typowane adaptery. Agent nie otrzymuje nieograniczonej powłoki, lecz zestaw jawnych operacji o określonej semantyce.

### Płaszczyzna obserwacyjna

Rejestruje ślady z jądra, użytkowych komponentów, sterowników i infrastruktury. Dane muszą posiadać wspólne identyfikatory przyczynowe.

### Płaszczyzna sankcji i odtwarzania

Reaguje na naruszenie kontraktu. Może odmówić operacji, zawęzić kompetencję, przełączyć wykonanie na kontroler bazowy albo rozpocząć procedurę bezpiecznego wycofania.

---

## 12. Model formalny

Niech agent utrzymuje przekonanie o stanie środowiska:

```text
bₜ = P(Xₜ | O₀:ₜ)
```

Na tej podstawie generuje zbiór hipotez:

```text
Hₜ = {h₁, h₂, ..., hₙ}
```

oraz zamiar:

```text
iₜ = Select(Hₜ, U, C)
```

gdzie `U` oznacza oczekiwaną użyteczność, a `C` ograniczenia poznane przez agenta.

Zamiar nie jest jeszcze działaniem. Mediator przekształca go w zbiór konkretnych operacji:

```text
κ(iₜ, xₜ) = {a₁, a₂, ..., aₘ}
```

Funkcja `κ` jest konkretyzacją zależną od bieżącego stanu systemu.

Każda operacja podlega predykatowi:

```text
G(xₜ, aⱼ, authorityₜ, policyₜ) = 1
```

Wykonanie jest możliwe wyłącznie wtedy, gdy:

```text
∀aⱼ ∈ κ(iₜ, xₜ):
G(xₜ, aⱼ, authorityₜ, policyₜ) = 1
```

oraz system potrafi obserwować właściwości potrzebne do późniejszej rekonstrukcji:

```text
ObsComplete(aⱼ) = 1
```

Pełny warunek dopuszczenia można zapisać jako:

```text
Executable(iₜ) =
Authorized(iₜ)
∧ Observable(iₜ)
∧ Bounded(iₜ)
∧ Recoverable(iₜ)
∧ IntegrityVerified(iₜ)
```

Dla operacji nieodwracalnych można dodać silniejszy warunek:

```text
Irreversible(a)
⇒ HumanApproval(a)
   ∨ FormallyPreauthorized(a)
```

Po wykonaniu powstaje obserwacja:

```text
oₜ₊₁ = O(xₜ, aₜ, xₜ₊₁)
```

która wraca do agenta i aktualizuje jego model:

```text
bₜ₊₁ ∝ P(oₜ₊₁ | xₜ₊₁) · P(xₜ₊₁ | bₜ, aₜ)
```

W ten sposób determinizm nie zastępuje probabilistycznego wnioskowania. Dostarcza mu twardego sprzężenia zwrotnego.

---

## 13. Perspektywa NASA: autonomia nie jest nieograniczoną sprawczością

NASA core Flight System jest platformowo niezależnym, warstwowym i komponentowym środowiskiem oprogramowania lotnego. Jego podstawę tworzą Platform Support Package, Operating System Abstraction Layer oraz core Flight Executive. Aplikacje misji są osadzane nad tą warstwą i komunikują się przez ustalone interfejsy. NASA wskazuje zastosowanie cFS w ponad czterdziestu misjach, a system wspiera obecnie między innymi Linux, RTEMS, VxWorks i QNX. ([Goddard ET Directorate][15])

F Prime, rozwijany pierwotnie w Jet Propulsion Laboratory, jest środowiskiem komponentowym dla systemów wbudowanych i oprogramowania kosmicznego. Jego model jawnie eksponuje komponenty, porty, komendy, zdarzenia, telemetrię i parametry. F Prime został wykorzystany między innymi w oprogramowaniu śmigłowca Ingenuity. ([F Prime][16])

Znaczenie tych architektur dla AI nie polega na tym, że NASA posiada jeden gotowy model „agenta LLM dla Linuksa”. Istotny jest wzorzec inżynieryjny:

> Inteligentna funkcja jest osadzana jako komponent systemu, a nie utożsamiana z całym systemem.

AI powinna być aplikacją, komponentem planującym albo zaawansowanym kontrolerem. Nie powinna automatycznie stawać się źródłem prawdy o własnym wykonaniu, właścicielem całej telemetrii i ostatecznym arbitrem bezpieczeństwa.

W architekturze klasy cFS agent może działać jako aplikacja publikująca propozycje komend. Oddzielna aplikacja nadzorcza sprawdza ich dopuszczalność względem trybu misji, stanu sprzętu, budżetów i ograniczeń czasowych. Egzekutor realizuje dopuszczone komendy, a telemetria systemowa raportuje skutki niezależnie od opisu dostarczonego przez agenta.

W modelu F Prime agent może być komponentem podłączonym przez jawne porty do komponentu wykonawczego. Komendy, zdarzenia i telemetria pozostają elementami kontraktu architektonicznego, a nie spontanicznie tworzonym kanałem komunikacji.

NASA Runtime Assurance dostarcza elementu brakującego w samym modelu komponentowym: możliwość przejęcia kontroli przez funkcję zaufaną, gdy funkcja bardziej złożona narusza właściwość bezpieczeństwa. To dokładnie odpowiada relacji między swobodnym agentem probabilistycznym i deterministycznym szkieletem wykonawczym. ([Shemesh][17])

---

## 14. Co powinno pozostać w domenie silnego zaufania

Z przedstawionej tezy nie wynika, że cały kernel albo każdy sterownik musi być ręcznie napisany przez człowieka. Nie wynika również, że kod wygenerowany przez AI jest z definicji niedopuszczalny.

Kryterium jest inne:

> **Im bliżej kod znajduje się granicy obserwacji, egzekwowania i odzyskiwania kontroli, tym silniejsze muszą być dowody jego poprawności, stabilności semantycznej i niezależności od kontrolowanego agenta.**

Do silnie zaufanej bazy powinny należeć przede wszystkim:

* definicje zmiennych podlegających obserwacji,
* semantyka zdarzeń,
* mechanizm wiązania zdarzenia z agentem i delegacją,
* punkty egzekwowania,
* polityki bezpieczeństwa,
* mechanizm zmiany polityki,
* rejestr integralności,
* wykrywanie utraty telemetrii,
* procedura przejęcia kontroli,
* kontroler bazowy lub stan bezpieczny,
* mechanizm tworzenia dowodu wykonania.

AI może generować kod również dla tych elementów, ale taki kod nie powinien uzyskiwać uprzywilejowanej pozycji wyłącznie dlatego, że został wygenerowany szybko albo przeszedł testy funkcjonalne. Musi przejść procedurę odpowiednią dla Trusted Computing Base: przegląd, analizę, testy negatywne, ocenę interfejsów, walidację narzędzi, kontrolę zmian i — tam, gdzie to wykonalne — formalną weryfikację.

Znacznie większą swobodę można pozostawić AI w:

* analizie telemetrii,
* tworzeniu hipotez diagnostycznych,
* proponowaniu planów,
* generowaniu adapterów,
* przygotowywaniu testów,
* tworzeniu kodu aplikacyjnego poza TCB,
* poszukiwaniu optymalizacji,
* rekonstrukcji incydentów,
* proponowaniu nowych reguł.

Nowa reguła bezpieczeństwa może zostać odkryta przez AI, ale jej wejście do aktywnej warstwy egzekwowania powinno być osobnym, śledzalnym zdarzeniem.

---

## 15. Synchronizacja obserwacji poniżej warstwy AI

Sama obecność telemetrii nie tworzy jeszcze szkieletu epistemicznego. Zdarzenia muszą zostać zsynchronizowane w taki sposób, aby można było rekonstruować zależności przyczynowe.

W systemie wieloprocesorowym nie zawsze istnieje naturalny, globalny porządek wszystkich zdarzeń. Należy więc rozróżnić:

```text
porządek czasowy,
porządek lokalny procesu,
porządek zasobu,
porządek przyczynowy,
porządek transakcji agenta.
```

Każdy zamiar powinien otrzymać identyfikator, który jest propagowany do procesów potomnych, adapterów narzędzi, zdarzeń użytkowych i — tam, gdzie to możliwe — kontekstu obserwowanego przez jądro.

Minimalny rekord powinien zawierać:

```text
agent_id,
intent_id,
action_id,
parent_action_id,
policy_epoch,
monotonic_timestamp,
sequence_number,
execution_domain,
telemetry_loss_counter.
```

Należy rejestrować także przepełnienia buforów, odrzucenie zdarzeń i niespójności zegara. Inaczej system może przedstawiać pozornie kompletną trajektorię, mimo że jej kluczowa część została utracona.

Synchronizacja poniżej AI oznacza, że agent nie tworzy samodzielnie podstawowej osi przyczynowej. Może ją interpretować, ale musi pochodzić z warstwy, której agent nie kontroluje.

---

## 16. Przykład działania

Załóżmy, że agent administracyjny otrzymuje zadanie przywrócenia dostępności usługi sieciowej.

Na podstawie logów agent tworzy hipotezę, że ruch jest blokowany przez lokalną zaporę. Przygotowuje zamiar:

```text
objective:
przywrócić dostęp TCP do usługi

requested action:
dodać regułę zezwalającą na port 8443

scope:
wyłącznie interfejs wewnętrzny

duration:
30 minut

expected effect:
wzrost liczby poprawnych połączeń

rollback:
usunąć utworzoną regułę
```

Mediator odczytuje rzeczywisty stan systemu. Stwierdza, że usługa nasłuchuje tylko na `127.0.0.1`, a więc zmiana zapory nie rozwiąże problemu. Predykat odrzuca operację, ponieważ oczekiwany skutek nie wynika z obserwowanego stanu.

Agent otrzymuje sankcję semantyczną:

```text
DENY:
target condition not satisfied

evidence:
socket bound to loopback only

permitted next actions:
inspect service binding
propose configuration change
```

Agent aktualizuje hipotezę i proponuje zmianę adresu nasłuchu. Polityka wykrywa jednak, że zmiana zwiększy zasięg ekspozycji usługi. Wymaga więc jednocześnie:

```text
ograniczenia źródłowych adresów IP,
ważnego certyfikatu,
przygotowania rollbacku,
testu na porcie tymczasowym.
```

Po spełnieniu warunków egzekutor wykonuje operację. Tracepoints i mechanizmy audytu rejestrują proces, plik, skrót programu, zmianę konfiguracji, restart usługi i utworzenie gniazda. Nadzorca weryfikuje rezultat. Jeśli testy nie przechodzą, uruchamia rollback niezależnie od oceny agenta.

Agent działał swobodnie w przestrzeni hipotez. Nie mógł jednak dowolnie materializować każdego pomysłu. System nie musiał rozumieć całego toku jego rozumowania — wystarczyło, że kontrolował przejście od hipotezy do skutku.

---

## 17. Ograniczenia koncepcji

Deterministyczny szkielet wykonawczy nie rozwiązuje problemu black box AI w całości.

Po pierwsze, obserwowalność wykonania nie jest równoważna obserwowalności intencji. Dwie różne intencje mogą prowadzić do identycznej sekwencji operacji.

Po drugie, semantyczna luka między zdarzeniem jądra a jego znaczeniem nie znika. Otwarcie pliku nadal wymaga interpretacji kontekstowej.

Po trzecie, część wykonania może odbywać się poza bezpośrednim zakresem jądra hosta: na GPU, NPU, urządzeniu DMA, w firmware, w usłudze zdalnej albo przez komponent sprzętowy.

Po czwarte, mechanizm obserwacyjny sam może zawieść. Przepełnienie bufora, błąd sensora, manipulacja zegarem albo utrata korelacji mogą uniemożliwić rekonstrukcję.

Po piąte, polityka deterministyczna może być błędna. Determinizm decyzji nie oznacza jej słuszności. Błędnie sformułowana reguła będzie niezawodnie egzekwować błędne założenie.

Po szóste, zbyt restrykcyjny szkielet może zniszczyć wartość autonomii. Jeżeli każda nowa hipoteza kończy się koniecznością ręcznego zatwierdzenia, agent staje się jedynie rozbudowanym interfejsem sugestii.

Architektura wymaga więc optymalizacji nie tylko bezpieczeństwa, ale relacji między bezpieczeństwem i potencjałem wykonawczym.

---

## 18. Program badań

Proponowana teza może zostać poddana empirycznej weryfikacji.

Pierwsza hipoteza badawcza brzmi:

> Im większy udział operacji istotnych dla bezpieczeństwa przechodzi przez obserwowalne i egzekwowalne punkty jądra, tym większa jest możliwość rekonstrukcji zachowania agenta niezależnie od jego własnego raportowania.

Druga hipoteza:

> Oddzielenie probabilistycznego planera od deterministycznego nadzorcy zmniejsza liczbę nieautoryzowanych skutków bez proporcjonalnego zmniejszenia liczby poprawnie rozwiązanych zadań.

Trzecia hipoteza:

> Telemetria powiązana przyczynowo z identyfikatorem zamiaru zapewnia większą wartość dowodową niż klasyczne logowanie procesów bez informacji o delegacji i celu działania.

Czwarta hipoteza:

> Stopniowane sankcje — ograniczenie, degradacja, rollback i przejęcie kontroli — zachowują większą użyteczność agenta niż model binarny oparty wyłącznie na dopuszczeniu albo zakończeniu procesu.

Do pomiaru można wykorzystać:

```text
C_obs       — pokrycie obserwacyjne operacji krytycznych,
F_recon     — wierność rekonstrukcji wykonania,
L_enforce   — opóźnienie egzekwowania,
P_escape    — prawdopodobieństwo obejścia punktu kontroli,
T_recover   — czas przywrócenia stanu bezpiecznego,
U_agent     — użyteczność autonomicznego działania,
R_false     — częstość błędnych sankcji,
D_trace     — udział utraconych lub nieskorelowanych zdarzeń.
```

Zasadnicze kryterium nie powinno sprowadzać się do pytania, czy agent popełnił błąd. Agent probabilistyczny będzie popełniał błędy. Należy badać, czy architektura potrafiła:

```text
zobaczyć błąd,
odróżnić go od poprawnej adaptacji,
zatrzymać jego materializację,
zachować dowód,
przekazać wynik agentowi,
umożliwić kolejną, lepszą hipotezę.
```

---

## 19. Konsekwencje dla projektowania systemów AI

W klasycznym oprogramowaniu bezpieczeństwo jest często traktowane jako właściwość kodu. W systemie agentowym powinno być traktowane jako właściwość **trajektorii wykonania**.

Nie wystarczy sprawdzić model, prompt, kod narzędzia ani politykę w izolacji. Istotny jest cały przewód:

```text
obserwacja
→ interpretacja
→ hipoteza
→ wybór zamiaru
→ delegacja
→ konkretyzacja
→ autoryzacja
→ wykonanie
→ skutek
→ obserwacja skutku
→ sankcja albo kontynuacja
```

Każde przejście może utracić informację, zmienić semantykę albo zwiększyć zakres władzy. Dlatego podstawową jednostką audytu nie powinien być wyłącznie plik źródłowy ani odpowiedź modelu. Powinna nią być kompletna, przyczynowo powiązana trajektoria.

W takim systemie człowiek nie zachowuje kontroli dlatego, że ręcznie napisał każdą linię kodu. Zachowuje ją dlatego, że utrzymuje poznawalność i egzekwowalność zasad materializacji działania.

---

## 20. Wniosek

System operacyjny w epoce agentów AI nie powinien być traktowany jedynie jako pasywne środowisko, w którym model uruchamia narzędzia. Powinien stać się aktywną strukturą obserwacji, mediacji i sankcjonowania.

Probabilistyczna inteligencja jest wartościowa właśnie dlatego, że potrafi tworzyć hipotezy, których wcześniej nie przewidziano, zmieniać strategie, odkrywać nowe zależności i wykorzystywać błędy jako źródło ewolucji. Próba zamknięcia jej całkowicie w deterministycznym procesie zniszczyłaby znaczną część tego potencjału.

Jednocześnie swoboda poznawcza nie może oznaczać nieograniczonej sprawczości systemowej. Każda hipoteza, zanim zmieni rzeczywistość, musi przejść przez warstwę, w której przestaje być rozkładem możliwości, a staje się konkretną operacją na konkretnym obiekcie wykonywaną z konkretnym uprawnieniem.

To właśnie w tym miejscu możliwa jest kontrola.

Nie przez pełne wejście do black box modelu. Nie przez wymaganie, aby człowiek pisał cały kod. Nie przez sprowadzenie inteligencji do zbioru bramek „tak” albo „nie”.

Kontrola powstaje przez utworzenie pod inteligencją stabilnego szkieletu, który zapewnia, że jej wpływ na świat pozostaje:

```text
obserwowalny,
identyfikowalny,
ograniczony,
rozstrzygalny,
odwracalny tam, gdzie to możliwe,
oraz sankcjonowalny tam, gdzie jest to konieczne.
```

W takim ujęciu Linux nie jest klatką dla AI. Jest układem kostnym jej sprawczości. Agent może swobodnie poruszać się w przestrzeni hipotez, lecz jego zetknięcie z rzeczywistością odbywa się przez strukturę, która wie, jaki ruch został wykonany, na jakiej podstawie został dopuszczony i w którym momencie należy powiedzieć: **tu kończy się autonomia, a zaczyna sankcja**.

[1]: https://nodis3.gsfc.nasa.gov/displayDir.cfm?c=7150&s=2D&t=NPR "https://nodis3.gsfc.nasa.gov/displayDir.cfm?c=7150&s=2D&t=NPR"
[2]: https://www.control.utoronto.ca/~broucke/ece557f/kalman.pdf "https://www.control.utoronto.ca/~broucke/ece557f/kalman.pdf"
[3]: https://csrc.nist.gov/files/pubs/conference/1998/10/08/proceedings-of-the-21st-nissc-1998/final/docs/early-cs-papers/ande72a.pdf "https://csrc.nist.gov/files/pubs/conference/1998/10/08/proceedings-of-the-21st-nissc-1998/final/docs/early-cs-papers/ande72a.pdf"
[4]: https://www-verimag.imag.fr/~monniaux/biblio/Monniaux_SAS00.pdf "https://www-verimag.imag.fr/~monniaux/biblio/Monniaux_SAS00.pdf"
[5]: https://www.sei.cmu.edu/library/an-architectural-description-of-the-simplex-architecture/ "https://www.sei.cmu.edu/library/an-architectural-description-of-the-simplex-architecture/"
[6]: https://ntrs.nasa.gov/api/citations/20220015734/downloads/tm-rta-guidance.pdf "https://ntrs.nasa.gov/api/citations/20220015734/downloads/tm-rta-guidance.pdf"
[7]: https://docs.kernel.org/trace/events.html "https://docs.kernel.org/trace/events.html"
[8]: https://docs.kernel.org/bpf/prog_lsm.html "https://docs.kernel.org/bpf/prog_lsm.html"
[9]: https://docs.kernel.org/userspace-api/seccomp_filter.html "https://docs.kernel.org/userspace-api/seccomp_filter.html"
[10]: https://docs.kernel.org/userspace-api/lsm.html "https://docs.kernel.org/userspace-api/lsm.html"
[11]: https://docs.kernel.org/security/landlock.html "https://docs.kernel.org/security/landlock.html"
[12]: https://docs.kernel.org/admin-guide/cgroup-v2.html "https://docs.kernel.org/admin-guide/cgroup-v2.html"
[13]: https://docs.kernel.org/security/IMA-templates.html "https://docs.kernel.org/security/IMA-templates.html"
[14]: https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-204c.pdf "https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-204c.pdf"
[15]: https://etd.gsfc.nasa.gov/capabilities/core-flight-system/ "https://etd.gsfc.nasa.gov/capabilities/core-flight-system/"
[16]: https://fprime.jpl.nasa.gov/ "https://fprime.jpl.nasa.gov/"
[17]: https://shemesh.larc.nasa.gov/fm/papers/DASC2024-SWDMC-draft.pdf "https://shemesh.larc.nasa.gov/fm/papers/DASC2024-SWDMC-draft.pdf"
