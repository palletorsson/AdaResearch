"""Verify pickup detector eligibility using actual scene physics in hidden Godot."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--label', default='after')
    args = parser.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9_-]+', args.label):
        parser.error('label must be a simple filename stem')
    folder = ROOT / 'ada_run/encounter_pilot/Pickup_detection'
    folder.mkdir(parents=True, exist_ok=True)
    paths = ['commons/scenes/mapobjects/pick_up_cube.gd',
             'commons/scenes/mapobjects/pick_up_cube.tscn',
             'commons/scenes/endless_museum.gd',
             'tools/probes/pickup_encounter.gd']
    (folder / f'{args.label}_sources.json').write_text(json.dumps({
        'source_sha256': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths}
    }, indent=2), encoding='utf-8')
    engine = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
    output = folder / f'{args.label}.json'
    command = [engine, '--path', str(ROOT), '--headless', '--xr-mode', 'off',
               '--log-file', str(folder / f'{args.label}_engine.log'),
               '--script', 'res://tools/probes/pickup_encounter.gd', '--', str(output)]
    with (folder / f'{args.label}_stdout.log').open('w', encoding='utf-8') as log:
        process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                                   creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
        try:
            result = process.wait(timeout=60)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            result = 124
    print(f'Pickup eligibility: exit={result}; report={output}')
    print('\n'.join((folder / f'{args.label}_stdout.log').read_text(encoding='utf-8', errors='replace').splitlines()[-10:]))
    return result


if __name__ == '__main__':
    raise SystemExit(main())
