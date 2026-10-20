"""Check scene-scoped quality settings and capture matched real tower views."""
from pathlib import Path
import json, os, shutil, subprocess, sys
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-19-void-visual-quality'
OUT.mkdir(parents=True, exist_ok=True)
subprocess.run([sys.executable, str(ROOT/'tools/test_void_game.py'), '--reuse', '--stage-only', '--out='+str(OUT)], cwd=ROOT, check=True)
stage = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
for name in ['void_evening_probe.gd', 'void_visual_quality_probe.gd']:
    shutil.copy2(ROOT/'tools/probes'/name, stage/'tools/probes'/name)
renderer = 'gl_compatibility' if '--compatibility' in sys.argv else ('forward_plus' if '--forward-plus' in sys.argv else 'mobile')
if renderer != 'mobile':
    OUT = OUT/('compatibility' if renderer == 'gl_compatibility' else 'forward-plus')
    OUT.mkdir(exist_ok=True)
cmd = [os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'), '--no-window', '--path', str(stage), '--rendering-method', renderer, '--xr-mode', 'off', '--fixed-fps', '60', '--script', 'res://tools/probes/void_visual_quality_probe.gd', '--', '--out='+str(OUT)]
with (OUT/'engine.log').open('w',encoding='utf-8') as stream:
    result = subprocess.run(cmd,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log = (OUT/'engine.log').read_text(encoding='utf-8',errors='replace')
assert result.returncode == 0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log, log[-7000:]
receipt = json.loads((OUT/'checks.json').read_text())
assert receipt['passed'], receipt
from PIL import Image, ImageChops, ImageStat
renders = {}
for name in ['line-collection','grid-shaft','point-one']:
    a = Image.open(OUT/(name+'-off.png')).convert('RGB')
    b = Image.open(OUT/(name+'-on.png')).convert('RGB')
    difference = ImageStat.Stat(ImageChops.difference(a,b)).mean
    assert sum(difference) > 0.05, (name, difference)
    renders[name] = difference
(OUT/'render-checks.json').write_text(json.dumps({'passed':True,'mean_absolute_rgb_difference':renders,'scope':'Native AA-off versus balanced, fixed camera and frozen sky. These are a controlled comparison, not screenshots of the previous menu-inherited settings.'},indent=2))
print(f"{len(receipt['checks'])} checks passed on {renderer}; 3 rendered comparisons saved.")
