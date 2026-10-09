from pathlib import Path
import subprocess, json, time, sys, hashlib

root = Path.cwd()
phase, name = sys.argv[1:3]
base = root / 'doc/book/iterations/2026-09-19-forces-review/relations'
out = base / phase
out.mkdir(parents=True, exist_ok=True)
watched = ['commons/scenes/endless_museum.gd', 'commons/scenes/em/em_detail.gd', 'commons/maps/VFM_07_Gravity/map_data.json', 'commons/artifacts/orbital_mechanics_demo/gravity_relations.gd', 'commons/hazards/octapod_crawler/four_leg_critter.gd']
def hashes():
    return {p: hashlib.sha256((root/p).read_bytes()).hexdigest() for p in watched}
cmd = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(root), '--rendering-method', 'mobile', '--rendering-driver', 'vulkan', '--xr-mode', 'off', '--audio-driver', 'Dummy', '--resolution', '1600x1000', '--log-file', str(out/(name+'-engine.log')), '--script', 'res://doc/book/iterations/2026-09-19-forces-review/relations/probes/probe_'+name+'.gd', '--', '--out=res://doc/book/iterations/2026-09-19-forces-review/relations/'+phase+'/']
if phase=="before": cmd.append("--replay-before")
start = time.time()
before = hashes()
si = subprocess.STARTUPINFO()
si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
si.wShowWindow = subprocess.SW_HIDE
with (out/(name+'-process.log')).open('w', encoding='utf-8') as log:
    p = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, creationflags=subprocess.CREATE_NO_WINDOW, startupinfo=si)
    try:
        rc = p.wait(timeout=180)
    except subprocess.TimeoutExpired:
        p.kill()
        p.wait()
        rc = -1
result = {'pid':p.pid, 'command':cmd, 'returncode':rc, 'seconds':time.time()-start, 'source_sha256_before':before, 'source_sha256_after':hashes()}
(out/(name+'-run.json')).write_text(json.dumps(result, indent=2))
print(json.dumps(result))

