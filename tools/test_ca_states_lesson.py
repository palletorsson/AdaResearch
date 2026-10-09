from pathlib import Path
import json,re,subprocess,hashlib,shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-a-state-that-lingers'
S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_ElementaryRules'
blocks=re.findall(r'```gdscript\n(.*?)\n```',(R/'commons/maps/CA_ElementaryRules/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==2
(O/'printed').mkdir(exist_ok=True);hashes={}
for name,code in zip(['volume.gd','point_body.gd'],blocks):
 assert code+'\n'==(S/name).read_text(encoding='utf-8')
 (O/'printed'/name).write_bytes((code+'\n').encode('utf-8'))
 hashes[name]=hashlib.sha256((O/'printed'/name).read_bytes()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(S.parent/'CA_Introduction/point_body.gd').read_bytes()
for variant in ['reverse','count-fading','rebirth-fading']:
 d=O/'variants'/variant;d.mkdir(parents=True,exist_ok=True);code=blocks[0]
 if variant=='reverse':code=code.replace('range(1, SIZE - 1)','range(SIZE - 2, 0, -1)')
 if variant=='count-fading':code=code.replace('old[index(p + offset)] == 1','old[index(p + offset)] > 0')
 if variant=='rebirth-fading':code=code.replace('if state == 2:\n\t\treturn 0','if state == 2 and neighbours < 6:\n\t\treturn 0')
 (d/'volume.gd').write_bytes((code+'\n').encode('utf-8'));shutil.copy2(S/'point_body.gd',d/'point_body.gd')
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
with (O/'stdout.log').open('w',encoding='utf-8') as log:
 result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--resolution','800x600','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/ca_states_lesson.gd'],cwd=R,stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[s for s in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
assert result.returncode==0 and not errors,(result.returncode,errors)
report=json.loads((O/'checks.json').read_text(encoding='utf-8'));assert report['passed'],report['failures']
assert all(hashlib.sha256((O/'printed'/n).read_bytes()).hexdigest()==v for n,v in hashes.items())
print(json.dumps({'passed':True,'checks':len(report['checks']),'exact_printed_code':True}))
