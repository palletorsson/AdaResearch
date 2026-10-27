"""Batch 25 / randomness_04 placement (Claude worker A). Writes floors 1-5 of rooms.json.

Run from the repo root:  python commons/void/trials/randomness_04/place_randomness_04.py
It refuses to overwrite floors that already carry artifacts unless --force is given,
so an editor save is never clobbered silently.

Rigid 180-degree turn per hall: x = cx - col, z = cz - row, chosen so the source spawn
(s / sp) lands on the arrival (0, 12). facing = (token yaw + 180) mod 360. Token height and
scale are kept, except where a support height is documented in HEIGHTS below. Every move
off the rigid position is listed in MOVES with its reason and written to moves.json.
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]

# Source spawn cell per map -> (cx, cz) so the spawn lands on (0, 12).
ANCHORS = {
    'Random_Cubes': (0, 12),             # s at (0, 0)
    'Random_Rotate_Random_XYZ': (0, 12), # sp at (0, 0)
    'Random_Walk': (9, 12),              # s at (9, 0)
    'Random_Gaussian': (5, 12),          # s at (5, 0)
    'Random_Mushrooms': (8, 12),         # s at (8, 0)
}

# Honest-fit moves: (dx, dz) applied to the rigid position, with the reason.
FIELD_SHIFT = (2.0, 0.0)
HALL2_SHIFT = (5.0, 0.0)
MOVE_REASONS = {
    'random_edge_profile': 'Profile field moved as one 6 x 8 block, +2 m east: at the rigid position its '
                           'col-8 row (x -8.5..-7.5, z -3..3) stood inside shaft A, over the floor-2 '
                           'landing pad drop. The block keeps its 1 m cell pitch and rows; 1 m clearance '
                           'to shaft A.',
    'floor2': 'Whole Random_Rotate_Random_XYZ hall moved +5 m east as one rigid group: the '
              'random_decay_multimesh study fits its stacks to a 10 m display, which at the rigid '
              'anchor (-6, 2) spans x -11..-1 through shaft A; RotateGridCubes stood 7.5 cm from '
              'shaft A. One shared vector keeps every relation between the five works; the wall now '
              'ends 1.5 m short of shaft A.',
}

# Height decisions that differ from the token's own y-offset field (recorded).
HEIGHTS = {
    'random_object_spawner': (1.0, 'source structure "2" cell: the spawner stands on a 1 m block '
                                   '(museum plan support_height_m 1.0). The block is restored as a '
                                   'platform_block prop under each spawner.'),
    'random_walk_collection': (0.75, 'token #plinth:0.75: the museum stands the rack root on a 0.75 m '
                                     'plinth deck (plinth erases the hover). The six frozen sheets hang '
                                     '0.28-0.40 m below the root, so height 0 would bury them in the '
                                     'slab. No plinth is built in the Void (missing support).'),
}

# Floor-1 structure "2" cells under the two spawners, as Void platform blocks.
PROPS = {1: [
    {'id': 'f1_structure2_5_6', 'kind': 'platform_block', 'position': [-5, 6], 'facing': 0, 'scale': 1},
    {'id': 'f1_structure2_6_6', 'kind': 'platform_block', 'position': [-6, 6], 'facing': 0, 'scale': 1},
]}

# Floor-3 moat: the source's structure "0" ring around random_walk_128 (museum plan basin
# depth 2.5, glass false, fire false), turned rigidly with the hall (x = 9 - col, z = 12 - row).
BASINS = {3: {'depth': 2.5, 'glass': False, 'rects': [
    [6.5, -12.5, 1, 15],    # col 2,  rows 10..24
    [-7.5, -12.5, 1, 15],   # col 16, rows 10..24
    [1.5, 1.5, 5, 1],       # row 10, cols 3..7
    [-6.5, 1.5, 5, 1],      # row 10, cols 11..15
    [1.5, -12.5, 5, 1],     # row 24, cols 3..7
    [-6.5, -12.5, 5, 1],    # row 24, cols 11..15
]}}


def num(v):
    f = float(v)
    return int(f) if f.is_integer() else round(f, 4)


def main() -> None:
    force = '--force' in sys.argv
    rooms_path = HERE / 'rooms.json'
    rooms = json.loads(rooms_path.read_text(encoding='utf-8-sig'))
    inv = json.loads((HERE / 'source-inventory.json').read_text(encoding='utf-8-sig'))
    if not force:
        assert not any(f['artifacts'] for f in rooms['floors']), 'rooms.json already has placements; use --force'
    for f in rooms['floors'][1:6]:
        f['artifacts'] = []
        f['props'] = []
        f.pop('basin', None)
    moves = []
    for p in inv['placements']:
        token, *cfg = p['token'].split('#')
        parts = token.split(':')
        yaw = float(parts[1]) if len(parts) > 1 and parts[1] != '' else 0.0
        height = float(parts[2]) if len(parts) > 2 and parts[2] != '' else 0.0
        scale = float(parts[3]) if len(parts) > 3 and parts[3] != '' else 1.0
        config = {}
        for s in cfg:
            k, _, v = s.partition(':')
            config[k] = v or 'true'
        cx, cz = ANCHORS[p['map']]
        col, row = p['source_cell']
        rigid = [cx - col, cz - row]
        at = list(rigid)
        reason = ''
        if p['artifact'] == 'random_edge_profile':
            at = [rigid[0] + FIELD_SHIFT[0], rigid[1] + FIELD_SHIFT[1]]
            reason = MOVE_REASONS['random_edge_profile']
        elif p['floor'] == 2:
            at = [rigid[0] + HALL2_SHIFT[0], rigid[1] + HALL2_SHIFT[1]]
            reason = MOVE_REASONS['floor2']
        if p['artifact'] in HEIGHTS:
            height = HEIGHTS[p['artifact']][0]
        at = [num(at[0]), num(at[1])]
        item = {
            'id': p['id'], 'artifact': p['artifact'],
            'station': ('N' if at[1] < 0 else 'S') + ('W' if at[0] < 0 else 'E'),
            'position': at,
            'facing': int((yaw + 180) % 360),
            'height': num(height), 'scale': num(scale), 'config': config,
        }
        rooms['floors'][p['floor']]['artifacts'].append(item)
        if at != [num(rigid[0]), num(rigid[1])]:
            moves.append({'id': p['id'], 'rigid': [num(rigid[0]), num(rigid[1])], 'placed': at, 'reason': reason})
    for floor, props in PROPS.items():
        rooms['floors'][floor]['props'] = props
    for floor, basin in BASINS.items():
        rooms['floors'][floor]['basin'] = basin
    rooms_path.write_text(json.dumps(rooms, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    heights = [{'artifact': k, 'height': v[0], 'why': v[1]} for k, v in HEIGHTS.items()]
    (HERE / 'moves.json').write_text(json.dumps({'moves': moves, 'heights': heights,
        'props': PROPS, 'basins': BASINS}, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print(len(inv['placements']), 'placements;', len(moves), 'moved;', 'floors 1-5 written')


if __name__ == '__main__':
    main()
