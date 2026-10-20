"""Verify and render the slow Void sky using the actual isolated Godot project."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-18-void-rose-violet-sky'
OUT.mkdir(parents=True, exist_ok=True)
subprocess.run([sys.executable, str(ROOT / 'tools/test_void_game.py'), '--reuse', '--stage-only', '--out=' + str(OUT)], cwd=ROOT, check=True)
stage = Path((ROOT / 'ada_run/void-game-test/latest.txt').read_text().strip()) / 'source'
shutil.copy2(ROOT / 'tools/probes/void_sky_probe.gd', stage / 'tools/probes/void_sky_probe.gd')
command = [os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
           '--no-window', '--path', str(stage), '--rendering-method', 'mobile', '--xr-mode', 'off',
           '--script', 'res://tools/probes/void_sky_probe.gd', '--', '--capture', '--out=' + str(OUT)]
with (OUT / 'engine.log').open('w', encoding='utf-8') as stream:
    result = subprocess.run(command, cwd=stage, stdout=stream, stderr=subprocess.STDOUT, timeout=120,
                            creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
log = (OUT / 'engine.log').read_text(encoding='utf-8', errors='replace')
assert result.returncode == 0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log, log[-6000:]
receipt = json.loads((OUT / 'checks.json').read_text())
assert receipt['passed'], receipt
print(f"{len(receipt['checks'])} sky checks passed; Mobile phase captures saved to {OUT}")
