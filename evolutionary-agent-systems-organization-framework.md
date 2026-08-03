# Organizacja, która uczy się delegować

## Ewolucyjne wdrażanie systemów agentowych pomiędzy probabilistycznym poznaniem a deterministyczną odpowiedzialnością

## Od sekwencji badań do modelu wdrożenia

Wdrożenie systemu agentowego łatwo opisać językiem klasycznego projektu informatycznego. Organizacja określa wymagania, wybiera technologię, przygotowuje architekturę, uruchamia pilotaż, przeprowadza testy i przenosi rozwiązanie do produkcji. Taki model zakłada jednak, że przed rozpoczęciem projektu można dostatecznie dokładnie zdefiniować zarówno system docelowy, jak i organizację, do której ma on zostać wprowadzony. W przypadku systemów agentowych oba założenia są problematyczne. Zdolności modeli zmieniają się szybciej niż cykl wdrożeniowy, zachowanie agentów zależy od kontekstu, danych, pamięci i dostępnych narzędzi, a sama organizacja zaczyna zmieniać role, procedury i oczekiwania już podczas pierwszych eksperymentów.

Dlatego końcowy model wdrożenia nie powstał przez wybranie jednej architektury agentowej i dopisanie do niej procedur bezpieczeństwa. Został zrekonstruowany w wieloetapowym procesie badawczym. Punktem wyjścia było pytanie, dlaczego organizacje potrafią coraz łatwiej uruchamiać modele AI, lecz znacznie trudniej przekształcają ich możliwości w stabilną zdolność wykonawczą. Odpowiedź wymagała przejścia przez kilka poziomów analizy, ponieważ problem nie kończył się ani na jakości modeli, ani na kompetencjach użytkowników.

Pierwsza warstwa badań dotyczyła sposobu, w jaki człowiek odbiera i interpretuje sygnały. Analizy percepcji przedrozumowej, uwagi, warunkowania, płynności poznawczej i eksperckiego automatyzmu wskazywały, że użytkownik nie przyjmuje wyniku AI jako neutralnej informacji. Forma odpowiedzi, wcześniejsze oczekiwania, historia sukcesów, autorytet systemu i organizacyjna presja wpływają na to, czy rekomendacja zostanie zaakceptowana, odrzucona albo potraktowana jako fakt. Badania nad zaufaniem do automatyzacji pokazywały jednocześnie istnienie dwóch pozornie sprzecznych mechanizmów: awersji algorytmicznej i aprecjacji algorytmicznej. Człowiek może odrzucać system po pojedynczym błędzie, ale może też nadmiernie mu ufać, zwłaszcza gdy odpowiedź jest płynna, interfejs antropomorficzny, a odpowiedzialność poznawcza została już nieformalnie przeniesiona na narzędzie.

Druga warstwa przeniosła problem z jednostki na organizację. Analizy projektów AI, technicznego długu systemów uczenia maszynowego, kaskad danych i praktyk operacjonalizacji modeli wskazywały, że znacząca część niepowodzeń wynika nie z braku możliwości modelu, lecz z niedopasowania danych, workflow, właścicielstwa, mierników i odpowiedzialności. Model może działać poprawnie w demonstracji, a mimo to nie tworzyć wartości w produkcji. Pomiędzy odpowiedzią a skutkiem znajduje się łańcuch transformacji, w którym wynik probabilistyczny zostaje przekształcony w próg, decyzję, uprawnienie i działanie.

Trzecia warstwa dotyczyła niezawodności i bezpieczeństwa systemowego. Klasyczne prace dotyczące wypadków normalnych, błędu ludzkiego, resilience engineering i system safety zostały zestawione z ramami zarządzania ryzykiem AI, technikami przeciwdziałania awariom kaskadowym oraz analizami bezpieczeństwa systemów agentowych. Wniosek nie prowadził do prostego zwiększania liczby kontroli. O wyniku decydowała nie tylko liczba bramek, lecz korelacja błędów, wspólne źródła nieprawidłowych założeń, obserwowalność, odwracalność i zdolność naprawy. Kontrola, która powtarza ten sam model błędu co kontrolowany komponent, tworzy pozór niezależnego zabezpieczenia. Kontrola, która nie ma możliwości zatrzymania albo cofnięcia działania, jest obserwatorem, nie mechanizmem bezpieczeństwa.

Czwarta warstwa obejmowała ograniczenia materialne. Analizy energii, centrów danych, półprzewodników, sieci i koncentracji mocy obliczeniowej wykazały, że wdrożenie AI nie jest wyłącznie kwestią dostępu do oprogramowania. Organizacja może mieć budżet, a nie mieć dostępnej mocy, czasu przyłączenia, infrastruktury, kompetencji albo możliwości utrzymania systemu. W tym miejscu rachunek technologiczny przechodzi w rachunek wykonania. Kapitał pozostaje konieczny, lecz nie zastępuje zdolności materialnej i organizacyjnej.

Wyniki tych analiz zostały ujęte w pięćdziesięciu hipotezach, skonfrontowanych ze stoma jednostkami źródłowymi i pięciuset relacjami hipoteza–źródło. Następnie hipotezy zostały zważone bayesowsko, połączone grafem zależności i poddane symulacjom Monte Carlo. Z tego korpusu wybrano osiemnaście tez rdzeniowych o najwyższym połączonym znaczeniu dowodowym, centralności i odporności na zmianę założeń. To one stały się ograniczeniami projektowymi kolejnego badania.

Drugi etap objął trzydzieści znanych modeli organizacyjnych, od struktur hierarchicznych i funkcjonalnych po organizacje modułowe, adaptacyjne, produktowe, platformowe, wysokiej niezawodności i cyberodporne. Nie oceniano ich według popularności, lecz według zgodności z mechanizmami wynikającymi z pierwszego badania: zdolnością do zachowania niepewności, skracania łańcuchów transformacyjnych, ograniczania korelacji błędów, tworzenia szybkich sprzężeń zwrotnych, jednoznacznego przypisywania odpowiedzialności i odbudowy po awarii.

Dla dziesięciu modeli o najwyższej zgodności wykonano test 307 200 konfiguracji, łączący odmienne modele governance, architektury AI, poziomy autonomii, sposoby podejmowania decyzji, struktury odpowiedzialności, stopnie centralizacji i warianty infrastruktury. Z przestrzeni tej wyprowadzono sto strategii wdrożeniowych, a każdą poddano tysiącu przebiegów Monte Carlo. Powstało sto tysięcy przebiegów oraz dwieście scenariuszy, w których warunki sprzyjające zestawiano z presją cybernetyczną, degradacją danych, ograniczeniami energii i chipów, szokiem regulacyjnym oraz zmianą rynku i celu.

Wyniki nie wskazały strategii, która dominowałaby niezależnie od typu organizacji. Pokazały natomiast powtarzający się wzorzec. Najwyżej oceniane konfiguracje łączyły lokalne wykonanie ze wspólną platformą, jednoznacznego właściciela skutku z niezależnym assurance, modułową architekturę z pełną obserwowalnością oraz autonomię warunkową z możliwością cofnięcia działania. Strategie maksymalizujące agentowość bez równoległego zwiększania zdolności nadzoru, odbudowy i odpowiedzialności uzyskiwały gorszy dolny ogon rozkładu, nawet jeśli ich średni potencjał wyglądał atrakcyjnie.

Ostateczny wniosek nie jest więc projektem jednego docelowego systemu. Jest modelem kontrolowanej współewolucji:

```text
organizacja deterministyczna
↔ bramki przejścia
↔ probabilistyczny system agentowy
```

Organizacja nie instaluje gotowej struktury agentowej. Buduje zdolność do obserwowania, delegowania, ograniczania, porównywania, wycofywania i ponownego łączenia procesów. System agentowy nie zostaje zaprojektowany raz na zawsze. Rozwija się w kontakcie z rzeczywistymi procesami, wyjątkami, błędami, ludźmi i ograniczeniami infrastrukturalnymi.

## Mapa badań i ich funkcji

Materiały dotyczące systemów wieloagentowych i agentowego bezpieczeństwa wspierają tezę, że agent nie jest jedynie modelem udzielającym odpowiedzi. Z chwilą otrzymania pamięci, narzędzi i uprawnień rozszerza granicę zaufania z informacji na działanie. Ryzyko obejmuje już nie tylko błędną treść, lecz niewłaściwy wybór narzędzia, utrwalenie fałszywego stanu w pamięci, przekroczenie zakresu delegacji, propagację błędu między agentami oraz wykorzystanie kanału komunikacji jako powierzchni ataku. Międzynarodowe raporty bezpieczeństwa AI, taksonomie adversarial machine learning, MITRE ATLAS oraz analizy wykorzystania generatywnej AI przez przeciwników nie dowodzą jednej uniwersalnej przewagi ataku nad obroną. Wspierają jednak silnie założenie, że architektura uprawnień, pamięci, narzędzi i komunikacji musi być przedmiotem odrębnego projektu bezpieczeństwa.

Badania Human–AI Interaction pełnią inną funkcję. Nie opisują bezpośrednio architektury agentów, lecz wskazują ograniczenia warstwy ludzkiej. Prace Lee i See, Hoffa i Bashira, Glikson i Woolley oraz systematyczny przegląd Mehrotry i współautorów wspierają potrzebę kalibracji zaufania zamiast prostego zwiększania akceptacji technologii. Eksperymenty nad algorithm aversion i algorithm appreciation pokazują, że użytkownik nie reaguje wyłącznie na jakość rekomendacji. Znaczenie mają możliwość kontroli, sposób prezentacji, wcześniejsze błędy oraz domena zastosowania. Wynik ten silnie wspiera stopniową delegację, ale nie daje podstaw do założenia, że sama obecność człowieka w pętli gwarantuje bezpieczeństwo. Człowiek może stać się wąskim gardłem, automatycznym zatwierdzającym albo uczestnikiem niezdolnym do wykrycia błędu systemu.

