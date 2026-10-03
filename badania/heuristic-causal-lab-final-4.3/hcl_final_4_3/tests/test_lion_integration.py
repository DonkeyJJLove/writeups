"""Explicit HTTP fixtures; these are software tests, never model measurements."""
import json
import threading
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
from copy import deepcopy
from pathlib import Path
import pytest
from heuristic_lab.providers import HTTPProvider,ProviderError
from heuristic_lab.llama_guard import runtime_metadata
from heuristic_lab.lion_setup import create_profile
from heuristic_lab.util import ASSETS,read_json,write_json

@pytest.fixture
def llama_server():
    state={'ctx':16384,'tokens':2400,'models':['fixture-not-a-model'],'template':'fixture template',
           'missing':set(),'calls':[],'break_strict_schema':False}
    class Handler(BaseHTTPRequestHandler):
        def log_message(self,*a): pass
        def emit(self,body,status=200):
            data=json.dumps(body).encode();self.send_response(status)
            self.send_header('Content-Type','application/json');self.send_header('Content-Length',str(len(data)))
            self.end_headers();self.wfile.write(data)
        def do_GET(self):
            state['calls'].append(('GET',self.path,None))
            if self.path in state['missing']:return self.emit({'error':'disabled'},404)
            if self.path=='/v1/models':return self.emit({'data':[{'id':x,'owned_by':'fixture'} for x in state['models']]})
            if self.path=='/props':return self.emit({'default_generation_settings':{'n_ctx':state['ctx'],'params':{}},
                                                     'total_slots':1,'chat_template':state['template'],
                                                     'model_path':'fixture.gguf','build_info':'FIXTURE_ONLY'})
            self.emit({'error':'not found'},404)
        def do_POST(self):
            body=json.loads(self.rfile.read(int(self.headers['Content-Length'])))
            state['calls'].append(('POST',self.path,body))
            if self.path in state['missing']:return self.emit({'error':'disabled'},404)
            if self.path=='/apply-template':return self.emit({'prompt':'header'+json.dumps(body['messages'])})
            if self.path=='/tokenize':return self.emit({'tokens':[1]*state['tokens']})
            if self.path=='/v1/chat/completions':
                rf=body.get('response_format',{})
                schema=None
                if rf.get('type')=='json_object' and isinstance(rf.get('schema'),dict):
                    schema=rf.get('schema')
                elif rf.get('type')=='json_schema' and isinstance(rf.get('schema'),dict):
                    schema=rf.get('schema')
                elif rf.get('type')=='json_schema' and isinstance(rf.get('json_schema'),dict):
                    schema=rf['json_schema'].get('schema')
                elif isinstance(body.get('json_schema'),dict):
                    schema=body.get('json_schema')
                if isinstance(schema,dict):
                    if state.get('break_strict_schema'):
                        content='not-json'
                    elif schema.get('properties',{}).get('kind',{}).get('const')=='probe':
                        content='{"kind":"probe","value":7}'
                    else:
                        messages=body.get('messages',[])
                        user='\n'.join(str(x.get('content','')) for x in messages if x.get('role')=='user')
                        if 'Call tool read' in user and 'TOOL_OBSERVATION' not in user:
                            content='{"kind":"tool","tool_name":"read","args":{"id":"packet"},"decision":"none","answer":null,"evidence":[],"confidence":0,"status":"UNKNOWN","reason":"read"}'
                        elif 'TOOL_OBSERVATION' in user:
                            content='{"kind":"final","tool_name":"none","args":{},"decision":"answer","answer":7,"evidence":["receipt-1"],"confidence":0.5,"status":"SUPPORTED","reason":"probe"}'
                        else:
                            content='{"kind":"final","tool_name":"none","args":{},"decision":"answer","answer":7,"evidence":[],"confidence":0.5,"status":"SUPPORTED","reason":"probe"}'
                elif rf.get('type')=='json_object':
                    # Application-validated JSON transport used by HCL 4.3. Emit
                    # compact shapes matching the real target backend behaviour.
                    messages=body.get('messages',[])
                    user='\n'.join(str(x.get('content','')) for x in messages if x.get('role')=='user')
                    if 'final JSON action with answer 7' in user or 'Return one JSON final action with answer 7' in user:
                        content='{"kind":"final","answer":7,"status":"SUPPORTED","confidence":0.5,"evidence":[],"reason":"fixture"}'
                    elif 'tool JSON action calling read' in user or 'Call tool read' in user:
                        content='{"kind":"tool","tool_name":"read","args":{"id":"packet"}}'
                    elif 'TOOL_OBSERVATION' in user:
                        content='{"kind":"final","answer":7,"status":"SUPPORTED","confidence":0.5,"evidence":["shadow-receipt"],"reason":"fixture"}'
                    else:
                        content='{"kind":"tool","tool_name":"read","args":{"id":"packet"}}'
                else:
                    content='{"ok":true}'
                return self.emit({'choices':[{'message':{'content':content},'finish_reason':'stop'}],
                                  'model':'fixture-not-a-model','usage':{'prompt_tokens':state['tokens'],'completion_tokens':4}})
            self.emit({'error':'not found'},404)
    s=ThreadingHTTPServer(('127.0.0.1',0),Handler);t=threading.Thread(target=s.serve_forever,daemon=True);t.start()
    cfg={'type':'openai_compatible','url':f'http://127.0.0.1:{s.server_port}/v1','model':'AUTO',
         'allow_remote':False,'timeout_s':2,'llama_cpp_guard':True}
    yield cfg,state
    s.shutdown();s.server_close();t.join()


