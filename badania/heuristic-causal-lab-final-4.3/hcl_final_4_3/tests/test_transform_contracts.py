import pytest
from heuristic_lab.generators import generate
from heuristic_lab.tools import Environment
from heuristic_lab.references import COUNT_ORACLES


def test_direct_enumeration_timeout_is_not_unsat():
    env=Environment(generate('factor_count',1,0),20)
    out=env.step('enumerate',{})
    assert out['status']=='UNKNOWN_BUDGET'
    assert not env.observations[out['receipt']].conclusive
    assert env.observations[out['receipt']].attests is None


def test_work_budget_is_shared_across_tools():
    env=Environment(generate('linear_count',1,0),5)
    for _ in range(6):out=env.step('read',{'id':'packet'})
    assert out['status']=='UNKNOWN_BUDGET'
    assert env.step('eliminate',{})['status']=='UNKNOWN_BUDGET'


def test_invalid_cnf_partition_finds_crossing_constraint():
    env=Environment(generate('factor_count',3,1))
    out=env.step('factor',{'groups':[[i] for i in range(12)]})
    assert out['status']=='INVALID_TRANSFORM'
    assert 'crosses' in out['message']
    assert env.invalid_transform_attempts==1

@pytest.mark.parametrize('groups',[[],[[0,0],[1]],[[True],[1]],[[0],[99]],'all'])
def test_partition_rejects_missing_duplicate_and_invalid_indices(groups):
    env=Environment(generate('factor_count',1,0))
    assert env.step('factor',{'groups':groups})['status']=='INVALID_TRANSFORM'


def test_suffix_rejects_loss_of_necessary_history():
    env=Environment(generate('suffix_count',3,1))
    result=env.step('suffix',{'memory':0})
    assert result['status']=='INVALID_TRANSFORM'


def test_cover_multiplicity_is_semantic_not_cosmetic():
    case=generate('cover_count',1,1);env=Environment(case)
    groups={}
    for i,row in enumerate(case.public['packet']['problem']['rows']):groups.setdefault(tuple(row),[]).append(i)
    assert env.step('quotient',{'groups':list(groups.values()),'preserve_multiplicity':False})['status']=='INVALID_TRANSFORM'
    result=env.step('quotient',{'groups':list(groups.values()),'preserve_multiplicity':True})
    assert result['status']=='COUNT'
    assert result['value']==case.private['expected']['answer']


def test_recovery_does_not_change_access_to_primary():
    case=generate('recovery',11,1);env=Environment(case)
    assert env.step('recover',{})['data']['service_status']=='UNAVAILABLE'
    assert env.step('read',{'id':'primary'})['data']['service_status']=='TIMEOUT'
    assert env.step('read',{'id':'backup'})['status']=='TOOL_ERROR'


def test_tool_returns_no_unbounded_proof_status():
    env=Environment(generate('linear_count',12,1))
    out=env.step('eliminate',{})
    assert out['status']=='COUNT' and out['value']==0
    assert out['scope']=='this finite input only'
    assert out['verification_level']=='computed_not_formally_certified'
