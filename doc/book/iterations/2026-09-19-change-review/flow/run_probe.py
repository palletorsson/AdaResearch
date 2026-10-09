from pathlib import Path
import hashlib
import json
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[5]
BASE = Path(__file__).resolve().parent
phase = sys.argv[1]
out = BASE / phase
out.mkdir(parents=True, exist_ok=True)
artifact_only = '--artifact-only' in sys.argv
sources = [
    'commons/artifacts/flow_field_painter/flow_field_painter.gd',
    'commons/artifacts/flow_field_painter/shared_field_lesson.gd',
    'commons/maps/Flow_Field/map_data.json',
    'commons/maps/Flow_Field/final.md',
    'commons/scenes/endless_museum.gd',
    'commons/scenes/em/em_detail.gd',
]
def hashes():
    return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sources}

cmd = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT),
       '--xr-mode', 'off', '--audio-driver', 'Dummy', '--log-file', str(out / 'engine.log')]
cmd += ['--headless'] if artifact_only else ['--rendering-method', 'mobile', '--rendering-driver', 'vulkan', '--resolution', '1600x1000']
cmd += ['--script', 'res://' + (BASE / 'probe_flow.gd').relative_to(ROOT).as_posix(),
        '--', '--out=res://' + out.relative_to(ROOT).as_posix() + '/']
cmd += ['--artifact-only'] if artifact_only else ['--capture']
if phase == 'before-runtime' or '--replay-before' in sys.argv:
    cmd += ['--replay-before']
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = subprocess.SW_HIDE
start = time.time()
before = hashes()
with (out / 'process.log').open('w', encoding='utf-8') as log:
    proc = subprocess.Popen(cmd, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                            creationflags=subprocess.CREATE_NO_WINDOW, startupinfo=startup)
    (out / 'pid.json').write_text(json.dumps({'pid': proc.pid, 'command': cmd}, indent=2), encoding='utf-8')
    try:
        rc = proc.wait(timeout=180)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()
        rc = -1
result = {'command': cmd, 'pid': proc.pid, 'returncode': rc, 'seconds': time.time() - start,
          'source_sha256_before': before, 'source_sha256_after': hashes()}
(out / 'run.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps(result, indent=2))
sys.exit(rc)
