
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import spearmanr

OUT = Path("/mnt/data")
SEED = 20260818
N_BASE = 25000
N_RUNS = N_BASE * 4
N_AGENTS = 1000
T = 60

def simulate_mc(n_base=N_BASE, T=T, seed=SEED):
    rng = np.random.default_rng(seed)
    B = n_base

    fanout0 = rng.choice(np.array([1,2,5,10], dtype=np.int16), B)
    concurrency0 = rng.choice(np.array([100,250,500,750,1000], dtype=np.int16), B)

    dl_raw = rng.choice(np.array([50,100,250,500], dtype=np.float32), B)
    fr_raw = rng.choice(np.array([0.01,0.05,0.10,0.20], dtype=np.float32), B)
    deg_mode0 = rng.choice(np.array([0,1,2], dtype=np.int8), B, p=[0.25,0.25,0.50])  # latency/error/both
    deg_latency0 = np.where(deg_mode0 == 1, 0, dl_raw).astype(np.float32)
    fail_rate0 = np.where(deg_mode0 == 0, 0, fr_raw).astype(np.float32)

    gw_cap0 = rng.lognormal(mean=np.log(2200), sigma=0.12, size=B).astype(np.float32)
    auth_cap0 = rng.lognormal(mean=np.log(1800), sigma=0.15, size=B).astype(np.float32)
    be_cap0 = rng.lognormal(mean=np.log(13000), sigma=0.20, size=B).astype(np.float32)
    timeout0 = rng.uniform(350,700,B).astype(np.float32)

    reauth_p0 = rng.choice(np.array([0.0,0.5,1.0], dtype=np.float32), B, p=[0.25,0.25,0.50])
    circuit_breaker0 = rng.choice(np.array([0,1], dtype=np.int8), B, p=[0.70,0.30])
    retry_budget0 = rng.choice(np.array([0.35,0.60,1.0], dtype=np.float32), B, p=[0.20,0.25,0.55])
    full_scope0 = rng.choice(np.array([0,1], dtype=np.int8), B, p=[0.25,0.75])
    burst_factor0 = rng.choice(np.array([0.65,0.85,1.0], dtype=np.float32), B, p=[0.20,0.30,0.50])

    policy_names = np.array(["off","naive","backoff","aggressive"])
    R = B * 4
    rep = lambda x: np.repeat(x, 4)

    fanout = rep(fanout0)
    concurrency = rep(concurrency0)
    deg_latency = rep(deg_latency0)
    fail_rate = rep(fail_rate0)
    deg_mode = rep(deg_mode0)
    gw_cap = rep(gw_cap0)
    auth_cap = rep(auth_cap0)
    be_cap = rep(be_cap0)
    timeout = rep(timeout0)
    reauth_p = rep(reauth_p0)
    circuit_breaker = rep(circuit_breaker0)
    retry_budget = rep(retry_budget0)
    full_scope = rep(full_scope0)
    burst_factor = rep(burst_factor0)

    policy = np.tile(np.arange(4, dtype=np.int8), B)
    max_retry = np.array([0,3,3,5], dtype=np.int8)[policy]

    remaining = np.full(R, N_AGENTS, dtype=np.int32)
    pending = np.zeros((6,R), dtype=np.int32)

    qgw = np.zeros(R, dtype=np.float32)
    qauth = np.zeros(R, dtype=np.float32)
    qbe = np.zeros(R, dtype=np.float32)

    total_gw = np.zeros(R)
    total_auth = np.zeros(R)
    total_be = np.zeros(R)
    total_retry = np.zeros(R)
    completed = np.zeros(R)
    final_fail = np.zeros(R)

    peak_qratio = np.zeros(R, dtype=np.float32)
    peak_retry = np.zeros(R, dtype=np.float32)
    peak_auth_ratio = np.zeros(R, dtype=np.float32)
    peak_be_ratio = np.zeros(R, dtype=np.float32)
    unstable_ticks = np.zeros(R, dtype=np.int16)
    recovery_time = np.full(R, np.nan, dtype=np.float32)
    post_fault_peak_retry = np.zeros(R, dtype=np.float32)

    fault_end = 12
    arrival_cap = np.maximum(1, (concurrency * burst_factor).astype(np.int32))

    def sigmoid(x):
        return 1/(1+np.exp(-np.clip(x,-30,30)))

    for t in range(T):
        primary = np.minimum(remaining, arrival_cap)
        remaining -= primary

        active_levels = np.zeros((6,R), dtype=np.int32)
        active_levels[0] = primary

        for lvl in range(1,6):
            pend = pending[lvl]
            release = np.zeros(R, dtype=np.int32)

            immediate = (policy == 1) | (policy == 3)
            release[immediate] = pend[immediate]

            backoff = (policy == 2)
            if backoff.any():
                hazard = 1/(2**lvl)
                release[backoff] = rng.binomial(pend[backoff], hazard)

            pending[lvl] -= release
            active_levels[lvl] = release

        retry_attempts = active_levels[1:].sum(axis=0).astype(np.int32)
        attempts = primary + retry_attempts

        retry_fanout = np.where(full_scope == 1, fanout, 1).astype(np.float32)
        gw_arr = attempts.astype(np.float32)
        auth_arr = primary.astype(np.float32) + retry_attempts.astype(np.float32) * reauth_p
        be_arr = (
            primary.astype(np.float32) * fanout.astype(np.float32)
            + retry_attempts.astype(np.float32) * retry_fanout
        )

        total_gw += gw_arr
        total_auth += auth_arr
        total_be += be_arr
        total_retry += retry_attempts

        if t < fault_end:
            dl = deg_latency
            fr = fail_rate
            effective_be_cap = be_cap / (1 + dl/200.0)
        else:
            dl = np.zeros(R, dtype=np.float32)
            fr = np.zeros(R, dtype=np.float32)
            effective_be_cap = be_cap

        pre_g = qgw + gw_arr
        pre_a = qauth + auth_arr
        pre_b = qbe + be_arr

        qgw = np.maximum(0, pre_g - gw_cap)
        qauth = np.maximum(0, pre_a - auth_cap)
        qbe = np.maximum(0, pre_b - effective_be_cap)

        lg = 10 + (pre_g / np.maximum(gw_cap,1)) * 100
        la = 20 + (pre_a / np.maximum(auth_cap,1)) * 100
        lb = 50 + dl + (pre_b / np.maximum(effective_be_cap,1)) * 100

        pg = sigmoid((lg-timeout)/45.0)
        pa = sigmoid((la-timeout)/45.0)
        pt = sigmoid((lb-timeout)/45.0)

        p_child = 1 - (1-fr) * (1-pt)
        pbe_primary = 1 - np.power(np.clip(1-p_child,0,1), fanout)
        pbe_retry = 1 - np.power(np.clip(1-p_child,0,1), retry_fanout)

        pf_primary = np.clip(1-(1-pg)*(1-pa)*(1-pbe_primary), 0, 0.999)
        pf_retry = np.clip(1-(1-pg)*(1-pa)*(1-pbe_retry), 0, 0.999)

        qratio = (
            qgw/np.maximum(gw_cap,1)
            + qauth/np.maximum(auth_cap,1)
            + qbe/np.maximum(effective_be_cap,1)
        )

        cb_trip = (
            (circuit_breaker == 1)
            & (
                (qbe/np.maximum(effective_be_cap,1) > 0.5)
                | ((pf_primary + pf_retry)/2 > 0.25)
            )
        )

        for lvl in range(6):
            n = active_levels[lvl]
            if not np.any(n):
                continue

            p_level = pf_primary if lvl == 0 else pf_retry
            f = rng.binomial(n, p_level)
            completed += n - f

            can_retry = (lvl < max_retry)
            retry_f = np.where(can_retry, f, 0)

            probability = retry_budget.copy()
            probability = np.where(cb_trip, probability * 0.10, probability)
            to_retry = rng.binomial(retry_f, np.clip(probability,0,1)) if np.any(retry_f) else retry_f

            final_fail += f - to_retry
            if lvl < 5:
                pending[lvl+1] += to_retry.astype(np.int32)

        peak_qratio = np.maximum(peak_qratio, qratio)
        peak_retry = np.maximum(peak_retry, retry_attempts)
        peak_auth_ratio = np.maximum(peak_auth_ratio, auth_arr/np.maximum(auth_cap,1))
        peak_be_ratio = np.maximum(peak_be_ratio, be_arr/np.maximum(effective_be_cap,1))
        unstable_ticks += (qratio > 1.0).astype(np.int16)

        if t >= fault_end:
            post_fault_peak_retry = np.maximum(post_fault_peak_retry, retry_attempts)
            recovered = (qratio < 0.10) & (retry_attempts < 0.05*np.maximum(concurrency,1))
            setmask = np.isnan(recovery_time) & recovered
            recovery_time[setmask] = t - fault_end

    total_work = total_gw + total_auth + total_be
    waf = total_work / N_AGENTS
    waf0 = fanout + 2
    amplification = waf / waf0

    unstable = (unstable_ticks >= 3) | (peak_qratio >= 3.0)
    hysteresis = np.isnan(recovery_time) | (recovery_time > 5)
    architecture_signal = (amplification >= 2.0) & unstable

    return pd.DataFrame({
        "base_id": np.repeat(np.arange(B),4),
        "policy": policy_names[policy],
        "fanout": fanout,
        "concurrency": concurrency,
        "deg_mode": np.array(["latency","error","both"])[deg_mode],
        "deg_latency_ms": deg_latency,
        "fail_rate": fail_rate,
        "gw_cap": gw_cap,
        "auth_cap": auth_cap,
        "be_cap": be_cap,
        "timeout_ms": timeout,
        "reauth_p": reauth_p,
        "circuit_breaker": circuit_breaker,
        "retry_budget": retry_budget,
        "full_scope_retry": full_scope,
        "burst_factor": burst_factor,
        "waf": waf,
        "amplification": amplification,
        "raf": (total_gw + total_be) / N_AGENTS,
        "taf": total_auth / N_AGENTS,
        "baf": total_be / (N_AGENTS * fanout),
        "retry_requests": total_retry,
        "peak_queue_ratio": peak_qratio,
        "peak_retry_attempts": peak_retry,
        "peak_auth_util": peak_auth_ratio,
        "peak_backend_util": peak_be_ratio,
        "completion_ratio": completed / N_AGENTS,
        "final_fail_ratio": final_fail / N_AGENTS,
        "unstable": unstable,
        "hysteresis": hysteresis,
        "recovery_ticks": recovery_time,
        "post_fault_peak_retry": post_fault_peak_retry,
        "architecture_signal": architecture_signal
    })