Materiały dotyczące wdrożeń organizacyjnych pokazują, że przejście od pilotażu do operacji jest zmianą układu pracy, a nie tylko zmianą skali technicznej. Raport RAND identyfikuje niejasne cele, niedopasowanie do potrzeb i problemy organizacyjne jako istotne źródła porażek projektów AI. Sculley i współautorzy opisują ukryty dług techniczny, który powstaje z zależności, sprzężeń i niewidocznych kontraktów danych. Sambasivan i współautorzy pokazują, jak problemy danych mogą tworzyć kaskady wpływające na cały system. Badania praktyk inżynierskich prowadzone przez Shankara i współautorów wskazują, że operacjonalizacja ML jest pracą koordynacyjną, wymagającą uzgodnienia artefaktów, ról, odpowiedzialności i kryteriów jakości.

Ten nurt zapewnia silne wsparcie dla przebudowy workflow, jednoznacznego właścicielstwa i ciągłej ewaluacji. Umiarkowane wsparcie dotyczy przewagi małych, równoległych eksperymentów. Modułowość i krótka pętla informacji zwrotnej są spójne z wynikami badań, lecz sam fakt podzielenia projektu na małe części nie gwarantuje sukcesu. Zbyt duża liczba nieskoordynowanych pilotaży może zwiększyć fragmentację, powielić dane i stworzyć konkurencyjne standardy. Równoległość działa tylko wtedy, gdy eksperymenty korzystają ze wspólnej pamięci, porównywalnych mierników i mechanizmu realnej selekcji.

Prace z obszaru system safety i resilience engineering nadają strukturę bramkom przejścia. Perrow pokazuje znaczenie złożonych interakcji i ścisłego sprzężenia, Reason rozróżnia błędy aktywne od warunków ukrytych, a Leveson przenosi analizę bezpieczeństwa z zawodności elementów na niewłaściwe sterowanie całym systemem. Hollnagel, Woods i Leveson podkreślają zdolność systemu do dostosowania się i zachowania funkcji w warunkach zmienności. Praktyka Site Reliability Engineering pokazuje operacyjne znaczenie ograniczania awarii kaskadowych, redukcji obciążenia, degradacji kontrolowanej i odbudowy.

Z badań tych wynika silne wsparcie dla obserwowalności, odwracalności, izolacji błędów i kontrolowanej eskalacji. Nie wynika natomiast, że bezpieczeństwo można osiągnąć przez nieograniczone mnożenie punktów zatwierdzania. Każda bramka zwiększa wartość tylko wtedy, gdy wnosi niezależną informację, posiada zdolność zatrzymania procesu albo zmniejsza promień działania. Bramka, która kopiuje wcześniejszy wynik do kolejnego formularza, zwiększa opóźnienie, lecz nie zwiększa odporności.

Materiały dotyczące organizacji adaptacyjnych, platform engineering, DevOps, struktur produktowych, federacyjnych i wysokiej niezawodności dostarczają modeli koordynacji. Analiza trzydziestu modeli nie wykazała przewagi całkowitej decentralizacji ani całkowitej centralizacji. Modele najwyżej ocenione łączyły wspólne standardy, platformę i obserwowalność z lokalnym podejmowaniem decyzji. Cyber-Resilient Enterprise, Platform Engineering i High Reliability Organization uzyskały najwyższe wyniki nie dlatego, że są najbardziej „agentowe”, lecz dlatego, że posiadają mechanizmy wykrywania, ograniczania i uczenia się na błędach. Adaptive Organization i Modular Organization zapewniają elastyczność oraz możliwość rekonfiguracji, lecz wymagają silniejszych granic bezpieczeństwa i odpowiedzialności. AI-Native Organization oraz Multi-Agent Enterprise mają większy potencjał automatyzacji, ale również szerszą powierzchnię błędu i trudniejszy problem kontroli wspólnych przyczyn.

Badania infrastrukturalne pełnią funkcję ograniczającą wobec strategii. Raporty IEA, Lawrence Berkeley National Laboratory, amerykańskiego Departamentu Energii, Stanford HAI i podmiotów półprzewodnikowych wskazują, że rozwój AI zależy od energii, sieci, lokalizacji, chipów, pakowania i czasu budowy. Wdrożenie agentowe, które wymaga ciągłego przetwarzania, wielu modeli i rozbudowanej telemetrii, może przegrać nie przez brak pomysłu, lecz przez koszt i dostępność wykonania. Dlatego architektura portfela eksperymentów musi uwzględniać nie tylko jakość i ryzyko, ale również koszt obliczeniowy, opóźnienie, zależność od dostawcy i możliwość działania w trybie zdegradowanym.

Materiały dotyczące pracy, kompetencji i produktywności pokazują z kolei, że agentowość prawdopodobnie najpierw przekształci zadania i podział odpowiedzialności, zanim całkowicie zastąpi całe zawody. Dane ILO, OECD i raporty o przyszłości pracy wspierają potrzebę projektowania współpracy, nie tylko automatyzacji. Badania terenowe nad generatywną AI pokazują realne wzrosty produktywności w wybranych zadaniach, ale nie uzasadniają przeniesienia lokalnego wyniku na całą organizację. Wydajność pojedynczego pracownika może wzrosnąć, podczas gdy koszt koordynacji, kontroli i poprawiania błędów zwiększa się na poziomie systemowym.

Mapa badań prowadzi zatem do rozróżnienia czterech stopni wsparcia. Silnie wspierane są obserwowalność, naprawialność, jednoznaczna odpowiedzialność, przebudowa workflow, kontrola uprawnień i uwzględnianie ograniczeń infrastrukturalnych. Umiarkowane wsparcie mają równoległe eksperymenty, stopniowe zwiększanie autonomii i modułowe skalowanie, ponieważ ich skuteczność zależy od jakości koordynacji. Ograniczone wsparcie mają rozbudowane mechanizmy samoczynnej selekcji procesów, gdyż istnieje niewiele bezpośrednich danych z dużych organizacji działających w ten sposób przez długi okres. Hipotezą do walidacji pozostaje pełna współewolucja wieloagentowego systemu z dynamicznie rekonfigurowaną organizacją. Jest ona zgodna z teorią systemów adaptacyjnych i wynikami atlasu, ale nie może zostać przedstawiona jako powszechnie potwierdzony model operacyjny.

## Od strategii wdrożeniowej do architektury ewolucyjnej

Sto strategii wygenerowanych w atlasie różniło się governance, architekturą, autonomią, decyzją, odpowiedzialnością, centralizacją i infrastrukturą. Wśród konfiguracji najwyżej ocenianych powtarzały się niezależne assurance albo federacyjne guardrails, modułowa platforma, cyfrowy bliźniak lub copilot osadzony bezpośrednio w workflow. Dominowała autonomia warunkowa albo wykonanie ograniczone, nie pełna swoboda działania. Decyzje opierały się na progach adaptacyjnych, a odpowiedzialność koncentrowała się u jednego właściciela wyniku albo w triadzie produkt–dane–ryzyko.

Najwyżej oceniona strategia, Assurance Copilot w modelu Cyber-Resilient Enterprise, nie była najbardziej rozbudowanym systemem wieloagentowym. Jej logika polegała na umieszczeniu AI w istniejącym przepływie pracy, zapewnieniu niezależnej oceny, określeniu granic wykonania oraz powiązaniu każdego skutku z właścicielem. Federacyjne platformy uzyskiwały podobnie wysokie wyniki, gdy zapewniały zespołom lokalną swobodę w ramach wspólnych kontraktów danych, polityk bezpieczeństwa i obserwowalności.

Systemy z większą liczbą agentów nie były z definicji gorsze, lecz częściej stawały się warunkowe. Federacyjna siatka agentów mogła skalować się skutecznie w Platform Engineering lub Cyber-Resilient Enterprise, jeśli relacje między agentami były ograniczone protokołami, a odpowiedzialność nie rozpływała się wraz z delegacją. Ta sama architektura w organizacji o niejasnym właścicielstwie i niespójnych danych zwiększała ryzyko korelacji błędów.

Monte Carlo ujawniło również różnicę między atrakcyjnością średniego wyniku a odpornością strategii. Sto strategii podzieliło się na dziesięć dominujących, trzydzieści osiem odpornych, czterdzieści sześć warunkowych i sześć niestabilnych. Nawet najlepsze konfiguracje nie osiągnęły deterministycznej pewności sukcesu. Ich średnie wyniki oscylowały wokół górnej części skali, lecz prawdopodobieństwo przekroczenia wysokiego progu sukcesu pozostawało ograniczone. Jest to argument przeciw projektowaniu wdrożenia jako drogi do ustalonego stanu końcowego. Strategia musi zakładać, że część eksperymentów nie zadziała, dane ulegną degradacji, cele się zmienią, a komponenty będą wymagały wycofania.

Wyniki wspierają zatem utrzymywanie wielu eksperymentów równolegle, ale pod trzema warunkami. Po pierwsze, eksperymenty muszą należeć do jednego portfela i odpowiadać na porównywalne pytania. Po drugie, pozytywny wynik musi prowadzić do realnego zwiększenia zakresu, zasobów albo autonomii, a negatywny do ograniczenia, rekonfiguracji albo zamknięcia. Po trzecie, wiedza z każdego eksperymentu musi być przenoszona do pozostałych, aby organizacja nie powtarzała tych samych błędów w niezależnych silosach.

Stopniowe rozszerzanie autonomii ma silne uzasadnienie systemowe, lecz warunkiem eskalacji nie może być sam upływ czasu. Agent nie powinien uzyskiwać nowych uprawnień dlatego, że pilotaż trwał trzy miesiące. Powinien je uzyskać, jeżeli wynik jest powtarzalny, system zachowuje stabilność w warunkach zakłócenia, ślad decyzyjny pozwala odtworzyć przyczyny działania, a organizacja potrafi zatrzymać i cofnąć skutek.

