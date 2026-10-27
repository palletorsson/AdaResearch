import json, os, subprocess, sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else ROOT/'ada_run/intro-logic'
sys.stdout.reconfigure(encoding='utf-8')
slot=acquire_native_slot('Floor14 gravity logic / Jolt truth tables'); stage=stage_runtime()
with (OUT/'native.log').open('w',encoding='utf-8') as stream:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--headless','--rendering-method','gl_compatibility','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/intro_logic.gd','--','--no-bridges','--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=600,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'native.log').read_text(encoding='utf-8',errors='replace'); errors,shutdown=split_errors(log,'INTRO_LOGIC_RESULT ',allow_shutdown=result.returncode==0)
report=json.loads((OUT/'checks.json').read_text()) if (OUT/'checks.json').exists() else {'passed':False}
report.update(engine_exit=result.returncode,engine_errors=errors,shutdown_diagnostics=shutdown)
report['passed']=bool(report['passed'] and result.returncode==0 and not errors)
(OUT/'checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(log[-8000:]); assert report['passed'],{k:v for k,v in report.items() if k!='observations'}
