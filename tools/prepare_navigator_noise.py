from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-navigator-an-imperfect-observation'
M=R/'commons/maps/SwarmIntelligence_Agent_Based_Modeling_ABM'
(O/'before').mkdir(parents=True,exist_ok=True)
for n in ['map_data.json','tutorial.md','final.md']:
 p=O/'before'/n
 if not p.exists():shutil.copy2(M/n,p)
p=O/'before/plan-row.json'
if not p.exists():
 row=next(x for x in json.loads((R/'commons/data/museum/em_plan.json').read_text(encoding='utf-8'))['plans'] if x['map']==M.name)
 p.write_text(json.dumps(row,indent=2),encoding='utf-8')
print(O)
