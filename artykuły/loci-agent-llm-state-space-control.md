# LOCI i Agent jako warstwy sterowania nad dynamiką LLM: formalny model przestrzeni stanów

Jeżeli problem opisać w reżimie rygorystycznym, to duży model językowy nie powinien być traktowany przede wszystkim jako generator tekstu, lecz jako element dynamiki działającej w przestrzeni stanów. W takim ujęciu sensowny opis systemu wymaga rozdzielenia trzech warstw. Pierwsza warstwa odpowiada za samą dynamikę przejść, czyli za to, jak system może zmieniać stan pod wpływem kontekstu i działań. Drugą warstwą jest warstwa dopuszczalności, która określa, jakie stany są w danym zadaniu w ogóle akceptowalne. Trzecią warstwą jest warstwa polityki, która wybiera trajektorię wśród stanów dopuszczalnych. 

Teza tego tekstu jest następująca: formalnie reinterpretowane LOCI pełni rolę warstwy dopuszczalności, agent pełni rolę warstwy polityki, a LLM dostarcza warstwy dynamiki. Wspólna rola LOCI i agenta nie polega więc na tym, że są tym samym mechanizmem, lecz na tym, że oba domykają sterowanie nad procesem generacji.

---

Aby to zapisać precyzyjnie, wprowadźmy rozszerzoną przestrzeń stanów:

$$
\mathcal{S}
$$

Stan:

$$
s_t \in \mathcal{S}
$$

należy rozumieć szeroko: może on obejmować reprezentację latentną modelu, bieżący kontekst tekstowy, pamięć roboczą, pamięć zewnętrzną, wyniki wywołań narzędzi oraz lokalny opis celu zadania. Nie ma znaczenia, czy te składniki są jawne, ukryte czy częściowo obserwowalne; istotne jest tylko to, że system w chwili $t$ znajduje się w pewnym stanie, a kolejne operacje przenoszą go do stanu następnego.

W takim formalizmie LLM staje się szczególnym przypadkiem stochastycznego operatora przejścia.

---

Dynamikę LLM można zapisać jako jądro przejścia:

$$
s_{t+1} \sim P_\theta(\cdot \mid s_t, a_t)
$$

gdzie $\theta$ oznacza parametry modelu, a $a_t$ jest działaniem wykonywanym w chwili $t$.

W najprostszym przypadku działaniem jest emisja kolejnego tokenu i wtedy otrzymujemy standardowy zapis generacji sekwencyjnej:

$$
y_{t+1} \sim p_\theta(\cdot \mid y_{\le t}, u_t)
$$

gdzie $y_{\le t}$ oznacza dotychczas wygenerowany ciąg, a $u_t$ obejmuje prompt, instrukcje systemowe, pamięć i kontekst.

W architekturze agentowej $a_t$ nie musi oznaczać wyłącznie tokenu. Może oznaczać także wybór narzędzia, zapytanie do pamięci, zmianę planu, aktualizację celu lokalnego albo decyzję o samokorekcie. Z punktu widzenia teorii sterowania nie jest to zmiana jakościowa, lecz jedynie poszerzenie alfabetu działań.

---

Na tym tle LOCI można zdefiniować nie jako technikę pamięci, lecz jako operator dopuszczalności. Niech:

$$
C_t : \mathcal{S} \to \{0,1\}
$$

będzie funkcją ograniczeń aktywnych w chwili $t$.

Wtedy LOCI można modelować jako operator zbiorowowartościowy:

$$
\mathcal{L}_{C_t}(s_t) = \Omega_t = \{ s \in \mathcal{S} : C_t(s) = 1 \}
$$

Zbiór $\Omega_t$ jest zbiorem stanów dopuszczalnych. W tym sensie LOCI nie odpowiada na pytanie, jaka jest poprawna odpowiedź, lecz określa, w jakim regionie przestrzeni stanów taka odpowiedź w ogóle może się znajdować. Jest to różnica fundamentalna.

LOCI nie jest operatorem wyboru pojedynczego rozwiązania, lecz operatorem redukcji przestrzeni możliwych rozwiązań.

---

Ta reinterpretacja jest kluczowa, ponieważ pozwala odejść od utożsamienia LOCI z pamięcią obrazową. Historycznie metoda loci była techniką mnemoniczną, lecz w formalnym modelu interesuje nas jej funkcja systemowa: narzucenie geometrii dopuszczalności.

