import json
from heuristic_lab.protocol import ACTION_SCHEMA, PROBE_SCHEMA
from heuristic_lab.grading import parse_response
from heuristic_lab.analysis import _qualification_gate
from heuristic_lab.engine import run_episode
from heuristic_lab.generators import generate
from heuristic_lab.models import ProviderReply


def test_action_schema_is_flat_and_branch_agnostic():
    assert ACTION_SCHEMA['type'] == 'object'
    assert ACTION_SCHEMA['additionalProperties'] is False
    assert set(ACTION_SCHEMA['properties']['kind']['enum']) == {'tool','final'}
    assert 'oneOf' not in ACTION_SCHEMA
    assert {'kind','tool_name','args','decision','answer','evidence','confidence','status','reason'} == set(ACTION_SCHEMA['required'])


def test_probe_schema_is_deliberately_exact():
    assert PROBE_SCHEMA['properties']['kind']['const'] == 'probe'
    assert PROBE_SCHEMA['properties']['value']['const'] == 7
    assert PROBE_SCHEMA['additionalProperties'] is False


def test_valid_tool_contract_still_parses():
    x={'kind':'tool','name':'read','args':{'id':'packet'}}
    assert parse_response(json.dumps(x)) == x


def test_valid_final_contract_still_parses():
    x={'kind':'final','decision':'answer','answer':7,'evidence':['receipt-1'],'confidence':.7,'status':'SUPPORTED','reason':'evidence'}
    assert parse_response(json.dumps(x)) == x




def test_flat_tool_contract_parses_to_canonical_action():
    x={'kind':'tool','tool_name':'read','args':{'id':'packet'},'decision':'none','answer':None,'evidence':[],
       'confidence':0.0,'status':'UNKNOWN','reason':'read'}
    assert parse_response(json.dumps(x)) == {'kind':'tool','name':'read','args':{'id':'packet'}}


def test_flat_final_contract_parses_to_canonical_action():
    x={'kind':'final','tool_name':'none','args':{},'decision':'answer','answer':7,'evidence':['receipt-1'],
       'confidence':.7,'status':'SUPPORTED','reason':'evidence'}
    assert parse_response(json.dumps(x)) == {'kind':'final','decision':'answer','answer':7,'evidence':['receipt-1'],
                                              'confidence':.7,'status':'SUPPORTED','reason':'evidence'}


def test_protocol_error_is_not_failure_to_stop():
    class Bad:
        is_mock=True
        def complete(self,*args): return ProviderReply('not json',{}, {'finish_reason':'stop'})
    budget={'max_turns':6,'max_tokens_per_turn':512,'tool_work':512,'max_context_chars':50000,'episode_seconds':30}
    r=run_episode(generate('authority',4,0),'',Bad(),budget,1)
    assert r['failure']=='PROTOCOL_ERROR'
    assert r['score']['failure_to_stop'] is False
    assert r['score']['protocol_success'] is False


def rows(protocol=1.0,generation=0.0,turn=0.0,provider=0.0,task=0.5,n=100):
    out=[]
    for i in range(n):
        out.append({'protocol_success':i < int(protocol*n),
                    'generation_limit':i < int(generation*n),
                    'failure':'TURN_LIMIT' if i < int(turn*n) else ('PROVIDER_ERROR' if i < int((turn+provider)*n) else None),
                    'task_success':i < int(task*n)})
    return out


def test_qualification_gate_passes_usable_instrument():
    q=_qualification_gate(rows())
    assert q['status']=='PASS'


def test_qualification_gate_rejects_protocol_contamination():
    q=_qualification_gate(rows(protocol=.90))
    assert q['status']=='FAIL'
    assert not q['checks']['protocol_success_rate']['pass']


def test_qualification_gate_rejects_floor_effect():
    q=_qualification_gate(rows(task=.05))
    assert q['status']=='FAIL'
    assert not q['checks']['pooled_task_success_rate']['pass']


def test_qualification_gate_rejects_ceiling_effect():
    q=_qualification_gate(rows(task=.95))
    assert q['status']=='FAIL'


def test_qualification_gate_rejects_turn_limit_dominance():
    q=_qualification_gate(rows(turn=.30))
    assert q['status']=='FAIL'
    assert not q['checks']['turn_limit_rate']['pass']


def test_flat_final_normalizes_observed_llama_response_field_and_none_decision():
    x={
        'kind':'final','tool_name':'none','args':{'response':'7'},'decision':'none','answer':None,
        'evidence':[],'confidence':0.9,'status':'SUPPORTED','reason':'transport placement'
    }
    assert parse_response(json.dumps(x)) == {
        'kind':'final','decision':'answer','answer':7,'evidence':[],
        'confidence':0.9,'status':'SUPPORTED','reason':'transport placement'
    }


def test_flat_final_normalizes_args_answer_boolean_string():
    x={
        'kind':'final','tool_name':'none','args':{'answer':'false'},'decision':'none','answer':None,
        'evidence':[],'confidence':0.5,'status':'SUPPORTED','reason':'transport placement'
    }
    assert parse_response(json.dumps(x))['answer'] is False
    assert parse_response(json.dumps(x))['decision'] == 'answer'


def test_flat_final_does_not_guess_arbitrary_prose_from_args_response():
    x={
        'kind':'final','tool_name':'none','args':{'response':'probably seven'},'decision':'none','answer':None,
        'evidence':[],'confidence':0.5,'status':'SUPPORTED','reason':'transport placement'
    }
    import pytest
    with pytest.raises(ValueError, match='canonicalizable scalar'):
        parse_response(json.dumps(x))


def test_full_study_config_is_confirmatory_and_transport_order_is_preregistered():
    from heuristic_lab.util import ASSETS, read_json
    cfg=read_json(ASSETS/'configs'/'study.json')
    assert cfg['phase']=='confirmatory'
    assert cfg['clusters']==256
    assert cfg['study']['planned_trials']==10240
    assert cfg['protocol']['transport_candidates']==['json_object']
    assert cfg['protocol']['transport_preflight_checks']==16
    assert cfg['protocol']['transport_circuit_breaker']['min_completed_trials']==40
    assert cfg['protocol']['transport_circuit_breaker']['max_pooled_protocol_error_rate']==0.10


def test_neutral_shadow_policy_is_natural_varied_and_not_a_treatment_policy():
    from heuristic_lab.util import ASSETS
    shadow=(ASSETS/'policies'/'neutral_shadow_policy.txt').read_text(encoding='utf-8')
    paragraphs=[x.strip() for x in shadow.split('\n\n') if x.strip()]
    assert len(shadow)>9000
    assert len(paragraphs)>=20
    assert len(set(paragraphs))==len(paragraphs)
    assert 'author_raw' not in shadow
    assert 'strong_control' not in shadow
