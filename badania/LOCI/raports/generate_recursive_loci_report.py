#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import annotations

import argparse
import json
import math
import re
import shutil
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional


# ============================================================
# MODELE
# ============================================================

@dataclass
class SampleBundle:
    sample_id: str
    sample_num: int
    year: Optional[int]
    result_dir: Path
    metaspace_json: Optional[Path] = None
    metaspace_png: Optional[Path] = None
    lcrt_json: Optional[Path] = None
    lcrt_png: Optional[Path] = None
    metaspace: Optional[dict] = None
    lcrt: Optional[dict] = None


# ============================================================
# I/O
# ============================================================

def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def copy_if_exists(src: Optional[Path], dst_dir: Path) -> Optional[str]:
    if src is None or not src.exists():
        return None
    dst_dir.mkdir(parents=True, exist_ok=True)
    dst = dst_dir / src.name
    shutil.copy2(src, dst)
    return dst.name


# ============================================================
# POMOCNICZE
# ============================================================

def safe_float(v, default=None):
    try:
        if v is None:
            return default
        return float(v)
    except Exception:
        return default


def safe_int(v, default=None):
    try:
        if v is None:
            return default
        return int(v)
    except Exception:
        return default


def fmt_num(v, digits=4) -> str:
    if v is None:
        return "—"
    try:
        fv = float(v)
        if math.isnan(fv):
            return "—"
        return f"{fv:.{digits}f}"
    except Exception:
        return str(v)


def fmt_generation(v) -> str:
    if v is None:
        return "unresolved"
    try:
        fv = float(v)
        if math.isnan(fv):
            return "unresolved"
        return f"G{int(fv):04d}"
    except Exception:
        return str(v)


def find_latest(paths: List[Path]) -> Optional[Path]:
    if not paths:
        return None
    return sorted(paths, key=lambda p: p.stat().st_mtime, reverse=True)[0]


def parse_sample_num(sample_id: str) -> int:
    m = re.search(r"Sample_(\d+)", sample_id)
    return int(m.group(1)) if m else 0


# ============================================================
# DETEKCJA PRAWDZIWEGO LOCI ROOT
# ============================================================

def has_real_loci_structure(root: Path) -> bool:
    if not root.exists() or not root.is_dir():
        return False

    required_dirs = ["results", "sample", "matlab", "parsers", "tests"]
    for name in required_dirs:
        if not (root / name).is_dir():
            return False

    results_dir = root / "results"
    sample_dir = root / "sample"

    result_samples = [p for p in results_dir.iterdir() if p.is_dir() and re.fullmatch(r"Sample_\d{4}", p.name)]
    sample_samples = [p for p in sample_dir.iterdir() if p.is_dir() and re.fullmatch(r"Sample_\d{4}", p.name)]

    return len(result_samples) > 0 and len(sample_samples) > 0


def infer_loci_root(start_path: Path) -> Path:
    """
    Szuka prawdziwego korzenia LOCI, a nie przypadkowego katalogu typu raports/.
    """
    current = start_path.resolve()
    if current.is_file():
        current = current.parent

    # 1) Szukaj w górę
    probe = current
    for _ in range(12):
        if has_real_loci_structure(probe):
            return probe
        parent = probe.parent
        if parent == probe:
            break
        probe = parent

    # 2) Specjalny przypadek: jeśli jesteśmy w LOCI/raports lub LOCI/reports,
    #    to sprawdź parent
    if current.name.lower() in {"raports", "reports"}:
        parent = current.parent
        if has_real_loci_structure(parent):
            return parent

    # 3) Ostatnia próba: skrypt w LOCI/raports/, więc parent parent może być LOCI
    if current.parent.name.lower() in {"raports", "reports"}:
        root = current.parent.parent
        if has_real_loci_structure(root):
            return root

    raise RuntimeError(
        f"Could not infer real LOCI root from: {start_path}\n"
        f"Expected a directory containing: results/, sample/, matlab/, parsers/, tests/ "
        f"and at least one Sample_XXXX in results/ and sample/."
    )


