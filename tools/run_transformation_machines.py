"""Serial, isolated native mechanical proof; no visible game window."""
import json,os,subprocess,sys,time
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/transformation-machines';OUT.mkdir(parents=True,exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8')
floor='--floor' in sys.argv;name='floor' if floor else 'native'
slot=acquire_native_slot('Transformation mechanical consequences '+name);stage=stage_runtime()
receipt=OUT/(name+'.json')
if receipt.exists():receipt.replace(OUT/(name+'-'+str(time.time_ns())+'.json'))
with (OUT/(name+'.log')).open('w',encoding='utf-8') as stream:
    mode=['--no-window','--rendering-method','gl_compatibility'] if floor else ['--headless']
    r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),*mode,'--path',str(stage),'--xr-mode','off','--script','res://tools/probes/'+('transformation_machines_floor' if floor else 'transformation_machines')+'.gd','--','--no-bridges','--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/(name+'.log')).read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(log,'TRANSFORMATION_MACHINES_FLOOR ' if floor else 'TRANSFORMATION_MACHINES ',allow_shutdown=r.returncode==0)
report=json.loads(receipt.read_text()) if receipt.exists() else dict(passed=False,failed=['No fresh receipt'])
report.update(engine_exit=r.returncode,engine_errors=errors,shutdown_diagnostics=shutdown);report['passed']=bool(report['passed'] and r.returncode==0 and not errors)
receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(log[-6500:]);assert report['passed'],report
