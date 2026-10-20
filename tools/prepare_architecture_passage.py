from pathlib import Path
import hashlib,json,shutil
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-architecture-a-place-to-pass'
files=['commons/maps/LSystems_Architecture/'+n for n in ['tutorial.md','final.md','technical.md','map_data.json']]+['commons/artifacts/architecture_lesson/architecture_lesson.gd','commons/artifacts/lsystem_dungeon/lsystem_dungeon.gd','commons/maps/sequences/lsystems.json','doc/book/course/execution-plan/plan.json']
hashes={}
for name in files:
 p=O/'before'/name;p.parent.mkdir(parents=True,exist_ok=True)
 if not p.exists():shutil.copyfile(R/name,p)
 hashes[name]=hashlib.sha256(p.read_bytes()).hexdigest()
(O/'before/hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
print(O)
