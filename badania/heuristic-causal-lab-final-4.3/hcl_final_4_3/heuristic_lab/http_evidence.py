"""Local, opt-in byte evidence for inference HTTP calls, before parsing.

No HTTP authentication headers or environment values are persisted. Request
bodies may contain full prompts; keep this directory private. Every attempt has
its own directory and receipt; existing attempts are never overwritten.
"""
from __future__ import annotations
from datetime import datetime, timezone
from hashlib import sha256
import json
from pathlib import Path
from uuid import uuid4


class HTTPEvidence:
    def __init__(self, root: str, path: str, payload: bytes, label: str | None = None):
        now=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
        self.folder=Path(root)/(now+'_'+uuid4().hex[:12])
        self.folder.mkdir(parents=True,exist_ok=False)
        self.meta={"endpoint_path":path,"label":label,"started_utc":now,
                   "request_sha256":sha256(payload).hexdigest(),
                   "response_received":False,"scope":"local raw HTTP payload; headers excluded"}
        (self.folder/'request.json').write_bytes(payload)
        self.flush()

    def response(self, raw: bytes, status: int = 200, truncated: bool = False) -> None:
        (self.folder/'response.raw').write_bytes(raw)
        self.meta.update(response_received=True,http_status=status,response_sha256=sha256(raw).hexdigest(),
                         response_bytes=len(raw),response_truncated=truncated)
        self.flush()

    def failure(self, error: str) -> None:
        self.meta['transport_exception']=error
        self.flush()

    def flush(self) -> None:
        # Only this receipt is updated while a call is in flight. Request and
        # response bytes are immutable once recorded; each call has a new folder.
        (self.folder/'receipt.json').write_text(json.dumps(self.meta,ensure_ascii=False,indent=2),encoding='utf-8')
