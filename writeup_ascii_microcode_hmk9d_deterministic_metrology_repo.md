# Deterministyczna metrologia strukturalna dla LLM: ASCII Microcode + HMK‑9D jako warstwa kontrolna i regresyjna

## Abstrakt

W praktycznych zastosowaniach dużych modeli językowych (LLM) stabilność procesu wytwarzania tekstu jest równie ważna jak „jakość semantyczna” odpowiedzi. Systemy produkcyjne potrzebują mechanizmów, które pozwalają odróżnić zmianę znaczenia od zmiany stylu, a fluktuacje modelu od zmian w danych wejściowych. Ten write‑up opisuje podejście „deterministycznej metrologii strukturalnej”, w którym odpowiedź LLM jest formatowana jako minimalny, parsowalny mikrokod ASCII, a następnie mapowana do wektora stanu HMK‑9D (AX/LENS/MT). Kluczowa obserwacja jest prosta: jeżeli skorer opiera się wyłącznie o cechy strukturalne (np. rozkład tagów), to identyczna struktura może dać identyczny wektor, nawet gdy treść jest inna. Zamiast traktować to jako błąd, traktujemy to jako celową własność warstwy regresyjnej, ułatwiającej testy, porównania między wątkami i archiwizację kroków Δ w mozaice.

## 1. Wprowadzenie: problem niedeterministycznej generacji i potrzeba „warstwy pomiarowej”

LLM są użyteczne, bo kompresują i rekonstruują znaczenie, ale ich inferencja bywa wrażliwa na parametry próbkowania, wersję modelu, a czasem nawet na zmienność infrastruktury. W dokumentacji usług chmurowych wprost podkreśla się, że „reproducible output” jest strategią best‑effort, a deterministyczne powtórzenie odpowiedzi nie jest gwarantowane w każdych warunkach (np. po zmianach infrastruktury lub aktualizacjach backendu).

Jeżeli zatem traktujemy odpowiedź LLM jako artefakt produkcyjny (log, raport, commit do repozytorium, wniosek audytowy), to potrzebujemy rozdzielenia dwóch warstw. Pierwsza to warstwa semantyczna: co model „powiedział” i czy da się to uzasadnić/zweryfikować. Druga to warstwa metrologiczna: jaką strukturę i jaką klasę epistemiczną przypisał elementom wypowiedzi, ile było pytań, ile ostrzeżeń, ile decyzji. W warstwie metrologicznej nie trzeba rozumieć języka; trzeba mieć deterministyczny format.

## 2. Model: trzy warstwy artefaktu (powierzchnia – ukryta orientacja – mozaika)

W ujęciu ASCII Microcode artefakt odpowiedzi można opisać warstwowo. W warstwie powierzchniowej znajdują się linie mikrokodu (jawny, parsowalny zapis). W warstwie „ukrytej” znajduje się orientacja 9D, traktowana jako wektor stanu procesu, który ma być wyliczalny na podstawie artefaktu. W warstwie mozaikowej odpowiedź jest kafelkowana w jednostki Δ, które można archiwizować, porównywać i łączyć w większe struktury.

Wektor stanu 9D (T,S,R,E,I,F,A,P,D) jest formalnym zapisem „stanu” w chwili t, a nie opisem świata. T (czas/rytm), S (sens), R (relacja), E (energia poznawcza), I (tożsamość), F (funkcja/mandat), A (abstrakcja, czyli skala chunkowania), P (przewidywanie) oraz D (decyzja jako commit) tworzą stabilny język do porównywania kroków procesu. W materiale projektowym zapisano to wręcz jako relację funkcyjną: znak końcowy Z ma być funkcją sygnału wejściowego S i dziewięciu wymiarów kompresji.

## 3. Mikrokod jako DSL: kontrolowany format, jawna klasa epistemiczna, parsowalność

Minimalny mikrokod jest celowo „ubogi”: opiera się o kilka klas linii oznaczonych tagiem i prostą składnię „TAG SP ID SP TEKST”. To pozwala pisać parser bez zgadywania i minimalizuje ryzyko niejawnych „kanałów bocznych” (np. znaczenia przemycanego przez markdown, nagłówki, formatowanie). Ta decyzja jest spójna z klasyczną intuicją informatyczną: znak nie jest ozdobą, tylko nośnikiem sygnału, który komputer potrafi jednoznacznie rozpoznać i przetworzyć.

Formalizacja składni jest możliwa wprost w BNF/EBNF, co czyni mikrokod DSL‑em (domain‑specific language) dla odpowiedzi LLM. Przykładowa gramatyka (BNF) dla tokenów i linii jest zdefiniowana w materiale referencyjnym i pokazuje, że „linia” jest obiektem formalnym, a nie tekstem dowolnym.

