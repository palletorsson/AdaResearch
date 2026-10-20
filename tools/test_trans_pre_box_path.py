"""Exercise the saved Pre route using production desktop and synthetic XR bodies."""
from pathlib import Path
import hashlib, json, os, subprocess, sys
from void_trial_runtime import stage_runtime
ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT/'doc/book/iterations/2026-10-20-trans-pre-box-path'
capture = '--capture' in sys.argv
out = REPORT/('images' if capture else 'tests')
out.mkdir(parents=True, exist_ok=True)
args = [os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--no-window' if capture else '--headless', '--path', str(stage_runtime()),
        '--rendering-method','mobile','--xr-mode','off','--fixed-fps','60',
        '--script','res://tools/probes/trans_pre_box_path_probe.gd','--','--no-bridges',
        '--out='+str(out)]
if capture: args.append('--capture')
with (out/'engine.log').open('w',encoding='utf8') as log:
    result = subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=300,
                            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log = (out/'engine.log').read_text(encoding='utf8',errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log, log[-8000:]
checks=json.loads((out/'checks.json').read_text())
assert checks['passed'],checks['failed']
before=json.loads((REPORT/'before-rooms.json').read_text())
now=json.loads((ROOT/'commons/void/trials/transformation/rooms.json').read_text())
for i in [0,2,3,4]: assert now['floors'][i]==before['floors'][i],i
for name,digest in json.loads((REPORT/'preserved.json').read_text()).items():
    assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,name
backup=Path.home()/'Desktop/Ada Void/trials/transformation/rooms.json'
assert json.loads(backup.read_text())==now
print(len(checks['checks']),'checks passed; other floors, text and Desktop backup verified.')