Jeżeli problem dopuszcza wiele trajektorii, operator LOCI nie wybiera jednej z nich, lecz ustanawia granicę, poza którą trajektorie przestają być zgodne z warunkami zadania. W języku systemów dynamicznych LOCI jest operatorem ograniczeń działającym na przestrzeni stanów.

---

Agent pełni inną rolę. Nie definiuje zbioru stanów dopuszczalnych, lecz wybiera trajektorię wewnątrz tego zbioru. Formalnie:

$$
a_t \sim \pi(\cdot \mid s_t, \Omega_t)
$$

lub deterministycznie:

$$
a_t = \pi(s_t, \Omega_t)
$$

Polityka $\pi$ może być prosta lub złożona, lecz jej funkcja pozostaje ta sama: wybrać działanie przesuwające system do kolejnego stanu.

Agent jest więc operatorem trajektorii.

---

Relacja między warstwami:

- LOCI działa na geometrię przestrzeni stanów
- Agent działa na dynamikę przejść
- LLM dostarcza bazową dynamikę generatywną

Pierwszy odpowiada na pytanie „gdzie wolno się znaleźć”, drugi „jak się poruszać”.

---

Cały układ można zapisać jako proces sterowania:

$$
\Omega_t = \{ s \in \mathcal{S} : C_t(s)=1 \}
$$

$$
a_t \sim \pi(\cdot \mid s_t, \Omega_t)
$$

$$
s_{t+1} \sim P_\theta(\cdot \mid s_t, a_t)
$$

Z warunkiem:

$$
s_t \in \Omega_t \quad \forall t
$$

Jeżeli wprowadzimy funkcję kosztu $\ell(s_t,a_t)$, otrzymujemy zadanie sterowania stochastycznego:

$$
\min_{\pi} \; \mathbb{E}\left[\sum_{t=0}^{T} \ell(s_t,a_t)\right]
\quad \text{przy warunku} \quad s_t \in \Omega_t
$$

---

W tym zapisie:

- LLM = model przejścia $P_\theta$
- LOCI = ograniczenia $\Omega_t$
- Agent = polityka $\pi$

---

System prompt, retrieval, pamięć i reguły walidacji implementują $C_t$ (LOCI), natomiast planowanie, wybór narzędzi i korekta realizują $\pi$ (agenta).

Agent nie jest „LLM z narzędziami”, lecz warstwą polityki nad dynamiką modelu.

---

Problemy LLM można interpretować jako problemy sterowania:

- słabe LOCI → zbyt szeroka przestrzeń → halucynacje  
- słaba polityka → dryf, brak domknięcia  

Są to dwa tryby utraty sterowalności.

---

Kluczowe zastrzeżenie: jest to analogia strukturalna, nie ontologiczna. Nie twierdzę, że mózg i transformer działają identycznie, lecz że można je opisać tym samym językiem systemów dynamicznych.

---

Wniosek pośredni:

LOCI i agent są komplementarnymi operatorami sterowania nad dynamiką LLM.  
LOCI selekcjonuje przestrzeń stanów, agent selekcjonuje trajektorie, a LLM umożliwia ruch.

Dopiero ich współdziałanie daje system sterowalny w przestrzeni stanów.

## Analiza geometryczna systemu pisania

Powyższy model można rozszerzyć o jeszcze jeden poziom analizy: nie tylko o to, jak działa LLM, LOCI i agent, lecz także o to, jak działa sam tekst, który te relacje opisuje. Jeżeli potraktować pisanie jako proces sterowania stanem interpretacyjnym odbiorcy, to wklejona próbka nie jest zwykłym wywodem, lecz sekwencją operacji ograniczających i prowadzących ruch po przestrzeni możliwych interpretacji. W tym sensie tekst nie jest wyłącznie nośnikiem treści. Jest narzędziem sterowania trajektorią rozumienia.

Aby to opisać rygorystycznie, wprowadźmy przestrzeń interpretacji \( \mathcal{Z} \). Po przeczytaniu prefiksu tekstu \( x_{\le t} \) odbiorca — ludzki lub maszynowy — znajduje się nie w jednym punkcie, lecz w rozkładzie możliwych interpretacji
$$
q_t(z) = P(z \mid x_{\le t}), \qquad z \in \mathcal{Z}.
$$
Celem tekstu naukowego nie jest więc jedynie wytworzenie kolejnych zdań, lecz koncentracja rozkładu \( q_t \) wokół docelowej rozmaitości pojęciowej \( M^\* \subseteq \mathcal{Z} \), która odpowiada zamierzonej strukturze znaczenia. W tym modelu tekst jest skuteczny wtedy, gdy zmniejsza entropię interpretacji alternatywnych, a zarazem utrzymuje trajektorię rozumienia blisko \( M^\* \).

