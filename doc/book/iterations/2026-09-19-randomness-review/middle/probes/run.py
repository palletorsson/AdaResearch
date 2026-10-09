from pathlib import Path
import subprocess, json, time, sys, hashlib

root = Path.cwd()
phase, name = sys.argv[1:3]
base = root / 'doc/book/iterations/2026-09-19-randomness-review/middle'
out = base / phase
out.mkdir(parents=True, exist_ok=True)
watched = list(json.loads((base / 'before-sha256.json').read_text()))
watched += ['ada_run/em_plan.json', 'commons/maps/sequences/randomness.json']

def hashes():
    return {p: hashlib.sha256((root/p).read_bytes()).hexdigest() for p in watched}
cmd = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(root), '--rendering-method', 'mobile', '--rendering-driver', 'vulkan', '--xr-mode', 'off', '--audio-driver', 'Dummy', '--resolution', '1600x1000', '--log-file', str(out/(name+'-engine.log')), '--script', 'res://doc/book/iterations/2026-09-19-randomness-review/middle/probes/probe_'+name+'.gd', '--', '--out=res://doc/book/iterations/2026-09-19-randomness-review/middle/'+phase+'/']
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

