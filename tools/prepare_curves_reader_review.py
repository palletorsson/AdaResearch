from pathlib import Path
import json,hashlib,shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-curves-one-sentence-three-readers'
files=['commons/maps/LSystems_Grammars_And_Curves/'+n for n in ['map_data.json','tutorial.md','final.md','technical.md']]
files+=['commons/artifacts/the_believing_turtle/the_believing_turtle.gd','commons/artifacts/interpreter_lesson/interpreter_lesson.gd','commons/maps/sequences/lsystems.json','doc/book/course/execution-plan/plan.json']
hashes={}
for name in files:
    target=O/'before'/name;target.parent.mkdir(parents=True,exist_ok=True)
    if not target.exists():shutil.copyfile(R/name,target)
    hashes[name]=hashlib.sha256(target.read_bytes()).hexdigest()
(O/'before/hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
print(O)
