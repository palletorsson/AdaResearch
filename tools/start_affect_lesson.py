from pathlib import Path
import json,hashlib,shutil
R=Path(__file__).resolve().parents[1]
M='SoftBodies_Affect_Theory_Visualization'
O=R/'doc/book/iterations/2026-10-09-affect-one-cue'
O.mkdir(exist_ok=True)
files=['commons/maps/'+M+'/'+n for n in ['tutorial.md','final.md','technical.md','map_data.json']]+['commons/maps/sequences/softbodies.json','commons/artifacts/timing_machines/soft_workshop.gd','algorithms/computationalbiology/radiolaria2/radiolaria.gd','commons/soft_body/soft_body_sim.gd']
if not (O/'before').exists():
 for f in files:
  p=O/'before'/f;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(R/f,p)
 (O/'before/hashes.json').write_text(json.dumps({f:hashlib.sha256((R/f).read_bytes()).hexdigest() for f in files},indent=2))
 for f,key,dest in [('commons/data/museum/em_plan.json','plans','museum-plan.json'),('doc/book/course/execution-plan/plan.json','lessons','lesson-plan.json')]:
  data=json.loads((R/f).read_text(encoding='utf8'));row=next(x for x in data[key] if x.get('map',x.get('id'))==M)
  (O/'before'/dest).write_text(json.dumps(row,ensure_ascii=False,indent=2),encoding='utf8')
(O/'baseline.json').write_text('{"baseline":true}')
print(O)
