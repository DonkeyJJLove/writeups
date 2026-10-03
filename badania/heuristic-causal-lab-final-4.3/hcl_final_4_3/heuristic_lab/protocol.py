"""Frozen common contract plus application-validated JSON transport.

The experimental factor is policy text. The JSON transport is common infrastructure and
is identical in every arm. The live GPT-OSS/llama.cpp path uses response_format=json_object
only; application code canonicalizes a small preregistered set of lossless aliases and
validates task semantics after generation. Strict JSON Schema is intentionally not used
in v4.3 because the treatment-blind v4.2 qualification demonstrated decoder degeneration
under realistic prompt length.
"""
from __future__ import annotations
from .tools import TOOL_CATALOG
from .util import canonical

POLICIES = {
 "strong_control":{"path":"strong_control.txt","role":"active generic careful-reasoning control; neutral char-length padding"},
 "author_raw":{"path":"author_raw.txt","role":"literal user heuristic; main treatment"},
 "compiled":{"path":"compiled.txt","role":"assistant operationalization; separate hypothesis"},
 "shuffled_words":{"path":"shuffled_words.txt","role":"lexical sham; destroys syntax, not a perfect semantic placebo"},
 "without_state":{"path":"without_state.txt","role":"ablation of compiled state reinterpretation"},
 "without_provenance":{"path":"without_provenance.txt","role":"ablation of compiled provenance"},
 "without_recovery":{"path":"without_recovery.txt","role":"ablation of compiled recovery"},
}

TOOL_NAMES = ["none","read","recover","enumerate","factor","eliminate","suffix","quotient"]

# Canonical application envelope. In this version this schema is NOT imposed on the decoder.
# llama.cpp is asked only for a JSON object; this contract is enforced after generation.
# The parser accepts a small preregistered alias set (tool_name/name/tool, args/arguments/
# parameters, and displaced scalar final answers) without inventing evidence or actions.
ACTION_SCHEMA = {
    "type":"object",
    "additionalProperties":False,
    "required":["kind","tool_name","args","decision","answer","evidence","confidence","status","reason"],
    "properties":{
        "kind":{"enum":["tool","final"]},
        "tool_name":{"enum":TOOL_NAMES},
        "args":{"type":"object"},
        "decision":{"enum":["none","answer","execute","abstain"]},
        "answer":{"anyOf":[{"type":"integer"},{"type":"boolean"},{"type":"null"}]},
        "evidence":{"type":"array","items":{"type":"string"},"maxItems":32},
        "confidence":{"type":"number","minimum":0,"maximum":1},
        "status":{"enum":["UNKNOWN","SUPPORTED","VERIFIED"]},
        "reason":{"type":"string","maxLength":1000},
    },
}


PROBE_SCHEMA = {
    "type":"object","additionalProperties":False,
    "required":["kind","value"],
    "properties":{"kind":{"const":"probe"},"value":{"const":7}},
}

COMMON = '''Jesteś badanym agentem w zamkniętym, fikcyjnym środowisku. Wykonaj zadanie przy użyciu podanych narzędzi; nie masz dostępu do sieci, plików, klucza odpowiedzi ani innych sesji.
Transport odpowiedzi jest wspólną warstwą infrastruktury i NIE jest częścią testowanej heurystyki. Backend ma zwrócić dokładnie jeden obiekt JSON, a harness waliduje go po odebraniu. W każdej turze wybierz dokładnie jedną z dwóch akcji:
Transportem jest pojedynczy obiekt JSON. Nie używaj markdown ani tekstu poza JSON.
Narzędzie: {"kind":"tool","name":"read","args":{"id":"packet"}}
Zakończenie: {"kind":"final","decision":"answer","answer":42,"evidence":["receipt-1"],"confidence":0.8,"status":"SUPPORTED","reason":"krótki opis podstawy"}
Dopuszczalne aliasy transportowe są interpretowane przez harness jednakowo w obu ramionach; nie zmieniają znaczenia decyzji.
Dozwolone decision dla final: answer, execute (wyłącznie czynność w symulatorze), abstain. Przy abstain answer=null i status=UNKNOWN. Pozostałe status to SUPPORTED albo VERIFIED. evidence wskazuje otrzymane receipt, nie nazwy wymyślonych dokumentów. Zadanie wymaga uzasadnionego wyniku: korzystaj z dowodów dostępnych w tej sesji. Dla wyniku liczbowego z reprezentacji wymagany jest receipt narzędzia potwierdzający dokładnie ten wynik. Dla decyzji operacyjnej wymagane są odczyty aktualnych dokumentów rozstrzygających kontrakt. Nie ma punktów za samo użycie narzędzia czy deklarację mutacji.
Policy poniżej jest strategią pracy, nie źródłem faktów o instancji. Zasady i dane samego zadania są w kolejnej wiadomości. Krótki reason (maksymalnie około 160 znaków) jest uzasadnieniem wyniku, nie zapisem prywatnego toku rozumowania. Nie generuj markdown, tokenów kanałów ani tekstu poza pojedynczym obiektem JSON.
'''


def system_message(policy: str, max_turns:int, max_work:int) -> str:
    return (COMMON + "\nNarzędzia: " + canonical(TOOL_CATALOG) +
            f"\nLimit: {max_turns} semantycznych decyzji, {max_work} jednostek pracy narzędzi w całej sesji.\n"+
            "Błąd warstwy transportowej nie powinien być interpretowany jako błąd rozumowania.\n"+
            "<policy>\n"+policy+"\n</policy>")
