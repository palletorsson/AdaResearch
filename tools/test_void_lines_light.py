"""Actual tower route, XRTools interactions and matched native-light captures."""
from pathlib import Path
import json, os, shutil, subprocess, sys
from PIL import Image, ImageChops, ImageStat
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-lines-that-open-and-light'
OUT.mkdir(parents=True,exist_ok=True)
subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],cwd=ROOT,check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
shutil.copy2(ROOT/'tools/probes/void_lines_light_probe.gd',stage/'tools/probes/void_lines_light_probe.gd')
shutil.copy2(ROOT/'tools/probes/void_lines_layout_probe.gd',stage/'tools/probes/void_lines_layout_probe.gd')
with (OUT/'desktop.log').open('w',encoding='utf-8') as stream:
    desktop=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--headless','--path',str(stage),'--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/void_lines_layout_probe.gd','--','--void-start-floor=3','--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
desktop_log=(OUT/'desktop.log').read_text(encoding='utf-8',errors='replace')
assert desktop.returncode==0 and 'SCRIPT ERROR' not in desktop_log and '\nERROR:' not in desktop_log,desktop_log[-4000:]
with (OUT/'engine.log').open('w',encoding='utf-8') as stream:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/void_lines_light_probe.gd','--','--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(OUT/'engine.log').read_text(encoding='utf-8',errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-9000:]
receipt=json.loads((OUT/'checks.json').read_text())
assert receipt['passed'],receipt
diff=ImageChops.difference(Image.open(OUT/'tunnel-lit.png').convert('RGB'),Image.open(OUT/'tunnel-unlit.png').convert('RGB'))
mean=ImageStat.Stat(diff).mean
assert sum(mean)>2,mean
(OUT/'render-checks.json').write_text(json.dumps({'passed':True,'mean_absolute_rgb_difference':mean,'scope':'Identical camera, hand and sky; only the carried OmniLight changes.'},indent=2))
print(str(len(receipt['checks']))+' native checks pass; carried illumination verified in pixels')
