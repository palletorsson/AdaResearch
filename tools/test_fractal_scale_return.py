"""Test production tree readings using a real renderer for MultiMesh readback."""
from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
GODOT = Path('C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')

if __name__ == '__main__':
    # Dummy/headless rendering returns identity from get_instance_transform().
    # The geometry assertions deliberately inspect the real rendered batches.
    result = subprocess.run([
        str(GODOT), '--no-window', '--rendering-method', 'gl_compatibility',
        '--path', str(ROOT), '--xr-mode', 'off', '--audio-driver', 'Dummy',
        '--log-file', 'ada_run/fractal-scale-return-engine.log',
        '--script', 'res://tools/probes/fractal_scale_return.gd',
    ], cwd=ROOT, capture_output=True, text=True, timeout=60)
    print('\n'.join(line for line in result.stdout.splitlines() if line.startswith('READINGS ')))
    if result.returncode:
        print(result.stderr)
        raise SystemExit(result.returncode)
    report = json.loads((ROOT/'ada_run/fractal_scale_return_tests.json').read_text(encoding='utf-8'))
    assert report['passed'] and not report['failures'], report
    assert 'SCRIPT ERROR' not in result.stderr + result.stdout
    print(f"Tree readings: {len(report['checks'])} checks passed (OpenGL, supplied XR poses).")
