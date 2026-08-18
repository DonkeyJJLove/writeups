# LOCI–Agent–LLM: formalny model sterowania w przestrzeni stanów i geometryka pisania

## Abstrakt

Duży model językowy nie jest agentem, agent nie jest środowiskiem wykonawczym, a obserwacja trajektorii nie jest jeszcze sterowaniem. Rozróżnienie tych poziomów jest konieczne, jeżeli system LLM ma być opisywany językiem teorii sterowania bez zamiany użytecznej analogii w pozorną formalizację. W artykule proponowany jest model zamkniętej pętli, w którym LLM generuje rozkład kandydatów na kolejne tokeny lub działania, agent realizuje politykę i koordynuje wykonanie, środowisko odpowiada za rzeczywistą dynamikę przejść, natomiast LOCI pełni dwie odrębne funkcje: rekonstruuje obserwowalny stan procesu oraz buduje warstwę dopuszczalności, przez którą muszą przejść działania.

Kluczowa korekta względem uproszczonego schematu „LLM = dynamika, LOCI = ograniczenie, agent = polityka” polega na rozdzieleniu dwóch skal. Na poziomie samej generacji tekstu LLM rzeczywiście można modelować jako stochastyczny operator przejścia po stanach kontekstu. Na poziomie systemu agentowego LLM nie jest jednak całą dynamiką: jest elementem polityki lub generatorem propozycji, podczas gdy przejście stanu realizują narzędzia, system operacyjny, API, użytkownik i otoczenie. Dopiero po tym rozdzieleniu LOCI, agent i LLM można połączyć w formalnie spójny układ obserwacji, ograniczeń, decyzji i działania.

Druga część artykułu przenosi ten sam aparat na proces pisania. „Geometryka pisania” oznacza tu projektowanie tekstu jako sterowania rozkładem możliwych interpretacji odbiorcy. Nie chodzi o minimalizację niepewności za wszelką cenę, lecz o zwiększanie prawdopodobieństwa rekonstrukcji zamierzonej struktury pojęciowej bez przedwczesnego zamykania sensu i bez przeciążania odbiorcy.

## Słowa kluczowe

LLM, agent, LOCI, przestrzeń stanów, POMDP, constrained MDP, obserwowalność, warstwa dopuszczalności, sterowanie, bezpieczeństwo agentowe, geometryka pisania.

## Status twierdzeń

**[FACT]** Formalizmy przestrzeni stanów, POMDP, polityki, ograniczeń i sprzężenia zwrotnego pochodzą z teorii sterowania, badań operacyjnych i uczenia ze wzmocnieniem (Kaelbling, Littman i Cassandra, 1998; Altman, 1999; Aubin, 1991).

**[MODEL]** Przypisanie LOCI roli obserwatora i konstruktora zbioru dopuszczalności jest autorskim modelem architektonicznym. Jest ono propozycją interpretacyjną, a nie ustalonym znaczeniem terminu w literaturze.

**[IMPLEMENTATION]** Aktualny podsystem LOCI w repozytorium przetwarza znormalizowane artefakty Human–AI, buduje wektor cech i analizuje trajektorię obserwowalnych zapisów. Nie odczytuje bezpośrednio stanów latentnych transformera i nie jest jeszcze samodzielnym mechanizmem egzekwowania ograniczeń.

**[HYPOTHESIS]** Teza, że warstwa LOCI poprawia sterowalność agenta lub stabilność interpretacji tekstu, wymaga eksperymentu porównawczego. Formalna zgodność modelu nie jest dowodem skuteczności empirycznej.

## 1. Problem: cztery obiekty, których nie wolno utożsamiać

LLM, agent, LOCI i środowisko wykonawcze mogą uczestniczyć w jednej pętli, lecz nie są tym samym rodzajem obiektu. LLM wyznacza rozkład prawdopodobieństwa kolejnych symboli albo kandydatów na działania. Agent utrzymuje cel, pamięć, plan, reguły zakończenia, wybór narzędzi i sprzężenie zwrotne. LOCI obserwuje ślady procesu, rekonstruuje jego operacyjny stan i może wyznaczać obszar dopuszczalności. Środowisko wykonuje działanie i wytwarza nowy stan, którego model nie kontroluje bezpośrednio.

