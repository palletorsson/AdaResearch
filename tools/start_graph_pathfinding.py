from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-pathfinding-a-route-kept';S=R/'doc/book/studies/graphs-through-the-hands/GT_Pathfinding'
O.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
paths=['commons/maps/GT_Pathfinding/'+n for n in ['tutorial.md','final.md','technical.md','map_data.json']]
paths+=['commons/maps/sequences/graphtheory.json','commons/artifacts/impatient_river/impatient_river.gd','commons/artifacts/impatient_river/impatient_river.tscn','commons/artifacts/registry/graphtheory.json','commons/data/museum/em_plan.json','ada_run/necklace_hand.json','doc/book/course/execution-plan/plan.json']
paths+=['doc/book/studies/graphs-through-the-hands/GT_Layout/'+n for n in ['traversal.gd','point_body.gd','study.gd','layout.gd']]
for rel in paths:
 p=R/rel;q=O/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
for name in ['point_body.gd','traversal.gd','study.tscn']:shutil.copy2(S.parent/'GT_Layout'/name,S/name)
(O/'baseline-spec.json').write_text('{"baseline":true}\n',encoding='utf8')
data=json.loads((R/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf8'))
print(json.dumps(next(x for x in data['lessons'] if x['id']=='GT_Pathfinding'),ensure_ascii=True,indent=2))
