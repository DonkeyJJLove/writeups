# Zadania, referenty i granice testu

Każdy epizod to zamknięty, fikcyjny świat. Znaczenie pól i reguły sukcesu są podane wszystkim ramionom. Bliźniacze przypadki różnią się warunkiem decyzyjnym lub wynikiem, a nie tylko nazwą. W danych publicznych nie ma pola `gold`, nazwy rodziny ani numeru wariantu. Losowane są nazwy obiektów, wartości, kolejności oraz konkretne instancje.

| Rodzina | Co musi zrobić agent | Kontrfaktyczna różnica | Niezależne sprawdzenie |
|---|---|---|---|
| authority | Oddzielić notatkę od rzeczywistej zgody | Adresat uprawniony / poza zakresem | Predykat bieżącej listy zgód oraz odczytu |
| lineage | Policzyć źródła pierwotne, nie kopie | Dwa root / kilka kopii jednego root | Liczność różnych korzeni |
| state_update | Odczytać nowe zdarzenie i wyłączyć superseded | Inna rzeczywista zmiana wartości | Suma aktywnych zmian dokładnego referenta |
| recovery | Odzyskać obserwację po TIMEOUT | Backup dostępny / niedostępny | Stan faktycznie odczytanej usługi |
| bounded_evidence | Nie awansować niepełnego sprawdzenia do dowodu | Pełne pokrycie skończonego zbioru / timeout | Status i równość pokrycia domeny |
| global_constraint | Ocenić wspólny skutek lokalnych zgód | Suma w limicie / przekracza limit | Cała atomowa transakcja i suma |
| factor_count | Zaproponować poprawny podział CNF | Rozdzielone komponenty / dodatkowe sprzężenie | Niezależna pełna enumeracja małej instancji |
| linear_count | Wybrać reprezentację XOR i sprawdzić zależność | Równanie redundantne / sprzeczne | Niezależna enumeracja bitów |
| suffix_count | Dobrać pamięć automatu zachowującą zakazane wzorce | Inny wzorzec i wymagana pamięć | Niezależna enumeracja słów |
| cover_count | Grupować równe wiersze bez zmiany pytania | Obiekty etykietowane / nieetykietowane | Niezależna enumeracja podzbiorów |

Mapowanie na źródło jest interpretacją konstrukcyjną asystenta. Oryginalny materiał dotyczy m.in. różnicy prognozy od trajektorii, amortyzacji błędów oraz odzyskania kontroli. Prompt kompilatora definiuje pochodzenie, rolę, autorytet, relewancję i reinterpretację historii. Nie twierdzimy, że autor podał te konkretne zadania albo parametry testów.

## Portfolio, a nie solver podarowany jednemu ramieniu

Wszyscy mają `read`, `recover`, `enumerate`, `factor`, `eliminate`, `suffix`, `quotient`. `factor` nie podaje z góry poprawnego podziału: model musi przesłać grupy. `suffix` wymaga odpowiedniej pamięci; `quotient` wymaga klas i zachowania krotności zgodnie z referentem. Narzędzie odpowiada na błędne założenia jawną odmową/kontrprzykładem. Budżet enumeracji jest taki sam dla każdego ramienia.

## Czego nie zaliczać do wyniku

Brak tu testu dowolnego języka naturalnego, wszystkich domen rzeczywistych, długich autonomicznych misji, formalnie certyfikowanych dowodów i odkrywania nieznanych algorytmów. Przypadki zawierają jawny kontrakt i czytelne dane. To kontrolowana pierwsza falsyfikacja hipotezy efektu instrukcji, a nie gotowy zamiennik testu produkcyjnego.

## Gdy pilot jest zbyt łatwy

Jeżeli mocna kontrola jest blisko 100%, nie ma miejsca na wykazanie dużej dodatniej różnicy. Nie obniżaj wtedy jej jakości po to, by heurystyka wygrała. Zbuduj nowy, trudniejszy zbiór zgodny z docelowym zastosowaniem, zmień wersję generatorów, zamroź nowe kryteria i użyj nowych ziaren. Stary pilot pozostaje pilotem.

## Zewnętrzna replikacja

Osoba niezależna może dodać nowy generator, bez dostępu do wyników ramion, oraz oddzielny oracle. W tej wersji nie ma automatycznego importera dowolnych benchmarków ani gwarancji held-out-family generalization. Samo użycie nowych ziaren nie oznacza nowych rodzin.
