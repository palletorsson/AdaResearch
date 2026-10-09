"""Capture the untouched student's comparison in an isolated real museum run."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-08-fractals-ghost-student'

def main(composition, revision=False):
    run = O / ('museum-revision' if revision else 'museum')
    run.mkdir(exist_ok=True)
    prefix = 'res://' + run.relative_to(R).as_posix() + '/'
    source = (R / 'commons/scenes/endless_museum.gd').read_text(encoding='utf-8')
    for name in ['em_inventory.json', 'em_showing_cards.json', 'em_live_footprints.json', 'em_bake.json', 'em_layout_walk.json', 'em_adoptions.json', 'em_built.json', 'em_foes.json', 'em_boot_last.json', 'em_pack_report.json', 'em_basin_plan.txt']:
        original = R / 'ada_run' / name
        if original.exists():
            shutil.copy2(original, run / name)
        source = source.replace('res://ada_run/' + name, prefix + name)
    (run / 'museum_snapshot.gd').write_text(source, encoding='utf-8')
    scene = (R / 'commons/scenes/endless_museum.tscn').read_text(encoding='utf-8')
    scene = re.sub(r' uid="[^"]+"', '', scene).replace('res://commons/scenes/endless_museum.gd', prefix + 'museum_snapshot.gd')
    (run / 'museum_snapshot.tscn').write_text(scene, encoding='utf-8')
    control = json.loads((R / 'ada_run/em_control.json').read_text(encoding='utf-8-sig'))
    control.update(first_chapter='fractals', first_map='Fractal_Synthesis', dollhouse=0)
    for key in ['resume_eye', 'resume_hall', 'resume_yaw', 'resume_pitch']:
        control.pop(key, None)
    (run / 'control.json').write_text(json.dumps(control), encoding='utf-8')
    for name in ['necklace_hand.json', 'em_overrides.json']:
        if (R / 'ada_run' / name).exists():
            shutil.copy2(R / 'ada_run' / name, run / name)
        else:
            (run / name).write_text('{}', encoding='utf-8')
    shutil.copy2(R / 'commons/data/museum/em_plan.json', run / 'plan.json')
    attempt_prefix = 'res://' + (O / 'attempt').relative_to(R).as_posix() + '/'
    spec = {'run': prefix, 'room': 'Fractal_Synthesis', 'sequence': 'fractals', 'original': attempt_prefix + 'reconstructed/Fractal_RecursiveTrees/tree.gd', 'composition': attempt_prefix + composition}
    (run / 'spec.json').write_text(json.dumps(spec, indent=2), encoding='utf-8')
    hashes = json.loads((O / 'submission-before-run.json').read_text(encoding='utf-8'))
    with (run / 'stdout.log').open('w', encoding='utf-8') as out:
        probe = 'res://tools/probes/fractals_ghost_revision_museum.gd' if revision else 'res://tools/probes/fractals_ghost_museum.gd'
        result = subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(R), '--xr-mode', 'off', '--no-window', '--rendering-method', 'gl_compatibility', '--resolution', '1440x1000', '--audio-driver', 'Dummy', '--log-file', str(run / 'engine.log'), '--script', probe, '--', prefix + 'spec.json'], cwd=R, stdout=out, stderr=subprocess.STDOUT, timeout=150, creationflags=subprocess.CREATE_NO_WINDOW)
    errors = [line for line in (run / 'engine.log').read_text(encoding='utf-8', errors='replace').splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line]
    unchanged = all(hashlib.sha256((O / 'attempt' / name).read_bytes()).hexdigest() == digest for name, digest in hashes.items())
    assert result.returncode == 0 and not errors and unchanged, (result.returncode, errors, unchanged)
    data = json.loads((run / 'report.json').read_text(encoding='utf-8'))
    assert data['passed'], data['failures']
    images = ['witness', 'overview'] if revision else ['front', 'oblique', 'side']
    assert all((run / (name + '.png')).is_file() for name in images)
    print(json.dumps({'checks': len(data['checks']), 'failures': data['failures'], 'submission_unchanged': unchanged}))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('composition', help='Entry script relative to attempt/')
    parser.add_argument('--revision', action='store_true')
    args = parser.parse_args()
    main(args.composition, args.revision)
