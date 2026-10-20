"""Real recorded traces, shared Grid, bounded lighting and matched Mobile renders."""
from pathlib import Path
import json, os, shutil, subprocess, sys
from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-19-trace-becomes-light'
OUT.mkdir(parents=True, exist_ok=True)
subprocess.run([sys.executable, str(ROOT/'tools/validate_void_rooms.py')], cwd=ROOT, check=True)
subprocess.run([sys.executable, str(ROOT/'tools/test_void_game.py'), '--reuse', '--stage-only', '--out='+str(OUT)], cwd=ROOT, check=True)
stage = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
shutil.copy2(ROOT/'tools/probes/void_trace_light_probe.gd', stage/'tools/probes/void_trace_light_probe.gd')
headless = '--headless' in sys.argv
with (OUT/'engine.log').open('w', encoding='utf-8') as stream:
    result = subprocess.run([
        os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--headless' if headless else '--no-window', '--path', str(stage),
        '--rendering-method', 'mobile', '--xr-mode', 'off', '--fixed-fps', '60',
        '--script', 'res://tools/probes/void_trace_light_probe.gd', '--', '--out='+str(OUT)
    ], stdout=stream, stderr=subprocess.STDOUT, timeout=240,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log = (OUT/'engine.log').read_text(encoding='utf-8', errors='replace')
assert result.returncode == 0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log, log[-11000:]
receipt = json.loads((OUT/'checks.json').read_text())
assert receipt['passed'], receipt
assert (ROOT/'commons/void/rooms.json').read_bytes() == (OUT/'rooms-before.json').read_bytes(), 'Authored layout changed'
if not headless:
    a, b = [Image.open(OUT/name).convert('RGB') for name in ('trace-lit.png','trace-light-off.png')]
    # Lower half excludes most luminous tubes: verify the light on surrounding surfaces.
    crop = (0, a.height//2, a.width, a.height)
    mean = ImageStat.Stat(ImageChops.difference(a.crop(crop), b.crop(crop))).mean
    assert sum(mean) > 2, mean
    (OUT/'render-checks.json').write_text(json.dumps({'passed':True,'mean_absolute_rgb_difference':mean,'scope':'Same mesh, camera and sky; only real trace lamps change. Lower half of image measures light on nearby surfaces.'},indent=2))
print(f"{len(receipt['checks'])} native checks passed" + ("; surface illumination verified in pixels" if not headless else ''))
