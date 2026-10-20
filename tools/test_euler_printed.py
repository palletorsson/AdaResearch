"""Reconstruct the five printed files and reject two controlled semantic faults."""
from pathlib import Path
import re,json,subprocess,hashlib,shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-the-same-throw-different-steps'
A=R/'algorithms/forces/euler_drift'
sources=[A/'step_model.gd',R/'doc/book/studies/forces-point-lineage/point_body.gd',A/'display_point.gd',A/'step_study.gd',A/'step_study.tscn']
blocks=re.findall(r'```(?:gdscript|ini)\n(.*?)\n```',(A/'tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==5
for p,s in zip(sources,blocks):assert p.read_text(encoding='utf-8').rstrip()==s.rstrip(),p
assert (A/'tutorial.md').read_text(encoding='utf-8') in (R/'commons/maps/VFM_05_Launch/tutorial.md').read_text(encoding='utf-8')
receipts=[]
for variant in ['printed','velocity-first','history-alias']:
 folder=R/'ada_run/euler_reconstruction'/variant;folder.mkdir(parents=True,exist_ok=True)
 prefix='res://'+folder.relative_to(R).as_posix()+'/'
 for p,s in zip(sources,blocks):
  for source in sources:s=s.replace('res://'+source.relative_to(R).as_posix(),prefix+source.name)
  if p.name=='step_model.gd':
   if variant=='velocity-first':
    old='position += velocity*h()\n\tvelocity += gravity*h()';assert old in s
    s=s.replace(old,'velocity += gravity*h()\n\tposition += velocity*h()')
   if variant=='history-alias':
    assert '_history.duplicate(true)' in s;s=s.replace('_history.duplicate(true)','_history')
  (folder/p.name).write_text(s+'\n',encoding='utf-8')
 dest=O/(variant+'-checks.json');log=O/(variant+'-engine.log');out=O/(variant+'-stdout.log')
 if dest.exists():dest.unlink()
 with out.open('w',encoding='utf-8') as stream:
  run=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(log),'--script','res://tools/probes/euler_step_test.gd','--','res://'+dest.relative_to(R).as_posix(),prefix],cwd=R,stdout=stream,stderr=subprocess.STDOUT,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW)
 d=json.loads(dest.read_text(encoding='utf-8'))
 assert not any(x in log.read_text(encoding='utf-8') for x in ['SCRIPT ERROR','Parse Error'])
 if variant=='printed':assert run.returncode==0 and d['passed']
 else:
  expected='signed explicit Euler difference 10' if variant=='velocity-first' else 'caller cannot alter saved history 10'
  assert run.returncode==1 and expected in d['failures'],d['failures']
 saved=O/'reconstruction'/variant;saved.mkdir(parents=True,exist_ok=True)
 for p in folder.iterdir():
  if p.suffix in ['.gd','.tscn']:shutil.copy2(p,saved/p.name)
 receipts.append({'variant':variant,'exit':run.returncode,'checks':len(d['checks']),'failures':d['failures']})
(O/'printed-validation.json').write_text(json.dumps({'files':5,'host':'Existing Ada 4.6 museum / XRTools / ControlConsole','only_path_relocation':True,'runs':receipts,'source_hashes':{p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}},indent=2),encoding='utf-8')
print(json.dumps(receipts))
