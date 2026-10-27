from pathlib import Path
import subprocess, sys
sys.stdout.reconfigure(encoding="utf8")
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
out=ROOT/'ada_run/s-descent-boolean-2026-10-27';out.mkdir(exist_ok=True)
lock=acquire_native_slot('Boolean S descent model',timeout=600)
stage=stage_runtime()
with (out/'native.log').open('w',encoding='utf8') as log:
 r=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--resolution','1440x1000','--fixed-fps','60','--script','res://tools/probes/boolean_s_descent.gd','--','--void-trial=s_descent_boolean','--no-bridges','--pictures='+str(out)],stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
print(r.returncode);print((out/'native.log').read_text(encoding='utf8')[-6500:])
raise SystemExit(r.returncode)
