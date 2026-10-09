from pathlib import Path
import subprocess,json,time,sys
root=Path.cwd();phase=sys.argv[1];name=sys.argv[2]
out=root/"doc/book/iterations/2026-09-19-color-review/late"/phase
out.mkdir(parents=True,exist_ok=True)
cmd=["C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe","--path",str(root),"--rendering-method","mobile","--rendering-driver","vulkan","--xr-mode","off","--audio-driver","Dummy","--log-file",str(out/(name+"-engine.log")),"--script","res://doc/book/iterations/2026-09-19-color-review/late/probes/probe_"+name+".gd","--","--out=res://doc/book/iterations/2026-09-19-color-review/late/"+phase+"/"]
start=time.time()
with (out/(name+"-process.log")).open("w",encoding="utf-8") as f:
 p=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 try:rc=p.wait(timeout=150)
 except subprocess.TimeoutExpired:p.kill();rc=-1
result={"pid":p.pid,"command":cmd,"returncode":rc,"seconds":time.time()-start}
(out/(name+"-run.json")).write_text(json.dumps(result,indent=2));print(json.dumps(result))
