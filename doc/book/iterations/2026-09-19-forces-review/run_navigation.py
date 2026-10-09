"""Headless, read-only production routing probe; does not construct a museum hall."""
import hashlib
import json
from pathlib import Path
import subprocess
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PATHS = ['commons/scenes/endless_museum.gd', 'commons/scenes/em/em_portal_stream.gd',
         'ada_run/em_plan.json', 'commons/maps/sequences/forces.json']


def hashes():
    return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in PATHS}


before = hashes()
start = time.time()
cmd = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless', '--path', str(ROOT),
       '--xr-mode', 'off', '--audio-driver', 'Dummy', '--log-file', str(HERE / 'navigation-engine.log'),
       '--script', 'res://doc/book/iterations/2026-09-19-forces-review/probe_navigation.gd']
with (HERE / 'navigation-process.log').open('w', encoding='utf-8') as log:
    process = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT,
                               creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        code = process.wait(timeout=50)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        code = -1
record = dict(returncode=code, seconds=time.time()-start, command=cmd, before=before, after=hashes())
(HERE / 'navigation-run.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
print('Navigation exit', code)
print((HERE / 'navigation-process.log').read_text(encoding='utf-8')[-1300:])
raise SystemExit(0 if code == 0 else 1)
