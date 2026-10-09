from pathlib import Path
import subprocess,json,sys,time
root=Path.cwd();phase=sys.argv[1];out=root/"doc/book/iterations/2026-09-19-tiling-review/relations"/phase;out.mkdir(exist_ok=True)
cmd=["C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe","--headless","--path",str(root),"--xr-mode","off","--audio-driver","Dummy","--log-file",str(out/"engine.log"),"--script","res://doc/book/iterations/2026-09-19-tiling-review/relations/probes/probe_overlay_positions.gd","--","--out=res://doc/book/iterations/2026-09-19-tiling-review/relations/"+phase+"/"]
with (out/"process.log").open("w",encoding="utf-8") as f:r=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,timeout=30)
(out/"run.json").write_text(json.dumps({"command":cmd,"returncode":r.returncode},indent=2),encoding="utf-8");print(r.returncode)
