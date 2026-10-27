from pathlib import Path
import json,os,subprocess,sys
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
sys.stdout.reconfigure(encoding='utf8')
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'doc/ports/2026-10-27-void-visual-profiles'
slot=acquire_native_slot('Void visual profile launch and F8');stage=stage_runtime()
with (OUT/'controls.log').open('w',encoding='utf8') as log:
    p=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--xr-mode','off','--rendering-method','mobile','--script','res://tools/probes/void_visual_profile_controls.gd','--','--no-bridges','--void-start-floor=16','--void-look=finish','--receipt='+str(OUT/'controls.json')],stdout=log,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
text=(OUT/'controls.log').read_text(encoding='utf8',errors='replace');errors,_=split_errors(text,'VOID_VISUAL_CONTROLS ',allow_shutdown=p.returncode==0)
print(text[-1600:]);assert p.returncode==0 and not errors,errors
assert json.loads((OUT/'controls.json').read_text(encoding='utf8'))['passed']
print('PASS: launch flag, F8 and source material restoration')
