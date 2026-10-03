"""Stateless local inference adapters using only the Python standard library.

The evaluator never substitutes scripted answers for a failed live model request.
Remote traffic requires explicit configuration and run-time consent.
"""
from __future__ import annotations
import ipaddress
import json
import math
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import asdict
from .models import ProviderReply
from .util import digest
from .http_evidence import HTTPEvidence
from .generation_budget import request_reasoning_budget
from .output_budget import output_cap_reached, assert_qualification_finished
import hashlib

class ProviderError(RuntimeError):
    pass

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self,req,fp,code,msg,headers,newurl):
        raise ProviderError("HTTP redirects are disabled; specify the exact endpoint")


def is_loopback(host: str|None) -> bool:
    if host=="localhost":return True
    try:return ipaddress.ip_address(host or "").is_loopback
    except ValueError:return False


def validate_endpoint(config: dict) -> None:
    try:
        request_reasoning_budget(config, 1)
    except ValueError as exc:
        raise ProviderError(str(exc)) from exc
    if not isinstance(config.get("url"),str) or not isinstance(config.get("model","AUTO"),str):
        raise ProviderError("url and model must be strings")
    for name in ["temperature","timeout_s"]:
        if name in config and (type(config[name]) not in {int,float} or not math.isfinite(config[name]) or config[name]<0):
            raise ProviderError("Invalid numerical provider option: "+name)
    u=urllib.parse.urlparse(config["url"])
    if u.scheme not in {"http","https"} or not u.hostname or u.username or u.password or u.query or u.fragment:
        raise ProviderError("Endpoint must be a plain http(s) base URL without credentials/query/fragment")
    if not is_loopback(u.hostname) and not config.get("allow_remote",False):
        raise ProviderError("Remote inference is disabled. Set allow_remote=true only after reviewing data/cost implications")
    if not is_loopback(u.hostname) and u.scheme!="https":
        raise ProviderError("Non-loopback inference requires HTTPS")
    if "cloud" in config.get("model", "").lower() and not config.get("allow_remote",False):
        raise ProviderError("Cloud model requires explicit allow_remote=true even via a local proxy")


