"""Extract the three printed files and execute them plus the production Koch reader."""
from pathlib import Path
import re, json, hashlib, subprocess, os
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/koch_student'; OUT.mkdir(parents=True, exist_ok=True)
text=(ROOT/'commons/maps/Fractal_KochSierpinski/tutorial.md').read_text(encoding='utf-8')
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text,re.S)
assert len(blocks)==3 and {n for n,_ in blocks}=={'koch.gd','point_body.gd','line_skin.gd'}
manifest={}
for name,code in blocks:
    assert '$' not in code
    target=OUT/name; target.write_text(code+'\n',encoding='utf-8')
    assert target.read_text(encoding='utf-8')==(ROOT/'doc/book/studies/fractals-through-the-hands/Fractal_KochSierpinski'/name).read_text(encoding='utf-8')
    manifest[name]=hashlib.sha256(target.read_bytes()).hexdigest()
(OUT/'extraction.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
report=ROOT/'ada_run/koch_hand_tests.json'
if report.exists(): report.unlink()
log=ROOT/'ada_run/koch-hand-engine.log'
with (OUT/'stdout.log').open('w',encoding='utf-8') as stream:
    result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(log),'--script','res://tools/probes/koch_hand.gd'],cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=70,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
errors=[s for s in log.read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
print('Exit',result.returncode,'script errors',errors)
if report.exists():
    data=json.loads(report.read_text()); print('Checks',len(data['checks']),'failures',data['failures'])
assert result.returncode==0 and not errors and report.exists()
assert json.loads(report.read_text())['passed']