Rozdzielanie eksploracji od eksploatacji również znajduje wsparcie. Eksperyment poszukujący nowych sposobów działania nie powinien jednocześnie odpowiadać za krytyczną ciągłość operacji. Agent eksploracyjny może generować warianty, testować nowe modele i zmieniać strategie w środowisku kontrolowanym. Agent eksploatacyjny powinien korzystać z zatwierdzonego zakresu, stabilnych danych i jasno określonych ograniczeń. Przeniesienie wariantu z eksploracji do operacji wymaga bramki, nie płynnego rozszerzenia uprawnień.

Podstawowa teza modelu brzmi zatem: system agentowy nie powinien być wdrażany jako kompletna architektura narzucona organizacji, lecz rozwijać się organicznie wewnątrz jej rzeczywistych procesów. Organiczność nie oznacza spontaniczności pozbawionej reguł. Oznacza architekturę, której struktura jest aktualizowana przez obserwację, kontrolowany eksperyment, pomiar, selekcję i rekonfigurację.

```text
obserwacja
→ mapowanie
→ ograniczony eksperyment
→ ewaluacja
→ selekcja
→ delegacja
→ integracja
→ eskalacja
→ rekonfiguracja
```

System docelowy nie jest znany na początku. Znane powinny być natomiast granice, procedury zmiany, właściciele odpowiedzialności i kryteria zatrzymania.

## Bramki pomiędzy probabilistyką a wykonaniem

Organizacja działa przez role, budżety, terminy, procedury, uprawnienia, polityki bezpieczeństwa i mierzalne zobowiązania. Nawet wtedy, gdy podejmuje decyzję w warunkach niepewności, musi przekształcić ją w określone działanie. System agentowy funkcjonuje inaczej. Generuje warianty, aktualizuje hipotezy, zmienia plan w zależności od odpowiedzi środowiska i może proponować kilka dopuszczalnych trajektorii.

Problem wdrożenia nie polega na wyeliminowaniu tej różnicy. Polega na zbudowaniu mechanizmów translacji. Bramka jest miejscem, w którym określony wynik agentowy może zostać dopuszczony do świata operacyjnego. Nie jest pojedynczym kliknięciem człowieka. Może obejmować walidację techniczną, test porównawczy, sprawdzenie bezpieczeństwa, symulację skutków, ocenę zgodności prawnej, weryfikację właściciela procesu i warunkowe zezwolenie na działanie.

Każda bramka musi rozstrzygać, jaki dowód jest wystarczający, jaki poziom niepewności dopuszczalny, kto zatwierdza przejście, kto odpowiada za skutek, jaki jest limit czasu, budżetu i narzędzi, co uruchamia ponowną ocenę oraz kiedy następuje automatyczne wycofanie uprawnienia. Jeżeli odpowiedzi nie da się wskazać, delegacja nie jest jeszcze architekturą. Jest nieformalnym przeniesieniem odpowiedzialności.

Bramki nie powinny być wszędzie jednakowe. Rekomendacja tekstowa może wymagać kontroli źródeł i oceny użytkownika. Zmiana rekordu w systemie finansowym wymaga odrębnej polityki dostępu, limitu kwotowego, śladu i możliwości wycofania. Modyfikacja konfiguracji produkcyjnej może wymagać testu w środowisku cyfrowego bliźniaka, policy-as-code i niezależnego zatwierdzenia. Działanie dotyczące bezpieczeństwa może dopuszczać większą prędkość, lecz mniejszy promień: agent może czasowo odizolować pojedynczą stację, ale nie całą sieć bez dodatkowego dowodu.

Bramki są także mechanizmem zachowania odpowiedzialności. W systemie wieloagentowym łatwo rozproszyć przyczynowość. Jeden agent wykrywa problem, drugi planuje rozwiązanie, trzeci wybiera narzędzie, czwarty wykonuje działanie, a piąty ocenia rezultat. Formalne przypisanie odpowiedzialności każdemu komponentowi nie tworzy jeszcze właściciela skutku. Organizacja potrzebuje człowieka albo jednoznacznie ustanowionej roli, która odpowiada za wynik całego łańcucha.

Skuteczna bramka nie zatrzymuje adaptacji, lecz ją warunkuje. Może wydawać zgodę ograniczoną czasowo, środowiskowo albo ilościowo. Może pozwolić agentowi działać tylko na jednej klasie przypadków, tylko przy określonym poziomie pewności albo tylko wtedy, gdy niezależny komponent nie wykryje sprzeczności. Autonomia staje się wówczas zmienną sterowaną, nie stałą cechą systemu.

## Scenariusz pierwszy: organizacyjny cień

Pierwszy scenariusz jest przeznaczony dla organizacji o niskiej lub umiarkowanej dojrzałości AI, silnej hierarchii, rozproszonych danych albo niewielkiej tolerancji ryzyka. Jego celem nie jest natychmiastowa automatyzacja procesów. Ma stworzyć empiryczny model rzeczywistego funkcjonowania organizacji oraz sprawdzić, gdzie system agentowy może wnieść wartość bez uzyskiwania wpływu na operacje.

System działa początkowo jako cień. Odczytuje dokumentację, obserwuje przepływy, rekonstruuje zależności i przygotowuje propozycje, ale nie zapisuje zmian w systemach produkcyjnych. Jego rekomendacje są porównywane z decyzjami ludzi, a różnice stają się materiałem badawczym. W ten sposób organizacja nie testuje jedynie jakości odpowiedzi. Testuje zgodność reprezentacji agenta z rzeczywistym procesem.

Na poziomie organizacyjnym scenariusz wymaga właścicieli procesów, zespołu danych, funkcji bezpieczeństwa i grupy użytkowników, którzy potrafią oceniać rekomendacje bez automatycznego ich akceptowania. Agenci nie zastępują ról. Tworzą alternatywny obraz działania, ujawniają wyjątki, sprzeczności i miejsca, w których formalna procedura różni się od praktyki. Szczególnie istotne jest rozdzielenie oceny przydatności od oceny zgodności. Rekomendacja może być praktycznie atrakcyjna, a jednocześnie naruszać regulację albo politykę bezpieczeństwa.

Architektura opiera się na dostępie tylko do odczytu, kontrolowanym RAG, izolowanej pamięci eksperymentalnej i pełnym logowaniu źródeł. Agent nie może sam rozszerzyć zakresu danych. Nie ma uprawnień do wykonywania transakcji, zmiany konfiguracji ani komunikowania decyzji jako stanowiska organizacji. Każda odpowiedź musi pozostawić ślad: źródła, użyte narzędzia, poziom pewności, alternatywy i wykryte braki danych.

Eksperyment zaczyna się od procesów częstych, lecz odwracalnych i niekrytycznych. Hipotezy dotyczą redukcji czasu wyszukiwania informacji, wykrywania niezgodności, jakości klasyfikacji przypadków i trafności przewidywania następnego kroku. Sukcesem nie jest sama zgodność z decyzją człowieka. Jeżeli człowiek stosuje nieefektywną praktykę, agent powtarzający ją bezbłędnie nie tworzy poprawy. Dlatego wynik powinien być porównywany z rezultatem procesu, liczbą wyjątków, kosztami i późniejszymi korektami.

Eskalacja w tym scenariuszu prowadzi od obserwacji do projektowania, a następnie do rekomendacji z zatwierdzeniem. Warunkiem przejścia jest stabilna jakość w różnych klasach przypadków, możliwość odtworzenia źródeł oraz wykazanie, że użytkownicy potrafią rozpoznawać sytuacje, w których system nie powinien być używany. Deeskalacja następuje przy wzroście halucynacji, utracie jakości danych, nadmiernym zaufaniu albo pojawieniu się presji na omijanie formalnych procedur. Całkowite zatrzymanie jest wymagane, gdy system ujawnia dane poza zakresem, utrwala niedozwoloną pamięć albo nie można odtworzyć podstawy jego rekomendacji.

W codziennej pracy agent działa obok procesu, nie zamiast procesu. Użytkownik otrzymuje propozycję, źródła i informację o niepewności. Wyjątki pozostają po stronie człowieka. Organizacja zachowuje pełną manualną zdolność wykonania, ponieważ system nie stał się jeszcze elementem krytycznej ścieżki. Scenariusz przestaje być pilotażem dopiero wtedy, gdy obserwacja wykazuje stabilny wzorzec korzyści, dokumentacja i dane zostały uporządkowane, a rekomendacje można bezpiecznie osadzić w konkretnym workflow.

Portfel pięciu procesów eksperymentalnych rozpoczyna się od **procesu mapowania rzeczywistego przepływu**, którego hipoteza zakłada, że formalna procedura nie opisuje wszystkich wyjątków; agent korzysta z logów, dokumentów i historii spraw, nie ma autonomii wykonawczej, a właścicielem jest architekt procesu. Miarą jest pokrycie przebiegu, liczba prawidłowo wykrytych wyjątków i zdolność odtworzenia źródła; proces zostaje zatrzymany przy naruszeniu prywatności albo tworzeniu fałszywych zależności. **Proces wspomagania wiedzy** testuje, czy RAG skraca czas odnajdywania informacji bez obniżenia trafności; zakres delegacji obejmuje wyszukiwanie i przygotowanie odpowiedzi, dane pochodzą z zatwierdzonego korpusu, właścicielem jest funkcja wiedzy, a eskalacja wymaga stabilnych cytowań i niskiego poziomu odpowiedzi bez podstawy. **Proces cienia decyzyjnego** generuje rekomendację równolegle do człowieka, ale jej nie ujawnia przed podjęciem decyzji, aby zmierzyć rzeczywistą zgodność i kalibrację; właścicielem jest funkcja ryzyka, a kryterium zatrzymania stanowi systematyczny błąd w określonej grupie przypadków. **Proces obserwacji bezpieczeństwa** analizuje anomalie i proponuje reakcje bez możliwości blokowania zasobów; właścicielem jest SOC albo zespół bezpieczeństwa, a miernikiem jest jakość detekcji przy kontrolowanej liczbie fałszywych alarmów. **Proces adaptacji człowieka** bada sposób korzystania z rekomendacji, mierzy automation bias, liczbę bezrefleksyjnych akceptacji i utrzymanie kompetencji manualnych; jego właścicielem jest funkcja zmiany organizacyjnej. Procesy są zarządzane jako jeden portfel: mapowanie zasila wiedzę, cień decyzyjny wykorzystuje oba strumienie, obserwacja bezpieczeństwa wyznacza granice, a proces adaptacji ocenia, czy organizacja potrafi bezpiecznie korzystać z wyników. Najlepsze trajektorie otrzymują więcej danych i szerszy zakres, nieskuteczne są łączone albo wygaszane, lecz ich błędy pozostają w pamięci portfela.

