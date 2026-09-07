#!/usr/bin/env python3
"""Public command interface for an assigned isolated process simulation."""
import json
import sys
from lab import client

try:
    if len(sys.argv) != 4:
        raise ValueError('Usage: client.py RUN EP JSON')
    req = json.loads(sys.argv[3])
    if not isinstance(req, dict):
        raise ValueError('JSON must be an object')
    result = client(sys.argv[1], sys.argv[2], req)
except (ValueError, TypeError, KeyError) as exc:
    result = {'ok': False, 'error': 'CLIENT_INPUT_ERROR', 'message': str(exc)}
print(json.dumps(result, ensure_ascii=False))
