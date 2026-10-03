# Windows / LION — HCL 3.0

Normal operation is one command from the extracted project directory:

```cmd
RUN_PILOT.cmd
```

Do not manually manage 8773, profile filenames, preflight filenames, or study directories.

The runner checks production LION on 8772 read-only. If the research endpoint is absent, it inspects the current `llama-server.exe` process behind 8772, clones its command line, and changes only the local endpoint to port 8773 with context 8192. The research process is stopped after the run if this invocation started it.

All study output uses unique timestamped directories under `runs/`.

Diagnostics:

```powershell
python -m heuristic_lab.runtime_cli status
python -m heuristic_lab.runtime_cli up
python -m heuristic_lab.runtime_cli down
```

Cleanup of prior extracted HCL versions:

```cmd
CLEAN_OLD_VERSIONS.cmd
```

The cleanup command verifies an HCL project marker before deletion and never deletes the current project.
