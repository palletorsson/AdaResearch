"""Render and verify the existing column generator revealed as a sequence of operations."""
from pathlib import Path
import hashlib
import json
import os
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-04-construction-revealed'
OUT.mkdir(parents=True, exist_ok=True)
paths = ['commons/artifacts/resolution_colonnade/resolution_totem.gd',
         'commons/artifacts/resolution_colonnade/gallery.gd',
         'commons/maps/Point_Trace/map_data.json']
before = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths}
engine = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
with (OUT / 'engine.log').open('w', encoding='utf-8') as log:
    result = subprocess.run([engine, '--path', str(ROOT), '--xr-mode', 'off', '--no-window',
         '--rendering-method', 'gl_compatibility', '--script', 'res://tools/probes/construction_monitor.gd'],
         cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=120,
         creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
after = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths}
(OUT / 'protected-sources.json').write_text(json.dumps({'before': before, 'after': after,
    'unchanged': before == after}, indent=2), encoding='utf-8')
print('Exit:', result.returncode, 'Existing source unchanged:', before == after)
print('\n'.join((OUT / 'engine.log').read_text(encoding='utf-8', errors='replace').splitlines()[-20:]))
raise SystemExit(result.returncode)
