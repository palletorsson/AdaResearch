"""Extract and execute the exact two printed files, including transfer and fault cases."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-a-pattern-visits'
S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_BeyondBinary'
blocks=re.findall(r'```gdscript\n(.*?)\n```',(R/'commons/maps/CA_BeyondBinary/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==2
(O/'printed').mkdir(exist_ok=True);hashes={}
for name,code in zip(['life.gd','point_body.gd'],blocks):
 assert code+'\n'==(S/name).read_text(encoding='utf-8')
 (O/'printed'/name).write_bytes((code+'\n').encode('utf-8'))
 hashes[name]=hashlib.sha256((O/'printed'/name).read_bytes()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(S.parent/'CA_GameOfLife/point_body.gd').read_bytes()
for variant in ['self-count','in-place','other-address']:
 d=O/'variants'/variant;d.mkdir(parents=True,exist_ok=True)
 code=blocks[0]
 if variant=='self-count':code=code.replace('if dx != 0 or dy != 0:', 'if true:')
 elif variant=='in-place':code=code.replace('var next: Array[bool] = []', 'var next: Array[bool] = old')
 else:code=code.replace('const SITE := Vector2i(10, 10)','const SITE := Vector2i(9, 10)')
 (d/'life.gd').write_bytes((code+'\n').encode('utf-8'));shutil.copy2(S/'point_body.gd',d/'point_body.gd')
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
with (O/'stdout.log').open('w',encoding='utf-8') as out:
 result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--resolution','800x600','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/ca_life_lesson.gd'],cwd=R,stdout=out,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[s for s in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
assert result.returncode==0 and not errors,(result.returncode,errors)
report=json.loads((O/'checks.json').read_text(encoding='utf-8'));assert report['passed'],report['failures']
assert all(hashlib.sha256((O/'printed'/n).read_bytes()).hexdigest()==v for n,v in hashes.items())
print(json.dumps({'passed':True,'checks':len(report['checks']),'exact_printed_code':True}))
