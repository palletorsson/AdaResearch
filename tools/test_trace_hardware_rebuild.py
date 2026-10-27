"""Run real Trace panel lifecycle checks with isolated saves and native lock."""
import json,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
sys.stdout.reconfigure(encoding='utf-8')
OUT=ROOT/'ada_run/trace-hardware-2026-10-26';OUT.mkdir(exist_ok=True)
slot=acquire_native_slot('Trace diptych rebuild regression',timeout=60)
stage=stage_runtime()
with (OUT/'engine.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/trace_hardware_rebuild.gd','--','--no-bridges','--out='+str(OUT/'checks.json')],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
text=(OUT/'engine.log').read_text(encoding='utf-8',errors='replace')
print(text[-5000:])
assert result.returncode==0 and 'SCRIPT ERROR:' not in text and '\nERROR:' not in text
assert json.loads((OUT/'checks.json').read_text(encoding='utf-8'))['passed']