def test_live_schema_token_checks_before_generation(llama_server):
    cfg,s=llama_server;p=HTTPProvider(cfg);info=p.inspect()
    assert info['identity']['model']=='fixture-not-a-model'
    assert info['identity']['llama_runtime']['context_tokens_per_slot']==16384
    r=p.complete([{'role':'user','content':'unchanged'}],2,256)
    assert r.metadata['llama_context_check']['required_tokens']==2720
    call=s['calls'][-1];assert call[1]=='/v1/chat/completions'
    assert call[2]['cache_prompt'] is False
    assert call[2]['messages'][0]['content']=='unchanged'
    assert not any(x[0]=='POST' and x[1]=='/props' for x in s['calls'])


def test_overflow_never_sends_generation(llama_server):
    cfg,s=llama_server;s['tokens']=4000;s['ctx']=4096;p=HTTPProvider(cfg);p.inspect()
    with pytest.raises(ProviderError,match='LLAMA_CONTEXT_TOO_SMALL'):p.complete([{'role':'user','content':'x'}],1,256)
    assert not any(x[1]=='/v1/chat/completions' for x in s['calls'])


def test_later_turn_overflow_guard(llama_server):
    cfg,s=llama_server;p=HTTPProvider(cfg);p.inspect();p.complete([],1,256)
    n=sum(x[1]=='/v1/chat/completions' for x in s['calls']);s['tokens']=17000
    with pytest.raises(ProviderError,match='LLAMA_CONTEXT_TOO_SMALL'):p.complete([],2,256)
    assert sum(x[1]=='/v1/chat/completions' for x in s['calls'])==n

@pytest.mark.parametrize('field,value',[('ctx',8192),('template','CHANGED')])
def test_runtime_drift_rejected(llama_server,field,value):
    cfg,s=llama_server;p=HTTPProvider(cfg);p.inspect();s[field]=value
    with pytest.raises(ProviderError,match='LLAMA_RUNTIME_CHANGED'):p.complete([],1,256)

@pytest.mark.parametrize('endpoint',['/props','/apply-template','/tokenize'])
def test_no_fallback_on_missing_guard_endpoint(llama_server,endpoint):
    cfg,s=llama_server;p=HTTPProvider(cfg);p.inspect();s['missing'].add(endpoint)
    with pytest.raises(ProviderError):p.complete([],1,256)
    assert not any(x[1]=='/v1/chat/completions' for x in s['calls'])


def test_no_router_auto_selection(llama_server):
    cfg,s=llama_server;s['models']=['a','b']
    with pytest.raises(ProviderError):HTTPProvider(cfg).inspect()
    cfg['model']='a'
    with pytest.raises(ProviderError,match='single-model'):HTTPProvider(cfg).inspect()


def test_setup_writes_pinned_profile_not_inference(llama_server,tmp_path):
    cfg,s=llama_server
    out=tmp_path/'lion.json'
    r=create_profile(ASSETS/'configs'/'pilot.json',out,cfg['url'])
    assert r['status']=='READY_FOR_PILOT'
    assert len(r['checks'])==20
    assert r['live_generation_requests']==0
    profile=read_json(out)
    assert profile['provider']['model']=='fixture-not-a-model'
    assert profile['provider']['llama_runtime_pin']['context_tokens_per_slot']==16384
    assert profile['arms']==['strong_control','author_raw']
    assert profile['budget']['max_turns']==6
    assert not any(x[1]=='/v1/chat/completions' for x in s['calls'])
    with pytest.raises(FileExistsError):create_profile(ASSETS/'configs'/'pilot.json',out,cfg['url'])


