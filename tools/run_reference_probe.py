"""Serial runner for the collection's focused native physics probes."""
from pathlib import Path
import os,json,subprocess,sys
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
R=Path(__file__).resolve().parents[1];sys.stdout.reconfigure(encoding='utf-8');name=sys.argv[1];out=R/'ada_run/matter-reference';capture='--capture' in sys.argv
slot=acquire_native_slot('Matter and Logic / '+name);stage=stage_runtime();logfile=out/(name+'-native.log')
with logfile.open('w',encoding='utf-8') as log:
 p=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window' if capture else '--headless','--fixed-fps','60','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--script','res://tools/probes/'+name+'.gd','--','--no-bridges','--out='+str(out),*sys.argv[2:]],stdout=log,stderr=subprocess.STDOUT,timeout=360 if capture else 180,creationflags=subprocess.CREATE_NO_WINDOW)
text=logfile.read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(text,'MATTER_REFERENCE_RESULT ',allow_shutdown=p.returncode==0);print(text[-6500:]);assert p.returncode==0 and not errors,errors
