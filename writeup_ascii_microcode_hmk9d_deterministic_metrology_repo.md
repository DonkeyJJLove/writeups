# Deterministyczna metrologia strukturalna dla LLM: ASCII Microcode + HMK-9D jako warstwa kontrolna, regresyjna i audytowalna

## Abstrakt

W praktycznych wdrożeniach dużych modeli językowych (LLM) stabilność procesu wytwarzania tekstu bywa równie krytyczna jak jakość semantyczna odpowiedzi. Ten sam prompt potrafi dać odpowiedzi o innej strukturze, a w usługach sieciowych do zmienności próbkowania dochodzą zmiany wersji modelu, backendu i infrastruktury serwującej. Niniejsza praca proponuje rozdzielenie „miękkiej” generacji od „twardego” pomiaru: odpowiedź jest formatowana jako minimalny, parsowalny mikrokod ASCII (ASCII Microcode), a następnie mapowana deterministycznie do wektora stanu HMK-9D oraz metryk pomocniczych. Kluczowa teza brzmi: jeżeli inferencja bywa niedeterministyczna, to warstwa metrologiczna powinna być deterministyczna, jawna i odporna na „literackość” wyjścia. Dowody w postaci dwóch bloków ODP pokazują, że identyczne wektory HMK-9D mogą występować w różnych wątkach przy różnej treści, jeżeli skorer opiera się na tag_counts, a nie na semantyce, co jest cechą (a nie błędem) metrologii strukturalnej.

## Słowa kluczowe

LLM; deterministyczność; metrologia strukturalna; structured outputs; constrained decoding; DSL; audyt; regresja; ASCII Microcode; HMK-9D.

## 1. Wprowadzenie: dlaczego metrologia LLM nie może być literacka

Inżynieria systemów uczy, że pomiar jest tak dobry, jak jego jednoznaczność oraz odporność na styl prezentacji. W przypadku LLM pojawia się napięcie: modele są użyteczne, bo potrafią wygenerować wiele poprawnych realizacji tej samej intencji, ale ta sama cecha utrudnia kontrolę procesu, porównywanie iteracji, automatyzację testów, a w konsekwencji także audyt i odpowiedzialność za decyzje. Z perspektywy operacyjnej odpowiedź LLM jest artefaktem pracy: bywa logiem, raportem, wynikiem analizy, wkładem do repozytorium lub materiałem do decyzji.

W praktyce produkcyjnej potrzebny jest podział na dwie warstwy. Warstwa semantyczna dotyczy treści: co model twierdzi, czy ma to pokrycie w źródłach, czy występują halucynacje, czy uzasadnienie jest poprawne. Warstwa metrologiczna dotyczy procesu: ile w odpowiedzi jest faktów roboczych, ile kontekstu, ile ryzyk, ile pytań, czy nastąpiło domknięcie wnioskiem; jakie jest „zagęszczenie” kroku i czy struktura zmienia się między iteracjami. Metrologia w tym ujęciu nie ma być „mądrzejsza od świata”; ma być stała, policzalna i audytowalna.

## 2. Założenie główne: twarda warstwa pomiarowa dla miękkiej generacji

Teza dokumentu jest celowo prosta: jeżeli generacja jest probabilistyczna, to pomiar powinien być deterministyczny. Nie oznacza to, że cały system staje się deterministyczny; oznacza to, że stabilny sygnał kontrolny (regresyjny) jest liczony z tego, co w pełni kontrolowalne: z formatu odpowiedzi i z jawnej klasyfikacji epistemicznej linii.

W takim ujęciu metrologia strukturalna nie próbuje „sprawdzać prawdy”. Ona mierzy odpowiedź jako artefakt: rozkład klas linii, gęstość, udział pytań, udział ostrzeżeń, obecność domknięcia decyzją lub wnioskiem. Dzięki temu metryka jest stabilna względem stylu wypowiedzi; jest też odporna na „ładne zdania”, bo w warstwie pomiarowej nie liczy się retoryka, tylko role linii.

## 3. ASCII Microcode jako DSL: tag determinuje klasę epistemiczną

