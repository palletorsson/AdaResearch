"""Exercise original artifact operations through architectural control surfaces."""
from pathlib import Path
import json, os, subprocess, sys
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
capture="--capture" in sys.argv
out=ROOT/"doc/book/iterations/2026-10-20-architectural-interfaces"/("images" if capture else "tests")
out.mkdir(parents=True,exist_ok=True)
stage=stage_runtime()
args=[os.environ.get("GODOT_EXE","C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
      "--no-window" if capture else "--headless","--path",str(stage),"--rendering-method","mobile",
      "--xr-mode","off","--fixed-fps","60","--script","res://tools/probes/interface_terminal_probe.gd",
      "--","--no-bridges","--out="+str(out)]
if capture: args.append("--capture")
with (out/"engine.log").open("w",encoding="utf8") as log:
    result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
text=(out/"engine.log").read_text(encoding="utf8",errors="replace")
if result.returncode or "SCRIPT ERROR" in text or "\nERROR:" in text:
    print(text[-9000:]);sys.exit(1)
checks=json.loads((out/"checks.json").read_text())
assert checks["passed"],checks["failed"]
print(f'{len(checks["checks"])} native checks passed: {out}')
