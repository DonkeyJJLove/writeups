# DonkeyJJLove — detailed professional and research profile

## Profile

I work at the intersection of **cybersecurity, AI/agentic security, security architecture, probabilistic systems research, program analysis and Human–AI interaction**. My work is not limited to studying language models as isolated components. I focus on the full path from **information and semantic interpretation to authority, execution, state change, observability and recovery**.

My professional security background spans application and infrastructure security, offensive research, pentesting and bug bounty, Secure SDLC / DevSecOps, SIEM/SOC and incident response, Windows/Linux environments, Active Directory and privileged-access architectures, network security controls, web security and industrial/ICS contexts. This operational background is used as the deterministic substrate for research on AI-driven and agentic systems.

The recurring research question across my repositories is:

> **How can probabilistic intelligence be given increasing autonomy without giving it uncontrolled authority over deterministic systems?**

I therefore treat AI security primarily as a problem of **execution-path control, compositional risk, provenance, observability and authority propagation**, rather than as a problem reducible to prompt filtering or model alignment alone.

---

## Main research directions

### AI / Agentic Security

I study security failures that emerge when individually valid primitives are composed by an AI system into a globally unsafe execution path. This research led to the **Security Model Boundary (SMB/SMBE)** line: a model of reachable trajectories that may remain locally policy-compliant while violating a global security invariant.

A related construct is the **Probabilistic–Deterministic Boundary (PDB)** — the point at which probabilistic interpretation and planning are converted into deterministic consequences such as `WRITE`, `EXECUTE`, `SEND`, `GRANT`, `DEPLOY` or `CHANGE_POLICY`.

The resulting architectural direction is:

```text
Probabilistic Intelligence
inside
Observable + Provenance-Aware + Capability-Bounded
+ Path-Aware + Deterministically Enforced Execution Envelope
```

This work also includes:

- Security Observability Kernel,
- Security Boundary Buffer,
- Combinatorial Execution Control,
- delegated-authority and capability tracking,
- context / memory / tool-use security,
- execution receipts and causal provenance,
- RED / BLUE / PURPLE model-expansion workflows,
- continuous adversarial validation of agentic systems.

### Offensive Security and Vulnerability Research

My security work includes **pentesting, web/application security, vulnerability research and bug-bounty methodology**, with emphasis on reconstructing complete exploitability rather than stopping at isolated primitives. The recurring analytical pattern is:

```text
primitive
→ composition
→ reachable path
→ authority transition
→ real security impact
```

The same logic is applied to classic vulnerabilities, authorization graphs, workflow flaws and AI-mediated attack paths. Research is scoped to owned, laboratory, authorized-assessment and in-scope bug-bounty environments.

### Security Architecture and DevSecOps

I design and analyze controls around:

- Zero Trust and least privilege,
- privileged access and delegated authority,
- identity and identity-over-time,
- SBOM and provenance,
- SAST / DAST / IAST and Secure SDLC,
- CI/CD security gates,
- runtime policy enforcement,
- segmentation and blast-radius control,
- deterministic enforcement around probabilistic systems,
- observability through Elastic/Kibana, Splunk, Prometheus, Grafana and Jaeger.

The `sbom` research line treats SBOM not only as inventory but as a repeated observation of software state, linked through delta, provenance and application identity.

### Program Analysis and Δ-first Engineering

In `glitchlab` and related repositories I work with **AST analysis, graph representations, delta-first software analysis, invariants, fingerprints and controlled remediation**. Instead of treating a repository only as a static snapshot, the primary object is often the transition:

```text
state_t
→ Δ
→ state_t+1
```

This makes it possible to connect code analysis, security findings, regressions and process observability in one model.

### Probabilistic Research and Complex Systems

I use **Monte Carlo simulation, heavy-tail analysis, Pareto optimization, counterfactual falsification, adversarial stress testing, Morris screening and Sobol sensitivity analysis** to study systems where deterministic point estimates are insufficient.

A key methodological constraint in this work is the separation:

```text
simulation convergence
≠ empirical truth
```

Large simulations reduce sampling error inside a model; they do not remove model risk, repair weak priors or convert calibration assumptions into empirical frequencies.

### Distributed and Multi-Agent Systems

My repositories include experimental work on:

