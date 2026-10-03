@echo off
setlocal
cd /d "%~dp0"
python -u -m heuristic_lab.runtime_cli down --research-port 8773
exit /b %ERRORLEVEL%
