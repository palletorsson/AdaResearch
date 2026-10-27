"""Serial native checks for source-faithful material computation ports."""
import json,os,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/matter-reference';OUT.mkdir(parents=True,exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8');slot=acquire_native_slot('source-faithful Matter Gates');stage=stage_runtime()
with (OUT/'native.log').open('w',encoding='utf-8') as log:
 r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--headless','--fixed-fps','60','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--script','res://tools/probes/matter_reference.gd','--','--no-bridges','--out='+str(OUT),*sys.argv[1:]],stdout=log,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
text=(OUT/'native.log').read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(text,'MATTER_REFERENCE_RESULT ',allow_shutdown=r.returncode==0)
p=OUT/'checks.json';d=json.loads(p.read_text(encoding='utf-8')) if p.exists() else {'passed':False};d.update(engine_exit=r.returncode,engine_errors=errors,shutdown_diagnostics=shutdown);d['passed']=bool(d['passed'] and not errors and r.returncode==0);p.write_text(json.dumps(d,indent=2)+'\n',encoding='utf-8');print(text[-13000:]);assert d['passed'],d.get('failures',errors)
