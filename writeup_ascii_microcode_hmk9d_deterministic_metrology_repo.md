# Deterministyczna metrologia strukturalna dla LLM: ASCII Microcode + HMK-9D jako warstwa kontrolna, regresyjna i audytowalna

## Abstrakt

W praktycznych wdrożeniach dużych modeli językowych (LLM) stabilność procesu wytwarzania tekstu bywa równie krytyczna jak jakość semantyczna odpowiedzi. W systemach produkcyjnych „to samo polecenie” nie jest zawsze „tym samym eksperymentem”: na wynik wpływa probabilistyczne próbkowanie, parametry dekodowania, a w usługach sieciowych dochodzą zmiany wersji modelu, zmiany backendu, równoważenie obciążenia oraz niejawne aktualizacje infrastruktury. W konsekwencji, nawet gdy semantyka pozostaje akceptowalna, zmienia się forma: liczba pytań, liczba ostrzeżeń, sposób domykania wniosków, gęstość argumentacji. Dokumentacja praktyk „reproducible outputs” wprost zakłada, że powtarzalność bywa „best effort” i opiera się na sygnałach typu `seed` oraz `system_fingerprint`, które służą do zwiększania, ale nie gwarantowania identyczności wyników w czasie.

Niniejsza praca proponuje rozdzielenie „miękkiej” generacji od „twardego” pomiaru: odpowiedź jest formatowana jako minimalny, parsowalny mikrokod ASCII (ASCII Microcode), a następnie mapowana deterministycznie do wektora stanu HMK-9D oraz metryk pomocniczych. Kluczowa teza brzmi: jeżeli inferencja bywa niedeterministyczna, to warstwa metrologiczna powinna być deterministyczna, jawna i odporna na „literackość” wyjścia; ma mierzyć artefakt odpowiedzi, nie „ładność” ani „prawdę” zdań.

Pokazujemy, jak to osiągnąć w praktyce przez trzy rygory operacyjne, które razem tworzą kontrakt audytowalności. Po pierwsze, klasa epistemiczna linii wynika wyłącznie z tagu, nie z treści. Po drugie, znacznik `[DET]` jest kontraktem na deterministyczne wyliczenie wartości AX/LENS/MT albo jawne `n/a` (bez udawania liczb). Po trzecie, fallback `SCORER_SPEC_LOCAL_DET` wylicza wartości 0–1 wyłącznie z rozkładu tagów w danym bloku `[ODP_BEGIN]…[ODP_END]`, co eliminuje `n/a` w środowisku bez zewnętrznego scorera. Dowody w postaci dwóch bloków ODP pokazują, że identyczne wektory HMK-9D mogą występować w różnych wątkach przy różnej treści, jeśli struktura (`tag_counts`) jest identyczna — i jest to zamierzona cecha metrologii strukturalnej: stabilna warstwa kontrolna nad niedeterministyczną generacją.

## Rama abstrakcji: odpowiedź jako artefakt, metrologia jako interfejs sterowania

Żeby traktować LLM „poważnie” w systemie specjalistycznym, trzeba przestać traktować odpowiedź jako tekst do czytania, a zacząć traktować ją jako artefakt procesowy. Artefakt ma strukturę, wejście, wyjście, reguły poprawności, reguły odpowiedzialności oraz historię zmian; dopiero na tym tle „znaczenie” staje się jedną z własności, nie jedyną. W takim ujęciu model nie jest jedynie autorem, lecz komponentem w łańcuchu: generuje materiał, który musi przejść przez walidację, pomiar, archiwizację i porównanie z poprzednimi iteracjami. Dla audytu i regresji kluczowe jest nie to, czy zdania brzmią ładnie, lecz czy proces jest policzalny, czy da się wskazać, co się zmieniło, oraz czy zmiana jest zamierzona.

Metrologia strukturalna jest tu świadomie „twardsza” niż semantyka. Semantyka jest miękka, bo zależy od kontekstu, źródeł, domeny, interpretacji; metrologia ma być twarda, bo ma działać jak czujnik w pętli kontroli. Czujnik nie ma mieć opinii o świecie; ma dawać stabilny sygnał o stanie procesu. Ten sygnał, z definicji, jest wtórny wobec treści: mówi „ile było pytań i ostrzeżeń”, „czy nastąpiło domknięcie”, „czy krok jest gęsty czy rozproszony”, „czy odpowiedź jest bardziej kontekstowa czy bardziej deklaratywna”. Dzięki temu pętla inżynieryjna (testy, monitoring, alerting, przeglądy) dostaje metrykę, która nie zależy od retoryki.

Współczesne praktyki „wymuszania struktury” w LLM idą w podobnym kierunku: narzędzia typu structured outputs wymuszają zgodność wyjścia ze schematem, aby system downstream nie musiał zgadywać, „co autor miał na myśli”. ([OpenAI Platform][15]) ASCII Microcode jest wariantem tej idei przesuniętym w stronę pracy repozytoryjnej i audytu: zamiast bogatego formatu danych, daje minimalny DSL, w którym już sama powierzchnia odpowiedzi jest „mierzalna”.

