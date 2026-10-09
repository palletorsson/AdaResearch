"""Test one optional author-made response; required lessons remain unchanged."""
from pathlib import Path
import json,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-a-question-to-follow'
with (O/'stdout.log').open('w',encoding='utf-8') as out:
 result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','gl_compatibility','--resolution','800x600','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/ca_composition_replay.gd'],cwd=R,stdout=out,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[s for s in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
assert result.returncode==0 and not errors,(result.returncode,errors)
d=json.loads((O/'checks.json').read_text(encoding='utf-8'));assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'scope':'Optional recorder/replayer; no required code or museum runtime changes.'}))
