from pathlib import Path
import subprocess, json, time, sys

root = Path.cwd()
base = root / 'doc/book/iterations/2026-09-19-tiling-review/opening'
name, phase = sys.argv[1:3]
out = base / phase
out.mkdir(parents=True, exist_ok=True)
script = 'capture_opening' if name.startswith('Pattern_') else name
map_name = next((arg.split('=', 1)[1] for arg in sys.argv if arg.startswith('--map=')),
                'Pattern_Disco' if name.startswith('probe_disco_') else name)
cmd = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(root),
       '--rendering-method', 'mobile', '--rendering-driver', 'vulkan',
       '--xr-mode', 'off', '--audio-driver', 'Dummy', '--resolution', '1400x900',
       '--log-file', str(out / (name + '-engine.log')), '--script',
       'res://doc/book/iterations/2026-09-19-tiling-review/opening/probes/' + script + '.gd',
       '--', '--map=' + map_name,
       '--out=res://doc/book/iterations/2026-09-19-tiling-review/opening/' + phase + '/', '--capture']
start = time.time()
if '--snapshot-before' in sys.argv:
    cmd.append('--snapshot-before')
if '--headless' in sys.argv:
    cmd.remove('--capture')
    cmd.insert(1, '--headless')
with (out / (name + '-process.log')).open('w', encoding='utf-8') as log:
    process = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT,
                               creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        rc = process.wait(timeout=150)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        rc = 124
result = {'pid': process.pid, 'command': cmd, 'returncode': rc, 'seconds': time.time()-start}
(out / (name + '-run.json')).write_text(json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps(result))
