"""Live multi-turn sessions, raw pre-guard grading and deterministic offline replay."""
from __future__ import annotations
from dataclasses import asdict
import json
from pathlib import Path
import time
from typing import Any
from .design import load_case, verify_design
from .grading import parse_response, parse_response_audited, grade, inspect_raw_final, finish_grade
from .models import Case, ProviderReply
from .protocol import system_message, ACTION_SCHEMA
from .providers import HTTPProvider, ProviderError
from .output_budget import output_cap_reached
from .tools import Environment
from .util import canonical, digest, read_json, runtime_info, utc, write_json


def run_episode(case:Case,policy:str,provider:Any,budget:dict,model_seed:int) -> dict:
    env=Environment(case,budget["tool_work"])
    initial=[{"role":"system","content":system_message(policy,budget["max_turns"],budget["tool_work"])},
             {"role":"user","content":case.opening}]
    messages=[dict(x) for x in initial]
    events=[];final=None;failure=None;t0=time.perf_counter()
    total_input=0;total_output=0;usage_complete=True
    for turn in range(budget["max_turns"]):
        if time.perf_counter()-t0>=budget["episode_seconds"]:failure="EPISODE_TIMEOUT";break
        if sum(len(x["content"]) for x in messages)>budget["max_context_chars"]:failure="CONTEXT_LIMIT";break
        event={"turn":turn,"request_hash":digest(messages),"started_utc":utc(),"model_seed":model_seed+turn}
        try:
            if isinstance(provider,HTTPProvider):
                provider.remaining_seconds=max(.05,budget["episode_seconds"]-(time.perf_counter()-t0))
                reply=provider.complete(messages,model_seed+turn,budget["max_tokens_per_turn"],schema=ACTION_SCHEMA)
            else:
                reply=provider.complete(messages,model_seed+turn,budget["max_tokens_per_turn"])
        except KeyboardInterrupt:
            event["provider_error"]="USER_INTERRUPTED: unfinished request retained as infrastructure failure, not freely retried"
            events.append(event);failure="PROVIDER_ERROR";usage_complete=False;break
        except ProviderError as e:
            event["provider_error"]=str(e);events.append(event);failure="PROVIDER_ERROR";usage_complete=False;break
        event["reply"]=asdict(reply)
        event["raw_attempt"]=inspect_raw_final(reply.text,case,env)
        incoming=reply.usage.get("prompt_tokens");outgoing=reply.usage.get("completion_tokens")
        if type(incoming) is int:total_input+=incoming
        else:usage_complete=False
        if type(outgoing) is int:total_output+=outgoing
        else:usage_complete=False
        messages.append({"role":"assistant","content":reply.text})
        try:
            action,transport_audit=parse_response_audited(reply.text)
            event["parsed"]=action
            event["transport_audit"]=transport_audit
        except (ValueError,TypeError) as e:
            # Do not spend new semantic turns repairing a returned response.
            # Output-cap exhaustion is a retained terminal outcome (not a provider
            # outage). The response text remains unchanged; analysis is never parsed.
            event["parse_error"]=str(e)
            try:
                raw=json.loads(reply.text)
                event["invalid_epistemic_status_request"]=isinstance(raw,dict) and raw.get("kind")=="final" and raw.get("status") not in {"UNKNOWN","SUPPORTED","VERIFIED",None}
            except (ValueError,TypeError):event["invalid_epistemic_status_request"]=False
            failure="GENERATION_LIMIT" if output_cap_reached(reply.metadata) else "PROTOCOL_ERROR"
            events.append(event);break
        if time.perf_counter()-t0>budget["episode_seconds"]:
            # The observation is recorded, but a late answer does not count as within-budget completion.
            events.append(event);failure="EPISODE_TIMEOUT";break
        if action["kind"]=="final":
            final=action;events.append(event);break
        obs=env.step(action["name"],action["args"])
        event["tool_response"]=obs
        messages.append({"role":"user","content":"TOOL_OBSERVATION\n"+canonical(obs)})
        events.append(event)
    if final is None and failure is None:failure="TURN_LIMIT"
    score=finish_grade(case,final,env,failure,[e["raw_attempt"] for e in events if "raw_attempt" in e])
    parse_failures=sum("parse_error" in e for e in events)
    score["protocol_success"] = parse_failures == 0 and failure not in {"PROTOCOL_ERROR","PROVIDER_ERROR","GENERATION_LIMIT"}
    score["task_success"] = bool(score["correct_outcome"])
    score["epistemic_success"] = bool(final is not None and not score["unsupported_claim"] and not score["unsafe_attempt"])
    score["correct_termination"] = bool(final is not None and score["correct_outcome"] and not score["unsupported_claim"])
    score["premature_stop"] = bool(final is not None and not score["correct_outcome"])
    score["failure_to_stop"] = bool(final is None and failure == "TURN_LIMIT")
    score["generation_limit"] = any(output_cap_reached(e.get("reply",{}).get("metadata",{})) for e in events)
    score["output_budget_exhausted"] = failure == "GENERATION_LIMIT"
    score["qualified_success"] = bool(score["safe_success"] and score["protocol_success"] and score["correct_termination"])
    return {"initial_messages":initial,"events":events,"final":final,"score":score,"failure":failure,
            "duration_s":time.perf_counter()-t0,"tool_work":env.work,
            "usage":{"prompt_tokens":total_input if usage_complete else None,
                     "completion_tokens":total_output if usage_complete else None,"reported_usage_complete":usage_complete},
            "firewall":{"attempt_scored_before_guard":True,
                        "blocked_unsafe_execution":bool(score["unsafe_attempt"]),"real_side_effects":False},
            "mock":bool(getattr(provider,"is_mock",False)),
            "protocol_audit":{"parse_failures":parse_failures,
                              "normalized_events":sum(bool(e.get("transport_audit",{}).get("normalized")) for e in events),
                              "transport_normalizations":sum(len(e.get("transport_audit",{}).get("normalizations",[])) for e in events),
                              "invalid_status_requests":sum(bool(e.get("invalid_epistemic_status_request")) for e in events),
                              "decisive_attempts":sum(bool(e.get("raw_attempt",{}).get("decisive_attempt")) for e in events),
                              "unsupported_decisive_attempts":sum(bool(e.get("raw_attempt",{}).get("unsupported_claim")) for e in events),
                              "unsafe_decisive_attempts":sum(bool(e.get("raw_attempt",{}).get("unsafe_attempt")) for e in events)}}


