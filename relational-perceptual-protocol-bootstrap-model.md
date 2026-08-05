# Kotwiczony Protokół Reakcji Relacyjnej (KPRR)

## Pełna dokumentacja naukowo-techniczna i walidacja symulacyjna 20 000 eksperymentów

**Wersja:** 1.0 
**Data:** 5 sierpnia 2026  
**Seed walidacji:** `20260805`  
**Status dowodowy:** kompletny projekt mechanizmu, plan eksperymentu i walidacja obliczeniowa; brak danych z rzeczywistych prób Łobuz–Lilith–Szatan.

## Streszczenie

Kotwiczony Protokół Reakcji Relacyjnej jest mechanizmem aktywnego wytwarzania i przekazywania jednej sekwencji behawioralnej pomiędzy trzema agentami. Łobuz `A` dotyka wspólnej kotwicy `Z`, Lilith `B` orientuje się na Łobuza i sama dotyka `Z`, a jej kontakt staje się sygnałem dla Szatana `C`. Rozwiązanie nie ogranicza się do obserwacji, czy zachowania spontanicznie współwystępują. System automatycznie wzmacnia wyłącznie prawidłową zależność relacyjną, stopniowo kształtuje pełną odpowiedź odbiorcy, chroni wcześniej utworzoną krawędź `A → B` przed wygaszeniem podczas nauki `B → C` i opóźnia wydanie nagród do zamknięcia całego okna odpowiedzi, aby dźwięk podajnika nie stał się sygnałem zastępczym.

Regułę uznawania krawędzi za utworzoną skalibrowano w `20 000` eksperymentach Monte Carlo obejmujących osiem rodzin scenariuszy: silny protokół, słaby protokół, brak protokołu, wspólną reakcję na obiekt, naśladowanie pozycji, zależność od człowieka, synchronizację czasową i brak transferu po usunięciu Łobuza. Połowę prób wykorzystano do kalibracji, a połowę jako niezależny zbiór walidacyjny. Ostateczna reguła rozpoznała `91,52%` silnych protokołów w zbiorze walidacyjnym i nie zaakceptowała żadnego z `7500` negatywnych scenariuszy; górna granica dwustronnego `95%` przedziału Cloppera–Pearsona dla odsetka fałszywych akceptacji wyniosła `0,0492%`. Wynik ten dotyczy wyłącznie modelu symulacyjnego i nie stanowi dowodu, że trzy konkretne koty utworzą protokół.

## 1. Cel i twierdzenia podlegające testowi

Celem jest wytworzenie, utrzymanie i przeniesienie następującej sekwencji:

```text
A dotyka Z
→
B orientuje się na A
→
B dotyka Z
→
C orientuje się na B
→
C dotyka Z
```

Twierdzenie `H_AB` jest spełnione, gdy kontakt Łobuza z rogami zmienia częstość pełnej odpowiedzi Lilith w porównaniu z warunkami kontrolnymi.

Twierdzenie `H_BC` jest spełnione, gdy kontakt Lilith z rogami zmienia częstość pełnej odpowiedzi Szatana w porównaniu z warunkami kontrolnymi.

Twierdzenie `H_T` jest spełnione, gdy po całkowitym usunięciu Łobuza relacja `B → C` nadal spełnia tę samą regułę decyzyjną.

Ostateczny wynik dodatni wymaga:

```text
H_AB = 1
∧
H_BC = 1
∧
H_T = 1
```

Niepełne wykonanie łańcucha nie jest klasyfikowane jako pełny KPRR.

## 2. Zakres wnioskowania

Badanie dotyczy jednej konkretnej triady:

```text
A — Łobuz
B — Lilith
C — Szatan
Z — rogi
```

Jednostką analizy statystycznej jest próba behawioralna, lecz zwierzęta nie są niezależnymi replikami biologicznymi. Wynik może potwierdzić albo odrzucić istnienie protokołu w tej triadzie w danych warunkach. Nie pozwala samodzielnie wnioskować o populacji kotów, wszystkich systemach wieloagentowych ani zdolności do abstrakcyjnego języka.

Walidacja przedstawiona w sekcjach 11–12 jest symulacją działania reguły klasyfikacyjnej. Nie zastępuje nagrań, etogramu ani eksperymentu in vivo.

