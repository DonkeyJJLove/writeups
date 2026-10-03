"""Regression on the user's recorded HTTP, plus explicitly synthetic controls.

These tests do not contact a live model; fixture-origin data must never be treated
as a new observed heuristic experiment.
"""
from __future__ import annotations
import copy
import hashlib
import json
from pathlib import Path
import pytest
from heuristic_lab import engine
from heuristic_lab.engine import run_episode, replay_trial
from heuristic_lab.providers import HTTPProvider, ProviderError
from heuristic_lab.protocol import ACTION_SCHEMA
from heuristic_lab.models import Case
from heuristic_lab.design import prepare, load_config
from heuristic_lab.util import digest, read_json, write_json, ROOT
from heuristic_lab.output_budget import assert_qualification_finished
from heuristic_lab.lion_setup import _qualify_transports

DATA=Path(__file__).parent/"data/runtime_7874"
RAW=(DATA/"response.raw").read_bytes()
REQUEST=read_json(DATA/"request.json")
ORIGINAL=read_json(DATA/"original_episode.json")
RESPONSE=json.loads(RAW)
PUBLIC=read_json(DATA/"case_public.json"); PRIVATE=read_json(DATA/"case_private.json")
CASE=Case(PRIVATE["case_id"],PRIVATE["cluster"],PRIVATE["family"],PRIVATE["twin"],
          PUBLIC["opening"],PUBLIC["public"],PRIVATE["private"])
BUDGET={"max_turns":6,"max_tokens_per_turn":768,"tool_work":512,
        "max_context_chars":50000,"episode_seconds":300}

class ByteResponse:
    status=200
    def __init__(self,raw):self.raw=raw
    def __enter__(self):return self
    def __exit__(self,*a):return False
    def read(self,n):return self.raw[:n]
class ByteOpener:
    def __init__(self,raw):self.raw=raw;self.calls=[]
    def open(self,req,timeout):self.calls.append(req);return ByteResponse(self.raw)

def provider(tmp_path,raw=RAW):
    p=HTTPProvider({"type":"openai_compatible","url":"http://127.0.0.1:8773/v1",
                    "model":REQUEST["model"],"structured_output_mode":"json_object",
                    "temperature":.2,"reasoning_effort":"none","reasoning_format":"auto",
                    "llama_reasoning_budget_policy":"above_completion_cap_v1", "llama_cpp_guard":True,
                    "http_evidence_dir":str(tmp_path)})
    class GuardDouble:
        def check(self,*a,**kw):return {"scope":"explicit software test double"}
    p.llama_guard=GuardDouble()
    p.opener=ByteOpener(raw);p.is_mock=True
    return p

def episode_record(result):
    record={"assignment":ORIGINAL["assignment"],"case_public_hash":CASE.public_hash,**result}
    record["artifact_hash"]=digest(record)
    return record

def test_fixture_matches_user_http_receipt():
    receipt=read_json(DATA/"receipt.json")
    assert hashlib.sha256(RAW).hexdigest()==receipt["response_sha256"]
    assert hashlib.sha256((DATA/"request.json").read_bytes()).hexdigest()==receipt["request_sha256"]

def test_real_empty_content_limit_is_retained_with_usage(tmp_path):
    p=provider(tmp_path)
    reply=p.complete(REQUEST["messages"],REQUEST["seed"],768,ACTION_SCHEMA)
    assert reply.text==""
    assert reply.usage["prompt_tokens"]==3636
    assert reply.usage["completion_tokens"]==768
    assert reply.metadata["reasoning_content_chars"]==3084
    assert reply.metadata["output_cap_reached"] is True
    sent=json.loads(p.opener.calls[0].data)
    assert sent["max_tokens"]==768 and sent["reasoning_budget_tokens"]==769
    assert sent==REQUEST  # No intervention in the failing request itself.
    assert Path(reply.metadata["http_evidence"],"response.raw").read_bytes()==RAW

def test_recorded_thought_tool_is_never_executed(tmp_path):
    p=provider(tmp_path)
    policy=(ROOT/"policies/strong_control.txt").read_text(encoding="utf-8")
    result=run_episode(CASE,policy,p,BUDGET,ORIGINAL["assignment"]["model_seed"])
    assert result["initial_messages"]==ORIGINAL["initial_messages"]
    assert json.loads(p.opener.calls[0].data)==REQUEST
    assert result["failure"]=="GENERATION_LIMIT"
    assert result["score"]["safe_success"] is False
    assert result["score"]["protocol_success"] is False
    assert result["score"]["generation_limit"] is True
    assert result["score"]["output_budget_exhausted"] is True
    assert result["tool_work"]==0 and result["final"] is None
    assert len(result["events"])==len(p.opener.calls)==1
    assert "tool_response" not in result["events"][0]
    assert result["usage"]=={"prompt_tokens":3636,"completion_tokens":768,"reported_usage_complete":True}
    assert replay_trial(CASE,episode_record(result),BUDGET)==[]

@pytest.mark.parametrize("content",["",'{"kind":',"null","[]",'{"kind":"tool"}',"prose"])
def test_incomplete_or_non_action_output_at_cap_is_no_retry_outcome(tmp_path,content):
    r=copy.deepcopy(RESPONSE);r["choices"][0]["message"]["content"]=content
    p=provider(tmp_path,json.dumps(r).encode())
    result=run_episode(CASE,"",p,BUDGET,1)
    assert result["failure"]=="GENERATION_LIMIT"
    assert len(p.opener.calls)==1 and not result["score"]["safe_success"]