Kluczowa własność epistemiczna w tym schemacie jest następująca: klasa linii wynika z tagu, a nie z tonu czy treści. Innymi słowy, to tag determinuje, czy dana linia jest „faktem roboczym”, „kontekstem”, „ryzykiem”, „pytaniem” albo „wnioskiem/decyzją”. Ten zabieg daje dwie rzeczy naraz: kontrolę nad formatem oraz możliwość czystego, deterministycznego liczenia na warstwie struktury.

## 4. Deterministyczny skorer strukturalny: od tagów do HMK‑9D

### 4.1. Intuicja i interpretacja wyników

Skorer strukturalny nie próbuje oceniać prawdziwości zdań. Liczy wyłącznie cechy powierzchniowe, które są dostępne bez NLP: rozkład tagów, gęstość linii, udział pytań, ostrzeżeń i decyzji. Taka metryka nie jest „empirią świata”; jest empirią odpowiedzi jako artefaktu.

W praktyce oznacza to, że dwa różne teksty, które mają identyczną strukturę mikrokodu (ten sam rozkład tagów i podobną gęstość linii), mogą dać identyczny wektor HMK‑9D. To wyjaśnia zjawisko obserwowane w wynikach: w różnych wątkach potrafią pojawiać się takie same AX/LENS/MT, mimo że treść „w środku” jest inna. W metrologii strukturalnej nie jest to błąd; to sygnał, że struktura procesu była podobna.

### 4.2. Rekonstrukcja rozkładu tagów z wektora (dowód‑przykład)

Jeżeli w danym kroku Δ uzyskano przykładowo:
`AX.T = 0.75`, `AX.S = 0.33`, `AX.R = 0.11`, `AX.P = 0.44`, `AX.D = 0.17`,
to przy założeniu skorera opartego o liczenie tagów można odtworzyć liczności linii w sposób czysto algebraiczny.

Z `AX.T = 0.75` wynika łączna liczba linii mikrokodu równa 9 (bo 0.75 = 9/12 przy typowej normalizacji „gęstości kroku”). `AX.R = 0.11` odpowiada 1/9, więc linie kontekstu `~~` wystąpiły raz. `AX.S = 0.33` odpowiada 3/9, czyli (fakt + kontekst) to trzy linie, a zatem faktów `==` było dwie linie. `AX.P = 0.44` odpowiada 4/9, czyli pytań `??` były cztery linie. Skoro całkowita liczba linii to 9, pozostają dwie linie: jedna ryzyka `!!` i jedna decyzji/wniosku `>>`, co jest spójne z `AX.D ≈ (1 + 0.5)/9 = 0.17` w typowej definicji, gdzie ryzyko częściowo „ciąży” na decyzji.

Otrzymany rozkład (==:2, ~~:1, ??:4, !!:1, >>:1) jest weryfikowalny bez czytania treści. To jest sedno „deterministycznej warstwy metrologicznej”: liczby są kontraktem pomiaru struktury, a nie opisem świata.

## 5. Powiązanie z nowoczesnymi praktykami LLM: constrained generation i structured outputs

Wdrożenia LLM w coraz większym stopniu opierają się o wymuszanie struktury wyjścia (np. JSON zgodny ze schematem) oraz walidowanie go po stronie aplikacji. Mechanizmy typu Structured Outputs pozwalają deklarować format i wymagać zgodności odpowiedzi z JSON Schema, co redukuje liczbę błędów parsowania i ułatwia automatyzację.

ASCII Microcode pełni analogiczną funkcję, ale w bardziej „ludzkiej” i edytowalnej warstwie: zamiast JSON, system wymusza proste tagi, stałą składnię linii i rygor wyjścia (np. „bez markdown”). Dzięki temu mikrokod nadaje się do ręcznego czytania, ręcznej edycji i repozytoryjnego versioningu, a jednocześnie zachowuje własności formalne przydatne maszynie.

W praktyce sensowna architektura jest hybrydowa. Mikrokod jest formatem pierwotnym dla człowieka i narzędzi tekstowych, a JSON (lub inna reprezentacja) może być formatem wtórnym dla integracji z systemami. Z punktu widzenia kontroli jakości istotne jest to, że obie warstwy są parsowalne i walidowalne, a pomiar HMK‑9D jest deterministyczny.

## 6. Metodologia implementacji: pipeline dla repozytorium i testów regresji

Minimalny pipeline produkcyjny składa się z czterech etapów, które da się wdrożyć bez ciężkiej infrastruktury.

Najpierw generacja: prompt wymusza tryb STRICT i format mikrokodu (bez markdown, bez ozdobników), tak by odpowiedź była „danymi”, a nie „prezentacją”. Następnie walidacja: parser sprawdza, czy każda linia jest zgodna z gramatyką i czy identyfikatory są unikalne. Trzecim etapem jest pomiar: skorer wylicza wektory AX/LENS/MT deterministycznie z cech strukturalnych. Czwartym etapem jest archiwizacja: wynik (mikrokod + wektor + hash wejścia) staje się kafelkiem mozaiki i może być porównywany w czasie.

