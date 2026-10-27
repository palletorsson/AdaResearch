from pathlib import Path
import os,subprocess,json,sys
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
sys.stdout.reconfigure(encoding='utf8')
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/rotation-electric/visuals';OUT.mkdir(parents=True,exist_ok=True)
slot=acquire_native_slot('Rotation electric visual capture');stage=stage_runtime()
with (OUT/'engine.log').open('w',encoding='utf8') as log:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/rotation_electric_photos.gd','--','--no-bridges','--void-start-floor=16','--out='+str(OUT)],stdout=log,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
text=(OUT/'engine.log').read_text(encoding='utf8',errors='replace');errors,shutdown=split_errors(text,'ROTATION_VISUAL_RESULT ',allow_shutdown=result.returncode==0)
receipt=json.loads((OUT/'capture-checks.json').read_text(encoding='utf8')) if (OUT/'capture-checks.json').exists() else {'passed':False}
print(text[-1500:]);assert result.returncode==0 and receipt['passed'] and not errors,errors
