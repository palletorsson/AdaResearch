"""Inspect a live museum hall without replacing the running museum's output files.

Usage: python tools/run_encounter_probe.py Array --render --spec path.json
The Godot probe reads optional rays, walks and shots in map-space metres.
This is a runtime inspection, not a learner or headset acceptance test.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('room')
    parser.add_argument('--sequence', default='array_tutorial')
    parser.add_argument('--render', action='store_true')
    parser.add_argument('--spec', type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9_]+', args.room):
        parser.error('room must be a map folder name')
    run = ROOT / 'ada_run/encounter_pilot' / args.room
    run.mkdir(parents=True, exist_ok=True)
    # A failed launch must not leave a previous passing report as its result.
    if (run / 'report.json').exists():
        shutil.copy2(run / 'report.json', run / 'previous-report.json')
        (run / 'report.json').unlink()
    prefix = 'res://' + run.relative_to(ROOT).as_posix() + '/'
    source_path = ROOT / 'commons/scenes/endless_museum.gd'
    source = source_path.read_text(encoding='utf-8')
    replacements = {}
    for name in ['em_inventory.json', 'em_showing_cards.json', 'em_live_footprints.json',
                 'em_bake.json', 'em_layout_walk.json', 'em_adoptions.json', 'em_built.json',
                 'em_foes.json', 'em_boot_last.json', 'em_pack_report.json', 'em_basin_plan.txt']:
        old = 'res://ada_run/' + name
        if old not in source:
            continue
        replacements[old] = prefix + name
        original = ROOT / 'ada_run' / name
        target = run / name
        if original.exists():
            shutil.copy2(original, target)
        elif target.exists():
            target.unlink()
        source = source.replace(old, prefix + name)
    (run / 'museum_snapshot.gd').write_text(source, encoding='utf-8')
    scene = (ROOT / 'commons/scenes/endless_museum.tscn').read_text(encoding='utf-8')
    scene = re.sub(r' uid="[^"]+"', '', scene)
    scene = scene.replace('res://commons/scenes/endless_museum.gd', prefix + 'museum_snapshot.gd')
    (run / 'museum_snapshot.tscn').write_text(scene, encoding='utf-8')
    control = json.loads((ROOT / 'ada_run/em_control.json').read_text(encoding='utf-8-sig'))
    control.update(first_chapter=args.sequence, first_map=args.room, dollhouse=0)
    for key in ['resume_eye', 'resume_hall', 'resume_yaw', 'resume_pitch']:
        control.pop(key, None)
    (run / 'control.json').write_text(json.dumps(control), encoding='utf-8')
    for name in ['necklace_hand.json', 'em_overrides.json']:
        original = ROOT / 'ada_run' / name
        if original.exists():
            shutil.copy2(original, run / name)
        else:
            (run / name).write_text('{}', encoding='utf-8')
    shutil.copy2(ROOT / 'ada_run/em_plan.json', run / 'plan.json')
    spec = json.loads(args.spec.read_text(encoding='utf-8-sig')) if args.spec else {}
    spec.update(room=args.room, sequence=args.sequence, run=prefix)
    (run / 'spec.json').write_text(json.dumps(spec, indent=2), encoding='utf-8')
    manifest = {'room': args.room, 'replacements': replacements,
                'scope': 'Live museum code; only output paths replaced. Headset and learner checks remain open.',
                'sources': {}}
    for path in [source_path, ROOT / f'commons/maps/{args.room}/map_data.json',
                 ROOT / 'tools/probes/museum_encounter.gd', ROOT / 'tools/run_encounter_probe.py',
                 ROOT / 'ada_run/em_plan.json', run / 'control.json', run / 'necklace_hand.json',
                 run / 'em_overrides.json', run / 'em_bake.json']:
        if not path.exists():
            continue
        manifest['sources'][path.relative_to(ROOT).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    evidence = ROOT / f'doc/book/iterations/2026-09-08-focused-book/evidence/{args.sequence}.json'
    if evidence.exists():
        for room in json.loads(evidence.read_text(encoding='utf-8-sig')).get('rooms', []):
            if room.get('room_id') == args.room:
                for relative in room.get('source_files', []):
                    path = ROOT / relative
                    if path.is_file():
                        manifest['sources'][relative] = hashlib.sha256(path.read_bytes()).hexdigest()
    (run / 'source_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    engine = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
    command = [engine, '--path', str(ROOT), '--xr-mode', 'off', '--log-file', str(run / 'engine.log'),
               '--script', 'res://tools/probes/museum_encounter.gd']
    command += ['--no-window', '--rendering-method', 'gl_compatibility'] if args.render else ['--headless']
    command += ['--', prefix + 'spec.json']
    with (run / 'stdout.log').open('w', encoding='utf-8') as log:
        process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                                   creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
        try:
            result = process.wait(timeout=150)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            result = 124
    print(f'{args.room}: exit={result}; report={run / "report.json"}')
    print('\n'.join((run / 'stdout.log').read_text(encoding='utf-8', errors='replace').splitlines()[-12:]))
    return result


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    raise SystemExit(main())
