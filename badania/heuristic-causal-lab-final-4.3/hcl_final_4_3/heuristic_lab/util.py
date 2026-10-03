"""Canonical serialization, integrity records and deterministic randomness."""
from __future__ import annotations
import hashlib
import json
import math
import os
import platform
import random
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parent
ASSETS = ROOT if (ROOT / "policies").is_dir() else PACKAGE / "assets"

def canonical(obj: Any) -> str:
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False)

def digest(obj: Any) -> str:
    return hashlib.sha256(canonical(obj).encode("utf-8")).hexdigest()

def file_hash(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def read_json(path: Path) -> Any:
    with path.open(encoding="utf-8-sig") as f:
        return json.load(f)

def write_json(path: Path, obj: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(obj, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8")
    os.replace(tmp, path)

def jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(s) for s in path.read_text(encoding="utf-8").splitlines() if s.strip()]

def rng_for(*parts: Any) -> random.Random:
    return random.Random(int(digest(parts)[:16], 16))

def utc() -> str:
    return datetime.now(timezone.utc).isoformat()

def runtime_info() -> dict:
    return {"python":sys.version, "platform":platform.platform(), "implementation":platform.python_implementation()}

def source_manifest() -> dict:
    result={"heuristic_lab/"+str(p.relative_to(PACKAGE)).replace(os.sep,"/"):file_hash(p)
            for p in sorted(PACKAGE.rglob("*.py")) if "__pycache__" not in p.parts}
    for dirname in ["policies","sources","docs"]:
        for p in sorted((ASSETS/dirname).rglob("*")):
            if p.is_file():result[dirname+"/"+str(p.relative_to(ASSETS/dirname)).replace(os.sep,"/")]=file_hash(p)
    return result


def safe_component(value: str) -> bool:
    return bool(value) and all(c.isalnum() or c in "_-" for c in value)

def finite_number(value: Any) -> bool:
    return isinstance(value, (int,float)) and not isinstance(value,bool) and math.isfinite(value)
