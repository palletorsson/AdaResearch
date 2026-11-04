"""Trans_Pre (Void floor 13) rebuilt at Palle's word, 2026-11-03.

"Stand-alone one cell platforms with two wedges for the static cube, translate cube, rotate cube and scale cube. Then
different platform configs of cube: one with two cubes and a wedge, one with three cubes and a wedge, then one with two
parallel platforms with four cubes and one wedge. For some of the later cubes spawn health plus and random falling
prefabs." Markers kept.

Writes floor 13 of commons/void/rooms.json: its construction (cubes and wedges of the primitives kit), the positions of
its own artifacts and props, and its route - and nothing else in the file, which is written back in its own format
(json indent 2, ensure_ascii off; it round-trips byte for byte). Prints a top view.

Geometry (floor-local metres, y = 0 the floor): a cube cell is 1 x 1 x 1 m with its origin at the bottom centre; a
wedge is 1 m wide, 1 m high, a 2 m run, centred on its cell, rising toward +z at facing 0, -z at 180, +x at 90,
-x at 270 (construction_grid.gd turns it about +y). Shafts A and B (6 x 6 m) stand at x -13..-7 and 7..13, z -3..3.

  python tools/trans_pre_layout.py [--write]
"""
from pathlib import Path
import json, os, sys

ROOT = Path(__file__).resolve().parents[1]
ROOMS = ROOT / 'commons/void/rooms.json'
FLOOR = 13
# On the floor's cell grid (Palle, 2026-11-03: "still out of grid"): every cube in a 1 m cell between whole metres, centre n + 0.5,
# as the game's own floor cells and the voxel editor's Levels brush stand; a wedge's 2 m run then ends on whole metres.
ZI = 0.5                 # the islands' row: cube cells at z 0.5, wedges centred at z 2 and -1
ISLANDS = [(-5.5, 'still', None, 'STILL'), (-1.5, 'rise', 'translation-marker', 'TRANSLATE'),
           (1.5, 'turn', 'rotation-marker', 'ROTATE'), (5.5, 'swell', 'scale-marker', 'SCALE')]
WEDGE_X = 15.0           # the configurations' one wedge, rising toward +x (x 14..16)
CONFIGS = [               # z, cube xs (each 1 m, from x 16)
    ('c1', 5.5, [16.5, 17.5]),
    ('c2', 2.5, [16.5, 17.5, 18.5]),
    ('c3a', -0.5, [16.5, 17.5, 18.5, 19.5]),
    ('c3b', -2.5, [16.5, 17.5, 18.5, 19.5]),   # the parallel row: no wedge, a 1 m gap from c3a
]
# step boxes stand in a configuration's row instead of a cube (each is its own 1 m box)
STEP_BOXES = {('c2', 17.5): ('first-health', 'void_step_health_box', {}),
              ('c3a', 17.5): ('found-solid', 'void_step_prefab_box', {'drop_m': 2.2}),
              ('c3b', 18.5): ('last-health', 'void_step_health_box', {}),
              ('c3b', 16.5): ('found-solid-2', 'void_step_prefab_box', {'drop_m': 2.2})}
PICKUPS = {'pickup-1': ('c1', 17.5), 'pickup-2': ('c2', 18.5), 'pickup-3': ('c3a', 19.5), 'pickup-4': ('c3b', 19.5)}


def build():
    construction = []
    n = 0
    def piece(kind, x, z, facing):
        nonlocal n
        construction.append({'id': 'Pre-%s-%03d' % (kind, n), 'kind': kind, 'position': [x, 0, z], 'facing': facing})
        n += 1
    for x, _, _, _ in ISLANDS:
        piece('wedge', x, ZI + 1.5, 180)    # south wedge, rising north to the cube
        piece('cube', x, ZI, 0)
        piece('wedge', x, ZI - 1.5, 0)     # north wedge, rising south to the cube
    rows = {}
    for name, z, xs in CONFIGS:
        rows[name] = z
        if name != 'c3b':
            piece('wedge', WEDGE_X, z, 90)
        for x in xs:
            if (name, x) not in STEP_BOXES:
                piece('cube', x, z, 0)
    return construction, rows