Najbardziej użyteczny schemat nie ma więc postaci liniowej „prompt → model → odpowiedź”, lecz postać zamkniętej pętli:

```text
obserwacja
→ estymacja stanu
→ wyznaczenie ograniczeń
→ propozycja działania
→ walidacja i autoryzacja
→ wykonanie
→ nowa obserwacja
```

Teza artykułu brzmi: **LOCI i agent są komplementarnymi warstwami sterowania, ale sterują czym innym**. LOCI odpowiada za to, co system uważa za obserwowany stan i jakie stany lub działania uznaje za dopuszczalne. Agent odpowiada za wybór i koordynację trajektorii. LLM dostarcza stochastycznych propozycji. Rzeczywiste przejście stanu pozostaje własnością całego układu wraz ze środowiskiem.

## 2. Dwie skale dynamiki: generacja tekstu i działanie w świecie

Na poziomie pojedynczej generacji tekstowej stan można zdefiniować jako bieżący kontekst wraz z wygenerowanym prefiksem:

```math
s_t^{\mathrm{txt}} = \left(c_t, y_{\leq t}\right).
```

Następny token jest próbkowany z rozkładu modelu:

```math
y_{t+1} \sim p_\theta\!\left(\cdot \mid c_t, y_{\leq t}\right).
```

a stan tekstowy aktualizuje deterministyczna operacja dołączenia tokenu:

```math
s_{t+1}^{\mathrm{txt}} = \tau\!\left(s_t^{\mathrm{txt}}, y_{t+1}\right).
```

W tej skali stwierdzenie, że LLM dostarcza dynamiki przejścia, jest poprawną abstrakcją dla modelu autoregresyjnego opartego na architekturze transformera (Vaswani et al., 2017). Model wyznacza stochastyczne przejście pomiędzy kolejnymi stanami kontekstu tekstowego. Nie oznacza to jednak, że jego wewnętrzne reprezentacje zostały w tym modelu zidentyfikowane ani że stan tekstowy jest pełnym stanem obliczeniowym transformera. Jest to model wejście–wyjście wystarczający do opisu sekwencyjnej generacji.

Po podłączeniu narzędzi skala zmienia się zasadniczo. Niech $x_t \in \mathcal X$ oznacza rzeczywisty stan systemu i jego otoczenia, $o_t \in \mathcal O$ obserwację dostępną agentowi, a $u_t \in \mathcal U$ działanie wykonawcze. Wtedy:

```math
\begin{aligned}
o_t &\sim O\!\left(\cdot \mid x_t\right), \\
x_{t+1} &\sim T\!\left(\cdot \mid x_t, u_t, w_t\right).
\end{aligned}
```

gdzie $O$ jest modelem obserwacji, $T$ rzeczywistym jądrem przejścia środowiska, a $w_t$ reprezentuje zakłócenia i czynniki zewnętrzne. Wywołanie API, zapis pliku, odpowiedź serwera, zmiana uprawnień, błąd narzędzia albo decyzja człowieka należą do tej dynamiki. LLM może je przewidywać lub opisywać, lecz ich nie ustanawia.

Na poziomie systemowym LLM lepiej modelować jako generator kandydatów na działanie:

```math
\tilde u_t \sim \pi_\theta\!\left(\cdot \mid \hat b_t, g_t, m_t\right),
```

gdzie $\hat b_t$ jest estymowanym stanem lub stanem przekonania, $g_t$ celem, a $m_t$ pamięcią roboczą. Kandydat $\tilde u_t$ nie powinien jeszcze być utożsamiany z działaniem $u_t$. Pomiędzy propozycją a wykonaniem musi istnieć warstwa walidacji, autoryzacji i ograniczeń.

To rozróżnienie usuwa podstawowy błąd kategorialny. **W generatorze tekstowym LLM może być jądrem przejścia. W systemie agentowym LLM jest częścią kontrolera, a nie całym kontrolowanym światem.**

## 3. LOCI jako obserwator stanu i konstruktor dopuszczalności