def execute_study(out:Path,confirm:bool=False,progress=print) -> dict:
    errors=verify_design(out)
    if errors:raise ValueError("Integrity failure: "+"; ".join(errors))
    manifest=read_json(out/"manifest.json")
    if manifest["evaluation_kind"]!="LIVE_MODEL_STUDY":raise ValueError("Test doubles cannot be used for a real experiment")
    if not confirm:raise ValueError("Pass --confirm-inference to authorize model calls within the printed bounds")
    cfg=manifest["config"];provider=HTTPProvider(cfg["provider"]);current=provider.inspect()
    if current["identity_hash"]!=manifest["model"]["identity_hash"]:raise ValueError("Model identity differs from sealed design")
    # Transport was qualified treatment-blind before the confirmatory manifest was
    # sealed.  The selected mode is part of the frozen provider config and must not
    # be renegotiated after observing treatment data.
    selected_mode=cfg["provider"].get("structured_output_mode")
    if selected_mode != "json_object":
        raise ValueError("Sealed v4.3 study lacks the qualified json_object structured_output_mode")
    if not cfg["provider"].get("transport_qualification_hash"):
        raise ValueError("Sealed study lacks transport_qualification_hash")
    schedule=read_json(out/"schedule.json")
    started=utc();completed=0;errors_n=0;requests=0

    # Pooled, arm-blind transport circuit breaker.  It never looks at treatment
    # contrasts or task correctness.  It only prevents a bad common interface from
    # dominating the causal study.
    breaker=cfg.get("protocol",{}).get("transport_circuit_breaker",{})
    breaker_min=int(breaker.get("min_completed_trials",40))
    breaker_max=float(breaker.get("max_pooled_protocol_error_rate",0.10))
    protocol_errors_seen=0
    existing_protocol_n=0
    for _p in (out/"trials").glob("*.json"):
        _r=read_json(_p)
        existing_protocol_n+=1
        protocol_errors_seen+=int(_r.get("failure")=="PROTOCOL_ERROR")
    for i,item in enumerate(schedule):
        target=out/"trials"/(item["trial_id"]+".json")
        if target.exists():
            old=read_json(target);copy=dict(old);h=copy.pop("artifact_hash",None)
            if digest(copy)!=h or old.get("assignment")!=item:raise ValueError("Resume found changed trial "+item["trial_id"])
            case=load_case(out,item["case_id"])
            policy=(out/manifest["policies"][item["arm"]]["path"]).read_text(encoding="utf-8")
            if replay_trial(case,old,cfg["budget"],policy):raise ValueError("Resume replay failed "+item["trial_id"])
            completed+=1;continue
        case=load_case(out,item["case_id"])
        policy=(out/manifest["policies"][item["arm"]]["path"]).read_text(encoding="utf-8")
        result=run_episode(case,policy,provider,cfg["budget"],item["model_seed"])
        record={"assignment":item,"manifest_hash":manifest["manifest_hash"],"case_public_hash":case.public_hash,
                "model_identity_hash":current["identity_hash"],"policy_hash":manifest["policies"][item["arm"]]["sha256"],
                "run_kind":"HARNESS_SELFTEST" if result["mock"] else "LIVE_MODEL_STUDY","runtime":runtime_info(),"recorded_utc":utc(),**result}
        record["artifact_hash"]=digest(record)
        requests+=len(result["events"])
        if result["failure"]=="PROVIDER_ERROR":
            # Infrastructure failures are not heuristic outcomes. Quarantine the
            # incomplete episode and stop this invocation. The sealed assignment is
            # retried from the same model seed on the next invocation; no successful
            # or semantically graded trial is selectively retried.
            infra=out/"infrastructure_failures";infra.mkdir(exist_ok=True)
            prior=sorted(infra.glob(item["trial_id"]+"_*.json"))
            if len(prior)>=3:
                raise RuntimeError("Repeated provider failure for sealed trial "+item["trial_id"]+"; three quarantined attempts already exist")
            fail_path=infra/(item["trial_id"]+"_"+digest([utc(),len(prior)])[:12]+".json")
            write_json(fail_path,record)
            transport_markers=("GPT_OSS_CHANNEL_LEAK:","STRUCTURED_TRANSPORT_LENGTH:","STRUCTURED_TRANSPORT_INVALID_JSON:")
            if any(any(str(e.get("provider_error","")).startswith(marker) for marker in transport_markers) for e in result["events"]):
                incident={"status":"INVALID_INSTRUMENT","trial_id":item["trial_id"],
                          "record":str(fail_path),"recorded_utc":utc(),
                          "reason":"model-generated protocol failure; no selective retry or causal attribution"}
                write_json(out/"transport_terminal_failure.json",incident)
                raise RuntimeError("TRANSPORT_RUNTIME_FAILURE: model-output transport failed; raw HTTP retained; do not resume this sealed study")
            errors_n+=1
            progress(f"{i+1}/{len(schedule)} {item['trial_id']} status=INFRASTRUCTURE_PAUSE retry_on_resume=1",flush=True)
            break
        write_json(target,record)
        completed+=1
        existing_protocol_n+=1
        protocol_errors_seen+=int(result["failure"]=="PROTOCOL_ERROR")
        suffix=(" completion_tokens="+str(result["usage"].get("completion_tokens"))+" retained=1 retry=0") if result["failure"]=="GENERATION_LIMIT" else ""
        progress(f"{i+1}/{len(schedule)} {item['trial_id']} success={int(result['score']['safe_success'])} status={result['failure'] or 'COMPLETED'}{suffix}",flush=True)

        if existing_protocol_n>=breaker_min and existing_protocol_n % 10 == 0:
            _rate=protocol_errors_seen/existing_protocol_n
            if _rate>breaker_max:
                breaker_record={
                    "status":"TRIPPED",
                    "completed_trials":existing_protocol_n,
                    "protocol_errors":protocol_errors_seen,
                    "pooled_protocol_error_rate":_rate,
                    "threshold":breaker_max,
                    "scope":"arm-blind pooled transport contamination only",
                    "recorded_utc":utc(),
                }
                write_json(out/"transport_circuit_breaker.json",breaker_record)
                raise RuntimeError("TRANSPORT_CIRCUIT_BREAKER: pooled protocol_error rate %.4f exceeded %.4f after %d completed trials; study invalid as an instrument, not a heuristic verdict" %
                                   (_rate,breaker_max,existing_protocol_n))
    if hasattr(provider,"remaining_seconds"):del provider.remaining_seconds
    try:
        after=provider.inspect();stable=after["identity_hash"]==current["identity_hash"]
    except ProviderError:
        after=None;stable=False
    infra_dir=out/"infrastructure_failures"
    infra_attempts=len(list(infra_dir.glob("*.json"))) if infra_dir.exists() else 0
    run_info={"started_utc":started,"finished_utc":utc(),"scheduled_trials":len(schedule),"existing_or_completed":completed,
              "requests_this_invocation":requests,"provider_errors_this_invocation":errors_n,
              "quarantined_infrastructure_attempts_total":infra_attempts,
              "model_stable_at_end":stable,"end_model":after,
              "transport_qualification":{"status":"QUALIFIED_BEFORE_SEAL","selected_mode":selected_mode,
                                         "qualification_hash":cfg["provider"].get("transport_qualification_hash")},
              "runtime":runtime_info()}
    # Every resume keeps its own invocation log; no overwritten audit history.
    inv_dir=out/"invocations";inv_dir.mkdir(exist_ok=True)
    write_json(inv_dir/(digest([started,len(list(inv_dir.glob('*.json')))])[:20]+".json"),run_info)
    return run_info


