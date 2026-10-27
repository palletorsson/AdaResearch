"""randomness_05 placement (Claude worker B, batch 25). Writes rooms.json floors 1-5.

Every inventoried token keeps its key, config (strings; a bare #key is "true") and scale.
Each hall is turned 180 degrees so its source spawn lands on the arrival (0, 12):
x = cx - col, z = cz - row, facing = (yaw + 180) % 360. Departures from that rigid
frame are listed in MOVES with the reason; heights are listed in HEIGHTS with the reason.

Run from the repo root: python commons/void/trials/randomness_05/place.py
"""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
inventory = json.loads((HERE / 'source-inventory.json').read_text(encoding='utf-8'))
rooms_path = HERE / 'rooms.json'
rooms = json.loads(rooms_path.read_text(encoding='utf-8'))

# Source spawn per map (cell of `s`, or `sp` where the map has no `s`).
SPAWN = {
    'Random_Space_Geometry': (0, 0),             # s
    'Randomness_Examples_of_Randomness': (7, 0),  # s
    'Random_Pheromone': (0, 0),                  # s
    'Random_Space': (5, 2),                      # sp:4:0:5 (the map has no s)
    'Random_Game': (9, 0),                       # s (sp:9:0:2 stands 3 rows further in)
}
ARRIVAL = (0.0, 12.0)

# id -> (x, z, facing or None for the rigid facing, reason)
MOVES = {
    'f1_seeded_room_5_7': (-1.5, 4.5, None,
        'rigid (-5, 5): the 9 x 10.3 m room entered shaft A (x -9.5..-7.5, z 0.5..3) and closed the '
        'floor-1 pad exit; moved 3.5 m east and 0.5 m north, entrance and console still face the arrival'),
    'f2_extreme_randomness_5_20': (2.0, -10.0, None,
        'rigid (2, -8): its 1.4 m particle gallery (1.5 m up) crossed the default floor sign at '
        '(3.5, -7.8); moved 2 m north'),
    # Random_Space: the whole hall moves together (+1.25, -11) so its 15.4 x 28 m walk surface
    # (random_space at scale 1.4) stands between the shafts, clear of the arrival, and leaves
    # shaft A (the descent shaft and its pads) open. The other four keep their places on it.
    'f4_noise_mixer_4_3': (2.25, 0.0, None, 'Random_Space hall shift (+1.25, -11)'),
    'f4_worley_noise_8_4': (-1.75, -1.0, None, 'Random_Space hall shift (+1.25, -11)'),
    'f4_random_space_6_6': (0.25, -3.0, None,
        'Random_Space hall shift (+1.25, -11): rigid (-1, 8) ran 6 m off the south edge and 1.2 m '
        'into shaft A; 15.4 m wide it cannot fit the 15.0 m between the shafts, so it is offset '
        '0.25 m east: shaft A clear, shaft B entered by 0.45 m (z -3..3); 1 m overhangs the north edge'),
    'f4_dark_sphere_5_7': (1.25, -4.0, None, 'Random_Space hall shift (+1.25, -11)'),
    'f4_shannon_entropy_meter_4_9': (2.25, -6.0, None, 'Random_Space hall shift (+1.25, -11)'),
    # Random_Game is 66 m long; the floor is 32 m. The crossing and the arena keep their rigid
    # places in the centre band; the rest fold into a loop in the source order.
    'f5_random_doors_9_29': (-16.5, -6.5, 0,
        'rigid (0, -17) is off the floor: folded into the west wing, approached from the north '
        'strip after the arena, so turned 180 degrees from the rigid facing to keep its chooser side '
        'toward the visitor'),
    'f5_door_timing_trials_9_38': (-13.4, 9.5, 0,
        'rigid (0, -26) is off the floor: west wing south of shaft A, approached from the north '
        '(after the doors), turned 180 degrees like the doors'),
    'f5_cube_projectile_spawner_9_51': (14.5, 7.5, None,
        'rigid (0, -39) is off the floor: east wing south of shaft B, approached from the south strip'),
    'f5_waiting_profile_9_61': (16.0, -8.0, None,
        'rigid (0, -49) is off the floor: east wing north of shaft B, approached from the south'),
}

