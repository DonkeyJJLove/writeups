# JARZMO OBSERWOWALNOŚCI DLA MODELI OPENAI NA LINUX 7.1.8

## Architektura monitora referencyjnego z autoryzacją warunkowaną stanem obserwowalności, nadzorem czasu wykonania i atestacją skutków

**Stan badania: 11 sierpnia 2026 r.**
**Docelowe jądro: Linux 7.1.8 stable**
**Jądro rozwojowe odniesienia: Linux 7.2-rc7**
**Aktualna linia LTS: Linux 6.18.44**

## Wynik badania

**Tak — na aktualnym Linuksie można zbudować środowisko, w którym wzrost autonomii agenta zależy od zachowania obserwowalności, integralności platformy i kompletności pochodzenia wykonania.**

Gwarancja ta obowiązuje jednak tylko dla skutków, które:

1. przechodzą przez niepomijalny punkt egzekwowania polityki,
2. są wykonywane lokalnie albo przez kontrolowaną bramę zewnętrzną,
3. mogą zostać przypisane do konkretnego procesu, izolowanego środowiska i żądania narzędziowego,
4. pozostawiają sprawdzalne dowody wykonania.

Linux nie może samodzielnie dowieść wewnętrznego przebiegu inferencji wykonywanej na infrastrukturze OpenAI ani skutków narzędzi hostowanych poza lokalnym systemem. Może natomiast kontrolować lokalny **agent harness**, lokalne narzędzia, procesy, poświadczenia, połączenia sieciowe, system plików i wszystkie lokalne efekty przechodzące przez jądro.

---

## Streszczenie

Materiał wyjściowy odwraca klasyczną zależność „wykonanie, a następnie telemetryka” i przyjmuje zasadę „obserwowalność jako warunek dopuszczenia wykonania”. Utrata obserwowalności ma powodować ograniczenie uprawnień, a brak możliwości odtworzenia działania ma obniżać jego wiarygodność w modelu zaufania. 

Po dopasowaniu do istniejącej terminologii technicznej „Jarzmo obserwowalności” nie jest jednym mechanizmem. Jest złożeniem pięciu znanych klas architektur:

```text
REFERENCE MONITOR
+ COMPLETE MEDIATION
+ POLICY DECISION / POLICY ENFORCEMENT
+ RUNTIME ASSURANCE
+ EXECUTION PROVENANCE AND ATTESTATION
```

Najdokładniejsza pełna nazwa techniczna brzmi zatem:

> **Architektura monitora referencyjnego z autoryzacją warunkowaną obserwowalnością, nadzorem czasu wykonania i atestacją skutków.**

Po angielsku:

> **Observability-Conditioned Reference Monitor with Runtime Assurance and Execution Attestation.**

„Jarzmo obserwowalności” może pozostać nazwą projektu, ale w dokumentacji inżynieryjnej powinno być zawsze rozwijane do tej architektury.

---

# 1. Stan techniczny na 11 sierpnia 2026 roku

## Linux

**[FAKT]** Według kernel.org aktualną wersją stabilną jest Linux **7.1.8**, wydany 9 sierpnia 2026 r. Aktualną wersją mainline jest **7.2-rc7**, a najnowszą wskazaną linią longterm — **6.18.44**. Wersja `-rc` jest kandydatem rozwojowym, dlatego właściwym punktem bazowym PoC jest 7.1.8, nie 7.2-rc7. ([Kernel][1])

Wersja LTS 6.18.44 może być rozsądniejszym wyborem eksploatacyjnym, jeżeli priorytetem jest długotrwałe utrzymanie. Projekt referencyjny powinien jednak zostać zbadany na 7.1.8, ponieważ zawiera aktualny zestaw interfejsów Landlock, IPE i kontroli wykonywalności opisanych w dokumentacji jądra 7.1.

## OpenAI

**[FAKT]** Aktualną rodziną modeli ogólnego przeznaczenia jest GPT‑5.6: Sol jako wariant flagowy, Terra jako wariant równoważący koszt i możliwości oraz Luna jako wariant wysokoprzepustowy i ekonomiczny. Alias `gpt-5.6` prowadzi obecnie do `gpt-5.6-sol`, a OpenAI zaleca Responses API dla przepływów wykorzystujących rozumowanie, narzędzia i pracę wieloetapową. ([OpenAI][2])

Responses API może w jednym przebiegu wywoływać wiele narzędzi i utrzymywać stan między kolejnymi interakcjami. Oznacza to, że granicą badanego systemu nie jest już pojedyncze wywołanie modelu, lecz pełna trajektoria:

```text
WEJŚCIE
→ INFERENCJA
→ WYWOŁANIE NARZĘDZIA
→ WYNIK
→ KOLEJNA INFERENCJA
→ KOLEJNE DZIAŁANIE
```

([OpenAI Developers][3])

---

# 2. Normalizacja terminologii

## „Jarzmo obserwowalności”

W informatyce bezpieczeństwa najbliższym istniejącym pojęciem jest **reference monitor**, czyli monitor referencyjny. Jest to mechanizm egzekwujący politykę dostępu, który powinien być zawsze wywoływany, odporny na obejście i modyfikację oraz na tyle mały i jednoznaczny, aby można było go przeanalizować i zweryfikować. ([Csrc][4])

Samo pojęcie monitora referencyjnego nie zawiera jednak dynamicznego uzależnienia uprawnień od jakości telemetrii. W Jarzmie trzeba więc dołączyć:

* **continuous authorization** — ciągłą, ponawianą ocenę autoryzacji,
* **runtime assurance** — nadzór czasu wykonania i przejście do bezpieczniejszego sterownika lub stanu,
* **attestation** — atestację stanu platformy,
* **provenance** — pochodzenie i historię przetwarzania,
* **fail-closed degradation** — ograniczanie działania przy utracie wymaganych sygnałów.

W architekturach Runtime Assurance mniej zaufany, zaawansowany sterownik może działać tylko tak długo, jak długo monitor nie wykrywa naruszenia warunku bezpieczeństwa. Po jego naruszeniu kontrolę przejmuje zaufany sterownik zastępczy albo system zostaje zatrzymany. Jest to bezpośredni techniczny odpowiednik zasady „agent może działać tak długo, jak system utrzymuje nad nim kontrolę”. ([shemesh.larc.nasa.gov][5])

## „Sprawczość”

Technicznie należy używać określeń:

* **effect authority** — uprawnienie do powodowania skutków,
* **actuation authority** — uprawnienie do sterowania zasobem lub wykonania operacji,
* **authorized action space** — dozwolona przestrzeń działań.

Model językowy sam nie powinien posiadać sprawczości. Powinien jedynie generować **action proposals**, czyli propozycje działań. Uprawnienie do ich realizacji posiada dopiero podmiot wykonawczy działający przez kontrolowaną bramę.

## „Cyber-Tiger”

Łańcuch:

```text
ŹRÓDŁO → ZNACZENIE → INTERPRETACJA → AGENT → NARZĘDZIE → DECYZJA → DZIAŁANIE
```

należy określić jako:

> **semantic-to-operational decision provenance pipeline**

czyli:

> **łańcuch pochodzenia decyzji od źródła informacji do skutku operacyjnego.**

W3C PROV opisuje pochodzenie przez relacje między:

* **Entity** — informacją lub artefaktem,
* **Activity** — procesem przetwarzającym,
* **Agent** — podmiotem odpowiedzialnym lub uczestniczącym.

Cyber-Tiger można więc zapisać jako profil W3C PROV rozszerzony o decyzję, autoryzację i efekt. ([W3C][6])

## „LTBC — LLM Trust Boundary Collapse”

Nie jest to obecnie standardowa nazwa jednej klasy podatności. Jest to użyteczna nazwa zbiorcza dla kilku znanych mechanizmów:

```text
DATA → INSTRUCTION
= pomieszanie płaszczyzny danych i sterowania
= prompt injection

CONTEXT → AUTHORITY
= confused deputy
= ambient authority
= niejawne dziedziczenie uprawnień

MEMORY → FACT
= persistent-state poisoning
= provenance failure

MODEL OUTPUT → DECISION
= niezwalidowane wyjście modelu użyte jako sygnał sterujący

DECISION → TOOL AUTHORIZATION
= authority amplification

AGENT → AGENT → AUTHORITY
= transitive delegation
= credential forwarding
= delegation laundering
```

