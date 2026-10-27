"""Two-click regression, optional freehand, and real desktop/XR inputs on Point Lines."""
from pathlib import Path
import json, os, subprocess, sys
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/tape-two-clicks'
OUT.mkdir(parents=True, exist_ok=True)
cases = [('tool', 'tape_rolls', 'tape-rolls-checks.json', []),
         ('freehand', 'tape_stripes', 'tape-stripes-checks.json', []),
         ('desktop', 'tape_clicks_player', 'tape-rolls-player-checks.json', ['--mode=desktop']),
         ('xr', 'tape_clicks_player', 'tape-rolls-player-checks.json', ['--mode=xr'])]
reports = []
for name, script, receipt, extra in cases:
    if '--players-only' in sys.argv and name in ('tool','freehand'):
        reports.append(json.loads((OUT / name / receipt).read_text(encoding='utf8')))
        continue
    folder = OUT / name
    folder.mkdir(exist_ok=True)
    path = folder / receipt
    if path.exists(): path.unlink()
    slot = acquire_native_slot('Tape two-click check / ' + name)
    stage = stage_runtime()
    # A headless display cannot capture the mouse; the real desktop hand requires it.
    display = ['--rendering-method', 'mobile', '--resolution', '1280x800'] if name == 'desktop' else ['--headless']
    args = [os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
            *display, '--path', str(stage), '--xr-mode', 'off', '--fixed-fps', '60',
            '--script', 'res://tools/probes/' + script + '.gd', '--', '--no-bridges',
            '--out=' + str(folder), *extra]
    with (folder / 'engine.log').open('w', encoding='utf8') as log:
        result = subprocess.run(args, stdout=log, stderr=subprocess.STDOUT, timeout=240,
                                creationflags=subprocess.CREATE_NO_WINDOW)
    slot.close()
    lines = (folder / 'engine.log').read_text(encoding='utf8', errors='replace').splitlines()
    errors = [line for line in lines if line.startswith('ERROR:') or 'SCRIPT ERROR:' in line]
    report = json.loads(path.read_text(encoding='utf8')) if path.exists() else {'passed': False, 'failures': ['No receipt']}
    report.update(engine_errors=errors, exit_code=result.returncode, renderer='mobile' if name == 'desktop' else 'headless')
    report['passed'] = report['passed'] and not errors and result.returncode == 0
    path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    print(name, 'passed:', report['passed'], 'checks:', len(report.get('checks', [])), flush=True)
    if not report['passed']:
        print('\n'.join(lines[-35:]), flush=True)
        raise SystemExit(1)
    reports.append(report)
(OUT / 'checks.json').write_text(json.dumps({'passed': True, 'checks': [c for r in reports for c in r['checks']],
                                            'physical_headset': 'not tested', 'renderer': 'desktop mobile; focused and synthetic XR headless'}, indent=2) + '\n', encoding='utf8')
print('All tape checks passed.', flush=True)
