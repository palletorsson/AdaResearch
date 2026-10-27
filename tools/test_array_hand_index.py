"""Isolated native Array trial checks. --capture also renders the actual tower."""
from pathlib import Path
import hashlib, json, os, subprocess, sys
from void_trial_runtime import stage_runtime

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-20-array-hand-index'
capture='--capture' in sys.argv
dest=OUT/('images' if capture else 'tests')
dest.mkdir(parents=True,exist_ok=True)
protected=['commons/void/rooms.json','commons/void/layout.json',
           'commons/void/trials/transformation/rooms.json','commons/void/trials/noise/rooms.json',
           'commons/maps/Array/map_data.json','commons/maps/Array/tutorial.md','commons/maps/Array/final.md']
before={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in protected}
stage=stage_runtime()
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
      '--no-window','--path',str(stage),'--rendering-method','mobile',
      '--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/array_hand_index_probe.gd',
      '--','--no-bridges','--out='+str(dest)]
if capture:args.append('--capture')
with (dest/'engine.log').open('w',encoding='utf8') as stream:
    result=subprocess.run(args,stdout=stream,stderr=subprocess.STDOUT,timeout=420,
                          creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(dest/'engine.log').read_text(encoding='utf8',errors='replace')
after={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in protected}
assert before==after,'Protected map/layout changed during test; inspect concurrent edits.'
report=json.loads((dest/'checks.json').read_text()) if (dest/'checks.json').exists() else {}
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,(report.get('failed'),log[-8500:])
assert report['passed'],report['failed']
print(f'{len(report["checks"])} checks passed. Original texts and curated layouts unchanged. {dest}')

