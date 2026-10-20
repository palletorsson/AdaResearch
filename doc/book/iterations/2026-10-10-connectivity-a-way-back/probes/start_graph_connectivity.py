from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];ID='GT_Connectivity';O=R/'doc/book/iterations/2026-10-10-connectivity-a-way-back';S=R/'doc/book/studies/graphs-through-the-hands'/ID
O.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
paths=['commons/maps/'+ID+'/'+n for n in ['tutorial.md','final.md','technical.md','map_data.json']]
paths+=['commons/maps/sequences/graphtheory.json','algorithms/graphtheory/tarjan_algorithm/tarjan_algorithm.gd','algorithms/graphtheory/tarjan_algorithm/tarjan_algorithm.tscn','commons/artifacts/registry/algorithms_misc.json','commons/data/museum/em_plan.json','ada_run/necklace_hand.json','doc/book/course/execution-plan/plan.json']
for rel in paths:
 p=R/rel;q=O/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
for n in ['point_body.gd','traversal.gd','route.gd','ledger.gd','study.tscn']:shutil.copy2(S.parent/'GT_Network_Analysis'/n,S/n)
(O/'baseline-spec.json').write_text('{"baseline":true}\n',encoding='utf8')
print('Network Analysis baseline and carried files preserved.')

shutil.copy2(S.parent/'GT_Network_Analysis'/'study.gd',S/'network_study.gd')