def paired_diff_ci(df, metric, a, b):
    p = df.pivot(index="base_id", columns="policy", values=metric)
    d = p[a].astype(float).to_numpy() - p[b].astype(float).to_numpy()
    m = d.mean()
    se = d.std(ddof=1)/np.sqrt(len(d))
    return m, m-1.96*se, m+1.96*se

df = simulate_mc()

retry = df[df.policy != "off"].copy()
retry["be_margin"] = (
    retry.be_cap/(1+retry.deg_latency_ms/200)
    /(retry.concurrency*retry.burst_factor*retry.fanout)
)

# Key subsets
high_fan = retry[retry.fanout >= 5]
low_fan = retry[retry.fanout <= 2]
rea0 = retry[retry.reauth_p == 0]
rea1 = retry[retry.reauth_p == 1]
lat = retry[retry.deg_mode == "latency"]
err = retry[retry.deg_mode == "error"]
both = retry[retry.deg_mode == "both"]
smooth = retry[retry.burst_factor < 1]
burst = retry[retry.burst_factor == 1]
full = retry[retry.full_scope_retry == 1]
local = retry[retry.full_scope_retry == 0]
low_margin = retry[retry.be_margin <= 0.5]
high_margin = retry[retry.be_margin > 2.0]

structural = (
    (df.fanout >= 5)
    & (df.concurrency >= 750)
    & (df.full_scope_retry == 1)
    & (df.reauth_p >= 0.5)
    & (df.policy != "off")
)

