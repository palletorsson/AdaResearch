"""Actual Triangle interactions, Point One switch and native rooftop captures."""
from pathlib import Path
import json, os, shutil, subprocess, sys
from PIL import Image, ImageChops, ImageStat
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-triangles-roof-and-points'
OUT.mkdir(parents=True,exist_ok=True)
subprocess.run([sys.executable,str(ROOT/'tools/validate_void_rooms.py')],cwd=ROOT,check=True)
if '--reuse-stage' not in sys.argv:
    subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],cwd=ROOT,check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
for name in ['void_evening_probe.gd','void_triangle_light_probe.gd']:
    shutil.copy2(ROOT/'tools/probes'/name,stage/'tools/probes'/name)
with (OUT/'engine.log').open('w',encoding='utf-8') as log:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/void_triangle_light_probe.gd','--','--out='+str(OUT)],stdout=log,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(OUT/'engine.log').read_text(encoding='utf-8',errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-10000:]
receipt=json.loads((OUT/'checks.json').read_text());assert receipt['passed'],receipt
effects={}
for on,off in [('point-one-on.png','point-one-off.png'),('triangle-lit.png','triangle-light-off.png')]:
    a,b=[Image.open(OUT/name).convert('RGB') for name in [on,off]]
    effects[on]=ImageStat.Stat(ImageChops.difference(a,b)).mean
    assert sum(effects[on])>.3,effects
(OUT/'render-checks.json').write_text(json.dumps({'passed':True,'rgb_difference':effects,'scope':'Matched native views: real lamps enabled/disabled, same camera and sky.'},indent=2))
print(f"{len(receipt['checks'])} native checks passed; lamp contribution verified in rendered pixels.")
