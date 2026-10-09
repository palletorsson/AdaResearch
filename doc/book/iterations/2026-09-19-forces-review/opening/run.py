from pathlib import Path
import hashlib,json,subprocess,sys,time
root=Path.cwd(); base=root/'doc/book/iterations/2026-09-19-forces-review/opening'
mode=sys.argv[1] if len(sys.argv)>1 else 'headless'
assert mode in ('headless','headless-final','before','before-final','before-frozen','before-accepted','after-frozen','after')
out=base/mode;out.mkdir(parents=True,exist_ok=True)
paths=['doc/book/iterations/2026-09-19-forces-review/opening/frozen-museum.gd','commons/artifacts/torque_crank/torque_crank.gd','commons/artifacts/vector_normalize_demo/vector_normalize_demo.gd','commons/artifacts/_toy_console/toy_console.gd','commons/scenes/endless_museum.gd','commons/scenes/em/em_detail.gd','commons/maps/Vectors_Act2_VectorArithmetic/map_data.json']
def hashes():return {p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in paths}
start_hashes=hashes()
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(root),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(out/'engine.log')]
command += ['--headless'] if mode.startswith('headless') else ['--rendering-method','mobile','--rendering-driver','vulkan','--resolution','1600x1000']
command += ['--script','res://doc/book/iterations/2026-09-19-forces-review/opening/probe.gd','--',f'--out=res://doc/book/iterations/2026-09-19-forces-review/opening/{mode}/']
if not mode.startswith('headless'):command+=['--museum','--capture']
if mode.startswith('before'):command+=['--before']
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=subprocess.SW_HIDE
start=time.time()
with (out/'process.log').open('w',encoding='utf-8') as f:
 p=subprocess.Popen(command,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,startupinfo=startup)
 try: rc=p.wait(timeout=100)
 except subprocess.TimeoutExpired: p.kill();p.wait();rc=-1
record={'command':command,'returncode':rc,'seconds':time.time()-start,'hashes_before':start_hashes,'hashes_after':hashes()}
record['sources_stable_during_run']=record['hashes_before']==record['hashes_after']
record['loaded_sources_stable_during_run']=all(record['hashes_before'][k]==record['hashes_after'][k] for k in paths if k!='commons/scenes/endless_museum.gd')
(out/'run.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print(json.dumps(record));raise SystemExit(rc)
