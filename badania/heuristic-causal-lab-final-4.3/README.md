# Od heurystyki do architektury myślenia

## Co naprawdę pokazuje Heuristic Causal Lab

To badanie nie jest przede wszystkim testem jednej konkretnej heurystyki. Ta heurystyka była materiałem wejściowym: spontanicznym, częściowo chaotycznym tekstem, który nie powstał jako specyfikacja systemu agentowego. Właśnie dlatego wynik jest interesujący. Jeżeli nawet taki tekst potrafi w kontrolowanym układzie tak wyraźnie zmienić zachowanie tego samego modelu, przy tych samych narzędziach i tym samym zestawie zadań, to istotnym przedmiotem dalszych badań staje się nie sam tekst, lecz **sposób konstruowania struktur semantycznych, które organizują rozumowanie modelu**.

Pełne badanie confirmatory objęło 10 240 epizodów w 256 blokach generatora. Każde ramię otrzymało 5120 prób. Tekst autora osiągnął 1102 przypadki `safe_success`, kontrola aktywna 351. Różnica wyniosła **14,7 punktu procentowego**, a sparowany przedział dla kontrastu głównego wyniósł **[13,4; 15,9] pp**. Równolegle poprawność zadania wzrosła o 17,1 pp, poprawność epistemiczna o 15,0 pp, poprawne zatrzymanie o 14,5 pp, a poprawność protokołu o 21,8 pp. Efekt nie jest więc widoczny wyłącznie w jednym złożonym scorerze; pojawia się na kilku oddzielnie raportowanych osiach zachowania.

Jednocześnie formalny werdykt badania pozostaje negatywny: `CONTRADICTED_SAFETY_OR_UTILITY_IN_SCOPE`. Powód jest ważny metodologicznie. Hipoteza była silniejsza niż „tekst autora będzie lepszy od kontroli”. Wymagała również wystarczająco wysokiej użyteczności bezwzględnej. Na zadaniach wykonalnych poziom autora wyniósł około 13,8%, a więc bardzo daleko od uprzednio zamrożonego progu. To znaczy, że eksperyment **nie potwierdził gotowego, niezawodnego systemu**, ale jednocześnie wykazał duży i powtarzalny wpływ architektury instrukcji na zachowanie modelu.

## Heurystyka jako geometria problemu

Klasyczny prompt mówi modelowi, co ma zrobić. Heurystyka semantyczna może pełnić inną funkcję: ustawiać **układ współrzędnych**, w którym model interpretuje późniejszy problem. Nie chodzi wtedy o instrukcję „jeżeli X, zrób Y”, lecz o trwałe rozróżnienia: źródło nie jest informacją, obserwacja nie jest interpretacją, lokalna poprawność nie oznacza globalnej dopuszczalności, niepewność nie jest pewnością, a wynik narzędzia nie musi oznaczać przyznania nowego autorytetu.

W takim ujęciu tekst tworzy lokalną ontologię roboczą. Definiuje, jakie typy rzeczy mają znaczenie, jakie relacje należy śledzić, co może zmienić stan oraz jakie przejścia pomiędzy stanami są niedopuszczalne lub wymagają dodatkowej podstawy. Model nie dostaje gotowego rozwiązania. Dostaje **strukturę, w której pewne klasy rozumowania są naturalniejsze, a inne wymagają pokonania dodatkowej bariery semantycznej**.

To właśnie można nazwać architekturą myślenia. Nie jest to zmiana wag sieci neuronowej. Jest to architektura aktywnego kontekstu: porządek bytów, relacji, priorytetów, niezmienników, warunków przejścia i bramek decyzyjnych. Jeżeli taka struktura jest wystarczająco spójna, może wpływać na cały przebieg pracy agenta, a nie tylko na stylistykę jego odpowiedzi.

## Dlaczego rozkład wyników jest ważniejszy niż sama średnia

Najbardziej interesujący rezultat nie polega na samych 14,7 pp. Ważniejsze jest to, **gdzie** pojawia się przewaga.

