"""Capture before/after + interactive world-tinting screenshots of Floor 31 (Color_Rainbow)."""
from pathlib import Path
import json, os, subprocess, sys
from void_trial_runtime import stage_runtime
from void_native_slot import acquire_native_slot

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/color-rainbow-playground'


def main():
    sys.stdout.reconfigure(encoding='utf8')
    tag = 'before'
    expect_new = False
    for a in sys.argv[1:]:
        if a.startswith('--tag='):
            tag = a.split('=', 1)[1]
        elif a == '--expect-new':
            expect_new = True
    destination = OUT / tag
    destination.mkdir(parents=True, exist_ok=True)
    for stale in ('checks.json', 'progress.json', 'godot.log'):
        (destination / stale).unlink(missing_ok=True)
    beside = '--beside-play' in sys.argv
    slot = None if beside else acquire_native_slot(f'Color Rainbow playground ({tag})', timeout=1200)
    try:
        stage = stage_runtime()
        cmd = [
            sys.executable, str(ROOT / 'tools/godot_watchdog.py'),
            '--expect=' + str(destination), '--grace=360', '--stall=300', '--',
            os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
            '--log-file', str(destination / 'godot.log'),
            '--path', str(stage),
            '--xr-mode', 'off',
            '--resolution', '1600x1000',
            *(['--position', '3200,3200'] if beside else []),
            '--script', 'res://tools/probes/color_rainbow_playground_shots.gd',
            '--',
            '--out=' + destination.as_posix(),
            *(['--expect-new'] if expect_new else []),
        ]
        with (destination / 'engine.log').open('w', encoding='utf8') as stream:
            result = subprocess.run(
                cmd, stdout=stream, stderr=subprocess.STDOUT, timeout=1800,
                creationflags=subprocess.CREATE_NO_WINDOW
            )
    finally:
        if slot:
            slot.close()
    text = (destination / 'engine.log').read_text(encoding='utf8', errors='replace')
    log = destination / 'godot.log'
    if log.exists():
        text += log.read_text(encoding='utf8', errors='replace')
    report = destination / 'checks.json'
    if result.returncode not in (0, 1) or not report.exists() or 'SCRIPT ERROR' in text or 'Parse Error' in text:
        print(f'FAILED (exit {result.returncode}); log tail:')
        print(text[-4000:])
        sys.exit(1)
    for line in text.splitlines():
        if line.startswith('[void]'):
            print(line)
    checks = json.loads(report.read_text(encoding='utf8'))
    print(f"passed={checks['passed']} ({len(checks['checks'])} checks, failed={checks['failed']})")
    sys.exit(0 if checks['passed'] else 1)


if __name__ == '__main__':
    main()
