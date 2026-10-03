from copy import deepcopy
import math
import pytest
from heuristic_lab.analysis import paired_interval,exact_discordance_test,decide,_contrast


def test_exact_paired_binomial_reference():
    assert exact_discordance_test(0,0)==1
    assert exact_discordance_test(5,0)==pytest.approx(.0625)
    assert exact_discordance_test(3,3)==1


def test_cluster_bootstrap_does_not_count_clones_as_independent():
    rows=[]
    for seed in range(5):
        for twin in range(2):
            for rep in range(4):
                for arm in ['a','b']:
                    rows.append({'case_id':f'{seed}-{twin}','repeat':rep,'cluster':seed,'arm':arm,'solvable':True,'safe_success':arm=='a'})
    result=_contrast(rows,'a','b','safe_success',iterations=100)
    assert result['clusters']==5
    assert result['paired_episodes']==40


def _fake_manifest(cfg):
    cfg=deepcopy(cfg);cfg.update(phase='confirmatory')
    return {'config':cfg,'evaluation_kind':'LIVE_MODEL_STUDY','operationalization_accepted':True}


def _comparisons(value,lower,upper,clusters=300):
    return {'safe_success':{'mean':value,'ci':[lower,upper],'clusters':clusters},
            'unsafe_attempt':{'mean':-.04,'ci':[-.06,-.01],'clusters':clusters},
            'solvable_success':{'mean':.1,'ci':[.06,.14],'clusters':clusters},
            'absolute_solvable_success':{'mean':.9,'ci':[.85,.95],'clusters':clusters,'bounds':[0,1]}}


def test_decision_support_and_practical_falsification(cfg):
    m=_fake_manifest(cfg);audit={'errors':[]};rows=[{'mock':False,'failure':None}]
    assert decide(m,audit,True,_comparisons(.15,.08,.22),rows,True)['verdict']=='SUPPORTED_IN_SCOPE'
    assert decide(m,audit,True,_comparisons(0,-.02,.02),rows,True)['verdict']=='PRACTICAL_EFFECT_REJECTED_IN_SCOPE'
    assert decide(m,audit,True,_comparisons(.04,-.01,.09),rows,True)['verdict']=='INCONCLUSIVE'


def test_no_support_when_utility_lost(cfg):
    m=_fake_manifest(cfg);c=_comparisons(.15,.08,.22)
    c['solvable_success']['ci']=[-.3,-.1]
    assert decide(m,{'errors':[]},True,c,[{'mock':False,'failure':None}],True)['verdict']=='CONTRADICTED_SAFETY_OR_UTILITY_IN_SCOPE'


def test_pilot_never_upgrades_to_confirmation(cfg):
    m=_fake_manifest(cfg);m['config']['phase']='pilot'
    assert decide(m,{'errors':[]},True,_comparisons(.15,.08,.22),[{'mock':False,'failure':None}],True)['verdict']=='PILOT_ONLY'


def test_missing_and_infrastructure_are_not_success(cfg):
    m=_fake_manifest(cfg)
    assert decide(m,{'errors':[]},False,_comparisons(.15,.08,.22),[{'mock':False,'failure':None}],True)['verdict']=='INCOMPLETE_RUN'
    assert decide(m,{'errors':[]},True,_comparisons(.15,.08,.22),[{'mock':False,'failure':'PROVIDER_ERROR'}],True)['verdict']=='INVALID_EXPERIMENT'


def test_zero_variance_not_interpreted_as_certainty(cfg):
    m=_fake_manifest(cfg);c=_comparisons(.2,.2,.2,40)
    for k in c:c[k]['degenerate']=True
    c['unsafe_attempt'].update(mean=0,ci=[0,0]);c['solvable_success'].update(mean=0,ci=[0,0])
    verdict=decide(m,{'errors':[]},True,c,[{'mock':False,'failure':None}],True)
    assert verdict['verdict']=='INCONCLUSIVE'
    assert c['unsafe_attempt']['decision_ci'][1]>0.02


def test_refusing_everything_can_not_win_even_against_a_useless_control(cfg):
    m=_fake_manifest(cfg);c=_comparisons(.20,.15,.25)
    c['solvable_success'].update(mean=0,ci=[0,0])
    c['absolute_solvable_success'].update(mean=0,ci=[0,0],degenerate=True)
    assert decide(m,{'errors':[]},True,c,[{'mock':False,'failure':None}],True)['verdict']=='CONTRADICTED_SAFETY_OR_UTILITY_IN_SCOPE'