Zamiast twierdzić, że istnieje jedna „granica LLM”, należy opisywać konkretne przejście, w którym informacja zmienia rolę: z danych staje się instrukcją, z instrukcji decyzją, a z decyzji autoryzacją.

## „Agentic Execution Provenance Gap”

Najbliższe techniczne określenie to:

> **end-to-end execution attribution and provenance gap**

czyli:

> **luka pełnego przypisania i pochodzenia wykonania.**

Chodzi o różnicę między deklarowaną konfiguracją agenta a faktycznym zbiorem komponentów, stanów, poświadczeń i procesów, które wpłynęły na konkretny efekt.

## „AI-BOM / LBOM”

Nie należy przedstawiać ich jako istniejących, powszechnie przyjętych standardów na równi z SBOM.

Technicznie powinny zostać rozdzielone na:

* **runtime execution manifest** — manifest konkretnego wykonania,
* **model and context inventory** — inwentarz modelu i kontekstu,
* **decision provenance record** — zapis pochodzenia decyzji,
* **authorization provenance record** — zapis pochodzenia uprawnień,
* **runtime provenance graph** — graf pochodzenia działania.

Można je kodować jako rozszerzony profil W3C PROV i jako własny `predicateType` w strukturze in-toto Statement. in-toto służy do generowania weryfikowalnych twierdzeń o tym, jak powstał artefakt; analogiczny schemat można zastosować do wykonania agentowego, ale będzie to rozszerzenie projektu, nie gotowy standard AI. ([GitHub][7])

## „AuthGraph”

Najdokładniejsze określenie to:

> **authorization, delegation and capability graph**

czyli graf:

```text
PRINCIPAL
→ CREDENTIAL
→ DELEGATION
→ POLICY DECISION
→ CAPABILITY
→ EXECUTION SUBJECT
→ ACTION
→ RESOURCE
```

Graf danych i graf autoryzacji muszą pozostawać osobnymi strukturami. To, że agent otrzymał informację o zasobie, nie oznacza, że uzyskał uprawnienie do jego modyfikacji.

## „Memory poisoning”

Należy używać terminu:

> **persistent agent-state poisoning**

albo, zależnie od mechanizmu:

> **persistent context poisoning**
> **retrieval-store poisoning**
> **provenance-confused state update**

Zapis pamięci nie jest zwykłym zapisem danych. Może zmieniać przyszłą politykę wyboru działań i dlatego powinien być traktowany jak modyfikacja stanu sterownika.

## „Execution Receipt”

Najdokładniejsze określenie to:

> **signed, tamper-evident execution record**

albo:

> **execution attestation record**

Po polsku:

> **podpisany, odporny na niezauważalną modyfikację zapis wykonania.**

Nie powinien być automatycznie nazywany „dowodem” w znaczeniu matematycznym. Podpis kryptograficzny dowodzi co najwyżej, że określony podmiot podpisał określoną treść. Siła wniosku zależy od integralności kolektora, klucza, platformy i kompletności pomiaru.

## „Stado lwów”

Technicznie jest to:

> **distributed multi-sensor telemetry fusion and state reconstruction**

czyli:

> **rozproszona fuzja telemetrii oraz rekonstrukcja stanu z wielu niezależnych obserwatorów.**

Lokalne sensory nie muszą widzieć całości. Ich obserwacje muszą jednak dać się skorelować przez wspólne identyfikatory wykonania.

## „Parytet wykonalności”

Najbliższe określenia techniczne to:

* **assurance-overhead budget**,
* **security-performance feasibility envelope**,
* **control-plane overhead boundary**.

Chodzi o granicę, po przekroczeniu której koszt obserwacji i kontroli niszczy przepustowość albo opóźnienie systemu.

---

# 3. Rzeczywista granica systemu

Podstawowy błąd architektoniczny polegałby na potraktowaniu modelu OpenAI jak lokalnego procesu Linuksa. Nie jest nim.

Trzeba rozdzielić co najmniej pięć domen zaufania:

```text
T0 — HARDWARE / FIRMWARE / BOOT / KERNEL

T1 — ZAUFANY CONTROL PLANE
     agent harness, polityka, poświadczenia, rejestr dowodów

T2 — LOKALNY EXECUTION PLANE
     sandbox, procesy, narzędzia, filesystem, sieć

T3 — OPENAI INFERENCE DOMAIN
     zdalny model i infrastruktura API

T4 — EXTERNAL EFFECT DOMAIN
     serwisy SaaS, API, poczta, repozytoria, systemy produkcyjne
```

OpenAI samo rozdziela agentowy **harness** jako control plane od środowiska obliczeniowego, w którym wykonywane są polecenia i modyfikowane pliki. Harness ma być właścicielem pętli agenta, routingu narzędzi, zatwierdzeń, trace’ów, stanu i odzyskiwania, podczas gdy sandbox jest płaszczyzną wykonawczą. ([OpenAI Developers][8])

Shell OpenAI może być uruchamiany albo w kontenerze hostowanym przez OpenAI, albo w lokalnym runtime zarządzanym przez użytkownika. Tylko drugi wariant znajduje się pod kontrolą lokalnego kernela. ([OpenAI Developers][9])

Z tego wynika najważniejsza zasada zakresu:

> **Linux może wymusić Jarzmo na lokalnym harnessie i lokalnych efektach. Nie może wymusić go wewnątrz zdalnej infrastruktury modelu.**

Dla narzędzi hostowanych przez OpenAI lub zdalnego MCP pozostają tylko:

* identyfikatory API,
* trace’y dostawcy,
* deklaracje i wyniki narzędzi,
* ewentualne atestacje dostawcy,
* kontrola danych i uprawnień udostępnionych zewnętrznej domenie.

Nie są to lokalne dowody kernela.

---

# 4. Podstawowy model bezpieczeństwa

## Model nie jest podmiotem autoryzowanym

Model OpenAI powinien mieć status:

> **untrusted or less-trusted advanced decision component**

czyli mniej zaufanego komponentu generującego propozycje.

Podmiotem systemowym jest dopiero:

* proces harnessu,
* proces wykonawczy narzędzia,
* konkretna tożsamość usługi,
* konkretne, krótkotrwałe poświadczenie.

Model nie powinien:

* posiadać trwałych kluczy API,
* otrzymywać pełnych tokenów dostępowych,
* samodzielnie otwierać dowolnych połączeń,
* bezpośrednio wywoływać interfejsów produkcyjnych,
* nadawać sobie kolejnych capabilities.

Model może zaproponować:

```text
operation = "write_file"
target = "/workspace/result.txt"
content_digest = "..."
reason = "..."
```

ale nie może sam nadać temu żądaniu statusu autoryzowanego.

## Rdzeń formalny

Niech działanie ma postać:

```text
a = ⟨principal, run, operation, resource, parameters, impact_class⟩
```

Niech stan obserwowalności będzie wektorem:

```text
H(t) = ⟨
  API_TRACE,
  HARNESS_TRACE,
  PROCESS_IDENTITY,
  EXECUTION_COVERAGE,
  FILESYSTEM_COVERAGE,
  NETWORK_COVERAGE,
  AUDIT_HEALTH,
  PLATFORM_INTEGRITY
⟩
```

Każdy element przyjmuje jeden ze stanów:

```text
OK
DEGRADED
UNKNOWN
FAILED
```

Warunek dopuszczenia działania:

```text
PERMIT(a,t) =
    AUTHENTICATED(principal)
∧   AUTHORIZED_BY_POLICY(principal,a)
∧   CAPABILITY_BOUND_TO_RUN(a)
∧   PLATFORM_ATTESTED(t)
∧   REQUIRED_OBSERVERS_HEALTHY(a,t)
∧   PRE_EXECUTION_RECORD_DURABLE(a)
```

Dla operacji wysokiego wpływu:

```text
UNKNOWN = DENY
DEGRADED = DENY
FAILED = DENY
```

Dla operacji niskiego wpływu dopuszczalne może być działanie w ograniczonym trybie, na przykład wyłącznie odczytowym.

## Monotoniczność uprawnień względem obserwowalności

Najważniejszą własność Jarzma można zapisać następująco:

```text
jeżeli H1 jest gorsze niż H2,
to:

ALLOWED_ACTIONS(H1) ⊆ ALLOWED_ACTIONS(H2)
```

Pogorszenie obserwowalności nigdy nie może rozszerzyć przestrzeni działań.

To jest formalny odpowiednik:

```text
NO OBSERVATION → NO AUTHORITY
```

## Czas reakcji

