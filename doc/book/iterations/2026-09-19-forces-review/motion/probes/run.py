from pathlib import Path
import subprocess, json, time, sys, hashlib

root = Path.cwd()
phase, name = sys.argv[1:3]
base = root / 'doc/book/iterations/2026-09-19-forces-review/motion'
out = base / phase
out.mkdir(parents=True, exist_ok=True)
watched = ['algorithms/vectors/10_vector_field_flow/field_receivers.gd',
 'commons/maps/Vectors_Act4a_KineticForces/map_data.json',
 'commons/scenes/endless_museum.gd','commons/scenes/em/em_detail.gd',
 'commons/artifacts/registry/vectors_demos.json',
 'commons/artifacts/drag_corridor/kinetic_drag.gd','commons/artifacts/drag_corridor/kinetic_walk_provider.gd',
 'commons/artifacts/centrifuge_ring/centrifuge_ring.gd','commons/artifacts/force_mower/force_mower.gd',
 'commons/artifacts/sisyphus_mower/sisyphus_mower.gd','commons/artifacts/prop_carousel/prop_carousel.gd']

def hashes():
    return {p: hashlib.sha256((root/p).read_bytes()).hexdigest() for p in watched}
cmd = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(root), '--rendering-method', 'mobile', '--rendering-driver', 'vulkan', '--xr-mode', 'off', '--audio-driver', 'Dummy', '--resolution', '1600x1000', '--log-file', str(out/(name+'-engine.log')), '--script', 'res://doc/book/iterations/2026-09-19-forces-review/motion/probes/probe_'+name+'.gd', '--', '--out=res://doc/book/iterations/2026-09-19-forces-review/motion/'+phase+'/']
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

