from pathlib import Path
import re,json,hashlib,subprocess,shutil,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-reaction-what-keeps-a-pattern';S=R/'doc/book/studies/soft-bodies-through-the-hands/ProceduralGeneration_Reaction_Diffusion_Systems'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps'/S.name/'tutorial.md').read_text(encoding='utf8'),re.S)
assert len(blocks)==3
for folder in ['printed','variation','fault-conversion','fault-supply','fault-inplace','fault-replay']:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  if name=='field.gd':
   if folder=='variation':source=source.replace('FEED := 0.037','FEED := 0.050')
   if folder=='fault-conversion':source=source.replace('dv += conversion - removal','dv += -conversion - removal')
   if folder=='fault-supply':source=source.replace('du += -conversion + supply','du += -conversion')
   if folder=='fault-inplace':source=source.replace('next_u[i] = answer.x','next_u[i] = answer.x\n\t\t\tu[i] = answer.x').replace('next_v[i] = answer.y','next_v[i] = answer.y\n\t\t\tv[i] = answer.y')
  if name=='reaction.gd' and folder=='fault-replay':source=source.replace('left.reset()','left.ticks = 0').replace('right.reset()','right.ticks = 0')
  (O/folder/name).write_bytes((source+'\n').encode())
 shutil.copyfile(S/'study.tscn',O/folder/'study.tscn')
assert (S/'point_body.gd').read_bytes()==(S.parent/'SoftBodies_Affect_Theory_Visualization/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_text(json.dumps({name:hashlib.sha256((S/name).read_bytes()).hexdigest() for name,_ in blocks},indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--path',str(R),'--xr-mode','off','--script','res://tools/probes/reaction_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-40:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
r=json.loads(receipt.read_text());assert r['passed'],r['failures'];print(len(r['checks']),'code checks passed')