W tym artykule nazwa LOCI odnosi się do technicznego podsystemu i proponowanej warstwy architektonicznej repozytorium. Nie jest twierdzeniem, że klasyczna metoda loci została zaimplementowana w parametrach transformera. Ewentualne podobieństwo jest funkcjonalne: chodzi o organizowanie przestrzeni śladów, stanów i relacji, nie o identyczność mechanizmu poznawczego.

Aktualny pipeline repozytorium realizuje przede wszystkim funkcję obserwacyjną:

```math
\begin{aligned}
r_t &\xrightarrow{\;F_{27}\;} \phi_t \in \mathbb R^{27}, \\
\Phi_{1:t} &= \left[\phi_1,\ldots,\phi_t\right] \xrightarrow{\;R\;} \hat z_{1:t}.
\end{aligned}
```

gdzie $r_t$ jest znormalizowanym rekordem Human–AI, $F_{27}$ buduje jego 27-wymiarową reprezentację cech, a $R$ tworzy projekcję sekwencji $\Phi_{1:t}$ używaną do analizy trajektorii. W obecnej implementacji cechy obejmują między innymi własności leksykalne, strukturalne i różnice pomiędzy kolejnymi rekordami. Otrzymana trajektoria $\hat z_{1:t}$ jest zatem **operacyjnym przybliżeniem stanu artefaktu**, a nie bezpośrednim pomiarem stanu latentnego modelu, intencji człowieka ani prawdziwości treści.

Ta granica jest ważna. Standaryzacja cech i projekcja PCA mogą ujawnić zmianę trajektorii obserwowanych zapisów, ale same nie dowodzą istnienia określonej semantycznej rozmaitości. Jeżeli 9R ma być formalnym obiektem, a nie wyłącznie nazwą metaspace, potrzebna jest jawna mapa:

```math
R_9 : \mathbb R^{27} \rightarrow \mathbb R^9,
```

wraz z definicją semantyki dziewięciu wymiarów, procedurą identyfikacji, testem stabilności i walidacją na danych niezależnych. Trójwymiarowa projekcja wizualizacyjna powinna pozostać warstwą prezentacji, a nie zastępować dowodu modelu 9R.

Docelowa rola LOCI może być szersza. Niech:

```math
\left(\hat b_t,\Omega_t^x,\mathcal A_t,\rho_t\right)
=
\mathcal L\!\left(r_{\leq t},g_t,\kappa_t\right),
```

gdzie $\hat b_t$ jest estymacją stanu lub rozkładem przekonania, $\Omega_t^x$ zbiorem dopuszczalnych stanów, $\mathcal A_t$ stanowo zależnym zbiorem działań, $\rho_t$ miarą zaufania do estymacji, a $\kappa_t$ aktywnym kontraktem zadania: polityką, ograniczeniami bezpieczeństwa, budżetem, zakresem autorytetu i kryteriami zakończenia.

Dopuszczalność trzeba rozdzielić na ograniczenia stanu i działania. Niech:

```math
\Omega_t^x
=
\left\{x\in\mathcal X : c_j^x(x;\kappa_t)\leq 0,\; j=1,\ldots,m\right\},
```

oznacza zbiór dopuszczalnych stanów, a:

```math
\mathcal A_t(x)
=
\left\{u\in\mathcal U : c_k^u(x,u;\kappa_t)\leq 0,\; k=1,\ldots,n\right\},
```

zbiór działań dozwolonych w stanie $x$. LOCI nie odpowiada wtedy na pytanie „jaka odpowiedź jest prawdziwa?”. Odpowiada na trzy węższe pytania: **co obecnie obserwujemy, jak pewna jest ta rekonstrukcja oraz jakie przejścia pozostają zgodne z kontraktem**.

Przy częściowej obserwowalności nie wystarczy sprawdzić pojedynczego punktu. Bezpieczny zbiór działań powinien uwzględniać rozkład możliwych stanów, bieżące ograniczenia wykonawcze i prawdopodobny stan następny:

```math
\begin{aligned}
\mathcal U_t^{\mathrm{safe}}(\hat b_t)
= \Bigl\{u\in\mathcal U :
\Pr\bigl(&x_t\in\Omega_t^x,\;
          u\in\mathcal A_t(x_t),\;
          x_{t+1}\in\Omega_{t+1}^x \\
        &\mid \hat b_t,u\bigr)
\geq 1-\varepsilon_t\Bigr\}.
\end{aligned}
```

