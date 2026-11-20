"""Run one tower probe on the floor of a map and print its checks.

    python tools/run_floor_probe.py <Map> <probe.gd in tools/probes> <result.json> <folder under ada_run/improve> [extra args for the probe]

Stages the runtime, starts the game on that map's floor under the watchdog, and reads <result.json>, which
the probe writes as {"passed": bool, "checks": [{"check": str, "ok": bool, ...}], ...}.
"""
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from void_trial_runtime import stage_runtime  # noqa: E402

GODOT = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    name, probe, result, folder = sys.argv[1:5]
    floors = json.loads((ROOT / 'commons/void/rooms.json').read_text(encoding='utf-8'))['floors']
    floor = next(i for i, f in enumerate(floors) if f['map'] == name)
    out = ROOT / 'ada_run/improve' / folder
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    subprocess.run([sys.executable, str(ROOT / 'tools/godot_watchdog.py'), '--expect=' + str(out / result), '--grace=420', '--stall=300', '--',
                    GODOT, '--log-file', str(out / 'godot.log'), '--path', str(stage_runtime()), '--xr-mode', 'off', '--resolution', '1280x800',
                    '--position', '3200,3200', '--script', 'res://tools/probes/' + probe, '--', '--no-bridges', '--void-start-floor=%d' % floor,
                    '--out=' + out.as_posix()] + sys.argv[5:], cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                   creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
    record = out / result
    if record.exists():
        data = json.loads(record.read_text(encoding='utf-8'))
        print('PASSED' if data.get('passed') else 'FAILED', {k: v for k, v in data.items() if k not in ('checks', 'passed', 'floor', 'map')})
        for check in data.get('checks', []):
            print('   ', 'ok ' if check['ok'] else 'NO ', check['check'], json.dumps({k: v for k, v in check.items() if k not in ('check', 'ok')})[:300])
    else:
        print('no result')
    log = (out / 'godot.log').read_text(encoding='utf-8', errors='replace') if (out / 'godot.log').exists() else ''
    print([line[:240] for line in log.splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line][:6])
    print(sorted(p.name for p in out.rglob('*.png')))
    return 0 if record.exists() and json.loads(record.read_text(encoding='utf-8')).get('passed') else 1


if __name__ == '__main__':
    sys.exit(main())
