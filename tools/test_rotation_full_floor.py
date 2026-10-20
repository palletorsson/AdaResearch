"""Native integration tests and in-tower captures for the complete Rotation floor."""
from pathlib import Path
import hashlib, json, os, subprocess, sys
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
REPORT=ROOT/"doc/book/iterations/2026-10-20-rotation-full-floor"
capture="--capture" in sys.argv
out=REPORT/("images" if capture else "tests")
out.mkdir(parents=True,exist_ok=True)
rooms=json.loads((ROOT/"commons/void/rooms.json").read_text(encoding="utf8"))
before=json.loads((REPORT/"before-rooms.json").read_text(encoding="utf8"))
assert rooms["floors"][1:16]==before["floors"][1:16], "A different curated floor changed"
assert rooms["floors"][17]["map"]=="Trans_Scale"
for path,digest in json.loads((REPORT/"text-hashes.json").read_text()).items():
    assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,path
assert json.loads((Path.home()/"Desktop/Ada Void/rooms.json").read_text(encoding="utf8"))["floors"][16:] == rooms["floors"][16:]
args=[os.environ.get("GODOT_EXE","C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
      "--no-window" if capture else "--headless","--path",str(stage_runtime()),
      "--rendering-method","mobile","--xr-mode","off","--fixed-fps","60",
      "--script","res://tools/probes/rotation_full_floor.gd","--","--no-bridges",
      "--void-start-floor=16","--out="+str(out)]
if capture:args.append("--capture")
with (out/"engine.log").open("w",encoding="utf8") as log:
    result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=300,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name=="nt" else 0)
log=(out/"engine.log").read_text(encoding="utf8",errors="replace")
assert result.returncode==0 and "SCRIPT ERROR" not in log and "\nERROR:" not in log,log[-10000:]
checks=json.loads((out/"checks.json").read_text(encoding="utf8"))
assert checks["passed"],checks["failed"]
print(f'{len(checks["checks"])} native checks passed. Text hashes and desktop backup match.')
