"""Presentation of an existing summary, with optional diagnostics; no regrading.

A missing confidence interval remains missing. Aggregate data do not establish
raw-transcript audit, model identity, denominators of conditional metrics or causes.
"""
from __future__ import annotations
import argparse
import html
import json
from pathlib import Path
from .util import read_json, utc

CSS='''
:root{--ink:#14283b;--muted:#526676;--accent:#087e8b;--paper:#f2f5f7;--rule:#d9e3ea;--warn:#7c4c16}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.6 system-ui,-apple-system,"Segoe UI",sans-serif}main{max-width:1120px;margin:auto;padding:36px 26px}header{background:var(--ink);color:white;padding:42px;border-radius:12px;margin-bottom:26px}header p{max-width:820px;color:#e0ebf1}h1{font-size:36px;line-height:1.18;letter-spacing:-.8px;margin:12px 0 20px}h2{font-size:23px;line-height:1.25;margin:0 0 18px}h3{font-size:17px}.eyebrow{text-transform:uppercase;letter-spacing:2px;font-size:11px;font-weight:700}.tag{font:12px ui-monospace,monospace;padding:6px 10px;border:1px solid #6b8295;border-radius:5px;display:inline-block}section{background:white;padding:28px 30px;border:1px solid var(--rule);border-radius:10px;margin-bottom:22px}p{margin:10px 0 15px}.muted,figcaption{color:var(--muted);font-size:13px}.cards{display:flex;gap:15px;flex-wrap:wrap;margin:0 0 24px}.card{flex:1;min-width:190px;border:1px solid var(--rule);background:white;padding:23px;border-radius:10px}.big{font-size:34px;line-height:1.25;display:block;letter-spacing:-.8px;font-weight:700}.unit{font-size:12px;color:var(--muted)}.notice{border-left:4px solid var(--accent);padding:14px 18px;background:#edf6f7}.caution{border-left-color:#b57b30;background:#fcf6ec;color:#664217}table{border-collapse:collapse;width:100%;font-size:14px;margin:16px 0}th{text-align:left;font-size:12px;text-transform:uppercase;letter-spacing:.35px;color:var(--muted);background:#f4f7f9}td,th{padding:11px 10px;border-bottom:1px solid var(--rule);vertical-align:top}td.num{font-variant-numeric:tabular-nums;text-align:right}pre{font-size:11px;white-space:pre-wrap;overflow-wrap:anywhere;background:#f1f4f7;padding:16px}code{font-size:.9em;overflow-wrap:anywhere}details{margin:20px 0}summary{cursor:pointer;font-weight:600}.barrow{display:flex;align-items:center;gap:15px;margin:16px 0}.barname{width:160px;font-size:13px}.track{height:24px;background:#edf1f5;flex:1}.fill{height:24px;background:var(--accent);min-width:0}.barval{width:90px;text-align:right;font-variant-numeric:tabular-nums}.metric-section{page-break-inside:avoid}.small{font-size:12px}footer{color:var(--muted);font-size:12px;padding:10px 0 25px}a{color:#087785}.num{text-align:right}.okcell{background:#e3f2ef}.badcell{background:#f7edef}.unknown{color:#8a6427}thead{display:table-header-group}tr{page-break-inside:avoid}
@media(max-width:700px){main{padding:14px}header{padding:26px}h1{font-size:29px}section{padding:20px}table{font-size:12px}.scroll{overflow-x:auto}.barname{width:105px}}
@media print{@page{size:A4;margin:16mm 15mm 18mm;@bottom-left{content:"HCL / Raport pilota";font-size:8pt;color:#526676}@bottom-right{content:counter(page);font-size:8pt;color:#526676}}body{font:10.3pt/1.5 sans-serif;background:white}main{padding:0;max-width:none}header{padding:22pt;border-radius:0;margin-bottom:16pt;break-inside:avoid}h1{font-size:28pt}h2{font-size:17pt}section{padding:14pt 16pt;border-radius:0;margin-bottom:12pt}table{font-size:9pt}th{font-size:8pt}.big{font-size:23pt}.card{min-width:110px;padding:13pt}.cards{gap:8pt}.muted,figcaption{font-size:9pt}pre{font-size:8pt}details{display:none}footer{font-size:8pt}.metric-section{break-inside:avoid}h2,h3{break-after:avoid}}
'''
LABELS={'strong_control':'Kontrola aktywna','author_raw':'Tekst autora','compiled':'Operacjonalizacja',
        'without_state':'Bez aktualizacji stanu','without_provenance':'Bez provenance','without_recovery':'Bez recovery',
        'shuffled_words':'Kontrola przetasowana'}
