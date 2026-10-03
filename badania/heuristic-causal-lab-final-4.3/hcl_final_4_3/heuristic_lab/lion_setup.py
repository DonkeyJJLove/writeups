"""Create a frozen LION full-study backend profile.

This module performs treatment-blind infrastructure qualification only.  It never
runs a pilot and never observes author_raw versus strong_control outcomes.
"""
from __future__ import annotations
import argparse
from copy import deepcopy
import json
from pathlib import Path
import sys
from .design import load_config, plan
from .generators import make_suite, generate
from .protocol import POLICIES, ACTION_SCHEMA, system_message
from .providers import HTTPProvider, ProviderError
from .generation_budget import BUDGET_POLICY
from .grading import parse_response_audited
from .tools import Environment, TOOL_CATALOG
from .qualification_contract import validate_qualification_action
from .output_budget import assert_qualification_finished
from .util import ASSETS, digest, file_hash, utc, write_json

TRANSPORT_CANDIDATES = ("json_object",)
QUALIFICATION_SEED_BASE = 970000


def _neutral_shadow_policy(target_chars:int) -> str:
    src=(ASSETS/"policies"/"neutral_shadow_policy.txt").read_text(encoding="utf-8").strip()
    if len(src) < target_chars:
        # The file is varied natural prose; extending it by whole paragraphs is
        # preferable to a one-line repeated stress token sequence.
        chunks=[x.strip() for x in src.split("\n\n") if x.strip()]
        out=[];i=0
        while len("\n\n".join(out)) < target_chars:
            out.append(chunks[i % len(chunks)] + f" Neutral extension paragraph {i+1}.")
            i+=1
        src="\n\n".join(out)
    return src[:target_chars]


def _qualification_messages(cfg:dict, neutral:str) -> list[tuple[str,list[dict],int]]:
    rows=[]
    # Ten realistic first-turn cases, one per family, using seeds outside the
    # confirmatory schedule.  Task correctness is never graded here.
    cases=[generate(f,QUALIFICATION_SEED_BASE+i,0,cfg["phase"]) for i,f in enumerate(cfg["families"])]
    for i,case in enumerate(cases):
        rows.append((f"first_turn_{case.family}",[
            {"role":"system","content":system_message(neutral,cfg["budget"]["max_turns"],cfg["budget"]["tool_work"])},
            {"role":"user","content":case.opening + "\nTransport qualification only. Call tool read with args={id:packet}; no task answer is requested in this check."},
        ],980000+i))
    # Four realistic post-observation states.  The prior assistant message is a
    # canonical tool action; the observation contains no answer key from a study trial.
    prior=json.dumps({
        "kind":"tool","tool_name":"read","args":{"id":"packet"},
        "decision":"none","answer":None,"evidence":[],"confidence":0.0,
        "status":"UNKNOWN","reason":"neutral transport qualification"
    },separators=(",",":"))
    for j,case in enumerate(cases[:4]):
        observation=Environment(case,cfg["budget"]["tool_work"]).step("read",{"id":"packet"})
        rows.append((f"post_observation_{case.family}",[
            {"role":"system","content":system_message(neutral,cfg["budget"]["max_turns"],cfg["budget"]["tool_work"])},
            {"role":"user","content":case.opening},
            {"role":"assistant","content":prior},
            {'role':'user','content':'TOOL_OBSERVATION\n'+json.dumps(observation,ensure_ascii=False)+'\nReturn the next JSON action.'},
        ],981000+j))
    # Two direct actions under the same full-length shadow context.
    rows.append(("direct_final",[
        {"role":"system","content":system_message(neutral,cfg["budget"]["max_turns"],cfg["budget"]["tool_work"])},
        {"role":"user","content":"Transport qualification only. Return one final JSON action with answer 7. No prose outside the object."},
    ],982001))
    rows.append(("direct_tool",[
        {"role":"system","content":system_message(neutral,cfg["budget"]["max_turns"],cfg["budget"]["tool_work"])},
        {"role":"user","content":"Transport qualification only. Return one tool JSON action calling read with id=packet. No prose outside the object."},
    ],982002))
    return rows


