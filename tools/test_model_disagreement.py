from pathlib import Path
import json,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'ada_run/model_disagreement'
O.mkdir(parents=True,exist_ok=True)
with (O/'stdout.log').open('w',encoding='utf-8') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','gl_compatibility','--audio-driver','Dummy','--resolution','1600x1000','--log-file',str(O/'native.log'),'--script','res://tools/probes/model_disagreement.gd','--','--capture-disagreement','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[s for s in (O/'native.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
assert p.returncode==0 and not errors,(p.returncode,errors)
d=json.loads((O/'report.json').read_text())
assert not d['failed'],d['failed']
print(json.dumps({'passed':len(d['checks']),'captures':len(d['captures'])}))
