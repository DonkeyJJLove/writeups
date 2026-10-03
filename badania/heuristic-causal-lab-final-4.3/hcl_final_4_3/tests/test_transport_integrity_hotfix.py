"""Regression tests for HCL-owned faults, not evidence about a live model."""
import copy
import json
from pathlib import Path
import pytest
from heuristic_lab.grading import parse_response_audited
from heuristic_lab.qualification_contract import validate_qualification_action
from heuristic_lab.research_runtime import _clone_research_command, _research_transport_ok
from heuristic_lab.providers import HTTPProvider, ProviderError
from heuristic_lab.lion_setup import _qualification_messages, _qualify_transports, QUALIFICATION_SEED_BASE
from heuristic_lab.design import load_config
from heuristic_lab.generators import generate
from heuristic_lab.tools import Environment
from heuristic_lab.util import ASSETS
from heuristic_lab.models import ProviderReply


@pytest.mark.parametrize('field',['request','action','type'])
def test_unknown_action_field_is_not_silently_discarded(field):
    with pytest.raises(ValueError):
        parse_response_audited(json.dumps({'kind':'tool',field:{'name':'read','args':{'id':'packet'}}}))

@pytest.mark.parametrize('name',[None,'','   ',42,False])
def test_missing_or_nonstr_tool_is_not_manufactured(name):
    with pytest.raises(ValueError,match='tool name'):
        parse_response_audited(json.dumps({'kind':'tool','tool_name':name,'args':{}}))

def test_explicit_none_tool_can_be_a_bad_model_action_but_never_qualifies():
    action,_=parse_response_audited('{"kind":"tool","name":"none","args":{}}')
    assert action['name']=='none'
    with pytest.raises(ValueError,match='QUALIFICATION_TOOL_NAME'):
        validate_qualification_action('post_observation_state_update',action)

@pytest.mark.parametrize('bad',['not_authorized','ANSWER_NOW',12,False])
def test_invalid_explicit_decision_is_not_reinterpreted(bad):
    with pytest.raises(ValueError,match='decision'):
        parse_response_audited(json.dumps({'kind':'final','decision':bad,'answer':7}))

@pytest.mark.parametrize('confidence',[-1,2,'bad',True])
def test_supplied_invalid_confidence_is_not_clamped(confidence):
    with pytest.raises(ValueError,match='confidence'):
        parse_response_audited(json.dumps({'kind':'final','decision':'answer','answer':7,'confidence':confidence}))

@pytest.mark.parametrize('other',[8,True,False])
def test_conflicting_answers_are_rejected(other):
    with pytest.raises(ValueError,match='conflicting answer'):
        parse_response_audited(json.dumps({'kind':'final','decision':'answer','answer':7,'response':other}))

@pytest.mark.parametrize('value',[0,False,-12])
def test_falsy_answer_alias_not_lost(value):
    action,_=parse_response_audited(json.dumps({'kind':'final','decision':'none','args':{'response':value}}))
    assert type(action['answer']) is type(value) and action['answer']==value


def test_post_observation_is_real_read_not_fabricated_value7():
    cfg=load_config(ASSETS/'configs'/'study.json')
    messages=_qualification_messages(cfg,'neutral')
    assert len(messages)==16
    for j in range(4):
        case=generate(cfg['families'][j],QUALIFICATION_SEED_BASE+j,0,cfg['phase'])
        obs=Environment(case,cfg['budget']['tool_work']).step('read',{'id':'packet'})
        text=messages[10+j][1][-1]['content']
        parsed=json.loads(text.split('\n')[1])
        assert parsed==obs
        assert parsed['data']==case.public['packet']


def test_parser_success_alone_cannot_qualify_missing_tool():
    class Bad:
        config={}
        def complete(self,*args,**kwargs):
            return ProviderReply('{"kind":"tool","name":"none","args":{}}',{}, {'finish_reason':'stop'})
    cfg=load_config(ASSETS/'configs'/'study.json');provider=Bad()
    with pytest.raises(ProviderError,match='QUALIFICATION_TOOL_NAME'):
        _qualify_transports(provider,cfg)
    result=provider.qualification_partial['candidates'][0]
    assert result['requests']==1 and result['rows']==[]


