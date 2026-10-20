from pathlib import Path
import json,hashlib,shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-sampling-a-shape-kept'
O.mkdir(exist_ok=True)
files=['commons/maps/SoftBodies_Playground_of_Joy/'+n for n in ['tutorial.md','final.md','technical.md','map_data.json']]+['commons/maps/sequences/softbodies.json','commons/artifacts/timing_machines/soft_workshop.gd','commons/artifacts/frozen_glass_vessel/frozen_glass_vessel.gd','commons/soft_body/soft_body_sim.gd','algorithms/softbodies/rounded_softbody.gd']
if not (O/'before').exists():
 for f in files:
  p=O/'before'/f;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(R/f,p)
 (O/'before/hashes.json').write_text(json.dumps({f:hashlib.sha256((R/f).read_bytes()).hexdigest() for f in files},indent=2))
 for f,key,dest in [('commons/data/museum/em_plan.json','plans','museum-plan.json'),('doc/book/course/execution-plan/plan.json','lessons','lesson-plan.json')]:
  data=json.loads((R/f).read_text(encoding='utf8'))
  row=next(x for x in data[key] if x.get('map',x.get('id'))=='SoftBodies_Playground_of_Joy')
  (O/'before'/dest).write_text(json.dumps(row,ensure_ascii=False,indent=2),encoding='utf8')
(O/'baseline.json').write_text('{"baseline":true}')
print(O)
