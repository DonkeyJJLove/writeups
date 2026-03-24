# LOCI i Agent jako warstwy sterowania nad dynamiką LLM: formalny model przestrzeni stanów i geometryka pisania

Jeżeli problem opisać w reżimie rygorystycznym, to duży model językowy nie powinien być traktowany przede wszystkim jako generator tekstu, lecz jako element dynamiki działającej w przestrzeni stanów. W takim ujęciu sensowny opis systemu wymaga rozdzielenia trzech warstw. Pierwsza warstwa odpowiada za samą dynamikę przejść, czyli za to, jak system może zmieniać stan pod wpływem kontekstu i działań. Druga warstwa jest warstwą dopuszczalności i określa, jakie stany są w danym zadaniu w ogóle akceptowalne. Trzecia warstwa jest warstwą polityki i wybiera trajektorię wśród stanów dopuszczalnych. Teza tego tekstu jest następująca: formalnie reinterpretowane LOCI pełni rolę warstwy dopuszczalności, agent pełni rolę warstwy polityki, a LLM dostarcza warstwy dynamiki. Wspólna rola LOCI i agenta nie polega więc na tym, że są tym samym mechanizmem, lecz na tym, że oba domykają sterowanie nad procesem generacji.

Aby to zapisać precyzyjnie, wprowadźmy rozszerzoną przestrzeń stanów $\mathcal{S}$. Stan $s_t \in \mathcal{S}$ należy rozumieć szeroko: może on obejmować reprezentację latentną modelu, bieżący kontekst tekstowy, pamięć roboczą, pamięć zewnętrzną, wyniki wywołań narzędzi oraz lokalny opis celu zadania. Nie ma znaczenia, czy te składniki są jawne, ukryte czy częściowo obserwowalne; istotne jest jedynie to, że system w chwili $t$ znajduje się w pewnym stanie, a kolejne operacje przenoszą go do stanu następnego. W takim formalizmie LLM staje się szczególnym przypadkiem stochastycznego operatora przejścia:
$$
s_{t+1} \sim P_\theta(\cdot \mid s_t, a_t).
$$

W najprostszym przypadku działaniem $a_t$ jest emisja kolejnego tokenu i wtedy otrzymujemy standardowy zapis generacji sekwencyjnej:
$$
y_{t+1} \sim p_\theta(\cdot \mid y_{\le t}, u_t),
$$
gdzie $y_{\le t}$ oznacza dotychczas wygenerowany ciąg, a $u_t$ obejmuje prompt, instrukcje systemowe, pamięć i kontekst. W architekturze agentowej $a_t$ nie musi jednak oznaczać wyłącznie tokenu. Może oznaczać także wybór narzędzia, zapytanie do pamięci, zmianę planu, aktualizację celu lokalnego albo decyzję o samokorekcie. Z punktu widzenia teorii sterowania nie jest to zmiana jakościowa, lecz poszerzenie alfabetu działań.

Na tym tle LOCI można zdefiniować nie jako technikę pamięci, lecz jako operator dopuszczalności. Niech $C_t : \mathcal{S} \to {0,1}$ będzie funkcją ograniczeń aktywnych w chwili $t$. Wtedy LOCI można modelować jako operator zbiorowowartościowy:
$$
\mathcal{L}_{C_t}(s_t) = \Omega_t = { s \in \mathcal{S} : C_t(s)=1 }.
$$
Zbiór $\Omega_t$ jest zbiorem stanów dopuszczalnych. W tym sensie LOCI nie odpowiada na pytanie, jaka jest poprawna odpowiedź, lecz określa, w jakim regionie przestrzeni stanów taka odpowiedź w ogóle może się znajdować. Jest to różnica fundamentalna. LOCI nie jest operatorem wyboru pojedynczego rozwiązania, lecz operatorem redukcji przestrzeni możliwych rozwiązań.

