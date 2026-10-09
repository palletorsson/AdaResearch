"""Run an existing Ribbon probe with isolated outputs and visible provenance."""
from pathlib import Path
import datetime
import hashlib
import json
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[6]
HERE = Path(__file__).resolve().parent
GODOT = Path('C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fingerprints():
    before = json.loads((HERE.parent / 'before-manifest.json').read_text(encoding='utf-8'))
    paths = list(before['files']) + [
        'commons/scenes/endless_museum.gd',
        'commons/scenes/endless_museum.tscn',
        'commons/scenes/em/em_detail.gd',
        'commons/player/costume_wardrobe.gd',
        'commons/artifacts/fabric_shader_studio/fabric_recipe.gd',
        'commons/artifacts/fabric_shader_studio/fabric.gdshader',
        'commons/artifacts/drag_catwalk/runway_agent.gd',
    ]
    return {rel: digest(ROOT / rel) for rel in paths}


def main():
    name = sys.argv[1]
    assert name in ('layer_pattern', 'carrier_comparison', 'fabric_studio', 'drag_catwalk')
    script = HERE / f'probe_{name}.gd'
    headless = name == 'drag_catwalk'
    command = [str(GODOT), '--path', str(ROOT), '--xr-mode', 'off',
               '--audio-driver', 'Dummy', '--rendering-driver', 'vulkan',
               '--rendering-method', 'mobile', '--resolution', '1600x1000',
               '--log-file', str(HERE / f'{name}.godot.log'),
               '--script', str(script)]
    if headless:
        command += ['--headless']
    before = fingerprints()
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    t0 = time.monotonic()
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = subprocess.SW_HIDE
    timed_out = False
    with (HERE / f'{name}.process.log').open('w', encoding='utf-8') as output:
        process = subprocess.Popen(command, cwd=ROOT, stdout=output,
                                   stderr=subprocess.STDOUT,
                                   startupinfo=startup,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            code = process.wait(timeout=180)
        except subprocess.TimeoutExpired:
            timed_out = True
            process.kill()
            code = process.wait()
    after = fingerprints()
    report = {
        'probe': name, 'started_utc': started, 'duration_seconds': time.monotonic() - t0,
        'command': command, 'exit_code': code, 'timed_out': timed_out,
        'probe_sha256': digest(script), 'sources_before': before,
        'sources_after': after,
        'sources_changed_during_run': [rel for rel in before if before[rel] != after[rel]],
        'headset_tested': False,
        'capture_kind': 'unchanged-source comparison states' if not headless else 'no captures',
    }
    (HERE / f'{name}.run.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in report.items() if not k.startswith('sources_')}, indent=2))
    print('Sources changed:', report['sources_changed_during_run'])
    sys.exit(0 if code == 0 else 1)


if __name__ == '__main__':
    main()
