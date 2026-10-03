@echo off
setlocal EnableExtensions
for %%I in ("%~dp0..\..") do set "REPO=%%~fI"
cd /d "%REPO%" || exit /b 1

for /f "delims=" %%I in ('git rev-parse --show-toplevel 2^>nul') do set "TOP=%%I"
if not defined TOP (
  echo ERROR: not inside a Git repository.
  exit /b 2
)

set "P=badania\heuristic-causal-lab-final-4.3"

echo Staging canonical project files. Runtime runs/results/state remain ignored...
git add -- "%P%\README.md" "%P%\.gitignore" "%P%\artifacts" "%P%\STAGE_PROJECT.cmd"
if exist "%P%\hcl_final_4_3" git add -- "%P%\hcl_final_4_3"

echo.
echo HCL status after staging:
git status --short -- "%P%"
echo.
echo Review the list. Then commit and push:
echo   git commit -m "research: add Heuristic Causal Lab code and final artifacts"
echo   git push origin master
endlocal
