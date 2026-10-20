from pathlib import Path
import json,re,hashlib,subprocess,time,shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-soft-a-point-that-stays'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Soft_Body_Deformation'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/SoftBodies_Soft_Body_Deformation/tutorial.md').read_text(encoding='utf8'),re.S)
assert len(blocks)==3
hashes={}
for folder in ['printed','variation']:
 (O/folder).mkdir(exist_ok=True)
 for name,code in blocks:
  assert (code+'\n').encode()==(S/name).read_bytes() and '$' not in code
  if folder=='variation' and name=='yielding_cube.gd':code=code.replace('DIVISIONS := 4','DIVISIONS := 2')
  (O/folder/name).write_bytes((code+'\n').encode())
  if folder=='printed':hashes[name]=hashlib.sha256((code+'\n').encode()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/procedural-generation-through-the-hands/PG_Mirrored_Patterns/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
probe=(R/'tools/probes/soft_yield_lesson.gd').read_text().replace('res://doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Soft_Body_Deformation/','res://doc/book/iterations/2026-10-09-soft-a-point-that-stays/printed/')
(O/'run.gd').write_bytes(probe.encode())
receipt=O/'checks.json'
if receipt.exists():shutil.copyfile(receipt,O/'previous-checks.json');receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf8') as log:
 p=subprocess.Popen(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://'+(O/'run.gd').relative_to(R).as_posix(),'--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 deadline=time.monotonic()+65
 while p.poll() is None:
  time.sleep(.2)
  output=(O/'stdout.log').read_text(encoding='utf8',errors='replace')
  if 'SCRIPT ERROR' in output or 'Parse Error' in output or time.monotonic()>deadline:p.kill();break
 p.wait()
output=(O/'stdout.log').read_text(encoding='utf8',errors='replace')
print('\n'.join(output.splitlines()[-28:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in output and 'Parse Error' not in output
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'files':len(blocks)}))