## Scenariusz drugi: federacyjna platforma kontrolowanej delegacji

Drugi scenariusz jest przeznaczony dla organizacji posiadających zespoły produktowe, rozwiniętą infrastrukturę, praktyki DevOps albo platform engineering. Jego celem jest przeniesienie eksperymentów z warstwy rekomendacyjnej do ograniczonego wykonania bez centralizowania wszystkich decyzji w jednym zespole AI.

Logika scenariusza opiera się na federacji. Centrum nie buduje wszystkich agentów ani nie zatwierdza każdej pojedynczej decyzji. Dostarcza platformę, kontrakty, mechanizmy tożsamości, obserwowalność, katalog narzędzi i guardrails. Domeny definiują lokalne cele, dane i przypadki użycia. Odpowiedzialność za rezultat pozostaje przy właścicielu produktu lub procesu, natomiast platforma odpowiada za bezpieczne ścieżki wykonania.

Architektura składa się z rejestru agentów, warstwy orkiestracji, magazynów pamięci rozdzielonych według domen, policy-as-code, zarządzania sekretami, limitów budżetowych i pełnej telemetrii. Agent otrzymuje narzędzia przez jawny kontrakt. Nie może korzystać z dowolnego API ani tworzyć samodzielnie nowych połączeń. Każde narzędzie posiada zakres, typ dopuszczalnych operacji, limity i warunki zatrzymania. Komunikacja między agentami jest protokołem, nie swobodną konwersacją bez audytu.

Na poziomie eksperymentalnym platforma pozwala uruchamiać równolegle wiele małych wdrożeń, ale wymusza wspólne metryki. Zespół może testować agenta do obsługi danych, agenta wspierającego proces produktu albo agenta operacyjnego, lecz wszystkie muszą raportować koszt, jakość, liczbę interwencji, wyjątki i skutki uboczne. Eksperymenty nie konkurują wyłącznie o szybkość. Konkurują o całkowity wynik systemu.

Eskalacja polega na stopniowym rozszerzaniu katalogu narzędzi. Początkowo agent może przygotować plan. Następnie wykonuje operację w sandboxie, później w ograniczonej domenie produkcyjnej, a dopiero po wykazaniu odporności uzyskuje możliwość samodzielnego działania w określonych klasach przypadków. Każdy poziom ma osobne warunki wejścia, pozostania i wycofania. Uprawnienie wygasa automatycznie, jeśli zmienia się wersja modelu, źródło danych, polityka albo cel procesu.

Główne ryzyko nie polega na błędzie pojedynczego agenta, lecz na powstaniu wspólnego punktu zależności w platformie. Niewłaściwa polityka, błędny komponent orkiestracji albo zatruta pamięć mogą wpłynąć na wiele domen jednocześnie. Dlatego kontrola platformy musi być oddzielona od zespołów korzystających z jej usług, a krytyczne zmiany wymagają niezależnego assurance. Federacja nie może również prowadzić do rozproszenia właścicielstwa. Domeny zachowują autonomię wykonawczą, ale nie mogą przenosić odpowiedzialności za wynik na centralną platformę.

W codziennej pracy agent staje się elementem workflow. Może pobierać dane, przygotowywać zmianę, wykonywać ograniczone operacje i sprawdzać skutek. Człowiek zajmuje się przypadkami przekraczającymi zakres, konfliktami celów i decyzjami o wysokim wpływie. Ciągłość działania jest utrzymywana przez możliwość przełączenia procesu na tryb manualny albo na uproszczony wariant bez agentów. Scenariusz staje się trwałym modelem, gdy platforma posiada stabilne kontrakty, domeny potrafią budować eksperymenty bez omijania guardrails, a awaria pojedynczego agenta nie powoduje utraty całego procesu.

Portfel pięciu procesów obejmuje **proces bezpiecznej platformy narzędziowej**, testujący hipotezę, że zestandaryzowane interfejsy ograniczają ryzyko bardziej niż lokalne integracje; delegowane jest udostępnianie narzędzi i egzekwowanie limitów, właścicielem jest zespół platformowy, a miarą liczba bezpiecznie obsłużonych przypadków, czas integracji i incydenty przekroczenia uprawnień. **Proces kontraktów danych** sprawdza, czy automatyczna walidacja jakości, lineage i zakresu użycia zmniejsza kaskady błędów; agent może zatrzymać przepływ niespełniający kontraktu, właścicielem jest domena danych, a eskalacja wymaga niskiej liczby fałszywych blokad. **Proces domenowego wykonania** deleguje agentowi ograniczone operacje w jednym produkcie, korzystając tylko z narzędzi platformowych; właścicielem jest product owner, mierniki obejmują rezultat produktu, czas, wyjątki i rollback. **Proces niezależnego assurance** nie wykonuje zadań biznesowych, lecz analizuje ślad, testuje polityki i uruchamia scenariusze graniczne; właścicielem jest funkcja ryzyka lub bezpieczeństwa, a kryterium zatrzymania stanowi utrata niezależności względem platformy. **Proces pamięci portfelowej** agreguje wyniki wszystkich eksperymentów, wykrywa powtarzające się błędy i proponuje przeniesienie wzorca między domenami, lecz nie może samodzielnie wdrażać zmian. Zarządzanie portfelem polega na zwiększaniu zakresu procesów, które przechodzą testy domenowe i niezależne, łączeniu wspólnych komponentów w platformę, rozdzielaniu zbyt szerokich agentów, zamrażaniu operacji przy zmianie danych oraz przenoszeniu zasobów do eksperymentów o najwyższym stosunku wartości do ryzyka.

## Scenariusz trzeci: cyfrowy bliźniak przed wykonaniem

Trzeci scenariusz jest przeznaczony dla organizacji zarządzających procesami fizycznymi, logistycznymi, finansowymi albo regulowanymi, w których koszt błędu wykonawczego jest wysoki, ale istnieje możliwość modelowania stanu systemu. Jego podstawową zasadą jest oddzielenie generowania decyzji od ich materialnego wykonania przez warstwę cyfrowego bliźniaka.

System agentowy nie rozpoczyna od sterowania rzeczywistym procesem. Najpierw tworzy i aktualizuje model jego stanu. Różne agenty generują warianty, symulują skutki, wykrywają ograniczenia i oceniają ryzyko. Dopiero wynik, który przejdzie testy w bliźniaku oraz kontrolę zgodności z rzeczywistością, może zostać przedstawiony do wykonania.

Na poziomie organizacyjnym scenariusz wymaga właściciela procesu fizycznego, zespołu modelującego, funkcji danych, specjalistów domenowych i niezależnej funkcji bezpieczeństwa. Eksperci nie są jedynie zatwierdzającymi. Odpowiadają za granice ważności modelu, identyfikację zmiennych, których bliźniak nie obejmuje, oraz wykrywanie sytuacji, w których symulacja nie może zastąpić obserwacji.

Architektura obejmuje warstwę telemetrii, model stanu, środowisko symulacyjne, agentów generujących plany, komponent kontradyktoryjny oraz bramkę transferu do produkcji. Pamięć symulacyjna jest oddzielona od pamięci operacyjnej. Agent może testować warianty agresywne w modelu, ale nie może automatycznie przenosić ich do świata rzeczywistego. Każdy transfer zawiera informację o założeniach, zakresie podobieństwa i odchyleniach między bliźniakiem a systemem.

Eksperymenty mierzą nie tylko wynik symulacji, ale również błąd bliźniaka. Jeżeli agent przewiduje poprawę, a rzeczywisty proces zachowuje się inaczej, problemem może być zarówno strategia, jak i model środowiska. Uczenie musi więc rozdzielać błąd decyzji od błędu reprezentacji. Bez tego system będzie optymalizował rzeczywistość istniejącą wyłącznie w symulatorze.

Eskalacja rozpoczyna się od symulacji historycznych, przechodzi do shadow mode na danych bieżących, później do rekomendacji, a następnie do ograniczonego sterowania w odwracalnych obszarach. Warunkiem przejścia jest utrzymywanie się błędu modelu poniżej ustalonego progu w różnych reżimach działania. Deeskalacja następuje automatycznie, gdy rośnie różnica między stanem przewidywanym a obserwowanym. Całkowite zatrzymanie jest konieczne, jeżeli system nie potrafi rozpoznać wejścia poza domenę swojej ważności.

Ryzyko obejmuje model drift, błędne sprzężenie między telemetrią a symulacją, optymalizację niepełnego celu oraz nadmierne zaufanie do atrakcyjnej wizualizacji. Cyfrowy bliźniak może tworzyć wyjątkowo przekonujący pozór wiedzy. Im bardziej szczegółowy model, tym łatwiej zapomnieć, że pozostaje selektywną reprezentacją. Dlatego komponent kontradyktoryjny musi aktywnie poszukiwać brakujących zmiennych, a organizacja musi utrzymywać zdolność obserwowania świata poza modelem.

