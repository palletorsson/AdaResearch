import pathlib
import subprocess
import sys

OUT = pathlib.Path(__file__).resolve().parent
ROOT = OUT.parents[2]
render = '--screenshots' in sys.argv
with (OUT / ('render.log' if render else 'probe.log')).open('w', encoding='utf-8') as log:
    args = [
        'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe',
        '--xr-mode', 'off', '--path', str(ROOT), '--log-file', str(OUT / 'engine.log'),
        '--script', 'res://doc/space/randomness-portals-2026-09-16/probe.gd',
    ]
    args += ['--rendering-method', 'mobile', '--resolution', '1280x800', '--', '--screenshots'] if render else ['--headless']
    result = subprocess.run(args, stdout=log, stderr=log, timeout=130, creationflags=subprocess.CREATE_NO_WINDOW)
print('portal probe:', result.returncode)
raise SystemExit(result.returncode)