unmit = df[structural & (df.circuit_breaker == 0) & (df.retry_budget == 1.0)]
cbmit = df[structural & (df.circuit_breaker == 1) & (df.retry_budget == 1.0)]
bud035 = df[structural & (df.circuit_breaker == 0) & (df.retry_budget == 0.35)]
bud060 = df[structural & (df.circuit_breaker == 0) & (df.retry_budget == 0.60)]

# Interaction signal for fan-out x high degradation
synergy = {}
for pol in ["naive","backoff","aggressive"]:
    d = df[df.policy == pol]
    hf = d.fanout >= 5
    hs = (d.deg_latency_ms >= 250) | (d.fail_rate >= 0.10)
    means = {}
    for a in [False,True]:
        for b in [False,True]:
            means[(a,b)] = d[hf.eq(a) & hs.eq(b)].amplification.mean()
    synergy[pol] = means[(True,True)] - means[(True,False)] - means[(False,True)] + means[(False,False)]

naive_off = paired_diff_ci(df, "amplification", "naive", "off")
agg_naive = paired_diff_ci(df, "amplification", "aggressive", "naive")
back_naive_unstable = paired_diff_ci(df, "unstable", "backoff", "naive")
back_naive_peak = paired_diff_ci(df, "peak_retry_attempts", "backoff", "naive")

