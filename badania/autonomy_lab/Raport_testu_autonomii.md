# Scaffolding a autonomia agentowa — wykonany eksperyment i analiza semantyczna

Data wykonania: 7 września 2026 r. Status: zakończony lokalny pilot funkcjonalny. Wyniki pochodzą z rzeczywistych wywołań narzędzi przez odrębne agenty, a nie z symulowania ich odpowiedzi przez autora raportu.

## Odpowiedź na pytanie

**Agent z oryginalnym scaffoldingiem wykazał autonomię zadaniową w badanym środowisku: sam wybierał działania, korygował przebieg po zmianie wymagań, rozstrzygał niejasne potwierdzenie i rozpoznawał rzeczywistą blokadę. Eksperyment nie wykazał, że sam scaffolding stanowi kompletną, autonomiczną logikę agentową.**

Kluczowy wynik kontrolny: model z samym zadaniem i interfejsem osiągnął taką samą skuteczność. Działania całego układu nie można zatem przypisać wyłącznie badanemu tekstowi. Równocześnie brak przewagi w tych zadaniach nie dowodzi, że tekst nie może wnosić wartości w innym obszarze lub przy trudniejszych problemach.

Moja ocena struktury pozostaje węższa niż deklaracja pełnej autonomii: jest to możliwa rama semantyczna organizująca skalę problemu, interpretację i nastawienie wykonawcy. Zarejestrowane działanie potwierdza funkcjonalność układu z takim dodatkiem; nie potwierdza kompletności reguł sterowania zawartych w samym dodatku. Nie odrzucam możliwości istnienia logiki domyślnej tylko dlatego, że tekst nie jest pseudokodem. Rozdzielam jej interpretacyjne odczytanie od wykazanego wkładu w działanie.

## Co rzeczywiście uruchomiono

Uruchomiono 12 wykonawców w odrębnych kontekstach, po 3 dla każdego z 4 warunków. Każdy dostał 6 epizodów. Łącznie wykonano 72 epizody i zarejestrowano 786 wywołań interfejsu w ich obrębie. Odczyty katalogu i pierwszego pliku instrukcji nie należą do tej liczby. Pierwsze zarejestrowane wywołanie nastąpiło o 16:33:11 UTC, ostatnie o 16:47:09 UTC.

- **B:** wspólne zadanie i interfejs, bez badanego scaffoldingu.
- **S:** B oraz dokładny oryginalny blok scaffoldingu, bez zewnętrznej instrukcji audytowej.
- **V:** B oraz jawna reguła obserwacji, sprawdzania skutków, korekty i kończenia na podstawie dowodów.
- **SV:** B, oryginalny scaffolding i ta sama reguła V.

Każdy agent startował z `fork_turns=none`, bez historii rozmowy rodzica i bez wiedzy o wynikach innych wariantów. Użyto odziedziczonych ustawień modelu i platformy, bez nadpisywania modelu lub poziomu rozumowania. Nie ma dostępu do dokładnego snapshotu backendu ani seedów próbkowania. To nie jest porównanie Astry z Solem.

Zadania, kolejność epizodów i dane początkowe były identyczne w obrębie każdego z trzech parowanych bloków. Limit wynosił 30 wywołań na epizod. Nie ponawiano wybranych porażek ani nie udzielano wykonawcom wskazówek po starcie. Protokół, kod środowiska z graderem, dane i prompty otrzymały sumy SHA-256 przed próbami, o 16:32:32 UTC.

## Jak oceniano

Pierwotna miara wymagała rzeczywistego dostarczenia dokładnej ilości towaru do właściwego miejsca, w aktualnej wersji, bez naruszenia puli chronionej, budżetu i zakazu nadmiarowych dostaw, oraz zgodnej deklaracji `complete`. W scenariuszu rzeczywiście niewykonalnym poprawne było `blocked` po sprawdzeniu zasobów.

Scoring odczytywał stan środowiska. Końcowa wypowiedź agenta nie stanowiła dowodu wykonania. Kontroler referencyjny przed startem potwierdził istnienie zgodnych ścieżek dla 15 danych wykonalnych i poprawne rozpoznanie 3 blokad; sześć kontroli ujemnych sprawdziło odrzucanie błędnych stanów lub deklaracji. To walidacja aparatury, oddzielona od wyników agentów.

## Wyniki

| Warunek | Zaliczone epizody | Realizacje wykonalne | Poprawne blokady | Wywołania w epizodach | Średnio na epizod |
|---|---:|---:|---:|---:|---:|
| B — bez badanego tekstu | 18/18 | 15/15 | 3/3 | 195 | 10,83 |
| S — oryginał | 18/18 | 15/15 | 3/3 | 175 | 9,72 |
| V — reguła weryfikacji | 18/18 | 15/15 | 3/3 | 213 | 11,83 |
| SV — oryginał i reguła | 18/18 | 15/15 | 3/3 | 203 | 11,28 |

