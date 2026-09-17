# Między znakiem a decyzją: semantyczna kompresja jako metaarchitektura AGI

Punktem wyjścia do budowy systemu AGI nie musi być zwiększanie liczby parametrów modelu. Bardziej fundamentalnym problemem jest sposób, w jaki system **ogranicza przestrzeń możliwych interpretacji, stanów i działań, nie tracąc informacji relewantnej dla celu**. Język naturalny jest tu szczególnie interesujący, ponieważ już na najniższej warstwie reprezentacji pokazuje, że znak, zapis znaku, jego tokenizacja, znaczenie i pragmatyczne użycie nie są tym samym obiektem. Między bajtem a decyzją istnieje więc seria transformacji, z których każda coś zachowuje, coś usuwa i coś rekonstruuje. Te transformacje można potraktować nie jako niedoskonałość systemu, lecz jako mechanizm kontroli złożoności.

Pierwsze rozdzielenie zachodzi już między **znakiem a jego kodowaniem**. Unicode przypisuje znakom abstrakcyjne punkty kodowe, natomiast UTF-8 czy UTF-16 określają ich reprezentację w bajtach. Co istotniejsze, nawet na poziomie samych punktów kodowych dwa różne ciągi mogą być kanonicznie równoważne. Unicode definiuje dlatego NFC, NFD, NFKC i NFKD: procedury redukujące wiele reprezentacji do ustalonej postaci. Z drugiej strony istnieją znaki różne kodowo, które dla człowieka mogą wyglądać praktycznie identycznie; mechanizmy Unicode dotyczące *confusables* powstały właśnie dlatego, że podobieństwo percepcyjne nie implikuje identyczności reprezentacyjnej. Oznacza to, że relacja `kod → znak → znaczenie` od początku nie jest izomorfizmem jeden-do-jednego.

To ma bezpośrednią konsekwencję dla systemów językowych. Model LLM nie otrzymuje „znaczeń”. Otrzymuje zakodowany tekst, który zostaje przekształcony przez tokenizer w sekwencję identyfikatorów. Metody subwordowe, takie jak BPE, powstały między innymi po to, aby obsługiwać rzadkie i wcześniej niewidziane formy przez składanie ich z mniejszych jednostek. Jednak granice tokenów nie są granicami semantycznymi. Badania odporności pokazują, że drobne zmiany typograficzne mogą zmienić tokenizację i zachowanie modeli, a nowsze wyniki wskazują nawet przypadki, w których sposób segmentacji wpływa systematycznie na reprezentację znaczenia.

Powstaje więc pierwsza zasadnicza własność architektury myślenia: **semantyka nie znajduje się w tablicy znaków, ale tablica znaków ogranicza drogę, po której semantyka może zostać odtworzona**. Inny ciąg bajtów może prowadzić do innej tokenizacji; inna tokenizacja do innego zestawu reprezentacji wejściowych; te z kolei uczestniczą w innym przebiegu attention i wytwarzaniu kolejnych stanów ukrytych. Transformer konstruuje kontekstowe reprezentacje właśnie przez operacje attention nad reprezentacjami pozycji wejściowych, nie przez odczyt gotowych pojęć zapisanych w znakach.

Tu pojawia się przestrzeń latentna. Nie należy jej utożsamiać z magazynem gotowych znaczeń. Jest raczej wysokowymiarowym stanem obliczeniowym, w którym własności syntaktyczne, statystyczne, relacyjne i semantyczne mogą zostać rozłożone pomiędzy wiele wymiarów i wiele warstw. Znaczenie jest następnie rekonstruowane względem kontekstu i zadania. Ten sam zapis może więc aktywować wiele potencjalnych trajektorii interpretacyjnych, natomiast mechanizmy attention, kontekstu, instrukcji i późniejszej inferencji powodują, że tylko część z nich pozostaje relewantna.

Właśnie w tym miejscu „błąd” zmienia charakter. W klasycznym ujęciu transmisyjnym błąd oznacza różnicę między sygnałem nadanym a odebranym. W systemie semantycznym należy rozróżnić co najmniej dwa błędy: **błąd kodowy**, który zmienia reprezentację, oraz **dystorsję semantyczną**, która zmienia znaczenie istotne dla danego zadania. Dwa zdania mogą różnić się niemal wszystkimi tokenami, zachowując tę samą odpowiedź semantyczną. Badanie semantic entropy Farquhara i współautorów wykorzystuje właśnie tę własność: warianty leksykalne grupowane są według znaczenia, zanim szacowana jest niepewność. Rozkład nad ciągami tokenów i rozkład nad znaczeniami są więc dwoma różnymi obiektami probabilistycznymi.

