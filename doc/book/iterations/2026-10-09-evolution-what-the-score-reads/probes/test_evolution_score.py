from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-evolution-what-the-score-reads';S=R/'doc/book/studies/procedural-generation-through-the-hands/PG_Genetic_Evolution'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/PG_Genetic_Evolution/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==3
hashes={}
for folder in ['printed','variation','wrong_score','wrong_rank','wrong_hold']:
    (O/folder).mkdir(exist_ok=True)
    for name,code in blocks:
        data=(code+'\n').encode();assert data==(S/name).read_bytes() and '$' not in code
        if folder=='printed':hashes[name]=hashlib.sha256(data).hexdigest()
        if folder=='variation' and name=='evaluator.gd':code=code.replace('s.x*s.y*s.z*8.0','s.x*s.y*s.z')
        if folder=='wrong_score' and name=='evaluator.gd':code=code.replace('abs(estimate(candidate)-target)','(estimate(candidate)-target)')
        if folder=='wrong_rank' and name=='evaluator.gd':code=code.replace('candidates.duplicate()','candidates')
        if folder=='wrong_hold' and name=='selection.gd':code=code.replace('ordered[0].duplicate(true)','ordered[0].duplicate()')
        (O/folder/name).write_bytes((code+'\n').encode())
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/lsystems-through-the-hands/Assemblage_Same_Desire/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_bytes((json.dumps(hashes,indent=2)+'\n').encode())
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/evolution_score_lesson.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'source_comparisons':d['source_comparisons']}))