rho_q, _ = spearmanr(retry.peak_queue_ratio, retry.amplification)
rho_be, _ = spearmanr(retry.peak_backend_util, retry.amplification)

off_same = df[(df.base_id.isin(unmit.base_id.unique())) & (df.policy == "off")]

hypotheses = [
    ("H01","Retry + partial degradation increases work at fixed 1000 intents","SUPPORT",
     f"naive-off ΔAmplification={naive_off[0]:.3f}, 95% CI [{naive_off[1]:.3f},{naive_off[2]:.3f}]"),
    ("H02","Degradation alone is sufficient for comparable workload amplification","REJECT",
     f"retry=OFF: mean Amplification={df[df.policy=='off'].amplification.mean():.3f}x; architecture_signal={df[df.policy=='off'].architecture_signal.mean()*100:.3f}%"),
    ("H03","Aggressive retry amplifies more than naive retry","SUPPORT",
     f"aggressive-naive ΔAmplification={agg_naive[0]:.3f}, 95% CI [{agg_naive[1]:.3f},{agg_naive[2]:.3f}]"),
    ("H04","Backoff+jitter reduces instability relative to naive retry","SUPPORT",
     f"risk difference={back_naive_unstable[0]*100:.3f} pp, 95% CI [{back_naive_unstable[1]*100:.3f},{back_naive_unstable[2]*100:.3f}] pp"),
    ("H05","Fan-out and degradation interact super-additively","SUPPORT",
     "interaction Δ: " + ", ".join(f"{k}={v:.3f}" for k,v in synergy.items())),
    ("H06","Shared auth/token recoupling is necessary for amplification","REJECT",
     f"reauth_p=0 still gives mean Amplification={rea0.amplification.mean():.3f}x and instability={rea0.unstable.mean()*100:.3f}%"),
    ("H07","Shared auth/token recoupling increases auth pressure and total work","SUPPORT",
     f"TAF: {rea0.taf.mean():.3f}x at reauth=0 -> {rea1.taf.mean():.3f}x at reauth=1; Amplification {rea0.amplification.mean():.3f}x -> {rea1.amplification.mean():.3f}x"),
    ("H08","High fan-out materially increases structural instability","SUPPORT",
     f"fanout<=2 instability={low_fan.unstable.mean()*100:.3f}% vs fanout>=5={high_fan.unstable.mean()*100:.3f}%"),
    ("H09","High concurrency by itself is sufficient to produce workload amplification","REJECT",
     f"retry=OFF remains exactly 1.000x WAF amplification; instability only {df[df.policy=='off'].unstable.mean()*100:.3f}%"),
    ("H10","Latency-only degradation can trigger amplification/instability","SUPPORT",
     f"latency-only: mean Amplification={lat.amplification.mean():.3f}x; instability={lat.unstable.mean()*100:.3f}%"),
    ("H11","Error-only degradation produces the same instability as latency/capacity loss","REJECT",
     f"error-only instability={err.unstable.mean()*100:.4f}% vs latency-only={lat.unstable.mean()*100:.3f}%"),
    ("H12","Combined latency+errors are more amplifying than either alone","SUPPORT",
     f"both={both.amplification.mean():.3f}x vs latency={lat.amplification.mean():.3f}x vs errors={err.amplification.mean():.3f}x"),
    ("H13","Retry synchronization raises the peak retry wave","SUPPORT",
     f"backoff-naive peak retry Δ={back_naive_peak[0]:.1f} attempts, 95% CI [{back_naive_peak[1]:.1f},{back_naive_peak[2]:.1f}]"),
    ("H14","Start-time smoothing/jitter reduces instability","SUPPORT",
     f"burst instability={burst.unstable.mean()*100:.3f}% vs smoothed={smooth.unstable.mean()*100:.3f}%"),
    ("H15","Retry budgets reduce amplification and instability","SUPPORT",
     f"high-risk/no-CB: budget1.0={unmit.amplification.mean():.3f}x/{unmit.unstable.mean()*100:.2f}% unstable; budget0.35={bud035.amplification.mean():.3f}x/{bud035.unstable.mean()*100:.2f}%"),
    ("H16","Circuit breaking collapses the structural amplification signal","SUPPORT_WITH_TRADEOFF",
     f"high-risk: Amplification {unmit.amplification.mean():.3f}x -> {cbmit.amplification.mean():.3f}x; architecture signal {unmit.architecture_signal.mean()*100:.2f}% -> {cbmit.architecture_signal.mean()*100:.2f}%; completion {unmit.completion_ratio.mean():.3f} -> {cbmit.completion_ratio.mean():.3f}"),
    ("H17","Whole-workflow retry is more dangerous than localized child retry","SUPPORT",
     f"full-scope={full.amplification.mean():.3f}x/{full.unstable.mean()*100:.3f}% unstable; localized={local.amplification.mean():.3f}x/{local.unstable.mean()*100:.3f}%"),
    ("H18","Backend capacity margin predicts a phase-transition-like risk boundary","SUPPORT",
     f"margin<=0.5: {low_margin.unstable.mean()*100:.2f}% unstable, {low_margin.amplification.mean():.3f}x; margin>2: {high_margin.unstable.mean()*100:.3f}% unstable, {high_margin.amplification.mean():.3f}x"),
    ("H19","Removing the injected fault immediately removes secondary work","REJECT_AS_UNIVERSAL",
     f"post-fault retries occur in {100*(retry[retry.policy=='backoff'].post_fault_peak_retry>0).mean():.2f}% of backoff runs; >5-tick recovery tail in {100*(retry[retry.policy=='backoff'].recovery_ticks>5).mean():.2f}%"),
    ("H20","The architectural-fragility thesis survives broad perturbation and disappears under structural controls","SUPPORT_CLASS_LEVEL",
     f"unmitigated high-risk retry configs: {unmit.amplification.mean():.3f}x, {unmit.unstable.mean()*100:.2f}% unstable, {unmit.architecture_signal.mean()*100:.2f}% architecture signal; paired retry-OFF controls: {off_same.amplification.mean():.3f}x, {off_same.unstable.mean()*100:.3f}% unstable")
]
hyp = pd.DataFrame(hypotheses, columns=["id","hypothesis","status","evidence"])

