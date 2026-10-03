from copy import deepcopy
import pytest
from heuristic_lab.design import load_config
from heuristic_lab.util import ROOT

@pytest.fixture
def cfg():
    return deepcopy(load_config(ROOT/'configs'/'pilot.json'))
