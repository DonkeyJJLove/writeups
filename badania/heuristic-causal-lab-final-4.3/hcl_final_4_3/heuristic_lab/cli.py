"""Portable CLI; no external Python packages required for live local evaluation."""
from __future__ import annotations
import argparse
import json
import math
from pathlib import Path
import statistics
import sys
from .analysis import analyse
from .design import load_config, prepare, plan
from .engine import execute_study, audit_study
from .fixtures import smoke
from .providers import HTTPProvider, ProviderError
from .util import ROOT, ASSETS, runtime_info, write_json


def main(argv:list[str]|None=None) -> int:
    p=argparse.ArgumentParser(prog="python -m heuristic_lab",description="Causal test of a frozen heuristic, not a benchmark of unequal algorithm libraries.")
    sub=p.add_subparsers(dest="command",required=True)
    for name in ["doctor","plan","prepare","smoke"]:
        sp=sub.add_parser(name)
        sp.add_argument("--config",type=Path,default=ASSETS/"configs"/"pilot.json")
        if name in {"prepare","smoke"}:sp.add_argument("--output",type=Path,required=True)
        if name=="prepare":sp.add_argument("--accept-operationalization",action="store_true")
        if name=="doctor":sp.add_argument("--test-structured-output",action="store_true",help="perform four tiny live schema-constrained transport probes")
    run=sub.add_parser("run");run.add_argument("design",type=Path);run.add_argument("--confirm-inference",action="store_true")
    for name in ["audit","report"]:
        sp=sub.add_parser(name);sp.add_argument("design",type=Path)
    pw=sub.add_parser("power");pw.add_argument("--effect",type=float,default=.10);pw.add_argument("--cluster-sd",type=float,default=.20)
    pw.add_argument("--margin",type=float,default=.05);pw.add_argument("--power",type=float,default=.80);pw.add_argument("--alpha",type=float,default=.05/4)
    setup=sub.add_parser("configure")
    setup.add_argument("--model",required=True)
    setup.add_argument("--backend",choices=["ollama","openai_compatible"],default="ollama")
    setup.add_argument("--url")
    setup.add_argument("--template",type=Path,default=ASSETS/"configs"/"pilot.json")
    setup.add_argument("--output",type=Path,default=Path("configs/local.json"))
    args=p.parse_args(argv)
    try:
        if args.command=="configure":
            if args.output.exists():raise FileExistsError("Config already exists; choose a new filename")
            cfg=load_config(args.template)
            cfg["provider"].update(type=args.backend,model=args.model,url=args.url or ("http://127.0.0.1:11434" if args.backend=="ollama" else "http://127.0.0.1:8001/v1"))
            if args.backend=="openai_compatible":cfg["provider"].pop("think",None)
            HTTPProvider(cfg["provider"])
            write_json(args.output,cfg)
            print(json.dumps({"config":str(args.output),"inference_performed":False,"next":"Run doctor and prepare with this config."},indent=2))
        elif args.command=="doctor":
            cfg=load_config(args.config);provider=HTTPProvider(cfg["provider"]);model=provider.inspect()
            probe=provider.probe_structured_output(4) if args.test_structured_output else None
            print(json.dumps({"runtime":runtime_info(),"model":model,"structured_output_probe":probe,"plan":plan(cfg)},ensure_ascii=False,indent=2))
        elif args.command=="plan":print(json.dumps(plan(load_config(args.config)),ensure_ascii=False,indent=2))
        elif args.command=="prepare":
            result=prepare(load_config(args.config),args.output,args.accept_operationalization)
            print(json.dumps({"manifest":str(args.output/"manifest.json"),"hash":result["manifest_hash"],"model":result["model"],"plan":result["plan"]},ensure_ascii=False,indent=2))
        elif args.command=="run":
            result=execute_study(args.design,args.confirm_inference)
            print(json.dumps(result,ensure_ascii=False,indent=2))
            summary=analyse(args.design)
            print(json.dumps({"verdict":summary["verdict"],"report":str(args.design/"report.html")},ensure_ascii=False,indent=2))
            return 0 if result["provider_errors_this_invocation"]==0 and result["model_stable_at_end"] else 1
        elif args.command=="audit":
            result=audit_study(args.design);print(json.dumps(result,ensure_ascii=False,indent=2));return 0 if result["status"]=="PASS" else 1
        elif args.command=="report":
            result=analyse(args.design);print(json.dumps({"verdict":result["verdict"],"arms":result["arms"],"report":str(args.design/"report.html")},ensure_ascii=False,indent=2))
        elif args.command=="smoke":print(json.dumps(smoke(args.output,load_config(args.config)),ensure_ascii=False,indent=2))
        elif args.command=="power":
            if not 0<args.power<1 or not 0<args.alpha<.5 or args.effect<=args.margin or args.cluster_sd<=0:raise ValueError("Need effect > margin, positive SD, power/alpha in (0,1)")
            z=statistics.NormalDist()
            n=math.ceil(((z.inv_cdf(1-args.alpha/2)+z.inv_cdf(args.power))*args.cluster_sd/(args.effect-args.margin))**2)
            print(json.dumps({"approximate_clusters":n,"assumed_effect":args.effect,"practical_margin":args.margin,
                             "assumed_cluster_sd":args.cluster_sd,"scope":"normal approximation for planning only; estimate SD on separate pilot, not held-out outcomes",
                             "rare_harm_note":"Tight harm noninferiority can require more clusters than the benefit endpoint; no finite run guarantees decisiveness."},indent=2))
        return 0
    except (ValueError,FileExistsError,FileNotFoundError,ProviderError) as e:
        print("ERROR: "+str(e),file=sys.stderr)
        if args.command in {"doctor","prepare"}:
            print("No model answers were fabricated. Check the specific error above: AUTO with multiple models requires an exact ID; connection failure requires server/URL checks. Software-only check: python -m heuristic_lab smoke --output results/selftest",file=sys.stderr)
        return 2

if __name__=="__main__":raise SystemExit(main())
