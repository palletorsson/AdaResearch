"""Keep the native slot reserved until Palle closes the visible play window."""
import json,os,subprocess,time
from pathlib import Path
from void_native_slot import acquire_native_slot
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/matter-studies-desktop';OUT.mkdir(parents=True,exist_ok=True)
slot=acquire_native_slot('Palle playing floor46 matter studies; no automated native jobs',timeout=60)
for name in ['desktop-ready.json','launch-release.json']:
    file=OUT/name
    if file.exists():file.unlink()
with (OUT/'game.log').open('w',encoding='utf-8') as log:
    process=subprocess.Popen([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--windowed','--position','120,80','--resolution','1440x900','--rendering-method','gl_compatibility','--xr-mode','off','--path',str(ROOT),'--script','res://tools/probes/play_matter_studies.gd','--','--no-bridges','--void-start-floor=46'],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    (OUT/'session.json').write_text(json.dumps(dict(pid=process.pid,floor=46,started=time.time(),native_slot='held for human play until game closes'),indent=2)+'\n',encoding='utf-8')
    result=process.wait()
(OUT/'closed.json').write_text(json.dumps(dict(pid=process.pid,exit_code=result,closed=time.time()),indent=2)+'\n',encoding='utf-8')
