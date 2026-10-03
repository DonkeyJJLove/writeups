# HCL 4.3 build report

HCL 4.3 is a full confirmatory study runner, not a pilot.

## RCA addressed

The target GPT-OSS/llama.cpp stack passed several strict-schema qualification requests and then degenerated under a realistic-length strict decoder schema (`finish_reason=length`). The preregistered `json_object` fallback returned a semantically valid compact tool object (`kind`, `tool_name`, `args`) that v4.2 rejected only because its application parser required either the nine-field flat envelope or the legacy `name` form.

## v4.3 transport

- Decoder transport: `response_format={type: json_object}` only.
- No strict decoder JSON Schema candidate.
- Application parser accepts a preregistered, lossless alias set: `tool_name|name|tool`, `args|arguments|parameters`, and displaced scalar final answers.
- Missing evidence never becomes evidence; missing status becomes `UNKNOWN`; missing confidence becomes `0`; no execute decision or tool name is invented.
- The same canonicalizer is frozen for both treatment arms.
- 16 treatment-blind realistic-length live checks must all pass before the full study is sealed.
- The full 10,240-trial confirmatory design and arm-blind transport circuit breaker remain unchanged.

## Software validation

See test output generated for the packaged artifact. No live heuristic result is fabricated by this build report.
