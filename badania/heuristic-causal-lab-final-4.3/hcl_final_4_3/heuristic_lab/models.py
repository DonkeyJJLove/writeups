"""Public observations and private grading data are intentionally separate."""
from __future__ import annotations
from dataclasses import dataclass, asdict
from typing import Any
from .util import digest

@dataclass(frozen=True)
class Case:
    case_id: str
    cluster: int
    family: str
    twin: int
    opening: str
    public: dict[str, Any]
    private: dict[str, Any]

    @property
    def public_hash(self) -> str:
        return digest({"opening":self.opening,"public":self.public})

    def to_dict(self) -> dict:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: dict) -> "Case":
        return cls(**data)

@dataclass
class Observation:
    data: dict
    receipt_id: str
    attests: Any = None
    conclusive: bool = False

@dataclass
class ProviderReply:
    text: str
    usage: dict
    metadata: dict
