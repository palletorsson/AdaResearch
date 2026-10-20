"""Native model, scene, control and learner-transfer assertions; no headset claim."""
from pathlib import Path
import json,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-the-same-throw-different-steps'
with (O/'core-stdout.log').open('w',encoding='utf-8') as out:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'core-engine.log'),'--script','res://tools/probes/euler_step_test.gd','--','res://'+(O/'checks.json').relative_to(R).as_posix()],cwd=R,stdout=out,stderr=subprocess.STDOUT,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[s for s in (O/'core-engine.log').read_text(encoding='utf-8').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
assert p.returncode==0 and not errors,(p.returncode,errors)
d=json.loads((O/'checks.json').read_text(encoding='utf-8'));assert d['passed'],d['failures']
print(json.dumps({'checks':len(d['checks']),'observations':d['observations']}))