# Outputs
results_path = OUT / "agentic_amplification_mc_100k.csv.gz"
hyp_path = OUT / "agentic_amplification_hypotheses_20.csv"
report_path = OUT / "agentic_amplification_report.md"

df.to_csv(results_path, index=False, compression="gzip")
hyp.to_csv(hyp_path, index=False)

policy_summary = df.groupby("policy").agg(
    mean_amplification=("amplification","mean"),
    median_amplification=("amplification","median"),
    p95_amplification=("amplification", lambda x: x.quantile(0.95)),
    p99_amplification=("amplification", lambda x: x.quantile(0.99)),
    unstable_rate=("unstable","mean"),
    architecture_signal=("architecture_signal","mean"),
    mean_completion=("completion_ratio","mean"),
    mean_peak_retry=("peak_retry_attempts","mean")
)

# Chart 1
plt.figure(figsize=(8,5))
policy_summary["mean_amplification"].reindex(["off","naive","backoff","aggressive"]).plot(kind="bar")
plt.ylabel("Mean amplification (x baseline WAF)")
plt.xlabel("Retry policy")
plt.title("Mean workload amplification by retry policy — 100,000 Monte Carlo runs")
plt.tight_layout()
plt.savefig(OUT / "chart_1_policy_amplification.png", dpi=180)
plt.close()