# ============================================================
# ODKRYWANIE DANYCH
# ============================================================

def discover_sample_years(loci_root: Path) -> Dict[str, int]:
    candidates = [
        loci_root / "reports" / "sample_years.json",
        loci_root / "raports" / "sample_years.json",
    ]

    for cfg in candidates:
        if cfg.exists():
            try:
                data = load_json(cfg)
                return {str(k): int(v) for k, v in data.items()}
            except Exception:
                return {}

    return {}


def discover_samples(loci_root: Path, sample_years: Dict[str, int]) -> List[SampleBundle]:
    results_root = loci_root / "results"
    bundles: List[SampleBundle] = []

    for entry in sorted(results_root.iterdir()):
        if not entry.is_dir():
            continue
        if entry.name.startswith("_"):
            continue
        if not re.fullmatch(r"Sample_\d{4}", entry.name):
            continue

        metaspace_json = find_latest(list(entry.glob("*_metaspace_run_*.json")))
        metaspace_png = find_latest(list(entry.glob("*_metaspace_run_*.png")))
        lcrt_json = find_latest(list(entry.glob("*_lcrt_*.json")))
        lcrt_png = find_latest(list(entry.glob("*_lcrt_*.png")))

        bundle = SampleBundle(
            sample_id=entry.name,
            sample_num=parse_sample_num(entry.name),
            year=sample_years.get(entry.name),
            result_dir=entry,
            metaspace_json=metaspace_json,
            metaspace_png=metaspace_png,
            lcrt_json=lcrt_json,
            lcrt_png=lcrt_png,
        )

        if metaspace_json and metaspace_json.exists():
            bundle.metaspace = load_json(metaspace_json)

        if lcrt_json and lcrt_json.exists():
            bundle.lcrt = load_json(lcrt_json)

        bundles.append(bundle)

    bundles.sort(key=lambda b: ((b.year if b.year is not None else 9999), b.sample_num))
    return bundles


# ============================================================
# ANALIZA
# ============================================================

def classify_network_mode(bundle: SampleBundle) -> str:
    meta = bundle.metaspace or {}
    lcrt = bundle.lcrt or {}

    generations = safe_int(meta.get("generations"), 0) or 0
    traj = safe_float(meta.get("trajectory_length"), 0.0) or 0.0

    readiness = str(lcrt.get("readiness_status", "") or "").upper()
    cog_level = str(lcrt.get("cognitive_ready_level", "") or "").lower()
    llm_level = str(lcrt.get("llm_ready_level", "") or "").lower()

    groundedness = safe_float(lcrt.get("mean_groundedness"), 0.0) or 0.0
    risk = safe_float(lcrt.get("mean_negative_hallucination_risk"), 1.0) or 1.0
    maturity = safe_float(lcrt.get("mean_maturity_score"), 0.0) or 0.0

    if cog_level == "confirmed" and llm_level in {"candidate", "confirmed"}:
        return "Structured / Modular"

    if readiness in {"COGNITIVELY_STABLE", "LLM_READY", "LLM_READY_CANDIDATE"}:
        return "Hybrid / Reorganizing"

    if generations >= 80 and traj >= 100 and groundedness < 0.22 and risk > 0.50:
        return "Exploratory / Divergent"

    if maturity >= 0.48 and groundedness >= 0.22:
        return "Hybrid / Reorganizing"

    return "Exploratory / Divergent"


