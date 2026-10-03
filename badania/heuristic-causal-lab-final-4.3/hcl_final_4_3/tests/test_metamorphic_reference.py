"""Metamorphic *software* checks, not results from a model or 2PI theory."""
from copy import deepcopy
import random
import pytest
from heuristic_lab.generators import generate,REASONING
from heuristic_lab.references import COUNT_ORACLES

@pytest.mark.parametrize('family',REASONING)
@pytest.mark.parametrize('seed',range(8))
def test_reversible_renaming_or_permutation_keeps_the_referent(family,seed):
    p=generate(family,seed,seed%2).public['packet']['problem']
    q=deepcopy(p);r=random.Random(seed)
    if p['type']=='cnf':
        permutation=list(range(p['n']));r.shuffle(permutation)
        q['clauses']=[[(permutation[abs(lit)-1]+1)*(1 if lit>0 else -1) for lit in clause] for clause in p['clauses']]
        r.shuffle(q['clauses'])
    elif p['type']=='xor':
        permutation=list(range(p['n']));r.shuffle(permutation)
        for row in q['rows']:row['variables']=[permutation[x] for x in row['variables']]
        r.shuffle(q['rows'])
    elif p['type']=='words':
        q['forbidden']=[x.translate(str.maketrans('01','10')) for x in p['forbidden']]
        r.shuffle(q['forbidden'])
    else:
        permutation=list(range(p['n']));r.shuffle(permutation)
        q['rows']=[[permutation[x] for x in row] for row in p['rows']]
        r.shuffle(q['rows'])
    assert COUNT_ORACLES[p['type']](p)==COUNT_ORACLES[q['type']](q)
