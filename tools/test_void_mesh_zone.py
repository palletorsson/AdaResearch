"""Exercise the museum's mesh threshold in the real Triangle tower floor."""
from pathlib import Path
import json
import os
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-18-void-mesh-zone'
OUT.mkdir(parents=True, exist_ok=True)
subprocess.run([sys.executable, str(ROOT/'tools/test_void_game.py'), '--reuse', '--stage-only', '--out='+str(OUT)], cwd=ROOT, check=True)
stage = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
for rendered in [False, True] if '--capture' in sys.argv else [False]:
    command = [os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--no-window' if rendered else '--headless', '--path', str(stage),
        '--rendering-method', 'mobile', '--xr-mode', 'off', '--fixed-fps', '60',
        '--script', 'res://tools/probes/void_mesh_zone_probe.gd', '--', '--out='+str(OUT)]
    if rendered: command += ['--capture']
    log_path = OUT / ('capture.log' if rendered else 'engine.log')
    with log_path.open('w',encoding='utf-8') as log:
        result = subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=180,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    log = log_path.read_text(encoding='utf-8',errors='replace')
    assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-6000:]
    receipt = json.loads((OUT/('capture-checks.json' if rendered else 'checks.json')).read_text(encoding='utf-8'))
    assert receipt['passed'],receipt
    print(f"{len(receipt['checks'])} {'rendered' if rendered else 'desktop/XR'} mesh zone checks passed",flush=True)
