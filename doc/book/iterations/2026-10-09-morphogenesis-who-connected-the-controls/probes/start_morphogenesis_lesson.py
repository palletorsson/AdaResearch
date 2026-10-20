from pathlib import Path
import json,hashlib,shutil
R=Path(__file__).resolve().parents[1];M='Topology_Entropy_Morphogenesis';O=R/'doc/book/iterations/2026-10-09-morphogenesis-who-connected-the-controls'
O.mkdir(exist_ok=True)
files=['commons/maps/'+M+'/'+n for n in ['tutorial.md','final.md','technical.md','map_data.json']]+['commons/maps/sequences/softbodies.json','commons/artifacts/timing_machines/soft_workshop.gd','commons/artifacts/timing_machines/soft_workshop.json','algorithms/spacetopology/entropy_morphogenesis/entropy_morphogenesis_vr.gd','algorithms/spacetopology/entropy_morphogenesis/entropy_morphogenesis_vr.tscn','algorithms/spacetopology/gyroid_cheese/GyroidFieldGenerator.gd']
if not (O/'before').exists():
 for f in files:
  p=O/'before'/f;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(R/f,p)
 (O/'before/hashes.json').write_text(json.dumps({f:hashlib.sha256((R/f).read_bytes()).hexdigest() for f in files},indent=2))
 for f,key,name in [('commons/data/museum/em_plan.json','plans','museum-plan.json'),('doc/book/course/execution-plan/plan.json','lessons','lesson-plan.json')]:
  d=json.loads((R/f).read_text(encoding='utf8'));row=next(x for x in d[key] if x.get('map',x.get('id'))==M)
  (O/'before'/name).write_bytes(json.dumps(row,ensure_ascii=False,indent=2).encode())
(O/'baseline.json').write_text('{"baseline":true}')
print(O)
