"""Request-scoped llama.cpp reasoning-budget override, backed by the A/B diagnostic.

Do not confuse this with extending the total completion cap or disabling reasoning.
The separate forced-end counter is placed beyond the common completion limit.
"""
from __future__ import annotations

BUDGET_POLICY = "above_completion_cap_v1"
INT32_MAX = 2**31 - 1


def request_reasoning_budget(config: dict, max_tokens: int) -> int | None:
    """Return an explicit cap+1 override only for an opted-in llama.cpp provider.

    A literal -1 is deliberately not sent: the target build treats it as
    inheritance of the server default. The completion cap remains unchanged.
    """
    policy = config.get("llama_reasoning_budget_policy")
    if policy is None:
        return None
    if policy != BUDGET_POLICY:
        raise ValueError("Unsupported llama_reasoning_budget_policy: " + repr(policy))
    if config.get("type") != "openai_compatible" or config.get("llama_cpp_guard") is not True:
        raise ValueError("llama_reasoning_budget_policy requires an explicit llama_cpp_guard provider")
    if type(max_tokens) is not int or not (1 <= max_tokens < INT32_MAX):
        raise ValueError("Completion cap must be a positive integer below INT32_MAX")
    return max_tokens + 1
