import pytest
from heuristic_lab.generators import FAMILIES, generate
from heuristic_lab.fixtures import OracleFixture
from heuristic_lab.engine import run_episode
from heuristic_lab.tools import Environment
from heuristic_lab.references import COUNT_ORACLES
from heuristic_lab.util import canonical

@pytest.mark.parametrize('family',FAMILIES)
@pytest.mark.parametrize('twin',[0,1])
@pytest.mark.parametrize('seed',[1,2,3])
def test_generated_pair_oracle_executes_all_contracts(family,twin,seed,cfg):
    case=generate(family,seed,twin)
    result=run_episode(case,'neutral policy',OracleFixture(case),cfg['budget'],11)
    assert result['score']['safe_success'],result
    assert result['mock'] is True
    assert not result['score']['unsafe_attempt']
    assert not result['score']['unsupported_claim']

@pytest.mark.parametrize('family',FAMILIES)
def test_deterministic_generation(family):
    assert generate(family,12,0).to_dict()==generate(family,12,0).to_dict()
    a=generate(family,12,0);b=generate(family,12,1)
    assert a.case_id!=b.case_id
    assert a.private['expected']!=b.private['expected']

@pytest.mark.parametrize('family',FAMILIES)
def test_always_abstain_does_not_pass_solvable_cases(family,cfg):
    case=generate(family,1,0)
    result=run_episode(case,'',OracleFixture(case,'always_abstain'),cfg['budget'],2)
    if case.private['solvable']:
        assert not result['score']['safe_success']
        assert result['score']['overabstention']

@pytest.mark.parametrize('family',FAMILIES)
def test_unsafe_attempt_is_scored_before_firewall(family,cfg):
    case=generate(family,1,1)
    result=run_episode(case,'',OracleFixture(case,'unsafe'),cfg['budget'],2)
    assert result['score']['unsafe_attempt']
    assert result['firewall']['blocked_unsafe_execution']
    assert not result['score']['safe_success']


def test_reference_not_sent_to_actor(cfg):
    case=generate('state_update',5,0)
    class Spy(OracleFixture):
        def complete(self,messages,seed,max_tokens):
            payload=canonical(messages)
            for token in ['"expected"','"solvable"','"private"','"family"','"cluster"',case.case_id]:
                assert token not in payload
            return super().complete(messages,seed,max_tokens)
    result=run_episode(case,'opaque',Spy(case),cfg['budget'],2)
    assert result['score']['safe_success']


def test_state_update_requires_both_documents(cfg):
    case=generate('state_update',7,0);env=Environment(case)
    env.step('read',{'id':'packet'})
    from heuristic_lab.grading import grade
    final={'kind':'final','decision':'answer','answer':case.private['expected']['answer'],
           'evidence':['receipt-1'],'confidence':1.,'status':'VERIFIED','reason':'guess'}
    result=grade(case,final,env)
    assert result['unsupported_claim'] and not result['safe_success']
