from pathlib import Path
import shutil, json, hashlib
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-growth-what-a-branch-keeps'
O.mkdir(parents=True,exist_ok=True)
files=['commons/maps/LSystems_Growth/'+n for n in ['map_data.json','tutorial.md','final.md','technical.md']]
files+=['commons/artifacts/parametric_lsystem/parametric_lsystem.gd','commons/artifacts/growth_lesson/growth_lesson.gd','commons/maps/sequences/lsystems.json']
files+=['doc/book/course/execution-plan/plan.json']
hashes={}
for name in files:
    p=R/name
    if not p.exists():continue
    target=O/'before'/name
    target.parent.mkdir(parents=True,exist_ok=True)
    if not target.exists():shutil.copyfile(p,target)
    hashes[name]=hashlib.sha256(target.read_bytes()).hexdigest()
(O/'before/hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
print(str(O))
