"""Run the native apparatus checks and optional preview captures."""
from pathlib import Path
import subprocess, sys
ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT),
           '--xr-mode', 'off', '--audio-driver', 'Dummy', '--script',
           'res://doc/book/iterations/2026-10-15-entropy-compartments/verify.gd']
command += ['--no-window', '--rendering-method', 'gl_compatibility'] if '--render' in sys.argv else ['--headless']
command += ['--', '--no-bridges']
log_path = OUT / ('render.log' if '--render' in sys.argv else 'verification.log')
with log_path.open('w', encoding='utf-8') as log:
    result = subprocess.run(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                            timeout=90, creationflags=subprocess.CREATE_NO_WINDOW)
output = log_path.read_text(encoding='utf-8', errors='replace')
print(output[-5500:])
raise SystemExit(result.returncode)
