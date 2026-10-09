from pathlib import Path
import subprocess, sys
sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
with (OUT / 'run-log.txt').open('w', encoding='utf-8') as log:
    result = subprocess.run([
        'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT),
        '--xr-mode', 'off', '--audio-driver', 'Dummy', '--rendering-method', 'mobile',
        '--resolution', '1600x1200', '--script', 'res://commons/testing/test_ambient_patch.gd'
    ], stdout=log, stderr=subprocess.STDOUT, timeout=120, creationflags=subprocess.CREATE_NO_WINDOW)
print((OUT / 'run-log.txt').read_text(encoding='utf-8', errors='replace')[-4500:])
raise SystemExit(result.returncode)
