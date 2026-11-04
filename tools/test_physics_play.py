"""The physics play bench: the seven Jolt set-ups (commons/artifacts/physics_play) side by side, released and reset.
Runs commons/testing/probe_physics_play.tscn under the watchdog; photographs in ada_run/physics_play/.
  python tools/test_physics_play.py
"""
from pathlib import Path
import json, os, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/physics_play'


def main():
    sys.stdout.reconfigure(encoding='utf8')
    OUT.mkdir(parents=True, exist_ok=True)
    for stale in ('checks.json', 'godot.log'):
        (OUT / stale).unlink(missing_ok=True)
    subprocess.run([sys.executable, str(ROOT / 'tools/godot_watchdog.py'), '--expect=' + str(OUT), '--grace=200', '--stall=90', '--',
                    os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'), '--path', str(ROOT), '--xr-mode', 'off',
                    '--resolution', '960x640', '--log-file', str(OUT / 'godot.log'), 'res://commons/testing/probe_physics_play.tscn', '--', '--out=' + OUT.as_posix()],
                   cwd=ROOT, capture_output=True, text=True, encoding='utf8', errors='replace')
    report = OUT / 'checks.json'
    log = (OUT / 'godot.log').read_text(encoding='utf8', errors='replace') if (OUT / 'godot.log').exists() else ''
    if not report.exists():
        print(log[-4000:])
        sys.exit('the bench did not report')
    checks = json.loads(report.read_text(encoding='utf8'))
    for c in checks['checks']:
        print('PASS' if c['passed'] else 'FAIL', c['name'])
    for line in log.splitlines():
        if 'SCRIPT ERROR' in line:
            print(line)
    sys.exit(0 if checks['passed'] else 1)


if __name__ == '__main__':
    main()
