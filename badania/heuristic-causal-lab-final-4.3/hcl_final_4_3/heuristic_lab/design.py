"""Locally sealed, prospective designs. Hashes detect edits, not historical truth."""
from __future__ import annotations
from copy import deepcopy
import json
import math
from pathlib import Path
from .generators import FAMILIES, make_suite
from .models import Case
from .protocol import POLICIES
from .providers import HTTPProvider, ProviderError
from .util import ROOT, ASSETS, canonical, digest, file_hash, read_json, rng_for, source_manifest, utc, write_json


def load_config(path: Path) -> dict:
    cfg=read_json(path)
    required={"phase","families","clusters","seed_start","repeats","arms","primary_treatment","primary_control","provider","budget","decision"}
    if not required.issubset(cfg):raise ValueError("Missing configuration fields: "+str(required-set(cfg)))
    if cfg["phase"] not in {"pilot","confirmatory"}:raise ValueError("phase must be pilot or confirmatory")
    if not cfg["families"] or len(set(cfg["families"]))!=len(cfg["families"]) or not set(cfg["families"]).issubset(FAMILIES):raise ValueError("Invalid families")
    if not cfg["arms"] or len(set(cfg["arms"]))!=len(cfg["arms"]) or not set(cfg["arms"]).issubset(POLICIES):raise ValueError("Invalid arms")
    if cfg["primary_control"]==cfg["primary_treatment"] or not {cfg["primary_control"],cfg["primary_treatment"]}.issubset(cfg["arms"]):raise ValueError("Invalid primary contrast")
    for key in ["clusters","repeats"]:
        if type(cfg[key]) is not int or cfg[key]<1:raise ValueError(key+" must be positive integer")
    b=cfg["budget"]
    for k in ["max_turns","max_tokens_per_turn","tool_work","max_context_chars"]:
        if type(b.get(k)) is not int or b[k]<1:raise ValueError("Invalid budget: "+k)
    if b.get("episode_seconds",0)<=0:raise ValueError("episode_seconds must be positive")
    if cfg["clusters"]>10000 or cfg["repeats"]>20 or b["max_turns"]>30:raise ValueError("Safety limit; split very large studies")
    d=cfg["decision"]
    if not 0<d["alpha"]<.5 or type(d["min_clusters"]) is not int or d["min_clusters"]<2:raise ValueError("Invalid decision criteria")
    for key in ["minimum_effect","harm_margin","utility_loss_margin","minimum_utility_rate"]:
        if not isinstance(d.get(key),(float,int)) or not math.isfinite(d[key]) or not 0<=d[key]<=1:raise ValueError("Invalid decision margin: "+key)
    return cfg


def plan(cfg:dict) -> dict:
    cases=len(cfg["families"])*cfg["clusters"]*2
    trials=cases*len(cfg["arms"])*cfg["repeats"]
    return {"phase":cfg["phase"],"clusters":cfg["clusters"],"families":len(cfg["families"]),
            "counterfactual_episodes":cases,"trials":trials,"max_requests":trials*cfg["budget"]["max_turns"],
            "max_completion_tokens":trials*cfg["budget"]["max_turns"]*cfg["budget"]["max_tokens_per_turn"],
            "max_sequential_episode_hours":trials*cfg["budget"]["episode_seconds"]/3600,
            "cost":"no paid API required; local inference still consumes time and energy",
            "input_tokens":"measured from backend; not inferable exactly from character counts",
            "contrast":[cfg["primary_treatment"],cfg["primary_control"]]}


