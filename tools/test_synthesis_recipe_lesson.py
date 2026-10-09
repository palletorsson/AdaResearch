"""Extract and execute the exact printed learner files, including the depth variation."""
from pathlib import Path
import re,json,hashlib,subprocess,os
R=Path(__file__).resolve().parents[1]
O=R/'ada_run/synthesis_student';O.mkdir(parents=True,exist_ok=True)
text=(R/'commons/maps/Fractal_Synthesis/tutorial.md').read_text(encoding='utf-8')
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text,re.S)
assert len(blocks)==2 and {n for n,_ in blocks}=={'recipe.gd','point_body.gd'}
hashes={}
for name,code in blocks:
    assert '$' not in code
    p=O/name;p.write_text(code+'\n',encoding='utf-8')
    assert p.read_text(encoding='utf-8')==(R/'doc/book/studies/fractals-through-the-hands/Fractal_Synthesis'/name).read_text(encoding='utf-8')
    assert p.read_text(encoding='utf-8')==(R/'commons/artifacts/fractal_recipe_table'/name).read_text(encoding='utf-8')
    hashes[name]=hashlib.sha256(p.read_bytes()).hexdigest()
variant=(O/'recipe.gd').read_text(encoding='utf-8').replace('var recipe := {"seed": Vector2(0, 6), "fraction": 1.0 / 3.0, "steps": 3}', 'var recipe := {"seed": Vector2(0, 6), "fraction": 1.0 / 3.0, "steps": 4}')
(O/'four_cuts.gd').write_text(variant,encoding='utf-8')
(O/'extraction.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
report=R/'ada_run/synthesis_recipe_tests.json'
if report.exists():report.unlink()
log=R/'ada_run/synthesis-recipe-engine.log'
with (O/'stdout.log').open('w',encoding='utf-8') as out:
    result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(log),'--script','res://tools/probes/synthesis_recipe.gd'],cwd=R,stdout=out,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
errors=[s for s in log.read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
print('Exit',result.returncode,'script errors',errors)
if report.exists():
    data=json.loads(report.read_text(encoding='utf-8'));print('Checks',len(data['checks']),'failures',data['failures'])
assert result.returncode==0 and not errors and report.exists() and json.loads(report.read_text(encoding='utf-8'))['passed']
