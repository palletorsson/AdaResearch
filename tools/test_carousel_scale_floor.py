"""Native desktop and synthetic-XR tests, or actual rendered tower screenshots."""
from pathlib import Path
import hashlib,json,os,subprocess,sys
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
REPORT=ROOT/"doc/book/iterations/2026-10-20-carousels-and-scale"
capture="--capture" in sys.argv
regression="--rotation-regression" in sys.argv
out=REPORT/("rotation-regression" if regression else "images" if capture else "tests");out.mkdir(parents=True,exist_ok=True)
rooms=json.loads((ROOT/"commons/void/rooms.json").read_text(encoding="utf8"))
baseline=next((arg.split("=",1)[1] for arg in sys.argv if arg.startswith("--baseline=")), "before-rooms.json")
before=json.loads((REPORT/baseline).read_text(encoding="utf8"))
# Point Trace is being curated concurrently in the editor. The save itself
# checked every earlier floor atomically; never overwrite those later edits.
assert all(rooms["floors"][i]==before["floors"][i] for i in range(17) if baseline!="before-rooms.json" or i!=4), "Another curated floor changed"
for name,digest in json.loads((REPORT/"text-hashes.json").read_text()).items():
    assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,name
args=[os.environ.get("GODOT_EXE","C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
      "--no-window" if capture else "--headless","--path",str(stage_runtime()),
      "--rendering-method","mobile","--xr-mode","off","--fixed-fps","60",
      "--script","res://tools/probes/"+("rotation_full_floor.gd" if regression else "carousel_scale_floor.gd"),"--","--no-bridges",
      "--void-start-floor="+("16" if regression else "17"),"--out="+str(out)]
if capture:args.append("--capture")
with (out/"engine.log").open("w",encoding="utf8") as log:
    result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=240,
                          creationflags=subprocess.CREATE_NO_WINDOW if os.name=="nt" else 0)
text=(out/"engine.log").read_text(encoding="utf8",errors="replace")
assert result.returncode==0 and "SCRIPT ERROR" not in text and "\nERROR:" not in text,text[-10000:]
checks=json.loads((out/"checks.json").read_text())
assert checks["passed"],checks["failed"]
print(f'{len(checks["checks"])} native checks passed; earlier floors match {baseline}; texts unchanged.')
