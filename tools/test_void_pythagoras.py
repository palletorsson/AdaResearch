"""Check Pythagoras in the tower: carried trace, source interactions and descent."""
from pathlib import Path
import json
import os
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-18-void-pythagoras'
OUT.mkdir(parents=True, exist_ok=True)
subprocess.run([sys.executable, str(ROOT/'tools/test_void_game.py'), '--reuse', '--stage-only', '--out='+str(OUT)], cwd=ROOT, check=True)
stage = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
def run(rendered=False):
    command = [os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--no-window' if rendered else '--headless', '--path',str(stage),
        '--rendering-method','mobile','--xr-mode','off','--fixed-fps','60',
        '--script','res://tools/probes/void_pythagoras_probe.gd','--','--out='+str(OUT)]
    if rendered: command += ['--capture','--capture-only']
    log_path=OUT/('capture.log' if rendered else 'engine.log')
    with log_path.open('w',encoding='utf-8') as log:
        result=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=240,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    log=log_path.read_text(encoding='utf-8',errors='replace')
    assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-8000:]
    receipt=json.loads((OUT/('capture-checks.json' if rendered else 'checks.json')).read_text(encoding='utf-8'))
    assert receipt['passed'],receipt
    print(f"{len(receipt['checks'])} native {'rendered proof' if rendered else 'Pythagoras'} checks passed",flush=True)

if '--capture-only' not in sys.argv: run()
if '--capture' in sys.argv or '--capture-only' in sys.argv: run(True)
