#!/usr/bin/env python3
"""Read-only replay of recorded trials; does not alter frozen scoring or states."""
import copy
import hashlib
import json
from pathlib import Path
from lab import apply, evaluate_state

ROOT = Path(__file__).resolve().parent

def load(path):
    return json.loads(path.read_text(encoding='utf-8'))

def state_hash(state):
    return hashlib.sha256(json.dumps(state, sort_keys=True).encode()).hexdigest()

def audit():
    frozen = load(ROOT/'frozen_hashes.json')
    changes = [name for name, expected in frozen.items() if hashlib.sha256((ROOT/name).read_bytes()).hexdigest() != expected]
    manifest, fixtures = load(ROOT/'manifest.json'), load(ROOT/'fixtures.json')
    problems, rows = [], []
    for run in manifest['runs']:
        previous_end = None
        for ep in run['episodes']:
            path = ROOT/'runtime'/run['run']
            trace_path = path/f'{ep}.jsonl'
            trace = [json.loads(line) for line in trace_path.read_text(encoding='utf-8').splitlines()] if trace_path.exists() else []
            state = copy.deepcopy(fixtures[str(run['block'])][ep])
            prefix = f'{run["run"]}/{ep}'
            if trace and trace[0]['time'] < manifest['created_at']:
                problems.append(prefix+': trace precedes freeze')
            if trace and previous_end is not None and trace[0]['time'] < previous_end:
                problems.append(prefix+': episodes overlap or order differs')
            for entry in trace:
                if entry['state_before_sha256'] != state_hash(state):
                    problems.append(prefix+': before hash mismatch')
                n = len(state['events'])
                response = apply(state, entry['request'])
                if response != entry['response']:
                    problems.append(prefix+': response mismatch')
                if entry['call'] != state['calls']:
                    problems.append(prefix+': call counter mismatch')
                if entry['events'] != state['events'][n:]:
                    problems.append(prefix+': event mismatch')
                if entry['state_after_sha256'] != state_hash(state):
                    problems.append(prefix+': after hash mismatch')
            if state != load(path/f'{ep}.json'):
                problems.append(prefix+': stored final state differs from replay')
            if not state['closed']:
                problems.append(prefix+': episode not closed')
            if trace:
                previous_end = trace[-1]['time']
            rows.append({'run':run['run'], 'arm':run['arm'], 'block':run['block'], 'episode':ep, **evaluate_state(state, trace)})
    recorded = load(ROOT/'results'/'episode_scores.json')
    if rows != recorded:
        problems.append('Recorded grading differs from replay grading')
    result = {'frozen_files_checked':len(frozen), 'frozen_files_changed':changes, 'episodes_replayed':len(rows), 'journal_entries':sum(r['calls'] for r in rows), 'problems':problems, 'passed':not changes and not problems, 'scope':'Replays public requests, responses, events, counters, state hashes and grading. Does not audit all shell/file access or provide tamper-proof external attestation.'}
    (ROOT/'results'/'replay_audit.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    audit()
