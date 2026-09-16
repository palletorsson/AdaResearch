import json
import pathlib
import subprocess
import sys

OUT = pathlib.Path(__file__).resolve().parent
ROOT = OUT.parents[2]
GODOT = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
names = sys.argv[1:] or [row['map'] for row in json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))]
for name in names:
    with (OUT/(name+'-process.log')).open('w', encoding='utf-8') as log:
        cmd = [GODOT, '--path', str(ROOT), '--xr-mode', 'off', '--resolution', '1280x800',
               '--log-file', str(OUT/(name+'-godot.log')), '--script',
               'res://doc/space/entropy-ruin-2026-09-16/probe.gd', '--', '--map='+name, '--capture']
        try:
            result = subprocess.run(cmd, stdout=log, stderr=log, timeout=100, creationflags=subprocess.CREATE_NO_WINDOW)
            print(name, 'exit', result.returncode, flush=True)
        except subprocess.TimeoutExpired:
            print(name, 'TIMEOUT', flush=True)