class HTTPProvider:
    is_mock=False

    def __init__(self,config:dict):
        self.config=dict(config)
        validate_endpoint(self.config)
        if self.config["type"] not in {"ollama","openai_compatible"}:raise ProviderError("Unknown live backend")
        # Do not let an inherited HTTP_PROXY silently forward local prompts elsewhere.
        self.opener=urllib.request.build_opener(urllib.request.ProxyHandler({}),NoRedirect())
        self.llama_guard=None
        if self.config.get("llama_cpp_guard"):
            if self.config["type"]!="openai_compatible":
                raise ProviderError("llama_cpp_guard requires openai_compatible backend")
            from .llama_guard import LlamaGuard
            self.llama_guard=LlamaGuard(self.config)

    def _request(self,path:str,body:dict|None=None,timeout:float|None=None) -> dict:
        url=self.config["url"].rstrip("/")+path
        headers={"Content-Type":"application/json"}
        key_env=self.config.get("api_key_env")
        if key_env:
            key=os.getenv(key_env)
            if not key:raise ProviderError(f"Environment variable {key_env} is not set")
            headers["Authorization"]="Bearer "+key
        payload=json.dumps(body,ensure_ascii=False).encode("utf-8") if body is not None else None
        req=urllib.request.Request(url,data=payload,headers=headers)
        trace=None
        if path in {"/chat/completions","/api/chat"} and self.config.get("http_evidence_dir"):
            trace=HTTPEvidence(self.config["http_evidence_dir"],path,payload or b"",getattr(self,"trace_label",None))
            self.last_http_evidence=str(trace.folder)
        try:
            request_timeout=timeout or self.config.get("timeout_s",120)
            request_timeout=min(request_timeout,getattr(self,"remaining_seconds",request_timeout))
            with self.opener.open(req,timeout=max(.05,request_timeout)) as f:
                raw=f.read(8_000_001)
                if trace is not None:
                    trace.response(raw,status=getattr(f,"status",200),truncated=len(raw)>8_000_000)
                if len(raw)>8_000_000:raise ProviderError("Response exceeds safety limit")
                data=json.loads(raw)
        except urllib.error.HTTPError as e:
            error_raw=e.read(8_000_001)
            if trace is not None:
                trace.response(error_raw,status=e.code,truncated=len(error_raw)>8_000_000)
                trace.failure(f"HTTP {e.code}")
            detail=error_raw[:1200].decode(errors="replace")
            raise ProviderError(f"HTTP {e.code}: {detail}") from e
        except (OSError,ValueError,TimeoutError) as e:
            if trace is not None:trace.failure(f"{type(e).__name__}: {e}")
            raise ProviderError(f"{type(e).__name__}: {e}") from e
        if not isinstance(data,dict):raise ProviderError("Expected an object from the inference server")
        if data.get("error"):raise ProviderError(str(data["error"])[:1200])
        return data

    def inspect(self) -> dict:
        if self.config["type"]=="ollama":
            raw=self._request("/api/tags",timeout=4)
            models=raw.get("models",[])
            ids=[x.get("name",x.get("model")) for x in models]
        else:
            raw=self._request("/models",timeout=4)
            models=raw.get("data",[]);ids=[x["id"] for x in models]
        wanted=self.config.get("model","AUTO")
        if wanted=="AUTO":
            if len(ids)!=1:raise ProviderError("AUTO requires exactly one installed model. Available: "+", ".join(ids))
            wanted=ids[0]
        if wanted not in ids:raise ProviderError(f"Model {wanted!r} not present. Available: {ids}")
        if "cloud" in wanted.lower() and not self.config.get("allow_remote",False):raise ProviderError("Cloud inference is disabled")
        selected=models[ids.index(wanted)]
        if (selected.get("remote_host") or selected.get("remote_model")) and not self.config.get("allow_remote",False):
            raise ProviderError("Server reports a remote/cloud model")
        self.config["model"]=wanted
        identity={"type":self.config["type"],"url":self.config["url"],"model":wanted,
                  "digest":selected.get("digest"),"details":selected.get("details",{}),"owner":selected.get("owned_by")}
        if self.llama_guard is not None:
            if len(ids)!=1:
                raise ProviderError("LION guard supports a direct single-model server, not a model router")
            identity["llama_runtime"]=self.llama_guard.inspect()
            self.config["llama_runtime_pin"]=identity["llama_runtime"]
        return {"identity":identity,"identity_hash":digest(identity),"available_models":ids,
                "local_checkpoint_attested":bool(selected.get("digest")),
                "warning":"Endpoint metadata is not a cryptographic proof of provider identity. Quantization/context settings are part of the intervention scope."}

    def complete(self,messages:list[dict],seed:int,max_tokens:int,schema:dict|None=None, _schema_mode:str|None=None) -> ProviderReply:
        c=self.config;t0=time.perf_counter()
        try:
            reasoning_budget_override=request_reasoning_budget(c,max_tokens)
        except ValueError as exc:
            raise ProviderError(str(exc)) from exc
        context_check=None
        if self.llama_guard is not None:
            context_check=self.llama_guard.check(messages,max_tokens,getattr(self,"remaining_seconds",None))
            if hasattr(self,"remaining_seconds"):
                self.remaining_seconds=max(.05,self.remaining_seconds-(time.perf_counter()-t0))
        if c["type"]=="ollama":
            fmt=schema if schema is not None else "json"
            body={"model":c["model"],"messages":messages,"stream":False,"format":fmt,
                  "options":{"temperature":c.get("temperature",0.2),"seed":seed,
                             "num_ctx":c.get("context_tokens",16384),"num_predict":max_tokens}}
            if c.get("think") is not None:body["think"]=c["think"]
            raw=self._request("/api/chat",body)
            text=raw.get("message",{}).get("content","")
            usage={"prompt_tokens":raw.get("prompt_eval_count"),"completion_tokens":raw.get("eval_count"),
                   "prompt_ns":raw.get("prompt_eval_duration"),"completion_ns":raw.get("eval_duration"),
                   "load_ns":raw.get("load_duration")}
            meta={"returned_model":raw.get("model"),"finish_reason":raw.get("done_reason"),"done":raw.get("done")}
        else:
            body={"model":c["model"],"messages":messages,"stream":False,"temperature":c.get("temperature",0.2),
                  "max_tokens":max_tokens}
            if reasoning_budget_override is not None:
                body["reasoning_budget_tokens"]=reasoning_budget_override
            if c.get("reasoning_effort") is not None:
                body["reasoning_effort"]=c["reasoning_effort"]
            if c.get("reasoning_format") is not None:
                body["reasoning_format"]=c["reasoning_format"]
            if schema is None:
                body["response_format"]={"type":"json_object"}
            else:
                mode=_schema_mode or c.get("structured_output_mode")
                if mode is None:
                    # llama.cpp's broadly supported native form. A live LION profile
                    # never relies on this default: lion_setup probes and pins a mode.
                    mode="llama_json_object_schema" if self.llama_guard is not None else "openai_json_schema"
                if mode=="llama_json_object_schema":
                    body["response_format"]={"type":"json_object","schema":schema}
                elif mode=="json_object":
                    # GPT-OSS/llama.cpp JSON mode still uses an internal grammar.
                    # Qualification and the common application parser validate the
                    # observed reply; requesting JSON is not a success guarantee.
                    body["response_format"]={"type":"json_object"}
                elif mode=="llama_json_schema_legacy":
                    body["response_format"]={"type":"json_schema","schema":schema}
                elif mode=="openai_json_schema":
                    body["response_format"]={"type":"json_schema","json_schema":{
                        "name":"heuristic_lab_response","strict":True,"schema":schema}}
                elif mode=="llama_top_level_json_schema":
                    body["response_format"]={"type":"json_object"}
                    body["json_schema"]=schema
                else:
                    raise ProviderError("Unknown structured_output_mode: "+str(mode))
            if c.get("send_seed",True):body["seed"]=seed
            if self.llama_guard is not None:
                body["cache_prompt"]=False
            raw=self._request("/chat/completions",body)
            choices=raw.get("choices",[])
            if not choices:raise ProviderError("Missing completion choices")
            text=choices[0].get("message",{}).get("content","")
            usage=raw.get("usage",{})
            meta={"returned_model":raw.get("model"),"finish_reason":choices[0].get("finish_reason"),
                  "system_fingerprint":raw.get("system_fingerprint")}
            # Analysis is evidence about generation, NEVER an executable action.
            # Full analysis remains in response.raw; only size/hash enter metadata.
            reasoning=choices[0].get("message",{}).get("reasoning_content")
            if isinstance(reasoning,str):
                meta["reasoning_content_chars"]=len(reasoning)
                meta["reasoning_content_sha256"]=hashlib.sha256(reasoning.encode("utf-8")).hexdigest()
            else:
                meta["reasoning_content_chars"]=None
                meta["reasoning_content_sha256"]=None
        if not isinstance(text,str):raise ProviderError("The completion did not contain text")
        if schema is not None:
            # A schema-constrained reply must be a complete JSON value.  GPT-OSS +
            # llama.cpp/Jinja has an observed failure mode where preserved channel
            # tokens leak into message.content and loop until finish_reason=length.
            # That is transport/runtime failure, not evidence about either policy arm.
            leaked=[tok for tok in ("<|start|>","<|channel|>","<|message|>","<|end|>") if tok in text]
            if leaked:
                raise ProviderError("GPT_OSS_CHANNEL_LEAK: structured response contained chat control tokens "+",".join(leaked)+
                                    "; finish_reason="+str(meta.get("finish_reason"))+"; tail="+repr(text[-300:]))
            # A normal HTTP completion which hit its output cap is observable
            # model behavior. Return the actual text/usage so the engine can count
            # the failed trial instead of discarding it as an infrastructure error.
            # A complete, strictly valid action at the cap is still parseable; we
            # never finish partial JSON or promote reasoning into content.
            meta["output_cap_reached"]=output_cap_reached(meta)
            try:
                parsed_transport=json.loads(text)
            except (ValueError,TypeError) as exc:
                if not output_cap_reached(meta):
                    raise ProviderError("STRUCTURED_TRANSPORT_INVALID_JSON: "+str(exc)+"; raw="+repr(text[:500])) from exc
                meta["structured_json_observation"]="INCOMPLETE_OR_INVALID_AT_CAP"
            else:
                if not isinstance(parsed_transport,dict):
                    if not output_cap_reached(meta):
                        raise ProviderError("STRUCTURED_TRANSPORT_INVALID_JSON: JSON transport response was not an object")
                    meta["structured_json_observation"]="NON_OBJECT_AT_CAP"
                else:
                    meta["structured_json_observation"]="OBJECT_REQUIRES_ACTION_VALIDATION"
        if reasoning_budget_override is not None:
            meta["llama_reasoning_budget_control"]={
                "policy":c["llama_reasoning_budget_policy"],
                "max_tokens_requested":max_tokens,
                "reasoning_budget_tokens_requested":reasoning_budget_override,
                "scope":"request override; reasoning may occur within the unchanged total completion cap"}
        if context_check is not None:
            meta["llama_context_check"]=context_check
            meta["cache_prompt_requested"]=False
        if self.config.get("http_evidence_dir"):
            meta["http_evidence"]=getattr(self,"last_http_evidence",None)
        meta["roundtrip_s"]=time.perf_counter()-t0
        return ProviderReply(text,usage,meta)

    def probe_structured_output(self, attempts:int=4) -> dict:
        """Small selected-mode transport sanity check.

        Full-study transport selection is performed treatment-blind in lion_setup
        using realistic shadow-context requests.  This method remains for tests and
        explicit diagnostics; it never selects a different mode after sealing.
        """
        from .protocol import ACTION_SCHEMA
        from .grading import parse_response
        if attempts != 4:
            raise ProviderError("full-study protocol uses exactly four sanity probes")
        mode=self.config.get("structured_output_mode")
        if mode != "json_object":
            raise ProviderError("v4.3 full-study structured_output_mode must be json_object")
        rows=[]
        prompts=[
            ("direct_final","Return one JSON final action with answer 7.",940001),
            ("direct_tool","Return one JSON tool action calling read with id=packet.",940002),
        ]
        for name,user,seed in prompts:
            messages=[
                {"role":"system","content":"Transport sanity check. Return exactly one JSON action object and no prose."},
                {"role":"user","content":user},
            ]
            reply=self.complete(messages,seed=seed,max_tokens=192,schema=ACTION_SCHEMA,_schema_mode=mode)
            try:
                assert_qualification_finished(reply.metadata)
                action=parse_response(reply.text)
            except Exception as exc:
                raise ProviderError("STRUCTURED_OUTPUT_UNAVAILABLE: %s failed selected mode %s: %s; raw=%r" %
                                    (name,mode,exc,reply.text[:500]))
            rows.append({"probe":name,"ok":True,"mode":mode,"parsed_kind":action.get("kind"),
                         "finish_reason":reply.metadata.get("finish_reason")})
        canonical_tool=json.dumps({
            "kind":"tool","tool_name":"read","args":{"id":"packet"},
            "decision":"none","answer":None,"evidence":[],"confidence":0.0,
            "status":"UNKNOWN","reason":"transport sanity"
        },separators=(",",":"))
        for j in range(2):
            messages=[
                {"role":"system","content":"Transport sanity check. Return exactly one JSON action object and no prose."},
                {"role":"user","content":"Use the observation and return the next JSON action."},
                {"role":"assistant","content":canonical_tool},
                {"role":"user","content":"TOOL_OBSERVATION\n{\"receipt\":\"receipt-1\",\"status\":\"OBSERVATION\",\"data\":{\"value\":7}}"},
            ]
            reply=self.complete(messages,seed=940003+j,max_tokens=192,schema=ACTION_SCHEMA,_schema_mode=mode)
            try:
                assert_qualification_finished(reply.metadata)
                action=parse_response(reply.text)
            except Exception as exc:
                raise ProviderError("STRUCTURED_OUTPUT_UNAVAILABLE: post-observation sanity failed selected mode %s: %s; raw=%r" %
                                    (mode,exc,reply.text[:500]))
            rows.append({"probe":"post_observation_%d"%(j+1),"ok":True,"mode":mode,
                         "parsed_kind":action.get("kind"),"finish_reason":reply.metadata.get("finish_reason")})
        return {"status":"PASS","transport_probes":4,"http_generation_requests":4,
                "selected_mode":mode,"results":rows,
                "scope":"selected-mode sanity only; the mode was qualified treatment-blind before sealing"}
