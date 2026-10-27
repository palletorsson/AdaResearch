"""Actual tower, isolated saves, real mouse and synthetic XR controller inputs.
Run modes in separate processes to release renderer/import memory between them.
"""
from pathlib import Path
import json, os, shutil, subprocess, sys
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'doc/book/iterations/2026-10-26-pinned-canisters'
mode = next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--mode=')), 'both')
assert mode in ('desktop', 'xr', 'both')
BASE.mkdir(parents=True, exist_ok=True)
if mode == 'both':
    if '--assemble' not in sys.argv:
        for child_mode in ('desktop', 'xr'):
            child = [sys.executable, __file__, '--mode=' + child_mode]
            if '--capture' in sys.argv and child_mode == 'desktop': child.append('--capture')
            subprocess.run(child, check=True)
    runs = {m: json.loads((BASE / 'debug' / m / 'checks.json').read_text(encoding='utf8')) for m in ('desktop', 'xr')}
    report = {'passed': all(r['passed'] for r in runs.values()),
              'checks': [c for r in runs.values() for c in r['checks']],
              'engine_errors': [e for r in runs.values() for e in r['engine_errors']],
              'runs': {m: 'debug/' + m + '/checks.json' for m in runs},
              'physical_headset': 'not tested'}
    (BASE / 'checks.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    assert report['passed'], 'A native run failed; inspect per-mode receipts.'
    for source in (BASE / 'debug/desktop').glob('0*.png'): shutil.copy2(source, BASE / source.name)
    print('Verified:', len(report['checks']), 'checks across desktop and synthetic XR')
    sys.exit(0)
OUT = BASE / 'debug' / mode
OUT.mkdir(parents=True, exist_ok=True)
receipt = OUT / 'checks.json'
if receipt.exists(): receipt.unlink()
slot = acquire_native_slot('Void smoke canister acceptance / ' + mode)
stage = stage_runtime()
args = [os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--headless' if mode == 'xr' else '--no-window', '--rendering-method', os.environ.get('VOID_TEST_RENDERER', 'mobile'), '--resolution', '1280x800',
        '--path', str(stage), '--xr-mode', 'off', '--fixed-fps', '60',
        '--script', 'res://tools/probes/void_pinned_smoke_probe.gd', '--', '--no-bridges',
        '--out=' + str(OUT), '--mode=' + mode, '--smoke-debug']
if '--capture' in sys.argv: args.append('--capture')
log_path = OUT / 'engine.log'
with log_path.open('w', encoding='utf8') as stream:
    result = subprocess.run(args, stdout=stream, stderr=subprocess.STDOUT, timeout=420, creationflags=subprocess.CREATE_NO_WINDOW)
log = log_path.read_text(encoding='utf8', errors='replace')
print('\n'.join(s for s in log.splitlines() if '[void]' in s or 'SCRIPT ERROR' in s or 'SMOKE_RESULT' in s or s.startswith('ERROR:'))[-12000:])
report = json.loads(receipt.read_text(encoding='utf8')) if receipt.exists() else {'passed': False, 'failed': ['No receipt']}
report['exit_code'] = result.returncode
report['renderer'] = 'headless' if mode == 'xr' else os.environ.get('VOID_TEST_RENDERER', 'mobile')
report['engine_errors'] = [s for s in log.splitlines() if 'SCRIPT ERROR' in s or s.startswith('ERROR:')]
report['passed'] = bool(report['passed'] and not result.returncode and not report['engine_errors'])
receipt.write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
assert report['passed'], report.get('failed', []) + report['engine_errors'][:8]
print('Verified:', len(report['checks']), 'checks')
