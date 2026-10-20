"""Real Introduction traversal and passenger checks with isolated user saves."""
from pathlib import Path
import hashlib,json,os,subprocess,sys
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-introduction-hazard-pit'
capture='--capture' in sys.argv
dest=OUT/('images' if capture else 'tests');dest.mkdir(parents=True,exist_ok=True)
stage=stage_runtime()
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window' if capture else '--headless','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/introduction_crossing_probe.gd','--','--no-bridges','--out='+str(dest)]
if capture:args.append('--capture')
if '--verbose' in sys.argv:args.insert(1,'--verbose')
with (dest/'engine.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=360,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(dest/'engine.log').read_text(encoding='utf-8',errors='replace')
report=json.loads((dest/'checks.json').read_text()) if (dest/'checks.json').exists() else {}
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,(report.get('failed'),log[-9000:])
assert report['passed'],report['failed']
before=json.loads((OUT/'before.json').read_text(encoding='utf-8'))
for file,digest in before['preserved_sha256'].items():
    # The trial exposed an auto-return bug in the Void adapter. The original tc
    # and its factory remain shared; ride_platform's departure override is the fix.
    if file=='commons/void/ride_platform.gd':continue
    assert hashlib.sha256((ROOT/file).read_bytes()).hexdigest()==digest,file
rooms=json.loads((ROOT/'commons/void/trials/transformation/rooms.json').read_text())
assert rooms['floors'][:2]==before['rooms']['floors'][:2], 'Pre and its roof remain authored as before'
print(f'{len(report["checks"])} checks passed; Pre, texts and curated tower preserved. {dest}')
