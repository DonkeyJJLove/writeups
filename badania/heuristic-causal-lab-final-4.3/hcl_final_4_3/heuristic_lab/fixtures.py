"""Engineering test doubles, NEVER evidence about a heuristic or language model.

The scripted oracle has private labels by construction. This intentional fixture
lets the test suite check both valid and malicious outcomes. Live providers do not
receive a Case object or these labels. Every fixture artifact is marked MOCK.
"""
from __future__ import annotations
import json
from collections import defaultdict
from pathlib import Path
from .analysis import analyse
from .design import load_case, prepare
from .engine import run_episode
from .models import Case, ProviderReply
from .util import canonical, digest, read_json, runtime_info, utc, write_json


class OracleFixture:
    is_mock=True
    def __init__(self,case:Case,mode:str="oracle"):
        self.case=case;self.mode=mode;self.actions=[{"kind":"tool","name":"read","args":{"id":"packet"}}]
        if case.family=="state_update":self.actions.append({"kind":"tool","name":"read","args":{"id":"updates"}})
        if case.family=="recovery":
            self.actions.extend([{"kind":"tool","name":"read","args":{"id":"primary"}}, {"kind":"tool","name":"recover","args":{}}])
        if case.private["track"]=="representation":
            p=case.public["packet"]["problem"]
            if p["type"]=="cnf":
                parent=list(range(p["n"]))
                def root(x):
                    while parent[x]!=x:x=parent[x]
                    return x
                for clause in p["clauses"]:
                    variables=[abs(x)-1 for x in clause]
                    for x in variables[1:]:parent[root(x)]=root(variables[0])
                groups=defaultdict(list)
                for x in range(p["n"]):groups[root(x)].append(x)
                tool={"kind":"tool","name":"factor","args":{"groups":list(groups.values())}}
            elif p["type"]=="xor":tool={"kind":"tool","name":"eliminate","args":{}}
            elif p["type"]=="words":tool={"kind":"tool","name":"suffix","args":{"memory":max(map(len,p["forbidden"]))-1}}
            else:
                groups=defaultdict(list)
                for i,row in enumerate(p["rows"]):groups[tuple(sorted(row))].append(i)
                tool={"kind":"tool","name":"quotient","args":{"groups":list(groups.values()),"preserve_multiplicity":p["labeled"]}}
            self.actions.append(tool)
        exp=case.private["expected"]
        final={"kind":"final","decision":exp["decision"],"answer":exp["answer"],
               "evidence":[f"receipt-{i+1}" for i in range(len(self.actions))],"confidence":1.,
               "status":"UNKNOWN" if exp["decision"]=="abstain" else "VERIFIED","reason":"SCRIPTED_ORACLE_TEST_DOUBLE"}
        if mode=="always_abstain":final.update(decision="abstain",answer=None,status="UNKNOWN")
        elif mode=="unsafe":final.update(decision="execute",answer=-999,status="VERIFIED")
        self.actions.append(final);self.position=0

    def complete(self,messages:list[dict],seed:int,max_tokens:int) -> ProviderReply:
        if self.position>=len(self.actions):raise RuntimeError("fixture ran out of actions")
        action=self.actions[self.position];self.position+=1
        return ProviderReply(canonical(action),{}, {"model":"SCRIPTED_ORACLE_TEST_DOUBLE","seed":seed,"not_inference":True})


def smoke(out:Path,cfg:dict) -> dict:
    cfg=dict(cfg);cfg.update(phase="pilot",clusters=1,seed_start=71031,repeats=1,
                            arms=["strong_control","author_raw"],primary_treatment="author_raw",primary_control="strong_control")
    manifest=prepare(cfg,out,mock=True)
    for item in read_json(out/"schedule.json"):
        case=load_case(out,item["case_id"])
        policy=(out/manifest["policies"][item["arm"]]["path"]).read_text(encoding="utf-8")
        result=run_episode(case,policy,OracleFixture(case),cfg["budget"],item["model_seed"])
        record={"assignment":item,"manifest_hash":manifest["manifest_hash"],"case_public_hash":case.public_hash,
                "model_identity_hash":"TEST_DOUBLE","policy_hash":manifest["policies"][item["arm"]]["sha256"],
                "run_kind":"HARNESS_SELFTEST","runtime":runtime_info(),"recorded_utc":utc(),**result}
        record["artifact_hash"]=digest(record);write_json(out/"trials"/(item["trial_id"]+".json"),record)
    summary=analyse(out,iterations=500)
    if summary["verdict"]["verdict"]!="HARNESS_SELFTEST_ONLY":raise RuntimeError("Mock data escaped research firewall")
    if not summary["audit"]["fully_complete"]:raise RuntimeError("Smoke audit failed")
    if any(x["safe_success"]!=x["trials"] for x in summary["arms"].values()):raise RuntimeError("Oracle fixture failed an expected checker")
    return {"mode":"HARNESS_SELFTEST_ONLY","scope":"fixtures validate software, NOT heuristic quality",
            "episodes":sum(x["trials"] for x in summary["arms"].values()),"audit":summary["audit"],
            "report":str(out/"report.html"),"live_model_calls":0}
