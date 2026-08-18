# writeups — AI-Native Enterprise R&D Roadmap

Enterprise role: **R&D / Enterprise Research Memory**.

`writeups` remains the human-readable evidence and research corpus. It does not become a runtime configuration repository.

## Preserve

- AI Security / Security Model Boundary / PDB research,
- observability-conditioned runtime and multi-agent control mesh architectures,
- LOCI and epistemic studies,
- probabilistic research and simulations,
- OSINT and incident reconstruction,
- Human–AI research,
- publications and reproducibility packages.

## Build

### Phase 1 — R&D taxonomy

Introduce lightweight metadata/indexing for:

```text
ResearchRecord
ArchitectureProposal
Experiment
Finding
EngineeringCandidate
Publication
```

### Phase 2 — epistemic lineage

For high-value research preserve:

```text
status
sources
evidence for/against
falsifiers
assumptions
confidence
supersedes / superseded_by
related implementation
```

### Phase 3 — Cyber-Lion R&D adapter

Expose machine-readable metadata to `ai_platform` without allowing prose to configure production directly.

Promotion path:

```text
ResearchRecord
→ engineering candidate
→ tests/simulation
→ shadow validation
→ gate
→ normative spec
```

### Phase 4 — research swarms

Formalize temporary R&D cells with separated roles:

```text
Evidence Agent
Hypothesis Agent
Falsification Agent
Simulation Agent
Methodology/Security Auditor
Human Research Owner
```

## Invariants

```text
RESEARCH CLAIM != RUNTIME AUTHORITY
SIMULATION != OBSERVATION
MODEL EXPLANATION != SELF-VALIDATION
NEGATIVE RESULT MUST BE RETAINABLE
SUPERSEDED KNOWLEDGE MUST REMAIN TRACEABLE
```

## Enterprise references

- `DonkeyJJLove/ai_platform/cyber_lion/enterprise/RND_OPERATING_MODEL.md`
- [`AI_NATIVE_ENTERPRISE_RND_WRITEUP.md`](AI_NATIVE_ENTERPRISE_RND_WRITEUP.md)
