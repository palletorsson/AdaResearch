"""Bounded hidden-window native test/capture, serialized with the shared OS lock."""
from pathlib import Path
import json,os,subprocess,sys
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/rotation-z-width';OUT.mkdir(parents=True,exist_ok=True)
sys.stdout.reconfigure(encoding='utf8')
slot=acquire_native_slot('Rotation Z width comparison');stage=stage_runtime()
with (OUT/'engine.log').open('w',encoding='utf8') as log:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/rotation_z_width.gd','--','--no-bridges','--out='+str(OUT)],stdout=log,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
text=(OUT/'engine.log').read_text(encoding='utf8',errors='replace');errors,shutdown=split_errors(text,'ROTATION_Z_WIDTH_RESULT ',allow_shutdown=result.returncode==0)
receipt=json.loads((OUT/'checks.json').read_text(encoding='utf8')) if (OUT/'checks.json').exists() else {'passed':False,'failed':['No receipt']}
receipt.update(engine_exit=result.returncode,engine_errors=errors,shutdown_diagnostics=shutdown)
(OUT/'checks.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
print(text[-5000:]);assert result.returncode==0 and receipt['passed'] and not errors,receipt.get('failed',[])+errors
print(len(receipt['checks']),'focused native checks passed')
