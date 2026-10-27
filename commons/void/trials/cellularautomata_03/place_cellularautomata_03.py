"""Place all 27 source occurrences without changing source config, scale or height.

First transfer only; refuses to replace user arrangements without --force.
Locations separate the large original studies from the two shaft openings.
"""
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
inventory = json.loads((HERE / 'source-inventory.json').read_text())
rooms = json.loads((HERE / 'rooms.json').read_text())
if any(f['artifacts'] for f in rooms['floors']) and '--force' not in sys.argv:
    raise SystemExit('Existing arrangement: use --force only to deliberately replace it.')

POSITIONS = [
    [(0, 8.2), (-15, 8), (-16, -8), (0, -10), (15, 8), (16, -8)],
    [(0, 7), (15, 8), (-15, 8), (-4, -10), (15, -8), (0, -10), (-16, -8)],
    [(0, 7), (0, -10), (-15, 8), (15, 8), (-15, -8), (15, -8)],
    [(0, 6), (6, 8), (-15, -8)],
    [(0, 8), (-15, 8), (15, 8), (-15, -8), (15, -8)],
]

for level, positions in enumerate(POSITIONS, 1):
    entries = [p for p in inventory['placements'] if p['floor'] == level]
    assert len(entries) == len(positions)
    placed = []
    for item, (x, z) in zip(entries, positions):
        head, *bits = item['token'].split('#')
        values = head.split(':')
        yaw = float(values[1]) if len(values) > 1 and values[1] else 0
        height = float(values[2]) if len(values) > 2 and values[2] else 0
        scale = float(values[3]) if len(values) > 3 and values[3] else 1
        config = {}
        for bit in bits:
            key, _, value = bit.partition(':')
            config[key] = value or 'true'
        placed.append(dict(id=item['id'], artifact=item['artifact'],
                           station=('S' if z >= 0 else 'N') + ('E' if x >= 0 else 'W'),
                           position=[x, z], facing=int((yaw + 180) % 360),
                           height=height, scale=scale, config=config))
    rooms['floors'][level]['artifacts'] = placed

# Original proximity study has a collecting basin and ramps. Remove the host
# slab underneath so withdrawing cell support produces the original shallow fall.
rooms['floors'][2]['basin'] = dict(depth=.74, glass=False,
                                  rects=[[-2.62, -2.62, 5.24, 10.24]])
(HERE / 'rooms.json').write_text(json.dumps(rooms, indent=2) + '\n')
layout_file = HERE / 'layout.json'
layout = json.loads(layout_file.read_text())
layout['status'] = 'cellularautomata_03 / uncurated source transfer'
layout['floor_sign_positions'] = {str(i): [17, 12] for i in range(1, 6)}
layout_file.write_text(json.dumps(layout, indent=2) + '\n')
print('Placed all 27 original occurrences; original heights, scales and config retained.')
