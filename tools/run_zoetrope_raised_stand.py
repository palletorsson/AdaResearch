"""Serial native check of the staged open two-metre zoetrope."""
import hashlib,json,os,subprocess
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/zoetrope-raised-stand'
digest=hashlib.sha256((OUT/'draft-rooms.json').read_bytes()).hexdigest()
slot=acquire_native_slot('Raised open zoetrope');stage=stage_runtime()
with (OUT/'native.log').open('w',encoding='utf-8') as stream:
 result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--windowed','--position','-3000,-3000','--resolution','1440x900','--rendering-method','gl_compatibility','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/zoetrope_raised_stand.gd','--','--no-bridges','--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'native.log').read_text(encoding='utf-8',errors='replace')
errors,shutdown=split_errors(log,'ZOETROPE_RAISED_RESULT ',allow_shutdown=result.returncode==0)
report=json.loads((OUT/'checks.json').read_text()) if (OUT/'checks.json').exists() else {'passed':False,'failed':['No receipt']}
report.update(engine_exit=result.returncode,engine_errors=errors,shutdown_diagnostics=shutdown,draft_sha256=digest)
report['passed']=bool(report['passed'] and result.returncode==0 and not errors)
(OUT/'checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(log[-2000:]);assert report['passed'],report
