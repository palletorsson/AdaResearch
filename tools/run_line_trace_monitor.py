"""Render the new monitor in a private copy of the real Point_Trace hall.
The copied museum changes output paths only. No map or artifact source is edited.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'ada_run/line_trace_monitor'
OUT = ROOT / 'doc/book/iterations/2026-10-04-line-trace-monitor'
RUN.mkdir(parents=True, exist_ok=True)
OUT.mkdir(parents=True, exist_ok=True)
prefix = 'res://' + RUN.relative_to(ROOT).as_posix() + '/'
source_path = ROOT / 'commons/scenes/endless_museum.gd'
source = source_path.read_text(encoding='utf-8')
# Preserve every input copied from the active project; redirect the known outputs.
names = ['em_inventory.json', 'em_showing_cards.json', 'em_live_footprints.json',
         'em_bake.json', 'em_layout_walk.json', 'em_adoptions.json', 'em_built.json',
         'em_foes.json', 'em_boot_last.json', 'em_pack_report.json', 'em_basin_plan.txt']
for name in names:
    original = ROOT / 'ada_run' / name
    if original.exists(): shutil.copy2(original, RUN / name)
    source = source.replace('res://ada_run/' + name, prefix + name)
(RUN / 'museum_snapshot.gd').write_text(source, encoding='utf-8')
scene = (ROOT / 'commons/scenes/endless_museum.tscn').read_text(encoding='utf-8')
scene = re.sub(r' uid="[^"]+"', '', scene)
scene = scene.replace('res://commons/scenes/endless_museum.gd', prefix + 'museum_snapshot.gd')
(RUN / 'museum_snapshot.tscn').write_text(scene, encoding='utf-8')
control = json.loads((ROOT / 'ada_run/em_control.json').read_text(encoding='utf-8-sig'))
control.update(first_chapter='primitives', first_map='Point_Trace', dollhouse=0)
for key in ['resume_eye', 'resume_hall', 'resume_yaw', 'resume_pitch']: control.pop(key, None)
(RUN / 'control.json').write_text(json.dumps(control), encoding='utf-8')
for name in ['necklace_hand.json', 'em_overrides.json']:
    path = ROOT / 'ada_run' / name
    if path.exists(): shutil.copy2(path, RUN / name)
    else: (RUN / name).write_text('{}', encoding='utf-8')
shutil.copy2(ROOT / 'commons/data/museum/em_plan.json', RUN / 'plan.json')
(RUN / 'spec.json').write_text(json.dumps({'run': prefix}), encoding='utf-8')
protected = ['commons/maps/Point_Trace/map_data.json', 'commons/maps/Point_Lines/map_data.json',
             'commons/primitives/point/draw_dot.gd', 'commons/globals/trace_data.gd',
             'commons/primitives/line/grid_lines.gd', 'commons/scenes/endless_museum.gd']
before = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in protected}
engine = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
command = [engine, '--path', str(ROOT), '--xr-mode', 'off', '--no-window',
           '--rendering-method', 'gl_compatibility', '--log-file', str(RUN / 'engine.log'),
           '--script', 'res://tools/probes/line_trace_monitor.gd', '--', prefix + 'spec.json']
with (RUN / 'stdout.log').open('w', encoding='utf-8') as log:
    result = subprocess.run(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                            timeout=180, creationflags=subprocess.CREATE_NO_WINDOW)
after = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in protected}
(OUT / 'protected-sources.json').write_text(json.dumps({'before': before, 'after': after,
    'unchanged': before == after}, indent=2), encoding='utf-8')
print('Godot exit:', result.returncode, 'Existing code/maps unchanged:', before == after)
print('\n'.join((RUN / 'stdout.log').read_text(encoding='utf-8', errors='replace').splitlines()[-20:]))
raise SystemExit(result.returncode if before == after else 1)
