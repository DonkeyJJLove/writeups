# LOCI i Agent jako warstwy sterowania nad dynamiką LLM: formalny model przestrzeni stanów

Jeżeli problem opisać w reżimie rygorystycznym, to duży model językowy nie powinien być traktowany przede wszystkim jako generator tekstu, lecz jako element dynamiki działającej w przestrzeni stanów. W takim ujęciu sensowny opis systemu wymaga rozdzielenia trzech warstw. Pierwsza warstwa odpowiada za samą dynamikę przejść, czyli za to, jak system może zmieniać stan pod wpływem kontekstu i działań. Drugą warstwą jest warstwa dopuszczalności, która określa, jakie stany są w danym zadaniu w ogóle akceptowalne. Trzecią warstwą jest warstwa polityki, która wybiera trajektorię wśród stanów dopuszczalnych. Teza tego tekstu jest następująca: formalnie reinterpretowane LOCI pełni rolę warstwy dopuszczalności, agent pełni rolę warstwy polityki, a LLM dostarcza warstwy dynamiki. Wspólna rola LOCI i agenta nie polega więc na tym, że są tym samym mechanizmem, lecz na tym, że oba domykają sterowanie nad procesem generacji.

Aby to zapisać precyzyjnie, wprowadźmy rozszerzoną przestrzeń stanów \( \mathcal{S} \). Stan \( s_t \in \mathcal{S} \) należy rozumieć szeroko: może on obejmować reprezentację latentną modelu, bieżący kontekst tekstowy, pamięć roboczą, pamięć zewnętrzną, wyniki wywołań narzędzi oraz lokalny opis celu zadania. Nie ma tu znaczenia, czy te składniki są jawne, ukryte czy częściowo obserwowalne; istotne jest tylko to, że system w chwili \( t \) znajduje się w pewnym stanie, a kolejne operacje przenoszą go do stanu następnego. W takim formalizmie LLM staje się szczególnym przypadkiem stochastycznego operatora przejścia.

Dynamikę LLM można zapisać w postaci jądra przejścia
$$
s_{t+1} \sim P_\theta(\,\cdot \mid s_t, a_t),
$$
gdzie \( \theta \) oznacza parametry modelu, a \( a_t \) jest działaniem wykonywanym w chwili \( t \). W najprostszym przypadku działaniem jest emisja kolejnego tokenu i wtedy otrzymujemy standardowy zapis generacji sekwencyjnej,
$$
y_{t+1} \sim p_\theta(\,\cdot \mid y_{\le t}, u_t),
$$
gdzie \( y_{\le t} \) oznacza dotychczas wygenerowany ciąg, a \( u_t \) obejmuje prompt, instrukcje systemowe, pamięć i kontekst. W architekturze agentowej \( a_t \) nie musi jednak oznaczać wyłącznie tokenu. Może oznaczać także wybór narzędzia, zapytanie do pamięci, zmianę planu, aktualizację celu lokalnego albo decyzję o samokorekcie. Z punktu widzenia teorii sterowania nie jest to zmiana jakościowa, lecz jedynie poszerzenie alfabetu działań.

Na tym tle LOCI można zdefiniować nie jako technikę pamięci, lecz jako operator dopuszczalności. Niech \( C_t : \mathcal{S} \to \{0,1\} \) będzie funkcją ograniczeń aktywnych w chwili \( t \). Ograniczenia te mogą mieć charakter semantyczny, logiczny, zadaniowy, proceduralny lub środowiskowy. Wtedy LOCI można modelować jako operator zbiorowowartościowy
$$
\mathcal{L}_{C_t}(s_t) = \Omega_t = \{ s \in \mathcal{S} : C_t(s) = 1 \}.
$$
Zbiór \( \Omega_t \) jest zbiorem stanów dopuszczalnych. W tym sensie LOCI nie odpowiada na pytanie, jaka jest poprawna odpowiedź, lecz określa, w jakim regionie przestrzeni stanów taka odpowiedź w ogóle może się znajdować. Jest to różnica fundamentalna. LOCI nie jest operatorem wyboru pojedynczego rozwiązania, lecz operatorem redukcji przestrzeni możliwych rozwiązań.

