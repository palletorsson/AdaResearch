"""Exercise the shared door clock, physical passage and editable frame assemblies."""
import os,sys,subprocess,json
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
from validate_void_rooms import editor_validation
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-23-entropy-workshop/native'
OUT.mkdir(parents=True,exist_ok=True)
report=editor_validation(json.loads((OUT.parent/'draft-rooms.json').read_text(encoding='utf8')))
assert report['valid'], report['errors']
slot=acquire_native_slot('Entropy workshop');stage=stage_runtime()
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--resolution','1440x900','--rendering-method','mobile','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/entropy_workshop_probe.gd','--','--no-bridges','--void-start-floor=73','--void-draft='+str(OUT.parent/'draft-rooms.json'),'--out='+str(OUT)]
if '--desktop-only' in sys.argv:args.append('--desktop-only')
with (OUT/'native.log').open('w',encoding='utf8') as log:
    result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=900,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'native.log').read_text(encoding='utf8',errors='replace')
errors,shutdown=split_errors(log,'ENTROPY_WORKSHOP_RESULT',allow_shutdown=result.returncode==0)
print(log[-5000:]);assert result.returncode==0 and not errors and 'Parse Error' not in log,(errors,shutdown)
checks=json.loads((OUT/'checks.json').read_text(encoding='utf8'))
assert checks['passed'] and len(checks['checks'])>40, checks
