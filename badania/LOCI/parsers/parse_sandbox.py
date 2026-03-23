#!/usr/bin/env python3
"""
LOCI parser entrypoint.

Cel:
- czyta `sandbox.txt` z katalogu parsera
- zapisuje wynik do `sample/<Sample_ID>/raw|norm`
- zachowuje kontrakt pipeline
- tworzy manifest uruchomienia:
    * sample/<Sample_ID>/manifest.json
    * sample/<Sample_ID>/raw/manifest.json
- jest odporny na różne warianty formatu wejściowego

Obsługiwane wzorce wejścia:
1) klasyczne wpisy:
   12 marca o 10:33
   Autor
   Treść...

2) wpisy z datą dzienną:
   18 grudnia 2018
   Autor
   Treść...

3) wpisy rozdzielane tokenem [eot]

4) brak autora -> wpis nadal jest parsowany

5) brak rozpoznawalnych separatorów -> fallback:
   cały plik staje się jednym wpisem, zamiast pustego wyniku
"""

from __future__ import annotations

from pathlib import Path
import argparse
import hashlib
import json
import os
import re
from typing import List, Dict, Tuple, Optional


# ============================================================
# KONFIGURACJA
# ============================================================

AUTHOR_MAP = {
    "Sebastian Wieremiejczyk": "<AUTHOR_SELF>",
}

ALIASES = {
    "Sebastian Wieremiejczyk": ["Sebastian", "Sebastian W.", "d2j3", "DonkeyJJLove"],
}

# np. "12 marca o 10:33"
TIMESTAMP_RE = re.compile(
    r"^\s*(\d{1,2})\s+([A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]+)\s+o\s+(\d{1,2}:\d{2})\s*$",
    re.IGNORECASE,
)

# np. "18 grudnia 2018"
DATE_LINE_RE = re.compile(
    r"^\s*(\d{1,2})\s+([A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]+)\s+(\d{4})\s*$",
    re.IGNORECASE,
)

# opcjonalnie ISO
ISO_DATE_RE = re.compile(
    r"^\s*\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}(?::\d{2})?)?\s*$",
    re.IGNORECASE,
)

EOT_RE = re.compile(r"^\s*\[eot\]\s*$", re.IGNORECASE)

CONTROL_LINE_RE = re.compile(
    r"^\s*(\[eot\]|\[eod\]|\[end\]|\[separator\]|---+|===+)\s*$",
    re.IGNORECASE,
)

URL_RE = re.compile(r"https?://\S+", re.IGNORECASE)


# ============================================================
# NARZĘDZIA
# ============================================================

def sha1(text: str) -> str:
    return hashlib.sha1(text.encode("utf-8", errors="replace")).hexdigest()


def sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8", errors="replace")).hexdigest()


