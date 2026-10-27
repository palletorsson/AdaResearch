"""One serial native pass, using the normal isolated runtime and OS mutex."""
import json,os,subprocess,sys
from pathlib import Path
from void_trial_runtime import stage_runtime
from void_native_slot import acquire_native_slot
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/transformation-walkability'
sys.stdout.reconfigure(encoding='utf-8')
access='--access-only' in sys.argv;name='access' if access else 'native'
slot=acquire_native_slot('Curated Transformation '+name);stage=stage_runtime()
receipt=OUT/(name+'.json')
if receipt.exists(): receipt.replace(OUT/('previous-'+name+'.json'))
with (OUT/(name+'.log')).open('w',encoding='utf-8') as stream:
    r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--script','res://tools/probes/'+('transformation_access' if access else 'transformation_walkability')+'.gd','--','--no-bridges','--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/(name+'.log')).read_text(encoding='utf-8',errors='replace')
errors,shutdown=split_errors(log,'TRANSFORMATION_ACCESS ' if access else 'TRANSFORMATION_WALKABILITY ',allow_shutdown=r.returncode==0)
report=json.loads(receipt.read_text()) if receipt.exists() else dict(passed=False,failed=['No fresh receipt'])
report.update(engine_exit=r.returncode,engine_errors=errors,shutdown_diagnostics=shutdown)
report['passed']=bool(report['passed'] and r.returncode==0 and not errors)
receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(log[-5500:]);assert report['passed'],report.get('failed')