# id -> (height, reason). Everything else keeps the token height (0 when the token has none).
HEIGHTS = {
    'f1_perlin_noise_bridge_6_16': (0.0, 'token -0.5 is the half-cube grid offset; the schema floor is 0 (its grids stand at 1 m on their own)'),
    'f1_curl_noise_particles_9_17': (0.25, 'token -0.5; the 0.7 x 0.5 x 0.7 flow volume is centred on its origin, so it is lifted 0.25 m to sit on the slab instead of half inside it'),
    'f4_noise_mixer_4_3': (0.9, 'token -0.5 with #plinth:0.9: the museum stands it on a 0.9 m station plinth ("the plinth IS the height claim"); the Void builds no plinth'),
    'f4_worley_noise_8_4': (0.4, 'token -0.5 with #plinth:0.4 (as noise_mixer)'),
    'f4_random_space_6_6': (0.0, 'token -0.3 with #offset:0,0.2,0 (net -0.1); the schema floor is 0, so the walk surface stands 0.1 m higher than that sum'),
    'f4_shannon_entropy_meter_4_9': (1.05, 'token -0.5 with #plinth:1.05 (as noise_mixer)'),
    'f5_r_c_9_6': (0.0, 'token 3 is measured from the 3 m basin floor of the source pit: flush with the floor; floor 5 carries that basin'),
    'f5_random_removal_arena_9_17': (0.0, 'token 3 is measured from the 3 m basin floor (as randomness_03); floor 5 carries that basin'),
}

BASIN = {5: {'depth': 3, 'glass': False, 'rects': [
    [-2.5, 4.5, 5, 3],    # the r_c pit: source cols 7-11, rows 5-7 (5 x 3 zero cells)
    [-4.5, -9.5, 9, 9],   # the arena basin: source cols 5-13, rows 13-21 (9 x 9 zero cells)
]}}


def parse(token):
    head, *fragments = token.split('#')
    parts = head.split(':')
    yaw = float(parts[1]) if len(parts) > 1 and parts[1] != '' else 0.0
    height = float(parts[2]) if len(parts) > 2 and parts[2] != '' else 0.0
    scale = float(parts[3]) if len(parts) > 3 and parts[3] != '' else 1.0
    config = {}
    for fragment in fragments:
        key, _, value = fragment.partition(':')
        config[key] = value if value != '' else 'true'
    return yaw, height, scale, config


def num(value):
    return int(value) if float(value).is_integer() else round(float(value), 4)


def station(x, z):
    return ('S' if z >= 0 else 'N') + ('E' if x >= 0 else 'W')


ledger = []
by_floor = {}
for p in inventory['placements']:
    yaw, height, scale, config = parse(p['token'])
    col, row = p['source_cell']
    sc, sr = SPAWN[p['map']]
    cx, cz = ARRIVAL[0] + sc, ARRIVAL[1] + sr
    rigid = (cx - col, cz - row)
    facing = int((yaw + 180) % 360)
    x, z = rigid
    reason = ''
    if p['id'] in MOVES:
        x, z, turned, reason = MOVES[p['id']]
        if turned is not None:
            facing = turned
    h_reason = ''
    if p['id'] in HEIGHTS:
        height, h_reason = HEIGHTS[p['id']]
    item = {
        'id': p['id'], 'artifact': p['artifact'], 'station': station(x, z),
        'position': [num(x), num(z)], 'facing': facing, 'height': num(height),
        'scale': num(scale), 'config': config,
    }
    by_floor.setdefault(p['floor'], []).append(item)
    ledger.append({'id': p['id'], 'token': p['token'], 'rigid': [num(rigid[0]), num(rigid[1])],
                   'placed': item['position'], 'rigid_facing': int((yaw + 180) % 360), 'facing': facing,
                   'token_height': parse(p['token'])[1], 'height': item['height'], 'scale': item['scale'],
                   'move': reason, 'height_note': h_reason})

for index, floor in enumerate(rooms['floors']):
    if index in by_floor:
        floor['artifacts'] = by_floor[index]
        if index in BASIN:
            floor['basin'] = BASIN[index]
        else:
            floor.pop('basin', None)

rooms_path.write_text(json.dumps(rooms, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
(HERE / 'placement-ledger.json').write_text(json.dumps(ledger, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
print(sum(len(v) for v in by_floor.values()), 'placements on floors', sorted(by_floor))
