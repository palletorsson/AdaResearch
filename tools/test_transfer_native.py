"""Serial native acceptance runner for a delegated Void collection transfer."""
from pathlib import Path
import argparse, os, re, shutil, subprocess, sys, json, time
from void_trial_runtime import stage_runtime
from void_native_slot import acquire_native_slot
sys.stdout.reconfigure(encoding='utf8')
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('trial')
parser.add_argument('--focus', help='Named diagnostic case exposed by this trial probe; writes separate evidence')
parser.add_argument('--mode', choices=['both','desktop','xr'], default='both')
args=parser.parse_args()
trial=args.trial
assert trial.isidentifier() and (ROOT/f'commons/void/trials/{trial}/probe.gd').is_file()
if args.focus and not re.fullmatch(r'[a-z0-9_-]+',args.focus):parser.error('Invalid focus name')
if args.mode!='both' and not args.focus:parser.error('--mode requires --focus; acceptance always tests both input modes')
OUT=ROOT/f'commons/void/trials/{trial}/evidence'
if args.focus:OUT=OUT/'debug'/f'{args.focus}-{args.mode}'
OUT.mkdir(parents=True,exist_ok=True)
receipt=OUT/'checks.json'
if receipt.exists():
    try:previous_failed=not json.loads(receipt.read_text(encoding='utf8')).get('passed',False)
    except (ValueError,OSError):previous_failed=True
    if previous_failed:
        archive=OUT/'failures'/str(time.time_ns())
        archive.mkdir(parents=True)
        for name in ['checks.json','engine.log']:
            if (OUT/name).exists():shutil.copy2(OUT/name,archive/name)
if receipt.exists():receipt.unlink()
native_slot=acquire_native_slot('test '+trial+(' / '+args.focus if args.focus else ' / acceptance'))
stage=stage_runtime()
extra=(['--focus='+args.focus,'--mode='+args.mode] if args.focus else ['--capture'])
started=time.monotonic()
exit_code=-1
timed_out=False
with (OUT/'engine.log').open('w',encoding='utf8') as stream:
    try:
        result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script',f'res://commons/void/trials/{trial}/probe.gd','--','--no-bridges',*extra,'--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=420,creationflags=subprocess.CREATE_NO_WINDOW)
        exit_code=result.returncode
    except subprocess.TimeoutExpired:
        timed_out=True
log=(OUT/'engine.log').read_text(encoding='utf8',errors='replace')
print('\n'.join(line for line in log.splitlines()[-32:] if 'Available IDs:' not in line))
print('Godot exit code:', exit_code)
report=json.loads(receipt.read_text()) if receipt.exists() else {'passed':False,'checks':[],'failed':['No fresh receipt']}
report['runtime_checks_passed']=report['passed']
report['engine_exit_code']=exit_code
report['duration_seconds']=round(time.monotonic()-started,2)
report['timed_out']=timed_out
from void_log_diagnostics import split_errors
# A successful load-only receipt precedes renderer teardown. Retain narrowly
# recognized source resource leaks as diagnostics; all earlier errors still fail.
report['engine_errors'],report['shutdown_diagnostics']=split_errors(log,'TRANSFER_RESULT '+trial,
    allow_shutdown=bool(report.get('placement_load_only') and report['runtime_checks_passed'] and exit_code==0))
if args.focus and (report.get('acceptance') is not False or report.get('focus')!=args.focus or report.get('mode')!=args.mode):
    report['engine_errors'].append('Probe did not acknowledge the requested diagnostic scope')
report['passed']=bool(report['passed'] and exit_code==0 and not timed_out and not report['engine_errors'])
receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
assert report['passed'], {'failures':report.get('failed'),'exit_code':exit_code,'timeout':timed_out,'error_count':len(report['engine_errors']),'first_errors':report['engine_errors'][:5]}
label=('placement load checks passed' if report.get('placement_load_only') else
       'diagnostic checks passed' if args.focus else 'native acceptance checks passed')
print(len(report['checks']),trial,label,f"in {report['duration_seconds']}s")
