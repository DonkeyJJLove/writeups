# DonkeyJJLove — AI Security · Agentic Systems · Probabilistic Research

> **Profile README template and portfolio index.**  
> This file is the canonical profile description for the research ecosystem. GitHub will render it directly on the account page after a special repository named `DonkeyJJLove/DonkeyJJLove` is created and this content is copied to its `README.md`.
>
> **Detailed professional / research profile:** [`PROFILE_ABOUT.md`](PROFILE_ABOUT.md)

I build and research systems at the boundary between **cybersecurity, AI/agentic security, agentic execution, distributed systems, observability, software analysis, probabilistic modeling and Human–AI interaction**. My work is centered on one recurring question:

> **How do we let probabilistic AI act faster and more autonomously without giving it uncontrolled authority over deterministic systems?**

The repositories below are not isolated demos. Together they form an experimental stack: from offensive-security and vulnerability research, semantic protocols and program analysis, through agent runtime and distributed infrastructure, to provenance, security gates, Monte Carlo falsification and system-level resilience.

---

## Current research focus

### Security is a property of the execution path

A recurring result across the current AI-security work is that local correctness does not imply global safety:

```text
A = allowed
B = allowed
C = allowed

A → B → C ≠ automatically safe
```

The current security line therefore moves the unit of analysis from the isolated component to the complete trajectory:

```text
source
→ context
→ model / agent
→ authority
→ tool selection
→ deterministic side effect
→ state change
→ next action
```

The central architectural principle is:

```text
Probabilistic Intelligence
inside
Observable + Provenance-Aware + Capability-Bounded
+ Path-Aware + Deterministically Enforced Execution Envelope
```

