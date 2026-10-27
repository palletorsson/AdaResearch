"""Run one focused native curation check under the shared OS lock."""
import json, os, subprocess, sys
from pathlib import Path
from void_trial_runtime import stage_runtime
from void_native_slot import acquire_native_slot
ROOT=Path(__file__).resolve().parents[1];out=ROOT/'ada_run/transformation-workbench';out.mkdir(parents=True,exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8')
slot=acquire_native_slot('Transformation workbench curation');stage=stage_runtime()
with (out/'native.log').open('w',encoding='utf-8') as stream:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--headless','--path',str(stage),'--xr-mode','off','--script','res://tools/probes/transformation_workbench.gd','--','--no-bridges','--out='+str(out)],stdout=stream,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
text=(out/'native.log').read_text(encoding='utf-8',errors='replace')
from void_log_diagnostics import split_errors
errors,shutdown=split_errors(text,'TRANSFORMATION_WORKBENCH ',allow_shutdown=result.returncode==0)
report=json.loads((out/'native.json').read_text()) if (out/'native.json').exists() else {'passed':False,'failed':['no fresh receipt']}
report.update(engine_errors=errors,shutdown_diagnostics=shutdown,engine_exit=result.returncode);report['passed']=bool(report['passed'] and result.returncode==0 and not errors)
(out/'native.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(text[-5500:]);assert report['passed'],report.get('failed')