Ta reinterpretacja jest kluczowa, ponieważ pozwala odejść od utożsamienia LOCI z pamięcią obrazową. Historycznie metoda loci była techniką mnemoniczną, lecz w formalnym modelu interesuje nas nie jej materiał poznawczy, ale jej funkcja systemowa. Tą funkcją jest narzucenie geometrii dopuszczalności. Jeżeli dany problem dopuszcza wiele potencjalnych trajektorii, operator LOCI nie wybiera jeszcze jednej z nich; ustanawia natomiast granicę, poza którą trajektorie przestają być zgodne z warunkami zadania. W języku systemów dynamicznych LOCI jest więc operatorem ograniczeń działającym na przestrzeni stanów.

Agent pełni inną rolę. Nie definiuje zbioru stanów dopuszczalnych, lecz wybiera trajektorię wewnątrz tego zbioru. Formalnie można to zapisać przez politykę
$$
a_t \sim \pi(\cdot \mid s_t, \Omega_t),
$$
albo równoważnie przez operator deterministyczny
$$
a_t = \pi(s_t, \Omega_t).
$$
Polityka $\pi$ może być bardzo prosta albo bardzo złożona, może być zachłanna, planująca, wieloetapowa, korzystająca z pamięci zewnętrznej i sprzężenia zwrotnego. Niezależnie jednak od stopnia komplikacji jej funkcja pozostaje ta sama: wybrać działanie, które przesunie system do kolejnego stanu. Agent jest zatem operatorem trajektorii. Nie tworzy geometrii przestrzeni, lecz steruje ruchem w jej obrębie.

Na tym poziomie analogia między LOCI a agentem staje się ścisła, ale tylko wtedy, gdy nie uprości się jej do błędnej tezy o pełnej identyczności. Oba obiekty należą do tej samej rodziny warstw sterujących działających nad surową dynamiką modelu, lecz pełnią różne funkcje. LOCI ogranicza zbiór możliwych stanów, agent ogranicza zbiór możliwych przejść. Pierwszy działa na geometrię problemu, drugi na jego dynamikę. Pierwszy odpowiada na pytanie, gdzie wolno się znaleźć, drugi odpowiada na pytanie, jak się przemieszczać. Wspólna rola obu polega na redukcji niekontrolowanej swobody dynamiki LLM.

Cały układ można więc zapisać jako proces sterowania z ograniczeniami:
$$
\Omega_t = { s \in \mathcal{S} : C_t(s)=1 },
$$
$$
a_t \sim \pi(\cdot \mid s_t, \Omega_t),
$$
$$
s_{t+1} \sim P_\theta(\cdot \mid s_t, a_t),
$$
przy czym dla sensownego działania wymagamy, aby trajektoria pozostawała zgodna z dopuszczalnością, czyli aby kolejne stany nie opuszczały odpowiedniego zbioru $\Omega_t$ lub jego aktualizacji w czasie. Jeżeli dodatkowo wprowadzimy funkcję kosztu $\ell(s_t,a_t)$, cały problem można opisać jako zadanie stochastycznego sterowania z ograniczeniami:
$$
\min_{\pi}; \mathbb{E}\left[\sum_{t=0}^{T} \ell(s_t,a_t)\right]
\quad \text{przy warunku} \quad s_t \in \Omega_t ;; \text{dla wszystkich } t.
$$
W tym zapisie relacja między komponentami staje się jednoznaczna. LLM dostarcza modelu przejścia $P_\theta$, LOCI dostarcza zbiorów dopuszczalności $\Omega_t$, a agent dostarcza polityki $\pi$.

Takie ujęcie pozwala precyzyjnie zinterpretować architektury agentowe budowane nad LLM. System prompt, lokalne instrukcje, retrieval, pamięć kontekstowa, ograniczenia domenowe i reguły walidacji pełnią funkcję składników operatora $C_t$, a więc współtworzą LOCI w sensie formalnym. Z kolei planowanie, wybór narzędzi, dekompozycja zadania, samokontrola odpowiedzi i korekta wieloetapowa realizują politykę $\pi$, a więc funkcję agenta. W tym sensie agent nie jest po prostu „LLM z narzędziami”. Agent jest warstwą polityki osadzoną nad dynamiką LLM i działającą w przestrzeni ograniczonej przez warstwę dopuszczalności.