Jeżeli zbiór jest pusty albo $\rho_t$ spada poniżej progu, poprawnym działaniem nie jest „najbardziej prawdopodobna kontynuacja”, lecz zatrzymanie, pozyskanie dodatkowej obserwacji, eskalacja albo przekazanie decyzji człowiekowi.

## 4. Agent jako polityka, orkiestrator i mechanizm domknięcia pętli

Redukowanie agenta do samej polityki jest użyteczne matematycznie, ale niewystarczające architektonicznie. Agent obejmuje co najmniej estymację stanu, utrzymanie celu, planowanie, pamięć, wybór narzędzi, kontrolę wykonania, ocenę wyniku i warunek zakończenia. Architektury takie jak ReAct, Toolformer i Reflexion pokazują różne sposoby łączenia generacji językowej z działaniem, narzędziami i sprzężeniem zwrotnym. LLM może realizować część tych funkcji, lecz nie powinien sam egzekwować granic, których naruszenie ma skutek bezpieczeństwa.

Pętla sterowania może mieć następującą postać:

```math
\begin{aligned}
\hat b_t
&= \mathcal B\!\left(\hat b_{t-1},o_t,u_{t-1}\right), \\
\left(\Omega_t^x,\mathcal A_t\right)
&= \mathcal C\!\left(\hat b_t,g_t,\kappa_t\right), \\
\tilde u_t
&\sim \pi_\theta\!\left(\cdot\mid\hat b_t,g_t,m_t\right), \\
u_t
&= \mathrm{Shield}\!\left(
\tilde u_t;
\mathcal U_t^{\mathrm{safe}}(\hat b_t),
\rho_t,
\kappa_t
\right), \\
x_{t+1}
&\sim T\!\left(\cdot\mid x_t,u_t,w_t\right).
\end{aligned}
```

Operator `Shield` nie musi być jednym algorytmem. Może składać się z walidacji typów i argumentów, kontroli uprawnień, limitów kosztu, reguł domenowych, potwierdzenia człowieka, symulacji skutku, izolacji wykonania (sandboxingu), mechanizmu wycofania operacji (rollback) oraz blokady działania przy utracie obserwowalności. Ważne jest to, że egzekucja odbywa się poza swobodną semantyką promptu.

Problem optymalizacji można zapisać jako ograniczony proces decyzyjny:

```math
\pi^\star
\in
\arg\min_{\pi\in\Pi}
\mathbb E_\pi\!\left[
\sum_{t=0}^{T}\gamma^t\,\ell(x_t,u_t)
\right],
```

przy ograniczeniach:

```math
\mathbb E_\pi\!\left[
\sum_{t=0}^{T}\gamma^t\,d_k(x_t,u_t)
\right]
\leq D_k,
\qquad k=1,\ldots,K,
```

oraz przy warunku, że wykonanie nie przekracza jawnego zakresu autorytetu. Funkcja $\ell$ opisuje koszt lub błąd zadania, $d_k$ koszty ograniczeń, a $D_k$ ich budżety. Taki zapis pozwala rozdzielić skuteczność od bezpieczeństwa: polityka może optymalizować wynik, ale nie może „zapłacić” naruszeniem granicy autoryzacji, jeżeli ta granica jest twarda.

Nie każde lokalnie dopuszczalne działanie zachowuje dopuszczalność w przyszłości. Sterowanie powinno więc uwzględniać nie tylko to, czy ruch jest legalny teraz, lecz także to, czy pozostawia systemowi bezpieczne trajektorie następne. To jest różnica między filtrem jednego kroku a kontrolą zdolności całego procesu do pozostawania w obszarze dopuszczalnym (viability).

## 5. Co dokładnie robi każdy komponent

Najkrótsza poprawna synteza wygląda następująco:

```math
\begin{aligned}
\boxed{\text{LOCI: obserwuj, rekonstruuj i ogranicz}} \\
\boxed{\text{agent: wybieraj, koordynuj i domykaj pętlę}} \\
\boxed{\text{LLM: generuj rozkład kandydatów}} \\
\boxed{\text{środowisko: realizuj rzeczywiste przejścia}}
\end{aligned}
```