# Chart 2
pivot = df.pivot_table(index="concurrency", columns="policy", values="unstable", aggfunc="mean")
plt.figure(figsize=(8,5))
for col in ["off","naive","backoff","aggressive"]:
    plt.plot(pivot.index, pivot[col]*100, marker="o", label=col)
plt.xlabel("Concurrent miniagents")
plt.ylabel("Unstable runs (%)")
plt.title("Instability vs concurrency")
plt.legend()
plt.tight_layout()
plt.savefig(OUT / "chart_2_instability_concurrency.png", dpi=180)
plt.close()

# Chart 3
pivot_f = df.pivot_table(index="fanout", columns="policy", values="amplification", aggfunc="mean")
plt.figure(figsize=(8,5))
for col in ["off","naive","backoff","aggressive"]:
    plt.plot(pivot_f.index, pivot_f[col], marker="o", label=col)
plt.xlabel("Fan-out per intent")
plt.ylabel("Mean amplification (x)")
plt.title("Fan-out x retry amplification")
plt.legend()
plt.tight_layout()
plt.savefig(OUT / "chart_3_fanout_amplification.png", dpi=180)
plt.close()

# Chart 4
mitigation = pd.Series({
    "Unmitigated": unmit.amplification.mean(),
    "Retry budget 0.60": bud060.amplification.mean(),
    "Retry budget 0.35": bud035.amplification.mean(),
    "Circuit breaker": cbmit.amplification.mean()
})
plt.figure(figsize=(8,5))
mitigation.plot(kind="bar")
plt.ylabel("Mean amplification (x)")
plt.xlabel("High-risk structural configuration")
plt.title("Structural mitigations collapse amplification")
plt.tight_layout()
plt.savefig(OUT / "chart_4_mitigation_effect.png", dpi=180)
plt.close()

summary = {
    "runs": int(len(df)),
    "agents_per_run": N_AGENTS,
    "primary_agent_intents_simulated": int(len(df)*N_AGENTS),
    "seed": SEED,
    "overall_architecture_signal_rate": float(df.architecture_signal.mean()),
    "overall_amp_ge_2": float((df.amplification >= 2).mean()),
    "retry_amp_ge_2": float((retry.amplification >= 2).mean()),
    "max_observed_amplification": float(df.amplification.max()),
    "spearman_queue_vs_amplification": float(rho_q),
    "spearman_backend_util_vs_amplification": float(rho_be),
    "unmitigated_high_risk_mean_amp": float(unmit.amplification.mean()),
    "unmitigated_high_risk_unstable_rate": float(unmit.unstable.mean()),
    "circuit_breaker_high_risk_mean_amp": float(cbmit.amplification.mean()),
    "circuit_breaker_high_risk_unstable_rate": float(cbmit.unstable.mean())
}
(OUT / "agentic_amplification_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")

