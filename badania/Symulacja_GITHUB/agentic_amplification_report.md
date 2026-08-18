# Sandbox Agentic Amplification Study — 1000 miniagents × 100,000 Monte Carlo runs

## Scope
This is a local, isolated model of the architecture class:
1000 miniagents → intent → gateway → auth/token → shared backend.
It does not send traffic to GitHub or any external service and does not claim to reproduce GitHub 1:1.

## Experimental volume
- Monte Carlo runs: 100,000
- Miniagents / primary intents per run: 1,000
- Primary agent-intent instances represented: 100,000,000
- Base parameter sets: 25,000
- Paired retry policies per base set: OFF, naive, backoff+jitter, aggressive
- RNG seed: 20260818

## Operational signal
`architecture_signal = (Amplification >= 2.0x) AND unstable`

`unstable = queue-pressure > 1.0 for >=3 ticks OR peak aggregate queue ratio >=3.0`

## Core results
| policy     |   mean_amplification |   median_amplification |   p95_amplification |   p99_amplification |   unstable_rate |   architecture_signal |   mean_completion |   mean_peak_retry |
|:-----------|---------------------:|-----------------------:|--------------------:|--------------------:|----------------:|----------------------:|------------------:|------------------:|
| aggressive |              1.45539 |                1.072   |             4.45216 |             5.972   |         0.028   |               0.02656 |          0.762469 |          138.525  |
| backoff    |              1.31755 |                1.07169 |             3.02504 |             3.82903 |         0.00812 |               0.007   |          0.800747 |           71.1834 |
| naive      |              1.33875 |                1.072   |             3.24925 |             3.99    |         0.02168 |               0.01988 |          0.751871 |          132.392  |
| off        |              1       |                1       |             1       |             1       |         0.0006  |               0       |          0.644239 |            0      |

- Maximum observed amplification: 6.000x
- Runs >=2x amplification: 8.25% overall; 11.00% among retry-enabled runs.
- Overall architecture-signal rate: 1.34%.
- Spearman(queue pressure, amplification): rho=0.255
- Spearman(backend utilization, amplification): rho=0.387

## High-risk structural subset
Definition: fan-out >=5, concurrency >=750, full-workflow retry, reauth >=0.5, retry budget 1.0, no circuit breaker, retry enabled.

- Mean amplification: 2.471x
- Instability: 14.03%
- Architecture signal: 14.03%
- Same base configurations with retry OFF: 1.000x amplification; 0.184% instability.
- Circuit breaker variant: 1.088x; 0.48% instability; completion ratio falls from 0.747 to 0.514.
- Retry budget 0.35 variant: 1.235x; 3.25% instability.

