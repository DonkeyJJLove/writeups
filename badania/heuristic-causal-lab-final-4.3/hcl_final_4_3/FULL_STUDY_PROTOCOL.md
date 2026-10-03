# HCL 4.3.3 — full study, output-budget accounting amendment

This is a prospective change in how generated output-cap outcomes are recorded,
not a regrading or resumption of an aborted old study. No pilot is added.

## Plan

256 generation-seed blocks, 10 task families, 2 counterfactual twins, 2 arms:
author_raw and strong_control. 10,240 episodes. Blocks 30000–30255 replace the
exposed 20000–20255 range. Both arms see the same case and paired model seed.
Hypothesis margins, primary safe_success, tool-work cap, 6 turns and the 768-token
per-turn output cap are unchanged. Request reasoning_budget_tokens remains 769.

## Observed output-limit outcomes

A recognized length/limit finish with no strictly valid action in message.content
terminates the episode as GENERATION_LIMIT. Retain that assigned trial and its
actual usage in every relevant denominator. Do not retry it. Do not search
reasoning_content for a substitute action, proof, answer, or receipt.

If content already contains a complete action, run the unmodified strict parser
and grader; no JSON repair is performed. Preserve generation_limit=true and
separately expose output_budget_exhausted for no-action failures.

The same rule applies to both arms. A failure cannot become a success just
because it is now accounted for. Independent replay checks both the label and
token totals against the recorded ProviderReply.

## Boundaries

Neutral transport qualification retains its original 16 tests and no-length
criterion before sealing. Genuine connection/provider faults still pause and
preserve evidence. Existing conservative stops on leaked control tokens, invalid
non-limit provider JSON, or the pooled protocol-error breaker remain unchanged.
This patch does not claim that every remaining backend failure is resolved.

## Control and interpretation

The unchanged strong_control text includes repeated length-padding (43 repeats
of its opening padding sentence; 8414 of 9124 characters after the padding
marker). This is disclosed as part of the actual comparison, not assumed
semantically inert. No post-hoc removal from the control is made here.
Results target these two frozen instruction packages, model, tools and budgets.
They do not isolate a universal semantic operator or establish AGI.

## Prior observations and historical record

The previous aborted study produced one strong_control lineage reply with empty
content and 3084 characters of reasoning_content at the 768 output cap. It is
used only for software regression tests. Its sealed results are not altered or
pooled into the new study. The new local prospective seal discloses prior data.

## Runtime and reproducibility

Production LION 8772 lifecycle code is unchanged. Only the dedicated research
endpoint is used for generations. Separate ports still share GPU/CPU/RAM;
no guarantee of zero production latency impact is made. Do not run simultaneous
studies or copy an old STUDY_STATE.json. Source/policy hashes protect the new
seal; resume only its unchanged assignments. No output-limit failure is retried.

See README.md, BUILD_REPORT.md and docs/RUNTIME_7874_ANALYSIS.md. Historical
protocol is preserved under docs/history, not overwritten as an earlier result.
