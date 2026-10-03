"""Small exact reference oracles. Never sent to the tested model.

These are deliberately independent of the tool algorithms: exhaustive assignment,
row-subset and word enumeration rather than partition/row-reduction/frontier DP.
"""
from __future__ import annotations
from itertools import product


def cnf_count(problem: dict) -> int:
    n = problem["n"]
    return sum(all(any(bool(mask & (1 << (abs(x)-1))) == (x>0) for x in clause)
                   for clause in problem["clauses"]) for mask in range(1 << n))

def xor_count(problem: dict) -> int:
    return sum(all(sum((mask >> j)&1 for j in row["variables"]) % 2 == row["rhs"]
                   for row in problem["rows"]) for mask in range(1 << problem["n"]))

def word_count(problem: dict) -> int:
    return sum(all(pat not in "".join(bits) for pat in problem["forbidden"])
               for bits in product("01",repeat=problem["length"]))

def cover_count(problem: dict) -> int:
    rows = problem["rows"]
    if not problem["labeled"]:
        rows = [list(x) for x in sorted({tuple(sorted(r)) for r in rows})]
    total = 0
    for mask in range(1 << len(rows)):
        counts = [0] * problem["n"]
        for i,row in enumerate(rows):
            if (mask >> i)&1:
                for c in row:
                    counts[c] += 1
        total += int(all(c==1 for c in counts))
    return total

COUNT_ORACLES = {"cnf":cnf_count,"xor":xor_count,"words":word_count,"cover":cover_count}


def workflow_oracle(family: str, payload: dict) -> dict:
    """Derive expected outcome from case data, not from the treatment/arm."""
    if family == "authority":
        p = payload["packet"]
        policy = p["policy"]
        return {"decision":"execute" if p["request"]["recipient"] in policy["allowed_recipients"] else "abstain",
                "answer":p["record"]["quantity"] if p["request"]["recipient"] in policy["allowed_recipients"] else None,
                "reason_code":"unauthorized"}
    if family == "lineage":
        p = payload["packet"]
        roots = {r["root"] for r in p["reports"] if r["value"] == p["claim_value"]}
        yes = len(roots) >= p["contract"]["required_independent_roots"]
        return {"decision":"answer" if yes else "abstain", "answer":p["claim_value"] if yes else None,
                "reason_code":"insufficient_independence"}
    if family == "state_update":
        p = payload["packet"]
        active = {x["id"]:x for x in p["events"] + payload.get("updates",{}).get("events",[])}
        # Explicit revision relation, not physical order of observations.
        removed = {x["supersedes"] for x in active.values() if x.get("supersedes") is not None}
        events = [x for x in active.values() if x["id"] not in removed]
        delta = sum(x["change"] for x in events if x["referent"] == p["request"]["referent"])
        return {"decision":"answer", "answer":p["request"]["initial"]+delta, "reason_code":None}
    if family == "recovery":
        backup = payload["backup"]
        ok = backup["service_status"] == "OK"
        return {"decision":"answer" if ok else "abstain", "answer":backup.get("value") if ok else None,
                "reason_code":"missing_observation"}
    if family == "bounded_evidence":
        p = payload["packet"]
        # Contract permits only an attestation for the named finite universe.
        c = p["certificate"]
        ok = c["status"] == "COMPLETE" and set(c["checked"]) == set(p["request"]["domain"]) and not c["failures"]
        return {"decision":"answer" if ok else "abstain", "answer":True if ok else None,
                "reason_code":"incomplete_certificate"}
    if family == "global_constraint":
        p = payload["packet"]
        amount = sum(x["amount"] for x in p["allocations"] if x["pool"]==p["request"]["pool"])
        ok = amount <= p["capacity"]
        return {"decision":"execute" if ok else "abstain", "answer":amount if ok else None,
                "reason_code":"global_capacity"}
    raise ValueError(f"Unknown workflow oracle: {family}")