Inżynieria systemów uczy, że pomiar jest tak dobry, jak jego jednoznaczność, odporność na prezentację oraz możliwość odtworzenia w czasie. W przypadku LLM powstaje napięcie: modele są użyteczne, bo potrafią wygenerować wiele poprawnych realizacji tej samej intencji, ale ta sama cecha utrudnia kontrolę procesu, porównywanie iteracji, automatyzację testów, a w konsekwencji audyt i odpowiedzialność za decyzje. Z perspektywy operacyjnej odpowiedź LLM jest artefaktem pracy: bywa logiem, raportem, wynikiem analizy, wkładem do repozytorium, materiałem dowodowym w sporze technicznym, a czasem elementem decyzji o realnych skutkach.

W praktyce produkcyjnej potrzebny jest rozdział na warstwę semantyczną i metrologiczną, ale nie jako zabieg stylistyczny, tylko jako separacja odpowiedzialności. Warstwa semantyczna dotyczy treści: co model twierdzi, czy ma to pokrycie w źródłach, czy występują halucynacje, czy uzasadnienie jest poprawne w danej domenie. Warstwa metrologiczna dotyczy procesu: ile w odpowiedzi jest faktów roboczych, ile kontekstu, ile ryzyk, ile pytań, czy nastąpiło domknięcie wnioskiem; jakie jest „zagęszczenie” kroku i czy struktura zmienia się między iteracjami. Metrologia w tym ujęciu nie ma być „mądrzejsza od świata”; ma być stała, policzalna i audytowalna nawet wtedy, gdy środowisko generacji zmienia się w czasie.

To rozdzielenie staje się szczególnie istotne, gdy system korzysta z usług zewnętrznych. Nawet jeśli dostawca oferuje mechanizmy poprawiające powtarzalność, takie jak `seed` czy identyfikator konfiguracji po stronie serwera (`system_fingerprint`), to praktyka pozostaje probabilistyczna i wrażliwa na zmiany.  Metrologia strukturalna odpowiada na ten stan rzeczy wprost: skoro nie gwarantujemy identycznych zdań, to gwarantujemy identyczny pomiar tej samej struktury, o ile struktura jest ta sama.

Teza dokumentu jest celowo prosta: jeżeli generacja jest probabilistyczna, to pomiar powinien być deterministyczny. Nie oznacza to, że cały system staje się deterministyczny; oznacza to, że stabilny sygnał kontrolny i regresyjny jest liczony z tego, co w pełni kontrolowalne: z formatu odpowiedzi oraz z jawnej klasyfikacji epistemicznej linii. Taki sygnał nadaje się do porównań między wątkami, do porównań między wersjami promptu, do testów regresji, do monitoringu jakości procesu, do późniejszego audytu — nawet jeśli sama treść pozostaje domenowo dyskutowalna.

W takim ujęciu metrologia strukturalna nie próbuje „sprawdzać prawdy”. Ona mierzy odpowiedź jako artefakt: rozkład ról epistemicznych, gęstość, udział pytań, udział ostrzeżeń, obecność domknięcia decyzją lub wnioskiem. Dzięki temu metryka jest stabilna względem stylu wypowiedzi, a także odporna na „ładne zdania”: w warstwie pomiarowej nie liczy się retoryka, tylko role linii. Zyskujemy więc coś, co w praktyce jest ważniejsze niż pozorna „mądrość” liczby: zyskujemy niezmienność reguły jej wyliczania.

W tym miejscu pojawia się konsekwencja metodologiczna, która będzie wracać w całym tekście. Jeżeli ta sama struktura daje ten sam wynik, to identyczny wynik nie jest dowodem identycznej semantyki ani identycznej prawdziwości; jest dowodem identycznej struktury procesu. To przesunięcie intuicji jest kluczowe, bo usuwa fałszywe oczekiwanie, że „metrika ma mówić, czy to prawda”. Metryka ma mówić, „co się stało w procesie”.

## ASCII Microcode jako DSL: tag determinuje klasę epistemiczną

ASCII Microcode jest traktowany jako domenowy język opisu odpowiedzi (DSL), w którym każda linia ma stałą strukturę: tag, identyfikator, a następnie tekst. Sens tego rozwiązania nie polega na „estetyce prostoty”, tylko na tym, że parser ma działać bez zgadywania: linia ma być obiektem formalnym, a nie „akapitowym stylem”. W konsekwencji, to nie model decyduje, jaką strukturę zrozumie odbiorca; strukturę wymusza protokół, a model jedynie wypełnia pola treścią.

