"""Palle's four Primitives asks of 2026-11-05, placed in the tower:
  floor 3  Point_Lines          point_line_room in the scaffold workstation's glass bay over shaft A ("turn that box
                                black"), at the workstation's Output (-10, 0); the museum two_points_line moved into it
  floor 4  Point_Trace          standing_grid, 8 x 4 m - a clear spot found by tools/probes/void_candidates.gd
  floor 9  Primitives_Columns   form_table - a clear spot found the same way (Palle: "in 09 columns"; the floor-10 entry removed)
  floor 12 Primitives_Melencolia durer_box round the hall's MelencoliaEngraving part (measured: x -18.14..-13.24,
                                z -4.30..2.48, 5.70 m tall, its front toward +x / shaft A), the open front at x -13.18 so
                                the grid's frame stands on solid floor; three museum works moved out of the walls' way
--apply writes rooms.json (read, changed, written back in its own format); without it, only the probe's spots print.
  python tools/place_primitives_rooms.py [--apply | --moves-only]
"""
from pathlib import Path
import json, os, subprocess, sys
from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/primitives-rooms-placement'
ROOMS = ROOT / 'commons/void/rooms.json'

AUTO = [
    ('primitives-standing-grid', 'Point_Trace', 'standing_grid', {'editor_label': 'Standing grid: 8 x 4 m, a net in a large frame'},
     {'size': [8.5, 4.5, 2.0], 'centre': [0, 0, 0], 'near': [-9.5, -5.0]}),
    # floor 9 at Palle's word (2026-11-05: "the form table should be in 09 columns"); the first apply had put it on Profiles
    ('primitives-form-table', 'Primitives_Columns', 'form_table', {'editor_label': 'Form table: cones and column parts that snap'},
     {'size': [2.3, 1.3, 1.25], 'centre': [0, 0, .03], 'near': [3.5, -5.5]}),
]
FIXED = [
    ('point-room', 'Point_Lines', 'point_line_room', {'editor_label': 'The point room: black, in the workstation bay over shaft A'}, [-10.0, 0.0], 0),
    ('durer-box', 'Primitives_Melencolia', 'durer_box', {'editor_label': 'Box and grid round the Melencolia sculpture, the sight across the shaft'}, [-15.85, -0.9], 90),
]
# entries the first apply made and Palle then re-placed: taken out before the appends
REMOVES = [('Primitives_Profiles', 'primitives-form-table')]
# (floor map, artifact, old position) -> new position [, facing]
MOVES = [
    ('Point_Lines', 'two_points_line', [-18, -7.5], [-12.4, 1.0], 90),
    ('Primitives_Melencolia', 'eleven_dots', [-18.0, -4.4], [-18.0, -6.4], None),
    # the bigframes are boxbeam portals 2.3 m across, their width along z (museum_yaw 90): at z 3.6 they still cut the
    # south wall (the probe's clash check, 2026-11-05 10:21), so the pair goes south-west, 0.43 m off the wall
    ('Primitives_Melencolia', 'bigframe', [-15.0, 3.0], [-17.5, 4.5], None),
    ('Primitives_Melencolia', 'bigframe', [-13.5, 3.0], [-16.0, 4.5], None),
    ('Primitives_Melencolia', 'bigframe', [-15.0, 3.6], [-17.5, 4.5], None),   # from the first apply's interim spot
    ('Primitives_Melencolia', 'bigframe', [-13.5, 3.6], [-16.0, 4.5], None),
    ('Primitives_Melencolia', 'snap_pyramid_puzzle', [-13.5, -4.5], [-12.2, -5.2], None),
]


