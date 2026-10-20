"""Focused supplied-support check; not part of the independent student suite."""
from pathlib import Path
import subprocess,json,os
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
GODOT='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
with (OUT/'launcher-after.log').open('w',encoding='utf8') as log:
    result=subprocess.run([GODOT,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://doc/book/iterations/2026-10-10-shaders-ghost-student/launcher_check.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=60,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
data=json.loads((OUT/'launcher-check.json').read_text())
assert result.returncode==0 and data['passed'],data
assert not any(s in (OUT/'launcher-after.log').read_text() for s in ['SCRIPT ERROR','Parse Error'])
print(json.dumps({'launcher_checks':len(data['checks']),'passed':data['passed']}))
