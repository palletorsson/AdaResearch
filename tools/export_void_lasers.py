"""Add the two laser prefab models to the existing editor palette."""
from pathlib import Path
import subprocess, os
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT.parent/'ada_encyclopedia/public/void-models'
slot=acquire_native_slot('Export ceiling laser prefabs')
stage=stage_runtime()
log=ROOT/'ada_run/void-laser-export.log'
with log.open('w',encoding='utf8') as stream:
 result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--script','res://tools/probes/export_void_lasers.gd','--','--no-bridges','--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
text=log.read_text(encoding='utf8',errors='replace')
assert not result.returncode and 'SCRIPT ERROR' not in text and '\nERROR:' not in text,text[-7000:]
print('Laser prefab export passed; log:',log)
