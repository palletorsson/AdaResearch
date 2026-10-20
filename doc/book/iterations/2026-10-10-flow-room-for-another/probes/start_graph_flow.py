from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[1];ID='GT_Flow';O=R/'doc/book/iterations/2026-10-10-flow-room-for-another';S=R/'doc/book/studies/graphs-through-the-hands'/ID
O.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
paths=['commons/maps/'+ID+'/'+n for n in ['tutorial.md','final.md','technical.md','map_data.json']]
paths+=['commons/maps/sequences/graphtheory.json','algorithms/graphtheory/push_relabel/push_relabel.gd','algorithms/graphtheory/push_relabel/push_relabel.tscn','commons/artifacts/registry/algorithms_misc.json','commons/data/museum/em_plan.json','ada_run/necklace_hand.json','doc/book/course/execution-plan/plan.json']
for rel in paths:
 p=R/rel;q=O/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
for n in ['point_body.gd','study.tscn']:shutil.copy2(S.parent/'GT_Spanning_Trees'/n,S/n)
(O/'baseline-spec.json').write_text('{"baseline":true}\n',encoding='utf8')
print('Flow baseline preserved; PointBody carried unchanged.')
