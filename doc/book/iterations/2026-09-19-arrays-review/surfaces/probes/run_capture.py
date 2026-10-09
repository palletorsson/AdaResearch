from pathlib import Path
import subprocess,json,time,sys
root=Path.cwd();phase=sys.argv[1];map_name=sys.argv[2]
out=root/"doc/book/iterations/2026-09-19-arrays-review/surfaces"/phase
out.mkdir(parents=True,exist_ok=True)
cmd=["C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe","--path",str(root),"--rendering-method","mobile","--rendering-driver","vulkan","--xr-mode","off","--audio-driver","Dummy","--log-file",str(out/(map_name+"-engine.log")),"--script","res://doc/book/iterations/2026-09-19-arrays-review/surfaces/probes/capture_surfaces.gd","--","--map="+map_name,"--out=res://doc/book/iterations/2026-09-19-arrays-review/surfaces/"+phase+"/","--capture"]
start=time.time()
with (out/(map_name+"-process.log")).open("w",encoding="utf-8") as f:
 p=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 try:rc=p.wait(timeout=150)
 except subprocess.TimeoutExpired:p.kill();rc=-1
result={"pid":p.pid,"command":cmd,"returncode":rc,"seconds":time.time()-start}
(out/(map_name+"-run.json")).write_text(json.dumps(result,indent=2))
print(json.dumps(result))
