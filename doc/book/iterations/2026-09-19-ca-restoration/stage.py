"""Restore the two existing primary works as an approachable comparison gallery."""
from pathlib import Path
import copy
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
paths = ['commons/maps/CA_AgentsCircuits/map_data.json',
         'commons/maps/CA_AgentsCircuits/final.md',
         'commons/maps/sequences/cellularautomata.json',
         'commons/data/artifact_roles.json', 'commons/data/museum_core_encounters.json',
         'commons/data/map_authored.json', 'ada_run/em_plan.json',
         'commons/data/museum/em_plan.json', 'commons/data/long_museum.json',
         'commons/data/museum_order_effective.json', 'commons/scenes/endless_museum.gd']
hashes = {}
for rel in paths:
    source = ROOT / rel
    saved = HERE / 'before' / rel
    saved.parent.mkdir(parents=True, exist_ok=True)
    if not saved.exists():
        saved.write_bytes(source.read_bytes())
    hashes[rel] = hashlib.sha256(saved.read_bytes()).hexdigest()
(HERE/'before-sha256.json').write_text(json.dumps(hashes, indent=2)+'\n', encoding='utf-8')
rel = paths[0]
path = ROOT / rel
before = json.loads((HERE/'before'/rel).read_text(encoding='utf-8'))
doc = copy.deepcopy(before)
w, h = 13, 18
structure = [['4' if x in (0,w-1) or z in (0,h-1) else '1' for x in range(w)] for z in range(h)]
for z in [0,h-1]:
    for x in [5,6,7]: structure[z][x] = '1'
utilities = [[' ']*w for _ in range(h)]
utilities[1][6] = 's'
utilities[h-2][6] = 't'
artifacts = [[' ']*w for _ in range(h)]
artifacts[5][3] = 'ca_rule_explorer:180:1.04:1#study:neighbours#rule:90#plinth:0'
artifacts[12][9] = 'sierpinski_pyramid:0:0:0.42#plinth:0.25'
doc['layers'] = dict(structure=structure, utilities=utilities, interactables=artifacts)
doc['map_info'].update(title='The same pattern, different work',
    description='Follow triangular gaps on the Rule 90 desk near the entrance, then compare one remembered arrangement with the recursive pyramid beyond. Both works remain primary; the shared floor gives room to return and compare.',
    version='comparison-gallery-2026-09-19', dimensions=dict(width=w, depth=h, max_height=4),
    museum=dict(wall_height=3, open_roof=True, artifact_placement='map', plinths=False,
                piers=False, gate_depth_rows=0))
doc['map_info']['metadata']['learning_objectives'] = [
    'Follow a pattern made by repeated ordered-neighbour updates',
    'Compare one gap and its neighbours with a recursive construction',
    'Distinguish visual resemblance from a shared procedure',
    'Locate a correspondence and a point where the analogy fails']
doc['utility_definitions'].pop('s', None)
old_tokens = sorted(str(cell).split(':')[0].split('#')[0] for row in before['layers']['interactables'] for cell in row if str(cell).strip())
new_tokens = sorted(str(cell).split(':')[0].split('#')[0] for row in artifacts for cell in row if str(cell).strip())
assert old_tokens == new_tokens == ['ca_rule_explorer','sierpinski_pyramid']
current = json.loads(path.read_text(encoding='utf-8'))
first_placement = copy.deepcopy(doc)
first_placement['layers']['interactables'][5][3] = 'ca_rule_explorer:180:0:1#study:neighbours#rule:90#plinth:0'
assert current in [before,doc,first_placement], 'Map changed while staging; reconcile first'
if current != doc:
    path.write_text(json.dumps(doc, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
(HERE/'staging.json').write_text(json.dumps(dict(
    dimensions=[w,h], preserved_artifacts=new_tokens,
    primary_order=['ca_rule_explorer','sierpinski_pyramid'],
    source_cells={'ca_rule_explorer':[3,5],'sierpinski_pyramid':[9,12]},
    reason='Give the existing comparison its own continuous gallery, with the desk first and a walk-around sculpture beyond.',
    source_algorithms_changed=False, headset_tested=False), indent=2)+'\n', encoding='utf-8')
print('Staged 13 × 18 gallery; both original artifacts retained; book unchanged.')
