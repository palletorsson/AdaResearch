"""Photograph all saved Swarm placements; capture unplaced registry scenes separately."""
from pathlib import Path
import subprocess,sys,json
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-10-swarm-artifact-gallery'
O.mkdir(parents=True,exist_ok=True)
seq=json.loads((R/'commons/maps/sequences/swarmintelligence.json').read_text(encoding='utf8'))['sequences']['swarmintelligence']['maps']
for room in seq:
 out=R/'ada_run/encounter_pilot'/room/'all-artifacts'
 if not (out/'report.json').exists():
  args=[sys.executable,'tools/run_encounter_probe.py',room,'--sequence','swarmintelligence','--render','--no-bridges','--output-tag','all-artifacts','--probe','tools/probes/swarm_artifact_gallery.gd']
  p=subprocess.run(args,cwd=R,capture_output=True,timeout=170)
  (O/(room+'.log')).write_bytes(p.stdout+p.stderr)
  assert p.returncode==0,(room,p.stdout.decode('utf8',errors='replace')[-1500:])
 d=json.loads((out/'report.json').read_text(encoding='utf8'))
 assert d['completed'] and d['passed']
 print(room+': '+str(sum(a['loaded'] for a in d['artifacts']))+'/'+str(len(d['artifacts']))+' live placements',flush=True)

allreg={}
for f in (R/'commons/artifacts/registry').glob('*.json'):
 try:allreg.update(json.loads(f.read_text(encoding='utf8')).get('artifacts',{}))
 except (ValueError,AttributeError):pass
extras=set()
for f in ['swarmintelligence','accord_swarm']:
 extras.update(json.loads((R/'commons/artifacts/registry'/(f+'.json')).read_text(encoding='utf8'))['artifacts'])
live=set();missing=set()
for room in seq:
 d=json.loads((R/'ada_run/encounter_pilot'/room/'all-artifacts/report.json').read_text(encoding='utf8'))
 for a in d['artifacts']:
  (live if a['loaded'] else missing).add(a['token'])
seen={allreg[t].get('scene') for t in live if t in allreg}
library=[]
for token in sorted((extras-live)|missing):
 info=allreg.get(token,{})
 scene=info.get('scene','')
 if scene in seen:continue
 seen.add(scene)
 image=O/'library'/(token+'.png');image.parent.mkdir(exist_ok=True)
 args=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','gl_compatibility','--script','res://commons/testing/capture_artifact_shot.gd','--',f'--artifact={token}',f'--out={image.as_posix()}','--distance=0.5','--pitch=0.55','--yaw=0.5','--wait=2','--no-bridges']
 if not image.exists():
  try:p=subprocess.run(args,cwd=R,capture_output=True,timeout=40,creationflags=subprocess.CREATE_NO_WINDOW)
  except subprocess.TimeoutExpired as exc:
   (O/'library'/(token+'.log')).write_bytes((exc.stdout or b'')+(exc.stderr or b''));p=None
  if p is not None:(O/'library'/(token+'.log')).write_bytes(p.stdout+p.stderr)
 library.append({'token':token,'scene':scene,'image':str(image.relative_to(O)).replace('\\','/') if image.exists() else None,'missing_in_hall':token in missing,'kind':'isolated scene preview'})
 print(token+': '+('scene preview captured' if image.exists() else 'no preview'),flush=True)
(O/'library.json').write_bytes((json.dumps(library,indent=2)+'\n').encode())