Start here: [`writeups/ai_security_model_boundary_strategy_writeup.md`](https://github.com/DonkeyJJLove/writeups/blob/master/ai_security_model_boundary_strategy_writeup.md).

---

## Core competencies

### Cybersecurity / Offensive Research

- application and infrastructure security,
- pentesting and vulnerability research,
- bug-bounty methodology and exploitability reconstruction,
- web / API security,
- Windows / Linux security,
- Active Directory and privileged-access architectures,
- network security and segmentation,
- incident analysis and defensive validation.

### AI / Agentic Security

- agentic threat modeling and trust-boundary analysis,
- execution-path security and compositional risk,
- prompt / context / memory / tool-use security,
- provenance and delegated-authority tracking,
- deterministic enforcement around probabilistic agents,
- runtime observability and containment,
- RED / BLUE / PURPLE model-expansion workflows.

### Security Architecture & DevSecOps

- Zero Trust and least-privilege design,
- capability-oriented security,
- SBOM / provenance / identity-over-time,
- policy gates and fail-closed execution,
- SAST normalization and remediation pipelines,
- CI/CD security controls,
- Kubernetes, Istio, RBAC and network-policy architectures,
- Elastic/Kibana, Splunk, Prometheus, Grafana and Jaeger as observability layers.

### Distributed / Multi-Agent Systems

- agent orchestration and swarm architectures,
- Kubernetes-based distributed execution,
- MQTT / API / telemetry pipelines,
- multi-agent control planes,
- cross-domain identity and authority,
- blast-radius and cascade containment.

### Probabilistic & Systems Research

- Monte Carlo simulation,
- heavy-tail and tail-risk analysis,
- Pareto / multi-objective strategy comparison,
- counterfactual falsification and stress testing,
- Morris and Sobol sensitivity analysis,
- system dynamics and scenario modeling,
- model-risk separation from sampling error.

### Program Analysis & Research Tooling

- Python AST analysis,
- graph and topology-based code representation,
- delta-first change analysis,
- invariant-driven validation,
- A* / graph algorithms,
- executable research pipelines and reproducible artifacts.

### Human–AI / Epistemic Systems

- context protocols,
- semantic compression and state representation,
- Human–AI control loops,
- epistemic status and falsification,
- semantic drift / context provenance,
- experimental symbolic interfaces and microcode-like control languages,
- EEG/_neuro-inspired state-dynamics models used as analytical process structures rather than physiological measurement.

---

## Research constructs developed in the repositories

These are **authored research constructs, architectural models or hypotheses**. Their presence here does not mean that each one is an established external scientific standard.

### Security Model Boundary — SMB / SMBE

A model for reachable execution trajectories that can remain locally policy-compliant while violating a global security invariant. The associated strategy was subjected to falsification, a 1,000,000-world Monte Carlo experiment across 36 strategies, counterfactual testing and adversarial stress exploration.

Repository: [`writeups`](https://github.com/DonkeyJJLove/writeups)

### Probabilistic–Deterministic Boundary — PDB

The control boundary where probabilistic interpretation / planning becomes a deterministic side effect such as `WRITE`, `EXECUTE`, `GRANT`, `SEND`, `DEPLOY` or `CHANGE_POLICY`.

### Security Observability Kernel / Security Boundary Buffer / Combinatorial Execution Control

A family of architectural constructs for reconstructing causal authority chains, evaluating actions in the context of execution history and enforcing security invariants before consequential state changes.

### LLM Trust Boundary Collapse — LTBC

A threat-modeling line focused on collapsing boundaries between **DATA / INSTRUCTION / CONTEXT / AUTHORITY / MEMORY / DECISION / ACTION** in LLM and agent workflows.

Repository: [`writeups`](https://github.com/DonkeyJJLove/writeups)

### HMK-9D / `chunk–chunk→`

An experimental protocol for representing Human–AI processes as sequences of local transitions with explicit relational state, semantic bridges, thresholds and 9D compression coordinates.

Repository: [`chunk-chunk`](https://github.com/DonkeyJJLove/chunk-chunk)

### Δ-first software analysis / AST ↔ Mosaic

A software-engineering model in which change, rather than snapshot state, is the primary object. GlitchLab combines AST analysis, Δ tokens, fingerprints, invariants, SAST normalization and controlled repair proposals.

Repository: [`glitchlab`](https://github.com/DonkeyJJLove/glitchlab)

### AID + SBOM as identity-over-time

A DevSecOps research line treating SBOM not only as an inventory but as a repeatable state observation, with delta, provenance, risk gates and an application identity (`AID`) that persists across CI/CD observations.

Repository: [`sbom`](https://github.com/DonkeyJJLove/sbom)

### HA2D / persistent context systems

An experimental Human–AI architecture built around persistent context, symbolic state transitions, revision tracking, ASCII HUD concepts and semantic evolution.

Repository: [`HA2D`](https://github.com/DonkeyJJLove/HA2D)

### QV9D / LAT_GLX project mosaic

An integration layer that maps heterogeneous repositories, artifacts and responsibilities into a shared semantic/operational coordinate system and treats `ai_platform` as the orchestration layer over the broader research mosaic.

Repository: [`ai_platform`](https://github.com/DonkeyJJLove/ai_platform)

---

## Repository map

| Repository | Role in the portfolio | Main areas |
|---|---|---|
| [`writeups`](https://github.com/DonkeyJJLove/writeups) | **Research corpus / security architecture / publications** | AI Security, SMB, LTBC, observability, LOCI, Human–AI, cyber research |
| [`glitchlab`](https://github.com/DonkeyJJLove/glitchlab) | **Generative software engineering & analysis laboratory** | AST, Δ algebra, invariants, SAST, self-healing, observability |
| [`chunk-chunk`](https://github.com/DonkeyJJLove/chunk-chunk) | **Semantic / process protocol laboratory** | HMK-9D, context, microcode, Human–AI trajectories |
| [`ai_platform`](https://github.com/DonkeyJJLove/ai_platform) | **Integration and orchestration layer** | QV9D, project mosaic, governance, cross-repository mapping |
| [`sbom`](https://github.com/DonkeyJJLove/sbom) | **DevSecOps / software provenance laboratory** | SBOM, AID, CI/CD, Elastic/Splunk, gates, delta |
| [`swarm`](https://github.com/DonkeyJJLove/swarm) | **Distributed / swarm execution laboratory** | Kubernetes, drones, MQTT, Istio, telemetry, AI service, RBAC |
| [`HA2D`](https://github.com/DonkeyJJLove/HA2D) | **Persistent Human–AI context experiment** | PCE, memory/context, revision, symbolic state, HUD |
| [`mosaic_lab_pro.py`](https://github.com/DonkeyJJLove/mosaic_lab_pro.py) | **Program structure visualization laboratory** | Python AST, graphs, A*, 3D honeycomb, abstraction λ |
| [`SymulacjaKaskadySieciowej`](https://github.com/DonkeyJJLove/SymulacjaKaskadySieciowej) | **System dynamics / scenario simulation laboratory** | Monte Carlo, Morris, Sobol, cascades, phase transitions |
| [`hipotezy_nadawcze_LLM`](https://github.com/DonkeyJJLove/hipotezy_nadawcze_LLM) | **Small falsification laboratory for LLM communication hypotheses** | text→token hypothesis, epistemic testing |

---

## Selected technical evidence

### AI-Driven security strategy

The current AI-security research compares multiple security philosophies instead of assuming one architecture is correct. The main experiment evaluates **36 strategies on 1,000,000 common random worlds**, then applies convergence checks, counterfactual falsification, stress tests and adversarial search. The reported numbers are explicitly treated as **model outputs, not empirical incident frequencies**.

- [Security Model Boundary strategy write-up](https://github.com/DonkeyJJLove/writeups/blob/master/ai_security_model_boundary_strategy_writeup.md)
- [Full research index](https://github.com/DonkeyJJLove/writeups/tree/master/badania)
- [Research package](https://github.com/DonkeyJJLove/writeups/blob/master/AI_Driven_Security_Research_Package_2026-08-18.zip)

### Agent runtime / multi-agent control

- [Observability-Conditioned Reference Monitor](https://github.com/DonkeyJJLove/writeups/blob/master/OBSERVABILITY_CONDITIONED_REFERENCE_MONITOR_LINUX_OPENAI.md)
- [Linux Multi-Agent Control Mesh](https://github.com/DonkeyJJLove/writeups/blob/master/LINUX_MULTI_AGENT_CONTROL_MESH_REFERENCE_ARCHITECTURE.md)

### Reproducible simulation

[`SymulacjaKaskadySieciowej`](https://github.com/DonkeyJJLove/SymulacjaKaskadySieciowej) packages a falsifiable system-dynamics model with deterministic runs, Monte Carlo, Morris/Sobol global sensitivity analysis and phase-transition exploration.

### DevSecOps provenance

[`sbom`](https://github.com/DonkeyJJLove/sbom) implements the research loop:

```text
measurement
→ identity
→ SBOM / scan
→ delta
→ threshold
→ gate
→ analytical memory
```

### Distributed systems

[`swarm`](https://github.com/DonkeyJJLove/swarm) combines simulated drone telemetry, MQTT/UDP aggregation, APIs, PostgreSQL, Kubernetes, Istio, Prometheus/Grafana/Jaeger and RBAC/network policies with an AI service.

---

## Research discipline

I intentionally separate:

```text
FACT / OBSERVED
DERIVED
CALIBRATED
ASSUMED
HYPOTHESIS
SPECULATION
STRESS PARAMETER
```

A large Monte Carlo run can reduce **sampling noise inside a model**. It cannot remove **model risk**, repair weak priors or turn calibration parameters into empirical frequencies.

Likewise, an architectural analogy or convergence between independent systems is not automatically evidence of causal influence.

The preferred workflow is:

```text
hypothesis
→ evidence baseline
→ falsification
→ executable model
→ adversarial test
→ failure analysis
→ revised invariant
→ regression
→ deployment / monitoring
```

---

## Technology map

`Python` · `PowerShell` · `Linux` · `Windows` · `Active Directory` · `Git` · `GitHub Actions` · `Docker` · `Kubernetes` · `Istio` · `MQTT` · `PostgreSQL` · `Jenkins` · `Elastic/Kibana` · `Splunk` · `Prometheus` · `Grafana` · `Jaeger` · `NetworkX` · `Matplotlib` · `AST` · `Semgrep` · `Bandit` · `Gitleaks` · `OSV` · `Burp Suite` · `OWASP ZAP` · `Metasploit` · `SIEM/SOC` · `SAST/DAST/IAST` · `Monte Carlo` · `Sobol` · `Morris`

---

## How to navigate the work

For **security and research outputs**, start with [`writeups`](https://github.com/DonkeyJJLove/writeups).

For **software-analysis experiments**, go to [`glitchlab`](https://github.com/DonkeyJJLove/glitchlab) and [`mosaic_lab_pro.py`](https://github.com/DonkeyJJLove/mosaic_lab_pro.py).

For **semantic / Human–AI protocols**, go to [`chunk-chunk`](https://github.com/DonkeyJJLove/chunk-chunk), [`HA2D`](https://github.com/DonkeyJJLove/HA2D) and [`hipotezy_nadawcze_LLM`](https://github.com/DonkeyJJLove/hipotezy_nadawcze_LLM).

For **runtime and distributed execution**, go to [`swarm`](https://github.com/DonkeyJJLove/swarm) and [`ai_platform`](https://github.com/DonkeyJJLove/ai_platform).

For **software provenance / DevSecOps**, go to [`sbom`](https://github.com/DonkeyJJLove/sbom).

For **system dynamics and probabilistic simulation**, go to [`SymulacjaKaskadySieciowej`](https://github.com/DonkeyJJLove/SymulacjaKaskadySieciowej).

---

## Security scope

Offensive-security material in these repositories is intended for **defensive research, owned environments, laboratories, sandboxes, authorized assessments and in-scope bug-bounty work**. It is not an authorization to access or disrupt third-party systems.

---

**GitHub:** [@DonkeyJJLove](https://github.com/DonkeyJJLove)
