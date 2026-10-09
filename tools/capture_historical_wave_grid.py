"""Extract immutable old layouts and photograph them without touching live maps."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-08-wave-original-grid'
REV = '8d49b4d37'
GODOT = Path('C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
MAPS = ['WaveFunctions_Sine_Space', 'WaveFunctions_3D_Wave_Propagation']

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)

def main():
    rev = git('rev-parse', REV).decode().strip()
    manifest = {'commit': rev, 'commit_date': git('show', '-s', '--format=%aI', REV).decode().strip(), 'scope': 'Historical map JSON with current GridSystem and artifact implementations. JSON lighting; plain background using its authored colour; no biome ring or player.', 'maps': []}
    for name in sys.argv[1:] or MAPS:
        path = f'commons/maps/{name}/map_data.json'
        live_hash = hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
        dest = OUT / name
        dest.mkdir(parents=True, exist_ok=True)
        raw = git('show', rev + ':' + path)
        (dest / 'map_data.json').write_bytes(raw)
        args = [str(GODOT), '--path', str(ROOT), '--no-window', '--rendering-method', 'gl_compatibility', '--xr-mode', 'off', '--audio-driver', 'Dummy', '--script', 'res://tools/probes/historical_wave_grid.gd', '--', '--json=' + (dest / 'map_data.json').as_posix(), '--out=' + dest.as_posix()]
        with (dest / 'engine.log').open('w', encoding='utf8') as log:
            run = subprocess.run(args, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=180)
        assert run.returncode == 0, (name, run.returncode)
        report = json.loads((dest / 'render.json').read_text(encoding='utf8'))
        assert report['verified'] and report['json_sha256'] == hashlib.sha256(raw).hexdigest()
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == live_hash, 'Live map changed during capture'
        manifest['maps'].append({'map': name, 'source': path, 'sha256': report['json_sha256'], 'live_map_unchanged': True, 'artifacts': len(report['artifacts']), 'structure_cubes': report['structure_cubes']})
        print(name, 'captured', len(report['shots']), 'views', flush=True)
    (OUT / 'provenance.json').write_text(json.dumps(manifest, indent=2), encoding='utf8')

if __name__ == '__main__':
    main()