def test_runtime_profile_parses_channels_and_does_not_mutate_prod_dict():
    prod={'Name':'llama-server.exe','ExecutablePath':'C:/llama-server.exe',
          'CommandLine':'C:/llama-server.exe -m C:/model.gguf --host 127.0.0.1 --port 8772 -c 4096 --no-jinja --reasoning off --reasoning-format none --chat-template gpt-oss'}
    old=copy.deepcopy(prod)
    args=_clone_research_command(prod,8773,8192)
    assert prod==old
    assert '--jinja' in args and '--no-jinja' not in args
    assert args[args.index('--reasoning-format')+1]=='auto'
    assert args[args.index('--port')+1]=='8773'
    assert _research_transport_ok({'Name':'llama-server.exe','CommandLine':' '.join(args)})
    assert not _research_transport_ok(old)

class FakeResponse:
    status=200
    def __init__(self,raw):self.raw=raw
    def __enter__(self):return self
    def __exit__(self,*args):return False
    def read(self,n):return self.raw[:n]
class FakeOpener:
    def __init__(self,raw):self.raw=raw;self.sent=None
    def open(self,request,timeout):self.sent=request.data;return FakeResponse(self.raw)

@pytest.mark.parametrize('content,finish,error',[
    ('<|start|>assistant<|channel|>analysis<|message|>not JSON','stop','GPT_OSS_CHANNEL_LEAK'),
    ('{"kind":','length',None),
    ('not JSON','stop','STRUCTURED_TRANSPORT_INVALID_JSON'),
])
def test_raw_HTTP_survives_complete_validation_failure(tmp_path,content,finish,error):
    raw=json.dumps({'choices':[{'message':{'content':content},'finish_reason':finish}]}).encode()
    provider=HTTPProvider({'type':'openai_compatible','url':'http://127.0.0.1:8773/v1','model':'fixture',
                          'reasoning_format':'auto','structured_output_mode':'json_object','http_evidence_dir':str(tmp_path)})
    fake=FakeOpener(raw);provider.opener=fake
    if error:
        with pytest.raises(ProviderError,match=error):
            provider.complete([{'role':'user','content':'fixture'}],1,768,schema={'type':'object'})
    else:
        reply=provider.complete([{'role':'user','content':'fixture'}],1,768,schema={'type':'object'})
        assert reply.text==content and reply.metadata['output_cap_reached']
    folder=Path(provider.last_http_evidence)
    assert (folder/'response.raw').read_bytes()==raw
    assert (folder/'request.json').read_bytes()==fake.sent
    body=json.loads(fake.sent)
    assert body['reasoning_format']=='auto'
    assert body['response_format']=={'type':'json_object'}
    assert 'Authorization' not in (folder/'request.json').read_text()
    assert json.loads((folder/'receipt.json').read_text())['response_received'] is True


def test_evidence_does_not_overwrite_first_attempt(tmp_path):
    raw=b'{"choices":[{"message":{"content":"{}"},"finish_reason":"stop"}]}'
    provider=HTTPProvider({'type':'openai_compatible','url':'http://127.0.0.1:8773/v1','model':'fixture',
                          'structured_output_mode':'json_object','http_evidence_dir':str(tmp_path)})
    provider.opener=FakeOpener(raw)
    provider.complete([],1,100,schema={});a=provider.last_http_evidence
    provider.complete([],1,100,schema={});b=provider.last_http_evidence
    assert a!=b and Path(a).exists() and Path(b).exists()

def test_bundle_contains_only_this_transport_trace_and_never_headers(tmp_path):
    import zipfile
    from heuristic_lab.study_runner import bundle_preflight_failure
    run=tmp_path/'run';run.mkdir()
    (run/'unrelated_secret.txt').write_text('NOT_FOR_EXPORT')
    trace=run/'transport_http'/'call';trace.mkdir(parents=True)
    (trace/'request.json').write_text('{"messages":[]}')
    (trace/'response.raw').write_text('raw')
    (run/'profile.preflight.json').write_text('{"status":"FAIL"}')
    bundle=bundle_preflight_failure(run,'failed')
    with zipfile.ZipFile(bundle) as z:
        names=set(z.namelist())
        assert 'unrelated_secret.txt' not in names
        assert 'transport_http/call/response.raw' in names
        assert 'failure_receipt.json' in names
    with pytest.raises(FileExistsError):bundle_preflight_failure(run,'do not overwrite')
