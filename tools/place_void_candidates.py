"""Stand the spine worklist's unplaced artifacts on their halls' Void floors as CANDIDATES, for Palle to keep or remove
in the Void editor (localhost:3003/editor/void) - Palle, 2026-11-03: "add the rest of the artifacts so I can see them
in three editor and decide what will stay".

The plan is the worklist rows (doc/plans/spine-placement/worklist.json) of one sequence that stand nowhere and whose
hall has a Void floor (commons/void/rooms.json `map`). The probe tools/probes/void_candidates.gd measures each one in
the actual tower and finds it a clear spot on its floor; --apply then appends one entry per placed artifact to that
floor in rooms.json (id candidate-<token>, editor_label "candidate ..."), touching nothing else: the file is read,
appended to and written back in its own format (json indent 2, ensure_ascii off), which round-trips it byte for byte.

  python tools/place_void_candidates.py [--seq=primitives] [--apply] [--skip=token,token]
"""
from pathlib import Path
import json, os, subprocess, sys
from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/void-candidates'
ROOMS = ROOT / 'commons/void/rooms.json'


def arg(name, default):
    return next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--' + name + '=')), default)


def main():
    sys.stdout.reconfigure(encoding='utf8')
    seq = arg('seq', 'primitives')
    skip = set(filter(None, arg('skip', '').split(',')))
    work = json.loads((ROOT / 'doc/plans/spine-placement/worklist.json').read_text(encoding='utf8'))
    rooms = json.loads(ROOMS.read_text(encoding='utf8'))
    floor_of = {}
    for i, f in enumerate(rooms['floors']):
        floor_of.setdefault(f.get('map'), i)
    placed_already = {a.get('artifact') for f in rooms['floors'] for a in f.get('artifacts', [])}
    plan = []
    for r in work['items']:
        if r['sequence'] != seq or r['kind'] != 'artifact' or r['status'] != 'stands nowhere' or r['token'] in skip:
            continue
        if r['hall'] not in floor_of:
            print('no Void floor for', r['token'], '->', r['hall'])
            continue
        if r['token'] in placed_already:
            continue
        plan.append({'floor': floor_of[r['hall']], 'hall': r['hall'], 'token': r['token'], 'role': r['role']})
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'plan.json').write_text(json.dumps(plan, indent=1), encoding='utf8')
    print(len(plan), 'candidates on floors', sorted({p['floor'] for p in plan}))
    for stale in ('placements.json', 'checks.json', 'godot.log'):
        (OUT / stale).unlink(missing_ok=True)
    stage = stage_runtime()
    with (OUT / 'engine.log').open('w', encoding='utf8') as stream:
        # the 16-second rule, with room for a measuring settle per artifact
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
    results = json.loads(report.read_text(encoding='utf8'))
    hall = {p['token']: p['hall'] for p in plan}
    for r in results:
        s = r['spot']
        print('%-26s floor %2d  %s' % (r['token'], r['floor'], ('(%.1f, %.1f) facing %d, %.1f m from the route' % (s['x'], s['z'], s['facing'], s['to_route'])) if s else 'NO SPOT (%.1f x %.1f m)' % tuple(r['footprint'][:2])))
    if '--apply' not in sys.argv:
        return
    raw = ROOMS.read_text(encoding='utf8')
    data = json.loads(raw)
    if json.dumps(data, indent=2, ensure_ascii=False) + '\n' != raw:
        sys.exit('rooms.json does not round-trip in its own format any more; not writing')
    added = 0
    for r in results:
        if not r['spot']:
            continue
        f = data['floors'][r['floor']]
        ident = 'candidate-' + r['token']
        if any(a.get('id') == ident for a in f['artifacts']):
            continue
        x, z = r['spot']['x'], r['spot']['z']
        f['artifacts'].append({
            'id': ident, 'artifact': r['token'],
            'station': ('N' if z < 0 else 'S') + ('W' if x < 0 else 'E'),
            'position': [x, z], 'height': 0, 'scale': 1, 'facing': r['spot']['facing'],
            'config': {'editor_label': 'candidate / %s - spine worklist 2026-11-03: keep or remove' % hall[r['token']]},
        })
        added += 1
    text = json.dumps(data, indent=2, ensure_ascii=False) + '\n'
    tmp = ROOMS.with_suffix('.json.tmp')
    tmp.write_text(text, encoding='utf8', newline='\n')
    os.replace(tmp, ROOMS)
    print('appended', added, 'candidates to commons/void/rooms.json')


if __name__ == '__main__':
    main()