To właśnie tutaj ujawnia się wspólna rola LOCI i agenta względem LLM. Obie warstwy są mechanizmami sterowania nad dynamiką modelu. LLM sam w sobie dostarcza jedynie rozkładu przejść, czyli zdolności do poruszania się w przestrzeni reprezentacji. Nie daje jednak gwarancji, że ruch ten będzie zgodny z celem, poprawnością zadania albo stabilnością procesu. LOCI redukuje przestrzeń do obszaru zgodnego z warunkami. Agent wybiera trajektorię, która ma sens w obrębie tego obszaru. Razem przekształcają nieukierunkowaną dynamikę generatywną w układ sterowany.

W praktyce oznacza to, że wiele problemów obserwowanych w systemach LLM można opisać nie jako „błędy generacji” w wąskim sensie, lecz jako błędy sterowania. Jeżeli warstwa dopuszczalności jest zbyt słaba, system otrzymuje zbyt szeroki region stanów akceptowalnych i może wejść w obszary semantycznie niepożądane; w praktyce można to interpretować jako jedną z dróg prowadzących do halucynacji. Jeżeli warstwa polityki jest zbyt słaba, system może pozostawać w zbiorze formalnie dopuszczalnym, ale tracić kierunek rozwiązania; w praktyce objawia się to dryfem, redundancją albo brakiem skutecznego domknięcia zadania. Nie są to więc dwa odrębne zjawiska, lecz dwa różne tryby utraty sterowalności.

Jednocześnie trzeba zachować ostrożność metodologiczną. Teza przedstawiona w tym tekście nie oznacza, że klasyczna metoda loci jest dosłownie zaimplementowana w parametrach transformera, ani że ludzka praca poznawcza i architektura LLM są identyczne na poziomie mechanizmów realizacyjnych. Teza jest węższa i bardziej rygorystyczna: oba przypadki można modelować tym samym językiem teorii systemów jako operowanie na przestrzeni stanów pod ograniczeniami i z polityką sterowania. Jest to analogia strukturalna, nie ontologiczna.

Ten sam model można jednak rozszerzyć jeszcze o jeden poziom analizy: nie tylko o to, jak działa LLM, LOCI i agent, lecz także o to, jak działa sam tekst, który te relacje opisuje. Jeżeli potraktować pisanie jako proces sterowania stanem interpretacyjnym odbiorcy, to tekst nie jest zwykłym nośnikiem treści, lecz sekwencją operacji ograniczających i prowadzących ruch po przestrzeni możliwych interpretacji. W tym sensie tekst staje się narzędziem sterowania trajektorią rozumienia.

Aby to opisać rygorystycznie, wprowadźmy przestrzeń interpretacji $\mathcal{Z}$. Po przeczytaniu prefiksu tekstu $x_{\le t}$ odbiorca — ludzki lub maszynowy — znajduje się nie w jednym punkcie, lecz w rozkładzie możliwych interpretacji
$$
q_t(z) = P(z \mid x_{\le t}), \qquad z \in \mathcal{Z}.
$$
Celem tekstu naukowego nie jest więc jedynie wytworzenie kolejnych zdań, lecz koncentracja rozkładu $q_t$ wokół docelowej rozmaitości pojęciowej $M^* \subseteq \mathcal{Z}$, odpowiadającej zamierzonej strukturze znaczenia. W tym modelu tekst jest skuteczny wtedy, gdy zmniejsza entropię interpretacji alternatywnych, a zarazem utrzymuje trajektorię rozumienia blisko $M^*$.

