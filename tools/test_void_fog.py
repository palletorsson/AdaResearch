"""Exercise Void atmosphere with the full project's real autoloads and camera."""
from pathlib import Path
import json
import os
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-18-void-fog-runtime'
OUT = Path(next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--out=')), str(OUT))).resolve()
OUT.mkdir(parents=True, exist_ok=True)
renderer = next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--renderer=')), 'forward_plus')
baseline = '--baseline' in sys.argv
command = [os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
           '--no-window' if '--capture' in sys.argv else '--headless', '--path', str(ROOT),
           '--rendering-method', renderer, '--xr-mode', 'off',
           'res://tools/probes/void_fog_probe.tscn', '--', '--out=' + str(OUT)]
command += [a for a in ['--capture', '--baseline'] if a in sys.argv]
log_path = OUT / ('before.log' if baseline else 'engine.log')
with log_path.open('w', encoding='utf-8') as stream:
    result = subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT,
                            timeout=120, creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
log = log_path.read_text(encoding='utf-8', errors='replace')
assert result.returncode == 0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log, log[-7000:]
receipt = json.loads((OUT / ('before.json' if baseline else 'checks.json')).read_text())
if not baseline:
    assert receipt['passed'], receipt
print(json.dumps(receipt, indent=2))