To pozwala przejść od „błędu” do **semantycznej teorii kompresji**. Rate-distortion theory formalizuje podstawową zależność: dopuszczenie określonego poziomu zniekształcenia pozwala obniżyć ilość informacji konieczną do reprezentacji źródła. Information Bottleneck rozwija tę ideę dalej: należy znaleźć możliwie krótki kod wejścia, zachowując przede wszystkim informację relewantną dla zmiennej będącej przedmiotem przewidywania. Nie potrzebujemy więc zachować wszystkiego. Potrzebujemy zachować to, co zmienia wynik zadania.

Dla architektury AGI można zapisać ten problem następująco:

```text
X  = pełna reprezentacja wejściowa
G  = aktualny cel
Z  = skompresowany stan latentny
Y  = informacja potrzebna do decyzji
A  = dopuszczalne działanie

minimalizuj:
I(X ; Z)

przy zachowaniu:
I(Z ; Y | G)

oraz ograniczeniu:
D_sem(X, Z | G) ≤ ε
```

`ε` jest tutaj **budżetem błędu semantycznego**. Nie oznacza zezwolenia systemowi na dowolne pomyłki. Oznacza zgodę na utratę tych różnic wejścia, które nie zmieniają znaczenia potrzebnego do rozwiązania aktualnego problemu. W tym sensie szum może stać się elementem inteligencji: różnice istnieją w reprezentacji, ale układ relewancji klasyfikuje część z nich jako obliczeniowo nieistotne.

Dlatego kluczowe nie jest eliminowanie całego szumu, lecz właściwe wyznaczenie **granicy relewancji**. Jest to zbieżne z teoriami pragmatycznymi, w których interpretacja wypowiedzi nie polega wyłącznie na dekodowaniu znaków. Relevance Theory opisuje poznanie jako preferowanie informacji dających efekty poznawcze przy odpowiednim koszcie ich uzyskania; komunikacja obejmuje zarazem kodowanie oraz inferencję intencji. W architekturze maszynowej można nadać temu bardziej techniczne znaczenie: układ relewancji jest operatorem ograniczającym zbiór reprezentacji, hipotez lub działań względem celu, kosztu, ryzyka i aktualnego modelu świata.

Stąd wynika podstawowa teza: **inteligencja obliczeniowa nie polega na analizowaniu całej dostępnej przestrzeni, lecz na takim przekształcaniu reprezentacji, aby większość tej przestrzeni nie musiała zostać rozwinięta**. Jeżeli wejście o długości `n` zostanie przed drogą operacją sprowadzone do relewantnej reprezentacji długości `k`, gdzie `k << n`, oszczędność może pojawić się również na poziomie samej architektury modelu. W klasycznym self-attention macierz interakcji ma rozmiar zależny kwadratowo od długości sekwencji, choć całkowity koszt Transformera obejmuje także inne składniki. Redukcja reprezentacji przed lub pomiędzy kolejnymi etapami inferencji może więc ograniczać zarówno koszt przetwarzania sekwencji, jak i — co dla AGI ważniejsze — liczbę hipotez i działań wymagających dalszego rozwijania.

Nie należy jednak utożsamiać **losowego szumu** z tą optymalizacją. Losowe usuwanie informacji może zwiększyć niepewność i liczbę koniecznych hipotez. Korzystna jest dopiero dystorsja kontrolowana przez relewancję. Możemy zatem rozróżnić:

```text
szum przypadkowy
→ utrata informacji relewantnej
→ wzrost niepewności
→ wzrost kosztu inferencji

dystorsja kontrolowana
→ utrata informacji nierelewantnej
→ zachowanie zmiennych decyzyjnych
→ redukcja przestrzeni hipotez
→ spadek kosztu inferencji
```

Na tym poziomie scaffolding przestaje być „dobrym promptem”. Staje się **metaarchitekturą przejść między reprezentacjami**. Jego zadaniem jest określanie: co można uznać za semantycznie równoważne, które różnice należy zachować, które wolno skompresować, kiedy potrzebna jest ponowna ekspansja hipotez, jaki poziom błędu jest dopuszczalny, który model powinien wykonać następną inferencję i w którym miejscu reprezentacja probabilistyczna musi zostać zamknięta deterministycznym kontraktem.