Kluczowa własność epistemiczna jest następująca: klasa linii wynika z tagu, a nie z tonu lub treści. W materiale dowodowym (bloki ODP) tagi działają jak jawny metajęzyk ról: `==` oznacza fakt roboczy; `~~` oznacza kontekst; `!!` oznacza ryzyko lub ostrzeżenie; `??` oznacza pytanie; `>>` oznacza wniosek lub decyzję (domknięcie); `::` oznacza doprecyzowanie „przyklejone” do poprzedniej klasy i samo w sobie nie zmienia klasy epistemicznej. Jednocześnie dopuszcza się linie meta, które są poza ontologią mikrokodu i powinny zostać pominięte przez parser; to ważne, bo w przeciwnym razie nagłówki i ozdobniki stają się bocznym kanałem semantycznym i psują porównywalność.


## Znak jako interfejs: dlaczego „format” jest częścią sterowania

Tekst w LLM jest jednocześnie komunikatem i urządzeniem sterującym, bo jego postać wpływa na to, co da się z nim zrobić dalej: zparsować, zdiffować, przetestować regresyjnie, zarchiwizować, włączyć do pipeline’u. Jeżeli odpowiedź ma stać się artefaktem pracy (logiem, raportem, wkładem do repozytorium), to jej „literackość” jest ryzykiem operacyjnym: utrudnia automatyzację, wprowadza boczne kanały znaczenia (np. markdown, emoji, formatowanie), zaciera granice między faktem roboczym a komentarzem.

Dlatego fundamentem metrologii strukturalnej nie jest „rozumienie prawdy”, tylko kontrola formy. Zamiast próbować stabilizować model (co bywa niemożliwe w usługach sieciowych), stabilizuje się powierzchnię pomiaru: minimalny alfabet, minimalna składnia, jawne klasy epistemiczne linii. Tę powierzchnię da się utrzymać nawet wtedy, gdy treść semantyczna pływa.

## Znak w systemach cyfrowych: byt bitowo–symboliczno–semantyczny

Żeby to działało, trzeba uznać rzecz prostą: znak nie jest wyłącznie „literą”, tylko bytem o warstwach. Warstwa bitowa to konkretna reprezentacja kodowa (np. `01000001` jako kod `A` w ASCII) – to poziom, który widzi transmisja i parser. Warstwa symboliczna to figura graficzna widoczna dla człowieka (`A`, `?`, `~`, `>`), która umożliwia składnię i czytelność. Warstwa semantyczna to rola/znaczenie nadane w protokole (np. „ten tag oznacza fakt roboczy”), czyli to, co dopiero robi z tekstu sterowalny DSL, a nie luźną wypowiedź.

Ten trójwarstwowy opis jest ważny, bo pokazuje, dlaczego metrologia strukturalna nie może bazować na warstwie semantycznej „w sensie świata” (prawdziwość twierdzeń), tylko na semantyce protokołu (rola linii w artefakcie). To jest różnica między semantyką jako epistemologią a semantyką jako inżynierią interfejsu.

## Dlaczego ASCII: minimalny alfabet i odporność na degradację

ASCII to minimalny, stabilny alfabet do budowania DSL, bo jest przewidywalny w miejscach, gdzie formatowanie zwykle się psuje: w e-mailach, logach, terminalu, prostych edytorach, narzędziach diff. Technicznie ASCII obejmuje zakres `0–127` (7-bit), czyli 128 kodów, z czego część jest kontrolna, a część drukowalna. Ta surowa prostota jest zaletą: ogranicza powierzchnię błędów, zmniejsza liczbę niespodzianek związanych z normalizacją Unicode, ligaturami, znakami podobnymi wizualnie, kierunkowością pisma czy „sprytnym” formatowaniem.

W praktyce jednak pracuje się w świecie mieszanym, więc trzeba rozróżnić trzy kanały, które będą współistnieć: kanał ASCII jako nośnik minimalnych operatorów i składni; kanał Unicode jako warstwa komfortu zapisu (np. strzałki, symbole), ale pod kontrolą walidatora; kanał typograficzny (sup/sub, indeksy, ozdobniki), który jest najbardziej zdradliwy, bo bywa niszczony przez konwersję formatów. W metrologii strukturalnej kanał sterujący powinien być możliwie „głuchy” na typografię.

## ASCII Microcode jako DSL: tag wyznacza klasę epistemiczną

Mikrokod jest DSL-em, w którym linia ma stałą, parsowalną postać: `TAG SP ID SP TEKST`. Właściwość krytyczna nie dotyczy TEKSTU, tylko TAGU: klasa epistemiczna linii wynika wyłącznie z tagu, a nie z tonu, stylu, ani z tego, co „wygląda jak fakt”. W kanonie mikrokodu ta zasada jest wyrażona wprost przez definicję struktury linii i zamknięty zbiór tagów, które kodują role epistemiczne. ([GitHub][1])

