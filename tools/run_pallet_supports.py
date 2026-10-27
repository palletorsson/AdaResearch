import json,os,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/pallet-supports';OUT.mkdir(parents=True,exist_ok=True);capture='--capture' in sys.argv
sys.stdout.reconfigure(encoding='utf-8');slot=acquire_native_slot('Pallet support AND / '+('capture' if capture else 'Jolt manual AND'));stage=stage_runtime()
args=['--windowed','--position','-3000,-3000','--resolution','1440x900'] if capture else ['--headless']
logfile=OUT/('capture.log' if capture else 'native.log')
with logfile.open('w',encoding='utf-8') as stream:
 r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),*args,'--rendering-method','gl_compatibility','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/pallet_supports.gd','--','--no-bridges','--out='+str(OUT),*(['--capture'] if capture else [])],stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
log=logfile.read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(log,'PALLET_RESULT ',allow_shutdown=r.returncode==0);file=OUT/('capture-checks.json' if capture else 'checks.json')
report=json.loads(file.read_text()) if file.exists() else {'passed':False};report.update(engine_exit=r.returncode,engine_errors=errors,shutdown_diagnostics=shutdown);report['passed']=bool(report['passed'] and r.returncode==0 and not errors);file.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(log[-6500:]);assert report['passed'],report
