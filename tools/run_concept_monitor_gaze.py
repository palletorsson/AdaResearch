"""Check gaze-triggered playback, including the actual rendered monitor texture."""
from pathlib import Path
import hashlib
import json
import os
import subprocess

root = Path(__file__).resolve().parents[1]
out = root / 'doc/book/iterations/2026-10-04-construction-revealed'
protected = ['commons/artifacts/resolution_colonnade/resolution_totem.gd',
             'commons/artifacts/resolution_colonnade/gallery.gd',
             'commons/maps/Point_Trace/map_data.json']
before = {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in protected}
with (out / 'gaze-engine.log').open('w', encoding='utf-8') as log:
    result = subprocess.run([
        'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe',
        '--path', str(root), '--xr-mode', 'off', '--no-window',
        '--rendering-method', 'gl_compatibility',
        '--script', 'res://tools/probes/concept_monitor_gaze.gd'],
        cwd=root, stdout=log, stderr=subprocess.STDOUT, timeout=60,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
after = {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in protected}
report = json.loads((out / 'gaze-report.json').read_text(encoding='utf-8'))
print('Exit:', result.returncode, 'Checks:', len(report['checks']), 'Passed:', report['passed'])
print('Source generator, gallery and map unchanged:', before == after)
tail = '\n'.join((out / 'gaze-engine.log').read_text(encoding='utf-8', errors='replace').splitlines()[-28:])
print(tail.encode('ascii', errors='backslashreplace').decode('ascii'))
raise SystemExit(0 if result.returncode == 0 and report['passed'] and before == after else 1)
