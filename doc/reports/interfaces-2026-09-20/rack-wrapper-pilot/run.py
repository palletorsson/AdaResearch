from pathlib import Path
import subprocess
import sys
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
command = [r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT),
           '--xr-mode', 'off', '--audio-driver', 'Dummy', '--resolution', '1600x1200',
           '--rendering-method', 'mobile', '--log-file', str(HERE/'engine.log'),
           '--script', 'res://commons/testing/test_rack_wrapper_input.gd']
with (HERE/'run.log').open('w', encoding='utf-8') as log:
    result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT,
                            timeout=90, creationflags=subprocess.CREATE_NO_WINDOW)
print((HERE/'run.log').read_text(encoding='utf-8')[-14000:])
raise SystemExit(result.returncode)
