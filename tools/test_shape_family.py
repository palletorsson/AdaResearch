from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-shape-grammar-a-face-continues';S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Shape_Grammars'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/LSystems_Shape_Grammars/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==3
hashes={}
for folder in ['printed','variation','wrong_order','wrong_tag']:
 (O/folder).mkdir(exist_ok=True)
 for name,code in blocks:
  data=(code+'\n').encode();assert data==(S/name).read_bytes() and '$' not in code
  if folder=='printed':hashes[name]=hashlib.sha256(data).hexdigest()
  if folder=='variation' and name=='family.gd':code=code.replace('"04 REPEAT","faces":[8,9]','"04 REPEAT","faces":[8]')
  if folder=='wrong_order' and name=='faces.gd':code=code.replace('selected.reverse()','# incorrect: keep ascending indices')
  if folder=='wrong_tag' and name=='faces.gd':code=code.replace('"shoulder" if inset else "wall"','"growing"')
  (O/folder/name).write_bytes((code+'\n').encode())
assert (S/'point_body.gd').read_bytes()==(S.parent/'LSystems_Living/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_bytes(json.dumps(hashes,indent=2).encode())
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/shape_family_lesson.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'source_comparisons':d['source_comparisons']}))