## 20 hypotheses
| id   | hypothesis                                                                                              | status                | evidence                                                                                                                                     |
|:-----|:--------------------------------------------------------------------------------------------------------|:----------------------|:---------------------------------------------------------------------------------------------------------------------------------------------|
| H01  | Retry + partial degradation increases work at fixed 1000 intents                                        | SUPPORT               | naive-off ΔAmplification=0.339, 95% CI [0.331,0.347]                                                                                         |
| H02  | Degradation alone is sufficient for comparable workload amplification                                   | REJECT                | retry=OFF: mean Amplification=1.000x; architecture_signal=0.000%                                                                             |
| H03  | Aggressive retry amplifies more than naive retry                                                        | SUPPORT               | aggressive-naive ΔAmplification=0.117, 95% CI [0.112,0.122]                                                                                  |
| H04  | Backoff+jitter reduces instability relative to naive retry                                              | SUPPORT               | risk difference=-1.356 pp, 95% CI [-1.499,-1.213] pp                                                                                         |
| H05  | Fan-out and degradation interact super-additively                                                       | SUPPORT               | interaction Δ: naive=0.306, backoff=0.273, aggressive=0.483                                                                                  |
| H06  | Shared auth/token recoupling is necessary for amplification                                             | REJECT                | reauth_p=0 still gives mean Amplification=1.327x and instability=1.861%                                                                      |
| H07  | Shared auth/token recoupling increases auth pressure and total work                                     | SUPPORT               | TAF: 1.000x at reauth=0 -> 1.435x at reauth=1; Amplification 1.327x -> 1.396x                                                                |
| H08  | High fan-out materially increases structural instability                                                | SUPPORT               | fanout<=2 instability=0.000% vs fanout>=5=3.859%                                                                                             |
| H09  | High concurrency by itself is sufficient to produce workload amplification                              | REJECT                | retry=OFF remains exactly 1.000x WAF amplification; instability only 0.060%                                                                  |
| H10  | Latency-only degradation can trigger amplification/instability                                          | SUPPORT               | latency-only: mean Amplification=1.325x; instability=2.784%                                                                                  |
| H11  | Error-only degradation produces the same instability as latency/capacity loss                           | REJECT                | error-only instability=0.0053% vs latency-only=2.784%                                                                                        |
| H12  | Combined latency+errors are more amplifying than either alone                                           | SUPPORT               | both=1.464x vs latency=1.325x vs errors=1.232x                                                                                               |
| H13  | Retry synchronization raises the peak retry wave                                                        | SUPPORT               | backoff-naive peak retry Δ=-61.2 attempts, 95% CI [-62.7,-59.7]                                                                              |
| H14  | Start-time smoothing/jitter reduces instability                                                         | SUPPORT               | burst instability=2.155% vs smoothed=1.701%                                                                                                  |
| H15  | Retry budgets reduce amplification and instability                                                      | SUPPORT               | high-risk/no-CB: budget1.0=2.471x/14.03% unstable; budget0.35=1.235x/3.25%                                                                   |
| H16  | Circuit breaking collapses the structural amplification signal                                          | SUPPORT_WITH_TRADEOFF | high-risk: Amplification 2.471x -> 1.088x; architecture signal 14.03% -> 0.00%; completion 0.747 -> 0.514                                    |
| H17  | Whole-workflow retry is more dangerous than localized child retry                                       | SUPPORT               | full-scope=1.442x/2.493% unstable; localized=1.152x/0.195%                                                                                   |
| H18  | Backend capacity margin predicts a phase-transition-like risk boundary                                  | SUPPORT               | margin<=0.5: 49.42% unstable, 2.214x; margin>2: 0.279% unstable, 1.288x                                                                      |
| H19  | Removing the injected fault immediately removes secondary work                                          | REJECT_AS_UNIVERSAL   | post-fault retries occur in 60.51% of backoff runs; >5-tick recovery tail in 5.91%                                                           |
| H20  | The architectural-fragility thesis survives broad perturbation and disappears under structural controls | SUPPORT_CLASS_LEVEL   | unmitigated high-risk retry configs: 2.471x, 14.03% unstable, 14.03% architecture signal; paired retry-OFF controls: 1.000x, 0.184% unstable |

## Interpretation
The sandbox supports a class-level architectural-fragility thesis: under a fixed number of primary intents, retry scope, fan-out, queue pressure, and shared dependencies can create secondary work that is not present in retry-OFF controls. The effect is conditional rather than universal. It becomes concentrated when capacity margin shrinks, fan-out is high, whole-workflow retry is used, and protective controls are absent.

The experiment also falsifies stronger claims. Shared auth is not necessary for amplification. High concurrency alone is not sufficient. Error-only degradation is much less likely to create queue instability than latency/capacity degradation in this model. Therefore the observed mechanism is not simply 'AI creates more traffic'; it is a feedback architecture problem.

Circuit breaking and retry budgets sharply reduce the amplification signal, but circuit breaking trades completion for stability. Backoff+jitter reduces retry synchronization and instability while leaving a longer low-level recovery tail in a subset of runs.

## Validity boundary
The simulation validates technical possibility and causal structure inside the sandbox. It does not establish the root cause of the GitHub outage of 17 August 2026. External validity requires independent production evidence about topology, retry behavior, shared auth/token paths, capacities, and the actual triggering condition.