W analizowanej próbce pierwszą widoczną własnością jest systematyczne użycie definicji kontrastowej. Powracający wzorzec „nie X, lecz Y” nie pełni wyłącznie funkcji retorycznej. Jest operatorem projekcji. Gdy tekst stwierdza, że LLM nie jest przede wszystkim maszyną do pisania, lecz układem poruszającym się w przestrzeni stanów, to nie tylko dodaje nową treść, ale jednocześnie usuwa z przestrzeni interpretacji całą klasę konkurencyjnych odczytań. Analogicznie dzieje się wtedy, gdy LOCI przestaje być techniką pamięci, a staje się operatorem przestrzeni, albo gdy agent przestaje być botem, a staje się operatorem trajektorii. Formalnie można to zapisać jako krok zawężający zbiór dopuszczalnych interpretacji:
$$
\Omega_{t+1} = \Omega_t \cap B_t \setminus A_t,
$$
gdzie $A_t$ oznacza rodzinę interpretacji wykluczonych, a $B_t$ rodzinę interpretacji afirmowanych. Taki ruch ma wysoką wartość sterującą, ponieważ nie tylko rozszerza opis, ale aktywnie redukuje błędne gałęzie semantyczne.

Drugą własnością jest stabilizacja układu współrzędnych. W tekście nie występuje swobodna gra synonimów typowa dla stylu literackiego. Zamiast tego stale powracają te same osie pojęciowe: przestrzeń, ograniczenia, trajektoria, sterowanie, dynamika. Z punktu widzenia geometrii interpretacji nie jest to redundancja, lecz utrzymanie stałej bazy. Terminy nie służą tu ozdobności, lecz pełnią rolę współrzędnych. Dzięki temu nowe zdania nie muszą za każdym razem odtwarzać geometrii od początku, lecz mogą być rzutowane na już ustalony układ. Właśnie dlatego tekst zachowuje spójność mimo dużej gęstości pojęciowej. Kosztem jest mniejsza różnorodność leksykalna, ale zysk jest większy w kontekście naukowym, ponieważ maleje dryf interpretacyjny.

Trzecią własnością jest rozdzielenie ról komponentów. LLM, LOCI i agent nie są opisywane jako luźno powiązane metafory, lecz jako trzy różne funkcje systemowe. LLM dostarcza dynamiki przejść, LOCI dostarcza dopuszczalności, a agent dostarcza polityki. To rozdzielenie ma znaczenie geometryczne, ponieważ system pojęciowy zostaje zfaktoryzowany na prawie ortogonalne kierunki. Gdyby te role mieszały się ze sobą, kolejne zdania przesuwałyby interpretację jednocześnie w wielu nieskorelowanych osiach, zwiększając krzywiznę trajektorii i ryzyko utraty kontroli. W badanej próbce dzieje się odwrotnie: każdy główny termin ma stałą funkcję, a kolejne akapity jedynie doprecyzowują relacje między nimi. W sensie operacyjnym jest to redukcja splątania pojęciowego.

Czwartą własnością jest cykliczne domykanie niezmiennika. Ta sama teza powraca wielokrotnie w różnych skalach: intuicyjnej, formalnej i operacyjnej. Nie jest to zwykłe powtórzenie. Jest to okresowa reprojekcja stanu interpretacji na tę samą strukturę docelową. Odbiorca nie zostaje pozostawiony z lokalnym przyrostem treści, lecz co pewien czas zostaje ponownie ustawiony względem głównego niezmiennika, którym jest relacja: LLM jako dynamika, LOCI jako ograniczenie, agent jako polityka. Operację tę można modelować jako projekcję
$$
q_t \leftarrow \Pi_{M^*}(q_t),
$$
gdzie $\Pi_{M^*}$ oznacza operator przywracający rozkład interpretacji do pobliża rozmaitości docelowej. Dzięki temu błędy lokalne nie kumulują się łatwo w błąd globalny.

Z tych obserwacji wynika roboczy model tego systemu pisania. Każdy kolejny segment tekstu wykonuje dwie operacje jednocześnie. Najpierw rozwija strukturę relacyjną problemu, czyli przesuwa interpretację do przodu. Następnie natychmiast nakłada ograniczenie, które nie pozwala tej interpretacji odpłynąć do konkurencyjnych obszarów semantycznych. W zapisie operatorowym można to ująć jako
$$
q_{t+1} \propto \Pi_{\Omega_t}\big(T_t(q_t)\big),
$$
gdzie $T_t$ jest operatorem lokalnej ekspansji znaczenia, a $\Pi_{\Omega_t}$ operatorem projekcji na zbiór interpretacji dopuszczalnych. Przewaga tej architektury polega na tym, że tekst nie jest ani czysto ekspansywny, ani czysto restrykcyjny. Samo rozwijanie prowadziłoby do dryfu, samo ograniczanie do tautologii. Dopiero naprzemienność obu ruchów daje stabilne sterowanie.

