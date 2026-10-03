from copy import deepcopy
from pathlib import Path
import json
import pytest
from heuristic_lab.scientific_report import render, write_report
from heuristic_lab.diagnostics import inspect_study
from heuristic_lab.fixtures import smoke
from heuristic_lab.design import load_config
from heuristic_lab.util import ASSETS, read_json, write_json


def aggregate():
    return {'presentation_source':{'kind':'USER_SUPPLIED_AGGREGATE'},'manifest_hash':None,
        'evaluation_kind':'LIVE_MODEL_STUDY','phase':'pilot','verdict':{'verdict':'PILOT_ONLY'},
        'arms':{'strong_control':{'trials':20,'safe_success':2,'unsafe_attempt':0,'unsupported_claim':9,'overabstention':4},
                'author_raw':{'trials':20,'safe_success':1,'unsafe_attempt':0,'unsupported_claim':5,'overabstention':2}},
        'primary_contrasts':{'safe_success':{'mean':-.05,'ci':None,'clusters':1,'treatment':'author_raw','control':'strong_control','paired_episodes':20,'wins':1,'losses':2,'ties':17}},
        'family_results':{},'counterfactual_pairs':{},'audit':{'status':'PASS'}}


def test_aggregate_does_not_imply_replay_or_model():
    r=render(aggregate())
    assert 'nie wykonano ponownego audytu' in r
    assert 'nie podano w dostarczonym agregacie' in r
    assert 'Nie liczymy p-value' in r
    assert '−5' in r or '-5,0' in r
    assert 'przerejestrowan' not in r


def test_presentation_preserves_all_data():
    a=aggregate();before=deepcopy(a);render(a);assert a==before


def test_unavailable_fields_not_zero():
    r=render(aggregate())
    assert 'nieestymowany' in r
    assert 'Nie wiadomo, który mechanizm' in r


def test_html_injection_escaped():
    a=aggregate();a['model_identity']={'model':'<script>alert(1)</script>'};r=render(a)
    assert '<script>' not in r and '&lt;script&gt;' in r


def test_write_existing_report_refused(tmp_path):
    p=tmp_path/'s.json';write_json(p,aggregate());out=tmp_path/'r.html'
    assert write_report(p,out)['live_model_calls']==0
    with pytest.raises(FileExistsError): write_report(p,out)


def test_mismatched_diagnostics_refused(tmp_path):
    p=tmp_path/'s.json';write_json(p,aggregate());d=tmp_path/'d.json';write_json(d,{'manifest_hash':'different'})
    with pytest.raises(ValueError):write_report(p,tmp_path/'o.html',d)


@pytest.fixture
def fixture_study(tmp_path):
    path=tmp_path/'study';smoke(path,load_config(ASSETS/'configs'/'pilot.json'));return path


def test_diagnostic_readonly_and_counts(fixture_study,tmp_path):
    before={str(p):p.read_bytes() for p in fixture_study.rglob('*') if p.is_file()}
    out=tmp_path/'diagnosis';r=inspect_study(fixture_study,out)
    assert r['integrity']['status']=='PASS'
    assert r['integrity']['present']==40
    assert r['integrity']['replay_performed'] is False
    assert r['clusters_observed']==1
    assert sum(a['episodes'] for a in r['arms'].values())==40
    assert {str(p):p.read_bytes() for p in fixture_study.rglob('*') if p.is_file()}==before
    assert (out/'diagnostic_trials.csv').exists()


def test_diagnostic_prevents_write_inside_study(fixture_study):
    with pytest.raises(ValueError): inspect_study(fixture_study,fixture_study/'newdiag')


def test_diagnostic_detects_tampering(fixture_study,tmp_path):
    p=next((fixture_study/'trials').glob('*.json'));r=read_json(p);r['duration_s']+=1;write_json(p,r)
    d=inspect_study(fixture_study,tmp_path/'d')
    assert d['integrity']['status']=='FAIL'
    assert any('artifact hash' in e for e in d['integrity']['errors'])


def test_diagnostic_not_replace_old(fixture_study,tmp_path):
    out=tmp_path/'d';inspect_study(fixture_study,out)
    with pytest.raises(FileExistsError):inspect_study(fixture_study,out)


def test_smoke_report_explicit_test_double(fixture_study):
    r=(fixture_study/'report.html').read_text()
    assert 'HARNESS_SELFTEST_ONLY' in r
    assert 'Nie są wynikami modelu' in r


def test_diagnostic_can_render_without_regrade(fixture_study,tmp_path):
    d=tmp_path/'d';inspect_study(fixture_study,d)
    out=tmp_path/'view.html';r=write_report(fixture_study/'summary.json',out,d/'diagnostics.json')
    assert r['regraded'] is False
    assert 'Epizody z błędem schematu' in out.read_text()