Można to zapisać jako wielokrotną optymalizację:

```text
KOD
→ NORMALIZACJA
→ TOKENIZACJA
→ LATENT
→ SELEKCJA RELEWANCJI
→ KOMPRESJA SEMANTYCZNA
→ INFERENCJA
→ EKSPANSJA KONTRHIPOTEZ
→ PONOWNA KOMPRESJA
→ KANONICZNA REPREZENTACJA
→ DECYZJA
→ DZIAŁANIE
→ OBSERWACJA
→ NOWY STAN
```

Nie jest to zatem prosty kierunek `tekst → odpowiedź`. System wielokrotnych optymalizacji przechodzi naprzemiennie przez reprezentacje probabilistyczne i deterministyczne. LLM może szeroko generować hipotezy; inny model lub deterministyczny komponent może je grupować, redukować, falsyfikować i normalizować; następny model może rozwijać już tylko pozostałą przestrzeń; warstwa wykonawcza otrzymuje ostatecznie nie tekst języka naturalnego, lecz ograniczoną, typowaną reprezentację działania.

To dokładnie wyjaśnia, dlaczego w rozwijanej architekturze LION **model nie jest Materializerem**. Materializacja wymaga poza samą generacją typowanego wejścia, granicy reprezentacji, walidacji, niezależnej weryfikacji, reguł activation authority, obserwacji i reconciliacji. W proponowanym LCMS język czytelny dla człowieka i modelu ma być normalizowany do jednej kanonicznej Action IR; niekanoniczny Unicode, aliasy, niejednoznaczne jednostki i inne wieloznaczności mają być odrzucane właśnie dlatego, że różnica na poziomie kodowym nie może bez kontroli przechodzić w różnicę efektu.

W tym sensie przyszły scaffolding AGI powinien pełnić rolę **kompilatora relewancji**. Nie przechowuje jednej ontologii świata. Konstruuje roboczą ontologię potrzebną dla aktualnego zadania, wyznacza klasy równoważności pomiędzy reprezentacjami, określa dopuszczalną dystorsję, rozdziela eksplorację od decyzji i decyduje, w jakiej reprezentacji problem ma być przekazany następnej warstwie. LION ma już części tej logiki rozdzielone pomiędzy `Gap`, `CapabilityNeed`, `Composition`, `Mosaic`, Action IR i mechanizmy evidence; wcześniejszy raport wprost wskazuje, że nie istnieje jeszcze jeden kanoniczny Abstraction Compiler, a jego funkcje są rozproszone pomiędzy scaffolding, komponenty kompozycji i materializacji.

Dla systemów wieloagentowych konsekwencja jest jeszcze większa. Gdy `N` botów lub dronów otrzyma pełny model świata i pełny zbiór możliwych działań, złożoność nie wynika już jedynie z inferencji pojedynczego modelu. Pojawia się kombinatoryka stanów, komunikacji, konfliktujących planów i wzajemnych reakcji. Skalowanie inteligencji poprzez samo dodawanie agentów może więc zwiększać koszt szybciej niż zwiększa zdolność rozwiązania problemu. Rozwiązaniem jest hierarchiczna redukcja semantyczna: każdy agent operuje na lokalnym, wystarczającym statystycznie modelu sytuacji, natomiast kolejne poziomy systemu otrzymują nie wszystkie obserwacje, lecz relewantne abstrakcje, anomalie, konflikty i zmiany stanu.

Dron nie musi zatem „rozumieć wszystkiego”. Powinien posiadać wystarczającą reprezentację do swojego fragmentu problemu. Rój nie musi wymieniać całego kontekstu wszystkich agentów. Powinien wymieniać **semantyczne delty wpływające na wspólną decyzję**. Metaarchitektura może wówczas kontrolować trzy odrębne budżety: koszt reprezentacji, dopuszczalną dystorsję semantyczną oraz koszt działania. Tak zdefiniowana inteligencja roju nie rośnie przez kopiowanie identycznego umysłu, ale przez organizację różnych układów relewancji.

