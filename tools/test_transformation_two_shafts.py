"""Full Trans_Pre route and shaft landings; isolated saves, real desktop/XR rigs."""
from pathlib import Path
import hashlib,json,os,subprocess,sys
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-transformation-two-shafts'
capture='--capture' in sys.argv
dest=OUT/('images' if capture else 'tests');dest.mkdir(parents=True,exist_ok=True)
stage=stage_runtime()
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window' if capture else '--headless','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/transformation_two_shafts_probe.gd','--','--no-bridges','--out='+str(dest)]
if capture:args.append('--capture')
if '--verbose' in sys.argv:args.insert(1,'--verbose')
with (dest/'engine.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=300,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(dest/'engine.log').read_text(encoding='utf-8',errors='replace')
report=json.loads((dest/'checks.json').read_text()) if (dest/'checks.json').exists() else {}
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,(report.get('failed'),log[-7000:])
assert report['passed'],report['failed']
before=json.loads((OUT/'before.json').read_text(encoding='utf-8'))
for file,digest in before['preserved_sha256'].items():assert hashlib.sha256((ROOT/file).read_bytes()).hexdigest()==digest,file
print(f'{len(report["checks"])} checks passed. Curated tower and original texts unchanged. {dest}')
