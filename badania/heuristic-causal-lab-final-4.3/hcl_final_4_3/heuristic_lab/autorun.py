"""One-command Windows pilot/confirmatory runner for the heuristic experiment.

This command owns the research endpoint lifecycle for the duration of the run.
It never restarts production LION on 8772.  All output paths are unique, so an
old preflight or sealed study can never block a new invocation.
"""
from __future__ import annotations
import argparse
from datetime import datetime
import json
from pathlib import Path
import sys

from .analysis import analyse
from .design import load_config, prepare
from .engine import execute_study, audit_study
from .lion_setup import create_profile
from .research_runtime import ensure_research_endpoint, stop_research_endpoint, RuntimeErrorSafe
from .util import ASSETS, ROOT


def _unique_run_dir(base:Path,phase:str) -> Path:
    stamp=datetime.now().strftime('%Y%m%d-%H%M%S')
    p=base/f'{phase}_{stamp}'
    i=1
    while p.exists():
        p=base/f'{phase}_{stamp}_{i:02d}';i+=1
    p.mkdir(parents=True)
    return p


def run_full(phase:str='pilot',prod_port:int=8772,research_port:int=8773,context:int=8192,
             keep_server:bool=False,accept_operationalization:bool=False,base:Path|None=None) -> dict:
    if phase not in {'pilot','confirmatory'}: raise ValueError('phase must be pilot or confirmatory')
    if phase=='confirmatory' and not accept_operationalization:
        raise ValueError('Confirmatory run requires --accept-operationalization after reviewing the pilot and frozen protocol')
    base=base or (ROOT/'runs')
    run_dir=_unique_run_dir(base,phase)
    lease=None
    try:
        print('[1/6] Ensuring isolated research endpoint...',flush=True)
        lease=ensure_research_endpoint(prod_port,research_port,context)
        print(f'      research={lease.url} pid={lease.pid} started_here={lease.started_here}',flush=True)
        print(f'      production=http://127.0.0.1:{prod_port}/v1 untouched',flush=True)

        template=ASSETS/'configs'/('final_pilot.json' if phase=='pilot' else 'final_confirmatory.json')
        profile=run_dir/'profile.json'
        print('[2/6] Creating live profile and transport preflight...',flush=True)
        preflight=create_profile(template,profile,lease.url,test_inference=True)
        print(f'      {preflight["status"]}; mode={preflight.get("structured_output_probe",{}).get("selected_mode")}',flush=True)

        study=run_dir/'study'
        print('[3/6] Sealing randomized paired design...',flush=True)
        manifest=prepare(load_config(profile),study,accepted=accept_operationalization)
        print(f'      manifest={manifest["manifest_hash"]}',flush=True)

        print('[4/6] Running live heuristic comparison...',flush=True)
        run_info=execute_study(study,confirm=True)

        print('[5/6] Replaying deterministic audit...',flush=True)
        audit=audit_study(study)
        print(f'      audit={audit["status"]} checked={audit["checked"]}/{audit["scheduled"]}',flush=True)

        print('[6/6] Analysing and rendering report...',flush=True)
        summary=analyse(study)
        result={'run_dir':str(run_dir),'study':str(study),'profile':str(profile),
                'report':str(study/'report.html'),'summary':str(study/'summary.json'),
                'audit':audit,'verdict':summary['verdict'],
                'instrument_qualification':summary.get('instrument_qualification'),
                'run_info':run_info}
        (run_dir/'AUTORUN_RESULT.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        print('\n=== RESULT ===',flush=True)
        print(json.dumps({'verdict':result['verdict'],
                          'instrument_qualification':result['instrument_qualification'],
                          'report':result['report'],'run_dir':result['run_dir']},ensure_ascii=False,indent=2),flush=True)
        return result
    finally:
        if lease and lease.started_here and not keep_server:
            print('\nStopping only the research endpoint started by this run...',flush=True)
            stop_research_endpoint(lease)
            print('Research endpoint stopped. Production LION was not touched.',flush=True)


def main(argv:list[str]|None=None)->int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--phase',choices=['pilot','confirmatory'],default='pilot')
    p.add_argument('--prod-port',type=int,default=8772)
    p.add_argument('--research-port',type=int,default=8773)
    p.add_argument('--context',type=int,default=8192)
    p.add_argument('--keep-server',action='store_true')
    p.add_argument('--accept-operationalization',action='store_true')
    p.add_argument('--output-root',type=Path)
    a=p.parse_args(argv)
    try:
        r=run_full(a.phase,a.prod_port,a.research_port,a.context,a.keep_server,a.accept_operationalization,a.output_root)
        return 0 if r['audit']['status']=='PASS' else 1
    except KeyboardInterrupt:
        print('\nInterrupted by user. Partial study remains auditable; owned research endpoint is being stopped.',file=sys.stderr)
        return 130
    except (ValueError,OSError,RuntimeErrorSafe,RuntimeError) as e:
        print('ERROR: '+str(e),file=sys.stderr)
        print('Production LION was not restarted or modified.',file=sys.stderr)
        return 2

if __name__=='__main__': raise SystemExit(main())
