"""Live Godot verification & screenshots for F13 Trans_Pre 3x5 Motion Vocabulary Matrix."""
from pathlib import Path
import json, os, subprocess, sys
from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/trans-pre-matrix'


def main():
    sys.stdout.reconfigure(encoding='utf8')
    OUT.mkdir(parents=True, exist_ok=True)
    for stale in ('checks.json', 'progress.json', 'godot.log'):
        (OUT / stale).unlink(missing_ok=True)
    stage = stage_runtime()
    cmd = [
        sys.executable, str(ROOT / 'tools/godot_watchdog.py'),
        '--expect=' + str(OUT), '--grace=360', '--stall=300', '--',
        os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--log-file', str(OUT / 'godot.log'),
        '--path', str(stage),
        '--xr-mode', 'off',
        '--resolution', '1500x940',
        '--position', '3200,3200',
        '--script', 'res://tools/probes/trans_pre_matrix_shots.gd',
        '--',
        '--out=' + OUT.as_posix(),
    ]
    with (OUT / 'engine.log').open('w', encoding='utf8') as stream:
        result = subprocess.run(cmd, stdout=stream, stderr=subprocess.STDOUT, timeout=1800, creationflags=subprocess.CREATE_NO_WINDOW)
    text = (OUT / 'engine.log').read_text(encoding='utf8', errors='replace')
    if (OUT / 'godot.log').exists():
        text += (OUT / 'godot.log').read_text(encoding='utf8', errors='replace')
    report = OUT / 'checks.json'
    if result.returncode not in (0, 1) or not report.exists() or 'SCRIPT ERROR' in text or 'Parse Error' in text:
        print(f'FAILED (exit {result.returncode}); log tail:')
        print(text[-4000:])
        sys.exit(1)
    checks = json.loads(report.read_text(encoding='utf8'))
    print(f"passed={checks['passed']} ({len(checks['checks'])} checks, failed={checks['failed']})")
    sys.exit(0 if checks['passed'] else 1)


if __name__ == '__main__':
    main()
