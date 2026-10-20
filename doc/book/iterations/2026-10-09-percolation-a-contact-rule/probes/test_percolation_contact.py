from pathlib import Path
import re,json,hashlib,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-percolation-a-contact-rule'
S=R/'doc/book/studies/procedural-generation-through-the-hands/PG_Percolation_Network'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/PG_Percolation_Network/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==3
hashes={}
for folder in ['printed','variation','wrong_buffer','wrong_contact','wrong_empty']:
    (O/folder).mkdir(exist_ok=True)
    for name,source in blocks:
        assert (source+'\n').encode()==(S/name).read_bytes() and '$' not in source
        code=source
        if name=='reach.gd':
            if folder in ['variation','wrong_contact']:code=code.replace('Vector3i(0,0,-1)]','Vector3i(0,0,-1), Vector3i(1,1,1), Vector3i(-1,-1,-1)]')
            if folder=='wrong_buffer':code=code.replace('var next := reached.duplicate()','var next := reached')
            if folder=='wrong_empty':
                code=code.replace('for cell: Vector3i in occupied:', 'for cell: Vector3i in all_cells():')
                code+='\n\nfunc all_cells() -> Array:\n\tvar cells: Array = []\n\tfor x in SIZE:\n\t\tfor y in SIZE:\n\t\t\tfor z in SIZE: cells.append(Vector3i(x,y,z))\n\treturn cells'
        (O/folder/name).write_bytes((code+'\n').encode())
        if folder=='printed':hashes[name]=hashlib.sha256((code+'\n').encode()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(S.parent/'PG_Branching_Growth/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf-8') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/percolation_contact_lesson.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'source_steps':d['source_steps'],'density_counts':d['density_counts']}))
