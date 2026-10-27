"""Serial native test of the Void two-metre hand pull."""
import json, os, subprocess, sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT = Path(__file__).resolve().parents[1]
sys.stdout.reconfigure(encoding='utf8')
out = ROOT / 'ada_run/face-reach'
out.mkdir(exist_ok=True)
receipt = out / 'pull-checks.json'
if receipt.exists(): receipt.unlink()
with acquire_native_slot('Void two-metre pull') as slot:
    stage = stage_runtime()
    with (out / 'pull.log').open('w', encoding='utf8') as stream:
        run = subprocess.run([os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
            '--path', str(stage), '--rendering-method', 'mobile', '--resolution', '1280x800', '--xr-mode', 'off',
            '--fixed-fps', '60', '--script', 'res://tools/probes/force_pull.gd', '--', '--no-bridges', '--out='+str(out)],
            stdout=stream, stderr=subprocess.STDOUT, timeout=180, creationflags=subprocess.CREATE_NO_WINDOW)
log = (out / 'pull.log').read_text(encoding='utf8', errors='replace')
report = json.loads(receipt.read_text()) if receipt.exists() else {'passed':False, 'failed':['No receipt']}
errors = [s for s in log.splitlines() if s.startswith('ERROR:') or 'SCRIPT ERROR:' in s]
report.update(engine_errors=errors, exit_code=run.returncode)
report['passed'] = report['passed'] and not errors and run.returncode==0
receipt.write_text(json.dumps(report, indent=2)+'\n', encoding='utf8')
print(log[-6500:])
raise SystemExit(0 if report['passed'] else 1)