W zadaniach dotyczących pochodzenia danych tekst autora uzyskał 348 sukcesów na 512 prób wobec 83 dla kontroli. W zadaniach granic dowodu: 423 wobec 190. W ograniczeniach globalnych: 147 wobec 19. W uprawnieniach: 136 wobec 52. Są to rodziny, w których sukces zależy przede wszystkim od prawidłowego rozpoznania relacji między informacją, źródłem, zakresem dowodu, autorytetem i konsekwencją działania.

Tymczasem w czterech rodzinach zadań stricte zliczeniowych — faktoryzacji, algebrze liniowej, pamięci sufiksowej i exact cover — oba ramiona uzyskały zero pełnych sukcesów. To ogranicza łatwą narrację, że tekst po prostu „zwiększył inteligencję”. Wynik ma **profil funkcjonalny**. Efekt jest silny tam, gdzie problem przypomina relacyjną strukturę heurystyki, i nie pojawia się tam, gdzie dominującą trudnością jest czysta kombinatoryka.

Podobny wzorzec widać w parach kontrfaktycznych. Oba warianty tej samej sytuacji zostały poprawnie rozwiązane 315 razy po stronie autora i 40 razy po stronie kontroli. To sugeruje, że tekst nie wymusza jednej statycznej odpowiedzi. Pomaga częściej **zmieniać decyzję wraz ze zmianą stanu świata**.

Równie ważne jest zachowanie budżetu generacji. Kontrola aktywna wyczerpała limit bez poprawnej akcji w 4126 epizodach, tekst autora w 3007. Łączna liczba tokenów generacji była niższa po stronie autora, mimo większej liczby poprawnych rozstrzygnięć. Nie jest to dowód na zmniejszenie „przestrzeni latentnej”, ale jest zgodne z hipotezą, że lepsza organizacja relewancji może ograniczać bezproduktywne błądzenie.

## Jak projektować mniej losową heurystykę

Jeżeli ten kierunek ma stać się technologią, następna heurystyka nie powinna powstawać przez dopisywanie kolejnych rad do promptu. Powinna być projektowana jak **mikroarchitektura poznawcza**.

Punktem wyjścia jest ontologia robocza: minimalny zestaw kategorii, których system nie powinien ze sobą sklejać. Dalej powstają relacje: `pochodzi_z`, `potwierdza`, `falsyfikuje`, `uprawnia`, `ogranicza`, `zmienia_znaczenie`, `zależy_od`. Następnie definiowane są niezmienniki — lokalne „prawa fizyki” świata modelu. Przykładowo: dane nie dziedziczą autorytetu z formy gramatycznej; brak obserwowalności nie zwiększa uprawnień; niepewności nie wolno automatycznie promować do pewności; lokalna poprawność nie gwarantuje globalnej dopuszczalności.

Kolejna warstwa to dynamika stanu. Nowa informacja nie powinna tylko dopisywać kolejnego rekordu. Musi móc zmienić znaczenie wcześniejszych obserwacji: obniżyć zaufanie do źródła, zmienić rolę bytu, unieważnić relację, zwiększyć relewancję starego sygnału albo ujawnić nowy konflikt. Dopiero wtedy otrzymujemy mutator semantyczny, a nie statyczny prompt.

Potem potrzebna jest warstwa saliencji: co w aktualnym stanie jest krytyczne, co pomocnicze, a co należy chwilowo odsunąć. Następnie bramki epistemiczne i wykonawcze: wiedza nie jest jeszcze decyzją, decyzja nie jest jeszcze uprawnieniem, a uprawnienie nie jest jeszcze wykonaniem. Na końcu powinien istnieć mechanizm odzyskiwania kontroli: system nie ma być projektowany tak, aby nigdy się nie pomylił, lecz tak, aby błąd nie niszczył możliwości dalszej korekty.

W tym sensie dobrze skonstruowana heurystyka nie jest algorytmem. Algorytm mówi:

```text
A -> B -> C -> D
```

Heurystyka architektoniczna mówi raczej:

```text
B jest naturalnym kolejnym stanem po A,
C wymaga dodatkowego dowodu,
D jest niedostępne bez zmiany autorytetu,
E staje się relewantne dopiero po sygnale X,
a pojawienie się Y unieważnia wcześniejsze znaczenie B.
```

