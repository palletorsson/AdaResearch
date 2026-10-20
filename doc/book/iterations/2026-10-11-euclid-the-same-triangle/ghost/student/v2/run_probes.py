from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[6]
manifest = json.loads((HERE / 'pre_run_manifest.json').read_text(encoding='utf-8'))
for name, expected in manifest['sha256'].items():
    assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == expected, name
for name, expected in manifest['initial_evidence_sha256'].items():
    assert hashlib.sha256((HERE.parent / name).read_bytes()).hexdigest() == expected, 'Initial evidence changed: ' + name
probe = sys.argv[1]
assert probe in ('primary', 'shear')
script = f'res://doc/book/iterations/2026-10-11-euclid-the-same-triangle/ghost/student/v2/{probe}_probe.gd'
command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless', '--path', str(ROOT), '--xr-mode', 'off', '--audio-driver', 'Dummy', '--script', script, '--', '--no-bridges']
started = datetime.now(timezone.utc).isoformat()
try:
    run = subprocess.run(command, cwd=ROOT, timeout=90, capture_output=True, text=True, encoding='utf-8', errors='replace', creationflags=subprocess.CREATE_NO_WINDOW)
    stdout, stderr, code, timed_out = run.stdout, run.stderr, run.returncode, False
except subprocess.TimeoutExpired as exc:
    stdout, stderr, code, timed_out = exc.stdout or b'', exc.stderr or b'', None, True
    stdout = stdout.decode('utf-8', errors='replace') if isinstance(stdout, bytes) else stdout
    stderr = stderr.decode('utf-8', errors='replace') if isinstance(stderr, bytes) else stderr
(HERE / f'{probe}.stdout.log').write_text(stdout, encoding='utf-8')
(HERE / f'{probe}.stderr.log').write_text(stderr, encoding='utf-8')
record = {'command': command, 'started_at_utc': started, 'finished_at_utc': datetime.now(timezone.utc).isoformat(), 'exit_code': code, 'timed_out': timed_out, 'timeout_seconds': 90, 'creationflags': 'subprocess.CREATE_NO_WINDOW', 'encoding': 'utf-8'}
(HERE / f'{probe}_execution.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
print(json.dumps(record, indent=2))
print(stdout[-12000:])
print(stderr[-8000:])
