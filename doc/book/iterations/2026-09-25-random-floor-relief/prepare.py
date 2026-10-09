from pathlib import Path
import json,shutil,hashlib
r=Path.cwd();o=Path(__file__).parent
files=['commons/context/walkgrids/RandomSpace.gd','commons/context/walkgrids/random_space.tscn','commons/maps/Random_Space/map_data.json','commons/maps/Random_Space/final.md','commons/maps/Random_Space/intent.md','commons/data/museum_core_encounters.json','doc/book/captures/randomness/randomness-book.md','doc/book/captures/randomness/randomness-book.manifest.json']
assert not (o/'baseline.json').exists()
d={}
for f in files:
 p=r/f;q=o/'before'/f;q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q);d[f]=hashlib.sha256(p.read_bytes()).hexdigest()
(o/'baseline.json').write_text(json.dumps(d,indent=2)+'\n')
print('Baseline saved.')
