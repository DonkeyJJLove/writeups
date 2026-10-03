from pathlib import Path

from heuristic_lab.research_runtime import _clone_research_command
from heuristic_lab.grading import parse_response_audited


def test_clone_research_command_isolates_port_context_and_hardens_gptoss_transport():
    prod={
        'Name':'llama-server.exe',
        'ExecutablePath':'C:/Program Files/LION/llama-server.exe',
        'CommandLine':'"C:/Program Files/LION/llama-server.exe" -m "C:/Models/model.gguf" --host 127.0.0.1 --port 8772 --device Vulkan0 -ngl 99 -c 4096 -np 1 -n 384 --jinja --reasoning-budget 0'
    }
    args=_clone_research_command(prod,8773,8192)
    assert '--port' in args and args[args.index('--port')+1]=='8773'
    assert '-c' in args and args[args.index('-c')+1]=='8192'
    assert '--host' in args and args[args.index('--host')+1]=='127.0.0.1'
    assert '-m' in args and 'model.gguf' in args[args.index('-m')+1]
    assert '--jinja' in args
    assert '--no-jinja' not in args
    assert '--chat-template' not in args  # use checkpoint metadata template
    assert '--reasoning' in args and args[args.index('--reasoning')+1]=='off'
    assert '--reasoning-format' in args and args[args.index('--reasoning-format')+1]=='auto'


def test_observed_llama_envelope_is_semantic_action_not_protocol_failure():
    raw='{"kind":"final","tool_name":"none","args":{"response":"7"},"decision":"none","answer":null,"evidence":[],"confidence":0.9,"status":"SUPPORTED","reason":"observed"}'
    action,audit=parse_response_audited(raw)
    assert action['kind']=='final'
    assert action['decision']=='answer'
    assert action['answer']==7
    assert audit['normalized']


def test_tool_none_is_model_action_not_transport_failure():
    raw='{"kind":"tool","tool_name":"none","args":{},"decision":"none","answer":null,"evidence":[],"confidence":0,"status":"UNKNOWN","reason":"x"}'
    action,audit=parse_response_audited(raw)
    assert action=={'kind':'tool','name':'none','args':{}}
    assert not audit['normalized']