## 3. System wieloagentowy i graf dynamiczny

Zbiór agentów wynosi:

```text
N = {A, B, C}
```

Rogi są elementem środowiska, a nie agentem:

```text
Z ∉ N
```

Graf relacji w bloku pomiarowym `b` ma postać:

```text
G_b = (N, E_b, W_b)
```

Dla uporządkowanej pary `i → j` oblicza się:

```text
pᵢⱼ,normal
=
średnia częstość odpowiedzi
w dwóch blokach normalnych
```

```text
pᵢⱼ,control,max
=
max(
    pᵢⱼ,no-signal,
    pᵢⱼ,occluded,
    pᵢⱼ,position,
    pᵢⱼ,shifted
)
```

Waga krawędzi jest bezpośrednio mierzalna:

```text
wᵢⱼ
=
pᵢⱼ,normal
−
pᵢⱼ,control,max
```

Krawędź jest wpisywana do `E_b` wyłącznie po spełnieniu pełnego kryterium z sekcji 10. Oczekiwana sekwencja grafów wynosi:

```text
G₀: E = ∅

G₁: E = {A → B}

G₂: E = {A → B, B → C}

G₃ po usunięciu A:
E = {B → C}
```

Sam kontakt z rogami nie tworzy krawędzi. Krawędź oznacza, że zachowanie odbiorcy zależy od obserwowalnego działania nadawcy silniej niż od któregokolwiek kontrolowanego wyjaśnienia alternatywnego.

## 4. Aparatura

Obszar rejestrują dwie zsynchronizowane kamery o rozdzielczości co najmniej `1920 × 1080` i częstotliwości `25 kl./s`. Kamera górna służy do pomiaru pozycji, orientacji oraz widoczności agentów. Kamera boczna rozstrzyga kontakt nosa lub przedniej łapy z rogami. Zdarzenia są kodowane co `0,2 s`, czyli z częstotliwością `5 Hz`.

Podłoga zawiera cztery znaczniki kalibracyjne wyznaczające kwadrat `100 × 100 cm`. Współrzędne obrazu są przeliczane na centymetry przez homografię. Rogi pozostają w tej samej pozycji i orientacji przez cały eksperyment.

Każdy agent ma oddzielny automatyczny podajnik `D_A`, `D_B`, `D_C`, oddalony od rogów o co najmniej `1 m`. Żaden podajnik nie może zadziałać przed zamknięciem okna odpowiedzi ostatniego odbiorcy w danej próbie. Zapobiega to sytuacji, w której ruch lub dźwięk podajnika zastępuje sygnał społeczny.

Człowiek uruchamia system przed sesją, lecz podczas prób pozostaje poza obszarem widzenia i bez bezpośredniej interakcji z agentami.

## 5. Zmienne operacyjne

Dla agenta `i ∈ {A,B,C}` i chwili `t` rejestruje się:

```text
xᵢ(t), yᵢ(t)
```

Współrzędne środka tułowia w centymetrach.

```text
φᵢ(t)
```

Kierunek pyska od `0°` do `359°`, określony przez wektor od środka głowy do punktu pomiędzy uszami.

```text
dᵢZ(t)
```

Odległość nosa agenta od najbliższego punktu maski rogów.

```text
cᵢZ(t) ∈ {0,1}
```

Kontakt z rogami. Wartość `1` wymaga odległości nieprzekraczającej `2 cm` przez co najmniej dwa kolejne pomiary, czyli `0,4 s`.

```text
gⱼᵢ(t) ∈ {0,1}
```

Orientacja odbiorcy `j` na nadawcę `i`. Wartość `1` wymaga kąta nieprzekraczającego `20°` przez co najmniej `0,4 s`.

```text
zᵢ(t) ∈ {0,1}
```

Wejście do strefy rogów. Wartość `1` wymaga odległości środka tułowia od środka rogów nieprzekraczającej `40 cm` przez co najmniej `1 s`.

```text
vᵢⱼ(t) ∈ {0,1}
```

Widoczność nadawcy `i` dla odbiorcy `j`.

```text
h(t) ∈ {0,1}
```

Obecność człowieka w obszarze.

Przed uczeniem wykonuje się `10 min` swobodnego nagrania. Dla każdego agenta wyznacza się medianę dodatniej prędkości większej niż `5 cm/s`:

