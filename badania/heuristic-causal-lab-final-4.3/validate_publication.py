#!/usr/bin/env python3
"""Offline consistency check of the published HCL 4.3.3 artifacts.

This checks existing artifacts, not model inference or independent grader replay.
It never changes files and uses only the Python standard library.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import io
import json
from pathlib import Path
import sys
from typing import Any

RUN = Path('hcl_final_4_3/runs/study_20261002-122125')
SOURCE_COMMIT = '58383e874d0f684bfe2e290584fb4138f367c1b4'
CSV_SHA256 = 'fc6c591a57f83e4f819872fd65ad9327573678844f2fd2055b95cec7af8de68a'
BOOL_METRICS = (
    'safe_success', 'correct_outcome', 'task_success', 'epistemic_success',
    'protocol_success', 'correct_termination', 'premature_stop', 'failure_to_stop',
    'generation_limit', 'output_budget_exhausted', 'qualified_success',
    'unsafe_attempt', 'unsupported_claim', 'overabstention',
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def as_bool(value: str) -> bool:
    require(value in ('True', 'False'), f'Invalid boolean: {value!r}')
    return value == 'True'


def validate(source_csv: bytes, export_csv: bytes, summary: dict[str, Any],
             export_summary: dict[str, Any], profile: dict[str, Any]) -> dict[str, Any]:
    digest = hashlib.sha256(source_csv).hexdigest()
    git_lf_digest = hashlib.sha256(source_csv.replace(b'\r\n', b'\n')).hexdigest()
    require(git_lf_digest == CSV_SHA256, 'Source CSV differs from the documented final run (Git LF bytes)')
    require(source_csv == export_csv, 'Publication CSV is not byte-identical to source CSV')
    require(summary == export_summary, 'Publication and source summaries differ')
    matrix = list(csv.reader(io.StringIO(source_csv.decode('utf-8'), newline='')))
    require(bool(matrix) and len(matrix[0]) == 39, 'Expected 39 CSV columns')
    require(all(len(row) == 39 for row in matrix), 'Malformed CSV record width')
    rows = [dict(zip(matrix[0], row)) for row in matrix[1:]]
    require(len(rows) == 10240, 'Expected 10240 episodes')
    require(len({r['trial_id'] for r in rows}) == 10240, 'Duplicate trial identifiers')
    require(all(r['mock'] == 'False' for r in rows), 'Unexpected mock episodes')
    clusters = Counter(int(r['cluster']) for r in rows)
    require(set(clusters) == set(range(30000, 30256)), 'Unexpected generation seed blocks')
    require(set(clusters.values()) == {40}, 'Incomplete generation seed block')
    require(profile['clusters'] == 256 and profile['seed_start'] == 30000, 'Profile mismatch')
    require(profile['budget']['max_turns'] == 6, 'Turn cap mismatch')
    require(profile['budget']['max_tokens_per_turn'] == 768, 'Output cap mismatch')
    require(profile['decision']['minimum_utility_rate'] == 0.7, 'Utility threshold mismatch')
    require(summary['verdict']['verdict'] == 'CONTRADICTED_SAFETY_OR_UTILITY_IN_SCOPE', 'Verdict mismatch')
    arms = ('author_raw', 'strong_control')
    require(set(r['arm'] for r in rows) == set(arms), 'Unexpected experimental arms')
    observed: dict[str, Any] = {}
    for arm in arms:
        group = [r for r in rows if r['arm'] == arm]
        require(len(group) == 5120, f'{arm}: expected 5120 episodes')
        expected = summary['arms'][arm]
        totals = {key: sum(as_bool(r[key]) for r in group) for key in BOOL_METRICS}
        for key, total in totals.items():
            require(total == expected[key], f'{arm}: aggregate mismatch for {key}')
        for key in ('calls', 'prompt_tokens', 'completion_tokens', 'coverage'):
            total = sum(int(r[key]) for r in group)
            require(total == expected[key], f'{arm}: sum mismatch for {key}')
        attempts = sum(int(r['decisive_attempts']) for r in group)
        unsupported = sum(int(r['unsupported_decisive_attempts']) for r in group)
        require(attempts == expected['epistemic_decisive_attempts'], f'{arm}: attempt count mismatch')
        require(abs(unsupported / attempts - expected['epistemic_invalid_claim_rate']) < 1e-12,
                f'{arm}: conditional unsupported-claim rate mismatch')
        solvable = [r for r in group if as_bool(r['solvable'])]
        require(len(solvable) == 3840, f'{arm}: solvable denominator mismatch')
        observed[arm] = {'episodes': len(group), **totals, 'solvable_episodes': len(solvable),
                         'solvable_safe_success': sum(as_bool(r['safe_success']) for r in solvable)}
        for family in profile['families']:
            subset = [r for r in group if r['family'] == family]
            require(len(subset) == 512, f'{arm}/{family}: incomplete family')
            require(sum(as_bool(r['safe_success']) for r in subset) == summary['family_results'][family][arm]['success'],
                    f'{arm}/{family}: family success mismatch')
        twins: dict[tuple[str, str, str], list[dict[str, str]]] = defaultdict(list)
        for r in group:
            twins[(r['cluster'], r['family'], r['repeat'])].append(r)
        require(len(twins) == 2560, f'{arm}: twin pair count mismatch')
        require(all(len(g) == 2 and {r['twin'] for r in g} == {'0', '1'} for g in twins.values()),
                f'{arm}: incomplete counterfactual pair')
        both = sum(all(as_bool(r['safe_success']) for r in g) for g in twins.values())
        require(both == summary['counterfactual_pairs'][arm]['both_success'], f'{arm}: twin success mismatch')
    paired: dict[tuple[str, str], dict[str, dict[str, str]]] = defaultdict(dict)
    for r in rows:
        paired[(r['case_id'], r['repeat'])][r['arm']] = r
    require(len(paired) == 5120 and all(set(p) == set(arms) for p in paired.values()), 'Incomplete arm pairing')
    for metric in ('safe_success', 'task_success', 'epistemic_success', 'correct_termination', 'protocol_success', 'unsafe_attempt'):
        differences = [int(as_bool(p['author_raw'][metric])) - int(as_bool(p['strong_control'][metric])) for p in paired.values()]
        contrast = summary['primary_contrasts'][metric]
        require(abs(sum(differences) / len(differences) - contrast['mean']) < 1e-12, f'{metric}: mean contrast mismatch')
        for field, sign in (('wins', 1), ('losses', -1), ('ties', 0)):
            require(differences.count(sign) == contrast[field], f'{metric}: {field} mismatch')
    absolute = observed['author_raw']['solvable_safe_success'] / 3840
    require(abs(absolute - summary['primary_contrasts']['absolute_solvable_success']['mean']) < 1e-12,
            'Absolute utility mismatch')
    return {
        'status': 'PASS', 'scope': 'offline publication integrity and aggregate consistency; not new inference or grader replay',
        'source_commit': SOURCE_COMMIT, 'run': RUN.as_posix(), 'source_csv_sha256': digest, 'source_git_lf_sha256': git_lf_digest,
        'export_csv_sha256': hashlib.sha256(export_csv).hexdigest(), 'byte_identical_csv': True,
        'summaries_equal': True, 'episodes': len(rows), 'columns': 39, 'seed_blocks': len(clusters),
        'paired_cases': len(paired), 'arms': observed,
        'bootstrap_intervals_recomputed': False, 'independent_model_replication': False,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', type=Path, default=Path(__file__).resolve().parent,
                        help='HCL project directory (default: directory containing this script)')
    args = parser.parse_args()
    base = args.base.resolve()
    study = base / RUN / 'study'
    try:
        report = validate((study / 'trials.csv').read_bytes(), (base / 'artifacts/trials.csv').read_bytes(),
                          json.loads((study / 'summary.json').read_text(encoding='utf-8')),
                          json.loads((base / 'artifacts/summary.json').read_text(encoding='utf-8')),
                          json.loads((base / RUN / 'profile.json').read_text(encoding='utf-8')))
    except (OSError, ValueError, KeyError, TypeError, csv.Error) as exc:
        print(json.dumps({'status': 'FAIL', 'error': str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 1
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
