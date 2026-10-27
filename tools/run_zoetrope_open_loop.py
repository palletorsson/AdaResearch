"""Focused rendered check of the requested open gaps and fixed-size loop."""
import hashlib,json,os,subprocess
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/scale-zoetrope-open-loop';OUT.mkdir(parents=True,exist_ok=True)
saved=(ROOT/'commons/void/rooms.json').read_bytes()
(OUT/'draft-rooms.json').write_bytes(saved)
slot=acquire_native_slot('Zoetrope open gaps / fixed-size loop');stage=stage_runtime()
with (OUT/'native.log').open('w',encoding='utf-8') as stream:
 result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--windowed','--position','-3000,-3000','--resolution','1440x900','--rendering-method','gl_compatibility','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/zoetrope_open_loop.gd','--','--no-bridges','--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'native.log').read_text(encoding='utf-8',errors='replace')
errors,shutdown=split_errors(log,'ZOETROPE_OPEN_LOOP_RESULT ',allow_shutdown=result.returncode==0)
report=json.loads((OUT/'checks.json').read_text()) if (OUT/'checks.json').exists() else {'passed':False,'failed':['No receipt']}
before=json.loads(saved);after=json.loads((ROOT/'commons/void/rooms.json').read_bytes())
report.update(engine_exit=result.returncode,engine_errors=errors,shutdown_diagnostics=shutdown,rooms_sha256=hashlib.sha256(saved).hexdigest(),floor59_unchanged=before['floors'][59]==after['floors'][59],concurrent_changed_floors=[i for i,(a,b) in enumerate(zip(before['floors'],after['floors'])) if a!=b])
report['passed']=bool(report['passed'] and result.returncode==0 and not errors and report['floor59_unchanged'])
(OUT/'checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(log[-2500:]);assert report['passed'],report
