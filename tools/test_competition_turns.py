from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-competition-the-next-turn';S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Competition'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/LSystems_Competition/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==5
hashes={}
for folder in ['printed','variation','alias','winter_first']:
 (O/folder).mkdir(exist_ok=True)
 for name,code in blocks:
  data=(code+'\n').encode();assert data==(S/name).read_bytes() and '$' not in code
  if folder=='printed':hashes[name]=hashlib.sha256(data).hexdigest()
  if folder=='variation' and name=='soil.gd':code=code.replace('Vector2i(10, 10)','Vector2i(14, 10)')
  if folder=='alias' and name=='competition.gd':code=code.replace('soil.cells.duplicate(true)','soil.cells')
  if folder=='winter_first' and name=='competition.gd':code=code.replace('if tree.generation < CAP:', 'if tree.generation < CAP and not winter:')
  (O/folder/name).write_bytes((code+'\n').encode())
for name in ['grammar.gd','point_body.gd','line_skin.gd']:assert (S/name).read_bytes()==(S.parent/'LSystems_Grammars_And_Curves'/name).read_bytes()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/competition_turns_lesson.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'production_comparisons':d['production_comparisons']}))
