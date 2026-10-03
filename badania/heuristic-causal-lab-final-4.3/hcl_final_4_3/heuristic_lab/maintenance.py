"""Maintenance helpers for removing obsolete HCL version directories safely."""
from __future__ import annotations
import argparse
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import time

from .util import ROOT

NAME_RE=re.compile(r'^(?:hcl_final_|heuristic-causal-lab-final-)')


def _is_hcl_dir(p:Path)->bool:
    try:
        pyproject=(p/'pyproject.toml').read_text(encoding='utf-8',errors='ignore')
    except Exception:
        return False
    return (p/'heuristic_lab').is_dir() and 'name = "heuristic-causal-lab"' in pyproject


def _onerror(func,path,exc_info):
    try:
        os.chmod(path,stat.S_IWRITE|stat.S_IREAD)
        func(path)
    except Exception:
        raise exc_info[1]


def _remove_tree(p:Path)->tuple[bool,str|None]:
    try:
        for root,dirs,files in os.walk(p):
            for n in files:
                try: os.chmod(Path(root)/n,stat.S_IWRITE|stat.S_IREAD)
                except Exception: pass
            for n in dirs:
                try: os.chmod(Path(root)/n,stat.S_IWRITE|stat.S_IREAD|stat.S_IEXEC)
                except Exception: pass
        shutil.rmtree(p,onerror=_onerror)
        return True,None
    except Exception as first:
        if os.name=='nt':
            cp=subprocess.run(['cmd.exe','/d','/c','rd','/s','/q',str(p)],capture_output=True,text=True)
            if not p.exists(): return True,None
            return False,(cp.stderr or cp.stdout or repr(first)).strip()
        return False,repr(first)


def clean_old(parent:Path|None=None,yes:bool=False)->dict:
    current=ROOT.resolve()
    parent=(parent or current.parent).resolve()
    candidates=[]
    for p in parent.iterdir():
        if p.is_dir() and p.resolve()!=current and NAME_RE.match(p.name) and _is_hcl_dir(p):
            candidates.append(p)
    candidates=sorted(candidates)
    if not candidates:
        return {'status':'NOTHING_TO_DELETE','deleted':[],'failed':[],'parent':str(parent)}
    if not yes:
        raise RuntimeError('Refusing deletion without --yes. Candidates: '+', '.join(p.name for p in candidates))

    # Ensure this process itself is not holding a version directory as CWD.
    os.chdir(parent)
    deleted=[];failed=[]
    for p in candidates:
        ok,error=_remove_tree(p)
        if ok: deleted.append(str(p))
        else: failed.append({'path':str(p),'error':error,
                             'hint':'Close terminals/IDEs whose current directory is inside this old version and run cleanup again.'})
    return {'status':'PASS' if not failed else 'PARTIAL','deleted':deleted,'failed':failed,'parent':str(parent),
            'current_kept':str(current)}


def main(argv:list[str]|None=None)->int:
    p=argparse.ArgumentParser(description=__doc__)
    sub=p.add_subparsers(dest='cmd',required=True)
    c=sub.add_parser('clean-old');c.add_argument('--parent',type=Path);c.add_argument('--yes',action='store_true')
    a=p.parse_args(argv)
    try:
        if a.cmd=='clean-old':
            import json
            r=clean_old(a.parent,a.yes);print(json.dumps(r,ensure_ascii=False,indent=2));return 0 if r['status']!='PARTIAL' else 1
    except Exception as e:
        print('ERROR: '+str(e),file=sys.stderr);return 2
    return 0

if __name__=='__main__': raise SystemExit(main())
