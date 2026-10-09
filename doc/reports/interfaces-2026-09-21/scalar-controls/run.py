from pathlib import Path
import json, subprocess, sys
sys.stdout.reconfigure(encoding='utf-8')
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
variant=sys.argv[1] if len(sys.argv)>1 else 'after'
if variant not in ('before','after'): raise SystemExit('Choose before or after')
if variant=='before' and (HERE/'before/checks.json').exists(): raise SystemExit('Baseline is already archived')
out=HERE/variant
out.mkdir(parents=True,exist_ok=True)
report=out/'checks.json'
if report.exists(): report.unlink()
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--resolution','1600x1200','--rendering-method','mobile','--log-file',str(out/'engine.log'),'--script','res://commons/testing/test_scalar_library.gd','--',variant]
with (out/'run.log').open('w',encoding='utf-8') as log:
    try: result=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=160,creationflags=subprocess.CREATE_NO_WINDOW)
    except subprocess.TimeoutExpired:
        print((out/'run.log').read_text(encoding='utf-8',errors='replace')[-4000:]);sys.exit(124)
if report.exists():
    data=json.loads(report.read_text(encoding='utf-8'))
    print(len(data['checks']),'checks; failures:',data['failures'])
else: print((out/'run.log').read_text(encoding='utf-8',errors='replace')[-5000:])
log_text=(out/'run.log').read_text(encoding='utf-8',errors='replace')
if 'SCRIPT ERROR' in log_text:
    print(log_text[-4000:]);sys.exit(1)
sys.exit(result.returncode)
