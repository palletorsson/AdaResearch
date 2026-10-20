from pathlib import Path
import re,json,hashlib,subprocess,shutil
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-affect-one-cue';S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Affect_Theory_Visualization'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps'/S.name/'tutorial.md').read_text(encoding='utf8'),re.S)
assert len(blocks)==4
for folder in ['printed','variation','fault-shared','fault-cues','fault-live']:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  if name=='study.gd':
   if folder=='variation':source=source.replace('TURN_SPEED := 0.7','TURN_SPEED := 0.35')
   if folder=='fault-shared':source=source.replace('\tfor body in [left, right]:','\tvar shared_finish := StandardMaterial3D.new()\n\tfor body in [left, right]:').replace('var finish := StandardMaterial3D.new()','var finish = shared_finish')
   if folder=='fault-cues':source=source.replace('\tright.rotation = Vector3.ZERO','\tpass')
   if folder=='fault-live':source=source.replace('\tif condition == 1:\n','\tsurface.sim.step(0.0166667)\n\tright.mesh = surface.mesh_for(surface.sim.positions, saved_indices)\n\tif condition == 1:\n')
  (O/folder/name).write_bytes((source+'\n').encode())
 shutil.copyfile(S/'study.tscn',O/folder/'study.tscn')
for name in ['vessel_surface.gd','point_body.gd','solver.gd']:assert (S/name).read_bytes()==(S.parent/'SoftBodies_Playground_of_Joy'/name).read_bytes()
(O/'printed-hashes.json').write_text(json.dumps({name:hashlib.sha256((S/name).read_bytes()).hexdigest() for name,_ in blocks},indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--script','res://tools/probes/affect_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-30:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
r=json.loads(receipt.read_text());assert r['passed'],r['failures'];print(len(r['checks']),'code checks passed')
