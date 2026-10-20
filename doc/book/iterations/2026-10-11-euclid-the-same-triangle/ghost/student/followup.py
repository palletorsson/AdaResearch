from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[5]
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

if sys.argv[1] == 'freeze':
    data = {
        'frozen_at_utc': datetime.now(timezone.utc).isoformat(),
        'context': 'Primary had 3 failures after a one-shot synthetic rigid-body teleport. No lesson source changed. This follow-up changes only the synthetic input driver.',
        'hypothesis': 'A continuously supplied hand pose will keep the sphere at requested world coordinates and local model A at (1,-1); drop will project to local (1,1.12,-1) and remain there. The initial failure may be physics synchronization of a one-shot input, not host geometry.',
        'predicted_checks': 12,
        'source_sha256': {p.name: sha(p) for p in [HERE / 'continuous_grab_probe.gd', HERE / 'followup.py']},
        'additional_read': {'path': 'addons/godot-xr-tools/objects/pickable.gd', 'sha256': sha(ROOT / 'addons/godot-xr-tools/objects/pickable.gd'), 'scope': 'rg snippets for process, physics, force integration, pickup/drop, freeze and pose properties. No author code or external assessment.'},
        'retained_initial_failure': ['primary_results.json', 'primary.stdout.log', 'primary.stderr.log', 'primary_execution.json'],
        'runner_note': 'First Python console print failed on Windows cp1252 after UTF-8 log capture completed. Engine failure/results remained recorded. Later runner calls use python -X utf8; no Godot/source repair.',
    }
    (HERE / 'followup_predictions.json').write_text(json.dumps(data, indent=2), encoding='utf-8')
    print(json.dumps(data, indent=2))
else:
    frozen = json.loads((HERE / 'followup_predictions.json').read_text(encoding='utf-8'))
    for name, expected in frozen['source_sha256'].items(): assert sha(HERE / name) == expected
    original = json.loads((HERE / 'pre_run_manifest.json').read_text(encoding='utf-8'))
    for name, expected in original['sha256'].items(): assert sha(HERE / name) == expected
    command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless', '--path', str(ROOT), '--xr-mode', 'off', '--audio-driver', 'Dummy', '--script', 'res://doc/book/iterations/2026-10-11-euclid-the-same-triangle/ghost/student/continuous_grab_probe.gd', '--', '--no-bridges']
    start = datetime.now(timezone.utc).isoformat()
    try:
        run = subprocess.run(command, cwd=ROOT, timeout=90, capture_output=True, text=True, encoding='utf-8', errors='replace', creationflags=subprocess.CREATE_NO_WINDOW)
        stdout, stderr, code, timed_out = run.stdout, run.stderr, run.returncode, False
    except subprocess.TimeoutExpired as exc:
        stdout, stderr, code, timed_out = exc.stdout or b'', exc.stderr or b'', None, True
        stdout = stdout.decode('utf-8', errors='replace') if isinstance(stdout, bytes) else stdout
        stderr = stderr.decode('utf-8', errors='replace') if isinstance(stderr, bytes) else stderr
    (HERE / 'continuous_grab.stdout.log').write_text(stdout, encoding='utf-8')
    (HERE / 'continuous_grab.stderr.log').write_text(stderr, encoding='utf-8')
    record = {'command': command, 'started_at_utc': start, 'finished_at_utc': datetime.now(timezone.utc).isoformat(), 'exit_code': code, 'timed_out': timed_out, 'timeout_seconds': 90, 'creationflags': 'subprocess.CREATE_NO_WINDOW', 'encoding': 'utf-8'}
    (HERE / 'continuous_grab_execution.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
    print(json.dumps(record, indent=2))
    print(stdout[-8000:])
    print(stderr[-8000:])
