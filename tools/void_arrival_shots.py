#!/usr/bin/env python3
"""THE ARRIVAL RULE (Palle, 2026-11-11: "can you imagine walking the floor and improving them for the player? any
universal idea that easily could fix the progression and the curation of space?").

176 of the tower's 199 declared spawn points are the same spot - (0, 7.8), the south middle of the slab, looking north.
A floor is met from there, so it is curated from there: from the arrival point the player must see where to go first
(the floor's first work in timeline order, or the way to it), the floor's biggest thing, and nothing standing in the
face. This takes that picture: one frame per floor from the spawn point at eye height (1.6 m) looking at the middle
of the floor, and one turned 40 degrees to each side.

    python tools/void_arrival_shots.py <outdir> <floor,floor,...>      e.g. ada_run/arrival 85,87,90

view_1.png straight ahead, view_2.png left, view_3.png right, in <outdir>/f<floor>/. Several floors run at once, each
on its own staged runtime under the watchdog. It uses tools/probes/void_work_shots.gd --view.
Found by it on the day it was written: a room moved ONTO the spawn point (floor 87), a walk-up 1.3 m in front of the
face (floor 90), the floor's first works hidden behind its later ones (floor 85) - all three arranged from above.
"""
import json, math, os, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from void_trial_runtime import stage_runtime
L = json.loads((ROOT / 'commons/void/layout.json').read_text(encoding='utf-8'))
GODOT = os.environ.get('GODOT', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
out = ROOT / sys.argv[1]
procs = []
for f in sys.argv[2].split(','):
    x, _y, z = L['spawn_points'].get(f, [0, 0.06, 7.8])
    views = []
    for turn in (0, -40, 40):
        dx, dz = -x, -z                     # toward the floor's middle
        n = math.hypot(dx, dz) or 1.0
        a = math.radians(turn)
        rx, rz = (dx * math.cos(a) - dz * math.sin(a)) / n, (dx * math.sin(a) + dz * math.cos(a)) / n
        views.append('%.2f,1.6,%.2f:%.2f,1.2,%.2f' % (x, z, x + rx * 8, z + rz * 8))
    d = out / ('f' + f); d.mkdir(parents=True, exist_ok=True)
    stage = stage_runtime()
    procs.append(subprocess.Popen([sys.executable, str(ROOT / 'tools/godot_watchdog.py'), '--expect=' + str(d), '--grace=360', '--stall=300', '--',
        GODOT, '--log-file', str(d / 'godot.log'), '--path', str(stage), '--xr-mode', 'off',
        '--resolution', '1280x800', '--position', '3200,3200', '--script', 'res://tools/probes/void_work_shots.gd', '--', '--no-bridges',
        '--void-start-floor=' + f, '--out=' + d.as_posix(), '--works=none', '--settle=300', '--view=' + ';'.join(views)],
        cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=subprocess.CREATE_NO_WINDOW))
for p in procs: p.wait()
print('done', sorted(str(p.relative_to(out)) for p in out.glob('f*/view_1.png')))