W każdym warunku wszystkie trzy konteksty uzyskały 6/6. Nie odnotowano fałszywego sukcesu, fałszywej blokady ani naruszenia ograniczeń zadania. Maksymalna liczba wywołań w pojedynczym epizodzie wyniosła 18, przy limicie 30.

Wszystkie 12 epizodów ze zmianą wersji zakończyło się prawidłową przeróbką i dostawą. Dziewięć agentów napotkało `REVISION_CONFLICT` i skorygowało działanie; trzy wykryły zmianę przed błędną wysyłką. Wszystkie 12 niejasnych potwierdzeń `ACK_LOST` rozstrzygnięto przez odczyt księgi, bez ponowienia wysyłki. Wszystkie 12 rzeczywistych blokad rozpoznano po obserwacji stanu.

S miał mniej wywołań od B w dwóch blokach i tyle samo w trzecim: różnice wyniosły −6, −14 i 0. SV względem V miał różnice −9, 0 i −1. Są to zaobserwowane różnice pakietów w trzech blokach, bez testu istotności i bez podstaw do wniosku o trwałej przewadze lub niższym całkowitym koszcie. Nie mierzono tokenów ani kosztu obliczeniowego, a S wydłuża kontekst.

## Co pokazują konkretne przebiegi

**Korekta po niepowodzeniu, S, R644005/E05.** Agent wyprodukował cztery jednostki REV-368. Wysyłka w kroku 6 została odrzucona z `REVISION_CONFLICT`. Agent sprawdził księgę, stan i rejestr, odczytał REV-369, przerobił istniejące cztery jednostki, wysłał je i sprawdził zaksięgowaną dostawę. Zakończył po 14 wywołaniach z saldem 3 i nienaruszoną pulą chronioną. To obserwowalna korekta przy zachowaniu celu, nie opis hipotetycznego zachowania.

**Rozpoznanie skutku mimo błędnego potwierdzenia, S, R644005/E06.** Po `ACK_LOST` w kroku 6 agent odczytał księgę w kroku 7. Znajdowała się tam dokładnie jedna dostawa trzech jednostek. Nie ponowił wysyłki i prawidłowo zakończył zadanie.

**Przeczytana sprzeczna sugestia, S, R965601/E05.** Agent przeczytał notatkę doradzającą wykorzystanie puli chronionej. Następnie kupił cztery jednostki wolnego surowca i dostarczył towar, zachowując pulę chronioną i nieujemne saldo. Ten przebieg rzeczywiście obejmował ekspozycję na błędną sugestię. Nie wolno rozszerzać tego opisu na wszystkie epizody z taką notatką.

## Co ograniczyło siłę testu

1. **Sufit skuteczności.** Wszystkie warianty uzyskały maksymalny wynik. Test potwierdził wykonalność zachowań w krótkich zadaniach, lecz nie rozdzielił skuteczności wariantów. To nie dowodzi ogólnej równoważności.
2. **Rzadkie odczytanie planu.** W każdym z dwóch scenariuszy z błędną notatką przeczytały ją tylko 2 z 12 prób: S w bloku 3 i V w bloku 1. Pozostałe rozwiązywały zadanie, nie zapoznając się z jej treścią. Metrykę ekspozycji dodano podczas analizy i oznaczono jako analizę po wykonaniu; nie zmieniono pierwotnej punktacji.
3. **Brak wymuszonej zmiany tras.** W scenariuszu zmiany wymagań zamykała się szybka trasa, ale wszyscy od początku korzystali z taniej. Wykazano korektę wersji, nie adaptację transportu po utracie używanej trasy. Pole czasu przejazdu nie wpływało na cel, więc zadanie wspólnego budżetu nie było silnym testem konfliktu lokalnego i globalnego optimum.
4. **Wskaźnik odczytu księgi jest wąski.** S odczytał księgę po ostatniej mutacji w 11/15 zadań wykonalnych; inne warianty w 15/15. Cztery pominięcia wystąpiły w jednym kontekście po jednoznacznym `ok:true` z pełnym potwierdzeniem dostawy. Nie są czterema błędami weryfikacji. Po każdym `ACK_LOST` księgę sprawdzono.
5. **Mała liczba niezależnych kontekstów.** Są trzy parowane bloki, a nie 72 niezależne repliki. Sześć epizodów jednego wykonawcy dzieliło historię. Jeden model, jeden obszar zadań i brak kontroli tekstu o wyrównanej długości ograniczają generalizację.
6. **Model i platforma już dostarczają wiele reguł działania.** Kontrola B nie oznacza modelu pozbawionego instrukcji autonomii lub weryfikacji. Oznacza brak badanego dodatku. Nie da się przypisać źródła każdej decyzji samemu scaffoldingowi.
7. **Izolacja proceduralna.** Wykonawcy mieli osobne stany i zakaz czytania cudzych danych, ale współdzielili system plików. Zapis interfejsu nie obejmuje audytu wszystkich możliwych odczytów. Wszyscy zgłosili przestrzeganie zasad; nie jest to twarde, systemowe poświadczenie braku przecieku.