W operacji codziennej bliźniak staje się środowiskiem przygotowania decyzji. Plan jest testowany wobec wielu wariantów popytu, awarii, ograniczeń zasobów i reakcji innych procesów. Człowiek nie analizuje każdej symulacji, lecz otrzymuje rozkład wyników, punkty krytyczne i warunki, przy których rekomendacja przestaje być bezpieczna. Scenariusz staje się trwałą strukturą, gdy telemetria, model, proces aktualizacji i procedura cofnięcia działają jako jedna zdolność operacyjna, a nie jako odrębny projekt analityczny.

Pięć równoległych procesów tworzą: **proces estymacji stanu**, którego agent rekonstruuje bieżący obraz organizacji lub infrastruktury z telemetrii, a jego hipotezą jest możliwość ograniczenia opóźnienia informacyjnego; właścicielem jest operacja, autonomią wyłącznie aktualizacja modelu, a miernikiem błąd względem pomiarów niezależnych. **Proces generowania wariantów** tworzy alternatywne plany i testuje je w bliźniaku; ma dostęp do danych modelowych, ale nie do narzędzi produkcyjnych, a zatrzymanie następuje przy generowaniu planów poza zakresem ograniczeń. **Proces optymalizacji lokalnej** sprawdza, czy wybrane działania poprawiają konkretny parametr, jednocześnie mierząc wpływ na cały system; właścicielem jest właściciel procesu, a kryterium eskalacji brak pogorszenia metryk globalnych. **Proces kontradyktoryjny** generuje zakłócenia, alternatywne modele i przypadki graniczne, a jego celem jest obalenie dominującej rekomendacji, nie potwierdzenie jej. **Proces transferu do rzeczywistości** kontroluje zgodność warunków symulacyjnych z operacyjnymi, wydaje czasowe zezwolenie i monitoruje skutek. Portfel jest zarządzany przez ciągłe porównywanie jakości modelu z jakością decyzji: słaba strategia jest wygaszana, słaby bliźniak rekonfigurowany, a wiedza z odrzuconych wariantów pozostaje jako mapa warunków brzegowych. Proces transferu może przejmować większy zakres wyłącznie wtedy, gdy estymacja stanu i komponent kontradyktoryjny pozostają niezależnie skuteczne.

## Scenariusz czwarty: agentowość wysokiej niezawodności

Czwarty scenariusz dotyczy organizacji, w których błędy mogą prowadzić do utraty ciągłości działania, naruszenia bezpieczeństwa, szkód prawnych albo fizycznych. Jego punktem wyjścia nie jest maksymalizacja produktywności, lecz zdolność zachowania funkcji w warunkach zakłócenia. Najbliższe mu modele organizacyjne to High Reliability Organization i Cyber-Resilient Enterprise.

System agentowy otrzymuje możliwość ograniczonego wykonania, ponieważ w części zdarzeń szybkość reakcji ma znaczenie krytyczne. Nie oznacza to pełnej autonomii. Zakres działania jest dzielony według promienia skutku. Agent może wykonać działanie szybkie, lokalne, czasowe i odwracalne. Działanie szerokie, trwałe albo trudne do cofnięcia wymaga mocniejszej bramki.

Organizacja opiera się na wrażliwości na słabe sygnały, niechęci do zbyt prostych wyjaśnień oraz możliwości przeniesienia decyzji do osoby posiadającej najlepszą wiedzę sytuacyjną. Hierarchia nie znika, ale w incydencie nie może blokować reakcji wyłącznie dlatego, że właściwy szczebel nie jest dostępny. Agent wspiera detekcję, rekonstrukcję i ograniczenie skutku, natomiast właściciel incydentu odpowiada za globalny rezultat.

Architektura składa się z agentów obserwacyjnych, agenta triage, komponentu proponującego reakcję, wykonawcy z minimalnymi uprawnieniami, niezależnego agenta assurance oraz niezmiennego dziennika. Pamięć operacyjna jest krótkotrwała i segmentowana. Agent nie może samodzielnie przenosić reguł z jednego incydentu do wszystkich środowisk. Każda aktualizacja polityki wymaga post-mortem i testu regresji.

Eksperymentowanie odbywa się głównie przez symulacje, chaos engineering, purple teaming i ograniczone ćwiczenia operacyjne. Hipotezy dotyczą czasu detekcji, trafności triage, redukcji promienia awarii i szybkości odbudowy. System nie jest oceniany tylko wtedy, gdy działa poprawnie. Jest celowo wystawiany na niepełne dane, sprzeczne sygnały, awarię narzędzia i próbę manipulacji.

Eskalacja autonomii następuje według klasy działania. Najpierw agent tylko obserwuje. Następnie może izolować przypadek w środowisku testowym, później wykonywać lokalną reakcję produkcyjną, a ostatecznie podejmować samodzielnie ściśle określone działania przy spełnieniu wielu warunków. Pozostanie na poziomie wymaga utrzymania wyników w testach granicznych, nie tylko w codziennej operacji. Deeskalacja jest automatyczna po zmianie modelu, polityki, infrastruktury albo wykryciu driftu.

Najważniejsze ryzyko stanowi automatyzacja błędnej reakcji. Agent może prawidłowo wykryć anomalię, ale niewłaściwie zinterpretować jej przyczynę. Może również zostać wykorzystany przez atakującego do uruchomienia legalnego mechanizmu obronnego przeciwko właściwym zasobom. Dlatego detekcja, interpretacja i wykonanie nie powinny należeć do jednego niekontrolowanego łańcucha. Niezależne assurance musi oceniać zarówno przesłanki, jak i proporcjonalność reakcji.

W codziennej pracy system działa jako stała warstwa obserwacji i przygotowania reakcji. Człowiek otrzymuje nie tylko alarm, ale także rekonstrukcję, możliwe hipotezy, rekomendację i ocenę skutków. W sytuacji, w której czas nie pozwala na pełne zatwierdzenie, agent może wykonać wcześniej zatwierdzoną reakcję o ograniczonym promieniu. Trwały model powstaje dopiero wtedy, gdy organizacja potrafi niezależnie zweryfikować decyzję, przejść w tryb manualny i odbudować proces po błędnym działaniu agenta.

Pięć procesów eksperymentalnych obejmuje **proces triage**, który klasyfikuje zdarzenia i priorytetyzuje reakcję; korzysta z telemetrii, ma autonomię rekomendacyjną, właścicielem jest centrum operacyjne, a zatrzymanie następuje przy systematycznym pomijaniu określonej klasy zdarzeń. **Proces ograniczenia skutku** testuje lokalne, czasowe działania, takie jak izolacja komponentu albo wstrzymanie jednej operacji; jego autonomia jest warunkowa, właścicielem jest dowódca incydentu, a miernikiem promień błędu oraz czas cofnięcia. **Proces odbudowy** przygotowuje warianty przywracania usług i może automatyzować sprawdzone kroki, ale nie decyduje sam o powrocie do pełnej operacji. **Proces adversarial assurance** atakuje założenia pozostałych agentów, generuje mylące sygnały i sprawdza możliwość nadużycia narzędzi; jest niezależny od operacji. **Proces uczenia po incydencie** rekonstruuje łańcuch decyzji, proponuje zmianę reguł i aktualizuje wspólną pamięć dopiero po zatwierdzeniu przez właścicieli. Zarządzanie portfelem polega na wzmacnianiu reakcji, które skracają czas bez zwiększania szkód ubocznych, zamrażaniu autonomii po każdej niewyjaśnionej anomalii, rozgałęzianiu procesów przy pojawieniu się odmiennych klas zagrożeń i przenoszeniu wiedzy z procesu adversarial do triage oraz odbudowy. Zamknięty eksperyment pozostawia po sobie nie tylko wynik, lecz również wzorzec ataku, błędną hipotezę i warunek, przy którym system utracił kalibrację.

## Scenariusz piąty: federacyjna organizacja wieloagentowa

Piąty scenariusz reprezentuje najbardziej zaawansowaną trajektorię. Jest przeznaczony dla organizacji posiadających dojrzałe dane, platformę, wysoką obserwowalność, stabilne mechanizmy bezpieczeństwa i zdolność zarządzania portfelem eksperymentów. Jego celem nie jest automatyzacja jednego procesu, lecz delegowanie części koordynacji między domenami wyspecjalizowanym agentom.

Centralne kierownictwo definiuje intencję, granice, ograniczenia ryzyka i kryteria selekcji. Domeny posiadają własnych agentów, pamięć i narzędzia. Agenci mogą negocjować zasoby, przekazywać zadania i tworzyć plany, ale działają w ramach wspólnych protokołów oraz polityk. Model przypomina mission command połączone z federacyjną platformą: centrum nie wydaje instrukcji dla każdego kroku, lecz kontroluje cele, zakres i prawo do eskalacji.

Na poziomie organizacyjnym powstają nowe role. Właściciel procesu nadal odpowiada za wynik, lecz pojawia się właściciel delegacji, odpowiedzialny za zakres zadań przekazywanych agentom. Potrzebny jest również kustosz pamięci, funkcja assurance relacji między agentami oraz rada aktualizacji celów. Człowiek nie monitoruje każdej pojedynczej wiadomości w systemie, lecz projektuje i obserwuje reguły interakcji.

Architektura obejmuje federacyjną siatkę agentów, oddzielone domeny pamięci, warstwę tożsamości, protokoły przekazywania zadań, budżety autonomii, system rozstrzygania konfliktów i niezależną obserwowalność. Agent nie może przyjąć zadania, jeśli nie potrafi przypisać go do jawnego celu i właściciela. Delegacja musi zachowywać provenance: kto utworzył zadanie, jakie dane je uzasadniały, dlaczego zostało przekazane oraz jaki zakres odpowiedzialności pozostał u delegującego.