def _qualify_transports(provider:HTTPProvider,cfg:dict) -> dict:
    arm_lengths=[len((ASSETS/"policies"/POLICIES[a]["path"]).read_text(encoding="utf-8")) for a in cfg["arms"]]
    neutral=_neutral_shadow_policy(max(arm_lengths))
    probes=_qualification_messages(cfg,neutral)
    candidates=[]
    selected=None
    for mode in TRANSPORT_CANDIDATES:
        result={"mode":mode,"status":"CHECKING","requests":0,"rows":[]}
        try:
            for name,messages,seed in probes:
                print(f"      transport {result['requests']+1}/{len(probes)}: {name}",flush=True)
                provider.trace_label=name
                result["requests"]+=1
                reply=provider.complete(messages,seed=seed,max_tokens=cfg["budget"]["max_tokens_per_turn"],
                                        schema=ACTION_SCHEMA,_schema_mode=mode)
                assert_qualification_finished(reply.metadata)
                action,audit=parse_response_audited(reply.text)
                validate_qualification_action(name,action)
                if name == "direct_final" and action.get("kind") != "final":
                    raise ProviderError("QUALIFICATION_KIND_MISMATCH: direct_final returned "+str(action.get("kind"))+"; raw="+repr(reply.text[:800]))
                if name == "direct_tool" and action.get("kind") != "tool":
                    raise ProviderError("QUALIFICATION_KIND_MISMATCH: direct_tool returned "+str(action.get("kind"))+"; raw="+repr(reply.text[:800]))
                result["rows"].append({
                    "probe":name,
                    "finish_reason":reply.metadata.get("finish_reason"),
                    "completion_tokens":reply.usage.get("completion_tokens"),
                    "parsed_kind":action.get("kind"),
                    "normalized":bool(audit.get("normalized")),
                    "normalizations":audit.get("normalizations",[]),
                    "transport":audit.get("transport"),
                    "raw_text":reply.text,
                    "raw_metadata":reply.metadata,
                    "request_hash":digest(messages),
                })
            result["status"]="PASS"
            candidates.append(result)
            selected=mode
            break
        except Exception as exc:
            result["status"]="FAIL"
            result["error"]=str(exc)
            result["failed_probe"]=name
            result["http_evidence"]=getattr(provider,"last_http_evidence",None)
            candidates.append(result)
            provider.qualification_partial={"status":"FAIL","candidates":candidates}
    if selected is None:
        raise ProviderError("FULL_TRANSPORT_QUALIFICATION_FAILED: no preregistered candidate passed all 16 treatment-blind realistic checks; "+json.dumps(candidates,ensure_ascii=False)[:7000])
    provider.config["structured_output_mode"]=selected
    return {
        "status":"PASS",
        "candidate_order":list(TRANSPORT_CANDIDATES),
        "selected_mode":selected,
        "checks_per_candidate":len(probes),
        "neutral_policy_chars":len(neutral),
        "qualification_cases":"10 held-out family first-turn + 4 held-out post-observation + 2 direct actions",
        "candidates":candidates,
        "scope":"treatment-blind transport qualification only; no heuristic arm is loaded or scored",
    }


