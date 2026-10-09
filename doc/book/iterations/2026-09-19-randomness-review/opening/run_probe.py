from pathlib import Path
import hashlib,json,os,subprocess,sys,time
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[4]
OUT=HERE/sys.argv[1]; OUT.mkdir(parents=True,exist_ok=True)
rel='algorithms/randomness/generative/tenprintantmaze/ten_print_maze.gd'
source=(HERE/'before-source'/rel) if '--before' in sys.argv else ROOT/rel
sha=lambda:hashlib.sha256(source.read_bytes()).hexdigest()
startsha=sha(); env=os.environ.copy()
env['PROBE_SOURCE']='res://'+source.relative_to(ROOT).as_posix();env['PROBE_OUTPUT']=str(OUT/'checks.json')
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(OUT/'engine.log'),'--script','res://'+(HERE/'probe_maze.gd').relative_to(ROOT).as_posix()]
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=subprocess.SW_HIDE
start=time.time()
with (OUT/'process.log').open('w',encoding='utf-8') as log:
    process=subprocess.Popen(cmd,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT,startupinfo=startup,creationflags=subprocess.CREATE_NO_WINDOW)
    try: code=process.wait(timeout=35)
    except subprocess.TimeoutExpired: process.kill(); code=process.wait()
record=dict(command=cmd,pid=process.pid,returncode=code,elapsed=time.time()-start,source_before=startsha,source_after=sha(),source_stable=startsha==sha())
(OUT/'run.json').write_text(json.dumps(record,indent=2),encoding='utf-8');print(json.dumps(record))
