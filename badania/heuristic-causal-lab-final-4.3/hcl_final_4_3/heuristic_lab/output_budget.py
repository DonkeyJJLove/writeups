"""Distinguish an observed output cap from a provider/connection failure.

No inference, retries or extraction from reasoning_content is performed here.
Qualification may require stop before the cap; live outcomes keep the same cap.
"""
from __future__ import annotations
from typing import Any

LIMIT_FINISH_REASONS = frozenset({"length", "limit"})

def output_cap_reached(metadata: dict[str, Any]) -> bool:
    return metadata.get("finish_reason") in LIMIT_FINISH_REASONS

def assert_qualification_finished(metadata: dict[str, Any]) -> None:
    """Retain the original pre-seal no-limit-hit qualification requirement."""
    if output_cap_reached(metadata):
        raise ValueError("QUALIFICATION_GENERATION_LIMIT: neutral transport probe reached its output cap")