```text
ṽᵢ
=
mediana dodatniej prędkości ruchu agenta i
```

Maksymalną odległość możliwą w obszarze od rogów oznacza się `dmax`. Czas odpowiedzi jest indywidualny:

```text
TR(i)
=
ceil₀,₂(
    dmax / ṽᵢ + 1 s
)
```

gdzie `ceil₀,₂` oznacza zaokrąglenie w górę do wielokrotności `0,2 s`. Jeżeli wynik jest mniejszy niż `3 s`, przyjmuje się `TR(i)=3 s`.

Okres resetu wynosi:

```text
Treset
=
2 · max(TR(A), TR(B), TR(C))
```

Nowy sygnał jest liczony dopiero wtedy, gdy nadawca nie dotykał rogów przez pełny `Treset`.

Pełna odpowiedź `j` na sygnał `i` ma wartość:

```text
yᵢⱼ(k)=1
```

wyłącznie wtedy, gdy:

```text
1. nadawca jest widoczny w chwili tₖ,
2. odbiorca orientuje się na nadawcę w czasie 1 s,
3. odbiorca dotyka rogów do tₖ + TR(j).
```

W przeciwnym razie:

```text
yᵢⱼ(k)=0
```

## 6. Mechanizm aktywnego wytwarzania protokołu

### 6.1. Jednostka nagrody

Jedna jednostka nagrody wynosi `0,25%` zwykłej dziennej racji danego agenta. Nagroda pochodzi z dziennej racji; protokół nie wymaga głodzenia. Po osiągnięciu `10%` dziennej racji w jednej sesji sesja kończy się bez względu na liczbę prób.

Nie stosuje się kary, bodźców awersyjnych, przymusowego kontaktu ani fizycznego ustawiania agenta.

### 6.2. Kształtowanie odpowiedzi

Odbiorca przechodzi przez trzy poziomy. W danym poziomie nagradzane jest tylko aktualne kryterium.

```text
Poziom 1:
orientacja odbiorcy na nadawcę w ciągu 1 s

Poziom 2:
Poziom 1
+
wejście odbiorcy do strefy 40 cm w czasie TR

Poziom 3:
Poziom 1
+
kontakt odbiorcy z rogami w czasie TR
```

Przejście do następnego poziomu następuje po dwóch kolejnych blokach po `20` prób, w których aktualne kryterium zostało wykonane co najmniej `14` razy. Po przejściu do wyższego poziomu samo wykonanie niższego poziomu nie uruchamia nagrody.

Maksymalna liczba bloków na poziom wynosi `10`. Brak przejścia po `200` próbach oznacza przerwanie uczenia tej krawędzi i status `nie uzyskano akwizycji`.

### 6.3. Faza `A → B`

Każda próba rozpoczyna się od prawidłowo odseparowanego kontaktu Łobuza z rogami. Po zakończeniu okna odpowiedzi Lilith:

```text
jeżeli Lilith spełniła aktualny poziom:

    rA = 1
    rB = 1

w przeciwnym razie:

    rA = 0
    rB = 0
```

Nagroda Łobuza zależy zatem od skuteczności jego sygnału wobec Lilith, a nagroda Lilith — od prawidłowej reakcji na Łobuza.

Po zakończeniu Poziomu 3 przeprowadza się ocenę krawędzi `A → B` zgodnie z sekcjami 8–10.

### 6.4. Faza łańcuchowa `A → B → C`

Po utworzeniu `A → B` do obszaru wprowadzany jest Szatan. Kontakt Lilith z rogami, będący odpowiedzią na Łobuza, staje się początkiem okna odpowiedzi Szatana.

Żaden podajnik nie działa przed końcem okna `TR(C)`. Po jego zakończeniu stosuje się:

```text
rA(k)
=
yAB(k)
```

```text
rB(k)
=
yAB(k)
+
yBC(k)
```

```text
rC(k)
=
yBC(k)
```

Lilith zachowuje podstawową nagrodę za odpowiedź na Łobuza, więc wcześniej utworzona krawędź nie jest wygaszana podczas uczenia Szatana. Druga jednostka nagrody Lilith zależy od skutecznego uruchomienia Szatana. Jest to poprawka wobec wcześniejszej wersji, w której Lilith traciła całą nagrodę, gdy Szatan jeszcze nie umiał odpowiedzieć.

