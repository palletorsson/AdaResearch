"""Run the exact printed Growth program and a genuinely edited nested-rule copy."""
from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-growth-what-a-branch-keeps'
S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Growth'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/LSystems_Growth/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==4
hashes={}
for folder in ['printed','variation','mutations']:(O/folder).mkdir(exist_ok=True)
for name,code in blocks:
    data=(code+'\n').encode('utf-8')
    assert data==(S/name).read_bytes(),name
    assert '$' not in code
    (O/'printed'/name).write_bytes(data)
    hashes[name]=hashlib.sha256(data).hexdigest()
    if name=='growth.gd':code=code.replace('const RULE := {"F": "F[+F]F[-F]F"}', 'const RULE := {"F": "F[+F[-F]F]F"}')
    (O/'variation'/name).write_text(code+'\n',encoding='utf-8')
for name in ['point_body.gd','line_skin.gd']:
    assert (S/name).read_bytes()==(S.parent/'LSystems_Grammar_Lab'/name).read_bytes()
before=(S.parent/'LSystems_Grammar_Lab/grammar.gd').read_text(encoding='utf-8').split('\nfunc read(')[0]
assert (S/'grammar.gd').read_text(encoding='utf-8').split('\nfunc read(')[0]==before
source=(S/'grammar.gd').read_text(encoding='utf-8')
(O/'mutations/shared_state.gd').write_text(source.replace('stack.append(state.duplicate(true))','stack.append(state)'),encoding='utf-8')
(O/'mutations/first_saved.gd').write_text(source.replace('state = stack.pop_back()','state = stack.pop_front()'),encoding='utf-8')
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf-8') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/growth_branch_lesson.gd'],cwd=R,stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[line for line in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text(encoding='utf-8'));assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'production_comparisons':d['production_comparisons'],'files':list(hashes)}))
