"""Actual tower, isolated saves, mouse and synthetic XR inputs; native screenshots."""
from pathlib import Path
import json, os, subprocess, sys
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-26-catalyst-laser'
mode=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--mode=')),'both')
capture_only='--captures-only' in sys.argv
if mode!='both': OUT=OUT/'debug'/mode
OUT.mkdir(parents=True,exist_ok=True)
receipt=OUT/'checks.json'
if receipt.exists() and not capture_only: receipt.unlink()
slot=acquire_native_slot('Void ceiling laser acceptance')
stage=stage_runtime()
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--path',str(stage),'--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/void_laser_probe.gd']
# Headless cannot capture mouse input: run the real renderer for both input modes.
args[1:1]=['--no-window','--rendering-method','mobile']
args+=['--','--no-bridges','--out='+str(OUT),'--mode='+mode]
if mode!='both':args+=['--laser-debug']
if '--capture' in sys.argv: args+=['--capture']
if capture_only: args+=['--captures-only']
log_path=OUT/('capture.log' if capture_only else 'engine.log')
with log_path.open('w',encoding='utf8') as stream:
 result=subprocess.run(args,stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
log=log_path.read_text(encoding='utf8',errors='replace')
if capture_only:
 assert not result.returncode and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-5000:]
 print('Pickup screenshot captured');sys.exit(0)
print('\n'.join(s for s in log.splitlines() if '[void]' in s or 'SCRIPT ERROR' in s or 'LASER_RESULT' in s or s.startswith('ERROR:'))[-12000:])
receipt=OUT/'checks.json'
report=json.loads(receipt.read_text()) if receipt.exists() else {'passed':False,'failed':['No receipt']}
report['exit_code']=result.returncode
report['engine_errors']=[s for s in log.splitlines() if 'SCRIPT ERROR' in s or s.startswith('ERROR:')]
report['passed']=bool(report['passed'] and not result.returncode and not report['engine_errors'])
receipt.write_text(json.dumps(report,indent=2)+'\n')
assert report['passed'],report.get('failed',[])+report['engine_errors'][:8]
print('Verified:',len(report['checks']),'checks')