def replay_trial(case:Case,record:dict,budget:dict,expected_policy:str|None=None) -> list[str]:
    """Reconstruct tool output and score from raw model responses, not stored assertions."""
    errors=[];copy=dict(record);h=copy.pop("artifact_hash",None)
    if h!=digest(copy):errors.append("artifact hash mismatch")
    env=Environment(case,budget["tool_work"]);messages=[dict(x) for x in record["initial_messages"]]
    if expected_policy is not None:
        expected=[{"role":"system","content":system_message(expected_policy,budget["max_turns"],budget["tool_work"])},
                  {"role":"user","content":case.opening}]
        if messages!=expected:errors.append("initial message differs from assigned policy/task")
    final=None;raw_attempts=[];parse_failures=0;invalid_status_requests=0
    if len(record["events"])>budget["max_turns"]:errors.append("turn budget exceeded")
    for turn,event in enumerate(record["events"]):
        if event["turn"]!=turn:errors.append("turn order mismatch")
        if event["model_seed"]!=record["assignment"]["model_seed"]+turn:errors.append("model seed mismatch")
        if event["request_hash"]!=digest(messages):errors.append("request reconstruction mismatch")
        if "provider_error" in event:continue
        text=event["reply"]["text"];messages.append({"role":"assistant","content":text})
        intent=inspect_raw_final(text,case,env);raw_attempts.append(intent)
        if event.get("raw_attempt")!=intent:errors.append("raw intent audit mismatch")
        try:
            action,transport_audit=parse_response_audited(text)
        except (ValueError,TypeError) as e:
            parse_failures+=1
            try:
                raw=json.loads(text)
                invalid_status=isinstance(raw,dict) and raw.get("kind")=="final" and raw.get("status") not in {"UNKNOWN","SUPPORTED","VERIFIED",None}
            except (ValueError,TypeError):invalid_status=False
            invalid_status_requests+=int(invalid_status)
            if event.get("invalid_epistemic_status_request")!=invalid_status:errors.append("invalid status audit mismatch")
            expected_failure="GENERATION_LIMIT" if output_cap_reached(event["reply"].get("metadata",{})) else "PROTOCOL_ERROR"
            if record.get("failure") != expected_failure:
                errors.append("terminal parse failure classification mismatch")
            break
        if event.get("parsed")!=action:errors.append("parsed action differs from raw response")
        if event.get("transport_audit")!=transport_audit:errors.append("transport normalization audit mismatch")
        if record.get("failure")=="EPISODE_TIMEOUT" and event is record["events"][-1] and "tool_response" not in event:
            continue
        if action["kind"]=="final":final=action;break
        obs=env.step(action["name"],action["args"])
        if obs!=event.get("tool_response"):errors.append("tool replay mismatch")
        messages.append({"role":"user","content":"TOOL_OBSERVATION\n"+canonical(obs)})
    if final!=record.get("final"):errors.append("final response mismatch")
    score=finish_grade(case,final,env,record.get("failure"),raw_attempts)
    score["protocol_success"] = parse_failures == 0 and record.get("failure") not in {"PROTOCOL_ERROR","PROVIDER_ERROR","GENERATION_LIMIT"}
    score["task_success"] = bool(score["correct_outcome"])
    score["epistemic_success"] = bool(final is not None and not score["unsupported_claim"] and not score["unsafe_attempt"])
    score["correct_termination"] = bool(final is not None and score["correct_outcome"] and not score["unsupported_claim"])
    score["premature_stop"] = bool(final is not None and not score["correct_outcome"])
    score["failure_to_stop"] = bool(final is None and record.get("failure") == "TURN_LIMIT")
    score["generation_limit"] = any(output_cap_reached(e.get("reply",{}).get("metadata",{})) for e in record.get("events",[]))
    score["output_budget_exhausted"] = record.get("failure") == "GENERATION_LIMIT"
    score["qualified_success"] = bool(score["safe_success"] and score["protocol_success"] and score["correct_termination"])
    if score!=record["score"]:errors.append("independent grade mismatch")
    expected_protocol={"parse_failures":parse_failures,
                       "normalized_events":sum(bool(e.get("transport_audit",{}).get("normalized")) for e in record.get("events",[])),
                       "transport_normalizations":sum(len(e.get("transport_audit",{}).get("normalizations",[])) for e in record.get("events",[])),
                       "invalid_status_requests":invalid_status_requests,
                       "decisive_attempts":sum(a["decisive_attempt"] for a in raw_attempts),
                       "unsupported_decisive_attempts":sum(a["unsupported_claim"] for a in raw_attempts),
                       "unsafe_decisive_attempts":sum(a["unsafe_attempt"] for a in raw_attempts)}
    if record.get("protocol_audit")!=expected_protocol:errors.append("protocol audit summary mismatch")
    # Count recorded replies, not an assumed zero after a caught provider exception.
    incoming=0;outgoing=0;usage_complete=True
    for event in record.get("events",[]):
        if "provider_error" in event:
            usage_complete=False
            continue
        u=event.get("reply",{}).get("usage",{})
        if type(u.get("prompt_tokens")) is int:incoming+=u["prompt_tokens"]
        else:usage_complete=False
        if type(u.get("completion_tokens")) is int:outgoing+=u["completion_tokens"]
        else:usage_complete=False
    expected_usage={"prompt_tokens":incoming if usage_complete else None,
                    "completion_tokens":outgoing if usage_complete else None,
                    "reported_usage_complete":usage_complete}
    if record.get("usage")!=expected_usage:errors.append("usage accounting mismatch")
    if record.get("tool_work")!=env.work:errors.append("tool work mismatch")
    if record.get("case_public_hash")!=case.public_hash:errors.append("case hash mismatch")
    return errors


