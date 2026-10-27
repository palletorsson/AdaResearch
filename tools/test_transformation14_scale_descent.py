"""Serial native acceptance for the opt-in scale elevator and electrical cover."""
import argparse,json,os,subprocess,sys,hashlib
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime

def main():
    sys.stdout.reconfigure(encoding="utf8");p=argparse.ArgumentParser();p.add_argument("--xr",action="store_true");p.add_argument("--capture",action="store_true");p.add_argument("--focused",action="store_true");a=p.parse_args()
    root=Path(__file__).resolve().parents[1];out=root/"ada_run/transformation14-scale-descent-2026-10-26"/(("focused-" if a.focused else "")+("xr" if a.xr else "desktop"));out.mkdir(parents=True,exist_ok=True)
    receipt=out/"checks.json"
    if receipt.exists():receipt.unlink()
    slot=acquire_native_slot("Scale descent "+out.name);stage=stage_runtime()
    command=[os.environ.get("GODOT_EXE","C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),"--path",str(stage),"--xr-mode","off","--fixed-fps","60"]
    command += ["--no-window","--rendering-method","mobile","--resolution","1440x900"] if a.capture else ["--headless"]
    command += ["--script","res://tools/probes/transformation14_scale_descent.gd","--","--desktop","--no-bridges","--out="+str(out)]
    if a.xr:command.append("--xr-only")
    if a.capture:command.append("--capture")
    if a.focused:command.append("--focused")
    with (out/"engine.log").open("w",encoding="utf8") as stream: result=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
    text=(out/"engine.log").read_text(encoding="utf8",errors="replace")
    r=json.loads(receipt.read_text(encoding="utf8")) if receipt.exists() else {"passed":False,"error":"No receipt"}
    r["engine_errors"]=[s for s in text.splitlines() if s.startswith(("ERROR:","SCRIPT ERROR:"))];r["exit_code"]=result.returncode;r["passed"]=r["passed"] and result.returncode==0 and not r["engine_errors"]
    r["floor14_sha256"]=hashlib.sha256(json.dumps(json.loads((root/"commons/void/rooms.json").read_text())["floors"][14],sort_keys=True).encode()).hexdigest()
    (out/"run-result.json").write_text(json.dumps(r,indent=2),encoding="utf8")
    print("\n".join(s for s in text.splitlines() if "[void]" in s or "ROUTE_CONTACT" in s or "SCALE_RIDE_DETAILS" in s or s.startswith(("ERROR:","SCRIPT ERROR:"))))
    print("Passed",r["passed"],"exit",result.returncode);return 0 if r["passed"] else 1
if __name__=="__main__":raise SystemExit(main())