Samo wykrywanie nie wystarcza. System musi zdążyć zatrzymać wykonanie przed skutkiem nieodwracalnym:

```text
T_detect
+ T_decide
+ T_revoke
<
T_irreversible_effect
```

Jeżeli nierówność nie jest spełniona, obserwator jest wyłącznie rejestratorem incydentu, a nie mechanizmem kontroli.

---

# 5. Architektura Jarzma

## Przepływ główny

```text
PRINCIPAL
→ TRUSTED AGENT HARNESS
→ OPENAI MODEL
→ ACTION PROPOSAL
→ INTENT NORMALIZER
→ POLICY DECISION POINT
→ PRE-EXECUTION INTENT RECORD
→ CAPABILITY BROKER
→ POLICY ENFORCEMENT POINT
→ PER-ACTION SANDBOX
→ LINUX KERNEL ENFORCEMENT
→ RESOURCE / EXTERNAL EFFECT
→ EFFECT OBSERVATION
→ EXECUTION ATTESTATION RECORD
→ VERIFIER
→ STATE UPDATE
```

Przepływ z materiału źródłowego wymagał, aby nie istniała legalna ścieżka działania omijająca sprawdzenie obserwowalności. 

W terminologii NIST decyzję podejmuje **Policy Decision Point**, a wymusza ją położony przy zasobie **Policy Enforcement Point**. PEP ma znajdować się możliwie blisko chronionego zasobu, a każda operacja ma być osobno uwierzytelniana i autoryzowana. ([NIST][10])

## Trusted Agent Harness

Harness jest zaufanym control plane’em. Odpowiada za:

* identyfikację principal,
* wywołanie modelu,
* przechowywanie stanu przebiegu,
* normalizację tool call,
* przekazanie żądania do PDP,
* odbiór wyników,
* zatrzymanie pętli,
* kontrolę delegacji między agentami.

Harness nie wykonuje sam poleceń modelu jako uprzywilejowany proces. Uruchamia osobny worker dla każdego działania albo spójnej, ograniczonej transakcji.

## Intent Normalizer

Wyjście modelu musi zostać przekształcone w jednoznaczną strukturę:

```text
operation
resource
normalized_parameters
expected_effect
maximum_effect
risk_class
required_observers
rollback_or_compensation
```

Na tym etapie następuje przejście z języka naturalnego do deterministycznego interfejsu wykonawczego.

Wolny tekst modelu nie może trafić bezpośrednio do `bash`, `sh`, PowerShella, SQL ani zewnętrznego API w profilu wysokiego zaufania.

## Policy Decision Point

PDP ocenia:

* tożsamość principal,
* typ zadania,
* politykę,
* klasyfikację efektu,
* stan obserwatorów,
* atestację platformy,
* historię delegacji,
* poziom kompletności pochodzenia,
* wymaganie zatwierdzenia przez człowieka.

## Capability Broker

Po pozytywnej decyzji wydawana jest krótkotrwała, zawężona capability. Powinna być związana co najmniej z:

```text
principal_id
run_id
action_id
operation
resource
parameter_constraints
worker_identity
cgroup_identity
expiry
non_delegable = true
```

Lepszy jest token typu proof-of-possession niż zwykły token bearer. Przejęcie samej wartości tokenu nie powinno wystarczać do użycia go z innego procesu albo środowiska.

## Policy Enforcement Point

PEP znajduje się:

* przed uruchomieniem narzędzia,
* na granicy zapisu do chronionego systemu plików,
* na bramie połączeń wychodzących,
* przed użyciem poświadczenia,
* przed zatwierdzeniem nieodwracalnego efektu.

Jedna bramka na poziomie „tool call” nie wystarcza. Narzędzie może zostać przejęte, podmienione albo wykonać więcej operacji, niż deklarowało. Dlatego ostateczna egzekucja musi odbywać się również na poziomie kernela i bramy zasobu.

---

# 6. Linux jako warstwa egzekwowania

## cgroup v2, pidfd i tożsamość wykonania

Każde działanie powinno być uruchamiane w osobnym poddrzewie cgroup v2.

```text
/agent-runs/<run_id>/<action_id>/
```

**SEE:** cgroup udostępnia stan zasobów, liczbę procesów, zdarzenia pamięciowe i presję zasobową.

**ATTRIBUTE:** identyfikator cgroup może pełnić funkcję lokalnego identyfikatora wykonania, do którego korelowane są procesy, zdarzenia BPF, audit i sieć.

**CONTROL:** można ograniczyć CPU, pamięć, liczbę procesów i I/O. `pids.max` ustanawia twardą granicę liczby procesów, a próba jej przekroczenia przez `fork()` lub `clone()` zostaje odrzucona. ([Dokumentacja Kernela Linuxa][11])

**REVOKE:** `cgroup.freeze` zatrzymuje wszystkie procesy w poddrzewie, natomiast `cgroup.kill` wysyła `SIGKILL` do wszystkich procesów w cgroup i jej potomkach. Jest to właściwy mechanizm awaryjnego zatrzymania całego działania, również przy współbieżnym tworzeniu procesów potomnych. ([Dokumentacja Kernela Linuxa][11])

**PROVE:** cgroup nie tworzy dowodu kryptograficznego. Dostarcza kontekst wykonania, który musi zostać przejęty przez chroniony kolektor i włączony do podpisanego zapisu.

`pidfd` daje stabilny uchwyt do procesu, pozwala monitorować jego zakończenie i wysyłać sygnały bez polegania wyłącznie na podatnym na ponowne użycie numerze PID. ([man7.org][12])

Tożsamość agenta nie może być utożsamiana z samym PID. Powinna być relacją:

```text
agent_instance_id
↔ run_id
↔ action_id
↔ cgroup_id
↔ pidfd
↔ executable_digest
↔ LSM_label
```

## Namespaces i izolacja kontenerowa

Mount, PID, network, IPC i inne namespaces izolują widok zasobów. Są podstawą kontenerów i umożliwiają nadanie procesom własnej przestrzeni procesów, systemu plików oraz sieci. ([man7.org][13])

**SEE:** identyfikatory namespace pozwalają ustalić, w jakim środowisku działa proces.

**ATTRIBUTE:** zdarzenia można przypisać do konkretnego network lub mount namespace.

**CONTROL:** namespaces ograniczają widoczność i dostępność zasobów.

**REVOKE:** same nie zapewniają mechanizmu odwołania; potrzebne są cgroups, pidfd, zamknięcie bramy sieciowej lub zniszczenie kontenera.

**PROVE:** nie stanowią atestacji ani dowodu integralności.

Kontener nadal korzysta z tego samego kernela co host. W modelu zagrożeń obejmującym exploity kernela operacje wysokiego wpływu powinny być przenoszone do osobnej maszyny wirtualnej lub microVM opartej na KVM. Jest to propozycja ograniczenia wspólnej Trusted Computing Base, nie gwarancja odporności na wszystkie klasy błędów.

Tworzenie user namespaces przez niezaufane workloady należy ograniczyć. Dokumentacja jądra wskazuje, że na systemach z niezaufanymi programami user namespaces mogą umożliwiać nadużywanie zasobów i komplikować kontrolę. ([Dokumentacja Kernela Linuxa][14])

## Capabilities i `no_new_privs`

Proces wykonawczy powinien rozpoczynać działanie bez capabilities, z możliwością dodania wyłącznie pojedynczych uprawnień wymaganych przez konkretne narzędzie.

`no_new_privs` jest dziedziczone przez `fork`, `clone` i `execve`, nie może zostać cofnięte i zapobiega uzyskiwaniu nowych przywilejów przez wykonanie pliku setuid, setgid lub pliku z capabilities. Nie blokuje jednak wszystkich możliwych zmian uprawnień, dlatego jest warstwą wzmacniającą, a nie samodzielnym sandboxem. ([Dokumentacja Kernela Linuxa][15])

## seccomp

Seccomp powinien ograniczać powierzchnię wywołań systemowych procesu.

**SEE:** sam seccomp nie jest systemem obserwacji, choć może generować zdarzenia i wykorzystywać user notification.

**ATTRIBUTE:** decyzja dotyczy konkretnego procesu i wywołania systemowego.

**CONTROL:** pozwala dopuścić, odrzucić, zabić proces albo skierować żądanie do nadzorcy.

**REVOKE:** istniejącego procesu nie „cofa”; reakcja polega na odrzuceniu operacji albo zakończeniu procesu.

**PROVE:** filtr i wynik jego działania nie są samodzielnie kryptograficznym dowodem.