W samym HMK‑9D mosty (LENS.*) są traktowane jak operatory procesu, a „Próg–Przejście” jest interpretowany jako commit do historii, czyli moment przejścia od analizy do działania. To naturalnie spina się z repozytoryjnym trybem pracy: każdy krok Δ jest artefaktem, który ma strukturę, metrykę i historię.

Poniżej minimalny pseudokod (czytelny jako logika, nie jako gotowa biblioteka):

```text
input: prompt, response_text

1) lines = parse_microcode_lines(response_text)  # (tag, id, text)
2) validate(grammar_ok && unique_ids && output_policy_ok)
3) counts = count_tags(lines, tags={==,~~,??,!!,>>})
4) AX = deterministic_AX(counts)
5) LENS = deterministic_LENS(AX, counts)
6) MT = deterministic_MT(counts)
7) snapshot = {hash(prompt), lines, AX, LENS, MT, timestamp}
8) store(snapshot)  # mozaika Φ: archiwum kroków Δ
```

## 7. Dyskusja: co ta metrologia daje, a czego nie daje

Metrologia strukturalna jest „twarda” tam, gdzie LLM są „miękkie”. Daje możliwość stabilnego porównywania wątków i iteracji, bo liczy to, co da się policzyć bez interpretacji: strukturę. Może działać jak czujnik jakości procesu: rosnąca gęstość `??` sygnalizuje niejednoznaczność polecenia, rosnący udział `!!` sygnalizuje narastające ryzyko, a `>>` – domykanie decyzji i przejście przez próg.

Jednocześnie metrologia strukturalna nie odpowiada na pytanie „czy to prawda?”. Nie wykryje halucynacji faktograficznej, jeżeli model nada jej tag `==`. To jest świadomy kompromis: oddzielamy pomiar struktury od oceny treści. W produkcji oznacza to konieczność drugiej warstwy walidacyjnej (fact‑checking, retrieval, testy jednostkowe, human review) oraz rygorystycznych zasad, kiedy wolno użyć tagu faktu.

Warto też rozumieć „cechę uboczną” skorera tag‑count: metrykę da się „ogrywać”, jeżeli ktoś świadomie manipuluje strukturą (np. mnoży `??` lub usuwa `!!`). To kolejny argument, by traktować HMK‑9D jako metrykę procesu, a nie jako metrykę prawdy.

## 8. Wnioski

Połączenie ASCII Microcode i HMK‑9D tworzy pragmatyczny interfejs między generacją LLM a inżynierią procesu. Mikrokod daje parsowalną powierzchnię, HMK‑9D daje formalny wektor stanu, a deterministyczny skorer daje stabilny sygnał regresyjny. W środowisku, w którym sama generacja jest potencjalnie niedeterministyczna, taka warstwa pomiarowa pozwala odzyskać kontrolę: porównywać kroki Δ, wykrywać zmiany struktury, archiwizować decyzje i wprowadzać świadome „Plan–Pauza” w pipeline.

Najważniejsza praktyczna lekcja z obserwowanych wyników brzmi: jeżeli wyniki „powtarzają się” między wątkami, to najpierw trzeba sprawdzić, czy powtarza się struktura, a nie czy „model zgłupiał”. Metrologia strukturalna ma być stabilna; to semantyka ma być zmienna, dyskutowana i weryfikowana.

## 9. Źródła (linki)

```text
Repo / writeups (materiał referencyjny użytkownika):
- https://github.com/DonkeyJJLove/writeups/blob/master/ascii-ontologiczny-microcode-ai_czesc1-fundament-znak-semantyka.md
- https://github.com/DonkeyJJLove/writeups/blob/master/ascii-microcode-ai_part2.md
- https://github.com/DonkeyJJLove/writeups/blob/master/ascii-microcode-ai_part3.md

Dokumentacja LLM – deterministyczność i formatowanie:
- https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/reproducible-output
- https://platform.openai.com/docs/guides/structured-outputs
```

## 10. Stopka microcode (do wklejenia pod artykułem)

```text
== SRC1 github_writeups_fundament_znak
== SRC2 github_writeups_microcode_part3_bnf_3layers
~~ CTX1 Metrologia_strukturalna:_mierzymy_format_i_role_linii,_nie_prawde_semantyczna
!! RSK1 Skorer_tag_counts_jest_stabilny_regresyjnie,_ale_slepy_na_halucynacje_faktograficzne
>> DEC1 Uzywaj_HMK9D_do_porownywania_krokow_Δ,_a_prawdziwosc_weryfikuj_osobno
Plan–Pauza · Rdzeń–Peryferia · Cisza–Wydech · Wioska–Miasto · Ostrze–Cierpliwość · Locus–Medium–Mandat · Human–AI · Próg–Przejście · Semantyka–Energia‡
```
