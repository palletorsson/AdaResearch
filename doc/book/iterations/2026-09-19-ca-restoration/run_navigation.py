"""Run the bounded, read-only production route check with no visible window."""
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
paths = ['commons/scenes/endless_museum.gd', 'ada_run/em_plan.json',
         'commons/data/museum/em_plan.json', 'commons/data/map_authored.json']
def hashes():
    return {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths}
before = hashes()
command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless',
           '--path', str(ROOT), '--xr-mode', 'off', '--audio-driver', 'Dummy',
           '--log-file', str(HERE/'navigation-engine.log'), '--script',
           'res://doc/book/iterations/2026-09-19-ca-restoration/probe_navigation.gd']
with (HERE/'navigation-process.log').open('w', encoding='utf-8') as log:
    result = subprocess.run(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                            timeout=50, creationflags=subprocess.CREATE_NO_WINDOW)
after = hashes()
(HERE/'navigation-run.json').write_text(json.dumps(dict(returncode=result.returncode,
    before=before, after=after, inputs_unchanged=before==after), indent=2)+'\n', encoding='utf-8')
print('Route check:', result.returncode, 'inputs unchanged:', before==after)
print((HERE/'navigation-process.log').read_text(encoding='utf-8')[-700:])
raise SystemExit(result.returncode if before==after else 1)
