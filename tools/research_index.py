from __future__ import annotations
from dataclasses import dataclass,asdict
from hashlib import sha256
import json,subprocess
from pathlib import Path,PurePosixPath
MAX_ENTRIES=128
ALLOWED_TOP_EXT={".md",".txt",".json"}
PREFIX_RULES=(
 "badania/heuristic-causal-lab-final-4.3/",
 "badania/LOCI/",
)
EXCLUDED_PARTS={".git",".env","secrets","credentials","__pycache__",".venv","venv","node_modules"}
class ResearchIndexError(ValueError):pass
def _git(repo:Path,*args:str)->bytes:
 cp=subprocess.run(["git",*args],cwd=repo,stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=False)
 if cp.returncode:raise ResearchIndexError(cp.stderr.decode("utf-8","replace")[-1000:])
 return cp.stdout
def _safe(path:str)->bool:
 p=PurePosixPath(path)
 return not p.is_absolute() and ".." not in p.parts and not (set(p.parts)&EXCLUDED_PARTS)
def _selected(path:str)->bool:
 if not _safe(path):return False
 p=PurePosixPath(path)
 if len(p.parts)==1 and p.suffix.lower() in ALLOWED_TOP_EXT:return True
 if path.startswith("badania/heuristic-causal-lab-final-4.3/"):
  return p.name in {"README.md","BUILD_REPORT.md","manifest.json","source_manifest.json"}
 if path.startswith("badania/LOCI/"):
  return p.name=="README.md" or path=="badania/LOCI/parsers/manifest.json"
 return False
def classify(path:str)->str:
 if path.endswith(".json"):return "STRUCTURED_RESEARCH_ARTIFACT"
 if path.startswith("badania/"):return "RESEARCH_ARTIFACT"
 if path in {"AGENTS.md","PROCESS_GUARD.md","AI_NATIVE_ROADMAP.md","cyber-lion.repository.json","REPOSITORY_STANDARDIZATION_R1.json"}:return "REPOSITORY_CONTROL_DOCUMENT"
 return "RESEARCH_DOCUMENT"
def build_index(repo:Path,source_ref:str="HEAD")->dict:
 repo=Path(repo).resolve()
 head=_git(repo,"rev-parse",source_ref).decode().strip();tree=_git(repo,"rev-parse",head+"^{tree}").decode().strip()
 names=_git(repo,"-c","core.quotepath=false","ls-tree","-r","--name-only","-z",head).split(b"\0")
 paths=sorted(x.decode("utf-8") for x in names if x and _selected(x.decode("utf-8")))
 if len(paths)>MAX_ENTRIES:raise ResearchIndexError("selection exceeds bound")
 rows=[]
 for path in paths:
  raw=_git(repo,"show",head+":"+path)
  rows.append({"path":path,"sha256":sha256(raw).hexdigest(),"bytes":len(raw),"class":classify(path),"version_ref":head,"retention":"KEEP_SOURCE_BOUND"})
 payload={"schema":"lion.research-index/v1","repository":"DonkeyJJLove/writeups","head":head,"tree":tree,"selection_policy":"TOP_LEVEL_DOCS_PLUS_BOUNDED_HCL_LOCI_METADATA","entry_count":len(rows),"entries":rows,"authority_effect":"NONE","execution_effect":"NONE"}
 canonical=json.dumps(payload,sort_keys=True,separators=(",",":"),ensure_ascii=False).encode()
 payload["index_digest"]=sha256(b"LION/RESEARCH-INDEX/1\0"+canonical).hexdigest()
 return payload
def validate_index(value:dict)->dict:
 if value.get("schema")!="lion.research-index/v1" or value.get("repository")!="DonkeyJJLove/writeups":raise ResearchIndexError("identity")
 if value.get("entry_count")!=len(value.get("entries",[])) or value["entry_count"]>MAX_ENTRIES:raise ResearchIndexError("count")
 if value.get("authority_effect")!="NONE" or value.get("execution_effect")!="NONE":raise ResearchIndexError("effects")
 paths=[r.get("path") for r in value["entries"]]
 if paths!=sorted(set(paths)) or any(not isinstance(p,str) or not _safe(p) for p in paths):raise ResearchIndexError("paths")
 payload=dict(value);digest=payload.pop("index_digest",None)
 canonical=json.dumps(payload,sort_keys=True,separators=(",",":"),ensure_ascii=False).encode()
 expected=sha256(b"LION/RESEARCH-INDEX/1\0"+canonical).hexdigest()
 if digest!=expected:raise ResearchIndexError("digest")
 return value
def read_entry(repo:Path,index:dict,path:str)->bytes:
 validate_index(index)
 matches=[r for r in index["entries"] if r["path"]==path]
 if len(matches)!=1:raise ResearchIndexError("entry not indexed")
 raw=_git(Path(repo).resolve(),"show",index["head"]+":"+path)
 if sha256(raw).hexdigest()!=matches[0]["sha256"] or len(raw)!=matches[0]["bytes"]:raise ResearchIndexError("content drift")
 return raw
if __name__=="__main__":
 root=Path(__file__).resolve().parents[1];print(json.dumps(build_index(root),ensure_ascii=False,indent=2))