def ensure_text(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = text.replace("\ufeff", "")
    return text


def clean_line(line: str) -> str:
    return line.rstrip()


def normalize_spaces(text: str) -> str:
    lines = [re.sub(r"[ \t]+", " ", ln).strip() for ln in text.splitlines()]
    return "\n".join(lines).strip()


def looks_like_header(line: str) -> bool:
    s = line.strip()
    if not s:
        return False
    return bool(TIMESTAMP_RE.match(s) or DATE_LINE_RE.match(s) or ISO_DATE_RE.match(s))


def looks_like_author(line: str) -> bool:
    """
    Heurystyka:
    - krótka linia
    - bez URL
    - nie wygląda jak data
    - nie wygląda jak znacznik sterujący
    - nie jest bardzo "gęstym" zdaniem z wieloma separatorami
    """
    s = line.strip()
    if not s:
        return False
    if looks_like_header(s):
        return False
    if CONTROL_LINE_RE.match(s):
        return False
    if URL_RE.search(s):
        return False
    if len(s) > 80:
        return False
    if "\n" in s:
        return False
    if s.count(" ") > 6:
        return False
    if re.search(r"[.!?]{1,}", s):
        return False
    return True


def map_author(author_raw: str) -> str:
    author_raw = (author_raw or "").strip()
    if not author_raw:
        return "<AUTHOR_UNKNOWN>"
    if author_raw in AUTHOR_MAP:
        return AUTHOR_MAP[author_raw]

    for canon, aliases in ALIASES.items():
        if author_raw == canon or author_raw in aliases:
            return AUTHOR_MAP.get(canon, "<AUTHOR_UNKNOWN>")

    return "<AUTHOR_UNKNOWN>"


def detect_entry_type(content: str, links: List[str]) -> str:
    s = content.strip().lower()
    if not s:
        return "empty"
    if links and len(s) < 300:
        return "link_drop"
    if "?" in s:
        return "question_or_prompt"
    if len(s.splitlines()) >= 3:
        return "multiline_block"
    return "text_block"


def collect_links(text: str) -> List[str]:
    return URL_RE.findall(text or "")


def line_is_effectively_empty(line: str) -> bool:
    return not line.strip()


def next_sample_id(out_root: Path) -> str:
    max_id = 0
    if out_root.exists():
        for item in out_root.iterdir():
            if not item.is_dir():
                continue
            m = re.fullmatch(r"Sample_(\d{4})", item.name)
            if m:
                max_id = max(max_id, int(m.group(1)))
    return f"Sample_{max_id + 1:04d}"


def relpath_str(path: Path, start: Path) -> str:
    try:
        return str(path.resolve().relative_to(start.resolve()))
    except Exception:
        return str(path)


# ============================================================
# PODZIAŁ NA SEGMENTY
# ============================================================

def split_by_eot(text: str) -> List[str]:
    """
    Jeśli wejście ma [eot], traktujemy to jako separator logiczny.
    """
    chunks = re.split(r"(?im)^\s*\[eot\]\s*$", text)
    return [chunk.strip("\n ").strip() for chunk in chunks if chunk.strip()]


def split_block_by_headers(block: str, warnings: List[str]) -> List[Dict]:
    """
    Rozbija pojedynczy blok na wpisy po nagłówkach dat/czasów.
    Jeśli nie znajdzie nagłówków -> fallback: jeden wpis.
    """
    lines = [clean_line(ln) for ln in ensure_text(block).splitlines()]
    entries: List[Dict] = []
    i = 0
    seq = 0

    while i < len(lines):
        while i < len(lines) and (line_is_effectively_empty(lines[i]) or CONTROL_LINE_RE.match(lines[i].strip())):
            i += 1

        if i >= len(lines):
            break

        if looks_like_header(lines[i].strip()):
            header = lines[i].strip()
            i += 1

            author_raw = ""
            if i < len(lines):
                probe = lines[i].strip()
                if looks_like_author(probe):
                    author_raw = probe
                    i += 1

            content_lines = []
            while i < len(lines):
                probe = lines[i].strip()
                if looks_like_header(probe):
                    break
                if CONTROL_LINE_RE.match(probe):
                    i += 1
                    break
                content_lines.append(lines[i])
                i += 1

            content_raw = "\n".join(content_lines).strip()
            if not content_raw and author_raw:
                content_raw = ""

            entries.append({
                "timestamp_text": header,
                "author_raw": author_raw,
                "content_raw": content_raw,
                "links": collect_links(content_raw),
                "sequence_index": seq,
                "hash": sha1(content_raw),
                "source_mode": "header_split",
            })
            seq += 1
        else:
            content_lines = []
            while i < len(lines):
                probe = lines[i].strip()
                if looks_like_header(probe):
                    break
                if CONTROL_LINE_RE.match(probe):
                    i += 1
                    break
                content_lines.append(lines[i])
                i += 1

            content_raw = "\n".join(content_lines).strip()
            if content_raw:
                entries.append({
                    "timestamp_text": None,
                    "author_raw": "",
                    "content_raw": content_raw,
                    "links": collect_links(content_raw),
                    "sequence_index": seq,
                    "hash": sha1(content_raw),
                    "source_mode": "free_block",
                })
                seq += 1

    if not entries:
        fallback = normalize_spaces(block)
        if fallback:
            warnings.append("[split_block_by_headers] No headers recognized in block; fallback to single entry.")
            entries.append({
                "timestamp_text": None,
                "author_raw": "",
                "content_raw": fallback,
                "links": collect_links(fallback),
                "sequence_index": 0,
                "hash": sha1(fallback),
                "source_mode": "single_block_fallback",
            })

    return entries


def split_entries(text: str) -> Tuple[List[Dict], List[str]]:
    """
    Główny parser:
    1) jeśli są [eot] -> dziel po [eot], potem próbuj nagłówki wewnątrz bloków
    2) jeśli nie ma [eot] -> próbuj parsować po nagłówkach
    3) jeśli nic nie znajdziesz -> jeden wpis fallback
    """
    warnings: List[str] = []
    text = ensure_text(text).strip()

    if not text:
        warnings.append("[split_entries] Input text is empty.")
        return [], warnings

    entries: List[Dict] = []

    if EOT_RE.search(text):
        blocks = split_by_eot(text)
        seq = 0
        for block in blocks:
            chunk_entries = split_block_by_headers(block, warnings)
            for item in chunk_entries:
                item["sequence_index"] = seq
                seq += 1
                entries.append(item)
    else:
        entries = split_block_by_headers(text, warnings)

    if not entries:
        normalized = normalize_spaces(text)
        if normalized:
            warnings.append("[split_entries] No entries parsed from input text; fallback to single full-text entry.")
            entries = [{
                "timestamp_text": None,
                "author_raw": "",
                "content_raw": normalized,
                "links": collect_links(normalized),
                "sequence_index": 0,
                "hash": sha1(normalized),
                "source_mode": "full_text_fallback",
            }]
        else:
            warnings.append("[split_entries] No entries parsed from input text.")
            return [], warnings

    filtered = []
    for idx, entry in enumerate(entries):
        content = (entry.get("content_raw") or "").strip()
        timestamp = (entry.get("timestamp_text") or "").strip()
        author = (entry.get("author_raw") or "").strip()
        if content or timestamp or author:
            entry["sequence_index"] = idx
            filtered.append(entry)

    if not filtered:
        warnings.append("[split_entries] All parsed entries were empty after filtering.")
        return [], warnings

    return filtered, warnings


# ============================================================
# NORMALIZACJA
# ============================================================

def resolve_timestamp_iso(timestamp_text: Optional[str]) -> Optional[str]:
    """
    Na razie świadomie nie próbujemy agresywnie zgadywać daty.
    Zostawiamy None, chyba że wejście było ISO.
    """
    if not timestamp_text:
        return None
    ts = timestamp_text.strip()
    if ISO_DATE_RE.match(ts):
        return ts.replace(" ", "T")
    return None


def normalize_entry(sample_id: str, idx: int, entry: Dict) -> Dict:
    author_raw = (entry.get("author_raw") or "").strip()
    author_id = map_author(author_raw)
    content_raw = entry.get("content_raw", "") or ""
    content_norm = normalize_spaces(content_raw)
    links = entry.get("links", []) or []

    return {
        "sample_id": sample_id,
        "entry_id": f"{sample_id}_E{idx:04d}",
        "author_id": author_id,
        "author_role": "self" if author_id == "<AUTHOR_SELF>" else "unknown",
        "author_raw": author_raw,
        "timestamp_text": entry.get("timestamp_text"),
        "timestamp_iso": resolve_timestamp_iso(entry.get("timestamp_text")),
        "content_norm": content_norm,
        "content_display": content_raw,
        "entry_type": detect_entry_type(content_norm, links),
        "parent_entry_id": None,
        "similarity_score": None,
        "links": links,
        "entities_masked": (
            [{"type": "PERSON", "raw": author_raw, "norm": author_id}] if author_raw else []
        ),
        "source_mode": entry.get("source_mode", "unknown"),
        "hash": entry.get("hash") or sha1(content_raw),
    }


# ============================================================
# RAPORTY / MANIFEST
# ============================================================

def build_parse_report(
    sample_id: str,
    sandbox_path: Path,
    entries: List[Dict],
    warnings: List[str]
) -> Dict:
    authors_detected = sorted(
        {e.get("author_raw", "").strip() for e in entries if e.get("author_raw", "").strip()}
    )
    links_count = sum(len(e.get("links", []) or []) for e in entries)

    relation_counts = {}
    for e in entries:
        mode = e.get("source_mode", "unknown")
        relation_counts[mode] = relation_counts.get(mode, 0) + 1

    return {
        "sample_id": sample_id,
        "sandbox_path": str(sandbox_path),
        "entries_count": len(entries),
        "links_count": links_count,
        "authors_detected": authors_detected,
        "relation_counts": relation_counts,
        "warnings_count": len(warnings),
        "warnings_preview": warnings[:20],
        "notes": [
            "timestamp_iso is conservatively resolved only for ISO-like input",
            "entry typing is heuristic and should be refined on real corpus",
            "parser uses fallback-to-single-entry instead of emitting empty payloads",
        ],
    }


def build_manifest(
    sample_id: str,
    sandbox_path: Path,
    text: str,
    sample_root: Path,
    raw_dir: Path,
    norm_dir: Path,
    raw_entries_path: Path,
    norm_entries_path: Path,
    parse_report_path: Path,
    warnings_path: Path,
    author_map_path: Path,
    aliases_path: Path,
    sample_manifest_path: Path,
    raw_manifest_path: Path,
    project_root: Path,
) -> Dict:
    return {
        "sample_id": sample_id,
        "status": "parsed",
        "parser_mode": "python-canonical",
        "input": {
            "sandbox_path": str(sandbox_path),
            "sandbox_sha256": sha256(text),
            "sandbox_bytes_utf8": len(text.encode("utf-8", errors="replace")),
        },
        "paths": {
            "sample_root": relpath_str(sample_root, project_root),
            "raw_path": relpath_str(raw_dir, project_root),
            "norm_path": relpath_str(norm_dir, project_root),
            "sample_manifest": relpath_str(sample_manifest_path, project_root),
            "raw_manifest": relpath_str(raw_manifest_path, project_root),
        },
        "outputs": {
            "raw_entries_jsonl": relpath_str(raw_entries_path, project_root),
            "norm_sample_json": relpath_str(norm_entries_path, project_root),
            "parse_report_json": relpath_str(parse_report_path, project_root),
            "warnings_json": relpath_str(warnings_path, project_root),
            "author_map_json": relpath_str(author_map_path, project_root),
            "aliases_json": relpath_str(aliases_path, project_root),
        },
        "parser_contract": {
            "writes_to": "sample/<Sample_ID>/raw|norm",
            "fallback_mode": "single_entry_if_no_structural_split_detected",
            "empty_output_allowed": False,
            "sample_manifest_location": "sample/<Sample_ID>/manifest.json",
        },
        "runtime": {
            "cwd": os.getcwd(),
            "script_name": Path(__file__).name,
        },
    }


# ============================================================
# ZAPIS
# ============================================================

def write_json(path: Path, payload: Dict | List) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def write_jsonl(path: Path, rows: List[Dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fh:
        for row in rows:
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")


# ============================================================
# MAIN
# ============================================================

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample-id", default=None)
    parser.add_argument("--sandbox", default=str(Path(__file__).with_name("sandbox.txt")))
    parser.add_argument("--out-root", default=str(Path(__file__).resolve().parents[1] / "sample"))
    args = parser.parse_args()

    sandbox = Path(args.sandbox)
    if not sandbox.exists():
        raise SystemExit(f"Missing sandbox file: {sandbox}")

    out_root = Path(args.out_root)
    out_root.mkdir(parents=True, exist_ok=True)

    sample_id = args.sample_id or next_sample_id(out_root)

    project_root = Path(__file__).resolve().parents[1]
    sample_root = out_root / sample_id
    raw_dir = sample_root / "raw"
    norm_dir = sample_root / "norm"

    raw_dir.mkdir(parents=True, exist_ok=True)
    norm_dir.mkdir(parents=True, exist_ok=True)

    text = ensure_text(sandbox.read_text(encoding="utf-8", errors="replace"))
    entries, warnings = split_entries(text)

    if not entries and text.strip():
        warnings.append("[main] Emergency fallback activated: full text stored as one entry.")
        entries = [{
            "timestamp_text": None,
            "author_raw": "",
            "content_raw": normalize_spaces(text),
            "links": collect_links(text),
            "sequence_index": 0,
            "hash": sha1(text),
            "source_mode": "emergency_full_text_fallback",
        }]

    raw_rows = []
    for idx, entry in enumerate(entries):
        raw_rows.append({
            "sample_id": sample_id,
            "entry_id": f"{sample_id}_E{idx:04d}",
            **entry,
        })

    norm_entries = [normalize_entry(sample_id, idx, entry) for idx, entry in enumerate(entries)]

    raw_entries_path = raw_dir / "entries.jsonl"
    norm_entries_path = norm_dir / "sample_norm.json"
    author_map_path = norm_dir / "author_map.json"
    aliases_path = norm_dir / "aliases.json"
    parse_report_path = raw_dir / "parse_report.json"
    warnings_path = raw_dir / "warnings.json"
    raw_manifest_path = raw_dir / "manifest.json"
    sample_manifest_path = sample_root / "manifest.json"

    write_jsonl(raw_entries_path, raw_rows)
    write_json(norm_entries_path, norm_entries)
    write_json(author_map_path, AUTHOR_MAP)
    write_json(aliases_path, ALIASES)
    write_json(parse_report_path, build_parse_report(sample_id, sandbox, entries, warnings))
    write_json(warnings_path, {
        "sample_id": sample_id,
        "warnings": warnings,
    })

    manifest = build_manifest(
        sample_id=sample_id,
        sandbox_path=sandbox,
        text=text,
        sample_root=sample_root,
        raw_dir=raw_dir,
        norm_dir=norm_dir,
        raw_entries_path=raw_entries_path,
        norm_entries_path=norm_entries_path,
        parse_report_path=parse_report_path,
        warnings_path=warnings_path,
        author_map_path=author_map_path,
        aliases_path=aliases_path,
        sample_manifest_path=sample_manifest_path,
        raw_manifest_path=raw_manifest_path,
        project_root=project_root,
    )

    write_json(raw_manifest_path, manifest)
    write_json(sample_manifest_path, manifest)

    print(f"Parsed {len(entries)} entries into {sample_root}")
    print(f"Manifest: {sample_manifest_path}")


if __name__ == "__main__":
    main()