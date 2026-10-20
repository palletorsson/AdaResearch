"""Paired native views; gameplay assertions run in test_introduction_sequence.py."""
from pathlib import Path
import os,subprocess
from void_trial_runtime import stage_runtime
root=Path(__file__).resolve().parents[1]
out=root/'doc/book/iterations/2026-10-19-introduction-three-crossings/images'
stage=stage_runtime()
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/introduction_sequence_photos.gd','--','--no-bridges','--out='+str(out)]
with (out/'photo-engine.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=160,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
text=(out/'photo-engine.log').read_text(encoding='utf-8',errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in text and '\nERROR:' not in text,text[-5000:]
for name in ['growth-small','growth-full','rotation-aligned','rotation-turned','three-crossings','route-overview']:
    assert (out/(name+'.png')).is_file(),name
print('Six native in-tower views saved.')
