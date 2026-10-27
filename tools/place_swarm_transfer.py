"""Batch 04: retain the eight source placements without curating the collection."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
folder = ROOT / 'commons/void/trials/swarmintelligence'
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))

def write(path, data):
    path.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')

inventory = read(folder / 'source-inventory.json')
rooms = read(folder / 'rooms.json')
assert not any(f['artifacts'] for f in rooms['floors']), 'Do not overwrite an edited trial.'
positions = [(15, 9), (0, 7), (-33, 0), (4, -6), (-4, 6), (3, 6), (-15, 8), (3, -9.5)]
for source, (x, z) in zip(inventory['placements'], positions):
    fields = source['token'].split('#')[0].split(':')
    config = {k: v or 'true' for k, _, v in (s.partition(':') for s in source['token'].split('#')[1:])}
    item = dict(id=source['id'], artifact=source['artifact'], position=[x, z],
                height=float(fields[2]) if len(fields) > 2 else 0,
                facing=int(fields[1]) if len(fields) > 1 else 0,
                scale=float(fields[3]) if len(fields) > 3 else 1,
                station=('N' if z < 0 else 'S') + ('W' if x < 0 else 'E'), config=config)
    rooms['floors'][source['floor']]['artifacts'].append(item)
    source.update(status='placed', void_position=[x, item['height'], z])
write(folder / 'rooms.json', rooms)
write(folder / 'source-inventory.json', inventory)
layout = read(folder / 'layout.json')
layout.update(storey_height=8, levels=[0, -8, -16, -24],
              status='Eight original placements; legacy PSO volume beside the tower awaits spatial fitting')
layout['descent']['landing_max_speed'] = 14
write(folder / 'layout.json', layout)
write(folder / 'transfer-status.json', dict(owner='Codex', stage='placed; validation pending',
    maps=inventory['maps'], source_placements=8, placed=8, omitted=[], native_tested=False,
    headset_tested=False, curated=False,
    adaptations=['Eight-metre storeys preserve the original seven-metre trace wall without shrinking its hand controls.',
                 'Legacy PSO remains full scale beside the west edge; simulation parameters unchanged.'],
    unresolved_dependencies=['Legacy PSO volume crosses storeys and has no walkable display route yet.',
                             'The original standalone ant has no colony or pheromone system attached.',
                             'Native inputs, viewport isolation and sleep/wake remain to be verified.']))
print('Placed all eight original Swarm artifacts.')
