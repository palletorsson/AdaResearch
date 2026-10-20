"""Extract five printed files; test their reconstruction, then two specific faults."""
from pathlib import Path
import re,json,subprocess,hashlib
R=Path(__file__).resolve().parents[1]; O=R/'doc/book/iterations/2026-10-09-navigator-an-imperfect-observation'
A=R/'commons/artifacts/navigator_noise'; engine='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
sources=[A/'navigation_pair.gd',R/'doc/book/studies/forces-point-lineage/point_body.gd',A/'start_point.gd',A/'NavigatorNoise.gd',A/'NavigatorNoise.tscn']
blocks=re.findall(r'```(?:gdscript|ini)\n(.*?)\n```',(A/'tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==5
for p,s in zip(sources,blocks):assert s.rstrip()==p.read_text(encoding='utf-8').rstrip(),p
receipts=[]
for variant in ['printed','missing-as-zero','endpoints-only']:
 folder=R/'ada_run/navigator_reconstruction'/variant; folder.mkdir(parents=True,exist_ok=True)
 prefix='res://'+folder.relative_to(R).as_posix()+'/'
 for p,s in zip(sources,blocks):
  for source in sources:s=s.replace('res://'+source.relative_to(R).as_posix(),prefix+source.name)
  if p.name=='navigation_pair.gd':
   if variant=='missing-as-zero':s=s.replace('return null if uniforms[block]<dropout else truth','return 0.0 if uniforms[block]<dropout else truth')
   if variant=='endpoints-only':s=s.replace('var radius := OBSTACLE_RADIUS+RADIUS','if distance_at(b)>0: return -1.0\n\tvar radius := OBSTACLE_RADIUS+RADIUS')
  (folder/p.name).write_text(s+'\n',encoding='utf-8')
 dest=O/(variant+'-checks.json'); log=O/(variant+'-engine.log'); out=O/(variant+'-stdout.log')
 if dest.exists():dest.unlink()
 with out.open('w',encoding='utf-8') as stream:
  run=subprocess.run([engine,'--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(log),'--script','res://tools/probes/navigator_noise_test.gd','--','res://'+dest.relative_to(R).as_posix(),prefix],cwd=R,stdout=stream,stderr=subprocess.STDOUT,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW)
 d=json.loads(dest.read_text(encoding='utf-8'))
 assert not any(x in log.read_text(encoding='utf-8') for x in ['SCRIPT ERROR','Parse Error'])
 if variant=='printed':assert run.returncode==0 and d['passed']
 else:
  expected='missing is represented as null' if variant=='missing-as-zero' else 'swept collision detects crossing even with both endpoints outside'
  assert run.returncode==1 and expected in d['failures'],d['failures']
 receipts.append({'variant':variant,'exit':run.returncode,'checks':len(d['checks']),'failures':d['failures']})
 # Preserve the actual reconstructed variant, including intentionally faulty versions.
 saved=O/'reconstruction'/variant; saved.mkdir(parents=True,exist_ok=True)
 for p in folder.iterdir():
  if p.suffix in ['.gd','.tscn']:(saved/p.name).write_bytes(p.read_bytes())
manifest={p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
(O/'printed-validation.json').write_text(json.dumps({'files':5,'host':'Existing Ada4.6/XRTools/ControlConsole','only_path_relocation':True,'runs':receipts,'source_hashes':manifest},indent=2),encoding='utf-8')
print(json.dumps(receipts))
