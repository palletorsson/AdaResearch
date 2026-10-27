import os,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];OUT=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else ROOT/'ada_run/intro-logic'
sys.stdout.reconfigure(encoding='utf-8');slot=acquire_native_slot('Floor14 gravity logic / screenshots');stage=stage_runtime()
with (OUT/'capture.log').open('w',encoding='utf-8') as stream:
    r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--windowed','--position','-3000,-3000','--resolution','1440x900','--rendering-method','gl_compatibility','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/intro_logic_capture.gd','--','--no-bridges','--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=300,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'capture.log').read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(log,'INTRO_CAPTURE_RESULT ',allow_shutdown=r.returncode==0)
assert r.returncode==0 and not errors,(r.returncode,errors);print(log[-1000:])
