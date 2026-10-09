"""Extract exactly what the learner reads, execute it, then test transfer/faults."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-what-a-neighbour-offers'
S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_SoftRules'
blocks=re.findall(r'```gdscript\n(.*?)\n```',(R/'commons/maps/CA_SoftRules/tutorial.md').read_text(encoding='utf-8'),re.S)
names=['field.gd','exchange.gd','point_body.gd'];assert len(blocks)==len(names)
(O/'printed').mkdir(exist_ok=True);hashes={}
for name,code in zip(names,blocks):
 assert code+'\n'==(S/name).read_text(encoding='utf-8')
 (O/'printed'/name).write_bytes((code+'\n').encode('utf-8'));hashes[name]=hashlib.sha256((O/'printed'/name).read_bytes()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(S.parent/'CA_ExpandingSpace/point_body.gd').read_bytes()
for variant in ['no-subtraction','in-place','edge-seed']:
 d=O/'variants'/variant;d.mkdir(parents=True,exist_ok=True)
 for name,code in zip(names,blocks):
  if name=='field.gd' and variant=='no-subtraction':code=code.replace(' - 4.0 * values[index(x, y)]','')
  if name=='field.gd' and variant=='in-place':code=code.replace('next_v[i] = answer.y','next_v[i] = answer.y\n\t\t\tu[i] = answer.x\n\t\t\tv[i] = answer.y')
  if name=='exchange.gd' and variant=='edge-seed':code=code.replace('right.reset()','right.reset()\n\tleft.seed_at(Vector2i(0, 0))\n\tright.seed_at(Vector2i(0, 0))')
  (d/name).write_bytes((code+'\n').encode('utf-8'))
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
with (O/'stdout.log').open('w',encoding='utf-8') as out:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--resolution','800x600','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/ca_exchange_lesson.gd'],cwd=R,stdout=out,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[s for s in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
assert p.returncode==0 and not errors,(p.returncode,errors)
report=json.loads((O/'checks.json').read_text(encoding='utf-8'));assert report['passed'],report['failures']
print(json.dumps({'passed':True,'checks':len(report['checks']),'exact_printed_files':names,'maximum_parity_difference':report['maximum_parity_difference']}))
