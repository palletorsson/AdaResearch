"""The pendulum and the plank on a ball on floor 14 (Trans_Introduction; moved from floor 21 on 2026-11-09, below the
skateboard on 15) in the actual tower, desktop walker. Probe: tools/probes/physics_play_floor14.gd.
Output: ada_run/physics-play-floor14/checks.json (+ photographs). Runs beside other Godot jobs (2026-11-06 rule)."""
from pathlib import Path
import json, os, subprocess, sys
from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/physics-play-floor14'


def main():
    sys.stdout.reconfigure(encoding='utf8')
    destination = OUT
    destination.mkdir(parents=True, exist_ok=True)
    for stale in ('checks.json', 'godot.log'):
        (destination / stale).unlink(missing_ok=True)   # a crash must not read the last run's report
    stage = stage_runtime()
    with (destination / 'engine.log').open('w', encoding='utf8') as stream:
        # the 16-second rule: the watchdog kills a run that stops writing (the tower boots in ~60 s)
        result = subprocess.run([sys.executable, str(ROOT / 'tools/godot_watchdog.py'), '--expect=' + str(destination), '--grace=240', '--stall=120', '--',
            os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
            '--log-file', str(destination / 'godot.log'), '--path', str(stage), '--xr-mode', 'off',
            '--resolution', '1600x1000', '--script', 'res://tools/probes/physics_play_floor14.gd', '--', '--out=' + destination.as_posix()
        ], stdout=stream, stderr=subprocess.STDOUT, timeout=900, creationflags=subprocess.CREATE_NO_WINDOW)
    text = (destination / 'engine.log').read_text(encoding='utf8', errors='replace')
    log = destination / 'godot.log'
    if log.exists():
        text += log.read_text(encoding='utf8', errors='replace')
    report = destination / 'checks.json'
    if result.returncode not in (0, 1) or not report.exists() or 'SCRIPT ERROR' in text or 'Parse Error' in text:
        print('did not report (exit %d); log tail:' % result.returncode)
        print(text[-4000:])
        sys.exit(1)
    for line in text.splitlines():
        if line.startswith(('[void]',)):
            print(line)
    checks = json.loads(report.read_text(encoding='utf8'))
    print('%d/%d' % (sum(1 for c in checks['checks'] if c['passed']), len(checks['checks'])))
    sys.exit(0 if checks['passed'] else 1)


if __name__ == '__main__':
    main()
