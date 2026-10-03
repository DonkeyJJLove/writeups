"""Public wire-contract checks; never inspect a private answer key.

A parser returning kind=tool is not proof that a usable function call was made.
Incorrect task choices remain task outcomes; the checks here establish only the
public tool interface and the two explicitly requested transport-control actions.
"""
from __future__ import annotations
from typing import Any
from .tools import TOOL_CATALOG


def _groups(value: Any) -> bool:
    return isinstance(value,list) and bool(value) and all(
        isinstance(group,list) and bool(group) and all(type(x) is int and x>=0 for x in group)
        for group in value)


def validate_qualification_action(probe: str, action: dict) -> None:
    if action["kind"]=="tool":
        name=action.get("name"); args=action.get("args")
        if name not in TOOL_CATALOG:
            raise ValueError("QUALIFICATION_TOOL_NAME: no real tool selected: "+repr(name))
        if not isinstance(args,dict):
            raise ValueError("QUALIFICATION_TOOL_ARGS: object required")
        valid=False
        if name=="read":
            valid=set(args)=={"id"} and args["id"] in {"packet","primary","updates"}
        elif name in {"recover","enumerate","eliminate"}:
            valid=not args
        elif name=="factor":
            valid=set(args)=={"groups"} and _groups(args.get("groups"))
        elif name=="suffix":
            valid=set(args)=={"memory"} and type(args.get("memory")) is int and 0<=args["memory"]<=24
        elif name=="quotient":
            valid=set(args)=={"groups","preserve_multiplicity"} and _groups(args.get("groups")) and type(args.get("preserve_multiplicity")) is bool
        if not valid:
            raise ValueError("QUALIFICATION_TOOL_ARGS: not the public argument contract for "+name)
    elif action["kind"]!="final":
        raise ValueError("QUALIFICATION_KIND: expected tool or final")
    if probe.startswith("first_turn_") or probe=="direct_tool":
        if action != {"kind":"tool","name":"read","args":{"id":"packet"}}:
            raise ValueError("QUALIFICATION_CONTROL_ACTION: explicitly requested read(packet) was not returned")
    if probe=="direct_final":
        if action.get("kind")!="final" or action.get("decision")!="answer" or type(action.get("answer")) is not int or action["answer"]!=7:
            raise ValueError("QUALIFICATION_CONTROL_ACTION: explicitly requested final answer 7 was not returned")
