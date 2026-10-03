"""Read-only llama.cpp metadata and per-request prompt-fit checks.

No server configuration is changed. No generation, shortening of a policy, or
model selection occurs here. This guards the *model backend*, not LION's agent
runtime or mission broker. Server metadata is evidence, not remote attestation.
"""
from __future__ import annotations
from copy import deepcopy
from time import monotonic
from urllib.parse import urlsplit, urlunsplit
from .util import digest


def runtime_metadata(props: dict) -> dict:
    from .providers import ProviderError
    generation = props.get('default_generation_settings', {})
    if not isinstance(generation, dict):
        raise ProviderError('LLAMA_METADATA_UNSUPPORTED: default_generation_settings is not an object')
    n_ctx = generation.get('n_ctx')
    slots = props.get('total_slots')
    if type(n_ctx) is not int or n_ctx < 1:
        raise ProviderError('LLAMA_CONTEXT_UNKNOWN: /props did not report per-slot default_generation_settings.n_ctx')
    if slots is not None and (type(slots) is not int or slots < 1):
        raise ProviderError('LLAMA_METADATA_UNSUPPORTED: invalid total_slots')
    # n_ctx in default_generation_settings is the slot context, not a total to divide.
    template = props.get('chat_template')
    if not isinstance(template, str) or not template:
        raise ProviderError('LLAMA_TEMPLATE_UNKNOWN: /props did not expose the chat template')
    params = generation.get('params', {})
    return {
        'context_tokens_per_slot': n_ctx,
        'total_slots': slots,
        'build_info': props.get('build_info'),
        'chat_template_sha256': digest(template),
        'model_path_sha256': digest(props.get('model_path')),
        'reasoning_budget_reported': params.get('reasoning_budget') if isinstance(params, dict) else None,
        'scope': 'server-reported metadata; no GGUF content hash or process attestation',
    }


class LlamaGuard:
    """Guard a single-model /v1 adapter using that same server's root endpoints."""
    def __init__(self, config: dict):
        from .providers import HTTPProvider, ProviderError
        parsed = urlsplit(config['url'])
        if parsed.path.rstrip('/') != '/v1':
            raise ProviderError('LLAMA_URL: expected a direct llama-server base URL ending in /v1')
        root_cfg = deepcopy(config)
        root_cfg.pop('llama_cpp_guard', None)
        root_cfg.pop('llama_runtime_pin', None)
        # This nested client only reads metadata and tokenizes, never generates.
        root_cfg.pop('llama_reasoning_budget_policy', None)
        root_cfg['url'] = urlunsplit((parsed.scheme, parsed.netloc, '', '', ''))
        self.http = HTTPProvider(root_cfg)
        self.config = config
        self.pinned = config.get('llama_runtime_pin')
        self.margin = config.get('llama_context_margin', 64)
        if type(self.margin) is not int or self.margin < 32:
            raise ProviderError('LLAMA_MARGIN: use an integer of at least 32 tokens')

    def _request(self, path: str, body: dict | None, deadline: float | None) -> dict:
        from .providers import ProviderError
        if deadline is not None:
            remaining = deadline - monotonic()
            if remaining <= 0:
                raise ProviderError('LLAMA_GUARD_TIMEOUT: episode budget exhausted')
            self.http.remaining_seconds = remaining
        elif hasattr(self.http, 'remaining_seconds'):
            del self.http.remaining_seconds
        return self.http._request(path, body, timeout=10)

    def inspect(self, deadline: float | None = None) -> dict:
        from .providers import ProviderError
        metadata = runtime_metadata(self._request('/props', None, deadline))
        if self.pinned is not None and metadata != self.pinned:
            raise ProviderError('LLAMA_RUNTIME_CHANGED: context/template/build metadata differs from the sealed configuration')
        self.pinned = metadata
        return metadata

    def check(self, messages: list[dict], max_tokens: int, seconds: float | None = None) -> dict:
        from .providers import ProviderError
        if type(max_tokens) is not int or max_tokens < 1:
            raise ProviderError('LLAMA_TOKEN_BUDGET: max_tokens must be positive')
        deadline = monotonic() + seconds if seconds is not None else None
        metadata = self.inspect(deadline)
        request = {'model': self.config['model'], 'messages': messages,
                   'add_generation_prompt': True}
        rendered = self._request('/apply-template', request, deadline)
        prompt = rendered.get('prompt')
        if not isinstance(prompt, str):
            raise ProviderError('LLAMA_TEMPLATE_UNSUPPORTED: /apply-template did not return prompt')
        tokenized = self._request('/tokenize', {'content': prompt, 'add_special': True,
                                                'parse_special': True, 'with_pieces': False}, deadline)
        tokens = tokenized.get('tokens')
        if not isinstance(tokens, list) or not all(type(x) is int for x in tokens):
            raise ProviderError('LLAMA_TOKENIZER_UNSUPPORTED: expected integer token IDs')
        count = len(tokens)
        required = count + max_tokens + self.margin
        capacity = metadata['context_tokens_per_slot']
        check = {'method': 'server apply-template + tokenize, special tokens, conservative margin',
                 'prompt_tokens_checked': count, 'max_completion_tokens': max_tokens,
                 'margin_tokens': self.margin, 'required_tokens': required,
                 'context_tokens_per_slot': capacity, 'fits': required <= capacity,
                 'rendered_prompt_sha256': digest(prompt), 'runtime': metadata}
        if required > capacity:
            raise ProviderError(f'LLAMA_CONTEXT_TOO_SMALL: prompt={count} + output={max_tokens} + margin={self.margin} = {required}; server per-slot context={capacity}. No prompt was shortened; no generation was sent. Review server capacity; do not score this as heuristic failure.')
        return check
