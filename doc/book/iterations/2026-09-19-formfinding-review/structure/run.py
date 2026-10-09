from pathlib import Path
import hashlib,json,subprocess,sys,time
root=Path.cwd();base=root/'doc/book/iterations/2026-09-19-formfinding-review/structure'
mode=sys.argv[1]; hall=sys.argv[2] if len(sys.argv)>2 else 'FormFinding_Catenary'
assert mode in ('headless-before','headless-after','museum-baseline','museum-baseline-final','museum-after','capture-before','capture-after','capture-before-final','capture-after-final','capture-before-accepted','capture-after-accepted','capture-before-verified','capture-after-verified')
assert hall in ('FormFinding_Catenary','FormFinding_Equilibrium')
out=base/(mode+'-'+hall);out.mkdir(parents=True,exist_ok=True)
paths=list(json.loads((base/'before-sha256.json').read_text()))
paths += ['commons/scenes/endless_museum.gd','commons/scenes/em/em_detail.gd','commons/artifacts/science_screen/science_screen.gd','doc/book/iterations/2026-09-19-formfinding-review/structure/frozen-museum.gd']
def hashes():return {p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in paths}
start_hashes=hashes()
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(root),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(out/'engine.log')]
command += ['--rendering-method','mobile','--rendering-driver','vulkan','--resolution','1600x1000'] if mode.startswith('capture') else ['--headless']
command += ['--script','res://doc/book/iterations/2026-09-19-formfinding-review/structure/probe.gd','--',f'--out=res://doc/book/iterations/2026-09-19-formfinding-review/structure/{out.name}/',f'--hall={hall}']
if not mode.startswith('headless'):command+=['--museum']
if mode.startswith('capture'):command+=['--capture']
if 'before' in mode or mode.startswith('museum-baseline'):command+=['--before']
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=subprocess.SW_HIDE
start=time.time()
with (out/'process.log').open('w',encoding='utf-8') as f:
 p=subprocess.Popen(command,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,startupinfo=startup)
 try:rc=p.wait(timeout=115)
 except subprocess.TimeoutExpired:p.kill();p.wait();rc=-1
record={'command':command,'pid':p.pid,'returncode':rc,'seconds':time.time()-start,'hashes_before':start_hashes,'hashes_after':hashes()}
record['sources_stable_during_run']=record['hashes_before']==record['hashes_after']
(out/'run.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in record.items() if not k.startswith('hashes')}));raise SystemExit(rc)