Szatan przechodzi te same trzy poziomy kształtowania co Lilith. W Poziomie 3 prawidłowa odpowiedź ma postać pełnego kontaktu z rogami.

### 6.5. Transfer `B → C` po usunięciu Łobuza

Po utworzeniu obu krawędzi Łobuz zostaje całkowicie usunięty z obszaru i z zasięgu bezpośredniego widzenia. Każdy prawidłowo odseparowany kontakt Lilith z rogami rozpoczyna próbę `B → C`.

Po zamknięciu okna Szatana:

```text
rB(k)
=
yBC(k)
```

```text
rC(k)
=
yBC(k)
```

Transfer nie wymaga, aby model wyjaśniał, dlaczego Lilith inicjuje kontakt. Wymaga, aby po jej kontakcie Szatan wykonywał pełną odpowiedź częściej niż w warunkach kontrolnych. Jeżeli nie uda się zebrać wymaganej liczby kontaktów Lilith, wynik brzmi `nierozstrzygnięty — niewystarczająca liczba sygnałów`, a nie `brak transferu`.

## 7. Sesje, dobrostan i warunki przerwania

Jedna sesja trwa maksymalnie `15 min` albo `20` prób — zależnie od tego, co nastąpi wcześniej. Dopuszczalne są najwyżej dwie sesje dziennie, oddzielone co najmniej `4 h`. Agent może w każdej chwili odejść od stanowiska.

Sesję przerywa się natychmiast w przypadku urazu, walki, uporczywego unikania stanowiska, silnego pobudzenia, dyszenia, długotrwałej wokalizacji alarmowej albo zachowania ocenionego przez opiekuna jako nietypowe i niepokojące. Po wystąpieniu konfliktu o nagrodę podajniki i odległości między nimi muszą zostać ponownie skonfigurowane przed kolejną sesją.

Realizacja in vivo wymaga wcześniejszej oceny prawnej, etycznej i weterynaryjnej adekwatnej do miejsca prowadzenia badania. Niniejszy dokument nie jest zgodą na eksperyment.

## 8. Próby oceniające i warunki kontrolne

Próby oceniające są sondami bez natychmiastowej nagrody zależnej od wyniku. Każdą sondę poprzedza jedna prawidłowa próba podtrzymująca z nagrodą. Zapobiega to uczeniu się na warunkach kontrolnych oraz ogranicza wygaszanie protokołu podczas oceny.

Dla każdej ocenianej krawędzi zbiera się:

```text
2 bloki normalne po 40 sond

1 blok no-signal po 40 sond

1 blok zasłoniętego nadawcy po 40 sond

1 blok pozycji bez kontaktu po 40 sond

1 blok obecności człowieka po 40 sond
```

Kontrola przesunięcia czasowego jest liczona offline z danych normalnych.

**Warunek normalny.** Nadawca, odbiorca i rogi są widoczni; człowiek jest nieobecny.

**No-signal.** Odbiorca ma dopasowaną pozycję początkową z tolerancją `10 cm`, ale nadawca nie dotyka rogów.

**Zasłonięty nadawca.** Odbiorca widzi rogi, lecz nie widzi nadawcy. Kontakt nadawcy jest rejestrowany z drugiej strony przegrody.

**Pozycja bez kontaktu.** Nadawca znajduje się w odległości do `10 cm` od swojej pozycji sygnałowej i ma orientację różniącą się najwyżej o `15°`, ale nie dotyka rogów.

**Obecność człowieka.** Człowiek stoi nieruchomo `2 m` od rogów i nie inicjuje interakcji.

**Przesunięcie czasowe.** Znaczniki prawdziwych sygnałów są przesuwane cyklicznie o:

```text
Δt
=
3 · TR(j)
```

i odpowiedzi są liczone ponownie.

Kolejność żywych warunków kontrolnych jest randomizowana przed rozpoczęciem oceny. Osoba kodująca nagrania nie zna hipotezy przypisanej do pliku ani wyniku nagradzania.

## 9. Kontrola jakości danych

Co najmniej `100` dodatnich i `100` ujemnych okien dla każdej klasy zdarzenia — kontakt, orientacja i wejście do strefy — jest kodowanych ręcznie. Automatyczny detektor może być używany w analizie głównej tylko wtedy, gdy względem kodowania referencyjnego osiąga:

