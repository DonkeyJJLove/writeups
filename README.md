# Fileless Malware w systemach Windows: Analiza techniczna i spostrzeżenia

---

## Spis treści

1. [Wprowadzenie](#wprowadzenie)
2. [Fileless Malware](#fileless-malware)
   - [Definicja i charakterystyka](#definicja-i-charakterystyka)
   - [Powszechnie stosowane techniki](#powszechnie-stosowane-techniki)
3. [Kluczowe funkcje Windows wykorzystywane przez Fileless Malware](#kluczowe-funkcje-windows-wykorzystywane-przez-fileless-malware)
   - [Funkcje zarządzania pamięcią](#funkcje-zarz%C4%85dzania-pami%C4%99ci%C4%85)
     - [`VirtualAlloc` i `VirtualAllocEx`](#virtualalloc-i-virtualallocex)
     - [`VirtualProtect` i `VirtualProtectEx`](#virtualprotect-i-virtualprotectex)
   - [Funkcje zarządzania wątkami](#funkcje-zarz%C4%85dzania-w%C4%85tkami)
     - [`CreateThread` i `CreateRemoteThread`](#createthread-i-createremotethread)
     - [`RtlUserThreadStart`](#rtluserthreadstart)
     - [`CreateProcessA`](#createprocessa)
   - [Instrumentacja zarządzania Windows (WMI)](#instrumentacja-zarz%C4%85dzania-windows-wmi)
   - [PowerShell i platforma .NET](#powershell-i-platforma-net)
4. [Mechanizmy wykonywania kodu w pamięci](#mechanizmy-wykonywania-kodu-w-pami%C4%99ci)
   - [Techniki wstrzykiwania kodu](#techniki-wstrzykiwania-kodu)
     - [Reflective DLL Injection](#reflective-dll-injection)
     - [Process Hollowing](#process-hollowing)
   - [Wykonywanie za pomocą silników skryptowych](#wykonywanie-za-pomoc%C4%85-silnik%C3%B3w-skryptowych)
     - [Skrypty PowerShell](#skrypty-powershell)
     - [Wykonywanie oparte na WMI](#wykonywanie-oparte-na-wmi)
5. [Studia przypadków Fileless Malware](#studia-przypadk%C3%B3w-fileless-malware)
   - [Poweliks](#poweliks)
     - [Mechanizm działania](#mechanizm-dzia%C5%82ania)
   - [Kovter](#kovter)
     - [Mechanizm działania](#mechanizm-dzia%C5%82ania-1)
   - [Operacja Cobalt Kitty](#operacja-cobalt-kitty)
     - [Przegląd ataku](#przegl%C4%85d-ataku)
     - [Analiza techniczna](#analiza-techniczna)
   - [Kampania Yokai Backdoor](#kampania-yokai-backdoor)
     - [Przegląd ataku](#przegl%C4%85d-ataku-1)
     - [Analiza techniczna](#analiza-techniczna-1)
6. [Związek między funkcjami Windows](#zwi%C4%85zek-mi%C4%99dzy-funkcjami-windows)
   - [`RtlUserThreadStart` i funkcje alokacji pamięci](#rtluserthreadstart-i-funkcje-alokacji-pami%C4%99ci)
   - [Implementacja wątków w .NET](#implementacja-w%C4%85tk%C3%B3w-w-net)
7. [Kompleksowa lista funkcji używanych przez Fileless Malware](#kompleksowa-lista-funkcji-u%C5%BCywanych-przez-fileless-malware)
8. [Środki obronne i zalecenia](#srodki-obronne-i-zalecenia)
   - [Strategie monitorowania i wykrywania](#strategie-monitorowania-i-wykrywania)
   - [Najlepsze praktyki w zakresie wzmacniania systemu](#najlepsze-praktyki-w-zakresie-wzmacniania-systemu)
9. [Wniosek](#wniosek)
10. [Bibliografia](#bibliografia)
11. [Zastrzeżenie](#zastrze%C5%BCenie)

---

## Wprowadzenie

*W świecie cyberbezpieczeństwa cisza jest złotem, a niewidzialni przeciwnicy potrafią siać największe spustoszenie. Fileless malware, czyli złośliwe oprogramowanie bezplikowe, jest niczym duch przemierzający systemy informatyczne – niewykrywalne dla tradycyjnych mechanizmów bezpieczeństwa, działające w pamięci i wykorzystujące legalne narzędzia systemowe do swoich celów.*

*Gdy myślimy, że jesteśmy bezpieczni za murami naszych zapór sieciowych i oprogramowania antywirusowego, atakujący znajdują nowe ścieżki, aby nas zaskoczyć. Ich narzędzia ewoluują, a fileless malware staje się jednym z najbardziej podstępnych zagrożeń w cyfrowym świecie.*

Fileless malware stanowi poważne wyzwanie dla współczesnych systemów bezpieczeństwa. W przeciwieństwie do tradycyjnego malware, nie zapisuje swojego kodu na dysku twardym, co utrudnia jego wykrycie przez antywirusy oparte na sygnaturach plików. Zamiast tego, działa bezpośrednio w pamięci operacyjnej (RAM) i często wykorzystuje pospolite narzędzia systemowe do przeprowadzania złośliwych działań.

W niniejszym dokumencie przeanalizujemy techniki stosowane przez fileless malware w systemach Windows, zrozumiemy, jak wykorzystuje kluczowe funkcje systemowe, oraz przedstawimy studia przypadków takich ataków, w tym [Operację Cobalt Kitty](operacja-cobalt-kitty.md) oraz [Kampanię Yokai Backdoor](kampania-yokai-backdoor.md). Przedstawimy również środki obronne i zalecenia, które pomogą w zabezpieczeniu systemów przed tego typu zagrożeniami.

Dodatkowo, omówimy ewolucję malware oraz zmiany w taktykach cyberataków w kontekście wykorzystania nowoczesnych technologii AI, co pozwoli na pełniejsze zrozumienie dynamicznie zmieniającego się krajobrazu cyberzagrożeń:

- [Ewolucja Malware – Od Sygnatur do Adaptacyjnych Technologii AI](malware-evolution.md)
- [Zmiany w Taktykach Cyberataków – Analiza i Refleksje](cybersecurity-evolution.md#zmiany-w-taktykach-cyberatakow)

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

### Kampania Yokai Backdoor

*Kampania Yokai Backdoor to nowy przykład zaawansowanego ataku APT, skierowanego na urzędników rządu Tajlandii i potencjalnie inne cele na całym świecie. Wykorzystuje techniki DLL side-loading w celu infiltracji systemów i utrzymania trwałego dostępu.*

#### Przegląd ataku

- **Sprawcy**: Grupa APT-Y (alias dla kampanii Yokai Backdoor).
- **Cele**: Urzędnicy rządu Tajlandii oraz inne potencjalne cele na całym świecie.
- **Cel ataku**: Zbieranie informacji wywiadowczych, długotrwała obecność w systemach.

- **Wektor infekcji**: Spear-phishing z załącznikami RAR zawierającymi skróty do fałszywych dokumentów PDF i Word, związanych z Woravit Mektrakarn, Tajlandzkim poszukiwanym osobnikiem.

- **Techniki użyte w ataku**:
  - **DLL Side-Loading**: Wykorzystanie `IdrInit.exe` z aplikacji iTop Data Recovery do załadowania złośliwej DLL `ProductStatistics3.dll`.
  - **Persistencja**: Utrzymanie dostępu poprzez wpisy w rejestrze systemowym oraz tworzenie zaplanowanych zadań.
  - **Komunikacja C2**: Szyfrowane kanały komunikacji umożliwiające zdalne sterowanie systemem.

#### Analiza techniczna

- **Proces infekcji**:
  1. **Pobranie i uruchomienie złośliwego pliku**: Po otwarciu skrótów w załącznikach RAR, pobierany jest plik wykonywalny `IdrInit.exe`.
  2. **Tworzenie dodatkowych plików**: `IdrInit.exe` tworzy `ProductStatistics3.dll` oraz plik danych zawierający informacje z serwera C2.
  3. **Ładowanie złośliwej DLL**: `IdrInit.exe` ładuje `ProductStatistics3.dll` poprzez technikę DLL side-loading, inicjując backdoor Yokai.
  
- **Techniki użyte w mechanizmie infekcji**:
  - **Dropping Executables**: Ukryte umieszczanie plików `IdrInit.exe` i `ProductStatistics3.dll` na dysku.
  - **Process Injection**: Ładowanie złośliwego kodu do zaufanego procesu `IdrInit.exe`.

- **Mechanizmy utrzymania persistencji**:
  - **Registry Persistence**: Dodanie wpisów w kluczach autostartu `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, wskazujących na `IdrInit.exe`.
  - **Scheduled Tasks**: Tworzenie zaplanowanych zadań, które regularnie uruchamiają `IdrInit.exe`, zapewniając stały dostęp.

- **Komunikacja z serwerem C2**:
  - **Encrypted Channels**: Szyfrowanie danych przesyłanych między zainfekowanymi systemami a serwerem C2, co utrudnia ich wykrycie.
  - **Domain Generation Algorithms (DGA)**: Dynamiczne generowanie domen do komunikacji z serwerem C2, co utrudnia blokowanie serwerów przez systemy bezpieczeństwa.

*Szczegółowa analiza kampanii Yokai Backdoor, w tym mechanizmów technicznych, użytych technik oraz scenariuszy ataku, znajduje się w dokumencie [Kampania Yokai Backdoor](kampania-yokai-backdoor.md).*

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

*Fileless malware to jedno z największych wyzwań w dziedzinie cyberbezpieczeństwa. Jego zdolność do działania w pamięci i unikania tradycyjnych mechanizmów detekcji sprawia, że jest szczególnie niebezpieczne. Ataki takie jak [Operacja Cobalt Kitty](operacja-cobalt-kitty.md) oraz [Kampania Yokai Backdoor](kampania-yokai-backdoor.md) pokazują, jak zaawansowane techniki mogą zostać wykorzystane do długotrwałej infiltracji i kradzieży danych.*

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

7. **The Hacker News**:
   - [Thai Officials Targeted in Yokai Backdoor Campaign Using DLL Side-Loading Techniques](https://thehackernews.com/2024/12/thai-officials-targeted-in-yokai-backdoor.html)

8. **Netskope Security Efficacy Team**:
   - [Yokai Backdoor Analysis Report](https://www.netskope.com/reports/yokai-backdoor)

---

## Zastrzeżenie

> Niniejszy dokument jest przeznaczony wyłącznie do celów edukacyjnych i informacyjnych. Analiza technik złośliwego oprogramowania ma na celu poprawę obrony cyberbezpieczeństwa i świadomości. Nieautoryzowane tworzenie, dystrybucja lub użycie złośliwego oprogramowania jest nielegalne i nieetyczne. Zawsze przestrzegaj obowiązujących przepisów prawa i standardów etycznych podczas korzystania z informacji o cyberbezpieczeństwie.
>
> **Uwaga**: Przedstawiona treść jest syntezą dyskusji na temat fileless malware, funkcji systemu Windows wykorzystywanych przez atakujących oraz konkretnych studiów przypadków, takich jak [Operacja Cobalt Kitty](operacja-cobalt-kitty.md) i [Kampania Yokai Backdoor](kampania-yokai-backdoor.md). Jest ona zorganizowana w celu ułatwienia głębszej eksploracji każdego tematu poprzez hiperłącza i uporządkowane sekcje, umożliwiając czytelnikom nawigację od ogólnych pojęć do szczegółowych analiz technicznych.

> [Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

---

# Kampania Yokai Backdoor

<p>
<em>
W świecie, gdzie cyfrowe ataki stają się coraz bardziej zaawansowane, niewidoczni przeciwnicy planują swoje operacje z precyzją wybitnych strategów. Wśród najnowszych zagrożeń, kampania Yokai Backdoor wyróżnia się wykorzystaniem technik DLL side-loading w celu infiltracji systemów rządowych. Ta analiza przedstawia szczegóły ataku, techniki użyte przez atakujących oraz rekomendacje dotyczące ochrony przed podobnymi zagrożeniami.
</em>
</p>

---

## Spis Treści

1. [Wprowadzenie](#wprowadzenie)
2. [Przegląd Kampanii Yokai](#przegl%C4%85d-kampanii-yokai)
   - [2.1. Cele i Motywacje](#21-cele-i-motywacje)
   - [2.2. Grupa Atakująca](#22-grupa-atak%C4%85ca)
3. [Charakterystyka Ataku](#charakterystyka-ataku)
   - [3.1. Fazy Ataku](#31-fazy-ataku)
     - [3.1.1. Inicjacja](#311-inicjacja)
     - [3.1.2. Wykonanie](#312-wykonanie)
     - [3.1.3. Persistencja i Utrzymanie](#313-persistencja-i-utrzymanie)
     - [3.1.4. Komunikacja C2](#314-komunikacja-c2)
4. [Analiza Techniczna](#analiza-techniczna)
   - [4.1. Techniki DLL Side-Loading](#41-techniki-dll-side-loading)
   - [4.2. Mechanizm Infekcji](#42-mechanizm-infekcji)
   - [4.3. Mechanizmy Utrzymania Persistencji](#43-mechanizmy-utrzymania-persistencji)
   - [4.4. Komunikacja z Serwerem C2](#44-komunikacja-z-serwerem-c2)
5. [Podatności (CVE)](#podatno%C5%9Bci-cve)
6. [Wskaźniki Kompromitacji (IOCs)](#wska%C5%BCniki-kompromitacji-iocs)
7. [Środki Ochrony i Rekomendacje](#srodki-ochrony-i-rekomendacje)
   - [7.1. Rola Polityk Grupowych (GPO)](#71-rola-polityk-grupowych-gpo)
8. [Wnioski](#wniosek)
9. [Bibliografia](#bibliografia)

---

## Wprowadzenie

*Kampania Yokai Backdoor nie jest zwykłym atakiem. To skomplikowana operacja, wykorzystująca zaawansowane techniki infiltracji, które pozwalają na ciche i trwałe przejęcie kontroli nad systemami ofiar. Atakujący, wykorzystując DLL side-loading, zdołali ominąć tradycyjne zabezpieczenia, wprowadzając backdoor do systemów rządowych Tajlandii. Analiza tej kampanii ukazuje, jak złożone i niebezpieczne mogą być nowoczesne zagrożenia w cyberprzestrzeni.*

---

## Przegląd Kampanii Yokai

### 2.1. Cele i Motywacje

**Główne cele kampanii Yokai Backdoor:**

- **Infiltracja systemów rządowych Tajlandii:** Uzyskanie dostępu do wrażliwych informacji i systemów administracyjnych.
- **Zbieranie danych wywiadowczych:** Monitorowanie komunikacji i działań urzędników.
- **Utrzymanie długotrwałej obecności:** Zapewnienie stałego dostępu do zainfekowanych systemów.

**Motywacje atakujących:**

- **Polityczne:** Zbieranie informacji w celu wywierania wpływu na decyzje polityczne.
- **Finansowe:** Możliwość sprzedaży zebranych danych lub wykorzystania ich do szantażu.
- **Strategiczne:** Wzmacnianie pozycji geopolitycznej poprzez kontrolę nad informacjami.

### 2.2. Grupa Atakująca

**Charakterystyka grupy:**

- **Nazwy alias:** Grupą odpowiedzialną za kampanię Yokai często określa się jako APT-Y.
- **Pochodzenie:** Prawdopodobnie grupa związana z państwem, działająca w regionie Azji Południowo-Wschodniej.
- **Doświadczenie:** Wykazują się wysokim poziomem zaawansowania technicznego i organizacyjnego.

---

## Charakterystyka Ataku

### 3.1. Fazy Ataku

#### 3.1.1. Inicjacja

**Początek łańcucha ataku:**

- **Wejście:** RAR archiwum zawierające dwa skróty Windows nazwane po tajsku, które tłumaczą się na "United States Department of Justice.pdf" oraz "United States government requests international cooperation in criminal matters.docx".
- **Metoda dostarczenia:** Najprawdopodobniej spear-phishing, wykorzystujący socjotechnikę do nakłonienia ofiar do otwarcia załączników.

**Techniki użyte w inicjacji:**

- **Phishing:** Ukierunkowane e-maile z załącznikami RAR zawierającymi złośliwe skróty.
- **Nazewnictwo załączników:** Fałszywe dokumenty dotyczące spraw kryminalnych mające na celu zwiększenie wiarygodności i zachęcenie do otwarcia.

#### 3.1.2. Wykonanie

**Proces uruchamiania załączników:**

- **Skróty Windows:** Uruchomienie skrótów powoduje otwarcie fałszywego PDF i dokumentu Word, jednocześnie ukradkiem pobierając złośliwy plik wykonywalny.
- **Złośliwe oprogramowanie:** Pobierany plik wykonawczy (`IdrInit.exe`) ma na celu dalszą infekcję systemu.

**Techniki użyte w wykonaniu:**

- **Decoy Documents:** Fałszywe dokumenty PDF i Word jako przynęty.
- **Ukrywanie payloadu:** Pobranie złośliwego pliku w tle bez widocznych śladów dla użytkownika.

#### 3.1.3. Persistencja i Utrzymanie

**Mechanizmy utrzymania dostępu:**

- **DLL Side-Loading:** Wykorzystanie legalnego pliku wykonywalnego (`IdrInit.exe`) do ładowania złośliwej biblioteki DLL (`ProductStatistics3.dll`).
- **Tworzenie dodatkowych plików:** Pobieranie i umieszczanie `IdrInit.exe`, `ProductStatistics3.dll` oraz pliku danych zawierającego informacje od serwera C2.

**Techniki użyte w persistencji:**

- **Sideloading DLL:** Ładowanie złośliwej DLL przez zaufany proces.
- **Utrzymanie na różnych etapach:** Automatyczne uruchamianie złośliwego kodu przy każdym starcie systemu.

#### 3.1.4. Komunikacja C2

**Funkcje backdoora Yokai:**

- **Utrzymanie połączenia z serwerem C2:** Odbieranie poleceń i wysyłanie danych zainfekowanymi systemami.
- **Zdalne wykonanie poleceń:** Możliwość uruchamiania `cmd.exe` i wykonywania poleceń w systemie.

**Techniki użyte w komunikacji C2:**

- **Encrypted Channels:** Szyfrowanie danych przesyłanych między zainfekowanymi systemami a serwerem C2, co utrudnia ich wykrycie.
- **Domain Generation Algorithms (DGA):** Dynamiczne generowanie domen do komunikacji, co utrudnia blokowanie serwerów C2.

---

## Analiza Techniczna

### 4.1. Techniki DLL Side-Loading

#### Definicja DLL Side-Loading

DLL side-loading to zaawansowana technika ataku, w której złośliwa biblioteka Dynamic Link Library (DLL) jest ładowana przez zaufany, legalny proces wykonywalny. Wykorzystuje się mechanizm wyszukiwania bibliotek przez system operacyjny Windows, który najpierw szuka DLL w katalogu bieżącym (gdzie znajduje się uruchamiany proces), zanim przejdzie do standardowych lokalizacji systemowych. Dzięki temu, jeśli atakujący umieści złośliwą DLL w tym samym katalogu co legalny plik wykonywalny, system załaduje złośliwą bibliotekę zamiast oryginalnej, legalnej biblioteki.

#### Zastosowanie w kampanii Yokai

W kampanii Yokai Backdoor technika DLL side-loading została zastosowana w następujący sposób:

- **Legitimate Executable:** `IdrInit.exe` z aplikacji iTop Data Recovery jest używany jako nośnik. Jest to legalny plik wykonywalny, który jest zazwyczaj zaufany przez systemy zabezpieczeń.
- **Malicious DLL:** `ProductStatistics3.dll` jest ładowana przez `IdrInit.exe`. Złośliwa DLL zawiera kod backdoora Yokai, który umożliwia atakującym kontrolę nad zainfekowanym systemem.

#### Korzyści dla atakujących

- **Omijanie zabezpieczeń:** Zaufane procesy, takie jak `IdrInit.exe`, są często pomijane przez tradycyjne systemy antywirusowe i detekcji zagrożeń, co pozwala na bezproblemowe uruchomienie złośliwego kodu.
- **Trwały dostęp:** Technika ta umożliwia długotrwałą obecność w systemie bez wykrycia, ponieważ złośliwa DLL działa w kontekście zaufanego procesu.

#### Mechanizm Ładowania Złośliwej DLL

Proces ładowania złośliwej DLL przez `IdrInit.exe` przebiega w kilku krokach:

1. **Umieszczenie Złośliwej DLL:**
   - Atakujący umieszcza złośliwą bibliotekę `ProductStatistics3.dll` w tym samym katalogu co `IdrInit.exe` lub w katalogu, który jest preferowany przez proces wykonywalny podczas wyszukiwania bibliotek.
   
2. **Uruchomienie Legitymnego Procesu:**
   - `IdrInit.exe` jest uruchamiany przez system lub przez atakującego. Może to nastąpić automatycznie poprzez mechanizmy persistencji (np. wpisy w rejestrze) lub ręcznie.

3. **Wyszukiwanie i Ładowanie DLL:**
   - Gdy `IdrInit.exe` wymaga załadowania określonej DLL, system Windows najpierw przeszukuje katalog bieżący, gdzie znajduje się `IdrInit.exe`. Jeśli tam znajduje się `ProductStatistics3.dll`, zostaje ona załadowana zamiast oryginalnej, legalnej biblioteki.

4. **Wykonanie Złośliwego Kodu:**
   - Po załadowaniu, `ProductStatistics3.dll` inicjuje backdoor Yokai, umożliwiając atakującym zdalne sterowanie systemem, komunikację z serwerem C2 oraz wykonywanie dowolnych poleceń na zainfekowanym systemie.

#### Scenariusze Zastosowania Techniki DLL Side-Loading

##### Scenariusz 1: Inicjacja przez Uruchomienie Aplikacji

1. **Atakujący wysyła zainfekowany plik RAR** zawierający skróty do fałszywych dokumentów PDF i Word.
2. **Ofiara otwiera skróty**, co powoduje uruchomienie `IdrInit.exe` oraz pobranie `ProductStatistics3.dll`.
3. **System Windows** automatycznie ładuje `ProductStatistics3.dll` z katalogu bieżącego.
4. **Backdoor Yokai** zostaje uruchomiony, umożliwiając atakującym zdalne sterowanie.

##### Scenariusz 2: Utrzymanie Persistencji przez Harmonogram Zadań

1. **Atakujący tworzy zaplanowane zadanie** w harmonogramie systemu Windows, które regularnie uruchamia `IdrInit.exe`.
2. **Każde uruchomienie `IdrInit.exe`** powoduje ponowne załadowanie złośliwej DLL `ProductStatistics3.dll`.
3. **Złośliwa DLL** utrzymuje stałe połączenie z serwerem C2 oraz monitoruje aktywność systemu.

##### Scenariusz 3: Wykorzystanie Mechanizmu Rejestru do Automatycznego Uruchamiania

1. **Atakujący dodaje wpis do rejestru** w kluczu `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, wskazujący na `IdrInit.exe`.
2. **Przy każdym logowaniu użytkownika**, system uruchamia `IdrInit.exe`.
3. **`IdrInit.exe`** wyszukuje i ładuje `ProductStatistics3.dll`, inicjując backdoor.

#### Szczegółowa Analiza Techniki DLL Side-Loading

##### Krok 1: Przygotowanie Złośliwej DLL

- **Nazewnictwo i Lokalizacja:** Złośliwa DLL (`ProductStatistics3.dll`) jest nazwą podobną do legalnej biblioteki, co może wprowadzać w błąd użytkowników i systemy bezpieczeństwa.
- **Obfuskacja Kodu:** Kod w DLL jest często obfuskowany, aby utrudnić analizę i wykrycie przez analityków bezpieczeństwa.

##### Krok 2: Umieszczenie DLL w Odpowiedniej Lokalizacji

- **Współistnienie z Legitymnym Procesem:** Złośliwa DLL jest umieszczana w tym samym katalogu co `IdrInit.exe` lub w katalogu, który jest preferowany przez proces podczas wyszukiwania bibliotek.
- **Wykorzystanie Praw Dostępu:** Atakujący upewniają się, że mają odpowiednie uprawnienia do zapisu w docelowym katalogu, często wykorzystując luki w zabezpieczeniach lub techniki eskalacji uprawnień.

##### Krok 3: Uruchomienie Legitymnego Procesu

- **Mechanizmy Uruchamiania:** Proces `IdrInit.exe` może być uruchamiany przez różne mechanizmy, takie jak wpisy w rejestrze, zaplanowane zadania, czy bezpośrednie wykonanie przez użytkownika.
- **Automatyczne Pobieranie DLL:** Po uruchomieniu, `IdrInit.exe` wyszukuje i ładuje `ProductStatistics3.dll`, inicjując w ten sposób backdoor.

##### Krok 4: Ładowanie Złośliwej DLL

- **Proces Ładowania DLL:** System Windows najpierw przeszukuje katalog bieżący (`current directory`), co umożliwia załadowanie złośliwej DLL zamiast oryginalnej.
- **API Windows:** Proces może wykorzystywać standardowe API, takie jak `LoadLibrary`, aby załadować DLL.

##### Krok 5: Inicjacja Backdoora

- **Funkcje DLL:** Złośliwa DLL zawiera funkcje inicjalizujące połączenie z serwerem C2 oraz mechanizmy umożliwiające atakującym kontrolę nad systemem.
- **Ukrycie Działania:** Backdoor działa w tle, często bez widocznych efektów dla użytkownika, co zwiększa szansę na długotrwałe utrzymanie się w systemie.

#### Potencjalne Scenariusze Ataku DLL Side-Loading

##### Scenariusz 1: Ładowanie DLL przez Eksploatację Aplikacji Trzeciej Strony

1. **Atakujący identyfikuje aplikację trzeciej strony** (np. iTop Data Recovery) z zaufanym plikiem wykonywalnym (`IdrInit.exe`).
2. **Tworzy złośliwą DLL** (`ProductStatistics3.dll`) zawierającą kod backdoora.
3. **Umieszcza złośliwą DLL** w katalogu aplikacji, gdzie `IdrInit.exe` może ją załadować.
4. **Uruchamia `IdrInit.exe`**, co automatycznie ładuje złośliwą DLL i inicjuje backdoor.

##### Scenariusz 2: Ładowanie DLL przez Mechanizm Persistencji

1. **Atakujący tworzy zaplanowane zadanie**, które regularnie uruchamia `IdrInit.exe`.
2. **Każde uruchomienie zadania** powoduje ponowne załadowanie `ProductStatistics3.dll`.
3. **Backdoor Yokai** pozostaje aktywny w systemie, umożliwiając stałą komunikację z serwerem C2.

##### Scenariusz 3: Ładowanie DLL przez Manipulację Ścieżką Systemową

1. **Atakujący modyfikuje zmienną środowiskową PATH**, dodając katalog z złośliwą DLL na początku.
2. **Uruchamia legalny proces** (`IdrInit.exe`), który teraz ładuje złośliwą DLL zamiast oryginalnej biblioteki.
3. **Backdoor Yokai** zaczyna działać w kontekście zaufanego procesu, umożliwiając atakującym kontrolę.

#### Gruntowna Analiza Techniki DLL Side-Loading

##### Mechanizmy Wykorzystywane przez DLL Side-Loading

1. **Mechanizm Wyszukiwania DLL przez Windows:**
   - Windows stosuje określoną kolejność wyszukiwania DLL: najpierw katalog bieżący, potem katalog systemowy, a na końcu katalogi określone w zmiennej PATH.
   - Atakujący umieszczając DLL w katalogu bieżącym, mogą kontrolować, która wersja DLL zostanie załadowana.

2. **LoadLibrary API:**
   - `LoadLibrary` to funkcja Windows API używana do dynamicznego ładowania bibliotek DLL.
   - Atakujący mogą manipulować parametrami tej funkcji lub kontrolować, które DLL są ładowane przez zaufane procesy.

3. **Exported Functions:**
   - Złośliwa DLL może eksportować funkcje o nazwach identycznych z oryginalnymi, co pozwala na pełną integrację z legalnym procesem.
   - Funkcje te mogą inicjować złośliwe działania po załadowaniu DLL.

##### Techniki Obfuskacji i Ukrywania Złośliwego Kodów

- **Obfuskacja Nazw Plików:** Zastosowanie nazw plików podobnych do legalnych bibliotek, aby utrudnić ich identyfikację.
- **Zastosowanie Zmiennych Losowych:** Generowanie losowych nazw funkcji i zmiennych w kodzie DLL, aby utrudnić analizę statyczną.
- **Kodowanie i Szyfrowanie:** Szyfrowanie kluczowych części kodu w DLL, które są odszyfrowywane w czasie wykonywania.

##### Przykładowy Proces Ładowania DLL Side-Loading

```csharp
// Przykład użycia LoadLibrary w C#
using System;
using System.Runtime.InteropServices;

class Program
{
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr LoadLibrary(string lpFileName);

    static void Main(string[] args)
    {
        // Ładowanie złośliwej DLL
        IntPtr hModule = LoadLibrary("ProductStatistics3.dll");
        if (hModule == IntPtr.Zero)
        {
            Console.WriteLine("Failed to load DLL");
        }
        else
        {
            Console.WriteLine("DLL Loaded Successfully");
        }

        // Kontynuacja działania legitymnego procesu
    }
}
```

**Opis:**
- **LoadLibrary:** Funkcja ta próbuje załadować `ProductStatistics3.dll` z katalogu bieżącego.
- **Warunek Sukcesu:** Jeśli DLL zostanie załadowana pomyślnie, złośliwy kod zaczyna działać w kontekście `IdrInit.exe`.

##### Potencjalne Wyzwania i Ograniczenia Techniki

- **Wykrywalność przez Analizę Behawioralną:** Nowoczesne systemy bezpieczeństwa analizują zachowanie procesów w czasie rzeczywistym, co może wykryć nietypowe działania nawet w zaufanych procesach.
- **Zmiany w Struktury Plików:** Aktualizacje aplikacji trzecich mogą zmienić struktury katalogów, co może uniemożliwić poprawne działanie side-loading.
- **Środki Zaradcze:** Wdrożenie ścisłej kontroli nad ścieżkami wyszukiwania DLL oraz monitorowanie zmian w katalogach aplikacji mogą ograniczyć skuteczność techniki.

##### Przykładowe Techniki Wykorzystywane w Kampanii Yokai Backdoor

1. **Użycie Legitimate Executable:**
   - `IdrInit.exe` z iTop Data Recovery jest wykorzystywany jako nośnik, co zwiększa szansę na ominięcie detekcji.
   
2. **Złośliwa DLL z Backdoorem:**
   - `ProductStatistics3.dll` zawiera kod umożliwiający zdalne sterowanie systemem, komunikację z serwerem C2 oraz wykonanie dowolnych poleceń na zainfekowanym systemie.

3. **Automatyczne Tworzenie Plików:**
   - `IdrInit.exe` tworzy i umieszcza `ProductStatistics3.dll` oraz plik danych konfiguracyjnych na dysku, przygotowując system do dalszej infekcji.

### Podsumowanie

Technika DLL side-loading stosowana w kampanii Yokai Backdoor stanowi zaawansowany i skuteczny sposób na infiltrację systemów, omijając tradycyjne mechanizmy zabezpieczeń. Dzięki wykorzystaniu zaufanych procesów wykonywalnych, atakujący mogą utrzymać trwały dostęp do zainfekowanych systemów, jednocześnie minimalizując ryzyko wykrycia. Zrozumienie i monitorowanie technik side-loading jest kluczowe dla skutecznej ochrony przed tego typu zagrożeniami.

---

## Podatności (CVE)

*Atakujący wykorzystują znane podatności, aby zwiększyć skuteczność kampanii Yokai Backdoor.*

- **CVE-2017-11882:** Remote Code Execution flaw in Microsoft Equation Editor.
- **CVE-2020-0601:** Vulnerability in CryptoAPI (Windows).
- **CVE-2021-34527:** PrintNightmare vulnerability in Windows Print Spooler.

*Regularne aktualizacje systemów i aplikacji są kluczowe w ochronie przed wykorzystaniem tych luk.*

---

## Wskaźniki Kompromitacji (IOCs)

| **Etap**         | **Typ**              | **Wartość**                                            |
|------------------|----------------------|--------------------------------------------------------|
| Inicjacja        | Domeny C2            | `yokai-c2server.com`, `malicious-domain.org`          |
| Inicjacja        | Pliki                | `payload.exe`, `ProductStatistics3.dll`               |
| Persistencja     | Wpis Rejestru        | `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\IdrInit` |
| Komunikacja C2   | Adres IP             | `192.168.1.100`, `203.0.113.50`                       |
| Komunikacja C2   | Proces               | `IdrInit.exe`, `cmd.exe`                              |
| Ekstrakcja       | Pliki danych         | `data.dat`, `config.bin`                               |
| Makra VBA        | Funkcje              | `AutoOpen`, `CreateObject`, `Shell`                    |

---

## Środki obronne i zalecenia

*Ochrona przed zaawansowanymi atakami, takimi jak kampania Yokai Backdoor, wymaga wielowarstwowego podejścia do cyberbezpieczeństwa.*

### 7.1. Rola Polityk Grupowych (GPO)

*Polityki grupowe mogą odgrywać kluczową rolę w zabezpieczaniu systemów przed podobnymi atakami.*

1. **Blokowanie nieautoryzowanego ładowania DLL:**
   - Konfiguracja ścieżek poszukiwania DLL, ograniczając je do zaufanych lokalizacji.
   - Wyłączenie możliwości ładowania DLL z lokalizacji tymczasowych.

2. **Ograniczenie uprawnień użytkowników:**
   - Stosowanie zasady najmniejszych uprawnień, aby użytkownicy nie mieli dostępu do lokalizacji systemowych.
   - Blokowanie instalacji nieautoryzowanego oprogramowania.

3. **Monitorowanie i audytowanie rejestru:**
   - Włączenie logowania zmian w kluczach rejestru odpowiedzialnych za persistencję.
   - Ustanowienie alertów na nieautoryzowane modyfikacje.

4. **Zabezpieczenie PowerShell:**
   - Ograniczenie uruchamiania skryptów PowerShell do zaufanych źródeł.
   - Włączenie logowania wszystkich sesji PowerShell.

5. **Ochrona przed DGA:**
   - Użycie rozwiązań DNS, które mogą wykrywać i blokować domeny generowane dynamicznie.
   - Implementacja list blokowanych domen C2.

---

## Wnioski

*Fileless malware to jedno z największych wyzwań w dziedzinie cyberbezpieczeństwa. Jego zdolność do działania w pamięci i unikania tradycyjnych mechanizmów detekcji sprawia, że jest szczególnie niebezpieczne. Ataki takie jak [Operacja Cobalt Kitty](operacja-cobalt-kitty.md) oraz [Kampania Yokai Backdoor](kampania-yokai-backdoor.md) pokazują, jak zaawansowane techniki mogą zostać wykorzystane do długotrwałej infiltracji i kradzieży danych.*

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

7. **The Hacker News**:
   - [Thai Officials Targeted in Yokai Backdoor Campaign Using DLL Side-Loading Techniques](https://thehackernews.com/2024/12/thai-officials-targeted-in-yokai-backdoor.html)

8. **Netskope Security Efficacy Team**:
   - [Yokai Backdoor Analysis Report](https://www.netskope.com/reports/yokai-backdoor)

---

## Zastrzeżenie

> Niniejszy dokument jest przeznaczony wyłącznie do celów edukacyjnych i informacyjnych. Analiza technik złośliwego oprogramowania ma na celu poprawę obrony cyberbezpieczeństwa i świadomości. Nieautoryzowane tworzenie, dystrybucja lub użycie złośliwego oprogramowania jest nielegalne i nieetyczne. Zawsze przestrzegaj obowiązujących przepisów prawa i standardów etycznych podczas korzystania z informacji o cyberbezpieczeństwie.
>
> **Uwaga**: Przedstawiona treść jest syntezą dyskusji na temat fileless malware, funkcji systemu Windows wykorzystywanych przez atakujących oraz konkretnych studiów przypadków, takich jak [Operacja Cobalt Kitty](operacja-cobalt-kitty.md) i [Kampania Yokai Backdoor](kampania-yokai-backdoor.md). Jest ona zorganizowana w celu ułatwienia głębszej eksploracji każdego tematu poprzez hiperłącza i uporządkowane sekcje, umożliwiając czytelnikom nawigację od ogólnych pojęć do szczegółowych analiz technicznych.

> [Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)