W praktyce wygląda to tak, że tagi typu `==`, `~~`, `!!`, `??`, `>>` nie są dekoracją, tylko formalnym interfejsem. `==` przenosi fakt roboczy (w sensie artefaktu), `~~` wnosi kontekst, `!!` wnosi ryzyko/ostrzeżenie, `??` wnosi pytanie (brak danych, niejednoznaczność, potrzeba doprecyzowania), `>>` domyka decyzją/wnioskiem. Tag `::` jest doprecyzowaniem „przyklejonym” do poprzedniej klasy i nie zmienia epistemicznej roli linii – to sposób na utrzymanie rygoru bez mnożenia wyjątków. ([GitHub][1])

To podejście ma konsekwencję audytową: parser nie musi zgadywać, „czy to zdanie jest faktem”. On tylko sprawdza, czy linia ma poprawną składnię i dozwolony tag. Semantyka świata jest osobnym torem, możliwym do dołączenia później (retrieval, testy, recenzja), ale nie jest wymagana do samego pomiaru strukturalnego.

## Determinizm jako kontrakt: `[DET]` i prawo do `n/a`

Warstwa metrologiczna wchodzi dopiero po parsowaniu: najpierw powstaje formalna reprezentacja (ciąg linii), potem liczy się metryki. W tym miejscu pojawia się kontrakt deterministyczności: jeśli coś jest oznaczone jako deterministyczne, to musi być liczone deterministycznie albo jawnie oznaczone jako `n/a`. W kanonie jest to opisane jako zasada, a nie sugestia: `[DET]` ma znaczyć „zero zgadywania”. ([GitHub][1])

To rozwiązuje klasyczny problem „ładnych liczb”: liczby nie mogą istnieć wyłącznie po to, żeby wyglądało naukowo. W metrologii strukturalnej liczby są dopuszczalne tylko wtedy, gdy da się wskazać funkcję wejście→wyjście, która zawsze da ten sam wynik dla tej samej struktury mikrokodu.

## Zmienność treści kontra stałość struktury: sens dowodu ODP

W materiale dowodowym, który już rozbijaliśmy, kluczowe jest to, że dwa różne bloki ODP mogą dać identyczny wektor HMK-9D, jeżeli mają identyczny rozkład tagów w obrębie tego samego reżimu. To nie jest błąd: to dokładnie cecha metrologii strukturalnej. Ona mierzy artefakt jako układ ról (fakty robocze, kontekst, ryzyko, pytania, domknięcie), a nie „co autor miał na myśli” ani „czy świat jest prawdziwy”. W tym sensie metrologia staje się warstwą kontrolną nad generacją: stabilizuje sygnał regresyjny nawet wtedy, gdy semantyka odpowiedzi pozostaje probabilistyczna.

### Uwaga implementacyjna: neutralizacja składni Markdown

W praktyce repozytoryjnej tekst protokołu często żyje w plikach `.md`, a tam część sekwencji znaków ma znaczenie formatowania. Najbardziej kłopotliwe są podwójne tyldy, ponieważ w GitHub Flavored Markdown są operatorem skreślenia. Dlatego tokeny mikrokodu nie mogą „pływać” w narracji jako gołe znaki. Zasada redakcyjna jest prosta: tagi zawsze zapisuje się w kodzie inline albo w blokach kodu, a nie w zwykłym tekście, tak aby warstwa prezentacji nie dotykała warstwy sterującej.

W tym miejscu protokół jest już kompletny na poziomie fundamentu: jest alfabet, jest składnia, są klasy epistemiczne, jest kontrakt deterministyczności. Reszta to konsekwentne dopięcie mapowania do HMK-9D oraz deterministycznego scorera opartego o cechy struktury (w szczególności `tag_counts`), tak aby metryki były porównywalne między krokami Δ przy zachowaniu audytowalności i zero-guessing.

## Materiał dowodowy i teza „powtarzalności struktury”

Rdzeń propozycji można zobaczyć na materiale dowodowym w dwóch blokach ODP, w których część semantyczna różni się w detalach, ale część metrologiczna kończy się identycznym wektorem HMK-9D. W obu przypadkach blok ma tę samą „rzeźbę” epistemiczną: występują fakty robocze, kontekst, ostrzeżenie/ryzyko, pytania oraz domknięcie wnioskiem; różni się natomiast to, co jest wpisane w polu TEKST w obrębie pytań.

W samych dowodach jest wprost zapisane wyjaśnienie: wartości oznaczone jako `[DET]` pochodzą z deterministycznego fallbacku `SCORER_SPEC_LOCAL_DET` liczonego wyłącznie z rozkładu tagów (`tag_counts`) w bieżącym `[ODP_BEGIN]…[ODP_END]`. To jest kluczowe rozdzielenie: treść jest „miękka” i może się zmieniać wraz z kontekstem, a pomiar ma być „twardy” i zależeć od tego, co kontrolowalne, czyli od jawnie zadeklarowanych klas linii.