def build_sample_narrative(bundle: SampleBundle) -> str:
    meta = bundle.metaspace or {}
    lcrt = bundle.lcrt or {}

    generations = safe_int(meta.get("generations"), 0) or 0
    traj = safe_float(meta.get("trajectory_length"), 0.0) or 0.0
    groundedness = safe_float(lcrt.get("mean_groundedness"), 0.0) or 0.0
    risk = safe_float(lcrt.get("mean_negative_hallucination_risk"), 1.0) or 1.0
    cog_level = str(lcrt.get("cognitive_ready_level", "") or "").lower()
    llm_level = str(lcrt.get("llm_ready_level", "") or "").lower()
    mode = classify_network_mode(bundle)

    parts = [f"{bundle.sample_id} jest klasyfikowany jako „{mode}”."]

    if bundle.year is not None:
        parts.append(f"Próbka jest osadzona na osi czasu w roku {bundle.year}.")

    if generations >= 80:
        parts.append("Długa trajektoria wskazuje na intensywną eksplorację przestrzeni semantycznej i większą dywergencję stanów.")
    else:
        parts.append("Relatywnie krótka trajektoria wskazuje na szybszą konwergencję i bardziej zwartą organizację procesu.")

    if traj >= 100:
        parts.append("Duża długość trajektorii sugeruje wysoką amplitudę przejść między stanami znaczeń.")
    else:
        parts.append("Niższa długość trajektorii sugeruje bardziej skupiony ruch w metaspace.")

    if groundedness >= 0.25:
        parts.append("Groundedness osiąga poziom wskazujący na względnie zakotwiczoną strukturę poznawczą.")
    else:
        parts.append("Groundedness pozostaje umiarkowany lub niski, więc artefakt nadal zostawia modelowi sporą swobodę interpretacji.")

    if risk <= 0.50:
        parts.append("Ryzyko halucynacyjne proxy jest umiarkowane lub obniżone.")
    else:
        parts.append("Ryzyko halucynacyjne proxy pozostaje podwyższone, co utrudnia pełne potwierdzenie gotowości LLM-safe.")

    if cog_level == "confirmed":
        parts.append("Poziom cognitive-ready jest potwierdzony.")
    elif cog_level == "candidate":
        parts.append("Poziom cognitive-ready pozostaje kandydatem.")
    else:
        parts.append("Poziom cognitive-ready nie został rozstrzygnięty.")

    if llm_level == "confirmed":
        parts.append("Poziom LLM-ready jest potwierdzony.")
    elif llm_level == "candidate":
        parts.append("Poziom LLM-ready pozostaje kandydatem.")
    else:
        parts.append("Poziom LLM-ready nie został osiągnięty.")

    return " ".join(parts)


def build_sample_analysis(bundle: SampleBundle) -> Dict:
    meta = bundle.metaspace or {}
    lcrt = bundle.lcrt or {}

    return {
        "sample_id": bundle.sample_id,
        "sample_num": bundle.sample_num,
        "year": bundle.year,
        "network_mode": classify_network_mode(bundle),
        "metaspace": {
            "generations": meta.get("generations"),
            "feature_count": meta.get("feature_count"),
            "onset_generation": meta.get("onset_generation"),
            "mean_step": meta.get("mean_step"),
            "max_step": meta.get("max_step"),
            "trajectory_length": meta.get("trajectory_length"),
        },
        "lcrt": {
            "readiness_status": lcrt.get("readiness_status"),
            "cognitive_ready_level": lcrt.get("cognitive_ready_level"),
            "llm_ready_level": lcrt.get("llm_ready_level"),
            "first_cognitive_stable_generation": lcrt.get("first_cognitive_stable_generation"),
            "first_llm_ready_generation": lcrt.get("first_llm_ready_generation"),
            "candidate_cognitive_stable_generation": lcrt.get("candidate_cognitive_stable_generation"),
            "candidate_llm_ready_generation": lcrt.get("candidate_llm_ready_generation"),
            "mean_groundedness": lcrt.get("mean_groundedness"),
            "mean_negative_hallucination_risk": lcrt.get("mean_negative_hallucination_risk"),
            "mean_interpretive_debt": lcrt.get("mean_interpretive_debt"),
            "mean_maturity_score": lcrt.get("mean_maturity_score"),
            "max_maturity_score": lcrt.get("max_maturity_score"),
        },
        "narrative": build_sample_narrative(bundle),
    }