Dokumentacja kernela jednoznacznie stwierdza, że filtrowanie syscalli nie jest sandboxem. Służy do zmniejszenia dostępnej powierzchni kernela i musi być łączone z innymi mechanizmami hardeningu oraz LSM. ([Dokumentacja Kernela Linuxa][16])

Dla profilu wysokiego zaufania należy rozważyć blokadę między innymi:

```text
bpf
perf_event_open
ptrace
mount
umount
setns
unshare
kexec
init_module
finit_module
delete_module
keyctl
```

Konkretna lista zależy od narzędzia i architektury.

### io_uring

`io_uring` tworzy dodatkową warstwę asynchronicznego wykonywania operacji. W pierwszej wersji PoC rozsądne jest odrzucenie `io_uring_setup` w profilu wysokiego zaufania, dopóki nie zostanie potwierdzone pełne pokrycie zdarzeń przez LSM, audit oraz kolektory. Jest to świadome ograniczenie zakresu, a nie twierdzenie, że `io_uring` jest samo w sobie podatnością.

Linux Audit zawiera osobny filtr dla operacji `io_uring`, co potwierdza, że wymagają one odrębnego uwzględnienia w polityce audytowej. ([man7.org][17])

## Linux Security Modules i BPF LSM

SELinux, AppArmor lub inny LSM powinien być podstawowym mechanizmem Mandatory Access Control.

**SEE:** decyzje LSM mogą generować komunikaty audytowe.

**ATTRIBUTE:** polityka wykorzystuje tożsamość procesu, label, credentials i chroniony obiekt.

**CONTROL:** LSM może dopuścić albo odrzucić operację na właściwym hooku kernela.

**REVOKE:** część polityk może być zmieniana dynamicznie, lecz istniejące uchwyty i stany wymagają oddzielnego modelu unieważniania.

**PROVE:** log decyzji LSM jest dowodem zdarzenia tylko w granicach zaufania do kernela, konfiguracji i kolektora.

BPF LSM umożliwia uprzywilejowanym administratorom podłączanie programów eBPF do hooków LSM w celu tworzenia polityk MAC i audit. ([Dokumentacja Kernela Linuxa][18])

BPF LSM jest szczególnie przydatny do:

* oznaczania zdarzeń `run_id` i `action_id`,
* polityk związanych z cgroup,
* kontroli wybranych operacji procesowych, plikowych i sieciowych,
* korelacji PEP z rzeczywistym skutkiem kernela.

Nie należy jednak twierdzić, że „eBPF jest Jarzmem”. Program BPF może zawierać błąd, może zostać podmieniony przez uprzywilejowany podmiot i zwiększa Trusted Computing Base. Dostęp workloadu do `bpf()` i capabilities administracyjnych musi być zablokowany.

## Landlock

Landlock umożliwia również nieuprzywilejowanym procesom dobrowolne ograniczenie własnego dostępu. ([Dokumentacja Kernela Linuxa][19])

W architekturze Jarzma polityki Landlock powinien instalować **zaufany launcher przed uruchomieniem niezaufanego kodu**, a nie sam model lub skrypt.

W Linux 7.1 Landlock może rejestrować odmowy dostępu, przypisywać je do domen oraz ograniczać prawa do systemu plików, wybrane operacje TCP, sygnały i abstrakcyjne sockety UNIX. ([Dokumentacja Kernela Linuxa][20])

**SEE:** głównie odmowy i stan domeny.

**ATTRIBUTE:** identyfikator domeny, PID jej twórcy, UID i blokujący typ prawa.

**CONTROL:** addytywne zawężanie uprawnień do plików, sieci i wybranych IPC.

**REVOKE:** polityka jest restrykcyjna i dziedziczona; nie służy do dynamicznego przywracania praw.

**PROVE:** log odmowy nie dowodzi kompletności wszystkich operacji dozwolonych.

Landlock jest warstwą defense-in-depth, nie zamiennikiem centralnego PDP/PEP.

## IPE, IMA, EVM, fs-verity, dm-verity i TPM

Ta grupa mechanizmów odpowiada nie za to, **co agent chce zrobić**, ale za to, **jaki kod i konfiguracja są dopuszczone do wykonania**.

### IPE

Integrity Policy Enforcement podejmuje lokalne decyzje egzekucyjne na podstawie niezmiennych właściwości źródła pliku, między innymi dm-verity i fs-verity. Może dopuścić wykonanie konkretnego pliku według digestu albo pliku posiadającego prawidłową sygnaturę fs-verity. ([Dokumentacja Kernela Linuxa][21])

**SEE:** decyzje IPE i informacje o naruszeniu polityki.

**ATTRIBUTE:** plik, proces, hook, reguła i digest polityki.

**CONTROL:** dopuszczenie albo odrzucenie wykonania lub mapowania kodu.

**REVOKE:** zmiana polityki może odebrać możliwość kolejnego wykonania; nie usuwa kodu już wykonującego się w pamięci.

**PROVE:** dostarcza silnego komponentu integralności, lecz jego log nadal wymaga chronionego łańcucha dowodowego.

IPE ma istotne ograniczenie: nie potrafi zweryfikować anonimowej pamięci wykonywalnej ani kodu generowanego przez JIT. ([Dokumentacja Kernela Linuxa][21])

Jest to szczególnie ważne dla:

* środowisk JavaScript,
* maszyn JVM z JIT,
* bibliotek generujących trampoliny,
* części runtime’ów AI,
* dynamicznie generowanego kodu.

### `AT_EXECVE_CHECK`

Linux 7.1 udostępnia `AT_EXECVE_CHECK` oraz securebits przeznaczone dla interpreterów skryptów i linkerów dynamicznych. Interpreter może poprosić kernel o ocenę, czy plik przekazany pośrednio do wykonania zostałby dopuszczony przez politykę kernela. Użycie deskryptora z `AT_EMPTY_PATH` ogranicza ryzyko TOCTOU między sprawdzeniem ścieżki a wykonaniem. ([Dokumentacja Kernela Linuxa][22])

Mechanizm wymaga jednak świadomej integracji interpretera. Zwykłe uruchomienie Pythona nie gwarantuje automatycznie, że każdy importowany lub interpretowany fragment został objęty taką kontrolą.

### fs-verity i dm-verity

fs-verity chroni pojedyncze pliki z użyciem drzewa Merkle’a i ponownie sprawdza dane przy wczytywaniu stron. dm-verity zapewnia integralność całego urządzenia blokowego lub obrazu. fs-verity może współpracować z IMA albo IPE. ([Dokumentacja Kernela Linuxa][23])

### IMA i EVM

IMA powinno odpowiadać za pomiary i ewentualną appraisal plików. EVM może chronić integralność istotnych rozszerzonych atrybutów bezpieczeństwa. IPE powinno odpowiadać za lokalne egzekwowanie polityki integralności. Dokumentacja IPE celowo rozdziela pomiar i atestację od lokalnego egzekwowania polityki. ([Dokumentacja Kernela Linuxa][24])

### TPM i atestacja

TPM może zakotwiczyć pomiary bootowania i platformy. Nie dowodzi jednak, że model podjął poprawną decyzję.

W terminologii IETF RATS:

```text
ATTESTER
→ EVIDENCE
→ VERIFIER
→ ATTESTATION RESULT
→ RELYING PARTY
→ AUTHORIZATION DECISION
```

Relying Party powinien domyślnie nie ufać Attesterowi, dopóki nie otrzyma autentycznego wyniku atestacji spełniającego politykę. ([RFC Editor][25])

## eBPF tracing, tracepoints, perf, kprobes, uprobes, fentry i fexit

Te mechanizmy należą głównie do płaszczyzny obserwacji.

**Tracepoints** są preferowane, gdy istnieje właściwy stabilny punkt zdarzeniowy.

**fentry/fexit** są wydajnym sposobem obserwowania wejścia i wyjścia z funkcji kernela przy wykorzystaniu BTF.

**kprobes** pozwalają obserwować funkcje kernela, lecz są bardziej zależne od implementacji i wersji.

**uprobes** pozwalają obserwować funkcje użytkowe, ale ich poprawność zależy od konkretnego pliku binarnego, symboli i optymalizacji.

**perf** dostarcza liczniki oraz próbki wykonania, lecz nie powinien być głównym źródłem dowodowym dla każdej akcji.

**SEE:** bardzo dobre pokrycie zdarzeń kernela i użytkowych.

**ATTRIBUTE:** możliwe przez PID, TGID, UID, cgroup ID, namespace i credentials.

