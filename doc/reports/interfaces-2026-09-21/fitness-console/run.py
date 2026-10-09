from pathlib import Path
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8')
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
command = [r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT),
           '--xr-mode', 'off', '--audio-driver', 'Dummy', '--resolution', '1600x1200',
           '--rendering-method', 'mobile', '--log-file', str(HERE/'engine.log'),
           '--script', 'res://commons/testing/test_fitness_physical_console.gd']
with (HERE/'run.log').open('w', encoding='utf-8') as log:
    result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT,
                            timeout=120, creationflags=subprocess.CREATE_NO_WINDOW)
print((HERE/'run.log').read_text(encoding='utf-8')[-16000:])
raise SystemExit(result.returncode)
