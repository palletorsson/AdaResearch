from pathlib import Path
import subprocess,json,time,sys,hashlib
root=Path.cwd();phase=sys.argv[1];name=sys.argv[2]
out=root/"doc/book/iterations/2026-09-19-tiling-review/relations"/phase
out.mkdir(parents=True,exist_ok=True)
shared=root/"commons/scenes/endless_museum.gd"
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
cmd=["C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe","--path",str(root),"--rendering-method","mobile","--rendering-driver","vulkan","--xr-mode","off","--audio-driver","Dummy","--resolution","1600x1000","--log-file",str(out/(name+"-engine.log")),"--script","res://doc/book/iterations/2026-09-19-tiling-review/relations/probes/probe_"+name+".gd","--","--out=res://doc/book/iterations/2026-09-19-tiling-review/relations/"+phase+"/"]
if phase=="clean-before":cmd.append("--replay-before")
detail=root/"commons/scenes/em/em_detail.gd"
start=time.time();before=digest(shared);detail_before=digest(detail)
si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=subprocess.SW_HIDE
with (out/(name+"-process.log")).open("w",encoding="utf-8") as f:
 p=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,startupinfo=si)
 try:rc=p.wait(timeout=150)
 except subprocess.TimeoutExpired:p.kill();p.wait();rc=-1
result={"pid":p.pid,"command":cmd,"returncode":rc,"seconds":time.time()-start,"museum_sha256_before":before,"museum_sha256_after":digest(shared),"detail_sha256_before":detail_before,"detail_sha256_after":digest(detail)}
(out/(name+"-run.json")).write_text(json.dumps(result,indent=2));print(json.dumps(result))