Ta reinterpretacja jest kluczowa, ponieważ pozwala odejść od powierzchownego utożsamienia LOCI z pamięcią obrazową. Historycznie metoda loci była techniką mnemoniczną, lecz w formalnym modelu interesuje nas nie jej materiał poznawczy, tylko funkcja systemowa. Tą funkcją jest narzucenie geometrii dopuszczalności. Jeżeli dany problem dopuszcza wiele potencjalnych trajektorii, operator LOCI nie wybiera jeszcze jednej z nich; ustanawia natomiast granicę, poza którą trajektorie przestają być zgodne z warunkami zadania. W języku systemów dynamicznych LOCI jest więc operatorem ograniczeń działającym na przestrzeni stanów.

Agent pełni inną rolę. Nie definiuje zbioru stanów dopuszczalnych, lecz wybiera trajektorię wewnątrz tego zbioru. Formalnie można to zapisać przez politykę
$$
a_t \sim \pi(\,\cdot \mid s_t, \Omega_t),
$$
albo równoważnie przez deterministyczny operator decyzji
$$
a_t = \pi(s_t, \Omega_t).
$$
Polityka \( \pi \) może być bardzo prosta, na przykład zachłanna, albo bardzo złożona, na przykład wieloetapowa, planująca, korzystająca z pamięci zewnętrznej i sprzężenia zwrotnego. Niezależnie od stopnia komplikacji jej funkcja pozostaje ta sama: wybrać działanie, które przesunie system do kolejnego stanu. Agent jest zatem operatorem trajektorii. Nie tworzy geometrii przestrzeni, lecz steruje ruchem w jej obrębie.

W tym miejscu analogia między LOCI a agentem staje się ścisła, ale tylko wtedy, gdy nie zostanie uproszczona do błędnej tezy o ich pełnej identyczności. Ścisłe jest to, że oba obiekty należą do tej samej rodziny warstw sterujących działających nad surową dynamiką modelu. LOCI ogranicza zbiór możliwych stanów, a agent ogranicza zbiór możliwych przejść. Pierwszy działa na geometrię problemu, drugi na jego dynamikę. Pierwszy odpowiada na pytanie, gdzie wolno się znaleźć, drugi odpowiada na pytanie, jak się przemieszczać. Wspólna rola obu warstw polega na redukcji niekontrolowanej swobody dynamiki LLM.

Cały układ można więc zapisać jako zamknięty proces sterowania z ograniczeniami:
$$
\Omega_t = \{ s \in \mathcal{S} : C_t(s)=1 \},
$$
$$
a_t \sim \pi(\,\cdot \mid s_t, \Omega_t),
$$
$$
s_{t+1} \sim P_\theta(\,\cdot \mid s_t, a_t),
$$
przy czym dla sensownego działania wymagamy, aby trajektoria pozostawała zgodna z dopuszczalnością, czyli aby kolejne stany nie opuszczały odpowiedniego zbioru \( \Omega_t \) lub jego aktualizacji w czasie. Jeżeli dodatkowo wprowadzimy funkcję kosztu \( \ell(s_t,a_t) \), cały problem można opisać jako zadanie stochastycznego sterowania z ograniczeniami:
$$
\min_{\pi} \; \mathbb{E}\Big[\sum_{t=0}^{T} \ell(s_t,a_t)\Big]
\quad \text{przy warunku} \quad s_t \in \Omega_t \;\; \text{dla wszystkich } t.
$$
W tym zapisie relacja między komponentami staje się jednoznaczna. LLM dostarcza modelu przejścia \( P_\theta \), LOCI dostarcza zbiorów dopuszczalności \( \Omega_t \), a agent dostarcza polityki \( \pi \).