def main():
    sys.stdout.reconfigure(encoding='utf8')
    rooms = json.loads(ROOMS.read_text(encoding='utf8'))
    floor_of = {}
    for i, f in enumerate(rooms['floors']):
        floor_of.setdefault(f.get('map'), i)
    plan = []
    for ident, hall, token, cfg, fp in AUTO:
        plan.append({'floor': floor_of[hall], 'hall': hall, 'token': token, 'id': ident, 'size': fp['size'], 'centre': fp['centre'], 'near': fp['near'], 'inside': True})
    OUT.mkdir(parents=True, exist_ok=True)
    if '--moves-only' in sys.argv:   # the spots are known: only MOVES (and FIXED) are applied, no probe run
        _apply({}, floor_of)
        return
    (OUT / 'plan.json').write_text(json.dumps(plan, indent=1), encoding='utf8')
    for stale in ('placements.json', 'checks.json', 'godot.log'):
        (OUT / stale).unlink(missing_ok=True)
    stage = stage_runtime()
    with (OUT / 'engine.log').open('w', encoding='utf8') as stream:
        subprocess.run([sys.executable, str(ROOT / 'tools/godot_watchdog.py'), '--expect=' + str(OUT), '--grace=240', '--stall=180', '--',
            os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
            '--headless', '--log-file', str(OUT / 'godot.log'), '--path', str(stage), '--xr-mode', 'off',
            '--script', 'res://tools/probes/void_candidates.gd', '--', '--out=' + OUT.as_posix(), '--plan=' + (OUT / 'plan.json').as_posix()
        ], stdout=stream, stderr=subprocess.STDOUT, timeout=1800, creationflags=subprocess.CREATE_NO_WINDOW)
    report = OUT / 'placements.json'
    if not report.exists():
        log = OUT / 'godot.log'
        print('the probe did not report; log tail:')
        print((log.read_text(encoding='utf8', errors='replace') if log.exists() else (OUT / 'engine.log').read_text(encoding='utf8', errors='replace'))[-4000:])
        sys.exit(1)
    results = {r['row']['id']: r for r in json.loads(report.read_text(encoding='utf8'))}
    for ident, r in results.items():
        s = r['spot']
        print('%-26s floor %3d  %s' % (ident, r['floor'], ('(%.1f, %.1f) facing %d, %.1f m from the route' % (s['x'], s['z'], s['facing'], s['to_route'])) if s else 'NO SPOT'))
    if '--apply' not in sys.argv:
        return
    _apply(results, floor_of)


def _apply(results, floor_of):
    raw = ROOMS.read_text(encoding='utf8')
    data = json.loads(raw)
    if json.dumps(data, indent=2, ensure_ascii=False) + '\n' != raw:
        sys.exit('rooms.json does not round-trip in its own format any more; not writing')
    entries = []
    for ident, hall, token, cfg, fp in AUTO:
        r = results.get(ident)
        if not r or not r['spot']:
            print('not placed:', ident); continue
        entries.append((floor_of[hall], ident, token, cfg, [r['spot']['x'], r['spot']['z']], r['spot']['facing']))
    for ident, hall, token, cfg, at, facing in FIXED:
        entries.append((floor_of[hall], ident, token, cfg, at, facing))
    removed = 0
    for hall, ident in REMOVES:
        f = data['floors'][floor_of[hall]]
        n = len(f['artifacts']); f['artifacts'] = [a for a in f['artifacts'] if a.get('id') != ident]; removed += n - len(f['artifacts'])
    added = 0
    for fi, ident, token, cfg, at, facing in entries:
        f = data['floors'][fi]
        if any(a.get('id') == ident for a in f['artifacts']):
            continue
        x, z = at
        f['artifacts'].append({'id': ident, 'artifact': token, 'station': ('N' if z < 0 else 'S') + ('W' if x < 0 else 'E'),
                               'position': [x, z], 'height': 0, 'scale': 1, 'facing': facing, 'config': cfg})
        added += 1
    moved = 0
    for hall, token, old, new, facing in MOVES:
        f = data['floors'][floor_of[hall]]
        # within 20 cm: the editor saves positions it has nudged (eleven_dots stood at -18.0279, -4.4167)
        hits = [a for a in f['artifacts'] if a.get('artifact') == token and abs(a['position'][0] - old[0]) < .2 and abs(a['position'][1] - old[1]) < .2]
        if len(hits) != 1:
            print('move skipped (%d matches): %s %s at %s' % (len(hits), hall, token, old)); continue
        hits[0]['position'] = new
        if facing is not None:
            hits[0]['facing'] = facing
        moved += 1
    text = json.dumps(data, indent=2, ensure_ascii=False) + '\n'
    tmp = ROOMS.with_suffix('.json.tmp')
    tmp.write_text(text, encoding='utf8', newline='\n')
    os.replace(tmp, ROOMS)
    print('appended %d works, moved %d, removed %d, in commons/void/rooms.json' % (added, moved, removed))


if __name__ == '__main__':
    main()
