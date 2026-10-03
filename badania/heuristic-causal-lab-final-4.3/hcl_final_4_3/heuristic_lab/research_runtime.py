"""Safe lifecycle manager for the isolated local research endpoint on Windows.

It never restarts or kills the production LION listener.  When the research
endpoint is absent, it clones the *currently running* production llama-server
command line and changes only host/port/context.  Logs and ownership metadata
live in a shared sibling runtime directory, not inside a versioned HCL folder,
so old HCL versions remain deletable.
"""
from __future__ import annotations
from dataclasses import dataclass
from datetime import datetime
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import time
import urllib.request
from typing import Any

from .util import ROOT, write_json, read_json


class RuntimeErrorSafe(RuntimeError):
    pass


@dataclass
class EndpointLease:
    url: str
    pid: int | None
    started_here: bool
    process: subprocess.Popen | None = None
    runtime_file: Path | None = None


def _runtime_root() -> Path:
    # project is usually .../badania/hcl_final_X; keep logs outside the version
    # folder so it can be deleted after a run.
    parent=ROOT.parent
    p=parent/'.hcl-research-runtime'
    p.mkdir(parents=True,exist_ok=True)
    return p


def _get_json(url:str,timeout:float=4.0) -> dict:
    opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(url,timeout=timeout) as f:
        raw=f.read(2_000_001)
    if len(raw)>2_000_000: raise RuntimeErrorSafe('Endpoint response too large')
    data=json.loads(raw)
    if not isinstance(data,dict): raise RuntimeErrorSafe('Endpoint returned non-object JSON')
    return data


def endpoint_info(port:int) -> dict | None:
    try:
        data=_get_json(f'http://127.0.0.1:{port}/v1/models',2.0)
    except Exception:
        return None
    rows=data.get('data',[])
    if not rows: return None
    meta=rows[0].get('meta',{})
    return {'raw':data,'model':rows[0].get('id'),'n_ctx':meta.get('n_ctx')}


def _powershell_json(script:str) -> Any:
    if os.name!='nt':
        raise RuntimeErrorSafe('Windows process inspection is required for automatic LION endpoint startup')
    cp=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-Command',script],
                      text=True,capture_output=True,encoding='utf-8',errors='replace',timeout=15)
    if cp.returncode!=0:
        raise RuntimeErrorSafe('PowerShell inspection failed: '+(cp.stderr or cp.stdout).strip()[:1000])
    out=cp.stdout.strip()
    if not out: return None
    return json.loads(out)


def listener_process(port:int) -> dict | None:
    script=(
        f"$c=Get-NetTCPConnection -LocalPort {int(port)} -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1;"
        "if($null -eq $c){'null'}else{"
        "$p=Get-CimInstance Win32_Process -Filter \"ProcessId=$($c.OwningProcess)\";"
        "$p | Select-Object ProcessId,ParentProcessId,Name,ExecutablePath,CommandLine | ConvertTo-Json -Compress}"
    )
    return _powershell_json(script)


def _split_windows_cmdline(commandline:str) -> list[str]:
    if os.name=='nt':
        import ctypes
        from ctypes import wintypes
        argc=ctypes.c_int()
        CommandLineToArgvW=ctypes.windll.shell32.CommandLineToArgvW
        CommandLineToArgvW.argtypes=[wintypes.LPCWSTR,ctypes.POINTER(ctypes.c_int)]
        CommandLineToArgvW.restype=ctypes.POINTER(wintypes.LPWSTR)
        ptr=CommandLineToArgvW(commandline,ctypes.byref(argc))
        if not ptr: raise RuntimeErrorSafe('Cannot parse production llama-server command line')
        try:return [ptr[i] for i in range(argc.value)]
        finally:ctypes.windll.kernel32.LocalFree(ptr)
    return shlex.split(commandline)


def _replace_arg(args:list[str],names:tuple[str,...],value:str) -> None:
    for i,x in enumerate(args[:-1]):
        if x in names:
            args[i+1]=value;return
    args.extend([names[0],value])


def _remove_flag(args:list[str], names:tuple[str,...]) -> list[str]:
    return [x for x in args if x not in names]


