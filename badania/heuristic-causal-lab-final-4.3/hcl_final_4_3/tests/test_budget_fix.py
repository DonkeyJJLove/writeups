"""Offline regression against user-supplied HTTP traces; no live model calls."""
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import pytest

from heuristic_lab.generation_budget import BUDGET_POLICY, request_reasoning_budget
from heuristic_lab.providers import HTTPProvider, ProviderError
from heuristic_lab.protocol import ACTION_SCHEMA
from heuristic_lab.grading import parse_response_audited
from heuristic_lab.qualification_contract import validate_qualification_action
from heuristic_lab.design import load_config, plan
from heuristic_lab.util import ASSETS

DATA = Path(__file__).parent / 'data' / 'observed_budget_ab'

class Guard:
    def __init__(self): self.caps = []
    def check(self, messages, cap, remaining=None):
        self.caps.append(cap)
        return {'status': 'TEST_DOUBLE', 'required_tokens': 2632 + cap + 64}

class Response:
    status = 200
    def __init__(self, raw): self.raw = raw
    def __enter__(self): return self
    def __exit__(self, *a): return False
    def read(self, n): return self.raw[:n]

class ReplayOpener:
    def __init__(self, raw): self.raw = raw; self.sent = []
    def open(self, req, timeout):
        self.sent.append(json.loads(req.data))
        return Response(self.raw)


def provider_for_trace(tmp_path, name='B_no_forced_budget_end'):
    source = json.loads((DATA / 'A_original/request.json').read_bytes())
    c = {'type': 'openai_compatible', 'url': 'http://127.0.0.1:8773/v1',
         'model': source['model'], 'llama_cpp_guard': True,
         'reasoning_format': source['reasoning_format'],
         'reasoning_effort': source['reasoning_effort'],
         'temperature': source['temperature'], 'structured_output_mode': 'json_object',
         'llama_reasoning_budget_policy': BUDGET_POLICY, 'http_evidence_dir': str(tmp_path)}
    p = HTTPProvider(c)
    p.llama_guard = Guard()
    p.opener = ReplayOpener((DATA / name / 'response.raw').read_bytes())
    return p, source


def test_actual_B_wire_request_is_exact_single_parameter_change(tmp_path):
    p, source = provider_for_trace(tmp_path)
    original = deepcopy(source['messages'])
    reply = p.complete(source['messages'], source['seed'], source['max_tokens'], schema=ACTION_SCHEMA)
    expected = json.loads((DATA / 'B_no_forced_budget_end/request.json').read_bytes())
    assert p.opener.sent == [expected]
    assert source['messages'] == original
    assert p.llama_guard.caps == [768]
    assert reply.usage['completion_tokens'] == 55
    action, audit = parse_response_audited(reply.text)
    validate_qualification_action('first_turn_authority', action)
    assert action == {'kind': 'tool', 'name': 'read', 'args': {'id': 'packet'}}
    assert reply.metadata['llama_reasoning_budget_control']['reasoning_budget_tokens_requested'] == 769
    assert json.loads((Path(p.last_http_evidence) / 'request.json').read_bytes()) == expected
    assert (Path(p.last_http_evidence) / 'response.raw').read_bytes() == (DATA / 'B_no_forced_budget_end/response.raw').read_bytes()


@pytest.mark.parametrize('cap', [64, 192, 384, 512, 768, 1024])
def test_override_follows_each_call_limit_not_a_hidden_extra_budget(tmp_path, cap):
    p, source = provider_for_trace(tmp_path)
    p.complete(source['messages'], source['seed'], cap, schema=ACTION_SCHEMA)
    sent = p.opener.sent[-1]
    assert sent['reasoning_budget_tokens'] == cap + 1
    assert sent['max_tokens'] == cap
    assert p.llama_guard.caps == [cap]