```text
czułość ≥ 0,90

swoistość ≥ 0,94
```

Zakres ten odpowiada zakresowi błędu detekcji użytemu w 20 000 testów odporności. Jeżeli warunek nie jest spełniony, analiza tej klasy zdarzeń musi zostać wykonana ręcznie albo model wizyjny musi zostać ponownie wytrenowany.

Dwadzieścia procent sond jest niezależnie kodowanych przez drugiego obserwatora. Rozbieżności są rozstrzygane przed odblokowaniem nazw warunków.

Próba jest wykluczana wyłącznie z jednego z wcześniej określonych powodów:

```text
utrata tożsamości agenta,
zasłonięcie punktów wymaganych do pomiaru,
awaria synchronizacji kamer,
przedwczesne działanie podajnika,
obecność człowieka poza warunkiem kontrolnym,
brak pełnego Treset przed sygnałem.
```

Wykluczonej próby nie zastępuje się danymi z tego samego przedziału; zbiera się nową, pełną próbę.

## 10. Reguła decyzyjna

Dla każdej krawędzi `i → j` i każdego bloku `b`:

```text
pᵢⱼ,b
=
liczba pełnych odpowiedzi / 40
```

Dwa bloki normalne muszą niezależnie spełniać:

```text
pᵢⱼ,normal,1 ≥ 0.60

pᵢⱼ,normal,2 ≥ 0.60
```

Każdy z czterech warunków wykluczających — no-signal, zasłonięcie, pozycja i przesunięcie czasu — musi spełniać:

```text
pᵢⱼ,control ≤ 0.40
```

Średnia z dwóch bloków normalnych musi przewyższać każdy z tych warunków o co najmniej:

```text
pᵢⱼ,normal
−
pᵢⱼ,control
≥
0.30
```

Dodatkowo stosuje się jednostronny dokładny test Fishera porównujący połączone `80` prób normalnych z `40` dopasowanymi próbami no-signal:

```text
pFisher < 0.01
```

Bezwzględna zmiana częstości odpowiedzi po pojawieniu się nieruchomego człowieka nie może przekroczyć:

```text
|pᵢⱼ,human − pᵢⱼ,normal|
≤
0.30
```

Wszystkie warunki działają łącznie. Wysoki wynik normalny nie kompensuje wysokiego wyniku kontroli.

Pełny KPRR zostaje uznany za utworzony tylko wtedy, gdy regułę przejdą:

```text
A → B

B → C przy obecnym A

B → C po usunięciu A
```

Wynik niespełniający kryterium może być oznaczony jako `subthreshold`, lecz nie jest klasyfikowany jako protokół.

## 11. Walidacja 20 000 eksperymentów Monte Carlo

### 11.1. Podział prób

Wygenerowano dokładnie:

```text
8 rodzin scenariuszy
×
2500 eksperymentów
=
20 000 eksperymentów
```

Pierwsze `1250` eksperymentów z każdej rodziny utworzyło zbiór kalibracyjny `n=10 000`. Pozostałe `1250` utworzyło nieużywany wcześniej zbiór walidacyjny `n=10 000`.

### 11.2. Rodziny scenariuszy

| Rodzina | Prawdopodobieństwo normalne | Charakterystyczny warunek alternatywny |
| --- | --- | --- |
| silny protokół | `0,80–0,95` | wszystkie kontrole `0,05–0,20` |
| słaby protokół | `0,60–0,78`; transfer `0,55–0,72` | kontrole `0,15–0,35` |
| brak protokołu | `0,10–0,35` | wszystkie warunki `0,10–0,35` |
| wspólna reakcja na obiekt | `0,75–0,92` | zasłonięty nadawca `0,70–0,90` |
| naśladowanie pozycji | `0,75–0,92` | pozycja bez kontaktu `0,70–0,90` |
| zależność od człowieka | bez człowieka `0,15–0,45` | z człowiekiem `0,75–0,92` |
| synchronizacja czasowa | `0,70–0,90` | przesunięcie `0,65–0,88`; inne kontrole podwyższone |
| brak transferu | pierwsze dwie krawędzie `0,80–0,95` | `B → C` po usunięciu `A`: `0,15–0,40` |