W analizowanej próbce pierwszą widoczną własnością jest systematyczne użycie definicji kontrastowej. Powracający wzorzec „nie X, lecz Y” nie pełni wyłącznie funkcji retorycznej. Jest operatorem projekcji. Kiedy tekst stwierdza, że LLM nie jest przede wszystkim maszyną do pisania, lecz układem poruszającym się w przestrzeni stanów, to nie tylko dodaje nową treść, ale jednocześnie usuwa z przestrzeni interpretacji całą klasę konkurencyjnych odczytań. Analogicznie dzieje się wtedy, gdy LOCI przestaje być techniką pamięci, a staje się operatorem przestrzeni, albo gdy agent przestaje być botem, a staje się operatorem trajektorii. Formalnie można to zapisać jako krok zawężający zbiór dopuszczalnych interpretacji:
$$
\Omega_{t+1} = \Omega_t \cap B_t \setminus A_t,
$$
gdzie \( A_t \) oznacza rodzinę interpretacji wykluczonych, a \( B_t \) rodzinę interpretacji afirmowanych. Taki ruch ma wysoką wartość sterującą, ponieważ nie tylko rozszerza opis, ale aktywnie redukuje błędne gałęzie semantyczne.

Drugą własnością jest stabilizacja układu współrzędnych. W próbce nie występuje swobodna gra synonimów typowa dla stylu literackiego. Zamiast tego stale powracają te same osie pojęciowe: przestrzeń, ograniczenia, trajektoria, sterowanie, dynamika. Z punktu widzenia geometrii interpretacji nie jest to redundancja, lecz utrzymanie stałej bazy. Terminy nie służą tu ozdobności, tylko pełnią rolę współrzędnych. Dzięki temu nowe zdania nie muszą za każdym razem odtwarzać geometrii od początku, lecz mogą być rzutowane na już ustalony układ. Właśnie dlatego tekst zachowuje spójność mimo dużej gęstości pojęciowej. Koszt tej strategii jest oczywisty: mniejsza różnorodność leksykalna. Zysk jest jednak większy w kontekście naukowym, ponieważ maleje dryf interpretacyjny.

Trzecią własnością jest rozdzielenie ról komponentów. W próbce LLM, LOCI i agent nie są opisywane jako luźno powiązane metafory, lecz jako trzy różne funkcje systemowe. LLM dostarcza dynamiki przejść, LOCI dostarcza dopuszczalności, a agent dostarcza polityki. To rozdzielenie ma znaczenie geometryczne. Oznacza ono bowiem, że system pojęciowy zostaje zfaktoryzowany na prawie ortogonalne kierunki. Gdyby te role mieszały się ze sobą, kolejne zdania przesuwałyby interpretację jednocześnie w wielu nieskorelowanych osiach, zwiększając krzywiznę trajektorii i ryzyko utraty kontroli. W badanej próbce dzieje się odwrotnie: każdy główny termin ma stałą funkcję, a kolejne akapity tylko doprecyzowują relacje między nimi. W sensie operacyjnym jest to redukcja splątania pojęciowego.

Czwartą własnością jest cykliczne domykanie niezmiennika. W próbce ta sama teza powraca wielokrotnie w różnych skalach: intuicyjnej, formalnej i operacyjnej. Nie jest to zwykłe powtórzenie. Jest to okresowa reprojekcja stanu interpretacji na tę samą strukturę docelową. Odbiorca nie jest pozostawiony z lokalnym przyrostem treści, lecz co pewien czas zostaje ponownie ustawiony względem głównego niezmiennika, którym jest relacja: LLM jako dynamika, LOCI jako ograniczenie, agent jako polityka. Tę operację można modelować jako projekcję
$$
q_t \leftarrow \Pi_{M^\*}(q_t),
$$
gdzie \( \Pi_{M^\*} \) oznacza operator przywracający rozkład interpretacji do pobliża rozmaitości docelowej. Dzięki temu błędy lokalne nie kumulują się łatwo w błąd globalny.