@pytest.mark.parametrize('name', ['A_original', 'A_repeat', 'C_original_budget_no_json_grammar'])
def test_real_bad_responses_are_still_rejected_without_extracting_an_action(tmp_path, name):
    p, source = provider_for_trace(tmp_path, name)
    with pytest.raises(ProviderError, match='GPT_OSS_CHANNEL_LEAK'):
        p.complete(source['messages'], source['seed'], 768, schema=ACTION_SCHEMA)
    assert (Path(p.last_http_evidence) / 'response.raw').read_bytes() == (DATA / name / 'response.raw').read_bytes()


@pytest.mark.parametrize('cap', [0, -1, True, 1.5, '768', 2**31-1])
def test_invalid_cap_is_rejected_without_HTTP(tmp_path, cap):
    p, source = provider_for_trace(tmp_path)
    with pytest.raises(ProviderError, match='Completion cap'):
        p.complete(source['messages'], source['seed'], cap, schema=ACTION_SCHEMA)
    assert p.opener.sent == []
    assert p.llama_guard.caps == []


@pytest.mark.parametrize('config', [
    {'type': 'ollama', 'llama_cpp_guard': True},
    {'type': 'openai_compatible'},
    {'type': 'openai_compatible', 'llama_cpp_guard': False},
])
def test_override_never_implicitly_targets_non_llama_providers(config):
    config = {**config, 'url': 'http://127.0.0.1:8773/v1', 'model': 'fixture',
              'llama_reasoning_budget_policy': BUDGET_POLICY}
    with pytest.raises(ProviderError, match='requires an explicit llama_cpp_guard'):
        HTTPProvider(config)


def test_invalid_policy_does_not_fall_back_to_server_zero():
    with pytest.raises(ValueError, match='Unsupported'):
        request_reasoning_budget({'llama_reasoning_budget_policy': 'typo'}, 768)


def test_provider_without_explicit_policy_is_unchanged():
    assert request_reasoning_budget({}, 768) is None


def test_study_freezes_same_full_research_and_new_budget_policy():
    cfg = load_config(ASSETS / 'configs' / 'study.json')
    assert cfg['phase'] == 'confirmatory'
    assert cfg['provider']['llama_reasoning_budget_policy'] == BUDGET_POLICY
    assert cfg['clusters'] == 256
    assert cfg['arms'] == ['strong_control', 'author_raw']
    assert cfg['budget']['max_tokens_per_turn'] == 768
    assert plan(cfg)['trials'] == 10240


def test_observed_variants_and_return_to_original_are_not_synthetic():
    names = ['A_original', 'B_no_forced_budget_end', 'D_no_forced_budget_end_no_json_grammar',
             'C_original_budget_no_json_grammar', 'A_repeat']
    requests = {n: json.loads((DATA / n / 'request.json').read_bytes()) for n in names}
    expected_changes = [set(), {'reasoning_budget_tokens'}, {'reasoning_budget_tokens', 'response_format'},
                        {'response_format'}, set()]
    base = requests['A_original']
    for name, changes in zip(names, expected_changes):
        r = requests[name]
        assert {k for k in r.keys() | base.keys() if r.get(k) != base.get(k)} == changes
        receipt = json.loads((DATA / name / 'result.json').read_bytes())
        for file, field in [('request.json', 'request_sha256'), ('response.raw', 'response_sha256')]:
            assert hashlib.sha256((DATA / name / file).read_bytes()).hexdigest() == receipt[field]
    a = json.loads((DATA / 'A_original/response.raw').read_bytes())['choices'][0]['message']['content']
    again = json.loads((DATA / 'A_repeat/response.raw').read_bytes())['choices'][0]['message']['content']
    assert a == again


def test_metadata_subclient_does_not_inherit_generation_only_policy():
    config = {'type': 'openai_compatible', 'url': 'http://127.0.0.1:8773/v1',
              'model': 'fixture', 'llama_cpp_guard': True,
              'llama_reasoning_budget_policy': BUDGET_POLICY}
    p = HTTPProvider(config)
    assert p.config['llama_reasoning_budget_policy'] == BUDGET_POLICY
    assert 'llama_reasoning_budget_policy' not in p.llama_guard.http.config
    assert p.llama_guard.http.llama_guard is None
