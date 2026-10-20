"""Real Primitives floors: source artifacts, editor poses, walking and descent."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-19-void-primitives-complete'
OUT.mkdir(parents=True, exist_ok=True)
if '--staged' not in sys.argv:
    subprocess.run([sys.executable, str(ROOT/'tools/test_void_game.py'), '--reuse',
                    '--stage-only', '--out='+str(OUT)], cwd=ROOT, check=True)
stage = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
shutil.copy2(ROOT/'tools/probes/void_primitives_probe.gd', stage/'tools/probes/void_primitives_probe.gd')
command = [os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
           '--no-window' if '--capture' in sys.argv else '--headless', '--path',str(stage),
           '--rendering-method','mobile','--xr-mode','off','--fixed-fps','60',
           '--script','res://tools/probes/void_primitives_probe.gd','--','--out='+str(OUT)]
if '--capture' in sys.argv: command.append('--capture')
with (OUT/'engine.log').open('w',encoding='utf-8') as log:
    result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=600,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
text = (OUT/'engine.log').read_text(encoding='utf-8',errors='replace')
assert result.returncode == 0 and 'SCRIPT ERROR' not in text and '\nERROR:' not in text, text[-10000:]
receipt = json.loads((OUT/'checks.json').read_text())
assert receipt['passed'], receipt
print(f"{len(receipt['checks'])} native Primitives checks passed")
