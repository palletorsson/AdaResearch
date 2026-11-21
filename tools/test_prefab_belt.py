"""The prefab belt on the Point_Animatedcube floor in the actual tower, 2026-11-21: built, standing on the slab,
cutting into nothing, stepped, photographed. Probe: tools/probes/prefab_belt_floor.gd.
Output: ada_run/prefab_belt/tower/checks.json (+ floor07_belt_*.png). `--beside-play`: no native slot, window off-screen."""
from pathlib import Path
from void_floors import floor_of
import json, os, subprocess, sys
from void_trial_runtime import stage_runtime
from void_native_slot import acquire_native_slot

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/prefab_belt/tower'


def main():
    sys.stdout.reconfigure(encoding='utf8')
    OUT.mkdir(parents=True, exist_ok=True)
    for stale in ('checks.json', 'progress.json', 'godot.log'):
        (OUT / stale).unlink(missing_ok=True)   # a crash must not read the last run's report
    beside = '--beside-play' in sys.argv   # Palle (2026-11-06): independent runs need not wait for the slot
    slot = None if beside else acquire_native_slot('Prefab belt floor %d (Point_Animatedcube)' % floor_of('Point_Animatedcube'), timeout=7200)
    stage = stage_runtime()
    with (OUT / 'engine.log').open('w', encoding='utf8') as stream:
        result = subprocess.run([sys.executable, str(ROOT / 'tools/godot_watchdog.py'), '--expect=' + str(OUT), '--grace=300', '--stall=120', '--',
            os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
            '--log-file', str(OUT / 'godot.log'), '--path', str(stage), '--xr-mode', 'off',
            '--resolution', '1600x1000', *(['--position', '3200,3200'] if beside else []),
            '--script', 'res://tools/probes/prefab_belt_floor.gd', '--', '--out=' + OUT.as_posix(), *[a for a in sys.argv if a.startswith('--floors=')],
        ], stdout=stream, stderr=subprocess.STDOUT, timeout=1800, creationflags=subprocess.CREATE_NO_WINDOW)
    if slot: slot.close()
    text = (OUT / 'engine.log').read_text(encoding='utf8', errors='replace')
    log = OUT / 'godot.log'
    if log.exists():
        text += log.read_text(encoding='utf8', errors='replace')
    report = OUT / 'checks.json'
    if result.returncode not in (0, 1) or not report.exists() or 'SCRIPT ERROR' in text or 'Parse Error' in text:
        print('did not report (exit %d); log tail:' % result.returncode)
        print(text[-4000:])
        sys.exit(1)
    for line in text.splitlines():
        if line.startswith(('[void]', '[prefab')):
            print(line)
    checks = json.loads(report.read_text(encoding='utf8'))
    print('%d/%d' % (sum(1 for c in checks['checks'] if c['passed']), len(checks['checks'])))
    sys.exit(0 if checks['passed'] else 1)


if __name__ == '__main__':
    main()
