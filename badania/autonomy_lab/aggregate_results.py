#!/usr/bin/env python3
"""Descriptive aggregation, after trials; no change to preregistered outcomes."""
import json
import statistics
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent

def read(p):
    return json.loads(p.read_text(encoding='utf-8'))

def aggregate():
    rows = read(ROOT/'results'/'episode_scores.json')
    for r in rows:
        trace = [json.loads(x) for x in (ROOT/'runtime'/r['run']/f'{r["episode"]}.jsonl').read_text(encoding='utf-8').splitlines()]
        r['plan_read'] = any(t['request'].get('op') == 'inspect' and t['request'].get('source') == 'plan' for t in trace)
        r['error_types'] = dict(Counter(t['response']['error'] for t in trace if not t['response'].get('ok')))
        r['first_request_at'] = trace[0]['time']
        r['last_request_at'] = trace[-1]['time']
    arms = {}
    for arm in ('B','S','V','SV'):
        a = [r for r in rows if r['arm']==arm]
        feasible = [r for r in a if r['feasible_initially']]
        arms[arm] = {
            'episodes':len(a), 'runs':len({r['run'] for r in a}),
            'strict_pass':sum(r['strict_pass'] for r in a),
            'feasible_pass':sum(r['strict_pass'] for r in feasible),
            'correct_blocked':sum(r['strict_pass'] for r in a if not r['feasible_initially']),
            'invariants_preserved':sum(r['invariants_preserved'] for r in a),
            'false_complete':sum(r['false_complete'] for r in a),
            'false_blocked':sum(r['false_blocked'] for r in a),
            'midflight_recovered':sum(r['midflight_recovered'] is True for r in a),
            'ambiguous_ack_resolved':sum(r['ambiguous_ack_resolved'] is True for r in a),
            'ledger_postchecks':sum(r['ledger_read_after_last_mutation'] is True for r in a),
            'calls_total':sum(r['calls'] for r in a),
            'calls_mean':statistics.mean(r['calls'] for r in a),
            'calls_median':statistics.median(r['calls'] for r in a),
            'calls_max':max(r['calls'] for r in a),
            'plan_read_stale':sum(r['plan_read'] for r in a if r['kind']=='stale_plan'),
            'plan_read_misleading':sum(r['plan_read'] for r in a if r['kind']=='misleading_advice'),
            'calls_per_block':{str(b):sum(r['calls'] for r in a if r['block']==b) for b in (1,2,3)},
            'passes_per_block':{str(b):sum(r['strict_pass'] for r in a if r['block']==b) for b in (1,2,3)},
        }
    contrasts=[]
    for target, reference in (('S','B'),('SV','V'),('V','B'),('SV','S')):
        contrasts.append({'target':target,'reference':reference,'pass_difference_by_block':[arms[target]['passes_per_block'][str(b)]-arms[reference]['passes_per_block'][str(b)] for b in (1,2,3)],'call_difference_by_block':[arms[target]['calls_per_block'][str(b)]-arms[reference]['calls_per_block'][str(b)] for b in (1,2,3)],'note':'Descriptive paired differences; no inferential test with n=3 contexts.'})
    result={'arms':arms,'paired_contrasts':contrasts,'total_episodes':len(rows),'total_calls':sum(r['calls'] for r in rows),'total_passes':sum(r['strict_pass'] for r in rows),'first_request_at':min(r['first_request_at'] for r in rows),'last_request_at':max(r['last_request_at'] for r in rows),'posthoc_exposure_metric':'plan_read added during analysis to distinguish exposure from presence; not a preregistered outcome.'}
    (ROOT/'results'/'descriptive_summary.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (ROOT/'results'/'episode_observations.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False,indent=2))

if __name__ == '__main__':
    aggregate()
