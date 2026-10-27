"""Descent experiments in the actual Void with isolated saves and both input rigs."""
from pathlib import Path
import hashlib, json, os, subprocess
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-20-void-formfinding'
stage=stage_runtime()
cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/formfinding_trial_probe.gd','--','--no-bridges','--capture','--out='+str(OUT)]
with (OUT/'engine.log').open('w',encoding='utf8') as log:
    result=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=360,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'engine.log').read_text(encoding='utf8',errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-14000:]
report=json.loads((OUT/'checks.json').read_text())
assert report['passed'],report['failed']
for file,digest in json.loads((OUT/'before.json').read_text()).items():
    assert hashlib.sha256((ROOT/file).read_bytes()).hexdigest()==digest,file
print(f"{len(report['checks'])} Formfinding checks passed; original artifacts and texts preserved.")