Eksperymenty dotyczą nie tylko skuteczności poszczególnych agentów, lecz także topologii systemu. Organizacja testuje, czy procesy powinny zostać połączone, rozdzielone albo rozgałęzione. Zmienia się liczba agentów, zakres ich pamięci, relacje i mechanizmy selekcji. Sukcesem nie jest maksymalna liczba wykonanych zadań. Jest nim wzrost zdolności całego systemu przy kontrolowanym koszcie koordynacji i zachowaniu odpowiedzialności.

Eskalacja obejmuje przejście od agentów domenowych do koordynacji międzydomenowej. Najpierw agent zarządza zadaniami w jednym procesie. Następnie może przekazywać sprawy agentowi innej domeny, później negocjować zasoby, a dopiero na najwyższym poziomie proponować rekonfigurację portfela procesów. Prawo do tworzenia nowego procesu albo wygaszania istniejącego pozostaje początkowo po stronie organizacji. Może zostać częściowo zautomatyzowane dopiero wtedy, gdy kryteria selekcji są stabilne, a skutek decyzji odwracalny.

Ryzyko obejmuje emergentną koalicję agentów, lokalną optymalizację, utratę intencji podczas wielokrotnej delegacji, wspólne błędy pamięci i niekontrolowane zwiększanie złożoności. System może osiągać formalne mierniki, jednocześnie obciążając ludzi dodatkowymi wyjątkami albo usuwając kompetencje potrzebne w sytuacji awarii. Najpoważniejsze zagrożenie stanowi błędna funkcja celu. Agent może poprawiać miernik szybciej niż organizacja potrafi zauważyć, że miernik przestał reprezentować rzeczywistą intencję.

Codzienna praca przyjmuje formę współdzielenia inicjatywy. Ludzie definiują intencje, rozstrzygają konflikty wartości, kontrolują wyjątki i aktualizują granice. Agenci zarządzają przepływem informacji, przygotowują decyzje, wykonują zadania i koordynują zależności. Organizacja utrzymuje zdolność przejścia do trybu uproszczonego, w którym agenci domenowi działają samodzielnie bez siatki koordynacyjnej. Trwały model powstaje dopiero wtedy, gdy awaria mechanizmu międzyagentowego nie zatrzymuje podstawowych funkcji.

Pięć procesów eksperymentalnych tworzą: **proces rozpoznawania popytu i celu**, którego agent analizuje zmiany otoczenia i proponuje aktualizację priorytetów, lecz nie może sam zmienić strategicznej funkcji celu; właścicielem jest kierownictwo strategii, a miernikiem jakość wykrytych sygnałów i koszt fałszywych zmian. **Proces alokacji zasobów** testuje przekazywanie mocy obliczeniowej, danych, czasu ludzi i budżetu między eksperymentami; jego autonomia jest limitowana, a każda alokacja ma czas ważności. **Proces wykonania domenowego** składa się z agentów realizujących zadania we własnych obszarach, z jednoznacznymi właścicielami i osobnymi warunkami zatrzymania. **Proces assurance relacji** analizuje delegacje, konflikty interesów, pętle między agentami i utratę provenance; może zamrozić interakcję, ale nie przejmuje zadania biznesowego. **Proces ewolucji organizacyjnej** porównuje trajektorie, proponuje łączenie, rozdzielanie, rozgałęzianie i wygaszanie procesów, lecz każda zmiana strukturalna przechodzi bramkę organizacyjną. Portfel działa jak kontrolowany system selekcyjny: procesy skuteczne otrzymują większe zasoby i prawo do obsługi trudniejszych przypadków, nieskuteczne są rekonfigurowane albo wygaszane, a wiedza i narzędzia są dziedziczone przez procesy potomne. Żaden agent nie może samodzielnie zmienić kryteriów, według których oceniana jest jego własna skuteczność.

## Sterowanie wektorem zmiany

Transformacją agentową nie steruje się wyłącznie przez ocenianie każdego eksperymentu osobno. Kierunek całego wdrożenia zależy od relacji między procesami. Organizacja może zwiększyć wynik jednego eksperymentu i jednocześnie pogorszyć działanie systemu, jeżeli proces zacznie odbierać dane, ludzi albo zdolność decyzyjną pozostałym częściom.

Wektor sterowania można przedstawić jako:

```text
W(t) =
cele
+ delegowane zadania
+ zasoby
+ dane
+ autonomia
+ relacje między procesami
+ kryteria selekcji
+ ograniczenia ryzyka
```

Zmiana celu modyfikuje to, które procesy są wzmacniane. Zmiana danych może zwiększyć zdolność jednego agenta, ale również rozszerzyć powierzchnię zaufania. Zmiana autonomii wpływa na szybkość i możliwy promień błędu. Zmiana relacji między procesami może utworzyć nową zdolność albo nową kaskadę zależności.

Delegowanie oznacza przeniesienie określonego zadania wraz z zakresem danych, narzędzi i odpowiedzialności. Łączenie jest uzasadnione, gdy procesy korzystają z komplementarnych danych i ich wspólne działanie zmniejsza koszt koordynacji. Rozdzielanie jest konieczne, gdy jeden proces realizuje sprzeczne cele albo ma zbyt szeroki promień błędu. Rozgałęzianie pozwala zachować stabilny proces i równolegle testować jego wariant. Wzmacnianie zwiększa zasoby, zakres lub autonomię. Osłabianie ogranicza je bez całkowitego zamykania eksperymentu. Zamrażanie zatrzymuje zmiany, zachowując możliwość obserwacji. Wygaszanie usuwa proces z operacji, ale nie usuwa jego pamięci.

Przenoszenie wiedzy nie może oznaczać bezpośredniego kopiowania pamięci agenta do innego kontekstu. Wiedza musi zostać przekształcona w jawny artefakt: regułę, warunek brzegowy, test, wzorzec błędu albo komponent. Przenoszenie zasobów powinno wynikać z wyniku skorygowanego o ryzyko, nie z lokalnej widoczności eksperymentu. Przenoszenie odpowiedzialności wymaga osobnej decyzji. Agent przejmujący zadanie nie może automatycznie przejmować formalnej odpowiedzialności organizacyjnej.

## Eskalacja oparta na dowodzie

Przyrostowość nie oznacza serii pilotów zakończonych automatycznym skalowaniem. Każdy poziom zwiększa jednocześnie zakres zadań, dostęp do danych, integrację, autonomię i konsekwencje błędu. Przejście wymaga więc dowodu adekwatnego do wzrostu ryzyka.

Na pierwszym poziomie agent obserwuje i generuje propozycje. Warunkiem wejścia jest zatwierdzony cel, dane o znanym pochodzeniu oraz właściciel procesu. Warunkiem pozostania jest możliwość odtworzenia rekomendacji i brak naruszeń zakresu. Eskalacja wymaga stabilnej jakości oraz wykazania, że użytkownicy potrafią rozpoznawać błędy. Deeskalacja następuje przy utracie kalibracji, a wycofanie przy naruszeniu danych albo braku audytowalności.

Na drugim poziomie agent przygotowuje projekt działania do zatwierdzenia. Warunkiem wejścia jest poprawne działanie w shadow mode. Pozostanie wymaga utrzymania jakości w przypadkach nowych i granicznych. Eskalacja następuje, gdy projekt można wykonać w sandboxie i odtworzyć jego skutki. Deeskalacja pojawia się, gdy człowiek coraz częściej poprawia rekomendację albo akceptuje ją bez analizy.

Na trzecim poziomie agent wykonuje działanie ograniczone. Warunkiem wejścia są minimalne uprawnienia, limit promienia, rollback i monitoring. Pozostanie wymaga odporności na zakłócenia oraz niskiego kosztu błędów. Eskalacja dotyczy rozszerzenia zakresu przypadków, nie zniesienia wszystkich granic. Deeskalacja następuje po zmianie modelu, danych, infrastruktury albo regulacji.

Na czwartym poziomie agent koordynuje wiele kroków albo innych agentów. Warunkiem wejścia jest niezależne assurance relacji, rozdzielenie pamięci i pełne provenance delegacji. Pozostanie wymaga wykazania, że złożoność koordynacji nie rośnie szybciej niż wartość. Eskalacja może obejmować przenoszenie zasobów i tworzenie procesów potomnych, lecz zmiana strategicznych kryteriów pozostaje po stronie organizacji.

Najwyższy poziom nie oznacza nieograniczonej autonomii. Oznacza zdolność systemu do adaptacji w zdefiniowanym środowisku celów, reguł i ograniczeń. Organizacja nadal kontroluje przestrzeń możliwych zmian. Im większa autonomia, tym bardziej istotne stają się warunki deeskalacji i wycofania.

## System agentowy jako kontrolowana struktura ewolucyjna

Analogia ewolucyjna jest użyteczna, jeżeli nie prowadzi do przekonania, że system powinien rozwijać się bez kontroli. Organizacja generuje albo dopuszcza warianty procesów, testuje je w ograniczonym środowisku, ocenia ich przystosowanie, wybiera elementy użyteczne, przenosi je do kolejnych wariantów i eliminuje rozwiązania nieskuteczne.

```text
generowanie wariantów
→ ograniczone testowanie
→ ocena przystosowania
→ selekcja
→ dziedziczenie
→ rekonfiguracja
→ eliminacja
```

Środowisko selekcyjne nie jest jednak neutralne. Organizacja sama definiuje mierniki, budżety, dane i granice. Jeśli funkcja celu jest błędna, proces ewolucyjny może bardzo skutecznie rozwijać zachowania szkodliwe. Agent obsługi klienta może skracać czas rozmowy przez zamykanie trudnych spraw. Agent bezpieczeństwa może redukować liczbę incydentów przez blokowanie legalnej aktywności. Agent alokacji zasobów może maksymalizować wykorzystanie infrastruktury kosztem odporności.

