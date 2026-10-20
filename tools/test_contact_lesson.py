from pathlib import Path
import json,re,hashlib,subprocess,time,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-contact-the-same-start'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Obsticals_Part2'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/SoftBodies_Obsticals_Part2/tutorial.md').read_text(encoding='utf8'),re.S)
assert len(blocks)==3
hashes={}
for folder in ['printed','variation','fault-reset','fault-confound','fault-held']:
 (O/folder).mkdir(exist_ok=True)
 for name,code in blocks:
  assert (code+'\n').encode()==(S/name).read_bytes() and '$' not in code
  if name=='study.gd':
   if folder=='variation':code=code.replace('"B", "damping": 0.6','"B", "damping": 0.1')
   if folder=='fault-reset':code=code.replace('func replay() -> void:', 'func replay() -> void:\n\tif not panels.is_empty():\n\t\telapsed = 0.0\n\t\tresults.clear()\n\t\trunning = true\n\t\tarmed = false\n\t\treturn')
   if folder=='fault-confound':code=code.replace('panel.damping_coefficient = CASES[i].damping','panel.damping_coefficient = CASES[i].damping\n\t\tif i == 1: panel.total_mass = 2.0')
   if folder=='fault-held':code=code.replace('if points[i].held():','if false:')
  (O/folder/name).write_bytes((code+'\n').encode())
  if folder=='printed':hashes[name]=hashlib.sha256((code+'\n').encode()).hexdigest()
for name in ['pressure_panel.gd','point_body.gd']:
 assert (S/name).read_bytes()==(S.parent/'SoftBodies_Obsticals'/name).read_bytes()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf8') as log:
 p=subprocess.Popen(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/contact_lesson.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 deadline=time.monotonic()+90
 while p.poll() is None:
  time.sleep(.2);output=(O/'stdout.log').read_text(encoding='utf8',errors='replace')
  if 'SCRIPT ERROR' in output or 'Parse Error' in output or time.monotonic()>deadline:p.kill();break
 p.wait()
output=(O/'stdout.log').read_text(encoding='utf8',errors='replace');print('\n'.join(output.splitlines()[-55:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in output and 'Parse Error' not in output
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'files':len(blocks)}))
