from copy import deepcopy
from dataclasses import asdict
from pathlib import Path
import pytest
from heuristic_lab.design import prepare,verify_design,load_case
from heuristic_lab.engine import run_episode,replay_trial,audit_study,execute_study
from heuristic_lab.fixtures import OracleFixture,smoke
from heuristic_lab.analysis import analyse
from heuristic_lab.util import read_json,write_json,digest


def test_no_inference_without_explicit_consent(tmp_path,cfg):
    prepare(cfg,tmp_path/'run',mock=True)
    with pytest.raises(ValueError):execute_study(tmp_path/'run',False)


def test_manifest_is_prospective_no_overwrite(tmp_path,cfg):
    prepare(cfg,tmp_path/'run',mock=True)
    assert not verify_design(tmp_path/'run')
    with pytest.raises(FileExistsError):prepare(cfg,tmp_path/'run',mock=True)


def test_policy_tampering_detected(tmp_path,cfg):
    out=tmp_path/'run';prepare(cfg,out,mock=True)
    (out/'policies/author_raw.txt').write_text('changed',encoding='utf-8')
    assert verify_design(out)


def test_same_case_model_seed_tools_and_budget_across_arms(tmp_path,cfg):
    out=tmp_path/'run';m=prepare(cfg,out,mock=True);schedule=read_json(out/'schedule.json')
    grouped={}
    for x in schedule:grouped.setdefault(x['case_id'],[]).append(x)
    assert all(len({x['model_seed'] for x in xs})==1 for xs in grouped.values())
    assert len(schedule)==40
    assert m['policies']['author_raw']['chars']==m['policies']['strong_control']['chars']


def test_inference_prompt_never_contains_assignment_label(tmp_path,cfg):
    out=tmp_path/'run';m=prepare(cfg,out,mock=True)
    item=read_json(out/'schedule.json')[0];case=load_case(out,item['case_id'])
    policy=(out/m['policies'][item['arm']]['path']).read_text(encoding='utf-8')
    record=run_episode(case,policy,OracleFixture(case),cfg['budget'],item['model_seed'])
    assert item['arm'] not in str(record['initial_messages'])


def test_replay_rejects_forged_score_even_with_new_hash(tmp_path,cfg):
    out=tmp_path/'run';smoke(out,cfg)
    p=next((out/'trials').glob('*.json'));rec=read_json(p)
    rec['score']['safe_success']=False
    rec.pop('artifact_hash');rec['artifact_hash']=digest(rec);write_json(p,rec)
    audit=audit_study(out)
    assert audit['status']=='FAIL'
    assert any('grade mismatch' in x for x in audit['errors'])


def test_mock_perfect_performance_never_tests_the_hypothesis(tmp_path,cfg):
    out=tmp_path/'run';r=smoke(out,cfg)
    assert r['live_model_calls']==0
    summary=analyse(out,iterations=100)
    assert all(x['safe_success']==x['trials'] for x in summary['arms'].values())
    assert summary['verdict']['verdict']=='HARNESS_SELFTEST_ONLY'


def test_oracle_fingerprint_can_not_be_counted_as_real_from_one_flag(tmp_path,cfg):
    out=tmp_path/'run';smoke(out,cfg)
    m=read_json(out/'manifest.json');m['evaluation_kind']='LIVE_MODEL_STUDY'
    m.pop('manifest_hash');m['manifest_hash']=digest(m);write_json(out/'manifest.json',m)
    summary=analyse(out,iterations=100)
    assert summary['verdict']['verdict']=='HARNESS_SELFTEST_ONLY'


def test_replay_rejects_forged_protocol_audit(tmp_path,cfg):
    out=tmp_path/'run';smoke(out,cfg)
    p=next((out/'trials').glob('*.json'));rec=read_json(p)
    rec['protocol_audit']['invalid_status_requests']=100
    rec.pop('artifact_hash');rec['artifact_hash']=digest(rec);write_json(p,rec)
    assert audit_study(out)['status']=='FAIL'


def test_provenance_points_to_exact_original_text():
    from heuristic_lab.util import ASSETS,file_hash
    p=read_json(ASSETS/'sources'/'provenance.json')
    assert file_hash(ASSETS/'policies'/'author_raw.txt')==p['raw_policy_sha256']
    raw=(ASSETS/'policies'/'author_raw.txt').read_text(encoding='utf-8')
    source=(ASSETS/'sources'/'original_compiler_input.txt').read_text(encoding='utf-8')
    assert raw.strip() in source