def _remove_option(args:list[str], names:tuple[str,...]) -> list[str]:
    out=[];i=0
    while i < len(args):
        if args[i] in names:
            i += 2
            continue
        out.append(args[i]);i += 1
    return out


def _clone_research_command(prod:dict,research_port:int,context:int) -> list[str]:
    """Clone production model/runtime but harden the isolated study transport.

    The production LION process is never modified.  GPT-OSS structured output has
    shown a concrete llama.cpp/Jinja failure mode where channel-control tokens are
    emitted into message.content and loop until the generation limit.  The research
    listener uses the checkpoint's Jinja chat template with reasoning-format auto.
    The format option controls parsing; 'none' requests raw output. The explicit
    request-scoped budget override is set by the provider; the retained off flag
    is NOT a claim that no analysis tokens can be generated.  These are treatment-invariant infrastructure
    settings and are pinned in the sealed study identity.
    """
    cmd=prod.get('CommandLine') or ''
    exe=prod.get('ExecutablePath')
    if not exe or not cmd or str(prod.get('Name','')).lower()!='llama-server.exe':
        raise RuntimeErrorSafe('Production port is not owned by an inspectable llama-server.exe; refusing to infer a command')
    args=_split_windows_cmdline(cmd)
    if not args: raise RuntimeErrorSafe('Empty production llama-server command line')
    args[0]=exe
    _replace_arg(args,('--host',),'127.0.0.1')
    _replace_arg(args,('--port',),str(research_port))
    _replace_arg(args,('-c','--ctx-size'),str(context))

    # Remove production chat-template/reasoning switches before adding the study
    # transport profile.  This does not touch the production process.
    args=_remove_flag(args,('--jinja','--no-jinja'))
    args=_remove_option(args,('--chat-template','--chat-template-file','--reasoning','-rea','--reasoning-format'))
    # Keep the server arguments matching the diagnosed A/B experiment. The HTTP
    # provider explicitly overrides this counter with max_tokens+1 per request.
    # reasoning=off alone did NOT prevent the observed empty-analysis loop.
    args.extend(['--jinja','--reasoning','off','--reasoning-format','auto'])
    return args




def _research_transport_ok(proc:dict|None) -> bool:
    if not proc or str(proc.get('Name','')).lower()!='llama-server.exe':
        return False
    cmd=proc.get('CommandLine') or ''
    checks=[
        r'(?:^|\s)--jinja(?:\s|$)',
        r'(?:^|\s)--reasoning-format\s+auto(?:\s|$)',
        r'(?:^|\s)(?:--reasoning|-rea)\s+off(?:\s|$)',
    ]
    return all(re.search(x,cmd) for x in checks) and not re.search(r'(?:^|\s)--no-jinja(?:\s|$)',cmd)

