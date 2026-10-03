"""One-command resumable confirmatory study of the frozen author heuristic.

This is not a pilot runner. It performs only treatment-blind infrastructure preflight
before sealing the full confirmatory design, then runs/resumes the same manifest until
all prespecified trials are complete. Production LION on 8772 is never restarted or
modified.
"""
from __future__ import annotations

import argparse
from datetime import datetime
import json
from pathlib import Path
import sys
import zipfile

from .analysis import analyse
from .design import load_config, prepare
from .engine import execute_study, audit_study
from .lion_setup import create_profile
from .research_runtime import ensure_research_endpoint, stop_research_endpoint, RuntimeErrorSafe
from .util import ASSETS, ROOT, digest, read_json, utc, write_json

STATE = ROOT / "STUDY_STATE.json"


def _run_dir() -> Path:
    root = ROOT / "runs"
    root.mkdir(exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    p = root / f"study_{stamp}"
    i = 1
    while p.exists():
        p = root / f"study_{stamp}_{i:02d}"
        i += 1
    p.mkdir(parents=True)
    return p


def _rel(p: Path) -> str:
    try:
        return str(p.resolve().relative_to(ROOT.resolve())).replace("\\", "/")
    except ValueError:
        return str(p.resolve())


def _resolve(s: str) -> Path:
    p = Path(s)
    return p if p.is_absolute() else ROOT / p


def _save_state(**fields) -> dict:
    current = read_json(STATE) if STATE.exists() else {}
    current.update(fields)
    current["updated_utc"] = utc()
    write_json(STATE, current)
    return current


def _new_state(run_dir: Path, study: Path, profile: Path, manifest: dict) -> dict:
    registration = {
        "created_utc": utc(),
        "kind": "LOCAL_PROSPECTIVE_SEAL",
        "statement": "New prospective schedule sealed before its treatment responses; earlier diagnostic/pilot data exist and are disclosed, not pooled as confirmatory data.",
        "manifest_hash": manifest["manifest_hash"],
        "primary_treatment": manifest["config"]["primary_treatment"],
        "primary_control": manifest["config"]["primary_control"],
        "planned_independent_blocks": manifest["config"]["clusters"],
        "planned_trials": manifest["plan"]["trials"],
        "primary_endpoint": "safe_success",
        "decision": manifest["config"]["decision"],
        "no_optional_stopping": True,
        "generation_seed_start": manifest["config"]["seed_start"],
        "output_budget_outcome_policy": manifest["config"].get("protocol",{}).get("output_budget_outcome_policy"),
        "known_prior_data": "Prior pilots and the aborted first strong_control lineage trial in HCL_RUNTIME_FAILURE_7874acc6.zip. New schedule is 30000..30255, not 20000..20255.",
        "resume_rule": "Only incomplete sealed assignments may be resumed. Completed semantic outcomes are never rerun.",
        "infrastructure_retry_rule": "Provider-layer failures are quarantined and the same sealed trial/model seed is retried on a later invocation; protocol/task failures are outcomes and are never retried.",
    }
    registration["registration_hash"] = digest(registration)
    write_json(run_dir / "PREREGISTRATION.json", registration)
    return _save_state(
        schema=1,
        status="ACTIVE",
        created_utc=registration["created_utc"],
        run_dir=_rel(run_dir),
        study=_rel(study),
        profile=_rel(profile),
        manifest_hash=manifest["manifest_hash"],
        registration_hash=registration["registration_hash"],
        planned_trials=manifest["plan"]["trials"],
        planned_clusters=manifest["config"]["clusters"],
        last_error=None,
    )


def _load_active() -> tuple[dict, Path] | tuple[None, None]:
    if not STATE.exists():
        return None, None
    st = read_json(STATE)
    if st.get("status") == "COMPLETE":
        return st, _resolve(st["study"])
    if st.get("status") == "INVALID_INSTRUMENT":
        raise RuntimeError("Existing sealed study is marked INVALID_INSTRUMENT by the preregistered transport circuit breaker. Preserve it for audit and start this software version in a clean directory; do not reinterpret it as a heuristic result.")
    study = _resolve(st.get("study", ""))
    if not (study / "manifest.json").exists():
        raise RuntimeError("STUDY_STATE.json points to a missing sealed study. Refusing to invent a replacement; use --new-study only after preserving the old state file.")
    return st, study


def _archive_state() -> None:
    if not STATE.exists():
        return
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    dst = ROOT / f"STUDY_STATE_ARCHIVE_{stamp}.json"
    STATE.replace(dst)


def _progress(study: Path) -> dict:
    manifest = read_json(study / "manifest.json")
    scheduled = len(read_json(study / "schedule.json"))
    trials = len(list((study / "trials").glob("*.json")))
    infra = len(list((study / "infrastructure_failures").glob("*.json"))) if (study / "infrastructure_failures").exists() else 0
    return {"manifest_hash": manifest["manifest_hash"], "completed_trials": trials, "scheduled_trials": scheduled,
            "remaining_trials": scheduled - trials, "quarantined_infrastructure_attempts": infra}


def bundle_preflight_failure(run_dir: Path, message: str) -> Path:
    """Package only this invocation's trace; no missions, secrets or other runs."""
    bundle=run_dir/"transport_failure.zip"
    receipt={"status":"PREFLIGHT_FAILED","error":message,"created_utc":utc(),
             "scope":"HTTP payload evidence; not a heuristic outcome",
             "trace_directory":"transport_http"}
    write_json(run_dir/"failure_receipt.json",receipt)
    members=[run_dir/"failure_receipt.json",run_dir/"profile.preflight.json"]
    trace=run_dir/"transport_http"
    if trace.exists():
        members.extend(sorted(x for x in trace.rglob("*") if x.is_file() and not x.is_symlink()))
    with zipfile.ZipFile(bundle,"x",zipfile.ZIP_DEFLATED) as z:
        for member in members:
            if member.is_file() and not member.is_symlink():
                z.write(member,member.relative_to(run_dir).as_posix())
    return bundle


def run_study(prod_port: int = 8772, research_port: int = 8773, context: int = 8192,
              keep_server: bool = False, new_study: bool = False) -> dict:
    if new_study:
        _archive_state()

    st, existing_study = _load_active()
    if st and st.get("status") == "COMPLETE":
        result = {"status": "ALREADY_COMPLETE", "study": str(existing_study),
                  "report": st.get("report"), "summary": st.get("summary"), "verdict": st.get("verdict")}
        print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
        return result

    lease = None
    try:
        print("[1/7] Research endpoint preflight (production 8772 remains untouched)...", flush=True)
        lease = ensure_research_endpoint(prod_port, research_port, context)
        print(f"      research={lease.url} pid={lease.pid} started_here={lease.started_here}", flush=True)
        print(f"      production=http://127.0.0.1:{prod_port}/v1 untouched", flush=True)

        if existing_study is None:
            run_dir = _run_dir()
            profile = run_dir / "profile.json"
            template = ASSETS / "configs" / "study.json"
            print("[2/7] Treatment-blind transport/context qualification...", flush=True)
            print(f"      raw HTTP evidence: {run_dir / 'transport_http'}",flush=True)
            preflight = create_profile(template, profile, lease.url, test_inference=True)
            if preflight.get("status") != "READY_FOR_STUDY":
                raise RuntimeError("Preflight did not qualify the full study: " + str(preflight.get("status")))
            print(f"      {preflight['status']}; mode={preflight.get('transport_qualification',{}).get('selected_mode')}", flush=True)

            study = run_dir / "study"
            print("[3/7] Prospectively sealing the full randomized paired study...", flush=True)
            manifest = prepare(load_config(profile), study, accepted=True)
            st = _new_state(run_dir, study, profile, manifest)
            print(f"      manifest={manifest['manifest_hash']}", flush=True)
            print(f"      blocks={manifest['config']['clusters']} trials={manifest['plan']['trials']}", flush=True)
            print(f"      preregistration={st['registration_hash']}", flush=True)
        else:
            study = existing_study
            prog = _progress(study)
            print("[2/7] Resuming the existing sealed study; no new randomization or thresholds...", flush=True)
            print(f"      manifest={prog['manifest_hash']}", flush=True)
            print(f"      completed={prog['completed_trials']}/{prog['scheduled_trials']} remaining={prog['remaining_trials']}", flush=True)
            print("[3/7] Prospective seal already exists; unchanged.", flush=True)

        print("[4/7] Running/resuming live heuristic comparison...", flush=True)
        print("      output-cap exhaustion is a retained GENERATION_LIMIT outcome; no retry, no analysis-to-action conversion", flush=True)
        run_info = execute_study(study, confirm=True)
        prog = _progress(study)
        _save_state(status="ACTIVE", completed_trials=prog["completed_trials"], remaining_trials=prog["remaining_trials"],
                    quarantined_infrastructure_attempts=prog["quarantined_infrastructure_attempts"], last_error=None)

        if run_info.get("provider_errors_this_invocation", 0):
            result = {"status": "PAUSED_INFRASTRUCTURE", "study": str(study), **prog,
                      "message": "A provider-layer failure was quarantined. Run RUN_STUDY.cmd again to resume the same sealed trial; no semantic outcome was retried."}
            _save_state(status="PAUSED_INFRASTRUCTURE", last_error=result["message"],
                        completed_trials=prog["completed_trials"], remaining_trials=prog["remaining_trials"])
            print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
            return result

        if prog["remaining_trials"]:
            # Normally only reachable after a controlled interruption path.
            result = {"status": "PAUSED_INCOMPLETE", "study": str(study), **prog,
                      "message": "Study remains incomplete. Run RUN_STUDY.cmd again; it will resume the same manifest."}
            _save_state(status="PAUSED_INCOMPLETE", last_error=result["message"])
            print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
            return result

        print("[5/7] Deterministic replay audit...", flush=True)
        audit = audit_study(study)
        if audit["status"] != "PASS" or not audit["fully_complete"]:
            raise RuntimeError("Final deterministic audit failed: " + json.dumps(audit, ensure_ascii=False)[:2000])
        print(f"      audit=PASS checked={audit['checked']}/{audit['scheduled']}", flush=True)

        print("[6/7] Prespecified statistical analysis...", flush=True)
        summary = analyse(study)
        verdict = summary["verdict"]
        print(json.dumps({"verdict": verdict, "primary_contrasts": summary.get("primary_contrasts")}, ensure_ascii=False, indent=2), flush=True)

        print("[7/7] Freezing final result pointers...", flush=True)
        final = _save_state(status="COMPLETE", completed_utc=utc(), completed_trials=prog["scheduled_trials"], remaining_trials=0,
                            report=_rel(study / "report.html"), summary=_rel(study / "summary.json"),
                            verdict=verdict, audit=_rel(study / "audit.json"), last_error=None)
        result = {"status": "COMPLETE", "study": str(study), "report": str(study / "report.html"),
                  "summary": str(study / "summary.json"), "audit": str(study / "audit.json"),
                  "verdict": verdict, "state": str(STATE), "registration_hash": final.get("registration_hash")}
        print("\n=== FULL STUDY COMPLETE ===", flush=True)
        print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
        return result

    except KeyboardInterrupt:
        _save_state(status="PAUSED_USER", last_error="Interrupted by user; rerun RUN_STUDY.cmd to resume the same sealed manifest.")
        print("\nInterrupted. The sealed study was not replaced. RUN_STUDY.cmd will resume it.", file=sys.stderr, flush=True)
        raise
    except Exception as exc:
        if existing_study is None and "run_dir" in locals() and not (run_dir/"study"/"manifest.json").exists():
            try:
                bundle=bundle_preflight_failure(run_dir,str(exc))
                print(f"Evidence bundle (no rerun needed): {bundle}",file=sys.stderr,flush=True)
            except Exception as archive_error:
                print(f"Could not package evidence: {archive_error}. Raw files remain in {run_dir}.",file=sys.stderr,flush=True)
        if STATE.exists():
            if str(exc).startswith(("TRANSPORT_CIRCUIT_BREAKER:","TRANSPORT_RUNTIME_FAILURE:")):
                _save_state(status="INVALID_INSTRUMENT", last_error=str(exc)[:4000])
            else:
                _save_state(status="PAUSED_ERROR", last_error=str(exc)[:4000])
        raise
    finally:
        if lease and lease.started_here and not keep_server:
            print("\nStopping only the isolated research endpoint started by this invocation...", flush=True)
            stop_research_endpoint(lease)
            print("Research endpoint stopped. Production LION was not touched.", flush=True)


def status() -> dict:
    if not STATE.exists():
        return {"status": "NOT_STARTED", "state": str(STATE)}
    st = read_json(STATE)
    study = _resolve(st["study"]) if st.get("study") else None
    if study and (study / "manifest.json").exists():
        st = {**st, **_progress(study)}
    return st


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--prod-port", type=int, default=8772)
    p.add_argument("--research-port", type=int, default=8773)
    p.add_argument("--context", type=int, default=8192)
    p.add_argument("--keep-server", action="store_true")
    p.add_argument("--new-study", action="store_true", help="Archive the existing state pointer and start a new prospectively sealed study. Never use this to replace an inconvenient result.")
    p.add_argument("--status", action="store_true")
    a = p.parse_args(argv)
    if a.status:
        print(json.dumps(status(), ensure_ascii=False, indent=2))
        return 0
    try:
        r = run_study(a.prod_port, a.research_port, a.context, a.keep_server, a.new_study)
        return 0 if r.get("status") in {"COMPLETE", "ALREADY_COMPLETE", "PAUSED_INFRASTRUCTURE", "PAUSED_INCOMPLETE"} else 1
    except KeyboardInterrupt:
        return 130
    except (ValueError, FileNotFoundError, OSError, RuntimeErrorSafe, RuntimeError) as exc:
        print("ERROR: " + str(exc), file=sys.stderr)
        print("The full-study manifest, if already sealed, was not replaced. Production LION was not restarted or modified.", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
