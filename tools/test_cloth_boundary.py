from pathlib import Path
import sys
sys.stdout.reconfigure(encoding='utf8')
import json,re,hashlib,subprocess,time
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-cloth-which-points-stay'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Cloth_Physics'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/SoftBodies_Cloth_Physics/tutorial.md').read_text(encoding='utf8'),re.S)
assert len(blocks)==3
hashes={}
for folder in ['printed','variation','fault-unpin','fault-or','fault-world']:
 (O/folder).mkdir(exist_ok=True)
 for name,code in blocks:
  assert (code+'\n').encode()==(S/name).read_bytes() and '$' not in code
  if name=='hanging_sheet.gd':
   if folder=='variation':code=code.replace('COLUMNS := 6','COLUMNS := 10')
   if folder=='fault-unpin':code=code.replace('set_point_pinned(i, keep)','if keep: set_point_pinned(i, true)')
   if folder=='fault-or':code=code.replace('top and (mode == 0 or (mode == 1 and corner))','(top or corner) and mode != 2')
   if folder=='fault-world':code=code.replace('var p := rest_points[i]','var p := get_point_transform(i) if is_inside_tree() else rest_points[i]')
  (O/folder/name).write_bytes((code+'\n').encode())
  if folder=='printed':hashes[name]=hashlib.sha256((code+'\n').encode()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Soft_Body_Deformation/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
probe=(R/'tools/probes/cloth_boundary_lesson.gd').read_text().replace('res://doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Cloth_Physics/','res://doc/book/iterations/2026-10-09-cloth-which-points-stay/printed/')
(O/'run.gd').write_bytes(probe.encode())
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf8') as log:
 p=subprocess.Popen(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://'+(O/'run.gd').relative_to(R).as_posix(),'--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 deadline=time.monotonic()+65
 while p.poll() is None:
  time.sleep(.2)
  output=(O/'stdout.log').read_text(encoding='utf8',errors='replace')
  if 'SCRIPT ERROR' in output or 'Parse Error' in output or time.monotonic()>deadline:p.kill();break
 p.wait()
output=(O/'stdout.log').read_text(encoding='utf8',errors='replace')
print('\n'.join(output.splitlines()[-38:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in output and 'Parse Error' not in output
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'files':len(blocks)}))
