# Cross-Repository Adversarial Audit — 2026-08-18

This register tracks the first process-level adversarial maintenance pass across the active DonkeyJJLove repositories.

The audit uses the shared model from [`PROCESS_GUARD.md`](PROCESS_GUARD.md): delta-first review, `_neuro` / EEG-like state dynamics, 9D semantic bridges and textual-lithography layers.

## Status legend

```text
FIXED-IN-BRANCH  — concrete repair already applied to process-upgrade-20260818
OPEN             — confirmed issue requiring a deeper follow-up
MONITOR          — no immediate patch; requires regression / observation
HYPOTHESIS       — suspected design issue, not yet confirmed
```

## Portfolio audit matrix

| Repository | Finding | Severity | Status | Repair / next gate |
|---|---|---:|---|---|
| `writeups` | ignore policy covered almost only IDE state | P3 | FIXED-IN-BRANCH | normalized source-purity rules + Process Guard |
| `glitchlab` | tracked `.env.local` and generated `*.egg-info`; missing canonical `.gitignore` | P2 | FIXED-IN-BRANCH | removed tracked local/generated state, added ignore policy |
| `glitchlab` | package metadata contained placeholder `you@example.com` | P3 | FIXED-IN-BRANCH | removed placeholder metadata |
| `chunk-chunk` | entire local `.venv` was tracked despite `.gitignore` declaring it ignored | P1 | FIXED-IN-BRANCH | removed `.venv` from branch tree; hardened ignore policy |
| `ai_platform` | `.idea` tracked; no canonical root README | P2 | FIXED-IN-BRANCH | removed IDE state, added `.gitignore`, README and process guard |
| `swarm` | duplicate `README.md` / `readme.md` case variant | P2 | FIXED-IN-BRANCH | retained canonical `README.md` only |
| `swarm` | `.gitignore` ignored `.gitignore` itself and mixed repository/source policy with local scratch rules | P3 | FIXED-IN-BRANCH | normalized ignore policy |
| `sbom` | no root `.gitignore` despite CI/CD, local analytics and test environments | P2 | FIXED-IN-BRANCH | added source-purity / local-data policy |
| `HA2D` | no explicit repository hygiene contract | P3 | FIXED-IN-BRANCH | added `.gitignore` + persistent-context Process Guard |
| `mosaic_lab_pro.py` | no explicit generated/local-state exclusion | P3 | FIXED-IN-BRANCH | added `.gitignore` + AST/Mosaic Process Guard |
| `SymulacjaKaskadySieciowej` | incomplete ignore policy for generated Python/tooling state | P3 | FIXED-IN-BRANCH | normalized `.gitignore` + simulation Process Guard |
| `hipotezy_nadawcze_LLM` | hypothesis lab had no explicit source-purity or falsification process contract | P3 | FIXED-IN-BRANCH | added `.gitignore` + hypothesis Process Guard |

## Cross-repository findings

### F-01 — Local-state leakage into source history

The strongest confirmed structural issue was not semantic but provenance-related: multiple repositories contained tracked local or generated state. This breaks the invariant:

```text
SOURCE ≠ LOCAL EXECUTION STATE
```

The branch repairs remove the confirmed tracked artifacts where the issue was directly visible and establish ignore policies to prevent recurrence.

### F-02 — Documentation identity drift

Case-variant duplicate README files and missing canonical entrypoints make repository state dependent on filesystem behavior and reader assumptions. The upgrade establishes the rule:

```text
one repository
→ one canonical README entrypoint
→ explicit deeper documents
```

### F-03 — Model / map drift

The portfolio contains several semantic integration layers (`QV9D`, HMK-9D, HA2D, GlitchLab, security write-ups). Their principal systemic risk is not that the models are rich; it is that a semantic map can become detached from executable state.

Required invariant:

```text
semantic model
↔
physical artifact / executable path
```

This remains a continuing audit target.

### F-04 — Simulation confidence boundary

Repositories using Monte Carlo, Morris, Sobol or scenario models must preserve the distinction:

```text
simulation convergence
≠
empirical truth
```

Large `N` reduces sampling noise conditional on a model. It does not remove model risk.

### F-05 — AI proposal / authority boundary

Across agentic repositories, the highest-value architectural review target remains:

```text
probabilistic proposal
→ independent policy / capability decision
→ deterministic side effect
```

A model or agent should not be the sole authority that approves its own consequential action.

## Second-pass attack plan

The next wave should target executable behavior rather than repository hygiene:

1. **CI truthfulness** — does documented CI actually execute the claimed checks?
2. **package / entrypoint coherence** — do `pyproject`, module layout and README quickstarts agree?
3. **negative testing** — malformed config, missing telemetry, permission loss, stale schemas.
4. **authority graph** — where can agent output cross into filesystem/network/deployment/policy effects?
5. **provenance continuity** — can every critical effect be reconstructed end-to-end?
6. **cross-repository coupling** — do shared concepts change compatibly across `chunk-chunk`, `glitchlab`, `ai_platform`, `HA2D`, `writeups`?
7. **generated artifact discipline** — outputs must remain reproducible and distinguishable from source.
8. **semantic falsification** — authored models must retain explicit falsifiers and alternative explanations.

## Definition of completion

The portfolio upgrade is not complete when every repository merely has a clean README. It is complete when every confirmed finding becomes:

```text
finding
→ root cause
→ invariant
→ patch
→ repeatable regression
→ documented model update
```

This file is therefore a living audit register, not a declaration that all repositories are defect-free.