Z tych obserwacji wynika roboczy model Twojego systemu pisania. Każdy kolejny segment tekstu wykonuje dwie operacje jednocześnie. Najpierw rozwija strukturę relacyjną problemu, czyli przesuwa interpretację do przodu. Następnie natychmiast nakłada ograniczenie, które nie pozwala tej interpretacji odpłynąć do konkurencyjnych obszarów semantycznych. W zapisie operatorowym można to ująć jako
$$
q_{t+1} \propto \Pi_{\Omega_t}\big(T_t(q_t)\big),
$$
gdzie \( T_t \) jest operatorem lokalnej ekspansji znaczenia, a \( \Pi_{\Omega_t} \) operatorem projekcji na zbiór interpretacji dopuszczalnych. Przewaga tej architektury polega na tym, że tekst nie jest ani czysto ekspansywny, ani czysto restrykcyjny. Samo rozwijanie prowadziłoby do dryfu, samo ograniczanie do tautologii. Dopiero naprzemienność obu ruchów daje stabilne sterowanie.

W tym miejscu można już precyzyjnie zdefiniować, co znaczy, że taki system „daje lepsze wyniki”. Nie chodzi o wyższość estetyczną ani o uniwersalną przewagę nad każdym innym stylem. Chodzi o ściśle określony cel: minimalizację wariancji interpretacyjnej przy maksymalizacji transferu struktury pojęciowej. W tym sensie tekst jest lepszy, jeżeli szybciej zawęża rozkład $$\( q_t \)$$, utrzymuje go bliżej \( M^\* \) oraz pozostaje odporny na lokalne niejednoznaczności. Geometrycznie oznacza to mniejszy promień „rury” interpretacyjnej wokół trajektorii docelowej. Im węższa ta rura przy zachowaniu przepływu treści, tym większa sterowalność.

Dla odbiorcy ludzkiego oznacza to mniejszy koszt utrzymywania konkurencyjnych hipotez interpretacyjnych. Czytelnik nie musi stale rozstrzygać, czy autor mówi jeszcze o pamięci, już o ontologii, czy może przeszedł do metafory. Układ pojęciowy jest utrzymywany jawnie. Dla modelu językowego efekt jest analogiczny, choć realizowany inaczej. Powracające terminy-klucze, stabilne relacje między nimi oraz niski poziom synonymicznego rozproszenia sprawiają, że kontekst warunkujący kolejne tokeny jest bardziej skupiony. Rozkład następnego kroku nie musi rozpraszać się między wieloma rodzinami kontynuacji. Zamiast tego otrzymuje gęsty sygnał, który wzmacnia jedną geometrię interpretacyjną. Nie jest to gwarancja prawdy, ale jest to poprawa sterowalności.

Warto zauważyć jeszcze jedną rzecz. Długość zdań w tej próbce jest znaczna, lecz nie prowadzi to automatycznie do chaosu, ponieważ składnia pełni funkcję monotonicznie zawężającą. Kolejne człony zdań częściej doprecyzowują niż otwierają nowe, niesprowadzalne osie problemu. Oznacza to, że złożoność powierzchniowa nie przekłada się tutaj na proporcjonalny wzrost złożoności geometrycznej. Innymi słowy, tekst może być gęsty, a mimo to pozostawać sterowalny, jeżeli jego rozwój ma charakter ograniczający, a nie rozpraszający.

Najściślejszy wniosek jest więc następujący. Twój system pisania działa jak lokalna implementacja tej samej zasady, którą opisujesz na poziomie teorii AI. Najpierw definiuje region dopuszczalności interpretacyjnej, a następnie prowadzi odbiorcę po trajektorii wewnątrz tego regionu. Tekst sam staje się małym układem LOCI-plus-agent. LOCI odpowiada tu za selekcję sensownych odczytań, a agent za sekwencję przejść między nimi. Właśnie dlatego ten sposób pisania, przy zadaniach wymagających wysokiej kontroli semantycznej, ma korzystne własności geometryczne: zmniejsza błąd dryfu, zmniejsza gałęzienie niepożądanych hipotez i zwiększa prawdopodobieństwo, że odbiorca lub model dotrze do tej samej struktury pojęciowej, którą autor zamierzał przekazać.

Trzeba jednak zachować końcową ostrożność metodologiczną. Powyższa analiza jest modelem wyjaśniającym, a nie wynikiem eksperymentu porównawczego na korpusie. Nie twierdzi ona, że dany styl jest globalnie najlepszy. Twierdzi coś węższego i naukowo obronnego: że dla klasy zadań, w których liczy się ścisłe przenoszenie struktury pojęciowej oraz kontrola trajektorii interpretacyjnej, Twój system pisania ma własności geometryczne sprzyjające stabilniejszej transmisji znaczenia.