def prepare(cfg:dict,out:Path,accepted:bool=False,mock:bool=False) -> dict:
    """Resolve/check a real model at seal time. No inference occurs in prepare."""
    if out.exists():raise FileExistsError("Design output already exists; never overwrite a sealed design")
    cfg=deepcopy(cfg)
    provenance=read_json(ASSETS/"sources"/"provenance.json")
    if file_hash(ASSETS/"policies"/"author_raw.txt") != provenance["raw_policy_sha256"]:
        raise ValueError("Original heuristic hash differs from sources/provenance.json. Version the new stimulus explicitly before sealing.")
    if cfg["phase"]=="confirmatory" and not accepted and not mock:
        raise ValueError("Confirmatory seal needs --accept-operationalization. Review sources/provenance.json and docs/PROTOCOL.md first")
    if mock:
        info={"identity":{"model":"SCRIPTED_TEST_DOUBLE","type":"mock"},"identity_hash":"TEST_DOUBLE","local_checkpoint_attested":False}
    else:
        provider=HTTPProvider(cfg["provider"]);info=provider.inspect();cfg["provider"]=provider.config
    out.mkdir(parents=True)
    for d in ["public","private","policies","trials"]:(out/d).mkdir()
    sources=source_manifest()
    policies={}
    for arm in cfg["arms"]:
        src=ASSETS/"policies"/POLICIES[arm]["path"]
        dst=out/"policies"/(arm+".txt");dst.write_bytes(src.read_bytes())
        policies[arm]={"path":str(dst.relative_to(out)).replace('\\','/'),"sha256":file_hash(dst),"chars":len(dst.read_text(encoding="utf-8")),"role":POLICIES[arm]["role"]}
    seeds=list(range(cfg["seed_start"],cfg["seed_start"]+cfg["clusters"]))
    suite=make_suite(cfg["families"],seeds,cfg["phase"])
    case_index=[]
    for c in suite:
        public={"case_id":c.case_id,"opening":c.opening,"public":c.public}
        private={"case_id":c.case_id,"cluster":c.cluster,"family":c.family,"twin":c.twin,"private":c.private}
        write_json(out/"public"/(c.case_id+".json"),public)
        write_json(out/"private"/(c.case_id+".json"),private)
        case_index.append({"case_id":c.case_id,"cluster":c.cluster,"family":c.family,"twin":c.twin,"public_hash":c.public_hash})
    schedule=[]
    for seed in seeds:
        block=[]
        for c in [x for x in suite if x.cluster==seed]:
            for repeat in range(cfg["repeats"]):
                model_seed=int(digest([c.case_id,repeat,"draw"])[:7],16)
                for arm in cfg["arms"]:
                    tid="trial_"+digest([c.case_id,arm,repeat])[:20]
                    block.append({"trial_id":tid,"case_id":c.case_id,"arm":arm,"repeat":repeat,"model_seed":model_seed})
        rng_for("schedule-v1",seed,cfg["phase"]).shuffle(block);schedule.extend(block)
    write_json(out/"schedule.json",schedule)
    write_json(out/"case_index.json",case_index)
    write_json(out/"source_manifest.json",sources)
    files={str(p.relative_to(out)).replace('\\','/'):file_hash(p) for p in sorted(out.rglob('*')) if p.is_file()}
    manifest={"schema":1,"created_utc":utc(),"evaluation_kind":"HARNESS_SELFTEST" if mock else "LIVE_MODEL_STUDY",
              "config":cfg,"plan":plan(cfg),"model":info,"policies":policies,"files":files,
              "source_hash":digest(sources),"operationalization_accepted":accepted,
              "scope":"literal frozen instruction package effect on generated closed-world tasks, fixed model and tool portfolio",
              "registration":"local seal only; not external preregistration and not a signed timestamp",
              "source_attribution":"author_raw is original; compiled/ablations are assistant-written operationalizations"}
    manifest["manifest_hash"]=digest(manifest)
    write_json(out/"manifest.json",manifest)
    return manifest


def load_case(out:Path,cid:str) -> Case:
    p=read_json(out/"public"/(cid+".json"));q=read_json(out/"private"/(cid+".json"))
    return Case(cid,q["cluster"],q["family"],q["twin"],p["opening"],p["public"],q["private"])


def verify_design(out:Path,check_source:bool=True) -> list[str]:
    errors=[];m=read_json(out/"manifest.json")
    copy=dict(m);claim=copy.pop("manifest_hash",None)
    if digest(copy)!=claim:errors.append("manifest hash mismatch")
    for name,expected in m["files"].items():
        p=(out/name).resolve()
        if not p.is_relative_to(out.resolve()):errors.append("unsafe manifest path");continue
        if not p.exists() or file_hash(p)!=expected:errors.append("changed/missing "+name)
    if check_source and digest(source_manifest())!=m["source_hash"]:errors.append("code/policy/source changed since seal")
    return errors
