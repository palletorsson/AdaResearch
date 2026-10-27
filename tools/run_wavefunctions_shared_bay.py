"""Render and check the draft shared bay without changing the live layout."""
import json
import os
import subprocess
import sys
import shutil
import time
import hashlib
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/wavefunctions-shared-bay'
sys.stdout.reconfigure(encoding='utf-8')
slot = acquire_native_slot('Wavefunctions shared working bay')
stage = stage_runtime()
draft_hash = hashlib.sha256((OUT / 'draft-rooms.json').read_bytes()).hexdigest()
if (OUT / 'checks.json').exists():
    previous = OUT / ('attempt-' + str(time.time_ns()))
    previous.mkdir()
    for source in OUT.iterdir():
        if source.is_file() and (source.suffix == '.png' or source.name in ['checks.json', 'native.log']):
            shutil.copy2(source, previous / source.name)
with (OUT / 'native.log').open('w', encoding='utf-8') as stream:
    result = subprocess.run([
        os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--no-window', '--rendering-method', 'gl_compatibility', '--xr-mode', 'off',
        '--path', str(stage), '--script', 'res://tools/probes/wavefunctions_shared_bay.gd',
        '--', '--no-bridges', '--out=' + str(OUT),
    ], cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, timeout=210,
       creationflags=subprocess.CREATE_NO_WINDOW)
log = (OUT / 'native.log').read_text(encoding='utf-8', errors='replace')
errors, shutdown = split_errors(log, 'SHARED_BAY_RESULT ', allow_shutdown=result.returncode == 0)
receipt = OUT / 'checks.json'
report = json.loads(receipt.read_text()) if receipt.exists() else dict(passed=False, failed=['No receipt'])
report.update(engine_exit=result.returncode, engine_errors=errors, shutdown_diagnostics=shutdown)
report['draft_sha256'] = draft_hash
assert hashlib.sha256((OUT / 'draft-rooms.json').read_bytes()).hexdigest() == draft_hash, 'Draft changed during this run.'
report['passed'] = bool(report['passed'] and result.returncode == 0 and not errors)
receipt.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(log[-6000:])
assert report['passed'], report