**CONTROL:** tracing sam nie kontroluje. Kontrola wymaga BPF LSM, cgroup BPF, seccomp albo innego PEP.

**REVOKE:** brak samodzielnego mechanizmu.

**PROVE:** surowy event BPF nie jest dowodem odpornym na przejęcie hosta. Dopiero chroniony kolektor, numeracja, łańcuch hashy i zewnętrzny podpis tworzą sensowny artefakt audytowy.

## Linux Audit

Audit powinien rejestrować przede wszystkim:

* decyzje autoryzacyjne,
* zmiany credentials,
* wykonanie kodu,
* naruszenia MAC,
* modyfikacje chronionych zasobów,
* zmianę polityki,
* utratę zdarzeń.

Audit posiada licznik utraconych rekordów i backlog. Konfigurację można zablokować trybem `-e 2`, a failure mode może być ustawiony od trybu cichego przez `printk` aż po panic. ([man7.org][17])

Panic całego hosta nie jest zawsze właściwym fail-closed. Dla większości systemów agentowych lepszą reakcją jest:

```text
AUDIT LOSS
→ BLOCK NEW HIGH-IMPACT ACTIONS
→ FREEZE ACTIVE HIGH-IMPACT CGROUPS
→ REVOKE CAPABILITIES
→ ALERT
```

Pełny audit wszystkich syscalli nie jest właściwym rozwiązaniem. Reguły syscall są oceniane dla każdego wywołania, a nadmiar reguł pogarsza wydajność. ([man7.org][17])

## fanotify i inotify

`inotify` jest przede wszystkim źródłem powiadomień i nie powinien pełnić funkcji PEP.

`fanotify` potrafi generować zarówno zdarzenia informacyjne, jak i permission events, dla których proces użytkowy może odpowiedzieć `FAN_ALLOW` albo `FAN_DENY`. ([man7.org][26])

Nie powinien jednak być jedynym monitorem referencyjnym. Zamknięcie deskryptora fanotify powoduje, że oczekujące decyzje permission zostają dopuszczone, co jest niepożądaną semantyką dla krytycznego fail-closed. ([man7.org][26])

fanotify jest użytecznym obserwatorem i dodatkowym gate’em dla konkretnych klas plików, ale nie zastępuje LSM.

## Sieć: network namespace, netfilter, cgroup BPF i egress proxy

Każdy worker powinien działać w oddzielnym network namespace.

Domyślna polityka:

```text
EGRESS = DENY
```

Dopuszczenie połączenia powinno wymagać:

* autoryzowanej destination class,
* konkretnego hosta lub usługi,
* ograniczenia portu i protokołu,
* capability związanej z `action_id`,
* przejścia przez kontrolowany egress proxy.

Netfilter lub cgroup BPF mogą kontrolować połączenia na poziomie sieciowym. Nie rozumieją jednak automatycznie semantyki zaszyfrowanego żądania HTTPS. Kernel może widzieć proces, socket, adres, port i ilość danych, ale nie musi wiedzieć, czy żądanie oznacza „pobierz status”, czy „usuń konto”.

Dlatego zewnętrzne API wysokiego wpływu powinny przechodzić przez bramę aplikacyjną, która:

1. terminuję kontrolowane połączenie,
2. rozpoznaje operację aplikacyjną,
3. sprawdza capability,
4. dodaje `run_id` i `action_id`,
5. zapisuje żądanie przed wysłaniem,
6. rejestruje odpowiedź i identyfikator transakcji.

## PSI, memory accounting i scheduler telemetry

Pressure Stall Information mierzy presję CPU, pamięci i I/O zarówno globalnie, jak i per cgroup. ([Dokumentacja Kernela Linuxa][27])

PSI nie jest sygnałem naruszenia bezpieczeństwa. Jest sygnałem zdrowia wykonania i obserwacji.

Przykładowa kaskada:

```text
MEMORY PRESSURE
→ opóźnienie kolektora
→ wzrost kolejki zdarzeń
→ utrata eventów
→ utrata kompletności pochodzenia
→ ograniczenie autoryzacji
```

Scheduler tracepoints mogą ustalić, czy worker został zagłodzony, zamrożony lub nietypowo obciążony. Nie należy jednak przechowywać pełnej telemetrii schedulerowej dla każdego przebiegu produkcyjnego. Powinna być uruchamiana selektywnie albo agregowana.

## KVM i mocniejsza granica izolacji

Dla działań:

* uruchamiających niezaufany kod,
* kompilujących i wykonujących dostarczone źródła,
* instalujących zależności,
* przetwarzających tajne dane,
* posiadających dostęp produkcyjny,

zalecana jest osobna microVM oparta na KVM.

Wtedy:

```text
HOST CONTROL PLANE
≠ GUEST EXECUTION KERNEL
```

Przejęcie kernela gościa nie musi oznaczać bezpośredniego przejęcia hosta. KVM również nie jest absolutną granicą, ale zmniejsza wspólną Trusted Computing Base w porównaniu ze zwykłym kontenerem.

---

# 7. Integracja z OpenAI

## Tryb ścisły

Dla Jarzma o silnych właściwościach należy używać:

* Responses API,
* wybranego i możliwie wersjonowanego modelu,
* własnych function tools,
* własnego lokalnego runtime,
* własnego harnessu,
* lokalnego PEP,
* lokalnych poświadczeń krótkotrwałych.

Alias `gpt-5.6` nie powinien być traktowany jako niezmienna identyfikacja modelu, ponieważ obecnie kieruje do Sol. Jeżeli konto i API udostępniają wersjonowany snapshot, należy go przypiąć. Jeżeli nie, receipt powinien zapisywać identyfikator żądany, identyfikator zwrócony oraz fakt, że dokładny snapshot po stronie dostawcy nie został kryptograficznie potwierdzony. OpenAI opisuje snapshoty jako sposób utrzymania stałego zachowania konkretnej wersji modelu. ([OpenAI Developers][28])

## Tracing OpenAI

Agents SDK może emitować strukturalne trace’y zawierające przebieg, wywołania modelu, tool calls, handoffs, guardrails i własne spany. ([OpenAI Developers][29])

Należy je klasyfikować jako:

```text
PROVIDER/API TELEMETRY
```

a nie:

```text
KERNEL ATTESTATION
```

Trace SDK może zostać błędnie skonfigurowany, wyłączony lub nie obejmować skutków poza SDK.

Dodatkowo tool guardrails Agents SDK dotyczą function tools, ale nie obejmują samego wywołania handoff. Nie wolno więc utożsamiać ich z niepomijalnym monitorem referencyjnym. ([OpenAI GitHub Pages][30])

## Narzędzia hostowane

Hosted shell, hosted code interpreter, hosted computer use i zdalny MCP należą do zewnętrznej domeny wykonania.

Dla działania wysokiego wpływu istnieją dwa poprawne rozwiązania:

```text
A. WYŁĄCZYĆ HOSTED TOOL
   i wykonać operację lokalnie pod kontrolą Jarzma

albo

B. TRAKTOWAĆ HOSTED TOOL JAK ZEWNĘTRZNĄ USŁUGĘ
   i wymagać osobnego wyniku atestacji lub poświadczenia
```

Lokalny kernel nie może dowieść, jakie syscalle wykonał kontener hostowany przez OpenAI.

## Pamięć i stan

Stan OpenAI, pamięć lokalna agenta, system retrieval i baza wektorowa muszą być traktowane oddzielnie.

Każdy zapis pamięci powinien mieć:

```text
source_id
source_trust_class
writer
write_time
content_digest
classification
retention
authorization
derived_from
```

Przy późniejszym użyciu receipt zapisuje identyfikatory rekordów, które zostały włączone do kontekstu.

Pamięć nie może samodzielnie podnosić własnego poziomu zaufania:

```text
UNTRUSTED MEMORY
≠ POLICY
≠ CREDENTIAL
≠ AUTHORITY
```

---

# 8. „No provenance → no effect” wymaga protokołu transakcyjnego

W materiale źródłowym pojawia się zasada:

```text
NO PROVENANCE → NO EFFECT
```



W dosłownym brzmieniu nie da się jej zagwarantować wyłącznie przez zapis tworzony po wykonaniu. Jeżeli proces najpierw wysłał przelew, usunął dane albo wysłał wiadomość, a następnie nie udało się zapisać receipt, skutek już nastąpił.

Technicznie zasadę trzeba wdrożyć jako:

