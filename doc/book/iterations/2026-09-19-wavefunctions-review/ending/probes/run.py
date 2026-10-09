from pathlib import Path
import subprocess,json,time,hashlib,sys
base=Path('doc/book/iterations/2026-09-19-wavefunctions-review/ending')
phase,name=sys.argv[1:3]
out=base/phase/name;out.mkdir(parents=True,exist_ok=True)
watched=[p for p in json.loads((base/'before-source-sha256.json').read_text(encoding='utf-8')) if p.endswith(('.gd','.tscn','map_data.json')) or '/registry/' in p]
def hashes():return {s:hashlib.sha256(Path(s).read_bytes()).hexdigest() for s in watched}
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(Path.cwd()),'--xr-mode','off','--audio-driver','Dummy','--log-file',str((out/'engine.log').resolve()),'--script','res://'+str(base/'probes'/f'{name}.gd').replace('\\','/'),'--','--out=res://'+str(out).replace('\\','/')+'/']
if phase=='after':cmd+=['--current']
if name!='museum':cmd.insert(1,'--headless')
else:cmd[1:1]=['--rendering-method','mobile','--rendering-driver','vulkan','--resolution','1600x1000']
before=hashes();start=time.time()
si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=subprocess.SW_HIDE
with (out/'process.log').open('w',encoding='utf-8') as f:
 p=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,startupinfo=si)
 (out/'pid.json').write_text(json.dumps({'pid':p.pid,'command':cmd},indent=2),encoding='utf-8')
 try:rc=p.wait(timeout=55)
 except subprocess.TimeoutExpired:p.kill();p.wait();rc=-1
result={'pid':p.pid,'returncode':rc,'seconds':time.time()-start,'source_sha256_before':before,'source_sha256_after':hashes(),'command':cmd}
(out/'run.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({'name':name,'returncode':rc,'seconds':result['seconds'],'stable':before==result['source_sha256_after']}))
