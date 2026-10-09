from pathlib import Path
import hashlib,json,shutil
r=Path.cwd();o=Path(__file__).resolve().parent
maps=['SoftBodies_Soft_Body_Deformation','SoftBodies_Cloth_Physics']
files=[p for m in maps for p in (r/'commons/maps'/m).iterdir() if p.suffix in ['.md','.json']]
paths=['commons/artifacts/jelly_cube/jelly_cube.gd','commons/artifacts/timing_machines/soft_workshop.gd','commons/artifacts/timing_machines/soft_workshop.json','algorithms/softbodies/cloth_straps/cloth_straps.gd','algorithms/physicssimulation/softbodies/softbodystop/fourstopsoftbody.gd','commons/scenes/base.tscn','addons/godot-xr-tools/hands/collision_hand.gd','commons/data/museum_core_encounters.json','commons/maps/sequences/softbodies.json','commons/data/book/softbodies.json','doc/tasks/book_softbodies.json','ada_run/em_plan.json']
files += [r/p for p in paths if (r/p).exists()]
assert not (o/'baseline.json').exists()
hashes={}
for p in files:
 rel=p.relative_to(r).as_posix();dest=o/'before'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest);hashes[rel]=hashlib.sha256(p.read_bytes()).hexdigest()
(o/'baseline.json').write_bytes((json.dumps(hashes,indent=2)+'\n').encode())
for name in ['collect.py','run_review.py']:
 s=(r/'doc/book/iterations/2026-09-25-fractals-opening-review'/name).read_text(encoding='utf-8').replace('_opening_review','_soft_opening_review')
 (o/name).write_bytes(s.encode())
print('Frozen',len(hashes),'files')
