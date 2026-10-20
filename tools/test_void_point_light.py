"""Verify the carried Coordinates light with actual XRTools and native renders."""
from pathlib import Path
import json, os, shutil, subprocess, sys
from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-19-point-carries-light'
OUT.mkdir(parents=True, exist_ok=True)
subprocess.run([sys.executable, str(ROOT/'tools/test_void_game.py'), '--reuse', '--stage-only', '--out='+str(OUT)], cwd=ROOT, check=True)
stage = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
shutil.copy2(ROOT/'tools/probes/void_point_light_probe.gd', stage/'tools/probes/void_point_light_probe.gd')
command = [os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'), '--no-window', '--path', str(stage), '--rendering-method', 'mobile', '--xr-mode', 'off', '--fixed-fps', '60', '--script', 'res://tools/probes/void_point_light_probe.gd', '--', '--out='+str(OUT)]
with (OUT/'engine.log').open('w', encoding='utf-8') as stream:
    result = subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, timeout=210, creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log = (OUT/'engine.log').read_text(encoding='utf-8', errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log, log[-7000:]
receipt = json.loads((OUT/'checks.json').read_text())
assert receipt['passed'], receipt
print(f"{len(receipt['checks'])} native interaction checks passed", flush=True)
# Same point, hand, camera and sky: only the actual lamp changes in each pair.
differences = {}
for view in ['west', 'north']:
    a = Image.open(OUT/f'held-{view}.png').convert('RGB')
    b = Image.open(OUT/f'held-{view}-light-off.png').convert('RGB')
    difference = ImageChops.difference(a,b)
    mean = ImageStat.Stat(difference).mean
    assert sum(mean)>2, f'No visible basin illumination in {view}: {mean}'
    differences[view] = mean
(OUT/'render-checks.json').write_text(json.dumps({'passed':True,'mean_absolute_rgb_difference':differences,'scope':'Matched Mobile images with only the carried light disabled; black surface and tracked hand unchanged.'},indent=2))
print('Rendered light contribution verified at both hand positions')