FAMILIES={'authority':'Uprawnienia','lineage':'Pochodzenie danych','state_update':'Aktualizacja stanu','recovery':'Odzyskiwanie obserwowalności','bounded_evidence':'Granice dowodu','global_constraint':'Ograniczenia globalne','factor_count':'Zliczanie: faktoryzacja','linear_count':'Zliczanie: algebra liniowa','suffix_count':'Zliczanie: pamięć sufiksowa','cover_count':'Zliczanie: exact cover'}

def esc(x): return html.escape(str(x))
def fmt(x,d=1): return 'brak danych' if x is None else f'{x:.{d}f}'.replace('.',',')
def rate(k,n): return None if k is None or not n else k/n

def metric_table(result):
    cols=[
        ("safe_success","Bezpieczny sukces"),
        ("task_success","Poprawny wynik"),
        ("epistemic_success","Epistemicznie poprawny"),
        ("correct_termination","Poprawne zatrzymanie"),
        ("failure_to_stop","Brak zatrzymania"),
        ("protocol_success","Poprawny protokół"),
        ("unsupported_claim","Niepoparte twierdzenie"),
        ("overabstention","Nadmierna odmowa"),
    ]
    out='<div class="scroll"><table><thead><tr><th>Ramię</th><th>Próby</th>'+''.join('<th>'+esc(label)+'</th>' for _,label in cols)+'</tr></thead><tbody>'
    for arm,r in result['arms'].items():
        n=r['trials'];out+='<tr><td><b>'+esc(LABELS.get(arm,arm))+'</b><br><code>'+esc(arm)+'</code></td><td class="num">'+str(n)+'</td>'
        for key,_ in cols:
            v=r.get(key)
            out+='<td class="num">'+('brak danych' if v is None else f'{v}/{n} ({fmt(100*v/n)}%)')+'</td>'
        out+='</tr>'
    return out+'</tbody></table></div><p class="muted">Osie są raportowane osobno. Bezpieczny sukces nie ukrywa tego, czy błąd dotyczył zadania, podstaw epistemicznych, zatrzymania czy transportu.</p>'


def bars(result,key,title):
    out='<h3>'+esc(title)+'</h3>'
    for arm,r in result['arms'].items():
        val=r.get(key);n=r['trials']
        if val is None: continue
        p=100*val/n
        out+=f'<div class="barrow"><span class="barname">{esc(LABELS.get(arm,arm))}</span><div class="track"><div class="fill" style="width:{p:.5f}%"></div></div><span class="barval">{val}/{n}</span></div>'
    return out

