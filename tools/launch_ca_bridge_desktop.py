"""Human play session. Keep the native slot while the player owns this desktop."""
import json,os,subprocess,sys,time
from pathlib import Path
from void_native_slot import acquire_native_slot
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/ca-bridge-desktop';OUT.mkdir(exist_ok=True)
slot=acquire_native_slot('Palle playing CA bridge floor107; no automated native jobs',timeout=60)
for name in ['desktop-ready.json','launch-release.json']:
 p=OUT/name
 if p.exists():p.unlink()
with (OUT/'game.log').open('w',encoding='utf8') as stream:
 proc=subprocess.Popen([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--windowed','--position','120,80','--resolution','1440x900','--rendering-method','mobile','--xr-mode','off','--path',str(ROOT),'--script','res://ada_run/ca-bridge-desktop/play.gd','--','--no-bridges','--void-start-floor=107'],cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 (OUT/'session.json').write_text(json.dumps({'pid':proc.pid,'floor':107,'native_slot':'held for human play until game closes','started':time.time()},indent=2)+'\n',encoding='utf8')
 code=proc.wait()
(OUT/'closed.json').write_text(json.dumps({'pid':proc.pid,'exit_code':code,'closed':time.time()},indent=2)+'\n',encoding='utf8')
