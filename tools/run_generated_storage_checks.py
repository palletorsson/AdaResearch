"""Native storage/game regression check, serialized with exports and migration."""
import json,os,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
from generated_storage import generated_root,model_directory,PROJECT
ROOT=PROJECT;OUT=ROOT/'ada_run/generated-storage-migration';sys.stdout.reconfigure(encoding='utf-8')
assert not generated_root().is_relative_to(ROOT)
assert model_directory(ROOT/'ada_run/example/native-models')==generated_root()/'project/ada_run/example/native-models'
assert model_directory(generated_root()/'public/void-models')==generated_root()/'public/void-models'
slot=acquire_native_slot('External models desktop and XR smoke');stage=stage_runtime()
with (OUT/'native.log').open('w',encoding='utf-8') as log:
 result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--windowed','--position','-3000,-3000','--resolution','1440x900','--rendering-method','gl_compatibility','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/generated_storage_smoke.gd','--','--no-bridges','--void-start-floor=7','--out='+str(OUT)],stdout=log,stderr=subprocess.STDOUT,timeout=300,creationflags=subprocess.CREATE_NO_WINDOW)
text=(OUT/'native.log').read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(text,'GENERATED_STORAGE_RESULT ',allow_shutdown=result.returncode==0)
r=json.loads((OUT/'native-checks.json').read_text()) if (OUT/'native-checks.json').exists() else {'passed':False,'failed':['No fresh native receipt']}
r.update(engine_exit=result.returncode,engine_errors=errors,shutdown_diagnostics=shutdown);r['passed']=bool(r['passed'] and result.returncode==0 and not errors)
(OUT/'native-checks.json').write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(text[-4000:]);assert r['passed'],r
