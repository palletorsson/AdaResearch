from pathlib import Path
import os,sys,subprocess,json,hashlib,time
ROOT=Path(__file__).resolve().parents[5]
OUT=Path(__file__).resolve().parent/sys.argv[1]
OUT.mkdir(parents=True,exist_ok=True)
SOURCE=ROOT/'algorithms/wavefunctions/unit_circle/UnitCircle.gd'
if len(sys.argv)>2 and sys.argv[2]=='before':
 SOURCE=Path(__file__).resolve().parent/'before-source/algorithms/wavefunctions/unit_circle/UnitCircle.gd'
sha=lambda:hashlib.sha256(SOURCE.read_bytes()).hexdigest()
before=sha()
env=os.environ.copy();env['UNIT_PROBE_OUTPUT']=str(OUT/'checks.json');env['UNIT_SOURCE']='res://'+SOURCE.relative_to(ROOT).as_posix()
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(OUT/'engine.log'),'--script','res://doc/book/iterations/2026-09-19-wavefunctions-review/opening/probe_unit_circle.gd']
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=subprocess.SW_HIDE
started=time.time()
with (OUT/'process.log').open('w',encoding='utf-8') as log:
 p=subprocess.Popen(cmd,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT,startupinfo=startup,creationflags=subprocess.CREATE_NO_WINDOW)
 try:code=p.wait(timeout=35)
 except subprocess.TimeoutExpired:p.kill();code=p.wait()
record={'command':cmd,'pid':p.pid,'returncode':code,'elapsed_seconds':time.time()-started,'source_before':before,'source_after':sha(),'source_stable':before==sha()}
(OUT/'run.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print(json.dumps(record))
