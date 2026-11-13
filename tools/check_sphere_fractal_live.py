"""Focused real-input acceptance for the moving, editable sphere fractal."""
import os, subprocess, json
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/sphere-fractal-live'
OUT.mkdir(exist_ok=True)
with acquire_native_slot('Living sphere fractal / desktop controls',timeout=60):
    stage=stage_runtime()
    args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--resolution','1440x1000','--fixed-fps','60','--script','res://tools/probes/sphere_fractal_live_probe.gd','--','--no-bridges','--void-trial=spatial_lab_ca573ae619','--out='+str(OUT)]
    with (OUT/'native.log').open('w',encoding='utf-8') as log:
        result=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'native.log').read_text(encoding='utf-8',errors='replace')
errors,cleanup=split_errors(log,'SPHERE_FRACTAL_LIVE_DONE',allow_shutdown=result.returncode==0)
assert result.returncode==0 and not errors,log[-12000:]
receipt=json.loads((OUT/'checks.json').read_text(encoding='utf-8'))
assert receipt['passed'],receipt['failed']
print('Passed',len(receipt['checks']),'native motion and real desktop input checks.',flush=True)
