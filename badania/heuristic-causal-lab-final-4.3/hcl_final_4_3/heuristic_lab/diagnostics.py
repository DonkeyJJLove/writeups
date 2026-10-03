"""Read-only diagnostic export, including from studies sealed by an older version.

This never recomputes, repairs or promotes a score and never performs inference.
An integrity inspection is not an independent replay with the original source.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
import csv
import json
from pathlib import Path
import statistics
from .design import verify_design
from .util import read_json, digest, source_manifest, write_json, utc


def inspect_study(study: Path, output: Path) -> dict:
    study, output = study.resolve(), output.resolve()
    if output == study or output.is_relative_to(study):
        raise ValueError('Diagnostic output must be outside the sealed study directory.')
    if output.exists():
        raise FileExistsError('Diagnostic output already exists. Choose a new directory.')
    manifest = read_json(study/'manifest.json')
    schedule = read_json(study/'schedule.json')
    index = {x['case_id']: x for x in read_json(study/'case_index.json')}
    expected = {x['trial_id']: x for x in schedule}
    errors = verify_design(study, check_source=False)
    trial_rows = []; seen = set(); families = defaultdict(Counter)
    counters = defaultdict(Counter); details = defaultdict(lambda: {'finish_reasons':Counter(), 'failure_reasons':Counter(), 'parse_messages':Counter(), 'roundtrip_s':[], 'durations':[]})
    for path in sorted((study/'trials').glob('*.json')):
        record = read_json(path); unsigned = dict(record); claim = unsigned.pop('artifact_hash',None)
        if digest(unsigned) != claim: errors.append('artifact hash mismatch: '+path.name)
        a = record['assignment']; tid = a['trial_id']; arm = a['arm']; s = record['score']
        if tid not in expected or a != expected[tid]: errors.append('assignment mismatch: '+tid)
        if tid in seen: errors.append('duplicate trial: '+tid)
        seen.add(tid)
        if record.get('manifest_hash') != manifest.get('manifest_hash'): errors.append('manifest binding mismatch: '+tid)
        events=record.get('events',[]); final=record.get('final'); meta=index.get(a['case_id'],{})
        private=read_json(study/'private'/(a['case_id']+'.json')).get('private',{})
        observed={}; calls=[]; parse=0; lengths=0; tool_fail=0; has_guard=False
        for e in events:
            reply=e.get('reply',{}); md=reply.get('metadata',{})
            finish=md.get('finish_reason')
            if 'reply' in e: details[arm]['finish_reasons'][str(finish) if finish is not None else 'NOT_REPORTED']+=1
            lengths += finish in {'length','limit'}
            if isinstance(md.get('roundtrip_s'),(int,float)): details[arm]['roundtrip_s'].append(md['roundtrip_s'])
            has_guard = has_guard or bool(md.get('llama_context_check'))
            if 'parse_error' in e:
                parse+=1; details[arm]['parse_messages'][str(e['parse_error'])]+=1
            action=e.get('parsed',{})
            if action.get('kind')=='tool': calls.append(action.get('name'))
            obs=e.get('tool_response')
            if isinstance(obs,dict):
                rid=obs.get('receipt_id',obs.get('id'))
                if rid: observed[rid]=obs
                # Preserve backend statuses; do not interpret all unknowns as tool errors.
                tool_fail+=bool(obs.get('error'))
        failure=record.get('failure'); count=counters[arm]; count['episodes']+=1
        for key in ['safe_success','correct_outcome','task_success','epistemic_success','protocol_success','correct_termination','premature_stop','failure_to_stop','generation_limit','qualified_success','unsafe_attempt','unsupported_claim','overabstention','solvable','abstained']:
            count[key]+=int(bool(s.get(key)))
        count['missing_final']+=int(final is None)
        count['episodes_with_parse_error']+=int(parse>0); count['parse_errors']+=parse
        count['episodes_with_length_finish']+=int(lengths>0); count['length_finishes']+=lengths
        count['episodes_with_tool_call']+=int(bool(calls)); count['tool_calls']+=len(calls)
        count['model_requests']+=len(events); count['reported_tool_errors']+=tool_fail
        count['correct_but_not_safe_success']+=int(bool(s.get('correct_outcome')) and not s.get('safe_success'))
        count['episodes_with_context_guard']+=int(has_guard)
        count['solvable_safe_success']+=int(bool(s.get('solvable')) and bool(s.get('safe_success')))
        details[arm]['failure_reasons'][failure or 'FINAL_RETURNED']+=1
        duration=record.get('duration_s')
        if isinstance(duration,(int,float)): details[arm]['durations'].append(duration)
        family=meta.get('family','UNKNOWN');families[(arm,family)]['n']+=1
        families[(arm,family)]['success']+=int(bool(s.get('safe_success')))
        trial_rows.append({'trial_id':tid,'arm':arm,'family':family,'cluster':meta.get('cluster'),
            'twin':meta.get('twin'),'safe_success':s.get('safe_success'),'correct_outcome':s.get('correct_outcome'),
            'task_success':s.get('task_success'),'epistemic_success':s.get('epistemic_success'),'protocol_success':s.get('protocol_success'),
            'correct_termination':s.get('correct_termination'),'premature_stop':s.get('premature_stop'),'failure_to_stop':s.get('failure_to_stop'),'generation_limit':s.get('generation_limit'),
            'unsupported_claim':s.get('unsupported_claim'),'unsafe_attempt':s.get('unsafe_attempt'),
            'overabstention':s.get('overabstention'),'failure':failure,'missing_final':final is None,
            'parse_failures':parse,'length_finishes':lengths,'tool_calls':len(calls),
            'tool_names':' / '.join(str(x) for x in calls),'required_documents_count':len(private.get('required_documents',[])),
            'cited_receipts_count':len(final.get('evidence',[])) if final else 0,
            'prompt_tokens':record.get('usage',{}).get('prompt_tokens'),
            'completion_tokens':record.get('usage',{}).get('completion_tokens'),
            'duration_s':duration,'context_guard_observed':has_guard})
    missing=sorted(set(expected)-seen)
    result={'schema':1,'generated_utc':utc(),'purpose':'Diagnostic export only; no new inference or regrading',
        'source_study':str(study),'manifest_hash':manifest.get('manifest_hash'),
        'source_hash_matches_current':manifest.get('source_hash')==digest(source_manifest()),
        'integrity':{'status':'PASS' if not errors else 'FAIL','errors':errors,'scheduled':len(expected),
                     'present':len(seen),'missing':len(missing),'replay_performed':False,
                     'scope':'manifest/sealed-file/trial hashes and assignment bindings; use original version for full replay'},
        'model_identity':manifest.get('model',{}).get('identity'),
        'frozen_budget':manifest.get('config',{}).get('budget'),
        'clusters_observed':len({r['cluster'] for r in trial_rows}),
        'arms':{},'family_results':{},
        'interpretation':'Signals identify diagnostic leads, not proven causes. Categories may overlap. Missing metadata is unknown, not zero.'}
    for arm,c in counters.items():
        d=details[arm]
        result['arms'][arm]={**dict(c),'finish_reasons':dict(d['finish_reasons']),
            'failure_reasons':dict(d['failure_reasons']),'parse_messages':dict(d['parse_messages']),
            'median_duration_s':statistics.median(d['durations']) if d['durations'] else None,
            'median_roundtrip_s':statistics.median(d['roundtrip_s']) if d['roundtrip_s'] else None,
            'format_episode_rate':1-c['episodes_with_parse_error']/c['episodes']}
    for (arm,fam),counts in families.items(): result['family_results'].setdefault(fam,{})[arm]=dict(counts)
    output.mkdir(parents=True)
    write_json(output/'diagnostics.json',result)
    if trial_rows:
        with (output/'diagnostic_trials.csv').open('w',encoding='utf-8',newline='') as f:
            w=csv.DictWriter(f,fieldnames=list(trial_rows[0]));w.writeheader();w.writerows(trial_rows)
    (output/'README.txt').write_text('Read-only metadata export. No model replies, policy text, credentials or private answers are included. Original source and studies remain unchanged. Use the original application version to replay the historical study.\n',encoding='utf-8')
    return result


def main(argv: list[str] | None = None) -> int:
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('study',type=Path);p.add_argument('--output',type=Path,required=True)
    a=p.parse_args(argv)
    try:
        r=inspect_study(a.study,a.output)
        print(json.dumps({'diagnostics':str(a.output/'diagnostics.json'),'integrity':r['integrity'],
            'clusters_observed':r['clusters_observed'],'arms':r['arms']},indent=2,ensure_ascii=False))
        return 0 if not r['integrity']['errors'] else 1
    except (ValueError,OSError,KeyError) as e:
        p.exit(2,'ERROR: '+str(e)+'\n')

if __name__=='__main__': raise SystemExit(main())
