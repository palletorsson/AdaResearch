from pathlib import Path
import json,subprocess
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/portal-player-descent';OUT.mkdir(exist_ok=True)
with acquire_native_slot('Portal descent / real player collision'):
 stage=stage_runtime()
 with (OUT/'native.log').open('w',encoding='utf8') as log:
  r=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/portal_player_descent.gd','--','--no-bridges','--void-start-floor=16','--out='+str(OUT)],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
text=(OUT/'native.log').read_text(encoding='utf8',errors='replace');assert r.returncode==0 and 'SCRIPT ERROR' not in text,text[-6500:]
checks=json.loads((OUT/'checks.json').read_text(encoding='utf8'));assert checks['passed'],checks;print(str(len(checks['checks']))+' player descent checks passed')