Jeżeli w obu blokach rozkład tagów jest identyczny, to metryka musi wyjść identyczna, nawet przy różnej treści. To nie jest uboczny efekt, tylko definicja działania warstwy metrologicznej: ma stabilizować proces, a nie „udawać”, że wie coś o prawdzie zdań.

## Rekonstrukcja wyniku HMK-9D z kanonu: liczby jako dowód deterministyczności

W kanonie `MICROCODE_ASCII_HMK9D_CANON.PROMPT` fallback `SCORER_SPEC_LOCAL_DET` jest zapisany jako procedura: najpierw liczone są liczności tagów, potem normalizowane przez `total`, następnie wyliczane są osie `AX.*`, potem mosty `LENS.*`, a na końcu metryki `MT.*`. Istotne jest tu to, że kanon celowo unika zapisu w rodzaju `n_~~`, tylko wprowadza bezpieczne nazwy liczników: `n_eq` dla `==`, `n_ctx` dla `~~`, `n_q` dla `??`, `n_risk` dla `!!`, `n_dec` dla `>>`.

Dla przypadku z dowodu (który daje wartości typu `AX.T = 0.75`, `AX.S = 0.33`, `AX.R = 0.11`, `AX.P = 0.44`, `AX.D = 0.17`) najprostsza, spójna z kanonem rekonstrukcja wygląda tak, że `total = 9`, a liczności wynoszą: `n_eq = 2`, `n_ctx = 1`, `n_q = 4`, `n_risk = 1`, `n_dec = 1`. Wtedy, zgodnie z definicjami fallbacku, dostaje się:

```text
total = 2 + 1 + 4 + 1 + 1 = 9

AX.S = (n_eq + n_ctx) / total = (2 + 1) / 9 = 0.333...
AX.D = (n_dec + 0.5*n_risk) / total = (1 + 0.5*1) / 9 = 1.5/9 = 0.166...
AX.E = (n_risk + 0.5*n_q) / total = (1 + 0.5*4) / 9 = 3/9 = 0.333...
AX.R = n_ctx / total = 1/9 = 0.111...
AX.A = n_ctx / total = 1/9 = 0.111...
AX.P = n_q / total = 4/9 = 0.444...
AX.M = (n_dec + n_eq) / total = (1 + 2) / 9 = 0.333...
AX.I = n_eq / total = 2/9 = 0.222...
AX.T = total / 12 = 9/12 = 0.75
```

Po zaokrągleniu do dwóch miejsc dziesiętnych wartości pokrywają się z tym, co widnieje w blokach ODP: `0.33`, `0.17`, `0.11`, `0.44`, `0.22`, `0.75`. Co ważne, w tym miejscu „dowód” nie polega na interpretacji treści, tylko na tym, że da się algebraicznie odtworzyć metrykę z samej struktury, a to znaczy, że liczby nie są narracją, tylko konsekwencją kontraktu.

Analogicznie da się sprawdzić mosty i metryki pomocnicze, bo kanon definiuje je jako proste funkcje `AX`. Przykładowo: `LENS.PP = 1 - AX.T = 0.25`, `LENS.CW = 1 - AX.E = 0.666…`, `LENS.WM = AX.R = 0.111…`, `MT.COH = (n_eq + n_dec)/total = (2+1)/9 = 0.333…`, `MT.INT = 1 - n_risk/total = 1 - 1/9 = 0.888…`, `MT.DEN = total/16 = 9/16 = 0.5625`. To dokładnie tłumaczy, dlaczego w dowodach pojawiają się pary w rodzaju `0.67` i `0.89`: to są te same ułamki po zaokrągleniu, a nie „intuicja modelu”.

## Kontrakt `[DET]` i sens „n/a”: liczby nie są ozdobą

W tej architekturze `[DET]` nie jest etykietą kosmetyczną, tylko semantyką proceduralną: oznacza, że dana wartość musi być wyliczona deterministycznie z materiału jawnie określonego przez specyfikację, albo — jeśli specyfikacja to dopuszcza — jawnie oznaczona jako `n/a`. Kanon precyzuje nawet motyw: fallback ma „usunąć potrzebę emisji `n/a` gdy brak telemetrii”, czyli w środowisku, w którym nie ma zewnętrznego scorera, wartości nie mają „znikać”, tylko mają powstać z tej minimalnej, strukturalnej podstawy.

W praktyce `[DET]` pełni rolę bezpiecznika przeciw halucynacji metryki. Jeżeli implementacja nie potrafi policzyć wartości zgodnie z `SCORER_SPEC_LOCAL_DET`, to poprawną reakcją nie jest „wymyślić liczbę”, tylko przyznać `n/a` (o ile tryb na to pozwala) albo odrzucić artefakt jako niespełniający reżimu. Ta różnica jest krytyczna w audycie: metryka ma być powtarzalna w czasie i pomiędzy wątkami, a więc musi być powiązana z konkretną wersją specyfikacji i z konkretnym materiałem wejściowym.

### Konwencja nazw liczników: tag w kodzie, licznik w alfabecie

