"""The flight bay in the biome court (floor 210): desktop walker and synthetic XR rig in the actual tower.
Probe: tools/probes/flight_bay_court.gd. Output: ada_run/flight-bay/<mode>/checks.json and photographs."""
from pathlib import Path
import json, os, subprocess, sys
from void_trial_runtime import stage_runtime
from void_native_slot import acquire_native_slot

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/flight-bay'

def main():
    sys.stdout.reconfigure(encoding='utf8')
    floor = next((s.split('=', 1)[1] for s in sys.argv if s.startswith('--main-floor=')), '210')
    modes = [m for m in ('desktop', 'xr') if '--' + m in sys.argv] or ['desktop', 'xr']
    wait = float(next((s.split('=', 1)[1] for s in sys.argv if s.startswith('--wait=')), '7200'))
    slot = acquire_native_slot('Flight bay in the biome court', timeout=wait)
    stage = stage_runtime()
    failed = 0
    for mode in modes:
        destination = OUT / mode
        destination.mkdir(parents=True, exist_ok=True)
        log = destination / 'engine.log'
        report = destination / 'checks.json'
        for stale in (report, destination / 'progress.json', destination / 'godot.log'):
            stale.unlink(missing_ok=True)   # a crash must not read the last run's report
        with log.open('w', encoding='utf8') as stream:
            # the 16-second rule: the watchdog kills a run that stops writing (the tower boots in ~60 s)
            result = subprocess.run([sys.executable, str(ROOT / 'tools/godot_watchdog.py'), '--expect=' + str(destination), '--grace=240', '--stall=90', '--',
                os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
                '--no-window', '--log-file', str(destination / 'godot.log'), '--path', str(stage), '--xr-mode', 'off', '--rendering-method', 'gl_compatibility',
                '--script', 'res://tools/probes/flight_bay_court.gd', '--', '--no-bridges', '--out=' + destination.as_posix(),
                '--main-floor=' + floor, *(['--xr'] if mode == 'xr' else [])
            ], stdout=stream, stderr=subprocess.STDOUT, timeout=600, creationflags=subprocess.CREATE_NO_WINDOW)
        godot_log = destination / 'godot.log'   # under the watchdog Godot's own output lands here
        text = log.read_text(encoding='utf8', errors='replace') + (godot_log.read_text(encoding='utf8', errors='replace') if godot_log.exists() else '')
        if result.returncode or not report.exists() or 'SCRIPT ERROR' in text or 'Parse Error' in text:
            print(mode, 'did not report (exit %d); log tail:' % result.returncode)
            print(text[-4000:])
            failed += 1
            continue
        checks = json.loads(report.read_text(encoding='utf8'))
        for c in checks['checks']:
            print(mode, 'PASS' if c.get('passed') else 'FAIL', c.get('name') or c.get('label'))
        print(mode, '%d/%d' % (sum(1 for c in checks['checks'] if c.get('passed')), len(checks['checks'])), flush=True)
        failed += 0 if checks['passed'] else 1
    slot.close()
    sys.exit(1 if failed else 0)

if __name__ == '__main__':
    main()
