from pathlib import Path
import hashlib
import json
import subprocess
import sys
import time

sys.stdout.reconfigure(encoding='utf-8')

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = HERE / 'diagram'
OUT.mkdir(exist_ok=True)
paths = ['algorithms/formfinding/settling_tremble/settling_tremble.gd',
         'doc/book/iterations/2026-09-19-formfinding-review/probe_diagram.gd']
def hashes(): return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths}
before = hashes()
command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT),
           '--xr-mode', 'off', '--audio-driver', 'Dummy', '--rendering-method', 'gl_compatibility',
           '--resolution', '1400x950', '--log-file', str(OUT / 'engine.log'),
           '--script', 'res://doc/book/iterations/2026-09-19-formfinding-review/probe_diagram.gd']
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = 0
start = time.time()
with (OUT / 'process.log').open('w', encoding='utf-8') as log:
    process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                               creationflags=subprocess.CREATE_NO_WINDOW, startupinfo=startup)
    try: code = process.wait(timeout=45)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        code = -1
(OUT / 'run.json').write_text(json.dumps(dict(command=command, seconds=time.time()-start,
    returncode=code, before=before, after=hashes()), indent=2), encoding='utf-8')
print('Diagram exit', code)
print((OUT / 'process.log').read_text(encoding='utf-8')[-1200:])
raise SystemExit(0 if code == 0 else 1)