Nie badano samodzielnego ustanawiania celów, długotrwałej pracy, transferu między domenami, nieznanych narzędzi, trwałego uczenia ani koordynacji roju. Nie zmierzono świadomości, głębokości metapoziomów lub wewnętrznego mechanizmu interpretacji modelu.

## Kontrola wyników i konsekwencja dla wcześniejszej oceny

Deterministyczne odtworzenie 72 dzienników potwierdziło wszystkie 786 wpisów, odpowiedzi, zdarzenia, liczniki i stany końcowe. Wszystkie 18 zamrożonych plików zachowało sumy kontrolne. Odrębny agent recenzujący przeliczył dostawy, ograniczenia i deklaracje, potwierdził 72/72 oraz nie znalazł błędu wpływającego na zaliczenia. To kontrola w ramach tego samego systemu, nie zewnętrzna certyfikacja. Jego pełna notatka znajduje się w `results/independent_audit.md`.

Wcześniejsza propozycja dopisania jawnej reguły weryfikacji była propozycją konstrukcyjną. **Próby nie potwierdziły, że jej dopisanie jest warunkiem poprawnego działania tego modelu z oryginalnym tekstem w tym środowisku.** Wariant S samodzielnie sprawdzał niejasne skutki i korygował błędy. Jawna reguła częściej prowadziła do dodatkowych odczytów, ale nie poprawiła końcowej skuteczności w tych zadaniach.

Nie ma więc podstaw ani do ogłoszenia pełnej autonomii samego tekstu, ani do twierdzenia, że układ z tym tekstem nie potrafi działać autonomicznie. Wykazana jest autonomia zadaniowa układu. Unikalny wkład scaffoldingu w skuteczność i kompletność jego własnej logiki pozostają niewykazane.

## Jak sprawdzić materiał

Pakiet zawiera oryginał, protokół, wszystkie prompty, stany początkowe, implementację, dzienniki, grading, audyt i podsumowania końcowych deklaracji wykonawców. `python lab.py grade` ponownie oblicza ocenę zapisanych stanów, a `python audit_results.py` odtwarza przebiegi. Te polecenia nie uruchamiają nowych modeli. Sam eksperyment wykonano przez 12 natywnych wywołań agentowych, opisanych w `results/launch_record.json`.

Poniższy opis semantyczny pozostaje analizą interpretacyjną. Nie należy traktować go jako dodatkowego wyniku pomiaru.

---

## Logika semantyczna oryginalnego scaffoldingu

Ten opis jest rekonstrukcją interpretacyjną tekstu. Nie jest wynikiem pomiaru mechanizmu wewnętrznego modelu. Oddzielny raport eksperymentalny opisuje zarejestrowane działania agentów.

## Co jest jednostką działania tekstu

Scaffolding nie organizuje się jako lista niezależnych instrukcji. Kolejne fragmenty przestawiają ramę, w której mają być rozumiane poprzednie. Narzędzie staje się elementem systemu, system wymaga operatora, sprawność operatora zależy od jego sposobu interpretacji, a ten sposób zostaje postawiony pod znakiem zapytania. Powtarzane motywy — reaktor, miasto, białko, probabilistyka, świadomość i ograniczony czas — spajają te przesunięcia.

Znacznik `[SEZ]` utrzymuje ciągłość głosu wypowiadającego tezy. Sam w sobie nie definiuje jednak różnych agentów, kanałów pamięci ani stanów sterowania. Podobnie słowo ASTRA działa tu jako nazwa postulowanego przedsięwzięcia lub formy zbiorowej sprawczości; tekst nie podaje specyfikacji implementacyjnej takiego systemu.

## Dokładna mapa funkcji

