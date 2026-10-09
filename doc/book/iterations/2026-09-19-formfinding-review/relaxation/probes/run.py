from pathlib import Path
import subprocess, json, time, sys, hashlib

root = Path.cwd()
phase, name = sys.argv[1:3]
base = root / 'doc/book/iterations/2026-09-19-formfinding-review/relaxation'
out = base / phase
out.mkdir(parents=True, exist_ok=True)
watched = ['commons/artifacts/verlet_workbench/verlet_workbench.gd', 'commons/artifacts/verlet_workbench/verlet_workbench.tscn', 'commons/artifacts/mass_spring_bench/mass_spring_bench.gd', 'commons/artifacts/frozen_glass_vessel/frozen_glass_vessel.gd', 'commons/soft_body/soft_body_sim.gd', 'commons/soft_body/soft_body_shapes.gd', 'commons/maps/FormFinding_Relaxation/map_data.json', 'commons/maps/FormFinding_Relaxation/final.md', 'commons/maps/FormFinding_Relaxation/tutorial.md', 'commons/scenes/endless_museum.gd', 'commons/scenes/em/em_detail.gd', 'commons/data/artifact_roles.json']

def hashes():
    return {p: hashlib.sha256((root/p).read_bytes()).hexdigest() for p in watched}
cmd = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(root), '--rendering-method', 'mobile', '--rendering-driver', 'vulkan', '--xr-mode', 'off', '--audio-driver', 'Dummy', '--resolution', '1600x1000', '--log-file', str(out/(name+'-engine.log')), '--script', 'res://doc/book/iterations/2026-09-19-formfinding-review/relaxation/probes/probe_'+name+'.gd', '--', '--out=res://doc/book/iterations/2026-09-19-formfinding-review/relaxation/'+phase+'/']
if '--headless' in sys.argv:
    at=cmd.index('--rendering-method');del cmd[at:at+4];cmd.insert(1,'--headless')
start = time.time()
before = hashes()
si = subprocess.STARTUPINFO()
si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
si.wShowWindow = subprocess.SW_HIDE
with (out/(name+'-process.log')).open('w', encoding='utf-8') as log:
    p = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, creationflags=subprocess.CREATE_NO_WINDOW, startupinfo=si)
    (out/(name+'-pid.json')).write_text(json.dumps({'pid':p.pid,'command':cmd},indent=2))
    try:
        rc = p.wait(timeout=180)
    except subprocess.TimeoutExpired:
        p.kill()
        p.wait()
        rc = -1
result = {'pid':p.pid, 'command':cmd, 'returncode':rc, 'seconds':time.time()-start, 'source_sha256_before':before, 'source_sha256_after':hashes()}
(out/(name+'-run.json')).write_text(json.dumps(result, indent=2))
print(json.dumps({'returncode':rc,'seconds':result['seconds'],'stable':result['source_sha256_before']==result['source_sha256_after']}))
sys.exit(rc)

