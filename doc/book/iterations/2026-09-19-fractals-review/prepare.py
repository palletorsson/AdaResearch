from pathlib import Path
import hashlib
import json
ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
maps = json.loads((ROOT/'commons/maps/sequences/fractals.json').read_text())['sequences']['fractals']['maps']
paths = [f'commons/maps/{m}/final.md' for m in maps] + [
 'commons/maps/Fractal_KochSierpinski/map_data.json',
 'algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd',
 'commons/artifacts/registry/cellular_automata.json',
 'commons/data/artifact_roles.json', 'commons/data/museum_core_encounters.json',
 'commons/maps/sequences/fractals.json','commons/data/map_authored.json',
 'ada_run/em_plan.json','commons/data/museum/em_plan.json',
 'commons/data/long_museum.json','commons/data/museum_order_effective.json']
for rel in paths:
 p=HERE/'before'/rel
 p.parent.mkdir(parents=True,exist_ok=True)
 if not p.exists():p.write_bytes((ROOT/rel).read_bytes())
hashes={rel:hashlib.sha256((HERE/'before'/rel).read_bytes()).hexdigest() for rel in paths}
hashes['commons/scenes/endless_museum.gd']=hashlib.sha256((ROOT/'commons/scenes/endless_museum.gd').read_bytes()).hexdigest()
(HERE/'before-sha256.json').write_text(json.dumps(hashes,indent=2)+'\n')
print('Saved bounded Fractals snapshots.')