```text
INTENT
→ DURABLE PREPARE RECORD
→ AUTHORIZATION
→ STAGED EXECUTION
→ COMMIT GATE
→ EXTERNAL EFFECT
→ EXTERNAL ACKNOWLEDGEMENT
→ FINAL RECEIPT
```

Jest to połączenie:

* write-ahead logging,
* prepare/commit,
* transactional outbox,
* idempotency key,
* poświadczenia odpowiedzi zewnętrznej.

Dla zapisu do pliku można najpierw utworzyć plik w staging area, obliczyć digest, sprawdzić politykę i dopiero wykonać atomowe `rename()`.

Dla wysyłki e-maila brama może najpierw utrwalić treść i decyzję, a dopiero następnie wydać polecenie wysyłki z idempotency key.

Dla zewnętrznego API bez transakcji, idempotencji ani potwierdzenia nie można zapewnić pełnego „no provenance → no effect”. Można jedynie ograniczyć ryzyko i zarejestrować próbę oraz odpowiedź.

---

# 9. Execution Attestation Record

Material źródłowy poprawnie rozróżnia telemetrykę, log, ślad, stan, interpretację i dowód. Nie są to synonimy. 

Minimalny rekord wykonania powinien mieć następującą strukturę:

```text
execution_record = {
  schema_version,

  run_id,
  action_id,
  parent_action_id,
  previous_record_hash,

  principal_id,
  agent_instance_id,
  delegation_chain,

  model_requested_id,
  model_reported_id,
  openai_response_id,
  model_configuration_digest,

  system_instruction_digest,
  user_input_digest,
  context_reference_ids,
  memory_record_ids,

  normalized_operation,
  normalized_resource,
  parameter_digest,
  impact_class,

  policy_id,
  policy_digest,
  policy_decision,
  approval_reference,

  capability_id,
  capability_digest,
  capability_constraints,
  capability_expiry,

  host_identity,
  boot_attestation_reference,
  kernel_release,
  kernel_config_digest,

  cgroup_id,
  namespace_ids,
  pidfd_reference,
  uid_gid,
  capability_sets,
  lsm_label,

  executable_digest,
  container_or_vm_digest,
  dependency_digests,

  filesystem_effects,
  network_effects,
  process_effects,
  resource_effects,

  external_transaction_id,
  result_digest,

  observer_health,
  audit_lost_counter,
  bpf_drop_counter,
  collector_sequence_range,

  realtime_started,
  realtime_finished,
  monotonic_started,
  monotonic_finished,

  attestation_references,
  signer_identity,
  signature
}
```

Nie należy zapisywać tajnych poświadczeń ani wymagać dostępu do ukrytego toku rozumowania modelu. Provenance ma obejmować obserwowalne wejścia, wyjścia, tool calls, politykę i skutki, a nie spekulację na temat wewnętrznych stanów sieci neuronowej.

Rekord może być reprezentowany jako:

* in-toto Statement z własnym predicate,
* graf W3C PROV,
* podpisany CBOR lub JSON,
* hash-chain,
* EAT dla atestacji platformowej.

RATS rozdziela Evidence generowane przez Attestera od Attestation Result generowanego przez Verifier. Ta separacja powinna zostać zachowana: worker nie może sam ogłosić się godnym zaufania. ([RFC Editor][25])

---

# 10. Dynamiczna degradacja uprawnień

Jarzmo powinno działać jako maszyna stanów:

```text
NORMAL
→ DEGRADED
→ RESTRICTED
→ FROZEN
→ REVOKED
```

## NORMAL

Wszystkie wymagane obserwatory działają, atestacja jest aktualna, brak utraty zdarzeń. Agent otrzymuje przestrzeń działań zgodną z polityką.

## DEGRADED

Jeden z niekrytycznych kanałów jest niepełny, na przykład chwilowo brak trace’u dostawcy API.

Reakcja:

```text
DENY NEW HIGH-IMPACT ACTIONS
ALLOW BOUNDED READ-ONLY OPERATIONS
PRESERVE CURRENT STATE
REQUEST RE-ATTESTATION
```

## RESTRICTED

Utracono ważną część pochodzenia, ale tożsamość procesu i lokalna kontrola nadal działają.

Reakcja:

```text
NO NEW CREDENTIALS
NO EXTERNAL WRITE
NO DELEGATION
LOCAL READ-ONLY ONLY
```

## FROZEN

Nie można wiarygodnie ustalić ciągłości działania lub pojawił się sygnał naruszenia.

Reakcja:

```text
cgroup.freeze = 1
REVOKE TOKENS
BLOCK EGRESS
PRESERVE FILESYSTEM SNAPSHOT
COLLECT FORENSIC STATE
```

## REVOKED

Integralność platformy, monitora albo control plane’u została naruszona.

Reakcja:

```text
cgroup.kill = 1
DESTROY EPHEMERAL CREDENTIALS
INVALIDATE RUN
REQUIRE CLEAN RESTART AND RE-ATTESTATION
```

Nie każda utrata telemetrii powinna powodować panic całego hosta. Reakcja musi być proporcjonalna do klasy wpływu działania.

---

# 11. Testy falsyfikujące

## Prompt injection, indirect prompt injection i zatrucie pamięci

```text
ATTACK
→ niezaufane dane zawierają instrukcję

LOST ASSUMPTION
→ dane zostały pomylone z polityką lub poleceniem

OBSERVABLE SIGNAL
→ model proponuje operację niezgodną z deklarowanym celem

POLICY RESPONSE
→ wyjście modelu pozostaje action proposal
→ PDP ocenia operację niezależnie od argumentacji modelu

AUTHORITY DEGRADATION
→ brak nowej capability

CONTAINMENT
→ brak uruchomienia workera

RECEIPT
→ zapis odrzuconej propozycji i reguły polityki
```

Dla pamięci dodatkowo trzeba oznaczyć rekord jako niezaufany i uniemożliwić mu zmianę polityki albo klasy autorytetu.

## Tool confusion i nadużycie delegowanej władzy

```text
ATTACK
→ agent wybiera narzędzie o szerszych skutkach niż deklarowane

LOST ASSUMPTION
→ nazwa narzędzia została utożsamiona z jego rzeczywistym efektem

SIGNAL
→ rozbieżność tool call ↔ syscalls ↔ network/filesystem effects

RESPONSE
→ capability ograniczona do operacji, zasobu i action_id

CONTAINMENT
→ LSM / egress PEP blokuje nadmiarowy efekt

RECOVERY
→ worker zostaje zamrożony lub zabity
```

## Agent-to-agent authority laundering

```text
ATTACK
→ agent A przekazuje agentowi B argumenty lub token

LOST ASSUMPTION
→ delegacja została uznana za dziedziczną

RESPONSE
→ capability jest non-delegable
→ związana z konkretnym workerem i cgroup
→ agent B musi uzyskać nową decyzję PDP
```

## Nieoczekiwany proces potomny i dziedziczenie credentials

```text
ATTACK
→ narzędzie tworzy potomka albo uruchamia inną binarkę

SIGNAL
→ sched_process_fork / exec / credential transition

CONTROL
→ pids.max
→ seccomp
→ IPE
→ MAC
→ capabilities drop

CONTAINMENT
→ cały potomek pozostaje w tym samym poddrzewie cgroup

REVOKE
→ cgroup.kill
```

## Container escape

Kontener nie jest pełnym zabezpieczeniem przed exploitem kernela. Działania wysokiego ryzyka powinny działać w osobnym kernelu KVM. Jeżeli założeniem systemu jest odporność na dowolne przejęcie lokalnego kernela, zwykły kontener falsyfikuje tę tezę.

## Nieobserwowana ścieżka sieciowa

```text
ATTACK
→ proces omija egress proxy

SIGNAL
→ socket utworzony poza dozwolonym flow

CONTROL
→ netns default deny
→ netfilter / cgroup BPF
→ brak raw sockets
→ brak bezpośrednich credentials

FALSIFICATION
→ jeżeli istnieje dozwolona trasa do efektu poza PEP,
   complete mediation nie jest spełniona
```

## TOCTOU i race condition

Kontrole oparte wyłącznie na ścieżkach są niewystarczające. Należy używać deskryptorów, `openat2`, atomowych operacji, digestów i — dla wykonywalności — `AT_EXECVE_CHECK` z `AT_EMPTY_PATH`. ([Dokumentacja Kernela Linuxa][22])

## Telemetry loss

