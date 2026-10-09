from pathlib import Path
import hashlib
import json
import subprocess
import sys
import time

root = Path.cwd()
mode = sys.argv[1] if len(sys.argv) > 1 else 'bridge'
assert mode in ('bridge', 'museum')
directory = 'runtime' if mode == 'bridge' else 'museum'
out = root / 'doc/book/iterations/2026-09-19-change-review/bridge' / directory
out.mkdir(parents=True, exist_ok=True)
source = root / 'algorithms/change/ftc_bridge.gd'
command = [
    'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe',
    '--path', str(root), '--rendering-method', 'mobile', '--rendering-driver', 'vulkan',
    '--xr-mode', 'off', '--audio-driver', 'Dummy', '--resolution', '1600x1000',
    '--log-file', str(out / 'engine.log'),
    '--script', f'res://doc/book/iterations/2026-09-19-change-review/bridge/probes/probe_{mode}.gd',
    '--', f'--out=res://doc/book/iterations/2026-09-19-change-review/bridge/{directory}/',
]
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = subprocess.SW_HIDE
start = time.time()
source_before = hashlib.sha256(source.read_bytes()).hexdigest()
with (out / 'process.log').open('w', encoding='utf-8') as handle:
    process = subprocess.Popen(command, stdout=handle, stderr=subprocess.STDOUT,
                               creationflags=subprocess.CREATE_NO_WINDOW, startupinfo=startup)
    try:
        rc = process.wait(timeout=90)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        rc = -1
record = {'command': command, 'pid': process.pid, 'returncode': rc,
          'seconds': time.time() - start,
          'source_sha256_before': source_before,
          'source_sha256_after': hashlib.sha256(source.read_bytes()).hexdigest()}
(out / 'run.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
print(json.dumps(record))
raise SystemExit(rc)