LOCI i agent należą do wspólnej rodziny mechanizmów sterujących, ale nie są wymienne. LOCI kształtuje przestrzeń rozpoznanych i dopuszczalnych stanów oraz działań. Agent wybiera trajektorię w tej przestrzeni, aktualizuje ją po obserwacji skutku i decyduje o zakończeniu. LLM dostarcza elastyczności generatywnej, ale nie dostarcza gwarancji. Środowisko może zareagować inaczej, niż przewidywał model.

W tym sensie pierwotna intuicja pozostaje prawdziwa po doprecyzowaniu: LOCI ogranicza niekontrolowaną swobodę procesu, a agent nadaje jej kierunek. Trzeba jedynie dodać, że żaden z tych mechanizmów nie zastępuje obserwacji, autoryzacji i rzeczywistej dynamiki środowiska.

## 6. Błędy generacji są często błędami całej pętli sterowania

Nie każdą halucynację można wyjaśnić „zbyt szerokim zbiorem stanów dopuszczalnych”. Halucynacja może wynikać z niepewności modelu, braków danych, błędnego retrievalu, niewłaściwego dekodowania, konfliktu instrukcji albo błędnej reprezentacji zadania. Model sterowania jest użyteczny wtedy, gdy rozdziela źródła awarii zamiast sprowadzać je do jednej przyczyny.

**Błąd obserwacji lub estymacji** występuje wtedy, gdy agent buduje niepoprawny obraz stanu $\hat b_t$. Może to wynikać z niepełnych danych, zatrutego kontekstu, błędnej pamięci albo mylącego wyniku narzędzia.

**Błąd specyfikacji** występuje wtedy, gdy $\Omega_t^x$ albo $\mathcal A_t$ kodują niewłaściwe wymagania. System może konsekwentnie realizować źle zdefiniowany cel i pozostawać formalnie zgodny z błędnym kontraktem.

**Błąd polityki lub planowania** oznacza wybór słabej trajektorii mimo poprawnej obserwacji i poprawnych ograniczeń. Działanie może być dozwolone, ale nieefektywne, redundantne albo prowadzące do ślepego zaułka.

**Błąd egzekwowania** powstaje wtedy, gdy kandydat wygenerowany przez LLM omija walidację, kontrolę uprawnień albo mechanizm zatwierdzania. W systemie agentowym jest to przejście od błędu semantycznego do realnego skutku operacyjnego.

**Błąd modelu środowiska** pojawia się wtedy, gdy narzędzie, API lub użytkownik reaguje inaczej, niż zakłada polityka. Nawet poprawny plan może utracić ważność po zmianie stanu poza kontrolą agenta.

Ta taksonomia ma bezpośrednie znaczenie dla bezpieczeństwa. Semantyczny operator dopuszczalności nie może być jedyną granicą ochronną. Autoryzacja, separacja uprawnień, provenance, podpisane delegacje, ograniczenia narzędzi, transakcyjność, sandboxing i audyt muszą być egzekwowane deterministycznie. LOCI może wykryć utratę spójności albo obserwowalności; nie może sam zastąpić systemu IAM, polityki wykonania ani modelu zaufania. To rozróżnienie łączy ten artykuł z modelem [LLM Trust Boundary Collapse](llm-trust-boundary-collapse-publication.md): tekstowa reprezentacja reguły nie jest jeszcze granicą zaufania.

## 7. Geometryka pisania: tekst jako sterowanie interpretacją

Ten sam schemat można przenieść z systemu agentowego na tekst. Przez **geometrykę pisania** rozumie się projektowanie kolejnych segmentów wypowiedzi tak, aby prowadziły odbiorcę przez przestrzeń możliwych interpretacji, jednocześnie zachowując jawne granice pomiędzy definicją, analogią, hipotezą i faktem.

Niech $\mathcal Z$ będzie przestrzenią możliwych interpretacji, a $q_t(z)$ idealizowanym rozkładem przekonań odbiorcy po przeczytaniu prefiksu $x_{\leq t}$:

```math
q_t(z)
=
P\!\left(z\mid x_{\leq t},K\right),
\qquad z\in\mathcal Z,
```

gdzie $K$ oznacza wiedzę uprzednią odbiorcy. Kolejny segment tekstu aktualizuje rozkład:

```math
q_{t+1}(z)
\propto
q_t(z)\,P\!\left(x_{t+1}\mid z,K\right).
```

Nie jest to twierdzenie, że autor zna rzeczywisty rozkład a posteriori czytelnika. Jest to model wyjaśniający, który pozwala mówić precyzyjnie o eliminowaniu odczytań, utrzymywaniu pojęć i korygowaniu dryfu.

Niech $M^\star\subseteq\mathcal Z$ oznacza zbiór interpretacji zgodnych z zamierzoną strukturą pojęciową. Celem tekstu technicznego nie powinno być samo zmniejszenie entropii $q_t$. Niska entropia może oznaczać również bardzo pewne, lecz błędne zrozumienie. Lepszym celem jest zwiększanie masy prawdopodobieństwa na $M^\star$, przy kontroli niepożądanej wieloznaczności i kosztu poznawczego:

```math
\mathcal J_{\mathrm{text}}
=
-\log q_T(M^\star)
+\lambda A_T
+\mu L_T,
```

gdzie $A_T$ reprezentuje resztkową wieloznaczność poza obszarem docelowym, a $L_T$ koszt utrzymania i integrowania struktury przez odbiorcę. Wartości tych składników nie są jeszcze mierzone w tym artykule; równanie definiuje kierunek testowalnego modelu.

Wzorzec „nie X, lecz Y” działa w takim ujęciu jak kontrastowy sygnał aktualizacyjny. Nie usuwa magicznie punktów z przestrzeni znaczeń, lecz obniża wiarygodność interpretacji należących do klasy X i podnosi wiarygodność klasy Y. Stabilne powtarzanie terminów takich jak „stan”, „obserwacja”, „ograniczenie”, „polityka” i „wykonanie” utrzymuje wspólny układ współrzędnych. Rekurencyjne przywracanie głównej tezy działa jak sprzężenie zwrotne: lokalny przyrost treści jest okresowo sprawdzany względem niezmiennika całego modelu.

Dobre pisanie techniczne wykonuje więc naprzemiennie dwa ruchy. Najpierw rozszerza przestrzeń opisu, wprowadzając nowy związek lub rozróżnienie. Następnie projektuje ten przyrost z powrotem na jawny układ pojęciowy, aby ograniczyć dryf. Sama ekspansja prowadzi do rozproszenia; samo ograniczanie prowadzi do tautologii. Sterowalność powstaje dopiero z ich naprzemienności.

Długie zdanie nie jest automatycznie błędem, ale każdy jego kolejny człon powinien zmniejszać nieoznaczoność albo jawnie rozszerzać model. Jeżeli człon otwiera nową oś bez jej zakotwiczenia, rośnie krzywizna trajektorii interpretacyjnej i koszt integracji. Geometryka pisania nie jest więc kultem gęstości. Jest dyscypliną kontroli nad tym, gdzie i po co tekst zmienia kierunek.

## 8. Jak sfalsyfikować model

Formalizacja staje się naukowo użyteczna dopiero wtedy, gdy można wskazać wynik, który ją osłabi. Najprostszy eksperyment powinien porównać cztery warunki: bazowy LLM, LLM z ograniczeniami zapisanymi wyłącznie w promptach, agenta z narzędziami i pętlą kontroli oraz agenta wyposażonego dodatkowo w obserwator LOCI i niezależny mechanizm dopuszczalności.

Testy powinny obejmować zadania wieloetapowe, częściową obserwowalność, sprzeczne instrukcje, zatrute źródła, błędy narzędzi i zmianę stanu w trakcie wykonania. Mierzyć należy co najmniej skuteczność zadania, częstość naruszeń ograniczeń, kalibrację estymacji stanu, dryf względem celu, czas odzyskania po zakłóceniu, liczbę niebezpiecznych kandydatów zablokowanych przed wykonaniem, koszt oraz opóźnienie.

