# Process Guard — adversarial maintenance for the research ecosystem

[← Repository map](README.MD)

This document turns the project's recurring heuristics — `_neuro`, EEG-like state inspection, 9D semantic bridges, delta-first analysis and textual lithography — into a **testable repository-maintenance protocol**.

It is not a physiological EEG model and it does not claim medical measurement. `EEG/_neuro` is used here as an engineering analogy for **dynamic state observation**: baseline, delta, burst, coupling, drift, saturation and recovery.

## 1. Core invariant

Every repository change must be reconstructable as:

```text
SOURCE
→ INTENT
→ CONTEXT
→ DELTA
→ AUTHORITY
→ EXECUTION
→ EFFECT
→ OBSERVATION
→ VERDICT
```

A change that cannot be reconstructed is a provenance failure.

## 2. Process state machine

```text
OBSERVE
→ CLASSIFY
→ PROBE
→ FALSIFY
→ PATCH
→ VERIFY
→ REGRESS
→ MERGE
→ MONITOR
```

No step is allowed to jump directly from `IDEA` to `MERGE` for consequential changes.

## 3. `_neuro` / EEG-like operational model

The repository is treated as a dynamic signal rather than a static directory.

| Signal concept | Repository interpretation |
|---|---|
| baseline | known-good branch / test state / documented architecture |
| delta | commit, dependency change, config change, semantic rewrite |
| burst | sudden large change, dependency spike, generated-file flood |
| coupling | change propagating across modules / repositories |
| drift | undocumented divergence between code, docs, tests and assumptions |
| saturation | excessive complexity, warnings, ignored checks, review overload |
| recovery | rollback, patch, regression pass, restored observability |

The important variable is not "activity" but **controlled deviation from baseline**.

## 4. Textual lithography model

Treat repository text and code as layered lithography:

```text
L0  SOURCE       — raw code / data / external input
L1  SEMANTICS    — interpretation, docs, schema, contracts
L2  MANDATE      — policy, identity, capabilities, permissions
L3  EXECUTION    — runtime, CI/CD, tools, side effects
L4  OBSERVATION  — logs, metrics, receipts, test results
L5  REVISION     — falsification, patch, regression, updated invariant
```

A security or process flaw is often a **mis-registration between layers**, not an error inside one layer.

Examples:

- docs claim one entrypoint while runtime uses another,
- policy says least privilege while a tool receives ambient authority,
- `.gitignore` declares generated artifacts excluded while those artifacts are already tracked,
- tests validate local functions but not the cross-module path,
- a model proposes an action and is also allowed to authorize the same action.

## 5. 9D bridge mapping for repository maintenance

The semantic bridges are used as review lenses:

- **Plan–Pauza** — does the change have a stop/review point before consequence?
- **Rdzeń–Peryferia** — is core logic separated from generated/cache/local artifacts?
- **Cisza–Wydech** — is there a low-noise baseline and a recovery state?
- **Wioska–Miasto** — does the local module remain safe when connected to the wider system?
- **Ostrze–Cierpliwość** — is aggressive automation bounded by verification?
- **Locus–Medium–Mandat** — where does data come from, through what medium, under whose authority?
- **Human–AI** — which decisions are proposed by AI and which are independently enforced?
- **Próg–Przejście** — what threshold changes the system from allow to review/block?
- **Semantyka–Energia** — does semantic complexity create disproportionate compute/review/operational cost?

## 6. Repository health invariants

### I1 — Source purity

Do not track local execution environments, caches, IDE state or generated packaging metadata unless they are intentional fixtures.

Typical forbidden artifacts:

```text
.venv/
venv/
Lib/site-packages/
Scripts/
*.egg-info/
__pycache__/
*.pyc
.idea/
.env*
```

Exceptions must be explicit and documented.

### I2 — Single canonical entrypoint

Each repository should have one obvious starting point:

```text
README → architecture / quickstart → executable entrypoint
```

Duplicate `README.md` / `readme.md` variants or undocumented alternative entrypoints are drift indicators.

### I3 — Epistemic status

Research claims should distinguish at least:

```text
FACT / OBSERVED
DERIVED
CALIBRATED
ASSUMED
HYPOTHESIS
SPECULATION
STRESS PARAMETER
```

Simulation output is not empirical frequency.

### I4 — Delta before state

Review the change, not only the final tree.

For meaningful changes record:

- what changed,
- what invariant it touches,
- what can fail,
- how it is tested,
- how it is rolled back.

### I5 — Independent consequence gate

For agentic or generative execution:

```text
model proposes
≠
model authorizes
```

Consequential actions need an independent policy/runtime decision.

### I6 — Observable critical transitions

```text
CriticalStateChange
⇒
ReconstructableProvenance
```

A critical action without traceable source, identity, authority and effect is a process failure.

### I7 — Composition testing

Do not stop at unit-safe primitives.

Test paths:

```text
A safe
B safe
C safe

A → B → C ?
```

The path may violate an invariant even when each primitive passes locally.

## 7. Adversarial maintenance checklist

For each repository:

1. **Inventory** — entrypoints, generated artifacts, secrets surfaces, CI, tests, docs.
2. **Baseline** — identify a known-good branch/state.
3. **Noise removal** — local envs, caches, duplicate docs, stale artifacts.
4. **Boundary search** — code↔docs, model↔tool, parser↔runtime, identity↔authority, local↔distributed.
5. **Failure injection** — invalid config, missing dependency, stale schema, partial telemetry, permission loss.
6. **Patch** — smallest generalized fix, not symptom masking.
7. **Regression** — convert the finding into a repeatable check.
8. **Documentation** — update the model so the same class is visible next time.
9. **Merge only after evidence** — tests, diff review, rollback path.

## 8. Severity for process findings

```text
P0 — can cause uncontrolled critical execution / secret exposure / destructive state change
P1 — breaks provenance, authority isolation, build/release integrity or reproducibility
P2 — creates material drift, false assurance, non-reproducible tests or operational ambiguity
P3 — documentation / hygiene issue with low immediate impact but measurable maintenance cost
```

## 9. Definition of done

A process fix is complete only when:

```text
finding
→ root cause
→ missing invariant
→ patch
→ regression check
→ documented model update
```

`finding → patch → close` is insufficient when the underlying class remains reachable.

---

**Operational rule:** increase autonomy and automation only as fast as observability, provenance, controllability and rollback capacity increase with them.
