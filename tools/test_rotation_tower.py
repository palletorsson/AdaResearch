"""Verify the promoted layouts and traverse the main tower with both player rigs."""
from pathlib import Path
import json, os, subprocess, sys
from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT/'doc/book/iterations/2026-10-20-rotation-in-tower'
capture = '--capture' in sys.argv
out = REPORT/('images' if capture else 'tests')
out.mkdir(parents=True, exist_ok=True)
rooms = json.loads((ROOT/'commons/void/rooms.json').read_text())
before = json.loads((REPORT/'before-rooms.json').read_text())
promoted = json.loads((REPORT/'promoted-rooms.json').read_text())
assert promoted['floors'][:16] == before['floors'], 'Promotion changed existing curated floors'
assert rooms['floors'][16]['map']=='Trans_Rotation'
import hashlib
assert hashlib.sha256((REPORT/'promoted-rooms.json').read_bytes()).hexdigest()==json.loads((REPORT/'save-receipt.json').read_text())['revision']
for name,digest in json.loads((REPORT/'text-hashes.json').read_text()).items():
    assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,name
assert json.loads((Path.home()/'Desktop/Ada Void/rooms.json').read_text())['floors'][16] == rooms['floors'][16]
args = [os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--no-window' if capture else '--headless', '--path', str(stage_runtime()),
        '--rendering-method', 'mobile', '--xr-mode', 'off', '--fixed-fps', '60',
        '--script', 'res://tools/probes/rotation_tower_probe.gd',
        '--', '--no-bridges', '--void-start-floor=16', '--out='+str(out)]
if capture:
    args.append('--capture')
if '--verbose' in sys.argv:
    args.insert(1,'--verbose')
with (out/'engine.log').open('w', encoding='utf8') as log:
    result = subprocess.run(args, stdout=log, stderr=subprocess.STDOUT, timeout=300,
                            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log = (out/'engine.log').read_text(encoding='utf8', errors='replace')
assert result.returncode == 0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log, log[-8000:]
checks = json.loads((out/'checks.json').read_text())
assert checks['passed'], checks['failed']
print(len(checks['checks']), 'native checks passed; promotion preserved original floors; Rotation matches Desktop backup.')
