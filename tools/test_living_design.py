from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-living-a-design-kept';S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Living'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/LSystems_Living/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==4
hashes={}
for folder in ['printed','variation','alias','wrong_round']:
 (O/folder).mkdir(exist_ok=True)
 for name,code in blocks:
  data=(code+'\n').encode();assert data==(S/name).read_bytes() and '$' not in code
  if folder=='printed':hashes[name]=hashlib.sha256(data).hexdigest()
  if folder=='variation' and name=='living.gd':code=code.replace('"angle": 30.0','"angle": 45.0')
  if folder=='alias' and name=='living.gd':code=code.replace('var snapshot := editing.duplicate(true)','var snapshot := editing')
  if folder=='wrong_round' and name=='design.gd':code=code.replace('roundi(float(record.depth) * 0.5)','floori(float(record.depth) * 0.5)')
  (O/folder/name).write_bytes((code+'\n').encode())
for name in ['point_body.gd','line_skin.gd']:assert (S/name).read_bytes()==(S.parent/'LSystems_Competition'/name).read_bytes()
def rewrite(p):return p.read_text(encoding='utf-8').split('func rewrite(')[1].split('\nfunc ')[0]
assert rewrite(S/'design.gd').strip()==rewrite(S.parent/'LSystems_Competition/grammar.gd').strip()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/living_design_lesson.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'production_comparisons':d['production_comparisons']}))