Drugim źródłem artefaktów jest notacja typu `n_~~`, która miesza symbolikę protokołu z symboliką Markdown. W tekstach objaśniających lepiej rozdzielić znak i znaczenie: tag pozostaje literalnym tokenem (zawsze w kodzie), a liczniki przyjmują neutralne nazwy alfabetowe. Przykładowo zamiast `n_~~` stosuje się `n_ctx`, zamiast `n_==` — `n_eq`, zamiast `n_??` — `n_q`, zamiast `n_!!` — `n_risk`, zamiast `n_>>` — `n_dec`. Dopiero w jednym miejscu, jawnie i w kodzie, definiuje się mapowanie licznika na tag, co poprawia czytelność, stabilność diffów i eliminuje przypadkowe skreślenia.

```text
n_ctx := count(tag == `~~`)
AX.R  := n_ctx / N
```

Ta konwencja jest zgodna z kanonem, bo kanon właśnie tak nazywa liczniki (`n_ctx`, `n_eq`, `n_q`, `n_risk`, `n_dec`). Dodatkowo ma zaletę repozytoryjną: diff nie „gubi” znaczenia, a renderer Markdown nie deformuje treści. W samych blokach mikrokodu sprawa jest jeszcze prostsza: tam i tak obowiązuje reżim „danych”, więc blok powinien być trzymany w ogrodzeniu kodu (fenced code block) albo w formacie wyjściowym bez Markdown, zgodnie z polityką „bez ozdobników” w obrębie mikrokodu.

Snapshot jako jednostka obserwowalności: regresja, audyt i zapis zdarzeń

Jeżeli uznać, że krok Δ jest artefaktem produkcyjnym, to naturalną jednostką kontroli staje się snapshot: zapis wejścia (hash promptu i ewentualnych źródeł), zapis samego mikrokodu, wynik parsowania, wersja `scorer_spec`, policzone `tag_counts` oraz wynikowe `AX/LENS/MT`. Wtedy regresja przestaje być porównywaniem „czy model mówi podobnie”, a staje się porównywaniem „czy proces zachowuje tę samą strukturę wtedy, gdy powinien ją zachować, i czy zmienia ją wtedy, gdy zmiana jest intencjonalna”.

W praktyce taka jednostka świetnie podpina się pod obserwowalność w sensie inżynierii systemów: snapshot może być traktowany jako zdarzenie, które da się składować, indeksować, korelować i odtwarzać w czasie. W warstwie repozytoryjnej to jest zwykły plik tekstowy; w warstwie telemetrycznej to jest rekord, który da się wysłać do systemu zdarzeń, a potem pytać o dryf protokołu, o zmiany `MT.DEN` pomiędzy wydaniami, o nagłe zniknięcia domknięć `>>`, o wzrost udziału `??` w pewnych klasach promptów, o przesunięcia `AX.T` wynikające z innej „gęstości kroku”. W tym miejscu metrologia spełnia swoją obietnicę: nie mówi, co jest prawdą, ale mówi, czy proces jest stabilny, sterowalny i audytowalny w czasie.

## Warstwa abstrakcji: LLM jako obiekt sterowania, a odpowiedź jako sygnał pomiarowy

Najbezpieczniejszy sposób myślenia o LLM w produkcji nie zaczyna się od „inteligencji”, tylko od dynamiki układu. Model jest obiektem probabilistycznym, a więc takim, który w tych samych warunkach potrafi wygenerować różne realizacje tej samej intencji; do tego dochodzi warstwa usługowa, czyli wersje backendu, parametry routingu, wymiany wag, aktualizacje i zmiany infrastruktury. To nie jest wada „języka”, tylko cecha sposobu wytwarzania wyniku. W tym sensie LLM zachowuje się jak czarna skrzynka o kontrolowanym wejściu (prompt, kontekst, parametry dekodowania) i nie w pełni kontrolowanym wyjściu (tekst), a więc jak obiekt, który w praktyce wymaga instrumentacji, nie narracji.

ASCII Microcode + HMK-9D są właśnie taką instrumentacją. Mikrokod jest tu odpowiednikiem czujnika: nie mierzy „prawdy świata”, tylko stan i strukturę pracy w kroku Δ. Wektor HMK-9D oraz metryki MT.* są odpowiednikiem telemetrii: zagęszczenie, udział pytań, udział ostrzeżeń, obecność domknięcia, rozkład klas epistemicznych. Kiedy tę warstwę traktuje się serio, zaczyna działać intuicja z automatyki i obserwowalności: można robić regresję procesu, porównywać kroki, wykrywać dryf formatu, odróżniać „zmianę stylu” od „zmiany struktury”, a przede wszystkim budować audyt, który nie zależy od literackiego brzmienia zdań.