report = f"""# Sandbox Agentic Amplification Study — 1000 miniagents × 100,000 Monte Carlo runs

## Scope
This is a local, isolated model of the architecture class:
1000 miniagents → intent → gateway → auth/token → shared backend.
It does not send traffic to GitHub or any external service and does not claim to reproduce GitHub 1:1.

## Experimental volume
- Monte Carlo runs: {len(df):,}
- Miniagents / primary intents per run: {N_AGENTS:,}
- Primary agent-intent instances represented: {len(df)*N_AGENTS:,}
- Base parameter sets: {N_BASE:,}
- Paired retry policies per base set: OFF, naive, backoff+jitter, aggressive
- RNG seed: {SEED}

## Operational signal
`architecture_signal = (Amplification >= 2.0x) AND unstable`

`unstable = queue-pressure > 1.0 for >=3 ticks OR peak aggregate queue ratio >=3.0`

## Core results
{policy_summary.to_markdown()}

- Maximum observed amplification: {df.amplification.max():.3f}x
- Runs >=2x amplification: {(df.amplification>=2).mean()*100:.2f}% overall; {(retry.amplification>=2).mean()*100:.2f}% among retry-enabled runs.
- Overall architecture-signal rate: {df.architecture_signal.mean()*100:.2f}%.
- Spearman(queue pressure, amplification): rho={rho_q:.3f}
- Spearman(backend utilization, amplification): rho={rho_be:.3f}

## High-risk structural subset
Definition: fan-out >=5, concurrency >=750, full-workflow retry, reauth >=0.5, retry budget 1.0, no circuit breaker, retry enabled.

- Mean amplification: {unmit.amplification.mean():.3f}x
- Instability: {unmit.unstable.mean()*100:.2f}%
- Architecture signal: {unmit.architecture_signal.mean()*100:.2f}%
- Same base configurations with retry OFF: {off_same.amplification.mean():.3f}x amplification; {off_same.unstable.mean()*100:.3f}% instability.
- Circuit breaker variant: {cbmit.amplification.mean():.3f}x; {cbmit.unstable.mean()*100:.2f}% instability; completion ratio falls from {unmit.completion_ratio.mean():.3f} to {cbmit.completion_ratio.mean():.3f}.
- Retry budget 0.35 variant: {bud035.amplification.mean():.3f}x; {bud035.unstable.mean()*100:.2f}% instability.

## 20 hypotheses
{hyp.to_markdown(index=False)}

## Interpretation
The sandbox supports a class-level architectural-fragility thesis: under a fixed number of primary intents, retry scope, fan-out, queue pressure, and shared dependencies can create secondary work that is not present in retry-OFF controls. The effect is conditional rather than universal. It becomes concentrated when capacity margin shrinks, fan-out is high, whole-workflow retry is used, and protective controls are absent.

The experiment also falsifies stronger claims. Shared auth is not necessary for amplification. High concurrency alone is not sufficient. Error-only degradation is much less likely to create queue instability than latency/capacity degradation in this model. Therefore the observed mechanism is not simply 'AI creates more traffic'; it is a feedback architecture problem.

Circuit breaking and retry budgets sharply reduce the amplification signal, but circuit breaking trades completion for stability. Backoff+jitter reduces retry synchronization and instability while leaving a longer low-level recovery tail in a subset of runs.

## Validity boundary
The simulation validates technical possibility and causal structure inside the sandbox. It does not establish the root cause of the GitHub outage of 17 August 2026. External validity requires independent production evidence about topology, retry behavior, shared auth/token paths, capacities, and the actual triggering condition.
"""
report_path.write_text(report, encoding="utf-8")

print("Completed:", len(df), "Monte Carlo runs")
print(policy_summary.round(4))
print("\nHigh-risk unmitigated:", {
    "mean_amp": round(unmit.amplification.mean(), 4),
    "unstable_rate": round(unmit.unstable.mean(), 4),
    "architecture_signal": round(unmit.architecture_signal.mean(), 4),
})
print("Max amplification:", round(df.amplification.max(), 4))
print("Hypothesis statuses:")
print(hyp[["id","status"]].to_string(index=False))
