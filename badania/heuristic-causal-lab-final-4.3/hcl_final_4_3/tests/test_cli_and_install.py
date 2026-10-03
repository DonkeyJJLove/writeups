import json
from pathlib import Path
import subprocess
import sys
from heuristic_lab.cli import main
from heuristic_lab.util import ROOT


def test_cli_plan(capsys):
    assert main(['plan'])==0
    p=json.loads(capsys.readouterr().out)
    assert p['trials']==40 and p['max_requests']==240


def test_configure_without_network(tmp_path,capsys):
    out=tmp_path/'my.json'
    assert main(['configure','--model','local-model','--output',str(out)])==0
    assert json.loads(out.read_text())['provider']['model']=='local-model'
    assert main(['configure','--model','local-model','--output',str(out)])==2


def test_power_is_planning_not_observation(capsys):
    assert main(['power'])==0
    p=json.loads(capsys.readouterr().out)
    assert p['approximate_clusters']>1
    assert 'planning' in p['scope']


def test_stdlib_only_smoke_from_cli(tmp_path):
    result=subprocess.run([sys.executable,'-S','-m','heuristic_lab','smoke','--output',str(tmp_path/'smoke')],cwd=ROOT,text=True,capture_output=True,timeout=20)
    assert result.returncode==0,result.stderr
    assert json.loads(result.stdout)['live_model_calls']==0
    assert (tmp_path/'smoke'/'report.html').is_file()
