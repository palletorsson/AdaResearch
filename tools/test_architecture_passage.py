from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-architecture-a-place-to-pass';S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Architecture'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/LSystems_Architecture/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==4
for name in ['printed','variation','mutations']:(O/name).mkdir(exist_ok=True)
hashes={}
for name,code in blocks:
 data=(code+'\n').encode();assert data==(S/name).read_bytes() and '$' not in code
 (O/'printed'/name).write_bytes(data);hashes[name]=hashlib.sha256(data).hexdigest()
 if name=='architecture.gd':code=code.replace('"F[+RF][-RF]F"','"F[+FR][-FR]F"')
 (O/'variation'/name).write_bytes((code+'\n').encode())
assert (S/'point_body.gd').read_bytes()==(S.parent/'LSystems_Grammars_And_Curves/point_body.gd').read_bytes()
def rewrite(p):return p.read_text(encoding='utf-8').split('func rewrite(')[1].split('\nfunc ')[0]
assert rewrite(S/'grammar.gd')==rewrite(S.parent/'LSystems_Grammars_And_Curves/grammar.gd')
code=(S/'footprint.gd').read_text(encoding='utf-8')
(O/'mutations/internal_walls.gd').write_bytes(code.replace('if occupied.has(cell + direction): continue','if false: continue').encode())
(O/'mutations/coarse_grid.gd').write_bytes(code.replace('const PITCH := 0.1','const PITCH := 0.2').encode())
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/architecture_passage_lesson.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'production_comparisons':d['production_comparisons']}))