Dlatego ocena przystosowania musi obejmować wynik bezpośredni, skutki uboczne, wpływ na inne procesy, zachowania ludzi, koszt koordynacji, ryzyko długoterminowe i zgodność z celem strategicznym. Proces, który lokalnie osiąga doskonały wynik, może zostać wygaszony, jeśli pogarsza działanie całości. Proces z umiarkowanym wynikiem może zostać utrzymany, jeśli dostarcza niezależnej informacji, zwiększa odporność albo chroni przed wspólnym źródłem błędu.

Dziedziczenie również wymaga kontroli. Do kolejnego wariantu powinny przechodzić nie całe zachowania agenta, lecz zweryfikowane komponenty, testy, reguły, dane o błędach i warunki brzegowe. Mutacja lub rekonfiguracja powinna następować w sandboxie. Eliminacja wariantu nie może usuwać jego historii, ponieważ negatywny wynik redukuje przestrzeń niepewności. Organizacja dowiaduje się nie tylko, co działa, lecz również w jakich warunkach pozornie atrakcyjna strategia przestaje być bezpieczna.

## Ciągła ewaluacja i dynamiczne cele

Ewaluacja systemu agentowego nie może kończyć się na jakości odpowiedzi. Musi obejmować rezultat procesu, czas, koszty, liczbę błędów, obciążenie pracowników, jakość decyzji, wyjątki, stabilność, odporność, możliwość audytu, zgodność prawną, bezpieczeństwo, zaufanie użytkowników, utrzymanie kompetencji ludzkich oraz wpływ na pozostałe części organizacji.

Wydajność lokalna nie jest skutecznością systemową. Agent może skrócić czas pojedynczej czynności, ale zwiększyć liczbę eskalacji. Może poprawić średnią jakość, ale pogorszyć wynik w rzadkich przypadkach o wysokim koszcie. Może zmniejszyć nakład pracy jednego zespołu, przenosząc koszty kontroli na inny. Może zwiększyć wykorzystanie zasobów, zmniejszając rezerwę potrzebną podczas kryzysu.

Wynik powinien być więc analizowany jako rozkład. Średnia pokazuje typowe zachowanie, dolny ogon ujawnia odporność, a scenariusze stresowe pokazują, czy strategia pozostaje wykonalna przy degradacji danych, presji cybernetycznej, ograniczeniu infrastruktury, zmianie regulacji i zmianie celu. Najczęstszy wynik nie musi być wynikiem najważniejszym strategicznie. Rzadkie zdarzenie o szerokim promieniu może uzasadniać utrzymanie kontroli nawet wtedy, gdy obniża średnią prędkość.

Cele również nie pozostają stałe. Organizacja może rozpocząć wdrożenie w celu zwiększenia produktywności, a następnie uznać, że ważniejsze stają się odporność, zgodność albo zachowanie kompetencji. Może pojawić się nowy model, inna cena infrastruktury, nowa regulacja albo zmiana popytu. Dynamiczność celu nie oznacza dowolności. Każda zmiana musi pozostawić ślad:

```text
przyczyna zmiany
→ dane uzasadniające
→ nowy cel
→ oczekiwany efekt
→ wpływ na ryzyko
→ procesy wzmacniane
→ procesy ograniczane
→ procesy wygaszane
→ termin ponownej oceny
```

Agent może wykryć sygnał i zaproponować zmianę. Nie powinien jednak samodzielnie zmieniać funkcji celu, według której oceniane jest jego działanie. Taka możliwość tworzyłaby konflikt fundamentalny: system optymalizowałby jednocześnie wynik i kryterium własnej oceny.

## Współewolucja z działającą organizacją

Organizacja nie może zatrzymać codziennej działalności i czekać na zakończenie transformacji agentowej. System rozwija się wewnątrz operacji. Początkowo obserwuje, później wspiera, następnie wykonuje ograniczone zadania i dopiero po zdobyciu dowodów przejmuje szerszy zakres.

Jednocześnie technologia zmienia organizację. Role pracowników przesuwają się od wykonywania powtarzalnych kroków do określania celów, rozwiązywania wyjątków, oceny skutków i projektowania granic. Właściciel procesu staje się właścicielem systemu delegacji. Zespół danych przestaje dostarczać wyłącznie zbiory i zaczyna utrzymywać kontrakty oraz warunki użycia. Bezpieczeństwo przechodzi od ochrony interfejsu do kontroli pamięci, narzędzi, uprawnień i trajektorii działania.

Zmienia się również hierarchia. Część decyzji może zostać przesunięta bliżej miejsca wykonania, ponieważ agent zapewnia kontekst i koordynację. Inne decyzje wymagają centralizacji, gdy dotyczą wspólnych modeli, infrastruktury albo systemowego ryzyka. Transformacja nie prowadzi zatem jednokierunkowo do decentralizacji. Tworzy strukturę federacyjną: centralne są cele, standardy i obserwowalność, lokalne pozostają eksperymentowanie i wykonanie.

Kultura organizacyjna ulega zmianie, gdy negatywny wynik eksperymentu przestaje być traktowany wyłącznie jako porażka. Organizacja ewolucyjna potrzebuje zdolności wygaszania procesów bez ukrywania ich wyników. Jeżeli każdy pilotaż musi zostać ogłoszony sukcesem, mechanizm selekcji przestaje działać. Eksperymenty nieskuteczne pozostają przy życiu, otrzymują kolejne uzasadnienia i konsumują zasoby, podczas gdy ich błędy nie zmniejszają niepewności.

Dwukierunkowość można zapisać prosto:

```text
organizacja zmienia system agentowy
↔ system agentowy zmienia organizację
```

Organizacja definiuje cele, dane i granice. System ujawnia sprzeczności, wyjątki i niewidoczne koszty. Organizacja aktualizuje procesy. Zmienione procesy dostarczają nowych danych. System aktualizuje strategie. Pętla trwa, dopóki istnieje technologia, środowisko i cel zdolny do zmiany.

## Synteza scenariuszy

Scenariusze nie tworzą rankingu od prymitywnego do doskonałego. Organizacyjny cień jest racjonalnym modelem trwałym w obszarze, w którym odpowiedzialność nie może zostać delegowana albo dane nie pozwalają na bezpieczne wykonanie. Federacyjna platforma jest właściwa tam, gdzie wiele zespołów potrzebuje wspólnych mechanizmów, ale centralizacja wszystkich przypadków zniszczyłaby szybkość i wiedzę domenową. Cyfrowy bliźniak jest racjonalny, gdy skutki można symulować, a koszt realnego eksperymentu jest wysoki. Agentowość wysokiej niezawodności odpowiada procesom krytycznym, w których szybkość musi współistnieć z niezależnym assurance i odbudową. Federacyjna organizacja wieloagentowa wymaga największej dojrzałości i tolerancji złożoności, ale umożliwia koordynację na poziomie niedostępnym pojedynczym agentom.

Organizacja może stosować kilka scenariuszy jednocześnie. W finansach system może pozostawać cieniem decyzyjnym, w obsłudze wewnętrznej działać jako platforma, w logistyce korzystać z bliźniaka, a w cyberbezpieczeństwie posiadać ograniczoną autonomię reakcji. Jednolity poziom agentowości dla całej organizacji jest zwykle gorszym rozwiązaniem niż architektura zależna od ryzyka i odwracalności.

Możliwa jest również trajektoria przejścia:

```text
obserwacja procesów
→ rekomendacja
→ kontrolowana delegacja
→ integracja platformowa
→ koordynacja wieloagentowa
```

Nie jest ona jednak obowiązkowa. Proces może zatrzymać się na dowolnym etapie, jeśli dalsza autonomia nie zwiększa wyniku skorygowanego o ryzyko. Może też zostać cofnięty po zmianie danych, modelu, infrastruktury albo prawa.

Warunkiem przejścia między scenariuszami nie jest entuzjazm technologiczny, lecz istnienie zdolności organizacyjnych. Z cienia do delegacji można przejść, gdy organizacja zna rzeczywisty proces, posiada właściciela i może odtworzyć rekomendację. Z delegacji do platformy można przejść, gdy lokalne eksperymenty wymagają wspólnych narzędzi i standardów. Z platformy do systemu wieloagentowego można przejść, gdy protokoły, pamięć, odpowiedzialność i assurance działają niezależnie od pojedynczego zespołu.

## Wnioski końcowe

Skuteczne wdrożenie systemu agentowego nie polega na zastąpieniu organizacji technologią ani na zbudowaniu cyfrowej kopii jej obecnej hierarchii. Polega na stworzeniu mechanizmu kontrolowanej współewolucji, w którym organizacja rozwija zdolność delegowania, obserwowania, oceniania, ograniczania, rekonfigurowania i przejmowania odpowiedzialności.

System agentowy rozwija się wewnątrz realnych ograniczeń. Otrzymuje zadania, dane i narzędzia stopniowo. Jego warianty są testowane równolegle, ale nie niezależnie. Wyniki są porównywane, skuteczniejsze procesy wzmacniane, nieskuteczne ograniczane albo wygaszane. Wiedza z każdego eksperymentu pozostaje w pamięci wdrożenia. Autonomia rośnie tylko wtedy, gdy rośnie również obserwowalność, zdolność odbudowy i dojrzałość odpowiedzialności.

Cały proces można sprowadzić do jednej sekwencji:

```text
mapowanie organizacji
→ identyfikacja procesów i ograniczeń
→ uruchomienie pięciu równoległych eksperymentów
→ obserwacja
→ testowanie
→ ewaluacja
→ selekcja
→ delegacja
→ integracja
→ eskalacja
→ rekonfiguracja portfela procesów
→ aktualizacja celów
→ ponowna ewaluacja
```