W tym miejscu można już precyzyjnie zdefiniować, co znaczy, że taki system „daje lepsze wyniki”. Nie chodzi o wyższość estetyczną ani o uniwersalną przewagę nad każdym innym stylem. Chodzi o ściśle określony cel: minimalizację wariancji interpretacyjnej przy maksymalizacji transferu struktury pojęciowej. W tym sensie tekst jest lepszy, jeżeli szybciej zawęża rozkład $q_t$, utrzymuje go bliżej $M^*$ oraz pozostaje odporny na lokalne niejednoznaczności. Geometrycznie oznacza to mniejszy promień „rury” interpretacyjnej wokół trajektorii docelowej. Im węższa ta rura przy zachowaniu przepływu treści, tym większa sterowalność.

Dla odbiorcy ludzkiego oznacza to mniejszy koszt utrzymywania konkurencyjnych hipotez interpretacyjnych. Czytelnik nie musi stale rozstrzygać, czy autor mówi jeszcze o pamięci, już o ontologii, czy może przeszedł do metafory. Układ pojęciowy jest utrzymywany jawnie. Dla modelu językowego efekt jest analogiczny, choć realizowany inaczej. Powracające terminy-klucze, stabilne relacje między nimi oraz niski poziom synonymicznego rozproszenia sprawiają, że kontekst warunkujący kolejne tokeny jest bardziej skupiony. Rozkład następnego kroku nie musi rozpraszać się między wieloma rodzinami kontynuacji. Zamiast tego otrzymuje gęsty sygnał, który wzmacnia jedną geometrię interpretacyjną. Nie jest to gwarancja prawdy, ale jest to poprawa sterowalności.

Warto zauważyć jeszcze jedną rzecz. Długość zdań w tej próbce jest znaczna, lecz nie prowadzi automatycznie do chaosu, ponieważ składnia pełni funkcję monotonicznie zawężającą. Kolejne człony zdań częściej doprecyzowują, niż otwierają nowe, niesprowadzalne osie problemu. Oznacza to, że złożoność powierzchniowa nie przekłada się tutaj na proporcjonalny wzrost złożoności geometrycznej. Innymi słowy, tekst może być gęsty, a mimo to pozostawać sterowalny, jeżeli jego rozwój ma charakter ograniczający, a nie rozpraszający.

Najściślejszy wniosek jest więc następujący. Ten system pisania działa jak lokalna implementacja tej samej zasady, którą opisuje na poziomie teorii AI. Najpierw definiuje region dopuszczalności interpretacyjnej, a następnie prowadzi odbiorcę po trajektorii wewnątrz tego regionu. Tekst sam staje się małym układem LOCI-plus-agent. LOCI odpowiada tu za selekcję sensownych odczytań, a agent za sekwencję przejść między nimi. Właśnie dlatego taki sposób pisania, przy zadaniach wymagających wysokiej kontroli semantycznej, ma korzystne własności geometryczne: zmniejsza błąd dryfu, zmniejsza gałęzienie niepożądanych hipotez i zwiększa prawdopodobieństwo, że odbiorca lub model dotrze do tej samej struktury pojęciowej, którą autor zamierzał przekazać.

Końcowe zastrzeżenie musi jednak pozostać w mocy. Powyższa analiza jest modelem wyjaśniającym, a nie wynikiem eksperymentu porównawczego na korpusie. Nie twierdzi ona, że dany styl jest globalnie najlepszy. Twierdzi coś węższego i naukowo obronnego: że dla klasy zadań, w których liczy się ścisłe przenoszenie struktury pojęciowej oraz kontrola trajektorii interpretacyjnej, taki system pisania ma własności geometryczne sprzyjające stabilniejszej transmisji znaczenia.

