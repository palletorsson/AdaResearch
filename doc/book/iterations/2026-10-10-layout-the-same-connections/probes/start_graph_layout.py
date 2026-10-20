from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-10-layout-the-same-connections'
S=R/'doc/book/studies/graphs-through-the-hands/GT_Layout'
O.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
paths=['commons/maps/GT_Layout/'+n for n in ['tutorial.md','final.md','technical.md','map_data.json']]
paths+=['commons/maps/sequences/graphtheory.json','algorithms/graphtheory/force_directed_layout/ForceDirectedLayout.gd','algorithms/graphtheory/force_directed_layout/force_directed_layout.tscn','commons/data/museum/em_plan.json','ada_run/necklace_hand.json','commons/artifacts/registry/graphtheory.json','doc/book/course/execution-plan/plan.json']
paths+=['doc/book/studies/graphs-through-the-hands/GT_Foundations/'+n for n in ['traversal.gd','point_body.gd','study.gd']]
for rel in paths:
 p=R/rel;q=O/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
for name in ['point_body.gd','traversal.gd','study.tscn']:shutil.copy2(S.parent/'GT_Foundations'/name,S/name)
(O/'baseline-spec.json').write_text('{"baseline":true}\n',encoding='utf8')
for rel,key in [('commons/data/museum/em_plan.json','plans'),('doc/book/course/execution-plan/plan.json','lessons')]:
 d=json.loads((R/rel).read_text(encoding='utf8'))
 print(rel,json.dumps(next(x for x in d[key] if x.get('id',x.get('map'))=='GT_Layout'),ensure_ascii=True)[:6500])