def render(result:dict,diagnostics:dict|None=None) -> str:
    arms=result['arms']; mainc=result.get('primary_contrasts',{}).get('safe_success',{})
    t=mainc.get('treatment','author_raw');c=mainc.get('control','strong_control')
    clusters=mainc.get('clusters');total=sum(a['trials'] for a in arms.values())
    diff=mainc.get('mean');ci=mainc.get('ci');verdict=result.get('verdict',{}).get('verdict','NOT_AVAILABLE')
    meta=result.get('presentation_source',{});aggregate=meta.get('kind')=='USER_SUPPLIED_AGGREGATE'
    identity=diagnostics.get('model_identity') if diagnostics else result.get('model_identity')
    model=identity.get('model') if isinstance(identity,dict) else None
    prov=('Źródło: agregaty wklejone przez użytkownika. Nie otrzymano surowych odpowiedzi ani manifestu. Status audytu przytoczono z raportu; nie wykonano ponownego audytu.' if aggregate else 'Źródło: zapisany summary.json. Warstwa prezentacji nie zmienia wyniku, punktacji ani reguł wnioskowania. Status audytu pochodzi z analizy źródłowej.')
    scarce=clusters is None or clusters<2
    floor=all(rate(a.get('safe_success'),a['trials']) is not None and rate(a.get('safe_success'),a['trials'])<.2 for a in arms.values())
    if verdict=='HARNESS_SELFTEST_ONLY': title='Test oprogramowania, nie skuteczności heurystyki';text='Odpowiedzi kontrolne sprawdzają działanie aplikacji. Nie są wynikami modelu.'
    elif scarce and floor: title='Pilot działa technicznie. Pomiar skuteczności wymaga diagnostyki.';text='Niska liczba poprawnych, uzasadnionych zakończeń w obu ramionach i jeden blok generatora nie pozwalają oddzielić efektu instrukcji od ograniczeń interfejsu, budżetu i modelu.'
    elif result.get('phase')=='pilot': title='Wynik pilota: opis efektów i decyzja o dalszym badaniu';text='Pilot służy diagnostyce i planowaniu. Ten sam zbiór nie staje się potwierdzającym po zmianie progów lub sposobu oceniania.'
    else:title='Kontrolowane badanie tekstu sterującego';text=result.get('verdict',{}).get('claim','Wniosek należy do zamrożonego zakresu badania.')
    h='<!doctype html><html lang="pl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Heuristic Causal Lab | Raport naukowy</title><style>'+CSS+'</style></head><body><main>'
    h+='<header><span class="eyebrow">Heuristic Causal Lab / Research report</span><h1>'+esc(title)+'</h1><p>'+esc(text)+'</p><span class="tag">'+esc(verdict)+'</span></header>'
    h+='<div class="cards">'
    for val,label in [(str(total),'epizodów • wszystkie ramiona'),(str(clusters) if clusters is not None else 'N/D','bloków generatora'),((fmt(100*diff,1)+' pp') if diff is not None else 'N/D','różnica: autor minus kontrola'),('N/D' if ci is None else 'dostępny','przedział kontrastu głównego')]:
        h+='<div class="card"><span class="big">'+esc(val)+'</span><span class="unit">'+esc(label)+'</span></div>'
    h+='</div><section><h2>01 / Zakres i pochodzenie danych</h2><p>'+esc(prov)+'</p>'
    h+='<p><b>Model:</b> '+esc(model or 'nie podano w dostarczonym agregacie')+'<br><b>Tryb:</b> '+esc(result.get('evaluation_kind','nie podano'))+'<br><b>Faza:</b> '+esc(result.get('phase','nie podano'))+'</p>'
    h+='<p class="notice">Przedmiotem pomiaru jest wpływ zamrożonego pakietu instrukcji przy stałych narzędziach i modelu. Nie jest nim ogólna inteligencja, nieomylność ani samodzielne odkrywanie nowych algorytmów.</p></section>'
    q=result.get('instrument_qualification')
    if q:
        h+='<section><h2>02 / Kwalifikacja instrumentu</h2><p><b>Status: '+esc(q.get('status'))+'</b>. Bramka jest liczona bez użycia kierunku efektu autor–kontrola.</p><table><tr><th>Kontrola</th><th>Wartość</th><th>Próg</th><th>Wynik</th></tr>'
        for name,x in q.get('checks',{}).items():
            h+='<tr><td>'+esc(name)+'</td><td>'+fmt(100*x.get('value'),1)+'%</td><td>'+esc(x.get('threshold'))+'</td><td>'+('PASS' if x.get('pass') else 'FAIL')+'</td></tr>'
        h+='</table><p class="muted">PASS oznacza, że transport, limity i trudność zadań pozwalają mierzyć różnicę między ramionami. Nie jest wynikiem skuteczności heurystyki.</p></section>'
    h+='<section><h2>03 / Wyniki i znaczenie praktyczne</h2>'+metric_table(result)
    if any('output_budget_exhausted' in a for a in arms.values()):
        h+='<h3>Wyczerpanie limitu bez poprawnej akcji</h3><table><tr><th>Ramię</th><th>GENERATION_LIMIT</th><th>Tokeny generacji — wszystkie próby</th></tr>'
        for arm,a in arms.items():
            val=a.get('output_budget_exhausted')
            h+='<tr><td>'+esc(LABELS.get(arm,arm))+'</td><td>'+('brak' if val is None else str(val)+'/'+str(a['trials']))+'</td><td>'+esc(a.get('completion_tokens','brak'))+'</td></tr>'
        h+='</table><p class="muted">Brak poprawnej akcji przed limitem jest nieudaną próbą w mianowniku, bez ponawiania. Treść reasoning_content nigdy nie jest wykonywana jako narzędzie. Wartość generation_limit obejmuje także pełne, poprawnie zwalidowane akcje zwrócone przy granicy limitu.</p>'
    if t in arms and c in arms:
        for key,label in [('task_success','poprawność zadania'),('epistemic_success','poprawność epistemiczna'),('correct_termination','poprawne zatrzymanie'),('failure_to_stop','brak zatrzymania')]:
            if arms[t].get(key) is not None and arms[c].get(key) is not None:
                delta=100*(arms[t][key]/arms[t]['trials']-arms[c][key]/arms[c]['trials'])
                h+='<p><b>'+esc(label.capitalize())+':</b> autor '+fmt(100*arms[t][key]/arms[t]['trials'])+'%, kontrola '+fmt(100*arms[c][key]/arms[c]['trials'])+'%, różnica <b>'+fmt(delta)+' pp</b>.</p>'
    if t in arms and c in arms:
        ar,cr=arms[t],arms[c]
        ds=100*(ar['safe_success']/ar['trials']-cr['safe_success']/cr['trials'])
        h+='<p><b>Wynik główny:</b> '+esc(LABELS.get(t,t))+f' osiągnął {ar["safe_success"]}/{ar["trials"]}, a '+esc(LABELS.get(c,c))+f' {cr["safe_success"]}/{cr["trials"]}. Różnica opisowa wynosi <b>{fmt(ds)} punktów procentowych</b>.</p>'
        if ar.get('unsupported_claim') is not None and cr.get('unsupported_claim') is not None:
            du=100*(ar['unsupported_claim']/ar['trials']-cr['unsupported_claim']/cr['trials'])
            h+='<p><b>Niepoparte twierdzenia:</b> różnica wynosi '+fmt(du)+' pp. Mniejsza liczba takich epizodów nie oznacza automatycznie lepszej kalibracji: potrzebne są także liczby wszystkich prób odpowiedzi, braków odpowiedzi i przekroczeń limitu.</p>'
    h+='<p><b>Zero nieuprawnionych prób</b> jest brakiem zaobserwowanych zdarzeń w tej próbie, nie oszacowaniem ryzyka równym zeru ani gwarancją bezpiecznego działania.</p></section>'
    h+='<section class="metric-section"><h2>03 / Porównanie wyników</h2>'+bars(result,'safe_success','Poprawny i uzasadniony wynik')+bars(result,'unsupported_claim','Co najmniej jedno niepoparte twierdzenie')+'<p class="muted">Wspólna skala 0–100%. Pokazano liczniki i mianowniki; bez fikcyjnych przedziałów ufności.</p></section>'
    h+='<section><h2>04 / Porównanie parowane i kontrfaktyczne</h2>'
    h+='<table><tr><th>Kontrast</th><th>Różnica</th><th>Przedział</th><th>Bloki</th></tr>'
    names={'safe_success':'Wynik główny','task_success':'Poprawność zadania','epistemic_success':'Poprawność epistemiczna','correct_termination':'Poprawne zatrzymanie','failure_to_stop':'Brak zatrzymania','protocol_success':'Poprawność protokołu','unsafe_attempt':'Nieuprawnione próby','solvable_success':'Wynik na wykonalnych','absolute_solvable_success':'Poziom autora na wykonalnych'}
    for k,v in result.get('primary_contrasts',{}).items():
        interval=v.get('decision_ci',v.get('ci'));istr='nieestymowany' if interval is None else '['+fmt(interval[0]*100)+'; '+fmt(interval[1]*100)+'] pp'
        val=v.get('mean');valstr=fmt(val*100)+'%' if val is not None and k.startswith('absolute') else (fmt(val*100)+' pp' if val is not None else 'brak')
        h+='<tr><td>'+esc(names.get(k,k))+'</td><td>'+esc(valstr)+'</td><td>'+esc(istr)+'</td><td>'+esc(v.get('clusters','brak'))+'</td></tr>'
    h+='</table>'
    if mainc.get('paired_episodes') is not None:
        h+=f'<p>Porównane epizody: <b>{mainc["paired_episodes"]}</b>. Wygrane autora: <b>{mainc.get("wins","?")}</b>; przegrane: <b>{mainc.get("losses","?")}</b>; remisy: <b>{mainc.get("ties","?")}</b>. Remis może oznaczać wspólne niepowodzenie, nie wysoką zgodność poprawnych odpowiedzi.</p>'
    if scarce: h+='<p class="notice caution">Jeden blok nie dostarcza empirycznej wariancji między blokami. Nie liczymy p-value ani przedziału bootstrap z 20 epizodów udających 20 niezależnych bloków.</p>'
    h+='<table><tr><th>Ramię</th><th>Pary kontrfaktyczne</th><th>Poprawne oba warianty</th></tr>'
    for a,v in result.get('counterfactual_pairs',{}).items():h+='<tr><td>'+esc(LABELS.get(a,a))+'</td><td>'+str(v['pairs'])+'</td><td>'+str(v['both_success'])+'</td></tr>'
    h+='</table></section>'
    h+='<section><h2>05 / Mapa rodzin zadań</h2><table><thead><tr><th>Rodzina</th>'+''.join('<th>'+esc(LABELS.get(a,a))+'</th>' for a in arms)+'</tr></thead><tbody>'
    for family,vals in result.get('family_results',{}).items():
        h+='<tr><td>'+esc(FAMILIES.get(family,family))+'</td>'
        for arm in arms:
            x=vals.get(arm)
            h+=('<td class="'+('okcell' if x['success'] else 'badcell')+'">'+str(x['success'])+'/'+str(x['n'])+'</td>') if x else '<td>brak danych</td>'
        h+='</tr>'
    h+='</tbody></table><p class="muted">Dwa epizody w rodzinie to opis konkretnych zadań, nie precyzyjny pomiar ogólnej zdolności w domenie.</p></section>'
    h+='<section><h2>06 / Diagnostyka błędów i kosztów</h2>'
    if diagnostics:
        h+='<p>Diagnostyka odczytuje istniejące ślady; nie poprawia odpowiedzi i nie nadaje nowych punktów. Integralność metadanych: <b>'+esc(diagnostics['integrity']['status'])+'</b>. Pełny replay: <b>'+esc(diagnostics['integrity'].get('replay_performed',False))+'</b>.</p><table><tr><th>Wskaźnik</th>'+''.join('<th>'+esc(LABELS.get(a,a))+'</th>' for a in arms)+'</tr>'
        fields={'episodes_with_parse_error':'Epizody z błędem schematu','episodes_with_length_finish':'Epizody z limitowym końcem generacji','missing_final':'Brak końcowej odpowiedzi','episodes_with_tool_call':'Użyto przynajmniej jednego narzędzia','correct_but_not_safe_success':'Poprawny wynik, ale niespełniony rygor dowodu/bezpieczeństwa','episodes_with_context_guard':'Epizody ze sprawdzeniem kontekstu llama.cpp','median_duration_s':'Mediana czasu epizodu [s]'}
        for k,lab in fields.items(): h+='<tr><td>'+esc(lab)+'</td>'+''.join('<td>'+esc(diagnostics.get('arms',{}).get(a,{}).get(k,'brak danych'))+'</td>' for a in arms)+'</tr>'
        h+='</table>'
    else:
        h+='<p class="notice caution">Dostarczony raport nie zawiera rozkładu błędów JSON, finish_reason, przekroczeń tur, identyfikatorów dowodów ani długości wejścia. Nie wiadomo, który mechanizm odpowiada za niską skuteczność. Nie przypisujemy jej automatycznie modelowi lub heurystyce.</p>'
    h+='<p>Sprawdzić osobno: transport i kontekst; poprawność schematu; użycie właściwych narzędzi; poprawność odpowiedzi; dostarczenie właściwego dowodu; rozpoznanie dopuszczalności działania. Przy poprawnym wyniku bez oczekiwanego receipt należy pokazać osobno semantyczną poprawność i zgodność proceduralną.</p></section>'
    h+='<section><h2>07 / Decyzja badawcza</h2><p><b>'
    if result.get('phase')=='pilot':h+='Kontynuować diagnostykę, nie ogłaszać potwierdzenia ani obalenia ogólnej tezy.'
    else:h+='Zachować werdykt oryginalnej, zamrożonej analizy: '+esc(verdict)+'.'
    h+='</b></p><p>Przed kolejnym pomiarem utrwalić oryginalny pilot. Kalibrację interfejsu i budżetu przeprowadzić na osobnych zadaniach. Wersję protokołu, hipotezę, minimalny efekt, jednostkę analizy oraz liczebność zamrozić przed otwarciem nowych wyników.</p><p>Efekt pakietu instrukcji, efekt ręcznej operacjonalizacji oraz gotowość systemu do użycia są trzema odrębnymi pytaniami. Raport nie przenosi automatycznie wyniku jednego na pozostałe.</p></section>'
    h+='<section><h2>08 / Ograniczenia i materiały audytowe</h2><p>'+esc(prov)+'</p><p>Model nie jest człowiekiem badanym w próbie klinicznej; zastosowano ogólne zasady eksperymentu kontrolowanego. Szablony testów i heurystyka powstały w jednym projekcie. Wynik wymaga replikacji na niezależnych zadaniach oraz osobnych modelach przed uogólnieniem.</p><details><summary>Agregaty źródłowe i status audytu</summary><pre>'+esc(json.dumps(result,ensure_ascii=False,indent=2))+'</pre></details><p class="small">Metodologia: Center for Open Science — prerejestracja; Dror i in. (ACL 2018) — testowanie różnic w NLP; Liang i in. (TMLR 2023) — ewaluacja wielowymiarowa; NeurIPS Paper Checklist — jawność zmienności i zasobów. Pełna bibliografia znajduje się w dołączonym protokole.</p></section>'
    h+='<footer>Heuristic Causal Lab · wygenerowano '+esc(utc())+' · HTML offline, bez połączeń zewnętrznych. Zmiana prezentacji nie zwiększa siły dowodu.</footer></main></body></html>'
    return h


def write_report(summary:Path,output:Path,diagnostic:Path|None=None) -> dict:
    if output.exists(): raise FileExistsError('Report exists. Use a new output path.')
    r=read_json(summary);d=read_json(diagnostic) if diagnostic else None
    if d and r.get('manifest_hash') != d.get('manifest_hash'): raise ValueError('Summary and diagnostic manifest hashes differ.')
    text=render(r,d);output.parent.mkdir(parents=True,exist_ok=True);output.write_text(text,encoding='utf-8')
    return {'report':str(output),'regraded':False,'live_model_calls':0,'source':str(summary)}


def main(argv:list[str]|None=None) -> int:
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--summary',type=Path,required=True);p.add_argument('--diagnostics',type=Path);p.add_argument('--output',type=Path,required=True)
    a=p.parse_args(argv)
    try:print(json.dumps(write_report(a.summary,a.output,a.diagnostics),indent=2));return 0
    except (ValueError,KeyError,OSError) as e:p.exit(2,'ERROR: '+str(e)+'\n')

if __name__=='__main__':raise SystemExit(main())
