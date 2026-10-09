from pathlib import Path
import json, re, subprocess, hashlib, shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-a-row-with-neighbours'
S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_Introduction'
text=(R/'commons/maps/CA_Introduction/tutorial.md').read_text(encoding='utf-8')
blocks=re.findall(r'```gdscript\n(.*?)\n```',text,re.S)
assert len(blocks)==2
(O/'printed').mkdir(exist_ok=True)
hashes={}
for name,code in zip(['row.gd','point_body.gd'],blocks):
 assert code+'\n' == (S/name).read_text(encoding='utf-8')
 p=O/'printed'/name; p.write_text(code+'\n',encoding='utf-8'); hashes[name]=hashlib.sha256(p.read_bytes()).hexdigest()
for variant in ['reverse','in-place']:
 d=O/'variants'/variant; d.mkdir(parents=True,exist_ok=True)
 code=blocks[0]
 if variant=='reverse': code=code.replace('for i in range(old.size()):','for i in range(old.size() - 1, -1, -1):')
 else: code=code.replace('var next: Array[bool] = []\n\tnext.resize(old.size())','var next: Array[bool] = old')
 (d/'row.gd').write_text(code+'\n',encoding='utf-8'); shutil.copy2(O/'printed/point_body.gd',d/'point_body.gd')
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
with (O/'stdout.log').open('w',encoding='utf-8') as out:
 result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--resolution','800x600','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/ca_row_lesson.gd'],cwd=R,stdout=out,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[s for s in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
assert result.returncode==0 and not errors,(result.returncode,errors)
data=json.loads((O/'checks.json').read_text(encoding='utf-8')); assert data['passed'],data['failures']
assert all(hashlib.sha256((O/'printed'/n).read_bytes()).hexdigest()==h for n,h in hashes.items())
print(json.dumps({'checks':len(data['checks']),'passed':True,'exact_printed_code':True,'script_errors':errors}))