ASCII Microcode jest traktowany jako domenowy język opisu odpowiedzi (DSL), w którym każda linia ma stałą strukturę: tag, identyfikator, a następnie tekst. W materiałach źródłowych format ten jest wyrażony wprost jako „TAG SP ID SP TEKST”, gdzie SP oznacza spację. Celem jest to, aby parser mógł działać bez zgadywania: linia jest obiektem formalnym, a nie „akapitowym stylem”.

Kluczowa własność epistemiczna jest następująca: klasa linii wynika z tagu, a nie z tonu lub treści. Na materiale dowodowym oraz w dokumentach referencyjnych występuje zestaw tagów, które wprost kodują role epistemiczne: „==” oznacza fakt roboczy; „~~” oznacza kontekst; „!!” oznacza ryzyko lub ostrzeżenie; „??” oznacza pytanie; „>>” oznacza wniosek lub decyzję (domknięcie); „::” oznacza doprecyzowanie przyklejone do poprzedniej klasy i nie zmienia klasy epistemicznej. Jednocześnie dopuszcza się linie meta (nagłówki, adnotacje, bloki typu @/; lub jawnie oznaczone komentarze), które są poza ontologią mikrokodu i powinny zostać pominięte przez parser, aby nie tworzyć bocznych kanałów znaczenia.

W efekcie mikrokod jest jednocześnie czytelny dla człowieka i formalny dla maszyny. W porównaniu do wymuszania czystego JSON mikrokod zachowuje kompatybilność z repozytoryjnym trybem pracy na plikach tekstowych, ułatwia diffowanie, ręczną korektę oraz pracę w trybie „chunk–chunk” bez utraty własności parsowalnych.

## 4. HMK-9D jako wektor stanu procesu: interpretacja operacyjna

Wektor HMK-9D jest tu rozumiany jako zapis stanu procesu w kroku Δ, a nie jako opis świata. Metryki AX.* opisują orientację kroku w dziewięciu wymiarach procesu; mosty LENS.* są operatorami interpretacji napięć między parami; metryki MT.* streszczają właściwości struktury, takie jak integracja, spójność czy gęstość. Interpretacja musi pozostać procesowa: identyczne wektory oznaczają identyczną strukturę, a nie identyczną prawdziwość.

W dowodach pojawia się dodatkowo kontrakt deterministyczności: wartości AX/LENS/MT są oznaczane jako [DET]. Jednocześnie zapisano explicite, że [DET] nie jest placeholderem, tylko zobowiązaniem do deterministycznego wyliczenia wartości albo do oznaczenia „n/a”. W praktyce oznacza to rygor: liczby nie mogą być „dla ozdoby” i nie mogą pozostawać nieokreślone, jeżeli specyfikacja obiecuje deterministyczny wynik.

## 5. Materiał dowodowy: dwa bloki ODP i identyczne wyniki HMK-9D

Podstawą analizy jest materiał dowodowy w postaci dwóch bloków ODP udostępnionych jako linki do rozmów. Oba bloki zawierają sekcje [FAKTY], [KONTEKST], [RYZYKO], [PYTANIA], [UZASADNIENIA / WNIOSKI], a następnie emitują identyczne wektory HMK-9D, w tym identyczne wartości AX.*, LENS.* i MT.*. Różnica dotyczy treści w polu tekstowym pytań: w pierwszym bloku pytania (RQ1–RQ3) zawierają odpowiedzi i doprecyzowania, w drugim bloku pytania deklarują brak treści wejściowej i brak możliwości odpowiedzi merytorycznej.

Wyjaśnienie jest wprost zaszyte w samych dowodach. W obu przypadkach pojawia się stwierdzenie, że wartości [DET] pochodzą z deterministycznego fallbacku SCORER_SPEC_LOCAL_DET na podstawie tag_counts dla danego [ODP]. Oznacza to, że skorer jest funkcją rozkładu tagów, a nie funkcją treści w polu TEKST. Jeżeli zatem oba bloki mają identyczny rozkład tagów, wynik metrologii będzie identyczny, nawet gdy treść będzie różna.

