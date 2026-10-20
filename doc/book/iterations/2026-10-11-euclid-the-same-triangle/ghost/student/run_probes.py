"""Bounded, windowless Godot runs. Does not import/repair or modify source."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[5]
GODOT = Path('C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
manifest = json.loads((HERE / 'pre_run_manifest.json').read_text(encoding='utf-8'))
for name, expected in manifest['sha256'].items():
    assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == expected, f'Changed since freeze: {name}'
probe = sys.argv[1]
assert probe in ('primary', 'shear')
script = f'res://doc/book/iterations/2026-10-11-euclid-the-same-triangle/ghost/student/{probe}_probe.gd'
command = [str(GODOT), '--headless', '--path', str(ROOT), '--xr-mode', 'off', '--audio-driver', 'Dummy', '--script', script, '--', '--no-bridges']
start = datetime.now(timezone.utc).isoformat()
try:
    completed = subprocess.run(command, cwd=ROOT, timeout=90, capture_output=True,
                               text=True, encoding='utf-8', errors='replace',
                               creationflags=subprocess.CREATE_NO_WINDOW)
    stdout, stderr, code, timed_out = completed.stdout, completed.stderr, completed.returncode, False
except subprocess.TimeoutExpired as exc:
    stdout = exc.stdout or b''
    stderr = exc.stderr or b''
    stdout = stdout.decode('utf-8', errors='replace') if isinstance(stdout, bytes) else stdout
    stderr = stderr.decode('utf-8', errors='replace') if isinstance(stderr, bytes) else stderr
    code, timed_out = None, True
(HERE / f'{probe}.stdout.log').write_text(stdout, encoding='utf-8')
(HERE / f'{probe}.stderr.log').write_text(stderr, encoding='utf-8')
record = {'command': command, 'started_at_utc': start, 'finished_at_utc': datetime.now(timezone.utc).isoformat(),
          'exit_code': code, 'timed_out': timed_out, 'timeout_seconds': 90,
          'creationflags': 'subprocess.CREATE_NO_WINDOW', 'encoding': 'utf-8',
          'stdout_sha256': hashlib.sha256((HERE / f'{probe}.stdout.log').read_bytes()).hexdigest(),
          'stderr_sha256': hashlib.sha256((HERE / f'{probe}.stderr.log').read_bytes()).hexdigest()}
(HERE / f'{probe}_execution.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
print(json.dumps(record, indent=2))
print(stdout[-10000:])
print(stderr[-10000:])
