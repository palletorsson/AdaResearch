from pathlib import Path
import re,json,hashlib,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-sculpted-what-the-centres-keep'
S=R/'doc/book/studies/procedural-generation-through-the-hands/PG_Sculpted_Forms'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/PG_Sculpted_Forms/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==4
hashes={}
for folder in ['printed','variation','wrong_world','wrong_round','wrong_faces']:
    (O/folder).mkdir(exist_ok=True)
    for name,source in blocks:
        assert (source+'\n').encode()==(S/name).read_bytes() and '$' not in source
        code=source
        if name=='sample.gd':
            if folder=='variation':code=code.replace('EXTENT_FACTOR := 1.0','EXTENT_FACTOR := 0.5')
            if folder=='wrong_world':code=code.replace('frame.to_local(body.global_position)','body.global_position')
            if folder=='wrong_round':code=code.replace('/ cell_size).floor()', '/ cell_size).round()')
            if folder=='wrong_faces':code=code.replace('if not cells.has(cell + direction):','if true:')
        (O/folder/name).write_bytes((code+'\n').encode())
        if folder=='printed':hashes[name]=hashlib.sha256((code+'\n').encode()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(S.parent/'PG_Caves_Mazes/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf-8') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/sculpted_sample_lesson.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'source_comparisons':d['source_comparisons'],'counts':d['counts']}))