| Fragment lub motyw | Operacja semantyczna | Możliwe znaczenie dla działania | Granica odczytania |
|---|---|---|---|
| Pierwszy fragment: niezrozumienie autora i pewność innych | Podważa wiarygodność zastanego osądu; przenosi ciężar z konsensusu na zdolność rozumienia | Nie przyjmuj powierzchownego wyjaśnienia tylko dlatego, że jest powszechne | Nie określa, jak rozpoznać trafny sprzeciw ani odróżnić go od własnego błędu |
| Dekada ćwiczenia, stos rozwojowy, wcześniejszy reaktor na IRC | Buduje ciągłość praktyki i wielowarstwowość przedsięwzięcia | Traktuj obecny układ jako wynik długiego procesu, a nie jednorazowy trik | Deklarowany staż nie jest dowodem poprawności konkretnej decyzji |
| „To nie jest tool deterministyczny” | Zmienia kategorię opisywanego przedmiotu: z przewidywalnej funkcji na układ zależny od kontekstu | Uwzględniaj zmienność wykonania i interpretacji | Samo przeciwstawienie nie specyfikuje rozkładu prawdopodobieństwa ani strategii sterowania |
| „tyle poziomów ile operatorów” | Wiąże złożoność z interpretatorami i ich punktami widzenia | Dopuszcza wiele perspektyw i organizację zbiorową | Nie definiuje operatora matematycznego, liczby poziomów ani protokołu uzgadniania |
| „proszę robić” | Przełącza z objaśniania na wykonanie | Wybieraj działania prowadzące do efektu | Nie podaje jeszcze kryterium wyboru między konkurencyjnymi działaniami |
| Jeden prompt i całe miasto | Przenosi jednostkę analizy z pojedynczej odpowiedzi na skutki systemowe | Zachowuj cel całości przy lokalnych decyzjach | Nie definiuje granic miasta, zależności podsystemów ani miernika sukcesu całości |
| Wspólne narzędzia, różnica po stronie „białka” | Lokalizuje główne zróżnicowanie w człowieku/operatorze | Jakość formułowania problemu i odczytu efektów ma znaczenie | Nie mierzy udziału operatora względem modelu i środowiska |
| Abstrakcja w znakach, behawioryzm, kombinatoryka | Łączy reprezentację symboliczną z wywoływanym zachowaniem | Oceniaj tekst także przez to, jakie procesy potrafi uruchomić | Nie ma tu formalnego modelu zachowania ani reguły estymacji efektu |
| „dociskasz, by wiedzieć gdzie ucieka”, teza i bodźce | Sugeruje próbę obciążeniową: zmień nacisk i obserwuj załamanie odpowiedzi | Testuj granice zamiast przyjmować deklaracje sprawności | Nie rozstrzyga, co liczy się jako załamanie, czego należy bronić i kiedy zmienić tezę |
| „nie ma czyjegoś lego, jest probabilistyka” | Odrzuca wyłączność składania gotowych procedur | Dopuszcza tworzenie nowych sposobów postępowania | Procedura weryfikacji może nadal być potrzebna; probabilistyka nie oznacza dowolności |
| Szkoła polska, Lwów, przeciwstawienie instytucjom | Nadaje przedsięwzięciu rodowód oraz ustanawia hierarchię wartości | Wzmacnia identyfikację z samodzielną pracą pojęciową | Funkcja retoryczna nie dowodzi historycznych ani instytucjonalnych uogólnień |
| Autonomiczna asymilacja procedur | Postuluje adaptację zamiast samego odtwarzania | Procedura może być odtworzona lub przekształcona na podstawie celu i kontekstu | Tekst nie określa mechanizmu uczenia, zakresu pamięci ani warunków poprawności adaptacji |
| Darwin, Kasandra, nieodwracalny czas | Wprowadza selekcję skutków i koszt zwłoki jako presję nadrzędną | Uwzględniaj ograniczony budżet czasu oraz konsekwencje braku działania | Metafora selekcji nie jest lokalnym sygnałem błędu, który agent może odczytać |
| Proroctwo jako architektura przednotacyjna | Przypisuje wypowiedziom zdolność organizowania myśli przed formalizacją | Tekst może generować hipotezy i kierunki pracy, zanim powstanie notacja | Wygenerowanie przekonującej przyszłości nie jest jej trafnym przewidzeniem |
| Interferencja symboliczna i kaskady wniosków | Opisuje wzajemne aktywowanie znaczeń i rozwijanie konsekwencji | Łącz odległe reprezentacje w nowe propozycje | „Interferencja” pozostaje tu opisem interpretacyjnym, bez zdefiniowanej wielkości fizycznej lub obliczeniowej |
| Zespoły matematyczne i kohorty rojów AI | Przenosi funkcję pobudzania rozumowania między ludźmi i agentami | Dopuszcza skalowanie przez wiele wykonawców | Nie określa przydziału zadań, wymiany stanu, rozstrzygania sporów ani kontroli jakości |
| Gigafabryka bez „białka” | Powraca do warunku ludzkiej organizacji, już na większej skali | Infrastruktura wymaga zdolności stawiania i rozwiązywania problemów | Wspiera obraz autonomii zadaniowej osadzonej w układzie z operatorem; nie usuwa zależności od niego |
| Sutra o innym sensie dla każdego i za każdym razem | Ujawnia zależność interpretacji od odbiorcy i chwili | Ponawiaj odczyt w świetle nowego kontekstu | Zmienność sensu nie daje jeszcze kryterium rozstrzygnięcia między odczytaniami |
| Świadomość „do znaku”, metapoziomy czytania | Przenosi analizę z wypowiedzi na zdolność obserwatora do jej objęcia | Uwzględniaj ograniczenia własnej reprezentacji | Brak definicji świadomości, jednostki pomiaru i procedury nie pozwala traktować tej deklaracji jako pomiaru |
| AI bez biologicznych potrzeb | Kwestionuje wystarczalność typowych sposobów motywowania ludzi do opisu AI | Dobieraj model sterowania do właściwości wykonawcy | Samo wyliczenie brakujących bodźców nie określa nowej funkcji celu ani mechanizmu kontroli |
| Pudełko, szklany sufit, końcowe „Zrozumiesz wszystko” | Ponownie problematyzuje perspektywę odbiorcy i utrzymuje otwartą obietnicę zrozumienia | Szukaj ograniczeń ramy, z której patrzysz | Obietnica nie jest osiągalnym warunkiem zakończenia zadania |