def ensure_research_endpoint(prod_port:int=8772,research_port:int=8773,context:int=8192,
                             startup_timeout:float=120.0) -> EndpointLease:
    existing=endpoint_info(research_port)
    if existing is not None:
        if int(existing.get('n_ctx') or -1)!=context:
            raise RuntimeErrorSafe(f'Research endpoint {research_port} exists but reports n_ctx={existing.get("n_ctx")}, expected {context}; refusing to replace it')
        proc=listener_process(research_port) if os.name=='nt' else None
        if os.name=='nt' and not _research_transport_ok(proc):
            raise RuntimeErrorSafe(f'Research endpoint {research_port} exists with a different transport. No process was killed. Use its original owner to stop that research instance; never stop production 8772.')
        if existing is not None:
            return EndpointLease(f'http://127.0.0.1:{research_port}/v1',int(proc['ProcessId']) if proc else None,False)

    # If something is listening but is not our HTTP model endpoint, do not kill it.
    occupied=listener_process(research_port) if os.name=='nt' else None
    if occupied:
        raise RuntimeErrorSafe(f'Port {research_port} is occupied by PID {occupied.get("ProcessId")} ({occupied.get("Name")}) but /v1/models is not healthy')

    prod_info=endpoint_info(prod_port)
    if prod_info is None:
        raise RuntimeErrorSafe(f'Production LION endpoint {prod_port} is not healthy. Nothing was restarted.')
    prod=listener_process(prod_port)
    if not prod:
        raise RuntimeErrorSafe(f'Cannot identify the process listening on production port {prod_port}')

    args=_clone_research_command(prod,research_port,context)
    rr=_runtime_root();logs=rr/'logs';logs.mkdir(exist_ok=True)
    stamp=datetime.now().strftime('%Y%m%d-%H%M%S')
    stdout_path=logs/f'research-{research_port}-{stamp}.stdout.log'
    stderr_path=logs/f'research-{research_port}-{stamp}.stderr.log'
    out=stdout_path.open('ab',buffering=0);err=stderr_path.open('ab',buffering=0)
    flags=0
    if os.name=='nt':
        flags=getattr(subprocess,'CREATE_NEW_PROCESS_GROUP',0)|getattr(subprocess,'DETACHED_PROCESS',0)
    try:
        p=subprocess.Popen(args,stdout=out,stderr=err,stdin=subprocess.DEVNULL,
                           creationflags=flags,close_fds=True)
    finally:
        out.close();err.close()

    runtime_file=rr/f'research-{research_port}.json'
    write_json(runtime_file,{'pid':p.pid,'research_port':research_port,'production_port':prod_port,
                             'context':context,'command':args,'stdout':str(stdout_path),'stderr':str(stderr_path),
                             'owner':'heuristic-causal-lab'})
    deadline=time.monotonic()+startup_timeout
    while time.monotonic()<deadline:
        info=endpoint_info(research_port)
        if info is not None:
            if int(info.get('n_ctx') or -1)!=context:
                stop_research_endpoint(EndpointLease('',p.pid,True,p,runtime_file))
                raise RuntimeErrorSafe(f'Research endpoint started with n_ctx={info.get("n_ctx")}, expected {context}')
            return EndpointLease(f'http://127.0.0.1:{research_port}/v1',p.pid,True,p,runtime_file)
        if p.poll() is not None:
            tail=''
            try: tail=stderr_path.read_text(encoding='utf-8',errors='replace')[-4000:]
            except Exception: pass
            raise RuntimeErrorSafe(f'Research llama-server exited during startup with code {p.returncode}. stderr tail: {tail}')
        time.sleep(1)
    stop_research_endpoint(EndpointLease('',p.pid,True,p,runtime_file))
    raise RuntimeErrorSafe(f'Research endpoint {research_port} did not become ready within {startup_timeout:.0f}s')


def stop_research_endpoint(lease:EndpointLease) -> bool:
    """Stop only a server this invocation started; production is never touched."""
    if not lease.started_here or not lease.pid:
        return False
    if lease.process is not None and lease.process.poll() is None:
        try:
            lease.process.terminate();lease.process.wait(timeout=12)
        except Exception:
            if os.name=='nt':
                subprocess.run(['taskkill','/PID',str(lease.pid),'/T','/F'],capture_output=True,text=True)
            else:
                try: lease.process.kill()
                except Exception: pass
    if lease.runtime_file:
        try: lease.runtime_file.unlink(missing_ok=True)
        except Exception: pass
    return True


def stop_owned_research(research_port:int=8773) -> dict:
    """Stop a research listener only when shared HCL ownership metadata and PID agree."""
    rf=_runtime_root()/f'research-{research_port}.json'
    if not rf.exists():
        return {'status':'NOT_OWNED_OR_NOT_RUNNING','stopped':False,'port':research_port}
    meta=read_json(rf);pid=int(meta.get('pid',-1))
    proc=listener_process(research_port) if os.name=='nt' else None
    if not proc:
        rf.unlink(missing_ok=True)
        return {'status':'ALREADY_STOPPED','stopped':False,'port':research_port,'pid':pid}
    cmd=proc.get('CommandLine') or ''
    if int(proc.get('ProcessId',-2))!=pid or str(proc.get('Name','')).lower()!='llama-server.exe' or not re.search(rf'(?:^|\s)--port\s+{research_port}(?:\s|$)',cmd):
        raise RuntimeErrorSafe('Ownership check failed; refusing to stop the process on the research port')
    subprocess.run(['taskkill','/PID',str(pid),'/T','/F'],capture_output=True,text=True)
    rf.unlink(missing_ok=True)
    return {'status':'STOPPED','stopped':True,'port':research_port,'pid':pid}