def build_evolution_analysis(samples: List[Dict]) -> Dict:
    if not samples:
        return {
            "title": "Recursive Evolution Analysis",
            "narrative": "Nie wykryto żadnych próbek z gotowymi wynikami metaspace i LCRT.",
            "phases": [],
        }

    phases = []
    for s in samples:
        phases.append({
            "sample_id": s["sample_id"],
            "year": s.get("year"),
            "network_mode": s["network_mode"],
            "cognitive_ready_level": s["lcrt"]["cognitive_ready_level"],
            "llm_ready_level": s["lcrt"]["llm_ready_level"],
            "mean_maturity_score": s["lcrt"]["mean_maturity_score"],
            "mean_groundedness": s["lcrt"]["mean_groundedness"],
            "trajectory_length": s["metaspace"]["trajectory_length"],
        })

    first = samples[0]
    last = samples[-1]

    narrative = (
        f"Analiza rekurencyjna wskazuje przejście od wcześniejszych próbek o charakterze "
        f"„{first['network_mode']}” do późniejszych próbek bliższych trybowi „{last['network_mode']}”. "
        f"Proces nie dotyczy wyłącznie pojedynczych artefaktów, lecz samej ewolucji heurystycznej w czasie. "
        f"Kolejne sample są traktowane jako etapy przebudowy połączeń funkcjonalnych: od większej dystrybucji, "
        f"entropii i rozproszenia ku większej selektywności, modułowości i stabilizacji rdzenia poznawczego."
    )

    return {
        "title": "Recursive Evolution Analysis",
        "narrative": narrative,
        "phases": phases,
    }


# ============================================================
# HTML
# ============================================================

