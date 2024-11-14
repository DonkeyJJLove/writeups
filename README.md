# Fileless Malware w systemach Windows: Analiza techniczna i spostrzeżenia

---

## Spis treści

1. [Wprowadzenie](#wprowadzenie)
2. [Zrozumienie złośliwego oprogramowania bezplikowego](#zrozumienie-złośliwego-oprogramowania-bezplikowego)
   - [Definicja i charakterystyka](#definicja-i-charakterystyka)
   - [Powszechnie stosowane techniki](#powszechnie-stosowane-techniki)
3. [Kluczowe funkcje Windows wykorzystywane przez Fileless Malware](#kluczowe-funkcje-windows-wykorzystywane-przez-fileless-malware)
   - [Funkcje zarządzania pamięcią](#funkcje-zarządzania-pamięcią)
     - [`VirtualAlloc` i `VirtualAllocEx`](#virtualalloc-i-virtualallocex)
     - [`VirtualProtect` i `VirtualProtectEx`](#virtualprotect-i-virtualprotectex)
   - [Funkcje zarządzania wątkami](#funkcje-zarządzania-wątkami)
     - [`CreateThread` i `CreateRemoteThread`](#createthread-i-createremotethread)
     - [`RtlUserThreadStart`](#rtluserthreadstart)
   - [Instrumentacja zarządzania Windows (WMI)](#instrumentacja-zarządzania-windows-wmi)
   - [PowerShell i platforma .NET](#powershell-i-platforma-net)
4. [Mechanizmy wykonywania kodu w pamięci](#mechanizmy-wykonywania-kodu-w-pamięci)
   - [Techniki wstrzykiwania kodu](#techniki-wstrzykiwania-kodu)
     - [Reflect DLL Injection](#reflect-dll-injection)
     - [Process Hollowing](#process-hollowing)
   - [Wykonywanie za pomocą silników skryptowych](#wykonywanie-za-pomocą-silników-skryptowych)
     - [Skrypty PowerShell](#skrypty-powershell)
     - [Wykonywanie oparte na WMI](#wykonywanie-oparte-na-wmi)
5. [Studia przypadków Fileless Malware](#studia-przypadków-fileless-malware)
   - [Powershell Empire](#powershell-empire)
     - [Mechanizm działania](#mechanizm-działania)
   - [Operacja Cobalt Kitty](operacja-cobalt-kitty.md#operacja-cobalt-kitty)
     - [Przegląd ataku](operacja-cobalt-kitty.md#przegląd-ataku)
     - [Analiza techniczna](operacja-cobalt-kitty.md#analiza-techniczna)
6. [Związek między funkcjami Windows](#związek-między-funkcjami-windows)
   - [`RtlUserThreadStart` i funkcje alokacji pamięci](#rtluserthreadstart-i-funkcje-alokacji-pamięci)
   - [Implementacja wątków w .NET](#implementacja-wątków-w-net)
7. [Kompleksowa lista funkcji używanych przez Fileless Malware](#kompleksowa-lista-funkcji-używanych-przez-fileless-malware)
8. [Środki obronne i zalecenia](#środki-obronne-i-zalecenia)
   - [Strategie monitorowania i wykrywania](#strategie-monitorowania-i-wykrywania)
   - [Najlepsze praktyki w zakresie wzmacniania systemu](#najlepsze-praktyki-w-zakresie-wzmacniania-systemu)
9. [Wniosek](#wniosek)
10. [Bibliografia](#bibliografia)
11. [Zastrzeżenie](#zastrzeżenie)

---

## Wprowadzenie

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

Fileless Malware pojawiło się jako zaawansowane zagrożenie w krajobrazie cyberbezpieczeństwa. W przeciwieństwie do tradycyjnego złośliwego oprogramowania, rezyduje w pamięci systemu, co utrudnia jego wykrycie za pomocą konwencjonalnych rozwiązań antywirusowych. Ten dokument zapewnia kompleksową analizę Fileless Malware w systemach Windows, badając techniki stosowane przez atakujących, funkcje Windows, które wykorzystują, oraz studia przypadków ilustrujące ich metody.

---

## Zrozumienie złośliwego oprogramowania bezplikowego

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

### Definicja i charakterystyka

Fileless Malware działa bez pozostawiania śladu na dysku. Wykorzystuje legalne narzędzia systemowe i rezyduje w pamięci, korzystając z natywnych funkcjonalności Windows do wykonywania złośliwego kodu.

**Kluczowe cechy:**

- **Brak obecności na dysku:** Unika zapisywania plików na dysku.
- **Używa legalnych narzędzi:** Wykorzystuje zaufane komponenty Windows.
- **Rezyduje w pamięci:** Działa głównie w RAM.
- **Trudne wykrycie:** Unika tradycyjnych metod wykrywania opartych na sygnaturach.

[Dowiedz się więcej](#mechanizmy-wykonywania-kodu-w-pamięci)

### Powszechnie stosowane techniki

- **Wstrzykiwanie kodu do pamięci**
- **Nadużywanie języków skryptowych (np. PowerShell)**
- **Wykorzystanie Instrumentacji Zarządzania Windows (WMI)**
- **Reflect DLL Injection**

[Poznaj techniki](#techniki-wstrzykiwania-kodu)

---

## Kluczowe funkcje Windows wykorzystywane przez Fileless Malware

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

### Funkcje zarządzania pamięcią

#### `VirtualAlloc` i `VirtualAllocEx`

- **Cel:** Alokują lub rezerwują pamięć w wirtualnej przestrzeni adresowej procesu.
- **Wykorzystanie przez złośliwe oprogramowanie:** Alokują obszary pamięci wykonawczej do przechowywania i uruchamiania złośliwego kodu.

[Szczegółowa analiza](#virtualalloc-i-virtualallocex)

#### `VirtualProtect` i `VirtualProtectEx`

- **Cel:** Zmieniać ochronę na regionie zaangażowanych stron pamięci.
- **Wykorzystanie przez złośliwe oprogramowanie:** Modyfikują uprawnienia pamięci do wykonywania kodu w wcześniej niewykonywalnych regionach.

[Szczegółowa analiza](#virtualprotect-i-virtualprotectex)

### Funkcje zarządzania wątkami

#### `CreateThread` i `CreateRemoteThread`

- **Cel:** Tworzą nowy wątek w obrębie procesu wywołującego lub zdalnego procesu.
- **Wykorzystanie przez złośliwe oprogramowanie:** Wykonują złośliwy kod w nowym wątku, często w innym procesie.

[Szczegółowa analiza](#createthread-i-createremotethread)

#### `RtlUserThreadStart`

- **Cel:** Funkcja wewnętrzna używana do rozpoczęcia wykonywania nowego wątku w trybie użytkownika.
- **Wykorzystanie przez złośliwe oprogramowanie:** Pośrednio zaangażowana, gdy złośliwe oprogramowanie tworzy wątki na niższym poziomie.

[Szczegółowa analiza](#rtluserthreadstart)

### Instrumentacja zarządzania Windows (WMI)

- **Cel:** Zapewnia infrastrukturę dla danych i operacji zarządzania w Windows.
- **Wykorzystanie przez złośliwe oprogramowanie:** Wykonuje kod, przemieszcza się lateralnie w sieciach i utrzymuje trwałość.

[Szczegółowa analiza](#instrumentacja-zarządzania-windows-wmi)

### PowerShell i platforma .NET

- **Cel:** Język skryptowy i platforma dla automatyzacji zadań i konfiguracji.
- **Wykorzystanie przez złośliwe oprogramowanie:** Wykonuje skrypty i polecenia w pamięci, pobiera i uruchamia kod bez dotykania dysku.

[Szczegółowa analiza](#powershell-i-platforma-net)

---

## Mechanizmy wykonywania kodu w pamięci

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

### Techniki wstrzykiwania kodu

#### Reflect DLL Injection

- **Koncepcja:** Reflect DLL Injection to technika polegająca na ładowaniu biblioteki DLL bezpośrednio z pamięci, zamiast z dysku, co utrudnia jej wykrycie. Technika ta została opisana w literaturze fachowej, m.in. w książce "Practical Malware Analysis" autorstwa Michaela Sikorskiego i Andrew Honiga, jako jedna z metod stosowanych do ataków na oprogramowanie poprzez dynamiczne modyfikacje pamięci.
- **Proces:**
  1. Alokacja pamięci za pomocą `VirtualAlloc`.
  2. Kopiowanie DLL do pamięci.
  3. Dostosowanie ochrony pamięci za pomocą `VirtualProtect`.
  4. Wykonanie Entry Point DLL.

[Dowiedz się więcej](#reflect-dll-injection)

#### Process Hollowing

- **Koncepcja:** Zastąpienie kodu legalnego procesu kodem złośliwym.
- **Proces:**
  1. Utworzenie procesu w stanie zawieszonym.
  2. Odmapowanie oryginalnego pliku wykonywalnego z pamięci.
  3. Mapowanie złośliwego kodu do przestrzeni pamięci procesu.
  4. Wznowienie wykonywania procesu.

[Dowiedz się więcej](#process-hollowing)

### Wykonywanie za pomocą silników skryptowych

#### Skrypty PowerShell

- **Wykorzystanie:** Uruchamianie złośliwych poleceń i skryptów bezpośrednio w pamięci.
- **Techniki:**
  - Używanie `Invoke-Expression` do wykonywania kodu.
  - Obfuskacja skryptów w celu uniknięcia wykrycia.
  - Ładowanie zestawów za pomocą `System.Reflection`.

[Dowiedz się więcej](#skrypty-powershell)

#### Wykonywanie oparte na WMI

- **Wykorzystanie:** Wykorzystanie WMI do wykonywania kodu i utrzymywania trwałości.
- **Techniki:**
  - Tworzenie subskrypcji zdarzeń WMI.
  - Wykonywanie poleceń na zdalnych systemach.

[Dowiedz się więcej](#wykonywanie-oparte-na-wmi)

---

## Studia przypadków Fileless Malware

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

### Powershell Empire

#### Mechanizm działania

- **Opis:** Otwarty framework post-exploitacyjny.
- **Kluczowe cechy:**
  - Wykonuje agentów PowerShell bez potrzeby użycia powershell.exe.
  - Używa zaszyfrowanej komunikacji.
  - Działa w pamięci, unikając zapisów na dysku.

[Szczegółowa analiza](#mechanizm-działania)

### Operacja Cobalt Kitty

#### Przegląd ataku

- **Sprawcy:** Grupa APT znana jako OceanLotus lub APT32.
- **Cele:** Przedsiębiorstwa w Azji Południowo-Wschodniej.
- **Cele ataku:** Długoterminowa działalność szpiegowska i eksfiltracja danych.

[Szczegółowa analiza](operacja-cobalt-kitty.md#przegląd-ataku)

#### Analiza techniczna

- **Początkowy wektor infekcji:** E-maile spear-phishingowe z złośliwymi dokumentami.
- **Użyte techniki:**
  - Fileless Malware wykonywane za pomocą PowerShell.
  - Wykonywanie kodu w pamięci przy użyciu `VirtualAlloc`.
  - Utrzymanie trwałości poprzez subskrypcje zdarzeń WMI.

[Dogłębna analiza](operacja-cobalt-kitty.md#analiza-techniczna)

---

## Związek między funkcjami Windows

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

### `RtlUserThreadStart` i funkcje alokacji pamięci

- **Interakcja:** Podczas gdy `RtlUserThreadStart` jest używana wewnętrznie do uruchamiania wątków, funkcje alokacji pamięci, takie jak `VirtualAlloc`, są używane do przygotowania regionów pamięci wykonywalnej.
- **Wykorzystanie przez złośliwe oprogramowanie:** Atakujący mogą pośrednio wykorzystywać `RtlUserThreadStart` podczas tworzenia wątków do wykonywania złośliwego kodu.

[Poznaj związek](#rtluserthreadstart-i-funkcje-alokacji-pamięci)

### Implementacja wątków w .NET

- **Platforma .NET:** Zapewnia zarządzane wątki poprzez `System.Threading.Thread`.
- **Interakcja z Windows API:** W tle wątki .NET interakcjonują z mechanizmami wątków Windows.
- **Implikacje dla złośliwego oprogramowania:** Złośliwe oprogramowanie wykorzystujące .NET może korzystać z wątków do wykonywania kodu w pamięci.

[Szczegółowa analiza](#implementacja-wątków-w-net)

---

## Kompleksowa lista funkcji używanych przez Fileless Malware

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

Szczegółowe zestawienie funkcji API Windows powszechnie wykorzystywanych przez Fileless Malware:

- **Funkcje pamięci:**
  - `VirtualAlloc`, `VirtualAllocEx`
  - `VirtualProtect`, `VirtualProtectEx`
- **Funkcje procesów i wątków:**
  - `CreateThread`, `CreateRemoteThread`
  - `NtCreateThreadEx`
  - `RtlCreateUserThread`
- **Funkcje wstrzykiwania i wykonywania:**
  - `WriteProcessMemory`
  - `SetThreadContext`, `GetThreadContext`
  - `QueueUserAPC`
- **Funkcje ładowania bibliotek:**
  - `LoadLibrary`, `LoadLibraryEx`
  - `GetProcAddress`
- **Skrypty i automatyzacja:**
  - Cmdlety PowerShell (np. `Invoke-Expression`)
  - Klasy i metody WMI (np. `Win32_Process`, `__EventFilter`)

[Pełna lista z opisami](#lista-funkcji)

---

## Środki obronne i zalecenia

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

### Strategie monitorowania i wykrywania

- **Implementacja narzędzi Endpoint Detection and Response (EDR):**
  - Monitorowanie wykorzystania pamięci i zachowań procesów.
- **Włączanie logowania PowerShell:**
  - Śledzenie wykonywania skryptów i wykrywanie obfuskowanych poleceń.
- **Monitorowanie aktywności WMI:**
  - Wykrywanie nietypowych subskrypcji zdarzeń WMI i zdalnych wykonań.

[Dowiedz się więcej](#strategie-monitorowania-i-wykrywania)

### Najlepsze praktyki w zakresie wzmacniania systemu

- **Zastosowanie zasady najmniejszych uprawnień:**
  - Ograniczenie uprawnień użytkowników do niezbędnego minimum.
- **Regularne aktualizacje systemów:**
  - Szybkie łatanie podatności.
- **Ograniczenie silników skryptowych:**
  - Ograniczenie użycia PowerShell i WMI do uprawnionego personelu.

[Dowiedz się więcej](#najlepsze-praktyki-w-zakresie-wzmacniania-systemu)

---

## Wniosek

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

Fileless Malware stanowi znaczącą ewolucję w zagrożeniach cybernetycznych, wykorzystując legalne funkcjonalności systemu do potajemnego wykonywania złośliwych działań. Zrozumienie podstawowych funkcji Windows i mechanizmów wykorzystywanych przez takie złośliwe oprogramowanie jest kluczowe dla opracowywania skutecznych strategii obronnych. Poprzez wdrażanie solidnego monitorowania, przestrzeganie najlepszych praktyk i promowanie kultury świadomości bezpieczeństwa, organizacje mogą zmniejszyć ryzyko stwarzane przez te zaawansowane ataki.

---

## Bibliografia

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

1. **Dokumentacja Microsoft:**
   - [Funkcja VirtualAlloc](https://learn.microsoft.com/pl-pl/windows/win32/api/memoryapi/nf-memoryapi-virtualalloc)
   - [Funkcja CreateThread](https://learn.microsoft.com/pl-pl/windows/win32/api/processthreadsapi/nf-processthreadsapi-createthread)
   - [Instrumentacja zarządzania Windows](https://learn.microsoft.com/pl-pl/windows/win32/wmisdk/wmi-start-page)
2. **Analiza Cybereason Labs:**
   - *Operation Cobalt Kitty - Part 1* [PDF](https://www.cybereason.com/hubfs/Cybereason%20Labs%20Analysis%20Operation%20Cobalt%20Kitty-Part1.pdf)
3. **Artykuły z badań bezpieczeństwa:**
   - FireEye: *APT32 i krajobraz zagrożeń w Azji Południowo-Wschodniej*
   - Kaspersky Lab: *OceanLotus i wzrost ataków APT w Azji*

---

## Zastrzeżenie

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

Niniejszy dokument jest przeznaczony wyłącznie do celów edukacyjnych i informacyjnych. Analiza technik złośliwego oprogramowania ma na celu poprawę obrony cyberbezpieczeństwa i świadomości. Nieautoryzowane tworzenie, dystrybucja lub użycie złośliwego oprogramowania jest nielegalne i nieetyczne. Zawsze przestrzegaj obowiązujących przepisów prawa i standardów etycznych podczas korzystania z informacji o cyberbezpieczeństwie.

---

**Uwaga:** Przedstawiona treść jest syntezą dyskusji na temat Fileless Malware, funkcji systemu Windows wykorzystywanych przez atakujących oraz konkretnych studiów przypadków, takich jak Operacja Cobalt Kitty. Jest ona zorganizowana w celu ułatwienia głębszej eksploracji każdego tematu poprzez hiperłącza i uporządkowane sekcje, umożliwiając czytelnikom nawigację od ogólnych pojęć do szczegółowych analiz technicznych.