Hipoteza o wartości LOCI zostanie wzmocniona, jeżeli warstwa obserwacji i dopuszczalności obniży częstość naruszeń oraz skróci czas powrotu do poprawnej trajektorii bez nieproporcjonalnego spadku skuteczności. Zostanie osłabiona, jeżeli ten sam wynik da prostszy walidator, jeżeli estymowany stan nie będzie lepiej skalibrowany od bazowego kontekstu albo jeżeli dodatkowa geometria nie przełoży się na decyzje.

Analogicznie należy testować geometrykę pisania. Czytelnicy lub niezależne modele powinny rekonstruować strukturę pojęciową tekstów w kilku wariantach redakcyjnych. Ocenie podlegałaby zgodność odtworzonego grafu pojęć, wariancja interpretacji, liczba błędnych relacji, retencja po czasie i koszt poznawczy. Bez takiego badania można mówić o spójnym modelu projektowym, ale nie o dowiedzionej przewadze stylu.

## Wniosek

Najbardziej rygorystyczna wersja tezy nie brzmi: „LOCI i agent są tym samym” ani „LLM jest całym układem dynamicznym”. Brzmi ona następująco:

> **System agentowy oparty na LLM staje się sterowalny dopiero wtedy, gdy rozdziela obserwację stanu, konstrukcję ograniczeń, generowanie kandydatów, politykę wyboru, autoryzację wykonania i rzeczywistą dynamikę środowiska.**

W takim układzie LOCI może pełnić rolę obserwatora i konstruktora dopuszczalności, agent może prowadzić trajektorię i domykać sprzężenie zwrotne, a LLM może dostarczać elastycznego rozkładu propozycji. Ich wspólna wartość nie polega na podobieństwie nazw ani na metaforycznej jedności, lecz na komplementarnym ograniczaniu swobody systemu tam, gdzie sama generacja probabilistyczna nie daje gwarancji.

Ten sam mechanizm opisuje geometrykę pisania. Tekst techniczny nie jest wyłącznie zbiorem zdań, lecz kontrolowaną trajektorią rekonstrukcji znaczenia. Jego jakość zależy nie od maksymalnego zagęszczenia pojęć, lecz od tego, czy odbiorca może odtworzyć właściwe relacje, zachować granice między poziomami modelu i rozpoznać, które zdania są faktami, które formalizacją, a które hipotezą czekającą na test.

## Powiązane artefakty repozytorium

- [LOCI — kanoniczny pipeline i drzewo nawigacji](../badania/LOCI/README.MD)
- [Kanoniczna macierz cech 27D](../badania/LOCI/matlab/features/build_loci_feature_matrix.m)
- [Kanoniczny wizualizator trajektorii](../badania/LOCI/matlab/visualizers/loci_27D_9R_visualizer_canonical.m)
- [LLM Trust Boundary Collapse](llm-trust-boundary-collapse-publication.md)
- [AI Security Model Boundary](../ai_security_model_boundary_strategy_writeup.md)

## Literatura

1. Vaswani, A. et al. (2017), [*Attention Is All You Need*](https://arxiv.org/abs/1706.03762).
2. Kaelbling, L. P., Littman, M. L., Cassandra, A. R. (1998), [*Planning and Acting in Partially Observable Stochastic Domains*](https://doi.org/10.1016/S0004-3702(98)00023-X).
3. Altman, E. (1999), [*Constrained Markov Decision Processes*](https://www.routledge.com/Constrained-Markov-Decision-Processes/Altman/p/book/9781315140223).
4. Aubin, J.-P. (1991), [*Viability Theory*](https://viability-theory.org/en/node/51).
5. Yao, S. et al. (2023), [*ReAct: Synergizing Reasoning and Acting in Language Models*](https://arxiv.org/abs/2210.03629).
6. Schick, T. et al. (2023), [*Toolformer: Language Models Can Teach Themselves to Use Tools*](https://arxiv.org/abs/2302.04761).
7. Shinn, N. et al. (2023), [*Reflexion: Language Agents with Verbal Reinforcement Learning*](https://arxiv.org/abs/2303.11366).
8. Kintsch, W. (1988), [*The Role of Knowledge in Discourse Comprehension: A Construction–Integration Model*](https://doi.org/10.1037/0033-295X.95.2.163).