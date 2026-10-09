from pathlib import Path
import json,hashlib,shutil
r=Path.cwd();o=Path(__file__).parent
assert not (o/'baseline.json').exists()
maps=json.loads((r/'commons/maps/sequences/randomness.json').read_text())['sequences']['randomness']['maps'][8:]
paths=[]
for m in maps:paths+=list((r/'commons/maps'/m).glob('*.md'))+[r/'commons/maps'/m/'map_data.json']
paths += [r/p for p in ['algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.gd','algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.tscn','algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd','algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.gd','algorithms/randomness/pheromone_terrain/pheromone_terrain.gd','commons/context/walkgrids/RandomSpace.gd','commons/artifacts/worley_noise/worley_noise.gd','commons/artifacts/randomness_space/waiting_profile.gd','commons/data/museum_core_encounters.json','commons/data/artifact_roles.json','commons/maps/sequences/randomness.json','commons/data/book/randomness.json','doc/tasks/book_randomness.json','doc/book/figures/README.md','doc/book/iterations/WORKING.md','doc/book/captures/randomness/randomness-book.md','doc/book/captures/randomness/randomness-book.manifest.json','ada_run/em_plan.json','commons/data/museum/em_plan.json']]
hashes={}
for p in paths:
 rel=p.relative_to(r);d=o/'before'/rel;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,d);hashes[rel.as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
(o/'baseline.json').write_text(json.dumps({'maps':maps,'files':hashes},indent=2)+'\n')
old=r/'doc/book/iterations/2026-09-25-randomness-turns-and-trails/collect.py'
(o/'collect.py').write_text(old.read_text().replace('2026-09-25-randomness-turns-and-trails',o.name))
print('Frozen',len(paths),'files for',maps)
