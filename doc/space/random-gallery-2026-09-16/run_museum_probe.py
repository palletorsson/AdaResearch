import pathlib
import subprocess
import sys

OUT = pathlib.Path(__file__).resolve().parent
ROOT = OUT.parents[2]
GODOT = pathlib.Path('C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
cmd = [str(GODOT), '--path', str(ROOT), '--xr-mode', 'off', '--resolution', '1280x800',
       '--log-file', str(OUT / 'museum-godot.log'), '--script',
       'res://doc/space/random-gallery-2026-09-16/museum-probe.gd', '--', '--capture']
with (OUT / 'museum-process.log').open('w', encoding='utf-8') as log:
    try:
        result = subprocess.run(cmd, stdout=log, stderr=log, timeout=160,
                                creationflags=subprocess.CREATE_NO_WINDOW)
    except subprocess.TimeoutExpired:
        print('Random gallery museum probe timed out.', flush=True)
        sys.exit(2)
print('Random gallery museum probe exit', result.returncode, flush=True)
sys.exit(result.returncode)
