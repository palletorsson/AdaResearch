"""Run the actual Translation course with desktop and synthetic XR players."""
from pathlib import Path
import hashlib,json,os,subprocess
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-translation-shaft-route'
dest=OUT/'tests';dest.mkdir(parents=True,exist_ok=True)
(dest/'checks.json').unlink(missing_ok=True)
stage=stage_runtime()
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--headless','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/translation_sequence_probe.gd','--','--no-bridges','--out='+str(dest)]
with (dest/'engine.log').open('w',encoding='utf-8') as log:
 result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=360,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(dest/'engine.log').read_text(encoding='utf-8',errors='replace')
report=json.loads((dest/'checks.json').read_text()) if (dest/'checks.json').exists() else {}
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,(report.get('failed'),log[-6000:])
assert report['passed'],report['failed']
before=json.loads((OUT/'before.json').read_text(encoding='utf-8'))
for file,digest in before['preserved_sha256'].items():assert hashlib.sha256((ROOT/file).read_bytes()).hexdigest()==digest,file
rooms=json.loads((ROOT/'commons/void/trials/transformation/rooms.json').read_text())
assert rooms['floors'][:3]==before['rooms']['floors'][:3]
print(f'{len(report["checks"])} checks passed; previous floors and chapter texts preserved.')
