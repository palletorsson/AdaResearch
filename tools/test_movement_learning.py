"""Run real Godot phrase learning, ordered negative tests and XR capture."""
from pathlib import Path
import json, subprocess, sys
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-teach-a-sphere-phrase'
if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'tests.json').unlink(missing_ok=True)
    with (OUT / 'tests-engine.log').open('w', encoding='utf-8') as log:
        try:
            result = subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless', '--xr-mode', 'off', '--audio-driver', 'Dummy', '--path', str(ROOT), '--script', 'res://tools/probes/movement_learning_test.gd', '--', '--no-bridges'], stdout=log, stderr=subprocess.STDOUT, timeout=75, creationflags=0x08000000)
            code = result.returncode
        except subprocess.TimeoutExpired:
            code = 124
    lines = (OUT / 'tests-engine.log').read_text(encoding='utf-8', errors='replace').splitlines()
    if any('SCRIPT ERROR:' in line for line in lines):
        code = code or 1
        if (OUT / 'tests.json').exists():
            receipt = json.loads((OUT / 'tests.json').read_text(encoding='utf-8'))
            receipt['passed'] = False
            receipt['failures'].append('GDScript exception in engine log; see tests-engine.log')
            (OUT / 'tests.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
    print('\n'.join(x for x in lines if any(t in x for t in ['PHRASE ', 'ERROR', 'SCRIPT', 'Parse', 'at:']))[-14000:])
    if not (OUT / 'tests.json').exists(): code = code or 1
    raise SystemExit(code)
