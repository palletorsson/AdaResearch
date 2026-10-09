from pathlib import Path
import subprocess, json, time, sys, hashlib

root = Path.cwd()
phase, name = sys.argv[1:3]
base = root / 'doc/book/iterations/2026-09-19-wavefunctions-review/middle'
out = base / phase
out.mkdir(parents=True, exist_ok=True)
watched = ['algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.gd', 'algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.tscn', 'algorithms/wavefunctions/mariocontrol/DualBallFMController.gd', 'algorithms/wavefunctions/mariocontrol/DualBallFMController.tscn', 'algorithms/wavefunctions/berninicolumns/BerniniColumns.gd', 'algorithms/wavefunctions/berninicolumns/BerniniScene.tscn', 'algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.gd', 'algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.tscn', 'commons/scenes/endless_museum.gd', 'commons/scenes/em/em_detail.gd', 'commons/data/artifact_roles.json', 'commons/artifacts/registry/wavefunctions.json', 'commons/maps/WaveFunctions_3D_Wave_Propagation/final.md', 'commons/maps/WaveFunctions_3D_Wave_Propagation/map_data.json', 'commons/maps/WaveFunctions_3D_Wave_Propagation/tutorial.md', 'commons/maps/WaveFunctions_3D_Wave_Propagation/critical.md', 'commons/maps/WaveFunctions_3D_Wave_Propagation/blurb.md', 'commons/maps/WaveFunctions_Effect_Sound/final.md', 'commons/maps/WaveFunctions_Effect_Sound/map_data.json', 'commons/maps/WaveFunctions_Effect_Sound/tutorial.md', 'commons/maps/WaveFunctions_Effect_Sound/critical.md', 'commons/maps/WaveFunctions_Effect_Sound/blurb.md', 'commons/maps/Wavefunctions_Bernini/final.md', 'commons/maps/Wavefunctions_Bernini/map_data.json', 'commons/maps/Wavefunctions_Bernini/tutorial.md', 'commons/maps/Wavefunctions_Bernini/critical.md', 'commons/maps/Wavefunctions_Bernini/blurb.md', 'commons/maps/WaveFunctions_John_Cage/final.md', 'commons/maps/WaveFunctions_John_Cage/map_data.json', 'commons/maps/WaveFunctions_John_Cage/tutorial.md', 'commons/maps/WaveFunctions_John_Cage/critical.md', 'commons/maps/WaveFunctions_John_Cage/blurb.md']

def hashes():
    return {p: hashlib.sha256((root/p).read_bytes()).hexdigest() for p in watched}
cmd = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(root), '--rendering-method', 'mobile', '--rendering-driver', 'vulkan', '--xr-mode', 'off', '--audio-driver', 'Dummy', '--resolution', '1600x1000', '--log-file', str(out/(name+'-engine.log')), '--script', 'res://doc/book/iterations/2026-09-19-wavefunctions-review/middle/probes/probe_'+name+'.gd', '--', '--out=res://doc/book/iterations/2026-09-19-wavefunctions-review/middle/'+phase+'/']
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

