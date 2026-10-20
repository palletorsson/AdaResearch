from pathlib import Path
import json,re,hashlib,subprocess,time,sys,shutil
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-sampling-a-shape-kept'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Playground_of_Joy'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/SoftBodies_Playground_of_Joy/tutorial.md').read_text(encoding='utf8'),re.S)
assert len(blocks)==4
hashes={}
for folder in ['printed','variation','fault-follow','fault-clock','fault-faces']:
 (O/folder).mkdir(exist_ok=True)
 for name,code in blocks:
  assert code+'\n'==(S/name).read_text(encoding='utf8') and '$' not in code
  if name=='study.gd':
   if folder=='variation':code=code.replace('SAMPLE_STEP := 40','SAMPLE_STEP := 200')
   if folder=='fault-follow':code=code.replace('if step_count == SAMPLE_STEP:', 'if step_count >= SAMPLE_STEP:')
   if folder=='fault-clock':code=code.replace('\tsurface = VesselSurface.new()\n','\tpass\n')
   if folder=='fault-faces':code=code.replace('saved_indices = surface.indices.duplicate()','saved_indices = surface.indices.slice(0, 6)')
  (O/folder/name).write_bytes((code+'\n').encode())
  if folder=='printed':hashes[name]=hashlib.sha256((code+'\n').encode()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(S.parent/'SoftBodies_Obsticals_Part2/point_body.gd').read_bytes()
assert (S/'solver.gd').read_bytes()==(R/'commons/soft_body/soft_body_sim.gd').read_bytes()
shutil.copyfile(S/'study.tscn',O/'printed/study.tscn')
shutil.copyfile(S/'study.tscn',O/'variation/study.tscn')
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf8') as log:
 p=subprocess.Popen(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/sampling_lesson.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 deadline=time.monotonic()+65
 while p.poll() is None:
  time.sleep(.2);output=(O/'stdout.log').read_text(encoding='utf8',errors='replace')
  if 'SCRIPT ERROR' in output or 'Parse Error' in output or time.monotonic()>deadline:p.kill();break
 p.wait()
output=(O/'stdout.log').read_text(encoding='utf8',errors='replace');print('\n'.join(output.splitlines()[-55:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in output and 'Parse Error' not in output
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'files':len(blocks)}))
