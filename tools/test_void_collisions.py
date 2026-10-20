"""Audit real staging/menu/held-mushroom collisions and observe actual player movement."""
from pathlib import Path
import json
import os
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-18-void-movement-room'
command = [os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
           '--headless' if '--headless' in sys.argv else '--no-window',
           '--audio-driver', 'Dummy', '--path', str(ROOT), '--rendering-method', 'mobile',
           '--xr-mode', 'off', '--max-fps', '90', 'res://tools/probes/void_staging_collision_probe.tscn',
           '--', '--desktop', '--no-bridges', '--out=' + str(OUT)]
baseline = '--menu-baseline' in sys.argv
if baseline:
    command.append('--menu-baseline')
stem = 'staging-menu-baseline' if baseline else 'staging-collisions'
with (OUT / (stem+'.log')).open('w', encoding='utf8') as log:
    result = subprocess.run(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                            timeout=180, creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
text = (OUT / (stem+'.log')).read_text(encoding='utf8', errors='replace')
errors = [line for line in text.splitlines() if line.startswith(('ERROR:', 'SCRIPT ERROR:'))]
(OUT/(stem+'-process.json')).write_text(json.dumps({'exit_code':result.returncode,'errors':errors},indent=2))
assert result.returncode == 0 and not errors, (result.returncode, errors)
if baseline:
    print('Menu-only staging baseline exited cleanly.')
    sys.exit(0)
receipt = json.loads((OUT / 'staging-collisions.json').read_text())
assert receipt['passed'], receipt['checks']
print(f"{len(receipt['checks'])} checks passed; {len(receipt['trials'])} real-staging movement trials.")
