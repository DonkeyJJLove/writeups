# HCL 4.3.3 — integralność publikacji i korekta eksportu CSV

[Writeup wynikowy](./SEMANTIC_SCAFFOLDING_WRITEUP.md) · [Opis badania](./README.md) · [Artefakty](./artifacts/README.md)

**Data kontroli:** 3 października 2026. **Wersja źródłowa:** `58383e874d0f684bfe2e290584fb4138f367c1b4`. **Zakres:** kontrola istniejących plików publikacyjnych, nie nowe uruchomienie badania ani niezależna replikacja inferencji.

## Ustalony problem

W tej wersji repozytorium kopia `artifacts/trials.csv` miała 10 brakujących separatorów między rekordami. Standardowy parser CSV odczytywał 10 230 rekordów zamiast 10 240, a dziesięć sklejonych wierszy miało po 77 pól zamiast 39. Różnica rozmiaru względem oryginału wynosiła 11 bajtów; poza separatorami dotyczyła również końcowego znaku nowej linii. Po usunięciu znaków CR/LF z obu plików ich pozostałe bajty były identyczne. To błąd reprezentacji kopii publikacyjnej, nie brak dziesięciu wyników w źródłowym badaniu. Nie ustalono tutaj, która wcześniejsza operacja wprowadziła błąd.

Oryginał [runs/study_20261002-122125/study/trials.csv](./hcl_final_4_3/runs/study_20261002-122125/study/trials.csv) zawierał 10 240 unikalnych identyfikatorów epizodów i 39 pól w każdym rekordzie. Jego agregaty odpowiadały [końcowemu summary.json](./hcl_final_4_3/runs/study_20261002-122125/study/summary.json). Źródłowe i publikacyjne podsumowania JSON były równe po parsowaniu.

## Wykonana korekta

Publikacyjny CSV zastąpiono dokładnym obiektem Git istniejącej tabeli źródłowej. Nie rekonstruowano wyników na podstawie opisu, nie przeliczano gradera i nie generowano nowych odpowiedzi modelu. Zawartość `runs/`, `results/`, `STUDY_STATE*.json`, kodu instrumentu, zamrożonych polityk oraz źródłowego `summary.json` pozostała bez zmian.

```text
SHA-256 wcześniejszego artifacts/trials.csv:
31566811ed24dd968ed15de76d757642fd723f6328b17c9d0a978031df397077

SHA-256 oryginalnego i przywróconego trials.csv:
fc6c591a57f83e4f819872fd65ad9327573678844f2fd2055b95cec7af8de68a

Rekordy po korekcie: 10 240
Unikalne trial_id:   10 240
Kolumny:            39
Bloki seeda:        256
Epizody na ramię:   5120
```

## Co sprawdzono

Kontrola obejmuje identyczność bajtową obu CSV, zgodność podsumowań JSON, kompletność 256 bloków, sparowanie ramion, dziesięć rodzin zadań, pary kontrfaktyczne, główne agregaty binarne, liczbę wywołań, sumy tokenów, mianowniki prób decyzyjnych i zadań `solvable`, średnie kontrastów oraz liczby wins/losses/ties. Walidator odrzucił wcześniejszą uszkodzoną kopię w teście regresyjnym. Maszynowy zapis kontroli znajduje się w [artifacts/publication_validation.json](./artifacts/publication_validation.json).

Bezpieczne sukcesy pozostają niezmienione: `author_raw = 1102/5120`, `strong_control = 351/5120`. W podzbiorze `solvable` są to odpowiednio `530/3840` i `216/3840`. Nie zmienia się też formalny werdykt `CONTRADICTED_SAFETY_OR_UTILITY_IN_SCOPE`.

Kontrolę można powtórzyć z katalogu głównego repozytorium, używając Pythona 3.10 lub nowszego i wyłącznie biblioteki standardowej:

```bash
python badania/heuristic-causal-lab-final-4.3/validate_publication.py
```

Skrypt niczego nie zapisuje i nie łączy się z modelem. Przypięta suma SHA-256 dotyczy bajtów Git z LF; walidator dopuszcza konwersję CRLF w kopii roboczej Git for Windows wyłącznie na potrzeby sprawdzenia tej sumy. Plik źródłowy i eksport muszą nadal być identyczne bajt w bajt między sobą. Zwraca JSON `PASS` albo kończy się błędem. Przedziały bootstrapowe są odczytywane z opublikowanego podsumowania; ta kontrola ich ponownie nie estymuje. Zapisany audyt badania `audit.json` i kontrola publikacyjna są odrębnymi artefaktami. Żaden z nich nie jest niezależną certyfikacją instytucjonalną.
