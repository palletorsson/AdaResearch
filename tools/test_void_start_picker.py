"""Serial menu/input regressions with isolated saves and actual staged sources."""
import argparse,json,os,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime

def main():
    sys.stdout.reconfigure(encoding="utf8")
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-only",action="store_true")
    parser.add_argument("--out",type=Path,required=True)
    args=parser.parse_args();out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    slot=acquire_native_slot("Void selected-map regression",timeout=600)
    stage=stage_runtime();config=stage/"project.godot"
    config.write_text(config.read_text(encoding="utf8").replace('config/name="Ada Void Trial Test"','config/name="Ada Menu Integration Test"'),encoding="utf8")
    probe="void_picker_input_probe.gd" if args.input_only else "game_menu_route.gd"
    command=[os.environ.get("GODOT_EXE","C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),"--path",str(stage),"--xr-mode","off"]
    command += ["--headless"] if args.input_only else ["--no-window","--rendering-method","mobile","--resolution","1600x1000"]
    command += ["--script","res://tools/probes/"+probe,"--","--desktop","--no-bridges","--route=void","--out="+str(out)]
    print("Testing",probe,flush=True)
    with (out/"engine.log").open("w",encoding="utf8") as log:
        result=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
    text=(out/"engine.log").read_text(encoding="utf8",errors="replace")
    receipt=out/("input-checks.json" if args.input_only else "void.json")
    report=json.loads(receipt.read_text(encoding="utf8")) if receipt.exists() else {"passed":False,"error":"No receipt"}
    report["exit_code"]=result.returncode
    report["engine_errors"]=[s for s in text.splitlines() if s.startswith(("ERROR:","SCRIPT ERROR:"))]
    report["passed"]=report["passed"] and result.returncode==0 and not report["engine_errors"]
    (out/"run-result.json").write_text(json.dumps(report,indent=2),encoding="utf8")
    print("\n".join(s for s in text.splitlines() if "[menu-route]" in s or "[picker-input]" in s or s.startswith(("ERROR:","SCRIPT ERROR:"))))
    print("Exit",result.returncode,"passed",report["passed"],flush=True)
    return 0 if report["passed"] else 1

if __name__=="__main__":raise SystemExit(main())
