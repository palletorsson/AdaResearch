import os,subprocess,sys,json
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
R=Path(__file__).resolve().parents[1];out=R/'ada_run/matter-reference';sys.stdout.reconfigure(encoding='utf-8');slot=acquire_native_slot('Original marble gate boards');stage=stage_runtime()
with (out/'marble-native.log').open('w',encoding='utf-8') as log:
 r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--headless','--fixed-fps','240' if '--240' in sys.argv else '60','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--script','res://tools/probes/marble_reference.gd','--','--no-bridges','--out='+str(out),*sys.argv[1:]],stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
text=(out/'marble-native.log').read_text(encoding='utf-8',errors='replace');errors,_=split_errors(text,'MATTER_REFERENCE_RESULT ',allow_shutdown=r.returncode==0);print(text[-11000:]);assert r.returncode==0 and not errors,errors
