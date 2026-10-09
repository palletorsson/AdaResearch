"""Load the current actual museum with private output paths and inspect one hall.

Usage: python ada_run/melencolia_restore/run_museum_probe.py [--render] [--config=path]
Optional config: {rays:[{tag,x,z,top,tolerance}], walks:[{tag,from:[x,y,z],to:[x,y,z],seconds}],
shots:[{tag,from:[x,y,z],look_at:[x,y,z],fov}]}. All positions are map-space metres,
with floor zero matching the first hall's map origin, NOT old-grid cube centres.
The source snapshot changes string paths only; all geometry/runtime logic is the live source.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8')

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
RUN = HERE / 'probe_runtime'
RUN.mkdir(parents=True, exist_ok=True)
prefix = 'res://' + RUN.relative_to(ROOT).as_posix() + '/'
source_path = ROOT / 'commons/scenes/endless_museum.gd'
source = source_path.read_text(encoding='utf-8')
# Redirect all outputs used by normal museum boot, retaining a snapshot of their
# prior contents and mtime so cache/ledger reads have the same initial values.
names = ['em_inventory.json', 'em_showing_cards.json', 'em_live_footprints.json', 'em_bake.json',
         'em_layout_walk.json', 'em_adoptions.json', 'em_built.json',
         'em_foes.json', 'em_boot_last.json', 'em_pack_report.json',
         'em_basin_plan.txt']
replacements = {}
for name in names:
    old = 'res://ada_run/' + name
    new = prefix + name
    if old in source:
        replacements[old] = new
        original = ROOT / 'ada_run' / name
        target = RUN / name
        if original.exists():
            shutil.copy2(original, target)
        elif target.exists():
            target.unlink()
        source = source.replace(old, new)
(RUN / 'endless_museum_snapshot.gd').write_text(source, encoding='utf-8')
scene = (ROOT / 'commons/scenes/endless_museum.tscn').read_text(encoding='utf-8')
scene = re.sub(r' uid="[^"]+"', '', scene)
scene = scene.replace('res://commons/scenes/endless_museum.gd', prefix + 'endless_museum_snapshot.gd')
(RUN / 'museum_snapshot.tscn').write_text(scene, encoding='utf-8')
control = json.loads((ROOT / 'ada_run/em_control.json').read_text(encoding='utf-8-sig'))
control.update({'first_chapter':'primitives','first_map':'Primitives_Melencolia', 'dollhouse':0})
for key in ['resume_eye', 'resume_hall', 'resume_yaw', 'resume_pitch']:
    control.pop(key, None)
(RUN / 'control.json').write_text(json.dumps(control), encoding='utf-8')
for name in ['necklace_hand.json', 'em_overrides.json']:
    original = ROOT / 'ada_run' / name
    if original.exists():
        shutil.copy2(original, RUN / name)
    else:
        (RUN / name).write_text('{}', encoding='utf-8')
config = next((a.split('=',1)[1] for a in sys.argv if a.startswith('--config=')), '')
if config:
    spec = json.loads(Path(config).read_text(encoding='utf-8-sig'))
else:
    spec = {'rays':[], 'walks':[], 'shots':[]}
(RUN / 'spec.json').write_text(json.dumps(spec, indent=2), encoding='utf-8')
(RUN / 'source_manifest.json').write_text(json.dumps({
    'source':str(source_path),'source_sha256':hashlib.sha256(source_path.read_bytes()).hexdigest(),
    'map_sha256':hashlib.sha256((ROOT/'commons/maps/Primitives_Melencolia/map_data.json').read_bytes()).hexdigest(),
    'changes':'Only literal output path substitutions; scene UID removed to avoid aliasing live scene.',
    'replacements':replacements}, indent=2), encoding='utf-8')
engine = os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
args = [engine,'--path',str(ROOT),'--xr-mode','off','--log-file',str(RUN/'engine.log'),
        '--script','res://ada_run/melencolia_restore/probe_museum.gd']
args += ['--no-window','--rendering-method','gl_compatibility'] if '--render' in sys.argv else ['--headless']
with (RUN/'stdout.log').open('w',encoding='utf-8') as log:
    process = subprocess.Popen(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    try:
        rc = process.wait(timeout=150)
    except subprocess.TimeoutExpired:
        process.kill(); process.wait(); rc=124
print(f'Museum probe exit={rc}; report={RUN / "report.json"}')
print('\n'.join((RUN/'stdout.log').read_text(encoding='utf-8',errors='replace').splitlines()[-18:]))
raise SystemExit(rc)