def build_html(report: Dict) -> str:
    generated_at = report["generated_at"]
    samples = report["samples"]
    evolution = report["evolution"]

    cards_html = []
    for s in samples:
        sid = s["sample_id"]
        year = s.get("year")
        mode = s["network_mode"]
        meta = s["metaspace"]
        lcrt = s["lcrt"]
        assets = s["assets"]

        year_html = f"<div class='pill'>Year: {year}</div>" if year is not None else ""

        metaspace_img = ""
        if assets.get("metaspace_png"):
            metaspace_img = f"""
            <div class="img-card">
              <div class="img-title">Metaspace</div>
              <img src="assets/{assets['metaspace_png']}" alt="{sid} metaspace">
            </div>
            """

        lcrt_img = ""
        if assets.get("lcrt_png"):
            lcrt_img = f"""
            <div class="img-card">
              <div class="img-title">LCRT</div>
              <img src="assets/{assets['lcrt_png']}" alt="{sid} lcrt">
            </div>
            """

        cards_html.append(f"""
        <section class="card">
          <div class="card-head">
            <div>
              <h2>{sid}</h2>
              <div class="subtitle">{mode}</div>
            </div>
            <div class="pill-row">
              {year_html}
              <div class="pill">Generations: {meta.get('generations', '—')}</div>
              <div class="pill">Features: {meta.get('feature_count', '—')}</div>
              <div class="pill">Cognitive: {lcrt.get('cognitive_ready_level', '—')}</div>
              <div class="pill">LLM: {lcrt.get('llm_ready_level', '—')}</div>
            </div>
          </div>

          <div class="metric-grid">
            <div class="metric"><span>Onset</span><strong>{fmt_generation(meta.get('onset_generation'))}</strong></div>
            <div class="metric"><span>Trajectory</span><strong>{fmt_num(meta.get('trajectory_length'))}</strong></div>
            <div class="metric"><span>Mean step</span><strong>{fmt_num(meta.get('mean_step'))}</strong></div>
            <div class="metric"><span>Groundedness</span><strong>{fmt_num(lcrt.get('mean_groundedness'))}</strong></div>
            <div class="metric"><span>Hallucination risk</span><strong>{fmt_num(lcrt.get('mean_negative_hallucination_risk'))}</strong></div>
            <div class="metric"><span>Maturity</span><strong>{fmt_num(lcrt.get('mean_maturity_score'))}</strong></div>
          </div>

          <div class="narrative">
            <h3>Analysis</h3>
            <p>{s['narrative']}</p>
          </div>

          <div class="img-grid">
            {metaspace_img}
            {lcrt_img}
          </div>
        </section>
        """)

    phases_html = []
    for p in evolution["phases"]:
        phases_html.append(f"""
        <tr>
          <td>{p['sample_id']}</td>
          <td>{p.get('year', '—') if p.get('year') is not None else '—'}</td>
          <td>{p['network_mode']}</td>
          <td>{p['cognitive_ready_level'] or '—'}</td>
          <td>{p['llm_ready_level'] or '—'}</td>
          <td>{fmt_num(p['mean_maturity_score'])}</td>
          <td>{fmt_num(p['mean_groundedness'])}</td>
          <td>{fmt_num(p['trajectory_length'])}</td>
        </tr>
        """)

    return f"""<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="utf-8">
  <title>LOCI Static Recursive Report</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    :root {{
      --bg: #f4f4f6;
      --card: #ffffff;
      --ink: #1f2430;
      --muted: #5f6675;
      --line: #d8dce3;
      --blue: #275dad;
      --violet: #6a1b9a;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      background: var(--bg);
      color: var(--ink);
      font-family: Arial, Helvetica, sans-serif;
      line-height: 1.55;
    }}
    .wrap {{
      width: min(1320px, 96%);
      margin: 0 auto;
      padding: 28px 0 56px;
    }}
    .hero, .evolution, .card {{
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 18px;
      box-shadow: 0 6px 24px rgba(0,0,0,0.05);
    }}
    .hero {{
      padding: 28px 32px;
      margin-bottom: 24px;
      background: linear-gradient(135deg, #ffffff, #edf3ff);
    }}
    h1 {{
      margin: 0 0 10px 0;
      font-size: 42px;
      line-height: 1.1;
    }}
    .lead {{
      max-width: 1050px;
      font-size: 18px;
      color: var(--muted);
    }}
    .stamp {{
      margin-top: 16px;
      font-size: 14px;
      color: var(--muted);
    }}
    .evolution {{
      padding: 24px 28px;
      margin-bottom: 24px;
    }}
    .evolution h2 {{
      margin-top: 0;
      font-size: 30px;
    }}
    .phase-table {{
      width: 100%;
      border-collapse: collapse;
      margin-top: 16px;
      font-size: 14px;
    }}
    .phase-table th, .phase-table td {{
      text-align: left;
      padding: 10px 8px;
      border-bottom: 1px solid var(--line);
      vertical-align: top;
    }}
    .card {{
      padding: 24px 28px;
      margin-bottom: 22px;
    }}
    .card-head {{
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 18px;
      flex-wrap: wrap;
    }}
    .card h2 {{
      margin: 0;
      font-size: 34px;
    }}
    .subtitle {{
      margin-top: 6px;
      font-size: 22px;
      color: var(--violet);
      font-style: italic;
    }}
    .pill-row {{
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      justify-content: flex-end;
    }}
    .pill {{
      background: #eef3ff;
      color: #1f4d93;
      border: 1px solid #d8e3ff;
      border-radius: 999px;
      padding: 8px 12px;
      font-size: 13px;
      font-weight: bold;
    }}
    .metric-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 12px;
      margin-top: 18px;
    }}
    .metric {{
      background: #fafbfc;
      border: 1px solid var(--line);
      border-radius: 14px;
      padding: 12px 14px;
    }}
    .metric span {{
      display: block;
      font-size: 13px;
      color: var(--muted);
      margin-bottom: 6px;
    }}
    .metric strong {{
      font-size: 20px;
    }}
    .narrative {{
      margin-top: 18px;
    }}
    .narrative h3 {{
      margin-bottom: 8px;
    }}
    .img-grid {{
      margin-top: 18px;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(360px, 1fr));
      gap: 20px;
    }}
    .img-card {{
      background: #fafbfc;
      border: 1px solid var(--line);
      border-radius: 14px;
      padding: 12px;
    }}
    .img-title {{
      margin-bottom: 10px;
      font-weight: bold;
      color: var(--muted);
    }}
    .img-card img {{
      width: 100%;
      height: auto;
      display: block;
      border-radius: 10px;
      border: 1px solid var(--line);
      background: white;
    }}
    .footer {{
      margin-top: 30px;
      text-align: center;
      color: var(--muted);
      font-size: 13px;
    }}
  </style>
</head>
<body>
  <div class="wrap">
    <section class="hero">
      <h1>LOCI Static Recursive Report</h1>
      <p class="lead">
        Statyczny raport budowany na podstawie już istniejących wyników zapisanych w katalogu
        <code>LOCI/results/</code>. Python zbiera gotowe analizy, kopiuje niezbędne media do katalogu raportu
        i generuje jedną stronę HTML, która wyłącznie prezentuje wcześniej policzone metryki metaspace i LCRT.
      </p>
      <div class="stamp">Generated at: {generated_at}</div>
    </section>

    <section class="evolution">
      <h2>{evolution["title"]}</h2>
      <p>{evolution["narrative"]}</p>

      <table class="phase-table">
        <thead>
          <tr>
            <th>Sample</th>
            <th>Year</th>
            <th>Network mode</th>
            <th>Cognitive</th>
            <th>LLM</th>
            <th>Maturity</th>
            <th>Groundedness</th>
            <th>Trajectory</th>
          </tr>
        </thead>
        <tbody>
          {''.join(phases_html)}
        </tbody>
      </table>
    </section>

    {''.join(cards_html)}

    <div class="footer">
      LOCI static recursive report · generated from precomputed results only
    </div>
  </div>
</body>
</html>
"""