Dla każdego eksperymentu osobno losowano czułość detektora z zakresu `0,90–0,99`, swoistość z zakresu `0,94–0,995` oraz koncentrację beta-binomialną `30–80`, wprowadzając nadmierną zmienność między blokami.

### 11.3. Kalibracja

Oceniono `2160` reguł kandydackich obejmujących:

```text
n ∈ {20,30,40,50,60}

minimalny wynik normalny
∈ {0,60;0,65;0,70;0,75}

maksymalny wynik kontrolny
∈ {0,30;0,35;0,40}

minimalną różnicę
∈ {0,25;0,30;0,35;0,40}

α ∈ {0,05;0,02;0,01}

maksymalny efekt człowieka
∈ {0,20;0,25;0,30}
```

Regułę wybierano wyłącznie na zbiorze kalibracyjnym. Musiała mieć `α=0,01`, minimalną różnicę co najmniej `0,30`, czułość dla silnego protokołu co najmniej `90%` i zero fałszywych akceptacji w scenariuszach negatywnych. Wybrano wariant o najmniejszej liczbie prób. Minimalne `n` spełniające warunek wyniosło `40`.

## 12. Wyniki walidacji

### 12.1. Zbiór niezależny

| Grupa                           | Akceptacje | N    | Odsetek  | 95% CI — dół | 95% CI — góra |
| ------------------------------- | ---------- | ---- | -------- | ------------ | ------------- |
| silny protokół                  | 1144       | 1250 | 0.915200 | 0.898362     | 0.930053      |
| słaby protokół                  | 40         | 1250 | 0.032000 | 0.022958     | 0.043322      |
| wszystkie scenariusze negatywne | 0          | 7500 | 0.000000 | 0.000000     | 0.000492      |

Dla scenariuszy negatywnych wynik `0/7500` nie oznacza matematycznie zerowego ryzyka. Dwustronny `95%` przedział Cloppera–Pearsona ma górną granicę `0,000492`, czyli `0,0492%`.

### 12.2. Wyniki według scenariusza

| Scenariusz                    | Liczba testów | Akceptacje — reguła końcowa | Odsetek — reguła końcowa | Akceptacje — reguła pierwotna | Odsetek — reguła pierwotna |
| ----------------------------- | ------------- | --------------------------- | ------------------------ | ----------------------------- | -------------------------- |
| silny protokół                | 1250          | 1144                        | 0.9152                   | 179                           | 0.1432                     |
| słaby protokół                | 1250          | 40                          | 0.0320                   | 0                             | 0.0000                     |
| brak protokołu                | 1250          | 0                           | 0.0000                   | 0                             | 0.0000                     |
| wspólna reakcja na obiekt     | 1250          | 0                           | 0.0000                   | 0                             | 0.0000                     |
| naśladowanie pozycji          | 1250          | 0                           | 0.0000                   | 0                             | 0.0000                     |
| zależność od człowieka        | 1250          | 0                           | 0.0000                   | 0                             | 0.0000                     |
| synchronizacja czasowa        | 1250          | 0                           | 0.0000                   | 0                             | 0.0000                     |
| brak transferu po usunięciu A | 1250          | 0                           | 0.0000                   | 0                             | 0.0000                     |

### 12.3. Porównanie z wcześniejszą regułą

Wcześniejsza reguła wymagała jednocześnie:

```text
wynik normalny ≥ 0,75

kontrola ≤ 0,25

różnica ≥ 0,50

p < 0,01

efekt człowieka ≤ 0,20
```

Na tym samym zbiorze walidacyjnym zaakceptowała tylko `179/1250`, czyli `14,32%`, silnych protokołów. Nie generowała fałszywych akceptacji, lecz odrzucała większość przypadków spełniających założenia silnego protokołu. Została więc zastąpiona regułą końcową.

Słaby protokół został zaakceptowany w `40/1250`, czyli `3,20%`, przypadków. Jest to konsekwencja przyjętej definicji: dokument identyfikuje stabilny, silny i odporny na kontrole protokół, a nie każdą statystycznie dostrzegalną zależność.

## 13. Poprawki wprowadzone do wersji ostatecznej

Pierwsza wersja mierzyła zależność, ale nie wytwarzała jej. Wersja końcowa zawiera automatyczną, warunkową regułę nagrody.

