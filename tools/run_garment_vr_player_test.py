"""Exercise the production VR player costume path without starting OpenXR."""
from pathlib import Path
import subprocess
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-10-dresses-on-the-vr-player'
OUT.mkdir(parents=True, exist_ok=True)
command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT),
           '--headless', '--xr-mode', 'off', '--audio-driver', 'Dummy',
           '--script', 'res://tools/probes/garment_vr_player_test.gd']
log = OUT / 'test-log.txt'
with log.open('w', encoding='utf-8') as f:
    result = subprocess.run(command, cwd=ROOT, stdout=f, stderr=subprocess.STDOUT,
                            timeout=80, creationflags=subprocess.CREATE_NO_WINDOW)
errors = [x for x in log.read_text(encoding='utf-8').splitlines() if 'SCRIPT ERROR' in x or x.startswith('FAIL ')]
print('VR player test exit:', result.returncode)
for error in errors: print(error)
raise SystemExit(result.returncode or bool(errors))
