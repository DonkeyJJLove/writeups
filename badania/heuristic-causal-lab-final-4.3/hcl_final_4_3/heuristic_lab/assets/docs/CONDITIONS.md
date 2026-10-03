# Zamrożone warianty tekstu

## author_raw

`policies/author_raw.txt` to dokładny wewnętrzny fragment `[STRUKTURA]` z dostarczonego pliku. `sources/original_compiler_input.txt` zachowuje pełne bajty oryginału. `sources/provenance.json` wskazuje ekstrakcję i sumy SHA-256. Wariant główny nie otrzymuje dodatków o tym, jak rozwiązać konkretną rodzinę benchmarku.

Materiał zawiera anegdoty i twierdzenia, których prawdziwości tu nie weryfikowano. Są bodźcem eksperymentalnym, nie przesłankami prawdziwości klucza odpowiedzi. Oryginalny plik urywał się w ETAPIE 5; nie dopisano brakującej treści źródłowej.

## strong_control

Aktywny baseline zawiera normalne zalecenia dokładnego czytania, planu, sprawdzania, porównania metod, kontroli założeń i granic danych. Jest wyrównany liczbą znaków przez jawne neutralne dopełnienie. Nie jest to kontrola „model bez instrukcji”.

## compiled

Siedem jawnych sekcji reinterpretacji: referent, pochodzenie, stan, odzyskiwanie, kompozycja, transformacja i mandat do twierdzenia. Tekst napisał asystent. Przypisanie każdej sekcji i jej treści jest w `sources/compiled_sections.json`. Nie wolno nazywać go literalnym tekstem autora ani wynikiem automatycznej kompilacji.

## shuffled_words

Te same słowa źródłowe w pseudolosowej kolejności. To kontrola leksykalna, nie doskonałe placebo. Zmienia również płynność, składnię, zasięg negacji i długość tokenową. Zwycięstwo nad tą kontrolą nie wystarcza do głównego wniosku.

## Ablacje

`without_state`, `without_provenance`, `without_recovery` usuwają odpowiednią sekcję kompilacji, uzupełniając długość neutralnym tekstem. Dotyczą mechanizmów ręcznej interpretacji, nie chirurgicznego usunięcia „semantyki” z oryginalnej narracji. Ich porównania są eksploracyjne, jeśli nie zostały osobno zadeklarowane jako główne przed pomiarem.

## Operatory, które rzeczywiście można badać

Zmiana referenta/relacji/roli ujawnia się w poprawnym traktowaniu danych i wyborze narzędzia. M_repr i M_compress mają parametryzowane reprezentacje. M_source/M_trust są mierzone przez pochodzenie i mandat. M_error/M_adv przez reakcje na odrzucone transformacje. M_meta to decyzje samego modelu w pętli, nie heurystyczna funkcja rodziny napisana w Pythonie. Nie każdy operator z wcześniejszej rozmowy ma osobny, wyizolowany punkt końcowy.

Zadania kontrfaktyczne nie są testem „prawa 2PI”. Testy metamorphic w `tests/` sprawdzają programowe zachowanie referenta przy odwracalnej zmianie danych. Nie nazywamy ich dowodem stabilności modelu ani teorią matematyczną 2PI.
