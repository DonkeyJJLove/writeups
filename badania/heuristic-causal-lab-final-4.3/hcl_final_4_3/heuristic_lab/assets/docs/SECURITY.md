# Bezpieczeństwo i integralność

Agent nie otrzymuje shella, dowolnego Pythona, plików prywatnych, sieci ani realnej skrzynki pocztowej. `execute` oznacza propozycję w pamięci symulatora. Nie wywołuje wysyłki, przelewu, kasowania plików ani zarządzania serwerem. Nie używamy `eval`/`exec` do treści modelu.

Wszystkie ramiona mają taki sam checker i guard. Ocena zamiaru poprzedza guard. Zablokowana zła akcja nie daje modelowi punktów za bezpieczeństwo. Poprawne odpowiedzi liczone są tylko wtedy, gdy model rzeczywiście odniósł się do dostępnych obserwacji, a nie wymyślił receipt.

Domyślnie dozwolony jest wyłącznie loopback. Wyłączono użycie zmiennych HTTP_PROXY oraz przekierowania HTTP, by lokalna konfiguracja nie przekazała tekstu przypadkowemu proxy. Zdalny endpoint wymaga `allow_remote: true`, HTTPS oraz jawnego uruchomienia `--confirm-inference`. Lokalny proxy może w rzeczywistości przesyłać dane dalej; program nie może tego udowodnić z samego adresu. Nazwy/metadata deklarujące modele cloud są blokowane bez zgody.

Nie wkładaj klucza API do URL ani konfiguracji. Adapter może odczytać klucz z nazwy zmiennej `api_key_env`. Loguje się nazwę zmiennej, nie wartość klucza. Błędy i odpowiedzi serwera mogą zawierać fragmenty promptu; traktuj katalog badania jako dane wrażliwe. Surowa heurystyka i pełne publiczne zadania trafiają do wybranego modelu przy prawdziwym `run`.

Hashe manifestu, strategii, kodu i trial nie są podpisami instytucjonalnymi. Osoba kontrolująca wszystkie pliki mogłaby sfabrykować spójny transcript. Replay wykrywa zwykłe zmiany, niespójne narzędzia, błędne oceny i artefakty niezgodne z harmonogramem; nie daje niepodrabialnego dowodu historycznego. Niezależny operator/archiwizacja przed badaniem to dodatkowy krok organizacyjny.

Zmiana kodu lub strategii po zamrożeniu unieważnia zgodność źródeł. Nie używaj `check_source=False` do raportowania wniosków badawczych. Taka opcja wewnętrzna służy tylko diagnostyce archiwów.

Testowe HTTP serwery w `tests/` są jawnymi atrapami protokołu, nie lokalnie uruchomionymi modelami językowymi. Nie mieszamy liczby żądań testowych z liczbą wywołań inferencji.
