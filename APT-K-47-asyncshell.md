# Analiza Malware Asyncshell

<p>
<em>
W cyfrowym świecie, gdzie dane stały się nową walutą, a cyberprzestrzeń polem bitwy, niewidoczni aktorzy planują swoje ataki z precyzją mistrzów szachowych. Wśród tych aktorów, grupa APT-K-47, znana również jako Mysterious Elephant, wprowadziła na scenę złośliwe oprogramowanie o nazwie Asyncshell. Ten zaawansowany malware, ewoluujący przez kilka wersji, stał się narzędziem do przeprowadzania precyzyjnych ataków na cele w Azji Południowej. Niniejsza analiza zagłębia się w tajemnice Asyncshell, ukazując jego mechanizmy, techniki i ewolucję.
</em>
</p>

---

## Spis Treści

1. [Wprowadzenie](#wprowadzenie)
2. [Przegląd Malware](#przegląd-malware)
3. [Charakterystyka Ataku](#charakterystyka-ataku)
   - [3.1. Fazy Ataku](#31-fazy-ataku)
4. [Analiza Techniczna](#analiza-techniczna)
   - [4.1. Ewolucja Asyncshell](#41-ewolucja-asyncshell)
   - [4.2. Mechanizmy Dostarczania](#42-mechanizmy-dostarczania)
   - [4.3. Funkcjonalność i Zdolności](#43-funkcjonalność-i-zdolności)
   - [4.4. Komunikacja z Serwerem C2](#44-komunikacja-z-serwerem-c2)
   - [4.5. Techniki Obfuskacji i Unikania Wykrycia](#45-techniki-obfuskacji-i-unikania-wykrycia)
5. [Gruntowna Analiza Kodu](#gruntowna-analiza-kodu)
   - [5.1. Ukrywanie Ciągów Znaków](#51-ukrywanie-ciągów-znaków)
   - [5.2. Dynamiczne Odszyfrowywanie Adresów C2](#52-dynamiczne-odszyfrowywanie-adresów-c2)
   - [5.3. Wykonywanie Poleceń Asynchronicznych](#53-wykonywanie-poleceń-asynchronicznych)
6. [Podatności (CVE)](#podatności-cve)
7. [Wskaźniki Kompromitacji (IOCs)](#wskaźniki-kompromitacji-iocs)
8. [Środki Ochrony i Rekomendacje](#środki-ochrony-i-rekomendacje)
   - [8.1. Zalecenia dla Organizacji](#81-zalecenia-dla-organizacji)
9. [Wnioski](#wnioski)
10. [Bibliografia](#bibliografia)

---

## Wprowadzenie

*Asyncshell nie jest zwykłym złośliwym oprogramowaniem. To narzędzie precyzyjnie zaprojektowane, aby przeniknąć do systemów ofiar, pozostając niewykrytym przez długi czas. Wykorzystuje zaawansowane techniki programowania asynchronicznego, szyfrowaną komunikację i dynamiczne mechanizmy dostarczania, czyniąc go poważnym zagrożeniem dla organizacji na całym świecie.*

---

## Przegląd Malware

Asyncshell to złośliwe oprogramowanie wykorzystywane przez grupę APT-K-47 w celu przeprowadzania ataków typu APT (Advanced Persistent Threat). Jego głównym celem jest uzyskanie zdalnego dostępu do systemu ofiary, wykonywanie poleceń i eksfiltracja danych.

**Charakterystyka Asyncshell:**

- **Programowanie asynchroniczne:** Wykorzystuje asynchroniczne metody do efektywnego wykonywania zadań.
- **Szyfrowana komunikacja:** Używa protokołu HTTPS oraz szyfrowania AES do komunikacji z serwerem C2.
- **Obfuskacja kodu:** Zastosowanie technik ukrywania ciągów znaków i obfuskacji utrudnia analizę.
- **Dynamiczne adresy C2:** Adresy serwerów Command and Control są odszyfrowywane w czasie rzeczywistym.

*Atakujący wykorzystują Asyncshell do przeprowadzania ukierunkowanych ataków, często na instytucje rządowe i organizacje w regionie Azji Południowej.*

---

## Charakterystyka Ataku

### 3.1. Fazy Ataku

#### **1. Dostarczenie**

<p>
<em>
Atak rozpoczyna się od precyzyjnie zaplanowanej dystrybucji złośliwego oprogramowania. Atakujący wykorzystują złośliwe pliki ZIP zawierające zaszyfrowane archiwa RAR oraz pliki tekstowe z hasłami. Dokumenty przynęty często dotyczą tematów religijnych lub politycznych, mających na celu zainteresowanie ofiary.
</em>
</p>

- **Techniki:**
  - **Phishing:** Wysyłanie ukierunkowanych wiadomości e-mail z załącznikami.
  - **Wykorzystanie plików CHM i LNK:** Uruchamianie złośliwego kodu poprzez pliki pomocy Windows i skróty.

#### **2. Wykonanie**

<p>
<em>
Po otwarciu złośliwego pliku, malware wykorzystuje skrypty VBS oraz zaplanowane zadania do uruchomienia Asyncshell. Dzięki temu atakujący uzyskują początkowy dostęp do systemu ofiary.
</em>
</p>

- **Techniki:**
  - **Skrypty VBS:** Automatyzacja zadań i uruchamianie złośliwego kodu.
  - **Zaplanowane zadania:** Utrzymanie persistencji w systemie.

#### **3. Utrzymanie i Unikanie Wykrycia**

<p>
<em>
Asyncshell stosuje zaawansowane techniki unikania wykrycia, w tym obfuskację kodu, usuwanie logów oraz szyfrowaną komunikację z serwerem C2. Dynamiczne odszyfrowywanie adresów C2 z plików lub fałszywych żądań sieciowych pozwala na elastyczne zarządzanie infrastrukturą ataków.
</em>
</p>

- **Techniki:**
  - **Obfuskacja:** Ukrywanie kluczowych informacji i ciągów znaków.
  - **Szyfrowanie:** Użycie AES i HTTPS do zabezpieczenia komunikacji.

#### **4. Komunikacja C2 (Command and Control)**

<p>
<em>
Malware nawiązuje szyfrowaną komunikację z serwerem C2, umożliwiając atakującym zdalne sterowanie zainfekowanym systemem. Wykorzystanie standardowych protokołów i portów pomaga w ukryciu ruchu przed systemami detekcji.
</em>
</p>

- **Techniki:**
  - **HTTPS:** Szyfrowana komunikacja z użyciem protokołu HTTPS.
  - **Dynamiczne adresy:** Odszyfrowywanie adresów C2 w czasie rzeczywistym.

#### **5. Działania na Systemie i Eksfiltracja Danych**

<p>
<em>
Asyncshell umożliwia atakującym wykonywanie dowolnych poleceń na systemie ofiary, a także eksfiltrację danych. Funkcje takie jak `UploadFileAsync` pozwalają na przesyłanie plików z systemu ofiary na serwer C2.
</em>
</p>

- **Techniki:**
  - **Wykonywanie poleceń:** Asynchroniczne metody umożliwiają efektywne zarządzanie zadaniami.
  - **Eksfiltracja danych:** Przesyłanie skradzionych danych na serwery C2.

---

## Analiza Techniczna

### 4.1. Ewolucja Asyncshell

*Asyncshell przeszedł znaczącą ewolucję, dostosowując się do zmieniających się warunków i środków bezpieczeństwa.*

- **Asyncshell-v1:** Wykorzystanie protokołu TCP, obsługa poleceń `cmd` i `PowerShell`.
- **Asyncshell-v2:** Przejście na komunikację HTTPS, zwiększenie bezpieczeństwa.
- **Asyncshell-v3:** Odszyfrowywanie adresu C2 z plików, dynamiczna konfiguracja.
- **Asyncshell-v4:** Zastosowanie zmodyfikowanego Base64, podszywanie się pod normalne żądania sieciowe, usunięcie logów.

### 4.2. Mechanizmy Dostarczania

- **Złośliwe Archiwa ZIP:** Zawierające zaszyfrowane pliki RAR oraz pliki tekstowe z hasłami.
- **Pliki CHM i LNK:** Używane do uruchamiania złośliwego kodu i wyświetlania dokumentów przynęty.
- **Skrypty VBS i Zaplanowane Zadania:** Automatyzacja uruchamiania malware i utrzymanie persistencji.

### 4.3. Funkcjonalność i Zdolności

- **Wykonywanie Poleceń Asynchronicznych:**
  - Użycie metod takich jak `RunExternalCommandAsync` i `ExecuteCommandAsync`.
  - Wykonywanie poleceń `cmd` i `PowerShell` na zainfekowanym systemie.

- **Odwrócona Powłoka (Reverse Shell):**
  - Funkcja `StartReverseShellClient` umożliwia atakującemu interaktywny dostęp.

- **Eksfiltracja Danych:**
  - Funkcje `UploadFileAsync` i `DownloadFileAsync` służą do przesyłania plików między systemem ofiary a serwerem C2.

### 4.4. Komunikacja z Serwerem C2

*Komunikacja jest zabezpieczona i ukryta przed systemami detekcji.*

- **Szyfrowanie Ruchu:**
  - Użycie protokołu HTTPS i szyfrowania AES.

- **Dynamiczne Adresy C2:**
  - Odszyfrowywanie adresów z plików lub żądań sieciowych.

- **Podszywanie się pod Legalny Ruch:**
  - Fałszywe żądania sieciowe imitujące normalne usługi.

### 4.5. Techniki Obfuskacji i Unikania Wykrycia

- **Ukrywanie Ciągów Znaków:**
  - Zastosowanie zmodyfikowanego Base64 do ukrywania kluczowych informacji.

- **Obfuskacja Kodu:**
  - Utrudnienie analizy statycznej i dynamicznej.

- **Usuwanie Logów:**
  - Redukcja śladów działania malware w systemie.

---

## Gruntowna Analiza Kodu

### 5.1. Ukrywanie Ciągów Znaków

*Malware wykorzystuje niestandardowe algorytmy do ukrywania ważnych informacji.*

#### Przykład kodu:

```csharp
string encodedString = "Zm9vYmFy"; // Zmodyfikowany Base64
string decodedString = CustomBase64Decode(encodedString);
```

**Opis:**

- **CustomBase64Decode:** Funkcja do dekodowania zmodyfikowanego Base64.
- **Ukrywanie adresów C2 i innych ciągów:** Utrudnia analizę i wykrycie.

### 5.2. Dynamiczne Odszyfrowywanie Adresów C2

*Adresy serwerów C2 są odszyfrowywane w czasie rzeczywistym, co pozwala na ich dynamiczną zmianę.*

#### Przykład kodu:

```csharp
string encryptedC2 = File.ReadAllText("license");
string decryptedC2 = DecryptAES(encryptedC2, key);
```

**Opis:**

- **Czytanie z pliku:** Malware czyta zaszyfrowany adres z pliku w tym samym katalogu.
- **Deszyfrowanie AES:** Użycie algorytmu AES do odszyfrowania adresu.

### 5.3. Wykonywanie Poleceń Asynchronicznych

*Wykorzystanie asynchronicznych metod pozwala na efektywne zarządzanie zadaniami bez blokowania wątków.*

#### Przykład kodu:

```csharp
public async Task ExecuteCommandAsync(string command)
{
    var process = new Process
    {
        StartInfo = new ProcessStartInfo
        {
            FileName = "cmd.exe",
            Arguments = "/c " + command,
            RedirectStandardOutput = true,
            UseShellExecute = false,
            CreateNoWindow = true
        }
    };
    process.Start();
    string result = await process.StandardOutput.ReadToEndAsync();
    // Wysyłanie wyniku do serwera C2
}
```

**Opis:**

- **Asynchroniczne czytanie wyjścia:** `ReadToEndAsync()` pozwala na nieblokujące odczytanie danych.
- **Wykonywanie poleceń:** Umożliwia atakującemu zdalne uruchamianie komend.

---

## Podatności (CVE)

*Malware może wykorzystywać znane podatności do przeprowadzenia ataku.*

- **CVE-2023-38831:** Wykorzystywana do początkowej infekcji poprzez pliki CHM.
- **Inne podatności:** Atakujący mogą wykorzystywać luki w zabezpieczeniach systemu lub aplikacji.

*Regularne aktualizacje i łatanie systemów są kluczowe w zapobieganiu takim atakom.*

---

## Wskaźniki Kompromitacji (IOCs)

| **Typ**               | **Wartość**                                                |
|-----------------------|------------------------------------------------------------|
| Hash SHA-256          | `5afa6d4f9d79ab32374f7ec41164a84d2c21a0f00f0b798f7fd40c3dab92d7a8` |
| Hash SHA-256          | `5488dbae6130ffd0a0840a1cce2b5add22967697c23c924150966eaecebea3c4` |
| Hash SHA-256          | `c914343ac4fa6395f13a885f4cbf207c4f20ce39415b81fd7cfacd0bea0fe093` |
| Plik                  | `Policy_Formulation_Committee.exe`                         |
| Wpis rejestru         | Modyfikacje w `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` |
| Zaplanowane zadanie   | `WinNetServiceUpdate`                                      |
| Domeny C2             | Dynamicznie odszyfrowywane, brak twardo zakodowanych adresów |
| Nietypowe procesy     | Uruchomienie skryptów VBS lub plików wykonywalnych w nietypowych lokalizacjach |

---

## Środki Ochrony i Rekomendacje

*Ochrona przed tak zaawansowanym malware wymaga wielowarstwowego podejścia.*

### 8.1. Zalecenia dla Organizacji

1. **Edukacja i Świadomość:**
   - Regularne szkolenia pracowników na temat phishingu i socjotechniki.
   - Ostrzeganie przed otwieraniem załączników z nieznanych źródeł.

2. **Aktualizacje i Łatki:**
   - Regularne aktualizowanie systemów operacyjnych i aplikacji.
   - Monitorowanie informacji o nowych podatnościach.

3. **Monitorowanie Systemów:**
   - Wdrożenie systemów EDR (Endpoint Detection and Response).
   - Analiza logów systemowych i sieciowych pod kątem anomalii.

4. **Segmentacja Sieci:**
   - Ograniczenie dostępu między różnymi segmentami sieci.
   - Zastosowanie zasad minimalnych uprawnień.

5. **Kontrola Aplikacji:**
   - Użycie białych list aplikacji do ograniczenia uruchamiania nieautoryzowanego oprogramowania.
   - Monitorowanie i blokowanie podejrzanych procesów.

6. **Analiza Ruchu Sieciowego:**
   - Wykrywanie i analizowanie szyfrowanego ruchu HTTPS do nieznanych serwerów.
   - Implementacja inspekcji SSL/TLS.

7. **Implementacja DLP (Data Loss Prevention):**
   - Monitorowanie i kontrola przepływu danych w celu zapobiegania eksfiltracji.

---

## Wnioski

*Asyncshell jest przykładem zaawansowanego złośliwego oprogramowania, które ewoluuje, aby unikać wykrycia i zwiększać skuteczność ataków. Jego analiza pokazuje, jak ważne jest ciągłe doskonalenie środków bezpieczeństwa i edukacja użytkowników.*

**Kluczowe wnioski:**

- **Ewolucja zagrożeń:** Atakujący stale udoskonalają swoje narzędzia, co wymaga od obrońców ciągłego monitorowania i adaptacji.

- **Znaczenie wielowarstwowej ochrony:** Żaden pojedynczy środek nie jest wystarczający; konieczne jest połączenie technologii, procesów i edukacji.

- **Rola edukacji:** Użytkownicy są często najsłabszym ogniwem; ich świadomość znacząco wpływa na bezpieczeństwo organizacji.

*W obliczu takich zagrożeń organizacje muszą być proaktywne, inwestując w nowoczesne technologie bezpieczeństwa i kładąc nacisk na edukację personelu.*

---

## Bibliografia

1. **APT-K-47 武器披露之 Asyncshell 的前世今生**, 2024-11-22, Zespół 404 Advanced Threat Intelligence Team firmy KnownSec.
   - [Link do artykułu](https://paper.seebug.org/3240/)

2. **Analizy Techniczne:**
   - Materiały dostarczone przez użytkownika oraz wcześniejsze analizy przeprowadzone w ramach tego wątku.

3. **CVE Details:**
   - [CVE-2023-38831](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2023-38831)

4. **Kontakt z Ekspertami:**
   - Zespół 404 Advanced Threat Intelligence Team firmy KnownSec: Intel-APT@knownsec.com

---

*Ostrzeżenie*: Analiza złośliwego oprogramowania powinna być przeprowadzana wyłącznie przez wykwalifikowanych specjalistów w kontrolowanym środowisku. Prezentowane informacje i techniki mają charakter edukacyjny i nie powinny być wykorzystywane do celów niezgodnych z prawem lub etyką. Celem tego dokumentu jest edukacja i poprawa bezpieczeństwa systemów informatycznych.

---

> [Powrót do głównego dokumentu](README.md#analiza-malware-asyncshell)
>
> [Powrót na górę](#analiza-malware-asyncshell)