Na tej podstawie można odtworzyć rozkład tagów zgodny z wartościami AX, przyjmując normalizację względem liczby linii mikrokodu N w kroku Δ. Wartość AX.R≈0.11 odpowiada 1/9, co wskazuje na jedną linię kontekstu „~~”. Wartość AX.S≈0.33 odpowiada 3/9, co wskazuje, że suma (fakty+kontrastowo-kontekst) wynosi trzy linie; skoro kontekst to jedna linia, faktów roboczych „==” jest dwie. Wartość AX.P≈0.44 odpowiada 4/9, co wskazuje na cztery linie pytań „??”. Pozostają dwie linie do domknięcia całkowitej liczby linii N=9; naturalnym uzupełnieniem jest jedna linia ryzyka „!!” i jedna linia wniosku/decyzji „>>”, co jest spójne z obecnością obu klas w dowodach.

Dla czytelności rekonstrukcja może zostać zapisana w postaci prostego zestawienia:

| Tag | Rola epistemiczna | Liczność w kroku Δ |
|---|---|---:|
| == | fakt roboczy | 2 |
| ~~ | kontekst | 1 |
| ?? | pytanie | 4 |
| !! | ryzyko/ostrzeżenie | 1 |
| >> | wniosek/decyzja | 1 |
|  | suma N | 9 |

Przypadek ten jest ważny metodologicznie, bo rozdziela dwa typy powtarzalności. Powtarzalność semantyczna byłaby podejrzana, gdyby model powtarzał te same zdania. Powtarzalność metrologiczna jest pożądana, jeżeli struktura procesu jest ta sama. W tym sensie identyczne AX/LENS/MT w różnych wątkach nie dowodzą, że „model się nie zmienia”, tylko że w obu krokach Δ wymuszono podobny układ ról epistemicznych, a skorer celowo nie analizował treści.

Źródła dowodów (linki): https://chatgpt.com/share/693c732c-0780-800e-a3c3-15d8c307076b oraz https://chatgpt.com/share/693c5391-ac2c-800e-b9a1-5d4665559850.

## 6. Rekonstrukcja minimalnego skorera deterministycznego zgodnego z dowodem

Dowód nie wymaga, aby skorer był „metryką prawdy”; wymaga, aby był deterministyczną funkcją struktury. Najprostsza rodzina skorerów, która spełnia ten warunek, opiera się na wektorze liczności tagów c = (n_==, n_\~\~, n_!!, n_??, n_>>), całkowitej liczbie linii N oraz ewentualnej normalizacji gęstości względem ustalonego N_max. Wtedy część składowych można zdefiniować bezpośrednio jako udziały: AX.R = n_\~\~/N; AX.P = n_??/N; AX.S = (n_== + n_~~)/N. Studium przypadku pokazuje, że taka definicja wystarcza do uzasadnienia kilku kluczowych wartości AX jako czysto strukturalnych.

Pozostałe wymiary AX.* oraz metryki MT.* i mosty LENS.* mogą być deterministycznymi funkcjami tych samych liczności, na przykład przez łączenie udziałów (dodatkowe wagi dla ryzyka, domknięć, lub relacji między klasami) oraz przez wprowadzenie progów normalizacyjnych. Materiał dowodowy używa nazwy SCORER_SPEC_LOCAL_DET, co w praktyce można potraktować jako identyfikator specyfikacji: ten sam format i te same liczności muszą zawsze dawać ten sam wynik, a każda zmiana specyfikacji musi być wersjonowana.

Wymóg wersjonowania jest tu fundamentalny, bo warunek „porównywalności między wątkami” dotyczy nie tylko treści, ale także definicji pomiaru. Jeżeli specyfikacja scorer_spec się zmieni, identyczne tag_counts mogą mapować się na inne AX/LENS/MT. Dlatego snapshot kroku Δ powinien przenosić metadane: hash wejścia (prompt, ewentualne źródła), wersję specyfikacji, wynik parsowania, wartości metryk oraz znacznik czasu. Dopiero wtedy regresja jest procedurą, a nie intuicją.

## 7. Integracja z praktykami structured outputs i constrained decoding