def route():
    r = [('WALK UP / THE SAME BUILDING PIECES', -6, 4.2)]
    for i, (x, _, _, word) in enumerate(ISLANDS):
        north_first = i % 2 == 1           # the walk zig-zags: up from the south, then back from the north
        a, b = (ZI - 3.2, ZI + 3.2) if north_first else (ZI + 3.2, ZI - 3.2)
        r.append(('%02d / %s' % (i + 1, word), x, a))
        r.append(('over the cube', x, b))
    r += [('NOW COLLECT THE MOVEMENT', 10, 4.6),
          ('05 / TWO CUBES', 13.4, 5.5), ('on the two cubes', 17.5, 5.5), ('step off', 17.5, 3.8),
          ('06 / THREE CUBES', 13.4, 2.5), ('on the three cubes', 18.5, 2.5), ('step off', 18.5, 0.9),
          ('07 / TWO PARALLEL ROWS', 13.4, -0.5), ('along the first row', 19.5, -0.5), ('jump to the parallel row', 19.5, -2.5),
          ('step off', 18, -4.0), ('B / NEXT FLOOR', 16, -6.2)]
    return [{'label': l, 'position': [x, z]} for l, x, z in r]


def main():
    sys.stdout.reconfigure(encoding='utf8')
    raw = ROOMS.read_text(encoding='utf8')
    data = json.loads(raw)
    if json.dumps(data, indent=2, ensure_ascii=False) + '\n' != raw:
        sys.exit('rooms.json does not round-trip in its own format; not writing')
    f = data['floors'][FLOOR]
    assert f['map'] == 'Trans_Pre', f['map']
    construction, rows = build()
    # pieces painted in the editor stay (Levels cubes on the cell grid); the first Levels test's cubes, painted half a
    # cell off before the brush was fixed, go (saved in ada_run/trans-pre/floor13_before_grid_2026-11-03.json)
    on_grid = lambda p: abs(p['position'][0] % 1 - .5) < 1e-6 and abs(p['position'][2] % 1 - .5) < 1e-6
    kept = [p for p in f.get('construction', []) if not p['id'].startswith('Pre-') and (on_grid(p) or not p['id'].startswith('level-cube'))]
    f['construction'] = construction + kept
    arts = {a['id']: a for a in f['artifacts']}
    for x, demo, marker, _ in ISLANDS:
        arts[demo]['position'] = [x, ZI]               # the demo cube floats 1 m over its island's cube (height 2)
        if marker:
            arts[marker]['position'] = [x + 1.2, ZI]   # its marker beside the island, as before at eye height
    for pid, (row, x) in PICKUPS.items():
        arts[pid]['position'] = [x, rows[row]]
    for (row, x), (ident, artifact, config) in STEP_BOXES.items():
        item = arts.get(ident)
        if item is None:
            item = {'id': ident, 'artifact': artifact, 'station': 'NE', 'position': [0, 0], 'height': 0, 'scale': 1, 'facing': 0,
                    'config': {'editor_label': 'Step box / random familiar solid, falling', 'contents': 'prefab', 'boost': 25}}
            f['artifacts'].append(item)
            arts[ident] = item
        item['position'] = [x, rows[row]]
        item['config'].update(config)
        if config.get('drop_m'):
            item['config']['editor_label'] = 'Step box / random familiar solid, falling'
    arts['health-2']['position'] = [20.3, 3.6]        # off the two-cube row
    props = {p['id']: p for p in f.get('props', [])}
    props['demo-work-light']['position'] = [-3.5, -6.2]
    props['route-work-light']['position'] = [20.4, 6.0]
    f['route'] = route()
    # top view: cube tops (#), wedges (/), step boxes (h / p), islands' demo cubes (o)
    grid = {}
    for p in construction:
        x, _, z = p['position']
        if p['kind'] == 'cube':
            grid[(round(x * 2), round(z * 2))] = '#'
        else:
            for t in (-0.5, 0.5):
                dx, dz = {0: (0, t), 180: (0, t), 90: (t, 0), 270: (t, 0)}[p['facing']]
                grid[(round((x + dx) * 2), round((z + dz) * 2))] = '/'
    for (row, x), (ident, artifact, _) in STEP_BOXES.items():
        grid[(round(x * 2), round(rows[row] * 2))] = 'p' if 'prefab' in artifact else 'h'
    for z2 in range(-14, 13):
        line = ''.join(grid.get((x2, z2), ('|' if (-26 <= x2 <= -14 or 14 <= x2 <= 26) and -6 <= z2 <= 6 else '.')) for x2 in range(-14, 42))
        print('%5.1f %s' % (z2 / 2, line))
    print('x from -7 to 20.5 in half metres; | = shafts; %d construction pieces' % len(construction))
    if '--write' in sys.argv:
        text = json.dumps(data, indent=2, ensure_ascii=False) + '\n'
        tmp = ROOMS.with_suffix('.json.tmp')
        tmp.write_text(text, encoding='utf8', newline='\n')
        os.replace(tmp, ROOMS)
        print('wrote floor 13 to', ROOMS)


if __name__ == '__main__':
    main()
