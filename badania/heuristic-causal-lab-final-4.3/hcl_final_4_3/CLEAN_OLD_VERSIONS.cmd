@echo off
setlocal
cd /d "%~dp0"
echo This removes sibling HCL version directories only after verifying they are heuristic-causal-lab projects.
echo The current 4.3 directory is always kept.
python -u -m heuristic_lab.maintenance clean-old --yes
exit /b %ERRORLEVEL%
