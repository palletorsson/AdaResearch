"""Exercise the retained screen/helper path without replacing earlier evidence."""
from pathlib import Path
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8')
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = HERE/'screen-regression'
OUT.mkdir(exist_ok=True)
source = (ROOT/'commons/testing/test_rack_wrapper_input.gd').read_text(encoding='utf-8')
source = source.replace('res://doc/reports/interfaces-2026-09-20/rack-wrapper-pilot/',
                        'res://doc/reports/interfaces-2026-09-21/physical-slider/screen-regression/')
(OUT/'test.gd').write_text(source, encoding='utf-8')
command = [r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT),
           '--xr-mode', 'off', '--audio-driver', 'Dummy', '--resolution', '1600x1200',
           '--rendering-method', 'mobile', '--log-file', str(OUT/'engine.log'),
           '--script', 'res://doc/reports/interfaces-2026-09-21/physical-slider/screen-regression/test.gd']
with (OUT/'run.log').open('w', encoding='utf-8') as log:
    result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT,
                            timeout=90, creationflags=subprocess.CREATE_NO_WINDOW)
print((OUT/'run.log').read_text(encoding='utf-8')[-14000:])
raise SystemExit(result.returncode)
