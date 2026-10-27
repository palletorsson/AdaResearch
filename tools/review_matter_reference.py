import json,os,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
R=Path(__file__).resolve().parents[1];out=R/'ada_run/matter-reference';capture='--capture' in sys.argv
sys.stdout.reconfigure(encoding='utf-8');slot=acquire_native_slot('Matter Gates '+('captures' if capture else 'placement review'));stage=stage_runtime()
with (out/('capture.log' if capture else 'review.log')).open('w',encoding='utf-8') as log:
 r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window' if capture else '--headless','--fixed-fps','60','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--script','res://tools/probes/matter_reference_review.gd','--','--no-bridges','--void-trial=matter_logic_reference','--out='+str(out),*(['--capture'] if capture else [])],stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
text=(out/('capture.log' if capture else 'review.log')).read_text(encoding='utf-8',errors='replace');errors,_=split_errors(text,'MATTER_REFERENCE_RESULT ',allow_shutdown=r.returncode==0);print(text[-6500:]);assert r.returncode==0 and not errors,errors
