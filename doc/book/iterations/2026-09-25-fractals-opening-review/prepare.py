from pathlib import Path
import hashlib,json,shutil
r=Path.cwd();o=Path(__file__).resolve().parent
maps=['Fractal_Recursion','Fractal_RecursiveTrees']
files=[p for m in maps for p in (r/'commons/maps'/m).iterdir() if p.suffix in ['.md','.json']]
paths=['algorithms/fractals/example_8_2_recursion_vr.gd','algorithms/fractals/example_8_3_recursion_circles_vr.gd','algorithms/fractals/example_8_9_lsystem_tree_vr.gd','algorithms/fractals/recursivetree/recursive_tree.gd','algorithms/fractals/recursive_tree/recursive_tree.gd','algorithms/fractals/cubesubdivision/cube_subdivision.gd','algorithms/fractals/cubesubdivision/recursive_chair.gd','commons/artifacts/recursion_lesson/recursion_lesson.gd','commons/artifacts/recursive_tree_lesson/recursive_tree_lesson.gd','commons/data/museum_core_encounters.json','commons/maps/sequences/fractals.json','commons/data/book/fractals.json','doc/tasks/book_fractals.json','ada_run/em_plan.json']
files += [r/p for p in paths if (r/p).exists()]
assert not (o/'baseline.json').exists()
hashes={}
for p in files:
 rel=p.relative_to(r).as_posix();dest=o/'before'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest);hashes[rel]=hashlib.sha256(p.read_bytes()).hexdigest()
(o/'baseline.json').write_bytes((json.dumps(hashes,indent=2)+'\n').encode())
shutil.copy2(r/'doc/book/iterations/2026-09-25-ca-ending-review/collect.py',o/'collect.py')
print('Frozen',len(hashes),'files')