Wcześniejsze nagrodzenie Lilith wyłącznie wtedy, gdy Szatan odpowiadał, mogło wygaszać `A → B` podczas początkowej nauki Szatana. Wersja końcowa zachowuje podstawową nagrodę Lilith za `yAB` i dodaje drugą jednostkę za `yBC`.

Wcześniejsze natychmiastowe uruchomienie podajników po kontakcie Lilith mogło dostarczyć Szatanowi dźwiękowego sygnału zastępczego. Wersja końcowa blokuje każdy podajnik do końca okna `TR(C)`.

Wprowadzono trzy poziomy kształtowania, aby mechanizm nie zależał od przypadkowego pojawienia się od razu pełnej odpowiedzi.

Wprowadzono sondy przeplatane próbami podtrzymującymi, aby testy kontrolne nie stały się treningiem ani długą procedurą wygaszania.

Krawędź grafu jest ważona względem najsilniejszego wyjaśnienia kontrolnego, a nie wyłącznie względem losowego okna bez sygnału.

Pierwotne progi `0,75/0,25/0,50` zastąpiono progami skalibrowanymi `0,60/0,40/0,30`, działającymi łącznie z czterema kontrolami i testem dokładnym.

Brak odpowiedniej liczby spontanicznych sygnałów Lilith po usunięciu Łobuza otrzymał status `nierozstrzygnięty`, zamiast być automatycznie uznawany za brak zdolności.

## 14. Ostateczny algorytm wykonawczy

```text
FAZA 0 — KALIBRACJA

1. Zsynchronizuj kamery.
2. Skalibruj podłogę i maskę rogów.
3. Nagraj 10 min ruchu bez nagrody.
4. Oblicz TR(A), TR(B), TR(C) i Treset.
5. Zweryfikuj czułość i swoistość detektorów.

FAZA 1 — A → B

6. Ustaw poziom B = 1.
7. Czekaj na prawidłowy kontakt A z Z.
8. Otwórz okno odpowiedzi B.
9. Po zamknięciu okna:
      jeśli B spełni poziom:
          wydaj 1 jednostkę A i 1 jednostkę B;
      w przeciwnym razie:
          nie wydawaj nagrody.
10. Po dwóch blokach 14/20 przejdź do następnego poziomu.
11. Po Poziomie 3 wykonaj pełną ocenę A → B.
12. Jeżeli krawędź nie przejdzie oceny, nie przechodź do transferu.

FAZA 2 — A → B → C

13. Wprowadź C i ustaw poziom C = 1.
14. Czekaj na kontakt A z Z.
15. Oceń odpowiedź B.
16. Jeżeli B dotknie Z, otwórz okno odpowiedzi C.
17. Nie uruchamiaj żadnego podajnika przed końcem okna C.
18. Po zamknięciu:
      rA = yAB
      rB = yAB + yBC
      rC = yBC
19. Po dwóch blokach 14/20 przejdź C do następnego poziomu.
20. Po Poziomie 3 wykonaj ocenę B → C przy obecnym A.

FAZA 3 — TRANSFER

21. Usuń A całkowicie z obszaru.
22. Czekaj na prawidłowo odseparowany kontakt B z Z.
23. Otwórz okno odpowiedzi C.
24. Po zamknięciu:
      rB = yBC
      rC = yBC
25. Zbierz dwa bloki normalne i wszystkie kontrole.
26. Zastosuj regułę z sekcji 10.

DECYZJA

27. Jeżeli A → B, B → C przy A oraz B → C bez A przechodzą regułę:
      KPRR = UTWORZONY.
28. Jeżeli liczba sygnałów jest niewystarczająca:
      KPRR = NIEROZSTRZYGNIĘTY.
29. W pozostałych przypadkach:
      KPRR = NIE WYKAZANO.
```

## 15. Schemat danych

Każdy wiersz pliku zdarzeń odpowiada jednej próbie i zawiera co najmniej:

```text
study_id
session_id
trial_id
phase
condition
sender
receiver
t_signal_s
sender_visible
orientation_latency_s
zone_entry_latency_s
contact_latency_s
response
reward_sender_units
reward_receiver_units
human_present
sender_occluded
position_control
valid_trial
exclusion_reason
video_file
annotator_id
```

