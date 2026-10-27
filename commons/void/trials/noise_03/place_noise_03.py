"""noise_03 placement (worker D, batch 25). Writes this folder's rooms.json only.

Rigid 180-degree turn per hall: x = cx - col, z = cz - row, with the source spawn
(s/sp) on the arrival (0, 12). Facing = (token yaw + 180) mod 360. Moves are listed
in MOVES with the reason; everything else stays at its rigid position.
Run: python commons/void/trials/noise_03/place_noise_03.py
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

# Height above the slab = museum support_height_m + token y offset (em_plan rows 88-90).
# Lab_Path is not in the museum plan; its token carries no offset.
SUPPORT = {'f2_dark_sphere_11_3': 1.0}  # source cell is structure '2' (1 m ring)

# id -> (new x, new z, reason). Rigid positions are computed and recorded beside them.
MOVES = {
    'f1_box_shell_space_17_19': (35.0, -6.0, 'box shell is ~24 x 29 x 10 m (mesh BOUNDS 27 x 11 x 29); two shells need >= 51 m on a 42 m floor and any dome over a shaft would fill that shaft column in the storey above. Exterior specimen beside the east edge, clear of the tower, floor:false kept (isosurfaces mc_cave precedent).'),
    'f1_box_atrium_space_51_19': (-35.0, -6.0, 'box atrium is ~26 x 29 x 10 m; same reason; exterior specimen beside the west edge.'),
    'f2_noise_space_6_6': (-6.5, 8.2, 'rigid (-6, 6): its 9.6 m stone margin and control panel entered shaft A (x -12.5..-7.5, z -3..3). Hall shifted (-0.5, +2.2) as a group; -0.5 keeps the entry ramp 0.55 m off column (-5, 14).'),
    'f2_dark_sphere_11_3': (-11.5, 11.2, 'same group shift as the noise space (source relation kept).'),
    'f3_simplex_noise_3_13': (2.0, 0.0, 'rigid (-2, 0); hall shifted +4 x as a group so the perlin field leaves shaft A.'),
    'f3_perlin_noise_8_13': (-3.0, 0.0, 'rigid (-7, 0): its 4 m field entered shaft A. Group shift +4 x.'),
    'f3_perlin_noise_terrain_2_17': (3.0, -4.0, 'group shift +4 x.'),
    'f3_dark_sphere_6_17': (-1.0, -4.0, 'group shift +4 x.'),
    'f3_configurable_portal_9_19': (-4.0, -6.0, 'group shift +4 x.'),
}

# Floor 3 order matters: the simplex pair study is built deferred from the simplex's
# _ready and looks up its twin (perlin) and the terrain. When the floor is streamed one
# factory per frame, both must already exist, so the simplex goes last.
ORDER = {3: ['f3_perlin_noise_terrain_2_17', 'f3_dark_sphere_6_17', 'f3_perlin_noise_8_13',
             'f3_simplex_noise_3_13', 'f3_configurable_portal_9_19']}

# Source structure reproduced only where a placement needs support or access
# (abstract floors draw no support rods). Delete to remove; nothing else depends on it.
CONSTRUCTION = {2: [
    # the source '2' cell (1 m) the dark sphere stands on
    {'id': 'f2_raised_cell_11_3', 'kind': 'cube', 'position': [-11.5, 0, 11.2], 'facing': 0},
    # the source wp walkways, as the existing 1 x 2 x 1 m wp wedge: onto the 1 m stone
    # margin at the noise space's entry gate (arrival side) and from its exit gate
    {'id': 'f2_access_wp_entry', 'kind': 'wedge', 'position': [-6.5, 0, 14.0], 'facing': 180},
    {'id': 'f2_access_wp_exit', 'kind': 'wedge', 'position': [-6.5, 0, 2.4], 'facing': 0},
]}

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
    height = SUPPORT.get(p['id'], 0.0) + y
    if height < 0:
        report.append(f"{p['id']}: token height {y} below 0; schema minimum 0 used")
        height = 0.0
    x, z = rigid
    if p['id'] in MOVES:
        x, z, why = MOVES[p['id']]
        report.append(f"{p['id']}: rigid {rigid} -> ({x}, {z}): {why}")
    entry = {'id': p['id'], 'artifact': p['artifact'], 'station': station(x, z),
             'position': [x, z], 'facing': int((yaw + 180) % 360), 'height': round(height, 3),
             'scale': scale, 'config': config}
    by_floor.setdefault(p['floor'], []).append(entry)

for floor, items in by_floor.items():
    if floor in ORDER:
        items.sort(key=lambda e: ORDER[floor].index(e['id']))
    record = rooms['floors'][floor]
    expected = {p['map'] for p in inventory['placements'] if p['floor'] == floor}
    assert expected == {record['map']}, (floor, record['map'], expected)
    record['artifacts'] = items
for floor, parts in CONSTRUCTION.items():
    rooms['floors'][floor]['construction'] = parts

(HERE / 'rooms.json').write_text(json.dumps(rooms, indent=2) + '\n', encoding='utf-8')
print('\n'.join(report))
print('placed', sum(len(v) for v in by_floor.values()))
