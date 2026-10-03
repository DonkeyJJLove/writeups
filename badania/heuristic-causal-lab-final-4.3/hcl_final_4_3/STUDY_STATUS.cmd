@echo off
setlocal
cd /d "%~dp0"
python -u -m heuristic_lab.study_runner --status
exit /b %ERRORLEVEL%