Takie ujęcie pozwala precyzyjnie zinterpretować architektury agentowe budowane nad LLM. System prompt, lokalne instrukcje, retrieval, pamięć kontekstowa, ograniczenia domenowe i reguły walidacji pełnią funkcję składników operatora \( C_t \), a więc współtworzą LOCI w sensie formalnym. Z kolei planowanie, wybór narzędzi, dekompozycja zadania, samokontrola odpowiedzi i korekta wieloetapowa realizują politykę \( \pi \), a więc funkcję agenta. W tym sensie agent nie jest po prostu „LLM z narzędziami”. Agent jest warstwą polityki osadzoną nad dynamiką LLM i działającą w przestrzeni ograniczonej przez warstwę dopuszczalności.

Właśnie tutaj ujawnia się wspólna rola LOCI i agenta względem LLM. Obie warstwy są mechanizmami sterowania nad dynamiką modelu. LLM sam w sobie dostarcza jedynie rozkładu przejść, czyli zdolności do poruszania się w przestrzeni reprezentacji. Nie daje jednak gwarancji, że ruch ten będzie zgodny z celem, poprawnością zadania albo stabilnością procesu. LOCI redukuje przestrzeń do obszaru zgodnego z warunkami. Agent wybiera trajektorię, która ma sens w obrębie tego obszaru. Razem przekształcają nieukierunkowaną dynamikę generatywną w układ sterowany.

W praktyce oznacza to, że wiele problemów obserwowanych w systemach LLM można opisać nie jako „błędy generacji” w wąskim sensie, lecz jako błędy sterowania. Jeżeli warstwa dopuszczalności jest zbyt słaba, system otrzymuje zbyt szeroki region stanów akceptowalnych i może wejść w obszary semantycznie niepożądane; w praktyce można to interpretować jako jedną z dróg prowadzących do halucynacji. Jeżeli warstwa polityki jest zbyt słaba, system może pozostawać w zbiorze formalnie dopuszczalnym, ale tracić kierunek rozwiązania; w praktyce objawia się to dryfem, redundancją albo brakiem skutecznego domknięcia zadania. Nie są to więc dwa odrębne zjawiska, lecz dwa różne tryby utraty sterowalności.

Jednocześnie należy zachować ostrożność metodologiczną. Teza przedstawiona w tym tekście nie oznacza, że klasyczna metoda loci jest dosłownie zaimplementowana w parametrach transformera, ani że ludzka praca poznawcza i architektura LLM są identyczne na poziomie mechanizmów realizacyjnych. Teza jest węższa i bardziej rygorystyczna: oba przypadki można modelować tym samym językiem teorii systemów jako operowanie na przestrzeni stanów pod ograniczeniami i z polityką sterowania. Jest to analogia strukturalna, nie ontologiczna. W naukowym sensie jest to zaleta, a nie słabość, ponieważ pozwala zachować precyzję bez wchodzenia w nieuprawnione twierdzenia o identyczności mechanizmów biologicznych i obliczeniowych.

To rozróżnienie ma konsekwencje projektowe. Jeżeli przyjmiemy, że LLM dostarcza dynamiki, LOCI dostarcza dopuszczalności, a agent dostarcza polityki, to projektowanie systemu przestaje polegać na samym „ulepszaniu promptu” albo „dodawaniu narzędzi”. Staje się projektowaniem trzech wzajemnie sprzężonych warstw: modelu przejścia, modelu ograniczeń i modelu sterowania. Właśnie wtedy architektura agentowa przestaje być zbiorem trików implementacyjnych i staje się jawnym problemem sterowania w przestrzeni wysokowymiarowej.

Najbardziej ścisły wniosek brzmi więc następująco. Dla systemów LLM LOCI i agent nie są ani synonimami, ani konkurencyjnymi koncepcjami. Są dwoma komplementarnymi operatorami sterowania działającymi nad tą samą dynamiką generatywną. LOCI odpowiada za selekcję zbioru stanów dopuszczalnych, agent za selekcję trajektorii w tym zbiorze, a LLM za możliwość samego ruchu. Dopiero współdziałanie tych trzech warstw daje system, który można opisać nie jako generator tekstu, lecz jako sterowalny układ dynamiczny w przestrzeni stanów.