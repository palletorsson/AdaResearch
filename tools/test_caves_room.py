from pathlib import Path
import re,json,hashlib,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-caves-a-route-needs-room'
S=R/'doc/book/studies/procedural-generation-through-the-hands/PG_Caves_Mazes'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/PG_Caves_Mazes/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==3
hashes={}
for folder in ['printed','variation','wrong_square','wrong_height','wrong_history']:
    (O/folder).mkdir(exist_ok=True)
    for name,source in blocks:
        assert (source+'\n').encode()==(S/name).read_bytes() and '$' not in source
        code=source
        if name=='carver.gd':
            if folder=='variation':code=code.replace('HEADROOM := 2','HEADROOM := 3')
            if folder=='wrong_square':code=code.replace('Vector2i(dx, dz).length() <= RADIUS','maxi(absi(dx), absi(dz)) <= RADIUS')
            if folder=='wrong_height':code=code.replace('for dy in HEADROOM:','for dy in HEADROOM + 1:')
            if folder=='wrong_history':code=code.replace('history.append(center)','if history.has(center): return\n\thistory.append(center)')
        (O/folder/name).write_bytes((code+'\n').encode())
        if folder=='printed':hashes[name]=hashlib.sha256((code+'\n').encode()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(S.parent/'PG_Percolation_Network/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf-8') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/caves_room_lesson.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'source_comparisons':d['source_comparisons'],'counts':d['counts']}))
