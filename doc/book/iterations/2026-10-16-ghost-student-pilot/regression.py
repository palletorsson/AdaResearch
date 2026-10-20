"""Re-run the existing gallery suite in a separate receipt directory."""
from pathlib import Path
import subprocess
ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
out = HERE / 'gallery-regression'
out.mkdir(exist_ok=True)
source = ROOT / 'doc/book/iterations/2026-10-16-hybrid-gallery/verify.gd'
code = source.read_text(encoding='utf8').replace('res://doc/book/iterations/2026-10-16-hybrid-gallery/', 'res://' + out.relative_to(ROOT).as_posix() + '/')
(out / 'verify.gd').write_text(code, encoding='utf8')
command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT), '--headless', '--xr-mode', 'off', '--audio-driver', 'Dummy', '--script', 'res://' + (out / 'verify.gd').relative_to(ROOT).as_posix(), '--', '--no-bridges']
with (out / 'verification.log').open('w', encoding='utf8') as log:
    result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=90, creationflags=subprocess.CREATE_NO_WINDOW)
print((out / 'verification.log').read_text(encoding='utf8', errors='replace')[-1200:])
raise SystemExit(result.returncode)
