"""Test the actual shared Introduction route with desktop and tracked XR bodies."""
from pathlib import Path
import json,os,subprocess,sys,hashlib
from void_trial_runtime import stage_runtime
root=Path(__file__).resolve().parents[1]
capture='--capture' in sys.argv
report_name=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--report=')),'2026-10-20-introduction-edited-gaps')
report=root/'doc/book/iterations'/report_name
out=report/('images' if capture else 'tests');out.mkdir(parents=True,exist_ok=True)
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window' if capture else '--headless','--path',str(stage_runtime()),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/introduction_order_probe.gd','--','--no-bridges','--out='+str(out)]
if capture:args.append('--capture')
with (out/'engine.log').open('w',encoding='utf8') as stream:
    result=subprocess.run(args,stdout=stream,stderr=subprocess.STDOUT,timeout=360,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(out/'engine.log').read_text(encoding='utf8',errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-8500:]
checks=json.loads((out/'checks.json').read_text())
assert checks['passed'],checks['failed']
for file,digest in json.loads((root/'doc/book/iterations/2026-10-20-introduction-steel-route/preserved.json').read_text()).items():
    assert hashlib.sha256((root/file).read_bytes()).hexdigest()==digest,file
before=json.loads((report/'before-rooms.json').read_text())
current=json.loads((root/'commons/void/trials/transformation/rooms.json').read_text())
# The user's entire static construction and ramps must remain exactly as saved.
floor_before=before['floors'][2];floor_now=current['floors'][2]
assert [c for c in floor_before['construction'] if c['id']!='SuspendedPlatform']==[c for c in floor_now['construction'] if c['id']!='SuspendedPlatform']
assert {k:v for k,v in floor_before.items() if k!='construction'}=={k:v for k,v in floor_now.items() if k!='construction'}
for i in [0,1,3,4]:assert current['floors'][i]==before['floors'][i],i
if '--unchanged-layout' in sys.argv:assert current==before,'Saved layout changed'
print(str(len(list(out.glob('*.png'))))+' native screenshots saved.' if capture else str(len(checks['checks']))+' desktop/synthetic XR checks passed; other floors and texts preserved.')