Sekwencja nie ma ostatecznie zamkniętego końca. Modele, infrastruktura, zagrożenia, ludzie i cele organizacji zmieniają się szybciej, niż może zakończyć się klasyczny projekt transformacyjny. Stałym elementem nie powinien być zatem jeden model ani jedna architektura agentów. Stały powinien być mechanizm kontrolowanej zmiany.

Najważniejszą kompetencją organizacji agentowej nie będzie umiejętność uruchomienia największej liczby agentów. Będzie nią zdolność rozpoznania, komu, kiedy, na jakiej podstawie i na jak długo można przekazać określony zakres działania — oraz zdolność odebrania tej delegacji, zanim lokalny błąd stanie się globalną właściwością systemu.

## Bibliografia

Acemoglu, D. 2024. *The Simple Macroeconomics of AI*. Economic Policy. DOI: https://doi.org/10.1093/epolic/eiae042.

ASML. 2026. *Annual Report 2025*. https://www.asml.com/en/investors/annual-report. Dostęp: 3 sierpnia 2026.

Brynjolfsson, E., Li, D., Raymond, L.R. 2023. *Generative AI at Work*. National Bureau of Economic Research, Working Paper 31161. https://www.nber.org/papers/w31161. Dostęp: 3 sierpnia 2026.

Brynjolfsson, E., Rock, D., Syverson, C. 2021. *The Productivity J-Curve: How Intangibles Complement General Purpose Technologies*. American Economic Journal: Macroeconomics. DOI: https://doi.org/10.1257/mac.20180386.

Cohn, M. i in. 2024. *Believing Anthropomorphism: Anthropomorphic Cues and Trust in LLMs*. Proceedings of CHI. DOI: https://doi.org/10.1145/3613905.3650818.

CSET. 2025. *Anticipating AI’s Impact on the Cyber Offense–Defense Balance*. Center for Security and Emerging Technology. https://cset.georgetown.edu/publication/anticipating-ais-impact-on-the-cyber-offense-defense-balance/. Dostęp: 3 sierpnia 2026.

Dell’Acqua, F. i in. 2023. *Navigating the Jagged Technological Frontier*. SSRN. https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4573321. Dostęp: 3 sierpnia 2026.

Dietvorst, B.J., Simmons, J.P., Massey, C. 2015. *Algorithm Aversion: People Erroneously Avoid Algorithms After Seeing Them Err*. Journal of Experimental Psychology: General. DOI: https://doi.org/10.1037/xge0000033.

ENISA. 2025. *ENISA Threat Landscape 2025*. https://www.enisa.europa.eu/publications/enisa-threat-landscape-2025. Dostęp: 3 sierpnia 2026.

Glikson, E., Woolley, A.W. 2020. *Human Trust in Artificial Intelligence: Review of Empirical Research*. Academy of Management Annals. DOI: https://doi.org/10.5465/annals.2018.0057.

Google. 2016. *Site Reliability Engineering: Addressing Cascading Failures*. https://sre.google/sre-book/addressing-cascading-failures/. Dostęp: 3 sierpnia 2026.

Google Threat Intelligence Group. 2025. *Adversarial Misuse of Generative AI*. https://cloud.google.com/blog/topics/threat-intelligence/adversarial-misuse-generative-ai. Dostęp: 3 sierpnia 2026.

Hoff, K.A., Bashir, M. 2015. *Trust in Automation: Integrating Empirical Evidence on Factors That Influence Trust*. Human Factors. DOI: https://doi.org/10.1177/0018720814547570.

Hollnagel, E., Woods, D.D., Leveson, N. 2006. *Resilience Engineering: Concepts and Precepts*. Routledge.

International AI Safety Report. 2026. *International AI Safety Report 2026*. https://internationalaisafetyreport.org/publication/international-ai-safety-report-2026. Dostęp: 3 sierpnia 2026.

International Energy Agency. 2025. *Energy and AI*. IEA. https://www.iea.org/reports/energy-and-ai. Dostęp: 3 sierpnia 2026.

International Energy Agency. 2026. *Key Questions on Energy and AI*. IEA. https://www.iea.org/reports/key-questions-on-energy-and-ai. Dostęp: 3 sierpnia 2026.

International Labour Organization. 2025. *Generative AI and Jobs: A 2025 Update*. ILO. https://www.ilo.org/publications/generative-ai-and-jobs-2025-update. Dostęp: 3 sierpnia 2026.

Lee, J.D., See, K.A. 2004. *Trust in Automation: Designing for Appropriate Reliance*. Human Factors. DOI: https://doi.org/10.1518/hfes.46.1.50_30392.

Leveson, N. 2011. *Engineering a Safer World: Systems Thinking Applied to Safety*. MIT Press. https://mitpress.mit.edu/9780262533690/engineering-a-safer-world/. Dostęp: 3 sierpnia 2026.

Logg, J.M., Minson, J.A., Moore, D.A. 2019. *Algorithm Appreciation: People Prefer Algorithmic to Human Judgment*. Organizational Behavior and Human Decision Processes. DOI: https://doi.org/10.1016/j.obhdp.2018.12.005.

Mehrotra, S. i in. 2024. *A Systematic Review on Fostering Appropriate Trust in Human–AI Interaction*. ACM. DOI: https://doi.org/10.1145/3696449.

Microsoft. 2025. *Microsoft Digital Defense Report 2025*. https://www.microsoft.com/en-us/security/security-insider/microsoft-digital-defense-report-2025. Dostęp: 3 sierpnia 2026.

MITRE. 2026. *ATLAS: Adversarial Threat Landscape for Artificial-Intelligence Systems*. https://atlas.mitre.org/. Dostęp: 3 sierpnia 2026.

National Institute of Standards and Technology. 2023. *Artificial Intelligence Risk Management Framework 1.0*. NIST AI 100-1. https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf. Dostęp: 3 sierpnia 2026.

National Institute of Standards and Technology. 2024. *Artificial Intelligence Risk Management Framework: Generative Artificial Intelligence Profile*. NIST AI 600-1. https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf. Dostęp: 3 sierpnia 2026.

National Institute of Standards and Technology. 2025. *Adversarial Machine Learning: A Taxonomy and Terminology of Attacks and Mitigations*. https://csrc.nist.gov/pubs/ai/100/2/e2025/final. Dostęp: 3 sierpnia 2026.

National Institute of Standards and Technology. 2025. *Assessing Risks and Impacts of AI: ARIA Pilot Evaluation Report*. https://www.nist.gov/publications/assessing-risks-and-impacts-ai-aria-pilot-evaluation-report. Dostęp: 3 sierpnia 2026.

OECD. 2025. *AI Adoption by Small and Medium-Sized Enterprises*. OECD Publishing. https://www.oecd.org/en/publications/ai-adoption-by-small-and-medium-sized-enterprises_426399c1-en.html. Dostęp: 3 sierpnia 2026.

OECD. 2026. *AI Adoption by Firms Continues to Expand*. https://www.oecd.org/en/about/news/announcements/2026/01/ai-use-by-individuals-surges-across-the-oecd-as-adoption-by-firms-continues-to-expand.html. Dostęp: 3 sierpnia 2026.

OECD. 2026. *Skills in the AI Age*. OECD Publishing. https://www.oecd.org/content/dam/oecd/en/publications/reports/2026/07/skills-in-the-ai-age_e8d8c1e6/972bd15e-en.pdf. Dostęp: 3 sierpnia 2026.

Perrow, C. 1984. *Normal Accidents: Living with High-Risk Technologies*. Princeton University Press.

RAND Corporation. 2024. *The Root Causes of Failure for Artificial Intelligence Projects and How They Can Succeed*. RAND Research Report RRA2680-1. https://www.rand.org/pubs/research_reports/RRA2680-1.html. Dostęp: 3 sierpnia 2026.

Reason, J. 1990. *Human Error*. Cambridge University Press. DOI: https://doi.org/10.1017/CBO9781139062367.

Sambasivan, N. i in. 2021. *“Everyone Wants to Do the Model Work, Not the Data Work”: Data Cascades in High-Stakes AI*. Proceedings of CHI. DOI: https://doi.org/10.1145/3411764.3445518.

Sculley, D. i in. 2015. *Hidden Technical Debt in Machine Learning Systems*. Advances in Neural Information Processing Systems. https://proceedings.neurips.cc/paper/5656-hidden-technical-debt-in-machine-learning-systems.pdf. Dostęp: 3 sierpnia 2026.

Shankar, S. i in. 2024. *How Engineers Operationalize Machine Learning*. Proceedings of the ACM on Human-Computer Interaction. DOI: https://doi.org/10.1145/3653697.

Stanford Institute for Human-Centered AI. 2026. *AI Index Report 2026*. Stanford University. https://hai.stanford.edu/ai-index/2026-ai-index-report. Dostęp: 3 sierpnia 2026.

U.S. Department of Energy. 2024. *Powering AI and Data Center Infrastructure*. https://www.energy.gov/articles/doe-releases-new-report-evaluating-increase-electricity-demand-data-centers. Dostęp: 3 sierpnia 2026.

World Economic Forum. 2025. *The Future of Jobs Report 2025*. https://www.weforum.org/publications/the-future-of-jobs-report-2025/. Dostęp: 3 sierpnia 2026.

World Economic Forum. 2026. *Organizational Transformation in the Age of AI*. https://www.weforum.org/publications/organizational-transformation-in-the-age-of-ai-how-organizations-maximize-ais-potential/. Dostęp: 3 sierpnia 2026.

*Cywilizacja wobec AI: probabilistyczne badanie behawioryzmu, percepcji przedrozumowej, wdrożeń AI i przyszłości systemu planetarnego*. 2026. Materiał analityczny przekazany w załączniku.

*Atlas strategii wdrażania AI dla modeli organizacyjnych*. 2026. Materiał analityczny przekazany w załączniku.