def test_setup_blocked_context_preserves_raw_and_no_config(llama_server,tmp_path):
    cfg,s=llama_server;s['ctx']=4096;s['tokens']=4200;out=tmp_path/'lion.json'
    raw=(ASSETS/'policies'/'author_raw.txt').read_bytes()
    with pytest.raises(ProviderError):create_profile(ASSETS/'configs'/'pilot.json',out,cfg['url'])
    assert not out.exists()
    assert read_json(out.with_suffix('.preflight.json'))['status']=='BLOCKED_CONTEXT'
    assert len(read_json(out.with_suffix('.preflight.json'))['errors'])==20
    assert (ASSETS/'policies'/'author_raw.txt').read_bytes()==raw


def test_full_transport_qualification_is_labelled_and_treatment_blind(llama_server,tmp_path):
    cfg,s=llama_server;r=create_profile(ASSETS/'configs'/'pilot.json',tmp_path/'p.json',cfg['url'],test_inference=True)
    q=r['transport_qualification']
    assert q['status']=='PASS'
    assert q['checks_per_candidate']==16
    assert q['candidate_order']==['json_object']
    assert q['selected_mode']=='json_object'
    assert r['live_generation_requests']==16
    for method, path, body in s['calls']:
        if method == 'POST' and path == '/v1/chat/completions':
            assert body['reasoning_budget_tokens'] == body['max_tokens'] + 1
    profile=read_json(tmp_path/'p.json')
    assert profile['provider']['llama_reasoning_budget_policy']=='above_completion_cap_v1'
    assert sum(x[1]=='/v1/chat/completions' for x in s['calls'])==16


def test_transport_qualification_uses_json_object_without_treatment_data(llama_server,tmp_path):
    cfg,s=llama_server
    r=create_profile(ASSETS/'configs'/'pilot.json',tmp_path/'fallback.json',cfg['url'],test_inference=True)
    q=r['transport_qualification']
    assert q['status']=='PASS'
    assert q['candidate_order']==['json_object']
    assert q['selected_mode']=='json_object'
    assert read_json(tmp_path/'fallback.json')['provider']['structured_output_mode']=='json_object'
    assert r['live_generation_requests']==16
    for method, path, body in s['calls']:
        if method == 'POST' and path == '/v1/chat/completions':
            assert body['reasoning_budget_tokens'] == body['max_tokens'] + 1
    profile=read_json(tmp_path/'fallback.json')
    assert profile['provider']['llama_reasoning_budget_policy']=='above_completion_cap_v1'


def test_missing_metadata_not_inferred_from_config():
    with pytest.raises(ProviderError,match='CONTEXT_UNKNOWN'):runtime_metadata({'n_ctx_train':131072})


def test_bare_root_is_rejected():
    with pytest.raises(ProviderError,match='LLAMA_URL'):
        HTTPProvider({'type':'openai_compatible','url':'http://127.0.0.1:8772','model':'x','llama_cpp_guard':True})


def test_inspected_profile_detects_changed_runtime(llama_server):
    cfg,s=llama_server;p=HTTPProvider(cfg);p.inspect();frozen=deepcopy(p.config);s['ctx']=8192
    with pytest.raises(ProviderError,match='LLAMA_RUNTIME_CHANGED'):HTTPProvider(frozen).inspect()


def test_full_confirmatory_profile_qualifies_before_seal(llama_server,tmp_path):
    cfg,s=llama_server
    out=tmp_path/'study_profile.json'
    r=create_profile(ASSETS/'configs'/'study.json',out,cfg['url'],test_inference=True)
    assert r['status']=='READY_FOR_STUDY'
    assert len(r['checks'])==20
    assert r['plan']['trials']==10240
    assert r['transport_qualification']['checks_per_candidate']==16
    assert r['transport_qualification']['selected_mode']=='json_object'
    profile=read_json(out)
    assert profile['phase']=='confirmatory'
    assert profile['provider']['structured_output_mode']=='json_object'
    assert profile['provider']['transport_qualification_hash']