W tym ujęciu materiał dowodowy z dwoma blokami ODP jest nie tyle ciekawostką, co testem akceptacyjnym metody. Jeśli scorer jest deterministyczną funkcją `tag_counts`, to identyczna struktura ma dawać identyczny sygnał kontrolny, nawet przy różnej treści. To jest cel, nie przypadek, i dokładnie tak rozumie się metrologię strukturalną: jako stabilną warstwę kontrolną nad niedeterministyczną generacją.

## Deterministyczność operacyjna: kontrakt [DET], wersjonowanie i odporność na dryf

W kanonie protokołu deterministyczność nie jest życzeniem, tylko kontraktem. Znacznik `[DET]` nie jest „ładną naklejką”, tylko zobowiązaniem, że wartości AX/LENS/MT wynikają w sposób deterministyczny z danych wejściowych mikrokodu, a jeśli deterministyczność nie jest możliwa, system ma obowiązek jawnie zwrócić `n/a` zamiast „wymyślać liczby”. ([GitHub][1])

Żeby taki kontrakt miał sens w czasie, musi istnieć równie twarda polityka wersjonowania specyfikacji scorera. W praktyce oznacza to, że snapshot kroku Δ niesie nie tylko sam mikrokod i wynik, ale też identyfikator `SCORER_SPEC_*`, wersję kanonu, oraz minimalne metadane środowiska, bo w przeciwnym razie porównujemy wyniki policzone innymi regułami, a to jest regresja pozorna. Sam Microsoft w kontekście „reproducible output” podkreśla, że nawet przy ustawieniu seeda powtarzalność zależy od zgodności warunków, a do diagnostyki służy m.in. `system_fingerprint`, czyli znacznik wersji/konfiguracji infrastruktury serwującej. ([Microsoft Learn][2]) Ta obserwacja jest spójna z Twoją tezą: skoro warstwa generacji może się zmieniać z powodów niezależnych od promptu, to warstwa pomiarowa musi być jawna, wersjonowana i audytowalna.

W tym miejscu dobrze widać różnicę między „deterministycznością tekstu” a „deterministycznością pomiaru”. Tekst można stabilizować parametrami i seedem, ale nie da się obiecać, że cały ekosystem nigdy nie wprowadzi wariancji. Natomiast deterministyczna metrologia jest osiągalna w pełni, bo bazuje na tym, co kontrolujesz: na formacie, gramatyce, dozwolonych tagach, regułach parsowania i jawnej funkcji scorera.

## Relacja do structured outputs i constrained decoding: konkurencja pozorna, komplementarność praktyczna

Współczesne „structured outputs” rozwiązują inny problem niż HMK-9D. Tam celem jest gwarancja zgodności wyjścia ze schematem danych, najczęściej JSON Schema, co jest kluczowe dla pipeline’ów integracyjnych. OpenAI opisuje structured outputs jako mechanizm, który ma zapewniać, że model zwróci dane zgodne z zadanym schematem (a nie tylko „podobne do schematu”), i to jest realna przewaga, gdy odpowiedź ma być bezpośrednio konsumowana maszynowo. ([OpenAI Platform][3])

ASCII Microcode idzie inną drogą: zamiast przenosić całą semantykę do JSON, utrzymuje minimalny DSL, w którym człowiek i repozytorium nadal widzą tekst, diff, kontekst i domknięcie decyzją. W praktyce te podejścia się uzupełniają. Structured outputs stabilizują interfejs danych „do maszyny”, a mikrokod stabilizuje interfejs procesu „do audytu i regresji”. Najbardziej pragmatyczny wariant hybrydowy wygląda tak, że mikrokod jest formatem pierwotnym (źródłowym), liczonym deterministycznie do HMK-9D, a JSON jest formatem wtórnym (kompilatem) dla integracji, generowanym deterministycznie z mikrokodu, a nie bezpośrednio z modelu.

### Reżim publikacji: literalność przykładów i odporność na kopiowanie

Wszystkie przykłady mikrokodu, wzory scorera i fragmenty, które mają zostać później parsowane lub kopiowane do narzędzi, powinny być publikowane wyłącznie w formie literalnej, czyli jako fenced code block albo jako inline code. To nie jest kosmetyka: renderer Markdown potrafi zmienić to, co człowiek widzi, a kopiowanie z widoku renderowanego do surowego tekstu potrafi zgubić znaki lub przenieść je w innej postaci. Jeżeli celem jest audytowalność i deterministyczna metrologia, dokument musi gwarantować, że „to samo” oznacza „dokładnie te same znaki”, niezależnie od środowiska prezentacji.

Ponieważ metrologia strukturalna opiera się na deterministycznym parsowaniu powierzchni odpowiedzi, higiena publikacji staje się elementem protokołu. W szczególności tokeny klas epistemicznych (`==`, `~~`, `!!`, `??`, `>>`) nie powinny pojawiać się w narracji w postaci „gołych znaków”. Ich poprawną reprezentacją w tekście pracy jest zawsze zapis w kodzie, czyli w backtickach, albo w bloku kodu. Dzięki temu warstwa typograficzna nie zmienia znaczenia znaków i nie wprowadza bocznych kanałów formatowania.