Gotowy nagłówek znajduje się w pliku `KPRR_event_data_template.csv`.

## 16. Reguły interpretacji

```text
UTWORZONY
=
wszystkie trzy wymagane krawędzie przechodzą kryterium

SUBTHRESHOLD
=
zależność istnieje, ale nie spełnia pełnego kryterium odporności

NIE WYKAZANO
=
zebrano komplet danych i kryterium nie zostało spełnione

NIEROZSTRZYGNIĘTY
=
nie zebrano wymaganej liczby ważnych prób
albo jakość detekcji nie przeszła kontroli
```

Sformułowanie `utworzony` odnosi się do operacyjnie zdefiniowanej sekwencji behawioralnej. Nie oznacza dowodu intencji, semantyki ani świadomego rozumienia.

## 17. Ograniczenia

Model dotyczy jednej triady i jednej kotwicy. Nie rozstrzyga, czy zachowanie generalizuje na inne obiekty, miejsca albo agentów.

Nagroda może utworzyć silne warunkowanie instrumentalne bez komunikacji semantycznej. Kontrole wykazują zależność relacyjną, lecz nie dowodzą świadomej intencji nadawcy.

Próby tego samego zwierzęcia są czasowo zależne. Kontrola przesunięcia czasu i dwa niezależne bloki ograniczają ten problem, ale nie tworzą biologicznych replik.

Symulacja zakłada określone przedziały prawdopodobieństw, błędów detektora i nadmiernej zmienności. Wyniki poza tymi zakresami mogą różnić się od raportowanych.

Walidacja `20 000` eksperymentów sprawdza regułę wykrywania i odrzucania konfuzji. Nie modeluje neurologii ani rzeczywistej szybkości uczenia konkretnych kotów.

Kontrola zasłonięcia zmienia środowisko i sama może wpływać na zachowanie. Dlatego jest interpretowana razem z pozostałymi kontrolami, a nie samodzielnie.

## 18. Reprodukowalność

Pakiet zawiera:

```text
KPRR_final_documentation.md
KPRR_simulation_20000.py
KPRR_monte_carlo_20000_runs.csv
KPRR_monte_carlo_summary.csv
KPRR_threshold_grid.csv
KPRR_threshold_grid_top25.csv
KPRR_event_data_template.csv
KPRR_manifest.json
```

Uruchomienie:

```bash
python KPRR_simulation_20000.py
```

wymaga bibliotek:

```text
numpy
pandas
scipy
```

## Bibliografia

1. Percie du Sert, N. i in. *The ARRIVE Guidelines 2.0: Updated Guidelines for Reporting Animal Research*. PLOS Biology, 2020, 18(7), e3000410. DOI: 10.1371/journal.pbio.3000410.
2. Parlament Europejski i Rada Unii Europejskiej. *Dyrektywa 2010/63/UE w sprawie ochrony zwierząt wykorzystywanych do celów naukowych*, tekst skonsolidowany.
3. Lowe, R., Foerster, J., Boureau, Y.-L., Pineau, J., Dauphin, Y. *On the Pitfalls of Measuring Emergent Communication*. 2019, arXiv:1903.05168.
4. Jaques, N. i in. *Social Influence as Intrinsic Motivation for Multi-Agent Deep Reinforcement Learning*. Proceedings of Machine Learning Research, 2019, 97, 3040–3049.
5. Olfati-Saber, R., Fax, J. A., Murray, R. M. *Consensus and Cooperation in Networked Multi-Agent Systems*. Proceedings of the IEEE, 2007, 95(1), 215–233. DOI: 10.1109/JPROC.2006.887293.
6. Lauer, J. i in. *Multi-animal pose estimation, identification and tracking with DeepLabCut*. Nature Methods, 2022, 19, 496–504. DOI: 10.1038/s41592-022-01443-0.
7. Pereira, T. D. i in. *SLEAP: A deep learning system for multi-animal pose tracking*. Nature Methods, 2022, 19, 486–495. DOI: 10.1038/s41592-022-01426-1.
8. Arahori, M. i in. *Cats Did Not Change Their Problem-Solving Behaviours after Observing a Human Demonstrator*. Animals, 2023, 13(6), 984. DOI: 10.3390/ani13060984.
