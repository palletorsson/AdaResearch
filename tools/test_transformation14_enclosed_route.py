"""Run enclosed floor-14 route through ordinary desktop/synthetic-XR physics."""
import argparse,json,os,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime

def main():
    sys.stdout.reconfigure(encoding="utf8")
    p=argparse.ArgumentParser();p.add_argument("--xr",action="store_true");p.add_argument("--capture",action="store_true");a=p.parse_args()
    out=Path(__file__).resolve().parents[1]/"ada_run/transformation14-enclosed-route-2026-10-26"/("xr" if a.xr else "desktop");out.mkdir(parents=True,exist_ok=True)
    slot=acquire_native_slot("Floor 14 enclosed route "+("XR" if a.xr else "desktop"));stage=stage_runtime()
    command=[os.environ.get("GODOT_EXE","C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),"--path",str(stage),"--xr-mode","off","--fixed-fps","60"]
    command += ["--no-window","--rendering-method","mobile","--resolution","1440x900"] if a.capture else ["--headless"]
    command += ["--script","res://tools/probes/transformation14_enclosed_route.gd","--","--desktop","--no-bridges","--out="+str(out)]
    if a.xr:command.append("--xr-only")
    if a.capture:command.append("--capture")
    with (out/"engine.log").open("w",encoding="utf8") as stream: result=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
    text=(out/"engine.log").read_text(encoding="utf8",errors="replace")
    receipt=out/"checks.json";r=json.loads(receipt.read_text(encoding="utf8")) if receipt.exists() else {"passed":False,"error":"No receipt"}
    r["engine_errors"]=[s for s in text.splitlines() if s.startswith(("ERROR:","SCRIPT ERROR:"))];r["exit_code"]=result.returncode;r["passed"]=r["passed"] and result.returncode==0 and not r["engine_errors"]
    (out/"run-result.json").write_text(json.dumps(r,indent=2),encoding="utf8")
    print("\n".join(s for s in text.splitlines() if "[void]" in s or "ENCLOSURE_APPROACH" in s or "ROUTE_CONTACT" in s or "ROUTE_CHARGE" in s or s.startswith(("ERROR:","SCRIPT ERROR:"))))
    print("Passed:",r["passed"],"exit",result.returncode)
    return 0 if r["passed"] else 1
if __name__=="__main__":raise SystemExit(main())
