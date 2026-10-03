@echo off
setlocal
cd /d "%~dp0"
if errorlevel 1 exit /b 1
if not exist "heuristic_lab\study_runner.py" (
    echo STOP: Put this CMD file in the project folder containing heuristic_lab and RUN_STUDY.cmd.
    exit /b 2
)
REM One-time entry point: preserve the invalid old run, require the verified new methods.
python -c "import sys; from pathlib import Path; import heuristic_lab; from heuristic_lab.util import ROOT,ASSETS,read_json,digest,source_manifest; check=lambda ok,msg: None if ok else sys.exit('STOP: '+msg); check(ROOT.resolve()==Path.cwd().resolve(), 'Python loaded another project. Nothing changed.'); check(heuristic_lab.__version__=='4.3.3', 'Expected accounting fix 4.3.3. Nothing changed.'); current=digest(source_manifest()); check(current=='ce703e5ab2c71ddc85de9161406e4c9165634ea17f04a8497ded7003932e6271', 'Source/policy hashes differ from the verified accounting fix. Nothing changed.'); c=read_json(ASSETS/'configs'/'study.json'); check(digest(c)=='3b80109ea5ad4626348571c8a7f73c17671eb665d438a893de72d569ed0cfc47', 'configs/study.json differs from the verified full-study configuration. Nothing changed.'); state_path=ROOT/'STUDY_STATE.json'; check(state_path.is_file(), 'No old state pointer. Use RUN_STUDY.cmd for a clean project.'); s=read_json(state_path); check(s.get('status')=='INVALID_INSTRUMENT', 'This one-time helper is only for INVALID_INSTRUMENT. For active/completed studies use RUN_STUDY.cmd.'); check(isinstance(s.get('study'),str) and bool(s['study']), 'Missing old study path. Nothing changed.'); old_path=(ROOT/s['study']).resolve(); check(old_path.is_relative_to(ROOT.resolve()), 'Old study is outside this project. Nothing changed.'); old=read_json(old_path/'manifest.json'); check(old.get('evaluation_kind')=='LIVE_MODEL_STUDY', 'State does not reference a live study. Nothing changed.'); check(old.get('source_hash') and old['source_hash']!=current, 'Old study already used this source version. No automatic restart under the same methods.'); oc=old['config']; check(type(oc.get('seed_start')) is int and type(oc.get('clusters')) is int and oc['clusters']>0, 'Cannot verify old seed interval. Nothing changed.'); check(max(c['seed_start'],oc['seed_start'])>=min(c['seed_start']+c['clusters'],oc['seed_start']+oc['clusters']), 'New and old seed intervals overlap. Nothing changed.'); print('PASS: verified HCL 4.3.3; confirmatory; 256 blocks; 10240 episodes; seeds 30000..30255.'); print('Old invalid study retained at:',old_path); print('The existing runner will archive ONLY its state pointer and create a new prospective study.')"
if errorlevel 1 (
    echo No new study was started. No files or services were changed by the check.
    exit /b 2
)
python -u -m heuristic_lab.study_runner --new-study
exit /b %ERRORLEVEL%
