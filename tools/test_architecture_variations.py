from pathlib import Path
import json, subprocess
R=Path(__file__).resolve().parents[1]
O=R/'ada_run/architecture_variations'
O.mkdir(parents=True,exist_ok=True)
with (O/'stdout.log').open('w',encoding='utf-8') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','gl_compatibility','--audio-driver','Dummy','--resolution','1600x1000','--log-file',str(O/'native.log'),'--script','res://tools/probes/architecture_variations.gd','--','--capture-variations','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[line for line in (O/'native.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line]
assert p.returncode==0 and not errors,(p.returncode,errors)
d=json.loads((O/'report.json').read_text())
assert not d['failed'],d['failed']
print(json.dumps({'checks':len(d['checks']),'passed':True,'captures':len(list(O.glob('*.png')))}))
