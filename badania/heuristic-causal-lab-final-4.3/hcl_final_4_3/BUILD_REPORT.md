# HCL 4.3.3 — output-budget outcome accounting

## Evidence and scope

User source: HCL_RUNTIME_FAILURE_7874acc6.zip. Offline inspection verified all
34 recorded request/response hashes, 10,245 sealed file hashes, and the manifest,
registration and episode hashes. 41 source/policy hashes matched the prior
hcl-4.3-budget-fix.zip package. There were 16 qualification calls, one attempted
treatment call, and zero completed trial files.

The failed HTTP 200 reply has empty content, 3084 characters of reasoning_content,
finish_reason=length, and usage 3636 input / 768 output tokens. It has no control-
token leakage in either message field. The stored old episode incorrectly had
usage=0, protocol_success=true, generation_limit=false and PROVIDER_ERROR.

## Changes

- Preserve observed HTTP output-cap replies and reported usage as ProviderReply.
- Strictly parse only message.content; never mine analysis for actions or answers.
- Missing/invalid action at the cap is terminal GENERATION_LIMIT, safe_success=false,
  retained in the denominator without retry. Valid complete action at the cap
  uses the same parser and grader, with the cap-hit flag visible.
- Add output_budget_exhausted as a descriptive endpoint and show it in HTML/CSV.
- Replay audits usage arithmetic and failure classification.
- Actual provider failures with unknown usage no longer assert zero complete usage.
- Neutral pre-seal qualification still rejects any cap hit.
- Retain the existing channel-leak guard and other conservative transport stops.
- Use new seeds 30000–30255 and disclose prior data/new accounting in the seal.

No model weights, requests (768/769), original policies, generators, tool semantics,
action parser, correctness grader, or LION runtime lifecycle code are altered.
21 files and 5 statistical function ASTs were compared with the old package:
see evidence/unchanged_components_output_budget.json. Statistical presentation
has changed to expose output-limit failures, not alter hypothesis thresholds.

## Executed validation

- Baseline original package: 296 tests passed.
- Patched suite: 314 tests passed, including 18 regression cases in
  tests/test_output_budget_accounting.py. Log and JUnit XML in evidence/.
- Actual recorded response replayed offline: same outgoing request object,
  GENERATION_LIMIT, success=false, input=3636/output=768, zero tools executed.
- Synthetic integration: 40/40 cap-exhausted trials are stored, replay audit PASS,
  no circuit breaker on ordinary cap exhaustion. Resume makes zero new requests.
  These are explicitly mock records, not model research results.
- Independent scripted-oracle smoke: 40/40 episodes, audit PASS; no live inference.
- compileall checked. The delivery archive is unpacked and validated separately;
  the standalone package verification report contains the exact delivered hashes.

Two prior tests were updated because they asserted the old erroneous rule
length => ProviderError. Other prior regression checks remained in the suite.
No new live model generation, remote connection, LION service change or Git write
was performed during this build. Test platform is Linux/Python in the container;
no native Windows/Vulkan run is claimed.

## Limitations

This patch fixes classification/accounting, not the model's failure to hand off.
One strong_control trace is not an estimate of author-minus-control. The control
contains extensive repeated padding and is left unchanged; this limits the
interpretation to the frozen packages. No universal heuristic claim follows.
Existing non-limit transport failures may still halt the study. No unseen backend
behavior is guaranteed. Production and research still share physical resources.

Do not overwrite or resume the old sealed study. This is a new prospective
measurement version; the uploaded source archive is preserved unchanged.