def test_complete_strictly_valid_action_at_cap_is_not_discarded(tmp_path):
    r=copy.deepcopy(RESPONSE)
    r["choices"][0]["message"]["content"]='{"kind":"tool","name":"read","args":{"id":"packet"}}'
    p=provider(tmp_path,json.dumps(r).encode())
    # One semantic turn is deliberate in this test; the actual action executes.
    result=run_episode(CASE,"",p,dict(BUDGET,max_turns=1),1)
    assert result["events"][0]["parsed"]["name"]=="read"
    assert "tool_response" in result["events"][0]
    assert result["failure"]=="TURN_LIMIT"
    assert result["score"]["generation_limit"] is True
    assert result["score"]["output_budget_exhausted"] is False
    assert not result["score"]["safe_success"]

def test_channel_leak_remains_separate_fail_closed_guard(tmp_path):
    r=copy.deepcopy(RESPONSE)
    r["choices"][0]["message"]["content"]='<|start|>assistant<|channel|>analysis<|message|>loop'
    p=provider(tmp_path,json.dumps(r).encode())
    with pytest.raises(ProviderError,match="GPT_OSS_CHANNEL_LEAK"):
        p.complete([],1,768,ACTION_SCHEMA)

def test_preseal_gate_still_rejects_output_cap_hit():
    with pytest.raises(ValueError,match="QUALIFICATION_GENERATION_LIMIT"):
        assert_qualification_finished({"finish_reason":"length"})

def test_real_fixture_still_fails_neutral_qualification_not_spuriously_passed(tmp_path,cfg):
    p=provider(tmp_path)
    with pytest.raises(ProviderError,match="QUALIFICATION_GENERATION_LIMIT"):
        _qualify_transports(p,cfg)
    assert len(p.opener.calls)==1

def test_forged_zero_token_accounting_is_rejected(tmp_path):
    result=run_episode(CASE,"",provider(tmp_path),BUDGET,ORIGINAL["assignment"]["model_seed"])
    rec=episode_record(result)
    rec["usage"]["completion_tokens"]=0
    rec.pop("artifact_hash");rec["artifact_hash"]=digest(rec)
    assert "usage accounting mismatch" in replay_trial(CASE,rec,BUDGET)

def test_failure_relabel_cannot_turn_length_into_network_error(tmp_path):
    result=run_episode(CASE,"",provider(tmp_path),BUDGET,ORIGINAL["assignment"]["model_seed"])
    rec=episode_record(result);rec["failure"]="PROVIDER_ERROR"
    rec.pop("artifact_hash");rec["artifact_hash"]=digest(rec)
    assert "terminal parse failure classification mismatch" in replay_trial(CASE,rec,BUDGET)

def test_actual_network_failure_stays_unknown_not_zero(cfg):
    class NetworkOutage:
        is_mock=True
        def complete(self,*a):raise ProviderError("connection refused test double")
    result=run_episode(CASE,"",NetworkOutage(),cfg["budget"],1)
    assert result["failure"]=="PROVIDER_ERROR"
    assert result["usage"]["completion_tokens"] is None
    assert result["score"]["protocol_success"] is False

def test_full_execution_continues_past_all_length_failures_without_retry(tmp_path,cfg,monkeypatch):
    # Intentionally synthetic execution path; all output records remain mock=True.
    cfg["budget"]=dict(BUDGET)
    cfg["provider"].update(type="openai_compatible",url="http://127.0.0.1:1/v1",structured_output_mode="json_object")
    cfg["provider"]["transport_qualification_hash"]="EXPLICIT_SOFTWARE_TEST_ONLY"
    out=tmp_path/"mock_study";manifest=prepare(cfg,out,mock=True)
    manifest["evaluation_kind"]="LIVE_MODEL_STUDY"
    manifest.pop("manifest_hash");manifest["manifest_hash"]=digest(manifest)
    write_json(out/"manifest.json",manifest)
    class RecordedReplyTestDouble(HTTPProvider):
        is_mock=True
        calls=0
        def __init__(self,config):
            super().__init__(config);self.opener=ByteOpener(RAW)
        def inspect(self):return manifest["model"]
        def complete(self,*a,**kw):
            type(self).calls+=1
            return super().complete(*a,**kw)
    monkeypatch.setattr(engine,"HTTPProvider",RecordedReplyTestDouble)
    result=engine.execute_study(out,confirm=True,progress=lambda *a,**kw:None)
    assert result["existing_or_completed"]==40
    assert result["provider_errors_this_invocation"]==0
    assert RecordedReplyTestDouble.calls==40
    assert len(list((out/"trials").glob("*.json")))==40
    assert not (out/"transport_terminal_failure.json").exists()
    assert not (out/"transport_circuit_breaker.json").exists()
    assert engine.audit_study(out)["status"]=="PASS"
    again=engine.execute_study(out,confirm=True,progress=lambda *a,**kw:None)
    assert again["requests_this_invocation"]==0
    assert RecordedReplyTestDouble.calls==40
    assert all(read_json(p)["mock"] for p in (out/"trials").glob("*.json"))

def test_new_config_preserves_budget_and_uses_disjoint_seeds():
    cfg=load_config(ROOT/"configs/study.json")
    assert cfg["clusters"]==256 and cfg["phase"]=="confirmatory"
    assert cfg["budget"]["max_tokens_per_turn"]==768
    assert cfg["seed_start"]==30000
    assert cfg["protocol"]["output_budget_outcome_policy"]["reasoning_budget_unchanged"]==769