To nie determinuje jednej trajektorii. **Kształtuje pole możliwych trajektorii**.

## Co w obecnym wyniku trzeba poprawić

Badanie pokazuje również koszt aktywizacji modelu. Tekst autora zwiększył liczbę poprawnych wyników i poprawnych decyzji, ale zwiększył też liczbę epizodów zawierających co najmniej jedno niepoparte twierdzenie: 737 wobec 380. Jednocześnie wśród rozpoznawalnych decyzyjnych prób finalnych warunkowy odsetek nieprawidłowych twierdzeń epistemicznych był niższy po stronie autora niż kontroli. Oznacza to, że prosty licznik niepopartych twierdzeń miesza dwa efekty: jakość pojedynczej decyzji i znacznie większą liczbę decyzji podejmowanych przez bardziej aktywny system.

To wskazuje bardzo konkretny kierunek rozwoju. Architektura nie może jedynie zwiększać relewancji i sprawczości. Musi zawierać mocniejszy tor:

```text
relewantność -> hipoteza -> podstawa -> kalibracja -> autorytet -> decyzja -> działanie
```

Innymi słowy: nie wystarczy nauczyć system szybciej widzieć strukturę problemu. Trzeba jeszcze nauczyć go **nie finalizować znaczenia przedwcześnie**.

Obecna heurystyka nie była projektowana laboratoryjnie. Zawierała metafory, powtórzenia i stylistyczny szum. Nie wiadomo, które z tych elementów pomagają, które są neutralne, a które szkodzą. To nie jest wada obecnego eksperymentu — jego celem było sprawdzenie zamrożonego pakietu. Dla kolejnego etapu oznacza natomiast konieczność ablacji: osobno provenance, authority, uncertainty, global constraints, feedback/recovery, narrative framing i kontrolowany szum. Dopiero wtedy będzie można przejść od stwierdzenia „ten tekst działa inaczej” do „ta konkretna struktura odpowiada za określoną część efektu”.

## Wniosek

Formalnie badanie nie potwierdziło gotowości systemu do użycia. I dobrze: próg był postawiony znacznie wyżej niż samo zwycięstwo nad kontrolą.

Jednocześnie wyniki są wystarczająco silne, aby potraktować semantyczne heurystyki poważniej niż jako odmianę prompt engineeringu. Przy tym samym modelu i tych samych narzędziach zmiana pakietu organizującego znaczenie przesunęła kilka niezależnych osi zachowania, a największe efekty pojawiły się właśnie w rodzinach wymagających rozumienia źródła, zakresu dowodu, autorytetu i relacji lokalne-globalne.

To sugeruje szerszą możliwość: **heurystykę można projektować jako zewnętrzną architekturę poznawczą dla systemu generatywnego**.

Kompilator semantyczny miałby wtedy bardzo konkretną rolę. Nie pisałby „lepszych promptów”. Brałby ludzką, relacyjną wiedzę o problemie i kompilował ją do jawnej struktury: ontologii, relacji, niezmienników, stanu, mutacji, saliencji i bramek działania.

Nie zmieniałby samej inteligencji modelu.

Projektowałby **warunki, w których ta inteligencja organizuje własne działanie**.

---

## Materiały badawcze

- [Raport wynikowy — HTML](./report.html)
- [Agregaty, kontrasty i werdykt — summary.json](./summary.json)
- [Dane wszystkich epizodów — trials.csv](./trials.csv)
- [Pełny protokół badania](./hcl_final_4_3/FULL_STUDY_PROTOCOL.md)
- [Dokumentacja i kod Heuristic Causal Lab](./hcl_final_4_3/README.md)
- [Artefakty dowodowe i audytowe](./hcl_final_4_3/evidence/)
- [Polityki eksperymentalne](./hcl_final_4_3/policies/)
- [Materiały źródłowe](./hcl_final_4_3/sources/)
- [Testy instrumentu](./hcl_final_4_3/tests/)

> Uwaga: trzy pierwsze odsyłacze są przeznaczone dla kanonicznych eksportów końcowych umieszczonych obok tego pliku. Po dodaniu `report.html`, `summary.json` i `trials.csv` linki zaczną działać bez zmiany dokumentu.