# ============================================================
# MAIN
# ============================================================

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--loci-root",
        default=None,
        help="Path to real LOCI root. If omitted, inferred robustly."
    )
    args = parser.parse_args()

    if args.loci_root:
        loci_root = infer_loci_root(Path(args.loci_root).resolve())
    else:
        loci_root = infer_loci_root(Path(__file__).resolve())

    results_root = loci_root / "results"
    sample_years = discover_sample_years(loci_root)
    bundles = discover_samples(loci_root, sample_years)

    timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    out_dir = results_root / "_reports" / f"static_recursive_report_{timestamp}"
    assets_dir = out_dir / "assets"

    out_dir.mkdir(parents=True, exist_ok=True)
    assets_dir.mkdir(parents=True, exist_ok=True)

    sample_rows = []
    for bundle in bundles:
        assets = {
            "metaspace_png": copy_if_exists(bundle.metaspace_png, assets_dir),
            "lcrt_png": copy_if_exists(bundle.lcrt_png, assets_dir),
            "metaspace_json": copy_if_exists(bundle.metaspace_json, assets_dir),
            "lcrt_json": copy_if_exists(bundle.lcrt_json, assets_dir),
        }

        analysis = build_sample_analysis(bundle)
        analysis["assets"] = assets
        sample_rows.append(analysis)

    evolution = build_evolution_analysis(sample_rows)

    summary = {
        "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "loci_root": str(loci_root),
        "results_root": str(results_root),
        "report_dir": str(out_dir),
        "samples_count": len(sample_rows),
        "samples": sample_rows,
        "evolution": evolution,
    }

    write_json(out_dir / "summary.json", summary)
    write_text(out_dir / "analysis.txt", evolution["narrative"])
    write_text(out_dir / "index.html", build_html(summary))

    print(f"[OK] LOCI root: {loci_root}")
    print(f"[OK] Results root: {results_root}")
    print(f"[OK] Samples found: {len(sample_rows)}")
    print(f"[OK] Static report created: {out_dir}")
    print(f"[OK] HTML: {out_dir / 'index.html'}")
    print(f"[OK] Summary: {out_dir / 'summary.json'}")


if __name__ == "__main__":
    main()