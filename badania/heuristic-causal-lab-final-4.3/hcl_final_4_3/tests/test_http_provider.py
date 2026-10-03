import json
import threading
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
import pytest
from heuristic_lab.providers import HTTPProvider,ProviderError,validate_endpoint
from heuristic_lab.models import ProviderReply
from heuristic_lab.engine import run_episode
from heuristic_lab.generators import generate

@pytest.fixture
def server():
    calls=[]
    class Handler(BaseHTTPRequestHandler):
        def log_message(self,*a):pass
        def emit(self,obj,status=200):
            data=json.dumps(obj).encode();self.send_response(status);self.send_header('Content-Type','application/json');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
        def do_GET(self):
            calls.append(('GET',self.path,None))
            if self.path=='/api/tags':self.emit({'models':[{'name':'test-local','digest':'fixture-digest','details':{'format':'test'}}]})
            elif self.path=='/v1/models':self.emit({'data':[{'id':'test-local','owned_by':'test-only'}]})
            else:self.emit({'error':'not found'},404)
        def do_POST(self):
            body=json.loads(self.rfile.read(int(self.headers['Content-Length'])));calls.append(('POST',self.path,body))
            answer=json.dumps({'kind':'tool','name':'read','args':{'id':'packet'}})
            if self.path=='/api/chat':self.emit({'model':'test-local','message':{'content':answer},'done':True,'done_reason':'stop','prompt_eval_count':23,'eval_count':8})
            elif self.path=='/v1/chat/completions':self.emit({'model':'test-local','choices':[{'message':{'content':answer},'finish_reason':'stop'}],'usage':{'prompt_tokens':23,'completion_tokens':8}})
            else:self.emit({'error':'not found'},404)
    s=ThreadingHTTPServer(('127.0.0.1',0),Handler);t=threading.Thread(target=s.serve_forever,daemon=True);t.start()
    yield f'http://127.0.0.1:{s.server_port}',calls
    s.shutdown();s.server_close();t.join()

@pytest.mark.parametrize('backend',['ollama','openai_compatible'])
def test_real_http_path_and_schema_with_explicit_test_server(server,backend):
    url,calls=server
    c={'type':backend,'url':url+('/v1' if backend=='openai_compatible' else ''),'model':'AUTO','allow_remote':False,'timeout_s':2}
    p=HTTPProvider(c);info=p.inspect()
    assert info['identity']['model']=='test-local'
    reply=p.complete([{'role':'user','content':'test'}],123,37)
    assert reply.usage['completion_tokens']==8
    assert json.loads(reply.text)['kind']=='tool'
    body=calls[-1][2]
    assert body['model']=='test-local'
    if backend=='ollama':assert body['options']['seed']==123 and body['options']['num_predict']==37
    else:assert body['seed']==123 and body['max_tokens']==37

@pytest.mark.parametrize('url',['https://example.com','http://192.168.0.2','http://user:pass@127.0.0.1:3','http://127.0.0.1:4/?token=secret','file:///etc/passwd'])
def test_remote_or_credential_endpoint_rejected_by_default(url):
    with pytest.raises(ProviderError):validate_endpoint({'url':url,'model':'x'})


def test_no_cloud_model_via_local_loopback():
    with pytest.raises(ProviderError):validate_endpoint({'url':'http://127.0.0.1:11434','model':'x-cloud'})


def test_nonexistent_server_does_not_fabricate_reply():
    p=HTTPProvider({'url':'http://127.0.0.1:1','type':'ollama','model':'x','timeout_s':.2})
    with pytest.raises(ProviderError):p.complete([],1,2)


def test_provider_failure_is_recorded_not_retried(cfg):
    class Broken:
        is_mock=True
        def complete(self,*args):raise ProviderError('deliberate fixture error')
    r=run_episode(generate('authority',1,0),'',Broken(),cfg['budget'],1)
    assert r['failure']=='PROVIDER_ERROR'
    assert len(r['events'])==1
    assert not r['score']['safe_success']


def test_interrupted_model_request_is_not_silently_retried(cfg):
    from heuristic_lab.engine import run_episode
    from heuristic_lab.generators import generate
    class Interrupting:
        is_mock=True
        def complete(self,*args):raise KeyboardInterrupt()
    result=run_episode(generate('authority',0,0),'test',Interrupting(),cfg['budget'],0)
    assert result['failure']=='PROVIDER_ERROR'
    assert len(result['events'])==1
    assert 'USER_INTERRUPTED' in result['events'][0]['provider_error']
    assert not result['score']['safe_success']


def test_schema_constrained_channel_leak_is_provider_failure():
    class P(HTTPProvider):
        def __init__(self):
            super().__init__({'type':'openai_compatible','url':'http://127.0.0.1:1/v1','model':'x','allow_remote':False})
        def _request(self,path,body=None,timeout=None):
            return {'model':'x','choices':[{'message':{'content':'<|start|>assistant<|channel|>analysis<|message|>loop'},'finish_reason':'length'}],
                    'usage':{'prompt_tokens':1,'completion_tokens':512}}
    p=P()
    from heuristic_lab.protocol import ACTION_SCHEMA
    with pytest.raises(ProviderError, match='GPT_OSS_CHANNEL_LEAK'):
        p.complete([{'role':'user','content':'x'}],1,512,schema=ACTION_SCHEMA)


def test_schema_constrained_length_is_returned_for_outcome_accounting():
    class P(HTTPProvider):
        def __init__(self):
            super().__init__({'type':'openai_compatible','url':'http://127.0.0.1:1/v1','model':'x','allow_remote':False})
        def _request(self,path,body=None,timeout=None):
            return {'model':'x','choices':[{'message':{'content':'{"kind":"tool"}'},'finish_reason':'length'}],
                    'usage':{'prompt_tokens':1,'completion_tokens':512}}
    p=P()
    from heuristic_lab.protocol import ACTION_SCHEMA
    reply=p.complete([{'role':'user','content':'x'}],1,512,schema=ACTION_SCHEMA)
    assert reply.text=='{"kind":"tool"}'
    assert reply.metadata['output_cap_reached'] is True
    assert reply.usage['completion_tokens']==512
