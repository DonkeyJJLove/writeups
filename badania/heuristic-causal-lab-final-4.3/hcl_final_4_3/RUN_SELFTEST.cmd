@echo off
cd /d "%~dp0"
set "OUT=results\selftest_%RANDOM%_%RANDOM%"
python -m heuristic_lab smoke --output "%OUT%"
if errorlevel 1 (
  echo Self-test failed. No live model was used.
) else (
  echo SOFTWARE SELF-TEST ONLY. This is not evidence of heuristic quality.
  echo Report: %OUT%\report.html
)
pause
