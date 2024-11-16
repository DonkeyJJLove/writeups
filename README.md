# Fileless Malware w systemach Windows: Analiza techniczna i spostrzeżenia

---

## Spis treści

1. [Wprowadzenie](#wprowadzenie)
2. [Fileless Malware](#zrozumienie-złośliwego-oprogramowania-bezplikowego)
   - [Definicja i charakterystyka](#definicja-i-charakterystyka)
   - [Powszechnie stosowane techniki](#powszechnie-stosowane-techniki)
3. [Kluczowe funkcje Windows wykorzystywane przez Fileless Malware](#kluczowe-funkcje-windows-wykorzystywane-przez-fileless-malware)
   - [Funkcje zarządzania pamięcią](#funkcje-zarządzania-pamięcią)
     - [`VirtualAlloc` i `VirtualAllocEx`](#virtualalloc-i-virtualallocex)
     - [`VirtualProtect` i `VirtualProtectEx`](#virtualprotect-i-virtualprotectex)
   - [Funkcje zarządzania wątkami](#funkcje-zarządzania-wątkami)
     - [`CreateThread` i `CreateRemoteThread`](#createthread-i-createremotethread)
     - [`RtlUserThreadStart`](#rtluserthreadstart)
     - [`CreateProcessA`](#createprocessa)
   - [Instrumentacja zarządzania Windows (WMI)](#instrumentacja-zarządzania-windows-wmi)
   - [PowerShell i platforma .NET](#powershell-i-platforma-net)
4. [Mechanizmy wykonywania kodu w pamięci](#mechanizmy-wykonywania-kodu-w-pamięci)
   - [Techniki wstrzykiwania kodu](#techniki-wstrzykiwania-kodu)
     - [Reflective DLL Injection](#reflective-dll-injection)
     - [Process Hollowing](#process-hollowing)
   - [Wykonywanie za pomocą silników skryptowych](#wykonywanie-za-pomocą-silników-skryptowych)
     - [Skrypty PowerShell](#skrypty-powershell)
     - [Wykonywanie oparte na WMI](#wykonywanie-oparte-na-wmi)
5. [Studia przypadków Fileless Malware](#studia-przypadków-fileless-malware)
   - [Poweliks](#poweliks)
     - [Mechanizm działania](#mechanizm-działania)
   - [Kovter](#kovter)
     - [Mechanizm działania](#mechanizm-działania-1)
   - [Operacja Cobalt Kitty](#operacja-cobalt-kitty)
     - [Przegląd ataku](#przegląd-ataku)
     - [Analiza techniczna](#analiza-techniczna)
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

*W świecie cyberbezpieczeństwa cisza jest złotem, a niewidzialni przeciwnicy potrafią siać największe spustoszenie. Fileless malware, czyli złośliwe oprogramowanie bezplikowe, jest niczym duch przemierzający systemy informatyczne – niewykrywalne dla tradycyjnych mechanizmów bezpieczeństwa, działające w pamięci i wykorzystujące legalne narzędzia systemowe do swoich celów.*

*Gdy myślimy, że jesteśmy bezpieczni za murami naszych zapór sieciowych i oprogramowania antywirusowego, atakujący znajdują nowe ścieżki, aby nas zaskoczyć. Ich narzędzia ewoluują, a fileless malware staje się jednym z najbardziej podstępnych zagrożeń w cyfrowym świecie.*

Fileless malware stanowi poważne wyzwanie dla współczesnych systemów bezpieczeństwa. W przeciwieństwie do tradycyjnego malware, nie zapisuje swojego kodu na dysku twardym, co utrudnia jego wykrycie przez antywirusy oparte na sygnaturach plików. Zamiast tego, działa bezpośrednio w pamięci operacyjnej (RAM) i często wykorzystuje pospolite narzędzia systemowe do przeprowadzania złośliwych działań.

W niniejszym dokumencie przeanalizujemy techniki stosowane przez fileless malware w systemach Windows, zrozumiemy, jak wykorzystuje kluczowe funkcje systemowe, oraz przedstawimy studia przypadków takich ataków, w tym [Operację Cobalt Kitty](operacja-cobalt-kitty.md). Przedstawimy również środki obronne i zalecenia, które pomogą w zabezpieczeniu systemów przed tego typu zagrożeniami.

Dodatkowo, omówimy ewolucję malware oraz zmiany w taktykach cyberataków w kontekście wykorzystania nowoczesnych technologii AI, co pozwoli na pełniejsze zrozumienie dynamicznie zmieniającego się krajobrazu cyberzagrożeń:

- [Ewolucja Malware – Od Sygnatur do Adaptacyjnych Technologii AI](malware-evolution.md)
- [Zmiany w Taktykach Cyberataków – Analiza i Refleksje](cybersecurity-evolusion.md#zmiany-w-taktykach-cyberatakow)
---

## Fileless Malware

### Definicja i charakterystyka

Fileless malware to złośliwe oprogramowanie, które nie zapisuje swojego kodu na dysku twardym. Zamiast tego działa bezpośrednio w pamięci operacyjnej (RAM) i często wykorzystuje legalne narzędzia systemowe, takie jak PowerShell czy WMI, do przeprowadzania swoich działań. Dzięki temu unika detekcji przez tradycyjne oprogramowanie antywirusowe, które opiera się na skanowaniu plików na dysku.

### Powszechnie stosowane techniki

*Atakujący, niczym mistrzowie kamuflażu, wykorzystują różnorodne techniki, aby ukryć swoje działania i pozostać niewykrytymi. Wiedzą, że najlepszym sposobem na uniknięcie detekcji jest działanie w cieniu, korzystając z narzędzi, które są częścią systemu operacyjnego.*

Najczęściej stosowane techniki to:

- **Wykorzystanie wbudowanych narzędzi systemowych**: PowerShell, WMI, `mshta.exe`, `regsvr32.exe`.
- **Iniekcja kodu do pamięci innych procesów**: Reflective DLL Injection, Process Hollowing.
- **Wykorzystanie złośliwych makr w dokumentach Office**.
- **Eksploatacja luk bezpieczeństwa umożliwiających zdalne wykonanie kodu w pamięci**.

---

## Kluczowe funkcje Windows wykorzystywane przez Fileless Malware

*System Windows, niczym ogromna maszyna z niezliczonymi mechanizmami, posiada wiele funkcji, które mogą zostać wykorzystane zarówno do dobrych, jak i złych celów. Atakujący znają te funkcje i potrafią je wykorzystać na swoją korzyść.*

### Funkcje zarządzania pamięcią

#### `VirtualAlloc` i `VirtualAllocEx`

- **Cel**: Alokują lub rezerwują pamięć w wirtualnej przestrzeni adresowej procesu.
- **Wykorzystanie przez malware**: Alokacja obszarów pamięci wykonywalnej do przechowywania i uruchamiania złośliwego kodu.

#### `VirtualProtect` i `VirtualProtectEx`

- **Cel**: Zmieniają ochronę na regionie pamięci (np. z niewykonywalnej na wykonywalną).
- **Wykorzystanie przez malware**: Modyfikacja uprawnień pamięci, aby umożliwić wykonanie wstrzykniętego kodu.

### Funkcje zarządzania wątkami

#### `CreateThread` i `CreateRemoteThread`

- **Cel**: Tworzą nowy wątek w obrębie procesu lub w zdalnym procesie.
- **Wykorzystanie przez malware**: Wykonywanie złośliwego kodu w nowym wątku, często w innym procesie, co utrudnia detekcję.

#### `RtlUserThreadStart`

- **Cel**: Funkcja wewnętrzna używana do rozpoczęcia wykonywania nowego wątku w trybie użytkownika.
- **Wykorzystanie przez malware**: Pośrednio zaangażowana przy tworzeniu wątków; może być wykorzystana w zaawansowanych technikach ukrywania kodu.

#### `CreateProcessA`

- **Cel**: Tworzy nowy proces oraz jego główny wątek; może uruchamiać aplikacje z określonymi parametrami.
- **Wykorzystanie przez malware**: Uruchamianie złośliwych poleceń lub tworzenie zadań harmonogramu bez zapisu na dysku.

[Przykład użycia `CreateProcessA` w Operacji Cobalt Kitty](operacja-cobalt-kitty.md#analiza-kodów)

### Instrumentacja zarządzania Windows (WMI)

- **Cel**: Zapewnia interfejs do zarządzania i monitorowania zasobów systemowych.
- **Wykorzystanie przez malware**: Wykonywanie złośliwych skryptów, utrzymanie persistencji, zdalne zarządzanie systemami.

### PowerShell i platforma .NET

- **Cel**: Potężne narzędzie skryptowe i automatyzacyjne dla administratorów.
- **Wykorzystanie przez malware**: Wykonywanie złośliwych poleceń i skryptów bezpośrednio w pamięci, pobieranie i uruchamianie kodu z sieci.

---

## Mechanizmy wykonywania kodu w pamięci

*Atakujący nieustannie poszukują sposobów na ukrycie swoich działań. Wykonywanie kodu bezpośrednio w pamięci stało się jednym z najbardziej efektywnych sposobów na uniknięcie detekcji.*

### Techniki wstrzykiwania kodu

#### Reflective DLL Injection

- **Opis**: Technika polegająca na ładowaniu biblioteki DLL bezpośrednio z pamięci, bez zapisu na dysku.
- **Proces**:
  1. Alokacja pamięci w procesie docelowym.
  2. Kopiowanie kodu DLL do pamięci.
  3. Modyfikacja ochrony pamięci, aby umożliwić wykonanie kodu.
  4. Uruchomienie kodu z biblioteki DLL.

#### Process Hollowing

- **Opis**: Technika zastępowania kodu legalnego procesu kodem złośliwym.
- **Proces**:
  1. Utworzenie procesu w stanie zawieszonym.
  2. Odmapowanie oryginalnego kodu procesu.
  3. Wstrzyknięcie złośliwego kodu.
  4. Wznowienie procesu, który teraz wykonuje złośliwy kod.

### Wykonywanie za pomocą silników skryptowych

#### Skrypty PowerShell

*PowerShell jest potężnym narzędziem, ale w niepowołanych rękach staje się bronią. Atakujący wykorzystują jego możliwości do wykonywania złośliwych skryptów bezpośrednio w pamięci.*

- **Techniki**:
  - Użycie `Invoke-Expression` (`IEX`) do wykonania pobranego kodu.
  - Obfuskacja skryptów w celu uniknięcia wykrycia.
  - Pobieranie i uruchamianie kodu z zewnętrznych źródeł.

#### Wykonywanie oparte na WMI

- **Opis**: Wykorzystanie WMI do zdalnego wykonywania kodu i utrzymania persistencji.
- **Techniki**:
  - Tworzenie trwałych subskrypcji zdarzeń WMI.
  - Wykonywanie złośliwych poleceń na zdalnych maszynach.

---

## Studia przypadków Fileless Malware

*Najlepszym sposobem na zrozumienie zagrożenia jest analiza konkretnych przypadków. Przyjrzyjmy się kilku przykładom złośliwego oprogramowania bezplikowego, które spowodowało znaczne szkody.*

### Poweliks

#### Mechanizm działania

- **Opis**: Jeden z pierwszych znanych przypadków fileless malware.
- **Działanie**:
  - Dostarczany przez złośliwe załączniki e-mail lub exploit kits.
  - Przechowuje złośliwy kod w rejestrze systemowym.
  - Wykorzystuje PowerShell do wykonywania kodu bezpośrednio z rejestru.

### Kovter

#### Mechanizm działania

- **Opis**: Malware początkowo działający jako adware, ewoluował w kierunku bardziej złośliwych działań.
- **Działanie**:
  - Przechowuje złośliwy kod w rejestrze.
  - Wykorzystuje techniki iniekcji kodu i skrypty PowerShell.
  - Utrzymuje persistencję poprzez zadania harmonogramu.

### Operacja Cobalt Kitty

*Operacja Cobalt Kitty to przykład zaawansowanego ataku APT, w którym wykorzystano fileless malware do długotrwałej infiltracji systemów korporacyjnych.*

#### Przegląd ataku

- **Sprawcy**: Grupa APT znana jako OceanLotus (APT32).
- **Cele**: Przedsiębiorstwa w Azji Południowo-Wschodniej.
- **Cel ataku**: Długotrwała infiltracja w celu szpiegostwa i eksfiltracji danych.

[Pełna analiza Operacji Cobalt Kitty](operacja-cobalt-kitty.md)

#### Analiza techniczna

- **Początkowy wektor infekcji**: E-maile phishingowe z złośliwymi dokumentami Word zawierającymi makra.
- **Techniki użyte w ataku**:
  - Wykorzystanie złośliwych makr VBA do uruchamiania skryptów PowerShell.
  - Wykonywanie kodu bezpośrednio w pamięci za pomocą funkcji `VirtualAlloc`.
  - Utrzymanie persistencji poprzez tworzenie zadań harmonogramu z użyciem `CreateProcessA`.
  - Wykorzystanie WMI do tworzenia trwałych subskrypcji i uruchamiania kodu.

*Atakujący działali niczym cienie, przenikając do systemów korporacyjnych i pozostając niewykrytymi przez wiele miesięcy. Wykorzystali zaawansowane techniki, aby zyskać dostęp do krytycznych danych i komunikować się z serwerami C2 bez wzbudzania podejrzeń.*

[Przykłady kodu użytego w Operacji Cobalt Kitty](operacja-cobalt-kitty.md#analiza-kodów)

---

## Związek między funkcjami Windows

### `RtlUserThreadStart` i funkcje alokacji pamięci

- **Interakcja**: Funkcja `RtlUserThreadStart` jest używana podczas inicjowania nowych wątków. W połączeniu z funkcjami alokacji pamięci, takimi jak `VirtualAlloc`, pozwala na przygotowanie i wykonanie złośliwego kodu w nowym wątku.

### Implementacja wątków w .NET

- **Opis**: Platforma .NET umożliwia tworzenie i zarządzanie wątkami, które w tle korzystają z funkcji systemowych Windows.
- **Wykorzystanie przez malware**: Złośliwe oprogramowanie napisane w .NET może wykorzystywać wątki do wykonywania kodu w pamięci, korzystając z zarządzanych funkcji platformy.

---

## Kompleksowa lista funkcji używanych przez Fileless Malware

- **Funkcje pamięci**:
  - `VirtualAlloc`, `VirtualAllocEx`
  - `VirtualProtect`, `VirtualProtectEx`
  - `HeapCreate`, `HeapAlloc`

- **Funkcje procesów i wątków**:
  - `CreateThread`, `CreateRemoteThread`
  - `NtCreateThreadEx`
  - `RtlCreateUserThread`
  - `CreateProcessA`, `CreateProcessW`

- **Funkcje wstrzykiwania i wykonywania**:
  - `WriteProcessMemory`
  - `SetThreadContext`, `GetThreadContext`
  - `QueueUserAPC`

- **Funkcje ładowania bibliotek**:
  - `LoadLibrary`, `LoadLibraryEx`
  - `GetProcAddress`

- **Skrypty i automatyzacja**:
  - Cmdlety PowerShell (np. `Invoke-Expression`, `Invoke-Command`)
  - Klasy i metody WMI (np. `Win32_Process`, `__EventFilter`)

---

## Środki obronne i zalecenia

*W walce z niewidzialnym przeciwnikiem potrzebne są zaawansowane metody obrony. Zrozumienie technik atakujących pozwala na wdrożenie skutecznych środków ochrony.*

### Strategie monitorowania i wykrywania

- **Implementacja narzędzi EDR (Endpoint Detection and Response)**:
  - Monitorowanie aktywności w pamięci.
  - Wykrywanie nietypowych zachowań procesów.

- **Włączanie zaawansowanego logowania PowerShell**:
  - Włączenie modułów logowania (np. PowerShell Script Block Logging).
  - Monitorowanie i analiza zdarzeń.

- **Monitorowanie aktywności WMI**:
  - Wykrywanie nietypowych subskrypcji zdarzeń.
  - Audytowanie zdalnych połączeń WMI.

### Najlepsze praktyki w zakresie wzmacniania systemu

- **Zasada najmniejszych uprawnień**:
  - Ograniczenie uprawnień użytkowników i procesów do niezbędnego minimum.

- **Regularne aktualizacje systemów i oprogramowania**:
  - Łatanie znanych podatności.

- **Edukacja użytkowników**:
  - Szkolenia dotyczące rozpoznawania phishingu i zagrożeń związanych z makrami.
  - Promowanie bezpiecznych praktyk, takich jak nieotwieranie załączników od nieznanych nadawców.

- **Ograniczenie dostępu do narzędzi systemowych**:
  - Blokowanie nieautoryzowanego dostępu do PowerShell i WMI.
  - Kontrola aplikacji za pomocą AppLocker lub podobnych narzędzi.

---

## Wnioski

*Fileless malware to jedno z największych wyzwań w dziedzinie cyberbezpieczeństwa. Jego zdolność do działania w pamięci i unikania tradycyjnych mechanizmów detekcji sprawia, że jest szczególnie niebezpieczne. Ataki takie jak [Operacja Cobalt Kitty](operacja-cobalt-kitty.md) pokazują, jak zaawansowane techniki mogą zostać wykorzystane do długotrwałej infiltracji i kradzieży danych.*

Zrozumienie mechanizmów działania złośliwego oprogramowania bezplikowego jest kluczowe dla skutecznej obrony. Wdrożenie zaawansowanych narzędzi monitorowania, edukacja użytkowników i stosowanie najlepszych praktyk bezpieczeństwa to niezbędne kroki w walce z tym zagrożeniem.

---

## Bibliografia

1. **Dokumentacja Microsoft**:
   - [Funkcja VirtualAlloc](https://learn.microsoft.com/pl-pl/windows/win32/api/memoryapi/nf-memoryapi-virtualalloc)
   - [Funkcja CreateThread](https://learn.microsoft.com/pl-pl/windows/win32/api/processthreadsapi/nf-processthreadsapi-createthread)
   - [Instrumentacja zarządzania Windows (WMI)](https://learn.microsoft.com/pl-pl/windows/win32/wmisdk/wmi-start-page)
   - [Funkcja CreateProcessA](https://learn.microsoft.com/pl-pl/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessa)

2. **Cybereason Labs**:
   - [Operation Cobalt Kitty - Technical Analysis](https://www.cybereason.com/blog/operation-cobalt-kitty-apt)

3. **FireEye**:
   - [APT32 and the Threat Landscape in Southeast Asia](https://www.fireeye.com/current-threats/apt-groups.html)

4. **Kaspersky Lab**:
   - [OceanLotus and the Rise of APT Attacks in Asia](https://securelist.com/oceanlotus-rising-apt-in-asia/)

5. **MITRE ATT&CK Framework**:
   - [Fileless Malware Techniques](https://attack.mitre.org/techniques/T1059/001/)
   - [APT32 Group Description](https://attack.mitre.org/groups/G0050/)

6. **Sikorski, M., Honig, A.**:
   - *Practical Malware Analysis: The Hands-On Guide to Dissecting Malicious Software*, No Starch Press, 2012.

---

## Zastrzeżenie

> Niniejszy dokument jest przeznaczony wyłącznie do celów edukacyjnych i informacyjnych. Analiza technik złośliwego oprogramowania ma na celu poprawę obrony cyberbezpieczeństwa i świadomości. Nieautoryzowane tworzenie, dystrybucja lub użycie złośliwego oprogramowania jest nielegalne i nieetyczne. Zawsze przestrzegaj obowiązujących przepisów prawa i standardów etycznych podczas korzystania z informacji o cyberbezpieczeństwie.
>
> **Uwaga**: Przedstawiona treść jest syntezą dyskusji na temat fileless malware, funkcji systemu Windows wykorzystywanych przez atakujących oraz konkretnych studiów przypadków, takich jak [Operacja Cobalt Kitty](operacja-cobalt-kitty.md). Jest ona zorganizowana w celu ułatwienia głębszej eksploracji każdego tematu poprzez hiperłącza i uporządkowane sekcje, umożliwiając czytelnikom nawigację od ogólnych pojęć do szczegółowych analiz technicznych.

> [Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)
