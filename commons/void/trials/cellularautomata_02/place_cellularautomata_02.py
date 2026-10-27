"""cellularautomata_02 placement (worker D, batch 25). Writes this folder's rooms.json only.

Rigid 180-degree turn: x = 6 - col, z = 12 - row (source spawn sp at col 6, row 0 lands
on the arrival (0, 12)). Facing = (token yaw + 180) mod 360. Moves are listed in MOVES.
Run: python commons/void/trials/cellularautomata_02/place_cellularautomata_02.py
"""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
inventory = json.loads((HERE / 'source-inventory.json').read_text(encoding='utf-8-sig'))
rooms = json.loads((HERE / 'rooms.json').read_text(encoding='utf-8-sig'))

def spawn(map_name):
    grid = json.loads((ROOT / 'commons/maps' / map_name / 'map_data.json').read_text(encoding='utf-8'))['layers']['utilities']
    for r, row in enumerate(grid):
        for c, cell in enumerate(row):
            if str(cell).strip().split(':')[0] in ('s', 'sp'):
                return c, r
    raise SystemExit('no spawn in ' + map_name)

MOVES = {
    'f1_lab_room_6_22': (-7.5, -9.6, 'rigid (0, -10): the 8 x 7 m room enclosed the default floor sign (3.5, -7.8) and left no slab for the rear gallery. Moved west; north wall 0.45 m off column (-5, -14); door (west after the turn) and stairs face the open strip east of shaft A.'),
    'f1_dark_sphere_4_28': (2.0, -13.0, 'rigid (2, -16) is the slab edge. Rear gallery pulled 3 m in, x kept.'),
    'f1_ca_columns_8_28': (-2.0, -13.0, 'rigid (-2, -16) is the slab edge (footprint 1.8 m at scale 0.2). Pulled 3 m in, x kept, 0.6 m east of the moved lab room.'),
    'f1_mirrored_cellular_automata_6_32': (0.0, -15.0, 'rigid (0, -20) is 4 m beyond the slab. Pulled to 1 m inside the north edge, still behind the sphere/columns line (2 m instead of 4 m).'),
}

# The source hole (structure 0, cols 3..9, rows 5..14 -> x -3.5..3.5, z -2.5..7.5 after
# the turn) under the bridge. ca_bridge's history study builds its own collecting floor
# (top -0.60, 0.12 thick) and two ramps for exactly this opening. A 0.72 m open basin cuts
# the slab so that floor rests on the basin bottom. The rect is 0.1 m wider per side than
# the hole: basin.gd stands its 0.1 m walls INSIDE the rect, and inside the hole they
# would put a 5 cm lip at the top of each ramp; here they sit flush beyond the ramp ends,
# like the museum's tile edge.
BASIN = {1: {'depth': 0.72, 'glass': False, 'rects': [[-3.6, -2.6, 7.2, 10.2]]}}

def station(x, z):
    return ('S' if z >= 0 else 'N') + ('E' if x >= 0 else 'W')

def parse(token):
    head, *frags = token.split('#')
    parts = head.split(':')
    yaw = float(parts[1]) if len(parts) > 1 and parts[1] else 0.0
    y = float(parts[2]) if len(parts) > 2 and parts[2] else 0.0
    scale = float(parts[3]) if len(parts) > 3 and parts[3] else 1.0
    config = {}
    for f in frags:
        key, _, value = f.partition(':')
        config[key] = value if value else 'true'
    return yaw, y, scale, config

report = []
by_floor = {}
for p in inventory['placements']:
    sc, sr = spawn(p['map'])
    cx, cz = sc, 12 + sr
    col, row = p['source_cell']
    rigid = (float(cx - col), float(cz - row))
    yaw, y, scale, config = parse(p['token'])
    height = y
    if height < 0:
        report.append(f"{p['id']}: token height {y}; schema minimum 0 used")
        height = 0.0
    x, z = rigid
    if p['id'] in MOVES:
        x, z, why = MOVES[p['id']]
        report.append(f"{p['id']}: rigid {rigid} -> ({x}, {z}): {why}")
    by_floor.setdefault(p['floor'], []).append({
        'id': p['id'], 'artifact': p['artifact'], 'station': station(x, z),
        'position': [x, z], 'facing': int((yaw + 180) % 360), 'height': round(height, 3),
        'scale': scale, 'config': config})

for floor, items in by_floor.items():
    record = rooms['floors'][floor]
    expected = {p['map'] for p in inventory['placements'] if p['floor'] == floor}
    assert expected == {record['map']}, (floor, record['map'], expected)
    record['artifacts'] = items
for floor, basin in BASIN.items():
    rooms['floors'][floor]['basin'] = basin

(HERE / 'rooms.json').write_text(json.dumps(rooms, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
print('\n'.join(report))
print('placed', sum(len(v) for v in by_floor.values()))