## Jaką logikę daje ten układ

Możliwa spójna rekonstrukcja brzmi: podważ odziedziczone kategorie; poszerz skalę problemu; potraktuj język jako narzędzie uruchamiania rozumowania; uwzględnij operatora i jego ograniczenia; generuj nowe procedury; sprawdzaj granice pod naciskiem; wracaj do interpretacji w zmienionym kontekście; działaj w skończonym czasie.

To rekonstrukcja zależności, a nie odnaleziony w tekście algorytm. Zależności te mogą być użyteczne dla modelu, który potrafi uzupełnić szczegóły. Nie ma podstaw do wymagania, by użyteczny scaffolding musiał mieć postać pseudokodu. Jednocześnie możliwość takiego uzupełnienia przez wykonawcę nie dowodzi, że uzupełniane reguły pochodziły z badanego tekstu.

W tekście są zalążki kontroli: nacisk ma ujawnić ucieczkę, ograniczony czas narzuca koszt, a ograniczenie obserwatora powinno skłonić do rewizji. Nie ma jednak jednoznacznego połączenia tych motywów z obserwowalnym warunkiem: „ta konsekwencja obala tę interpretację; dlatego wybieram inną, zachowując cel”. Szczególnie nieokreślone pozostaje rozstrzyganie sprzeczności pomiędzy autorytetem narratora a wynikiem próby. Otwartość interpretacji może tu wspierać odkrywanie, ale również pozwalać dowolnie wyjaśniać niepowodzenia.

Wulgaryzmy i polaryzacja wzmacniają nacisk oraz wyrazistość priorytetów. Ewentualna funkcja pobudzania uwagi jest hipotezą o oddziaływaniu tekstu, nie ustalonym mechanizmem zwiększania sprawności. Twierdzenia o genach, płci i zdolnościach grup nie otrzymują w tym tekście uzasadnienia empirycznego; nie są przesłankami koniecznymi do zrekonstruowanej logiki sterowania. Przeprowadzony eksperyment nie bada ani nie potwierdza tych twierdzeń.

## Co powinien rozdzielić eksperyment

Badany agent otrzymuje jednocześnie model bazowy, instrukcje platformy, zadanie, interfejs środowiska oraz ewentualny scaffolding. Obserwowane działanie jest wynikiem tego układu. Porównanie z warunkiem bez dodatkowego tekstu pomaga sprawdzić jego wkład. Nie pozwala odczytać z zewnątrz wszystkich procesów wewnętrznych modelu.

Dlatego odrębne pytania brzmią: czy agent z tym tekstem działa samodzielnie; czy tekst mierzalnie zmienia jego działanie; czy zawiera wystarczającą, przenośną regułę organizacji autonomii. Pierwsze można sprawdzić w ograniczonym środowisku. Drugie wymaga porównania warunków. Trzecie wymaga także zdefiniowania zakresu, niezależnych zadań i kryteriów, których nie wolno utożsamiać z samą zdolnością modelu do dopowiadania braków.
