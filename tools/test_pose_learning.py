"""Run real classifier and museum adapter assertions in native Godot."""
from pathlib import Path
import subprocess, sys
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-teach-a-sphere'
if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'tests.json').unlink(missing_ok=True)
    with (OUT / 'tests-engine.log').open('w', encoding='utf-8') as log:
        try:
            result = subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless', '--xr-mode', 'off', '--audio-driver', 'Dummy', '--path', str(ROOT), '--script', 'res://tools/probes/pose_learning_test.gd', '--', '--no-bridges'], stdout=log, stderr=subprocess.STDOUT, timeout=60, creationflags=0x08000000)
            code = result.returncode
        except subprocess.TimeoutExpired:
            code = 124
    lines = (OUT / 'tests-engine.log').read_text(encoding='utf-8', errors='replace').splitlines()
    print('\n'.join(x for x in lines if any(t in x for t in ['POSE ', 'Error', 'ERROR', 'SCRIPT', 'Parse', 'at:']))[-9000:])
    if not (OUT / 'tests.json').exists(): code = code or 1
    raise SystemExit(code)
