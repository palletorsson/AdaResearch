from pathlib import Path
import re,json,hashlib,subprocess
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-colonization-who-can-answer';S=R/'doc/book/studies/procedural-generation-through-the-hands/PG_Space_Colonization'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/PG_Space_Colonization/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==3
hashes={}
for folder in ['printed','variation','wrong_units','wrong_policy','wrong_hold']:
    (O/folder).mkdir(exist_ok=True)
    for name,source in blocks:
        assert (source+'\n').encode()==(S/name).read_bytes() and '$' not in source
        code=source
        if name=='growth.gd':
            if folder=='variation':code=code.replace('(p - nodes[nearest].position).normalized()','(p - nodes[nearest].position)')
            if folder=='wrong_units':code=code.replace('sum.normalized() * STEP','sum * STEP')
            if folder=='wrong_policy':code=code.replace('if network or not nodes.any','if true or not nodes.any')
        if name=='colony.gd' and folder=='wrong_hold':code=code.replace('model.nodes.duplicate(true)','model.nodes.duplicate()')
        (O/folder/name).write_bytes((code+'\n').encode())
        if folder=='printed':hashes[name]=hashlib.sha256((code+'\n').encode()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/procedural-generation-through-the-hands/PG_Genetic_Evolution/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf-8') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/colonization_answer_lesson.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'source_steps':d['source_steps'],'unit_child':d['unit_child'],'weighted_child':d['weighted_child']}))