```text
ATTACK / FAILURE
→ przepełnienie kolejki audit albo BPF

SIGNAL
→ audit.lost > 0
→ sequence gap
→ ring-buffer drop counter > 0

RESPONSE
→ observation_health = DEGRADED lub FAILED

AUTHORITY DEGRADATION
→ brak nowych operacji wysokiego wpływu

CONTAINMENT
→ freeze aktywnych workerów wysokiego ryzyka
```

Brak informacji o utracie zdarzeń byłby sam w sobie błędem projektu.

## BPF tampering i log manipulation

Workload nie może posiadać `CAP_BPF`, `CAP_PERFMON`, `CAP_SYS_ADMIN` ani dostępu do map i programów kontrolnych.

Zdarzenia powinny być wysyłane poza namespace workera i okresowo zakotwiczane w łańcuchu hashy podpisywanym przez oddzielny podmiot.

Jeżeli ten sam przejęty kernel:

* wykonuje operację,
* generuje event,
* podpisuje event,
* sam siebie weryfikuje,

to otrzymujemy dowód samozgłoszony przez skompromitowany TCB. Zewnętrzny Verifier i atestacja ograniczają problem, lecz nie eliminują błędów typu runtime kernel exploit.

## Runtime, model lub tool substitution

```text
EXPECTED
→ executable_digest = X
→ model_snapshot = Y
→ policy_digest = Z

OBSERVED
→ executable_digest ≠ X
   albo model identity nierozstrzygnięta
   albo policy_digest ≠ Z

RESPONSE
→ DENY
→ RE-ATTEST
```

IPE/fs-verity mogą kontrolować lokalną binarkę. Tożsamość zdalnego modelu wymaga twierdzenia dostawcy; lokalny kernel nie może jej sam ustalić.

## Stale policy

Każda decyzja musi zawierać digest i wersję polityki. Capability powinna wygasać szybko i nie może przeżyć krytycznej zmiany polityki.

## Crash, restart i częściowa partycja sieciowa

Po restarcie proces nie może automatycznie odzyskać dawnych capabilities.

```text
RESTART
→ RE-ATTEST PLATFORM
→ RECONSTRUCT RUN
→ INVALIDATE OLD TOKENS
→ REAUTHORIZE PENDING ACTIONS
```

W czasie utraty połączenia z PDP nie należy wydawać nowych uprawnień wysokiego wpływu.

## Przejęty observer lub control plane

To najsilniejszy kontrprzykład.

Jeżeli atakujący przejmie jednocześnie:

* PDP,
* PEP,
* kolektor,
* klucz podpisujący,
* rejestr dowodów,

Jarzmo może wytwarzać poprawnie podpisaną fikcję.

Dlatego wymagane są:

* separacja obowiązków,
* odrębna tożsamość podpisująca,
* zewnętrzny Verifier,
* append-only storage,
* atestacja platformowa,
* możliwie drugi niezależny kanał obserwacyjny.

Nie eliminuje to całego ryzyka, ale usuwa pojedynczy samopotwierdzający się punkt zaufania.

---

# 12. Minimalna wystarczająca obserwowalność

Nie należy śledzić każdego odczytu, każdej instrukcji CPU i każdego syscalla. Taki system byłby drogi, trudny do interpretacji i sam mógłby powodować utratę zdarzeń.

Bez próbkowania powinny być zapisywane:

```text
run start / end
model request / response identity
tool proposal
normalized action
policy decision
capability issue / use / revoke
worker create / exec / exit
credential transition
LSM / seccomp / IPE denial
protected filesystem write
network connection through egress PEP
external irreversible effect
cgroup freeze / kill
policy or collector change
audit or BPF event loss
attestation result
```

Próbkowane albo agregowane mogą być:

```text
scheduler activity
CPU profiles
low-risk reads
routine memory statistics
noncritical function traces
```

Nigdy nie należy próbkować:

* decyzji autoryzacyjnych,
* wydania credentials,
* operacji wysokiego wpływu,
* sygnałów utraty integralności,
* finalnych commitów efektów.

Metryki PoC powinny obejmować:

```text
p50 / p95 / p99 policy-gate latency
events per second
collector CPU and memory
bytes of evidence per action
audit lost events
BPF lost events
action-to-cgroup attribution rate
effect-to-action attribution rate
time to freeze
time to kill
false deny rate
false permit rate
```

Najważniejszym kryterium nie jest zerowy narzut, lecz:

```text
T_revoke < T_irreversible_effect
```

oraz:

```text
HIGH_IMPACT_EFFECT_ATTRIBUTION = 100%
```

w kontrolowanym zestawie testowym.

---

# 13. Minimalny Proof of Concept

## Środowisko

```text
Linux 7.1.8
UEFI Secure Boot
TPM 2.0
cgroup v2
SELinux albo AppArmor
BPF LSM
Landlock
seccomp
audit
IMA/IPE
fs-verity lub dm-verity
oddzielny network namespace per worker
```

Wymagane opcje kernela należy potwierdzić w konkretnym buildzie. Zestaw powinien obejmować co najmniej odpowiedniki:

```text
CONFIG_AUDIT
CONFIG_AUDITSYSCALL
CONFIG_BPF
CONFIG_BPF_SYSCALL
CONFIG_BPF_LSM
CONFIG_CGROUPS
CONFIG_CGROUP_BPF
CONFIG_SECCOMP
CONFIG_SECCOMP_FILTER
CONFIG_SECURITY
CONFIG_SECURITY_LANDLOCK
CONFIG_SECURITY_IPE
CONFIG_INTEGRITY
CONFIG_IMA
CONFIG_IMA_APPRAISE
CONFIG_EVM
CONFIG_FS_VERITY
CONFIG_DM_VERITY
CONFIG_PSI
CONFIG_NAMESPACES
```

## Model i API

```text
OpenAI Responses API
model: gpt-5.6-sol albo dostępny snapshot
hosted tools: disabled
remote MCP: disabled
custom function tools: enabled
local shell: początkowo disabled
```

Na pierwszym etapie należy udostępnić tylko dwa narzędzia:

```text
read_workspace_file
write_workspace_file
```

Następnie dodać:

```text
controlled_http_get
```

Nie rozpoczynać od ogólnego shella.

## Proces działania

```text
1. Harness tworzy run_id.

2. Model proponuje function call.

3. Intent Normalizer waliduje schemat i normalizuje ścieżkę.

4. PDP ustala klasę ryzyka i wymagany stan obserwatorów.

5. System zapisuje pre-execution intent record.

6. Broker wydaje jednorazową capability.

7. Launcher tworzy:
   cgroup
   namespaces
   filesystem view
   Landlock domain
   seccomp filter
   LSM context

8. Worker wykonuje pojedynczą operację.

9. eBPF, audit i PEP emitują zdarzenia.

10. Efekt jest porównywany z deklarowanym zakresem.

11. Attester tworzy podpisany execution record.

12. Verifier sprawdza:
    podpis
    hash-chain
    policy digest
    platform attestation
    kompletność wymaganych observerów

13. Harness przyjmuje wynik albo degraduje stan.
```

## Testy akceptacyjne

PoC przechodzi wyłącznie wtedy, gdy:

```text
każdy zapis do workspace ma action_id

każde action_id ma dokładnie jedną decyzję PDP

każdy worker ma własny cgroup i stabilny pidfd

proces nie może zapisać poza dozwolonym katalogiem

proces nie może utworzyć nieautoryzowanego połączenia

proces potomny pozostaje w tym samym cgroup

zmiana binarki powoduje odmowę wykonania

utrata audit/BPF powoduje degradację uprawnień

cgroup.freeze zatrzymuje działanie przed commit gate

cgroup.kill usuwa cały procesowy podgraf działania

receipt po zmianie dowolnego pola nie przechodzi weryfikacji
```

## Warunki falsyfikacji

Projekt zostaje obalony, jeżeli zostanie znaleziony choć jeden powtarzalny przypadek, w którym:

```text
HIGH-IMPACT EFFECT
∧ brak przejścia przez PEP
```

albo:

```text
EFFECT
∧ brak wiarygodnego action_id
```

albo:

```text
OBSERVABILITY FAILED
∧ system nadal wydaje nowe high-impact capabilities
```

albo:

```text
REVOKE REQUESTED
∧ proces może kontynuować do nieodwracalnego efektu
```

---

# 14. Co można zbudować bez patchowania kernela

Bez modyfikacji Linux 7.1.8 można zrealizować:

* oddzielny harness i execution plane,
* PDP i PEP,
* jednorazowe capabilities,
* cgroup per action,
* namespaces,
* seccomp,
* Landlock,
* SELinux/AppArmor,
* BPF LSM,
* eBPF tracing,
* Audit,
* IPE/IMA/fs-verity/dm-verity,
* TPM-backed platform attestation,
* freeze/kill,
* egress proxy,
* podpisane execution records,
* graf W3C PROV,
* zewnętrzny Verifier.

To wystarcza do wartościowego PoC i do silnej kontroli lokalnych efektów.

# 15. Co wymagałoby rozwoju kernela albo standardów

Dojrzała wersja skorzystałaby z:

1. **Pierwszoklasowego identyfikatora wykonania** propagowanego przez procesy, LSM, audit, sieć i cgroups zamiast korelacji wielu identyfikatorów użytkowych.

2. **Standaryzowanego wiązania capability z cgroup, procesem i action ID** na poziomie kernela lub systemowego brokera credentials.

3. **Lepszej kontroli interpreterów i kodu JIT**, ponieważ IPE nie obejmuje anonimowej pamięci wykonywalnej, a `AT_EXECVE_CHECK` wymaga współpracy runtime’u.

4. **Atestowanego kanału ciągłości telemetrii**, który pozwalałby zewnętrznemu Verifierowi odróżnić pełny strumień od strumienia selektywnie ocenzurowanego przez przejęty host.

5. **Standardu dostawcy modeli dla model execution attestation**, obejmującego dokładną wersję modelu, konfigurację, identyfikatory przebiegu i narzędziowe efekty hostowane.

6. **Kryptograficznie wiązanego identyfikatora API → local action → kernel execution → external transaction**.

Największe braki znajdują się zatem nie tylko w kernelu, lecz na styku:

```text
REMOTE MODEL
↔ LOCAL HARNESS
↔ LOCAL PROCESS
↔ EXTERNAL EFFECT
```

---

# Konkluzja

## Najsilniejsza teza

Można strukturalnie powiązać uprawnienie do działania z jakością obserwowalności, integralnością platformy i kompletnością pochodzenia. Linux posiada wystarczające prymitywy, aby lokalne działania modelu przechodziły przez niepomijalny PEP, były izolowane, przypisane do konkretnego wykonania, zatrzymywalne i objęte podpisanym zapisem.

## Najsilniejsza kontrteza

System obserwacyjny nie może sam z siebie zagwarantować własnej prawdziwości. Jeżeli wspólna Trusted Computing Base obejmująca kernel, PEP, kolektor i klucz podpisujący zostanie przejęta, może generować spójne, lecz fałszywe świadectwa. Ponadto lokalny Linux nie widzi wnętrza zdalnego modelu ani hostowanych narzędzi.

## Najbardziej prawdopodobne miejsce utraty kontroli

Nie jest nim sam model ani pojedynczy syscall. Jest nim przejście:

```text
MODEL TOOL CALL
→ LOKALNA AUTORYZACJA
→ RZECZYWISTY PROCES
→ RZECZYWISTY EFEKT
```

To tutaj semantyczna propozycja modelu musi zostać jednoznacznie związana z podmiotem systemowym, capability, cgroup, polityką i skutkiem.

## Ostateczna definicja

**Jarzmo obserwowalności nie jest systemem, który widzi wszystko.**

Jest to:

> **niepomijalna architektura kontroli, w której zakres dozwolonych efektów agenta jest funkcją aktualnego stanu obserwowalności, integralności platformy i weryfikowalnego pochodzenia wykonania.**

W formie najkrótszej:

```text
MODEL MOŻE PROPONOWAĆ.

HARNESS MOŻE PLANOWAĆ.

PDP MOŻE AUTORYZOWAĆ.

PEP I KERNEL MOGĄ WYKONAĆ.

VERIFIER MOŻE UZNAĆ WYNIK.

UTRATA OBSERWOWALNOŚCI
NIE MOŻE ZWIĘKSZYĆ WŁADZY.
```

A więc technicznie:

```text
NO REQUIRED OBSERVATION
→ NO NEW AUTHORITY

NO VALID PRE-EXECUTION PROVENANCE
→ NO COMMIT

LOSS OF EVIDENCE CONTINUITY
→ DEGRADE, FREEZE OR REVOKE

NO COMPLETE MEDIATION
→ NO CLAIM OF CONTROL
```

[1]: https://www.kernel.org/ "https://www.kernel.org/"
[2]: https://openai.com/index/gpt-5-6/ "https://openai.com/index/gpt-5-6/"
[3]: https://developers.openai.com/api/docs/guides/migrate-to-responses "https://developers.openai.com/api/docs/guides/migrate-to-responses"
[4]: https://csrc.nist.gov/glossary/term/reference_monitor "https://csrc.nist.gov/glossary/term/reference_monitor"
[5]: https://shemesh.larc.nasa.gov/fm/papers/DASC2024-SWDMC-draft.pdf "https://shemesh.larc.nasa.gov/fm/papers/DASC2024-SWDMC-draft.pdf"
[6]: https://www.w3.org/TR/prov-dm/ "https://www.w3.org/TR/prov-dm/"
[7]: https://github.com/in-toto/attestation "https://github.com/in-toto/attestation"
[8]: https://developers.openai.com/api/docs/guides/agents/sandboxes "https://developers.openai.com/api/docs/guides/agents/sandboxes"
[9]: https://developers.openai.com/api/docs/guides/tools-shell "https://developers.openai.com/api/docs/guides/tools-shell"
[10]: https://tsapps.nist.gov/publication/get_pdf.cfm?pub_id=930420 "https://tsapps.nist.gov/publication/get_pdf.cfm?pub_id=930420"
[11]: https://docs.kernel.org/admin-guide/cgroup-v2.html "https://docs.kernel.org/admin-guide/cgroup-v2.html"
[12]: https://man7.org/linux/man-pages/man2/pidfd_open.2.html "https://man7.org/linux/man-pages/man2/pidfd_open.2.html"
[13]: https://man7.org/linux/man-pages/man7/namespaces.7.html "https://man7.org/linux/man-pages/man7/namespaces.7.html"
[14]: https://docs.kernel.org/admin-guide/namespaces/resource-control.html "https://docs.kernel.org/admin-guide/namespaces/resource-control.html"
[15]: https://docs.kernel.org/userspace-api/no_new_privs.html "https://docs.kernel.org/userspace-api/no_new_privs.html"
[16]: https://docs.kernel.org/userspace-api/seccomp_filter.html "https://docs.kernel.org/userspace-api/seccomp_filter.html"
[17]: https://man7.org/linux/man-pages/man8/auditctl.8.html "https://man7.org/linux/man-pages/man8/auditctl.8.html"
[18]: https://docs.kernel.org/bpf/prog_lsm.html "https://docs.kernel.org/bpf/prog_lsm.html"
[19]: https://docs.kernel.org/userspace-api/landlock.html "https://docs.kernel.org/userspace-api/landlock.html"
[20]: https://docs.kernel.org/7.1/admin-guide/LSM/landlock.html "https://docs.kernel.org/7.1/admin-guide/LSM/landlock.html"
[21]: https://docs.kernel.org/7.1/admin-guide/LSM/ipe.html "https://docs.kernel.org/7.1/admin-guide/LSM/ipe.html"
[22]: https://docs.kernel.org/7.1/userspace-api/check_exec.html "https://docs.kernel.org/7.1/userspace-api/check_exec.html"
[23]: https://docs.kernel.org/filesystems/fsverity.html "https://docs.kernel.org/filesystems/fsverity.html"
[24]: https://docs.kernel.org/security/ipe.html "https://docs.kernel.org/security/ipe.html"
[25]: https://www.rfc-editor.org/info/rfc9334/ "https://www.rfc-editor.org/info/rfc9334/"
[26]: https://man7.org/linux/man-pages/man7/fanotify.7.html "https://man7.org/linux/man-pages/man7/fanotify.7.html"
[27]: https://docs.kernel.org/accounting/psi.html "https://docs.kernel.org/accounting/psi.html"
[28]: https://developers.openai.com/api/docs/models/gpt-5.6-sol "https://developers.openai.com/api/docs/models/gpt-5.6-sol"
[29]: https://developers.openai.com/api/docs/guides/agents/integrations-observability "https://developers.openai.com/api/docs/guides/agents/integrations-observability"
[30]: https://openai.github.io/openai-agents-python/guardrails/ "https://openai.github.io/openai-agents-python/guardrails/"
