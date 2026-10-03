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
set "H=%P%\hcl_final_4_3"

echo Staging full HCL research package, including runs/results/study state...
git add -- "%P%\README.md" "%P%\.gitignore" "%P%\artifacts" "%P%\STAGE_PROJECT.cmd"
if exist "%H%" git add -- "%H%"
if exist "%H%\runs" git add -- "%H%\runs"
if exist "%H%\results" git add -- "%H%\results"
for %%F in ("%H%\STUDY_STATE*.json") do if exist "%%~fF" git add -- "%%~fF"

echo.
echo HCL status after staging:
git status --short -- "%P%"
echo.
echo If the list is correct:
echo   git commit -m "research: track HCL runs results and study state"
echo   git push origin master
endlocal