Współczesne praktyki wdrożeniowe LLM coraz częściej wymuszają strukturę odpowiedzi, aby ograniczyć błędy parsowania i umożliwić automatyzację. W ekosystemie API obserwuje się rosnącą rolę structured outputs, czyli generowania odpowiedzi zgodnych ze schematem (na przykład JSON Schema), oraz constrained decoding, czyli ograniczania dekodowania do gramatyki lub zbioru dozwolonych tokenów. W tym kontekście ASCII Microcode jest wariantem struktury wyjścia, który zamiast abstrakcyjnego formatu danych daje minimalny, tekstowy DSL podporządkowany audytowi i pracy repozytoryjnej.

Te podejścia nie konkurują, lecz się uzupełniają. Structured outputs i constrained decoding są szczególnie użyteczne tam, gdzie odpowiedź ma być natychmiast konsumowana przez systemy (na przykład pipeline’y danych). ASCII Microcode jest przydatny tam, gdzie odpowiedź ma być jednocześnie archiwizowalna, czytelna, edytowalna i podatna na diff w repozytorium. W praktyce można stosować podejście hybrydowe: generować mikrokod jako format pierwotny dla człowieka oraz walidacji procesu, a następnie deterministycznie kompilować go do JSON jako formatu wtórnego dla integracji.

## 8. Pipeline repozytoryjny: od generacji do audytu

Minimalny pipeline produkcyjny nie wymaga ciężkiej infrastruktury, ale wymaga dyscypliny. Najpierw generacja: prompt wymusza tryb STRICT, stałą składnię linii oraz politykę „bez markdown” w bloku mikrokodu; celem jest to, by odpowiedź była danymi, a nie prezentacją. Następnie walidacja: parser sprawdza gramatykę, dopuszczalne tagi, unikalność identyfikatorów, oraz to, czy linie meta nie przenikają do ontologii mikrokodu. Dalej pomiar: skorer wylicza AX/LENS/MT deterministycznie z cech strukturalnych, w sensie „ten sam mikrokod daje ten sam wynik”. Na końcu archiwizacja: snapshot łączy hash wejścia, wersję specyfikacji, wynik parsowania i metryki, dzięki czemu każdy krok Δ jest w repozytorium porównywalny w czasie.

Poniższy pseudokod pokazuje istotę procedury bez przywiązywania się do konkretnej biblioteki:

```text
input: prompt, response_text

1) lines = parse_microcode_lines(response_text)      # (tag, id, text)
2) validate(grammar_ok && unique_ids && policy_ok)   # brak markdown w bloku, tagi dozwolone
3) counts = count_tags(lines, tags={==,~~,??,!!,>>})
4) AX = deterministic_AX(counts, scorer_spec)
5) LENS = deterministic_LENS(AX, counts, scorer_spec)
6) MT = deterministic_MT(counts, scorer_spec)
7) snapshot = {hash(prompt), scorer_spec, lines, AX, LENS, MT, timestamp}
8) store(snapshot)                                    # mozaika Φ: archiwum kroków Δ
````

Warto tu podkreślić sens operacyjny metryk: rosnący udział „??” sygnalizuje niejednoznaczność polecenia lub brak danych; rosnący udział „!!” sygnalizuje narastające ryzyko; zanik „>>” sygnalizuje brak domknięcia i potencjalną niezdolność do przejścia przez próg decyzyjny. Jest to kontrola procesu, nie kontrola prawdy.

## 9. Ograniczenia i ryzyka: dlaczego metrologia strukturalna nie zastępuje weryfikacji treści

Metrologia strukturalna daje stabilność tam, gdzie semantyka jest zmienna, ale ma świadome ograniczenia. Jest ślepa na halucynacje faktograficzne: jeżeli model oznaczy nieprawdziwą tezę tagiem „==”, metrologia nie wykryje błędu, bo nie analizuje prawdziwości. Metrykę można również „ograć”, jeśli ktoś celowo manipuluje strukturą, na przykład mnożąc pytania lub unikając ostrzeżeń. Istnieje też ryzyko dryfu protokołu: jeżeli system przestaje rygorystycznie egzekwować zasady (unikalność ID, brak markdown w bloku, rozdział meta od ontologii), metrologia traci sens, bo przestaje mierzyć to, co miała mierzyć.

Konsekwencja wdrożeniowa jest jasna: metrologia strukturalna musi być połączona z drugą warstwą walidacji treści. W zależności od domeny może to być retrieval z cytowaniem źródeł, testy jednostkowe, walidacja regułowa, przegląd ekspercki, albo kontrola krzyżowa przez niezależny system. ASCII Microcode i HMK-9D mają zapewniać czujnik procesu; prawda wymaga osobnego toru.

## 10. Wnioski

Połączenie ASCII Microcode i HMK-9D tworzy pragmatyczny interfejs między generacją LLM a inżynierią procesu. Mikrokod daje parsowalną powierzchnię i jawne klasy epistemiczne; HMK-9D daje formalny wektor stanu kroku Δ; deterministyczny skorer daje stabilny sygnał regresyjny, który można archiwizować i porównywać w repozytorium. Studium przypadku z materiału dowodowego pokazuje, że identyczne wyniki metrologii mogą pojawić się w różnych wątkach mimo różnej treści, jeżeli struktura jest taka sama; nie jest to wada, lecz oczekiwany efekt rozdzielenia treści od pomiaru. W praktyce oznacza to, że kontrola jakości powinna być dwutorowa: metrologia strukturalna do kontroli procesu oraz niezależna walidacja treści do kontroli prawdy.

## 11. Źródła i materiały referencyjne (linki)

Materiał projektu: [https://github.com/DonkeyJJLove/writeups/blob/master/ascii-ontologiczny-microcode-ai_czesc1-fundament-znak-semantyka.md](https://github.com/DonkeyJJLove/writeups/blob/master/ascii-ontologiczny-microcode-ai_czesc1-fundament-znak-semantyka.md); [https://github.com/DonkeyJJLove/writeups/blob/master/ascii-microcode-ai_part2.md](https://github.com/DonkeyJJLove/writeups/blob/master/ascii-microcode-ai_part2.md); [https://github.com/DonkeyJJLove/writeups/blob/master/ascii-microcode-ai_part3.md](https://github.com/DonkeyJJLove/writeups/blob/master/ascii-microcode-ai_part3.md).


Materiał dowodowy (bloki ODP): [https://chatgpt.com/share/693c732c-0780-800e-a3c3-15d8c307076b](https://chatgpt.com/share/693c732c-0780-800e-a3c3-15d8c307076b)

[https://chatgpt.com/share/693c5391-ac2c-800e-b9a1-5d4665559850](https://chatgpt.com/share/693c5391-ac2c-800e-b9a1-5d4665559850).


Dokumentacja dotycząca powtarzalności i struktury wyjścia: [https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/reproducible-output](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/reproducible-output); [https://platform.openai.com/docs/guides/structured-outputs](https://platform.openai.com/docs/guides/structured-outputs).

## 12. Załącznik A: minimalna stopka microcode do wklejenia pod artykułem

```text
== SRC1 github_writeups_fundament_znak
== SRC2 github_writeups_microcode_part2_grammar_tags
== SRC3 github_writeups_microcode_part3_parser_regime
== EVD1 chatgpt_share_693c53a5_0438_800e_a9f1_515b4fbd1c7d
== EVD2 chatgpt_share_693c5391_ac2c_800e_b9a1_5d4665559850
~~ CTX1 Metrologia_strukturalna_mierzy_format_i_role_linii_nie_prawde_semantyczna
!! RSK1 Metryka_tag_counts_jest_stabilna_regresyjnie_ale_slepa_na_halucynacje_faktograficzne
>> DEC1 HMK9D_uzywaj_do_porownywania_krokow_Δ_a_weryfikacje_prawdy_rob_osobno
Plan–Pauza · Rdzeń–Peryferia · Cisza–Wydech · Wioska–Miasto · Ostrze–Cierpliwość · Locus–Medium–Mandat · Human–AI · Próg–Przejście · Semantyka–Energia‡