def create_profile(template: Path, output: Path, url: str, model: str = "AUTO",
                   test_inference: bool = False) -> dict:
    proof_path=output.with_suffix(".preflight.json")
    if output.exists() or proof_path.exists():
        raise FileExistsError("Output or preflight report exists. Choose a new filename; no overwrite.")
    cfg=deepcopy(load_config(template))
    cfg["provider"].update(type="openai_compatible",url=url.rstrip("/"),model=model,
                           allow_remote=False,llama_cpp_guard=True,llama_context_margin=64,
                           reasoning_effort="none",reasoning_format="auto",
                           study_transport="gpt_oss_jinja_json_object_budgetfix1",
                           llama_reasoning_budget_policy=BUDGET_POLICY,
                           http_evidence_dir=str(output.resolve().parent/"transport_http"))
    cfg["provider"].pop("think",None)
    cfg["provider"].pop("llama_runtime_pin",None)
    cfg["provider"].pop("api_key_env",None)
    evidence={
        "created_utc":utc(),
        "purpose":"full-study treatment-blind LION transport/context qualification",
        "status":"CHECKING","live_generation_requests":0,
        "server_mutations":0,"mission_database_access":False,
        "source_template_sha256":file_hash(template),
        "candidate_config_sha256":digest(cfg),"checks":[],"errors":[],
        "note":"No pilot and no treatment outcome is observed. v4.3 preregisters only json_object plus application-side validation because realistic treatment-blind v4.2 qualification falsified strict decoder schema compatibility on the target GPT-OSS/llama.cpp stack."
    }
    try:
        p=HTTPProvider(cfg["provider"])
        info=p.inspect()
        cfg["provider"]=p.config
        runtime=info["identity"]["llama_runtime"]
        cfg["provider"]["context_tokens"]=runtime["context_tokens_per_slot"]
        evidence["identity"]=info
        evidence["plan"]=plan(cfg)
        cases=make_suite(cfg["families"],list(range(cfg["seed_start"],cfg["seed_start"]+cfg["clusters"])),cfg["phase"])
        # Do not spend tens of thousands of live tokenization calls before a
        # 10,240-trial study.  For each family, preflight the locally longest
        # opening under each arm.  Every actual turn is still checked by the
        # provider guard immediately before generation.
        longest={}
        for case in cases:
            cur=longest.get(case.family)
            if cur is None or len(case.opening)>len(cur.opening):
                longest[case.family]=case
        evidence["context_preflight_selection"]="longest opening per family under each arm; every live turn remains guarded"
        for arm in cfg["arms"]:
            policy=(ASSETS/"policies"/POLICIES[arm]["path"]).read_text(encoding="utf-8")
            for family in cfg["families"]:
                case=longest[family]
                messages=[
                    {"role":"system","content":system_message(policy,cfg["budget"]["max_turns"],cfg["budget"]["tool_work"])},
                    {"role":"user","content":case.opening},
                ]
                try:
                    check=p.llama_guard.check(messages,cfg["budget"]["max_tokens_per_turn"])
                    evidence["checks"].append({"arm":arm,"family":family,"case_id":case.case_id,
                                               "opening_chars":len(case.opening),**check})
                except ProviderError as exc:
                    evidence["errors"].append({"arm":arm,"family":family,"case_id":case.case_id,"error":str(exc)})
                    if "LLAMA_CONTEXT_TOO_SMALL" not in str(exc):
                        raise
        if evidence["errors"]:
            evidence["status"]="BLOCKED_CONTEXT"
            raise ProviderError("LION preflight failed: initial prompts do not fit unchanged. Config was not written; see "+str(proof_path))
        if test_inference:
            cap=cfg["budget"]["max_tokens_per_turn"]
            print(f"      generation budget: max_tokens={cap}; reasoning_budget_tokens={cap+1} (explicit request override)",flush=True)
            qual=_qualify_transports(p,cfg)
            cfg["provider"]=p.config
            cfg["provider"]["transport_qualification_hash"]=digest(qual)
            evidence["transport_qualification"]=qual
            evidence["live_generation_requests"]=sum(x.get("requests",0) for x in qual["candidates"])
        elif cfg.get("phase")=="confirmatory":
            raise ProviderError("Full confirmatory profile requires --test-inference treatment-blind transport qualification before sealing.")
        evidence["status"]="READY_FOR_STUDY" if cfg.get("phase")=="confirmatory" else "READY_FOR_PILOT"
        evidence["config_sha256"]=digest(cfg)
        evidence["scope"]="Context and transport qualified before sealing. The experiment itself still compares only frozen author_raw versus strong_control."
        write_json(output,cfg)
        return evidence
    except (ProviderError,ValueError) as exc:
        if evidence["status"]=="CHECKING":
            evidence["status"]="BLOCKED_PREFLIGHT"
        evidence["error"]=str(exc)
        if "p" in locals():
            partial=getattr(p,"qualification_partial",None)
            if partial:
                evidence["transport_qualification"]=partial
                evidence["live_generation_requests"]=sum(x.get("requests",0) for x in partial["candidates"])
            evidence["last_http_evidence"]=getattr(p,"last_http_evidence",None)
        raise
    finally:
        write_json(proof_path,evidence)


def main(argv:list[str]|None=None)->int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template",type=Path,default=ASSETS/"configs"/"study.json")
    parser.add_argument("--output",type=Path,default=Path("configs/study_lion_8773.json"))
    parser.add_argument("--url",default="http://127.0.0.1:8773/v1")
    parser.add_argument("--model",default="AUTO")
    parser.add_argument("--test-inference",action="store_true")
    args=parser.parse_args(argv)
    try:
        result=create_profile(args.template,args.output,args.url,args.model,args.test_inference)
        print(json.dumps({
            "status":result["status"],"config":str(args.output),
            "evidence":str(args.output.with_suffix(".preflight.json")),
            "model":result["identity"]["identity"]["model"],
            "runtime":result["identity"]["identity"]["llama_runtime"],
            "opening_checks":len(result["checks"]),
            "live_generation_requests":result["live_generation_requests"],
            "selected_transport":result.get("transport_qualification",{}).get("selected_mode"),
            "plan":result["plan"],
        },ensure_ascii=False,indent=2))
        return 0
    except (ProviderError,ValueError,OSError) as exc:
        print("ERROR: "+str(exc),file=sys.stderr)
        print("No LION production service was restarted. No treatment trial was run or fabricated.",file=sys.stderr)
        return 2

if __name__=="__main__":
    raise SystemExit(main())
