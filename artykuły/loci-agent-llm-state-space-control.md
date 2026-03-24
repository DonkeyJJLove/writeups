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

Wniosek końcowy:

LOCI i agent są komplementarnymi operatorami sterowania nad dynamiką LLM.  
LOCI selekcjonuje przestrzeń stanów, agent selekcjonuje trajektorie, a LLM umożliwia ruch.

Dopiero ich współdziałanie daje system sterowalny w przestrzeni stanów.