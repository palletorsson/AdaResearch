"""Hold the native slot until the user's visible desktop game closes."""
import json,os,subprocess,time,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/pallet-desktop';OUT.mkdir(parents=True,exist_ok=True)
slot=acquire_native_slot('Palle playing floor12 pallet track; no automated native jobs',timeout=60)
for name in ['desktop-ready.json','launch-release.json']:
 p=OUT/name
 if p.exists():p.unlink()
with (OUT/'game.log').open('w',encoding='utf-8') as log:
 p=subprocess.Popen([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--windowed','--position','120,80','--resolution','1440x900','--rendering-method','gl_compatibility','--xr-mode','off','--path',str(ROOT),'--script','res://tools/probes/play_pallet_track.gd','--','--no-bridges','--void-start-floor=12',*(['--pallet-study-id=pallet-or-workshop'] if '--or' in sys.argv else [])],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 (OUT/'session.json').write_text(json.dumps({'pid':p.pid,'floor':12,'native_slot':'held for human play until game closes','started':time.time()},indent=2)+'\n',encoding='utf-8')
 code=p.wait()
(OUT/'closed.json').write_text(json.dumps({'pid':p.pid,'exit_code':code,'closed':time.time()},indent=2)+'\n',encoding='utf-8')