- multi-agent control planes,
- swarm / distributed execution,
- Kubernetes and Istio,
- MQTT and telemetry pipelines,
- workload identity,
- cross-agent authority propagation,
- SOC-facing observability,
- containment and cascade control.

The architectural focus is not only whether an agent works, but whether the **whole distributed trajectory remains observable, reconstructable and controllable**.

### Human–AI, semantic protocols and epistemic systems

I also develop experimental models of Human–AI interaction and semantic state, including **HMK-9D / `chunk–chunk→`, HA2D, QV9D, LOCI, semantic bridges, context protocols and microcode-like textual structures**.

These constructs explore how information changes state across a process and how semantic transitions can be represented explicitly rather than left as invisible conversational context.

My `_neuro` / EEG-inspired models are used as **process and state-dynamics metaphors / analytical structures**, not as clinical or physiological measurements. They map concepts such as baseline, delta, burst, coupling, drift and recovery onto evolving computational or Human–AI processes.

---

## Research method

My preferred research loop is:

```text
hypothesis
→ evidence baseline
→ falsification
→ formalization
→ executable model
→ adversarial test
→ failure analysis
→ revised invariant
→ regression
→ deployment / monitoring
```

I explicitly separate:

```text
FACT / OBSERVED
DERIVED
CALIBRATED
ASSUMED
HYPOTHESIS
SPECULATION
STRESS PARAMETER
```

This is important because many of the projects operate close to the boundary between engineering, exploratory research and original conceptual modeling.

---

## Representative authored constructs

- **Security Model Boundary — SMB / SMBE**
- **Probabilistic–Deterministic Boundary — PDB**
- **Security Observability Kernel**
- **Security Boundary Buffer**
- **Combinatorial Execution Control**
- **LLM Trust Boundary Collapse — LTBC**
- **HMK-9D / `chunk–chunk→`**
- **Δ-first software analysis / AST ↔ Mosaic**
- **AID + SBOM identity-over-time**
- **HA2D persistent-context architecture**
- **QV9D / project-mosaic integration model**
- **LOCI state / trajectory analysis line**

These are authored research models, engineering constructs or hypotheses. They are not presented as external scientific standards unless independently established as such.

---

## Practical technology domains

`Python` · `PowerShell` · `Linux` · `Windows` · `Active Directory` · `Git` · `GitHub Actions` · `Docker` · `Kubernetes` · `Istio` · `MQTT` · `PostgreSQL` · `Jenkins` · `Elastic/Kibana` · `Splunk` · `Prometheus` · `Grafana` · `Jaeger` · `NetworkX` · `AST` · `Semgrep` · `Bandit` · `Gitleaks` · `OSV` · `Burp Suite` · `OWASP ZAP` · `Metasploit` · `SIEM/SOC` · `SAST/DAST/IAST` · `Monte Carlo` · `Sobol` · `Morris`

---

## Portfolio entry points

- [`writeups`](https://github.com/DonkeyJJLove/writeups) — research corpus, AI security, architecture and publications
- [`glitchlab`](https://github.com/DonkeyJJLove/glitchlab) — program analysis, Δ, invariants and security engineering
- [`chunk-chunk`](https://github.com/DonkeyJJLove/chunk-chunk) — HMK-9D and semantic/process protocols
- [`ai_platform`](https://github.com/DonkeyJJLove/ai_platform) — integration and orchestration
- [`sbom`](https://github.com/DonkeyJJLove/sbom) — software provenance and DevSecOps
- [`swarm`](https://github.com/DonkeyJJLove/swarm) — distributed / multi-agent execution
- [`HA2D`](https://github.com/DonkeyJJLove/HA2D) — persistent Human–AI context
- [`mosaic_lab_pro.py`](https://github.com/DonkeyJJLove/mosaic_lab_pro.py) — AST / graph / topology experiments
- [`SymulacjaKaskadySieciowej`](https://github.com/DonkeyJJLove/SymulacjaKaskadySieciowej) — Monte Carlo and system dynamics
- [`hipotezy_nadawcze_LLM`](https://github.com/DonkeyJJLove/hipotezy_nadawcze_LLM) — falsification of LLM communication hypotheses

---

## Compact identity statement

> **Cybersecurity practitioner and independent AI-security researcher working on agentic execution, compositional security, provenance, observability, probabilistic systems and Human–AI architectures — with a focus on controlling the boundary where semantic decisions become real execution.**