W praktyce stosuje się trzy równoważne strategie. Pierwsza polega na konsekwentnym użyciu kodu inline, np. „tag `~~` oznacza kontekst”, „liczność `n_~~` jest liczona po stronie parsera”. Druga polega na umieszczaniu przykładów protokołu wyłącznie w blokach kodu (fenced code blocks), które gwarantują literalność znaków. Trzecia polega na escapingu tyld w tekście narracyjnym, tj. zapisie `\~\~` zamiast `~~`, gdy z jakiegoś powodu kod inline nie może być użyty; ta metoda jest jednak mniej odporna na błędy redakcyjne, więc w dokumentach audytowych preferuje się kod.

Zasada ma znaczenie nie tylko estetyczne. Jeżeli dokument jest kopiowany z widoku renderowanego (HTML) do surowego tekstu, renderer może „ukryć” fragmenty lub zmienić ich postać, a to bezpośrednio uderza w powtarzalność parsowania i w audytowalność. Dlatego protokół powinien narzucać, by wszelkie fragmenty mikrokodu, definicje zmiennych typu `n_~~` oraz formuły scorera były publikowane jako kod, a nie jako typografia.

## Wnioski: po co to wszystko, gdy i tak „można pytać model”

Połączenie ASCII Microcode i HMK-9D jest w istocie propozycją nowego rodzaju kontraktu operacyjnego dla LLM: model może pozostać miękki, a nawet kapryśny w warstwie języka, ale system nie rezygnuje z twardej kontroli procesu. Tag decyduje o klasie epistemicznej, nie retoryka; parser działa bez zgadywania; `[DET]` wymusza deterministyczny pomiar albo jawne `n/a`; a fallback scorer oparty o `tag_counts` zapewnia, że w środowisku bez zewnętrznych scorerów nadal istnieje stabilny sygnał regresyjny.

Materiał dowodowy z dwoma ODP pokazuje sedno: identyczny sygnał HMK-9D może pojawić się w różnych wątkach przy różnej treści, jeśli struktura jest identyczna, i to jest poprawne zachowanie metrologii strukturalnej. Tym samym kontrola jakości staje się dwutorowa. Tor pierwszy to kontrola procesu, czyli metrologia strukturalna; tor drugi to kontrola prawdy, czyli weryfikacja treści przez źródła, testy, reguły lub przegląd ekspercki. Rozdzielenie tych torów nie osłabia systemu – przeciwnie, usuwa konflikt interesów, w którym „ładniejsze zdanie” udaje „lepszy pomiar”.

## Bibliografia i materiały referencyjne

MICROCODE_ASCII_HMK9D_CANON.PROMPT, repozytorium `chunk-chunk` (źródło kanonu tagów, zasad parsowania, kontraktu `[DET]` i wymogów deterministyczności). ([GitHub][1])

OpenAI Docs, „Structured Outputs” (mechanizm wymuszania zgodności wyjścia ze schematem, istotny kontekst integracyjny dla pipeline’ów LLM). ([OpenAI Platform][3])

Microsoft Learn, „How to generate reproducible output with Azure OpenAI…” (praktyczne ograniczenia powtarzalności oraz rola `seed` i `system_fingerprint` w diagnostyce i kontroli warunków). ([Microsoft Learn][2])

Materiał dowodowy (bloki ODP): [https://chatgpt.com/share/693c7492-3e60-800e-9c4c-28f1efb55dc5](https://chatgpt.com/share/693c7492-3e60-800e-9c4c-28f1efb55dc5) oraz [https://chatgpt.com/share/693c5391-ac2c-800e-b9a1-5d4665559850](https://chatgpt.com/share/693c5391-ac2c-800e-b9a1-5d4665559850)

Materiały projektu (lokalne pliki w tym wątku / odpowiadające im writeups): `ascii-ontologiczny-microcode-ai_czesc1-fundament-znak-semantyka.md`, `ascii-microcode-ai_part2.md`, `ascii-microcode-ai_part3.md`, `AISec_ASCII_MC_9D_eksperyment_kontekstowy.md`, `70_observability.md`, `egdb.md`.

[1]: https://raw.githubusercontent.com/DonkeyJJLove/chunk-chunk/refs/heads/master/MICROCODE_ASCII_HMK9D_CANON.PROMPT "raw.githubusercontent.com"
[2]: https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/reproducible-output "How to generate reproducible output with Azure OpenAI in Microsoft Foundry Models - Azure OpenAI | Microsoft Learn"
[3]: https://platform.openai.com/docs/guides/structured-outputs "Structured model outputs | OpenAI API"

[15]: https://platform.openai.com/docs/guides/structured-outputs "Structured model outputs | OpenAI API"
[16]: https://github.github.com/gfm/ "GitHub Flavored Markdown Spec"
