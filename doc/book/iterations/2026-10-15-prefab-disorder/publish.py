"""Publish actual native evidence, keeping the authored main route unchanged."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
RUN = ROOT / 'ada_run/encounter_pilot/Random_Entropy/prefab-disorder'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

for name in ['report.json', 'hall-zero.png', 'hall-half.png', 'hall-full.png', 'source_manifest.json']:
    shutil.copy2(RUN / name, HERE / ('museum-report.json' if name == 'report.json' else name))
shutil.copy2(ROOT / 'commons/artifacts/prefab_disorder/README.md', HERE / 'implementation.md')
reports = [read(HERE / name) for name in ['verification.json', 'museum-report.json']]
assert all(r['passed'] for r in reports)

before = read(HERE / 'before/commons/data/museum/em_plan.json')
after = read(ROOT / 'commons/data/museum/em_plan.json')
assert len(before['plans']) == len(after['plans'])
changed = [(i, a, b) for i, (a, b) in enumerate(zip(before['plans'], after['plans'])) if a != b]
assert len(changed) == 1 and 'Random_Entropy' in json.dumps(changed[0][2])
old_map = read(HERE / 'before/commons/maps/Random_Entropy/map_data.json')
new_map = read(ROOT / 'commons/maps/Random_Entropy/map_data.json')
old_map['layers']['interactables'][3][13] = 'prefab_disorder:180'
assert old_map == new_map, 'An existing placement or map field changed.'
wall = read(ROOT / 'commons/maps/Random_Entropy/writing_wall.json')
assert wall['order'][:6] == ['shannon_entropy_meter', 'entropy_jar', 'entropy_compartments', 'entropy_axiom', 'entropy_ruin', 'signal_room']
web = read(ROOT / 'commons/data/long_museum.json')
hall = next(s for s in web['segments'] if s.get('name') == 'Random_Entropy' and s['kind'] == 'hall')
assert {'x': 13, 'z': 3, 'token': 'prefab_disorder', 'rot': 180} in hall['artifacts']

paths = list((ROOT / 'commons/artifacts/prefab_disorder').glob('*.gd'))
paths += list((ROOT / 'commons/artifacts/prefab_disorder').glob('*.tscn'))
paths += [ROOT / 'commons/artifacts/registry/prefab_disorder.json']
paths += [ROOT / 'commons/maps/Random_Entropy' / name for name in ['map_data.json', 'tutorial.md', 'final.md', 'writing_wall.json', 'artifacts.md']]
for source in ['cardboard_box', 'computer_monitor', 'lab_stool', 'microscope']:
    paths += [ROOT / 'commons/artifacts' / source / (source + suffix) for suffix in ['.gd', '.tscn']]
(HERE / 'manifest.json').write_text(json.dumps({
    'checks': [len(r['checks']) for r in reports],
    'only_changed_plan_row': changed[0][0],
    'existing_placements_unchanged': True,
    'main_order_unchanged': True,
    'web_export_contains_study': True,
    'sha256': {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},
}, indent=2), encoding='utf8')
print('Published evidence:', HERE / 'index.html')