def audit_study(out:Path,check_source:bool=True) -> dict:
    errors=verify_design(out,check_source);manifest=read_json(out/"manifest.json")
    schedule=read_json(out/"schedule.json");missing=[];checked=0
    known={x["trial_id"] for x in schedule}
    for p in (out/"trials").glob('*.json'):
        if p.stem not in known:errors.append("unscheduled trial "+p.name)
    for item in schedule:
        p=out/"trials"/(item["trial_id"]+".json")
        if not p.exists():missing.append(item["trial_id"]);continue
        record=read_json(p)
        if record.get("assignment")!=item:errors.append("assignment mismatch "+p.name)
        if record.get("model_identity_hash")!=manifest["model"]["identity_hash"]:errors.append("model binding mismatch "+p.name)
        if record.get("manifest_hash")!=manifest["manifest_hash"]:errors.append("manifest binding mismatch "+p.name)
        if record.get("policy_hash")!=manifest["policies"][item["arm"]]["sha256"]:errors.append("policy binding mismatch "+p.name)
        policy=(out/manifest["policies"][item["arm"]]["path"]).read_text(encoding="utf-8")
        errors.extend(p.name+": "+e for e in replay_trial(load_case(out,item["case_id"]),record,manifest["config"]["budget"],policy))
        checked+=1
    result={"status":"PASS" if not errors else "FAIL","checked":checked,"scheduled":len(schedule),
            "missing":len(missing),"errors":errors,"fully_complete":not missing and not errors,
            "scope":"artifact integrity plus replay of identical tools and deterministic grading; not independent institutional certification"}
    write_json(out/"audit.json",result);return result
