"""Extract and execute the exact printed learner files, including the seed variation."""
from pathlib import Path
import re,json,hashlib,subprocess,os
R=Path(__file__).resolve().parents[1]
O=R/'ada_run/golden_student';O.mkdir(parents=True,exist_ok=True)
text=(R/'commons/maps/Fractal_GoldenSpiral/tutorial.md').read_text(encoding='utf-8')
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text,re.S)
assert len(blocks)==2 and {n for n,_ in blocks}=={'sum_points.gd','point_body.gd'}
hashes={}
for name,code in blocks:
    assert '$' not in code
    p=O/name;p.write_text(code+'\n',encoding='utf-8')
    assert p.read_text(encoding='utf-8')==(R/'doc/book/studies/fractals-through-the-hands/Fractal_GoldenSpiral'/name).read_text(encoding='utf-8')
    assert p.read_text(encoding='utf-8')==(R/'commons/artifacts/golden_mapping_lesson'/name).read_text(encoding='utf-8')
    hashes[name]=hashlib.sha256(p.read_bytes()).hexdigest()
variant=(O/'sum_points.gd').read_text(encoding='utf-8').replace('var values: Array[int] = [1, 1]','var values: Array[int] = [1, 2]')
(O/'different_seeds.gd').write_text(variant,encoding='utf-8')
(O/'extraction.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
report=R/'ada_run/golden_hand_tests.json'
if report.exists():report.unlink()
log=R/'ada_run/golden-hand-engine.log'
with (O/'stdout.log').open('w') as out:
    result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(log),'--script','res://tools/probes/golden_hand.gd'],cwd=R,stdout=out,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
errors=[s for s in log.read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
print('Exit',result.returncode,'script errors',errors)
if report.exists():
    data=json.loads(report.read_text());print('Checks',len(data['checks']),'failures',data['failures'])
assert result.returncode==0 and not errors and report.exists() and json.loads(report.read_text())['passed']