Dla systemów cyberfizycznych pojawia się jednak granica zasadnicza: kompresja semantyczna może decydować, **które działania rozważać**, lecz nie może dowolnie kompresować parametrów bezpieczeństwa efektu fizycznego. Semantycznie podobne polecenia mogą prowadzić do fizycznie różnych konsekwencji. Dlatego wraz ze zbliżaniem się do wykonania musi zmniejszać się dopuszczalna dystorsja, a reprezentacja powinna stawać się coraz bardziej typowana, kanoniczna i deterministyczna. To naturalnie prowadzi od swobodnej inferencji LLM do ActionSpec, walidacji jednostek i granic, runtime admission, wykonania, niezależnej obserwacji oraz reconciliacji.

Otrzymujemy w ten sposób ogólniejszą zasadę konstrukcyjną:

```text
im dalej od efektu:
większa swoboda semantyczna
większa probabilistyka
większa eksploracja
większy dopuszczalny błąd reprezentacji

im bliżej efektu:
mniejsza przestrzeń znaczeń
mniejsza dopuszczalna dystorsja
większa kanonizacja
większy determinizm
```

Dlatego metaarchitektura AGI nie powinna być pojedynczym modelem maksymalizującym długość i szczegółowość swojej reprezentacji świata. Powinna być systemem **wielokrotnie zmieniającym rozdzielczość poznawczą**. Raz rozwija problem do szerokiej przestrzeni latentnej, następnie ścina ją przez relewancję; ponownie rozwija kontrhipotezy tam, gdzie niepewność pozostaje wysoka; normalizuje język tam, gdzie wieloznaczność staje się niebezpieczna; a przed działaniem sprowadza wynik do minimalnej, kanonicznej reprezentacji efektu.

W tym właśnie miejscu szum, błąd i semantyka spotykają się w jednym mechanizmie. **Błąd kontrolowany jest ceną kompresji, kompresja jest mechanizmem redukcji złożoności, a relewancja określa, który błąd można zaakceptować.** Scaffolding staje się więc operatorem zarządzającym tą granicą pomiędzy pełną przestrzenią możliwości a minimalną reprezentacją wystarczającą do następnej decyzji.

To nie dowodzi jeszcze powstania AGI. Formułuje jednak falsyfikowalną zasadę jej budowy: system bardziej ogólny powinien potrafić dynamicznie dobierać reprezentację i poziom dopuszczalnej dystorsji do celu, zamiast wykonywać każdą inferencję na maksymalnie bogatym stanie. Jeżeli po wprowadzeniu semantycznych operatorów równoważności, relewancji i kompresji system przy tej samej jakości decyzji redukuje koszt inferencji, liczbę rozwijanych hipotez, komunikację międzyagentową i rozgałęzienie planowania, teza zyskuje empiryczne potwierdzenie. Jeżeli redukcja powoduje systematyczną utratę zmiennych koniecznych do poprawnej decyzji, zostaje sfalsyfikowana dla danego operatora i danego budżetu `ε`.

W takim ujęciu AGI staje się nie „modelem, który wie wszystko”, lecz **architekturą, która potrafi matematycznie decydować, czego w danym momencie nie musi reprezentować**. To właśnie jest fundamentalna funkcja scaffolding: nie dostarczanie większej ilości tekstu modelowi, lecz sterowanie przejściami pomiędzy kodem, znaczeniem, szumem, przestrzenią latentną, pragmatyką celu i kanoniczną decyzją. W systemach botów, rojów i dronów taka kontrola nie jest dodatkiem optymalizacyjnym. Jest warunkiem uniknięcia eksplozji kombinatorycznej.

## Bibliografia

1. Unicode Consortium, *Unicode Normalization Forms* oraz *Unicode Security Mechanisms*.
2. Sennrich R., Haddow B., Birch A., *Neural Machine Translation of Rare Words with Subword Units*, ACL 2016.
3. Vaswani A. et al., *Attention Is All You Need*, 2017.
4. Tishby N., Pereira F., Bialek W., *The Information Bottleneck Method*, 2000.
5. Stanford EE276, *Lossy Compression & Rate Distortion Theory*.
6. Farquhar S. et al., *Detecting hallucinations in large language models using semantic entropy*, Nature 630, 2024.
7. Wilson D., Sperber D., prace dotyczące Relevance Theory i architektury poznawczej.
8. Tay Y. et al., *Efficient Transformers: A Survey*.
9. Chai Y. et al., *Tokenization Falling Short: On Subword Robustness in Large Language Models*, Findings of EMNLP 2024.
