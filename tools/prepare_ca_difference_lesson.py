from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-08-ca-what-a-difference-keeps'
B=O/'before';B.mkdir(parents=True,exist_ok=True)
for name in ['tutorial.md','final.md','technical.md','encounter-notes.md','map_data.json']:
 target=B/name
 if not target.exists():shutil.copy2(R/'commons/maps/CA_EdgeOfChaos'/name,target)
for name in ['difference_model.gd','difference_study.gd','walking_slice.gd','self_organization_ca.gd']:
 if not (B/name).exists():shutil.copy2(R/'algorithms/cellularautomata/ca_showcase'/name,B/name)
plan=json.loads((R/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf-8'))
if not (B/'lesson-plan.json').exists():(B/'lesson-plan.json').write_text(json.dumps(next(r for r in plan['lessons'] if r['id']=='CA_EdgeOfChaos'),ensure_ascii=False,indent=2),encoding='utf-8')
d=json.loads((B/'map_data.json').read_text())
for key in ['interactables','utilities']:
 print(key,[(x,z,v) for z,row in enumerate(d['layers'][key]) for x,v in enumerate(row) if v.strip()])
for z,row in enumerate(d['layers']['structure']):print(z,' '.join(row))
print('target plan',json.loads((B/'lesson-plan.json').read_text()))
