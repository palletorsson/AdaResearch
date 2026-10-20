from pathlib import Path
import json,re,hashlib,subprocess,time,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-carousel-the-support-moves'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Carusell'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/SoftBodies_Carusell/tutorial.md').read_text(encoding='utf8'),re.S)
assert len(blocks)==3
hashes={}
for folder in ['printed','variation','fault-delta','fault-targets','fault-stop']:
 (O/folder).mkdir(exist_ok=True)
 for name,code in blocks:
  assert (code+'\n').encode()==(S/name).read_bytes() and '$' not in code
  if name=='study.gd':
   if folder=='variation':code=code.replace('RATE := 0.4','RATE := 0.8')
   if folder=='fault-delta':code=code.replace('phase + rate * delta','phase + rate')
   if folder=='fault-targets':code=code.replace('PhysicsServer3D.soft_body_move_point(sheet.get_physics_rid(), i, target)','pass # target ignored')
   if folder=='fault-stop':code=code.replace('"STOP": rate = 0.0','"STOP": rebuild()')
  (O/folder/name).write_bytes((code+'\n').encode())
  if folder=='printed':hashes[name]=hashlib.sha256((code+'\n').encode()).hexdigest()
for name in ['hanging_sheet.gd','point_body.gd']:assert (S/name).read_bytes()==(R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Cloth_Physics'/name).read_bytes()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf8') as log:
 p=subprocess.Popen(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/carousel_lesson.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 deadline=time.monotonic()+65
 while p.poll() is None:
  time.sleep(.2);output=(O/'stdout.log').read_text(encoding='utf8',errors='replace')
  if 'SCRIPT ERROR' in output or 'Parse Error' in output or time.monotonic()>deadline:p.kill();break
 p.wait()
output=(O/'stdout.log').read_text(encoding='utf8',errors='replace');print('\n'.join(output.splitlines()[-38:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in output and 'Parse Error' not in output
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'files':len(blocks)}))
