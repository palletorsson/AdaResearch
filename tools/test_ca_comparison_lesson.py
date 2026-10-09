"""Exact printed files, native runtime, independent transfer and deliberate defects."""
from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-08-ca-two-ways-to-make';S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_AgentsCircuits'
blocks=re.findall(r'```gdscript\n(.*?)\n```',(R/'commons/maps/CA_AgentsCircuits/tutorial.md').read_text(encoding='utf-8'),re.S)
names=['procedures.gd','comparison.gd','point_body.gd'];assert len(blocks)==3
(O/'printed').mkdir(exist_ok=True);hashes={}
for name,code in zip(names,blocks):
 assert code+'\n'==(S/name).read_text(encoding='utf-8')
 (O/'printed'/name).write_bytes((code+'\n').encode('utf-8'));hashes[name]=hashlib.sha256((O/'printed'/name).read_bytes()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(S.parent/'CA_SoftRules/point_body.gd').read_bytes()
for variant in ['or-fault','in-place','three-seeds']:
 d=O/'variants'/variant;d.mkdir(parents=True,exist_ok=True)
 for name,code in zip(names,blocks):
  if name=='procedures.gd' and variant=='or-fault':code=code.replace('left != right','left or right')
  if name=='procedures.gd' and variant=='in-place':code=code.replace('next[i] = left != right','next[i] = left != right\n\t\told[i] = next[i]')
  if name=='comparison.gd' and variant=='three-seeds':code=code.replace('var seed_sites: Array[int] = [16]','var seed_sites: Array[int] = [14, 16, 18]')
  (d/name).write_bytes((code+'\n').encode('utf-8'))
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
with (O/'stdout.log').open('w',encoding='utf-8') as out:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--resolution','800x600','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/ca_comparison_lesson.gd'],cwd=R,stdout=out,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[line for line in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line]
assert p.returncode==0 and not errors,(p.returncode,errors)
d=json.loads((O/'checks.json').read_text(encoding='utf-8'));assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'exact_printed_files':names}))
