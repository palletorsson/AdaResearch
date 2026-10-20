"""Run the existing rehearsal suite without replacing its historical evidence."""
from pathlib import Path
import subprocess
import json
ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
DEST = HERE / 'rehearsal-regression'
DEST.mkdir(exist_ok=True)
original = ROOT / 'doc/book/iterations/2026-10-16-ghost-student-pilot/verify.gd'
text = original.read_text(encoding='utf8').replace('const DIR="res://doc/book/iterations/2026-10-16-ghost-student-pilot/"', 'const DIR="res://' + DEST.relative_to(ROOT).as_posix() + '/"').replace('func run() -> void:', 'func run() -> void:\n\tAudioServer.set_bus_mute(0,true)')
text = text.replace('fresh.ghost.auto_enabled=false\n', 'fresh.ghost.auto_enabled=false\n\t# Let temporary native slider joints finish registering before teardown.\n\tfor i in 3: await physics_frame;await process_frame\n')
(DEST / 'verify.gd').write_text(text, encoding='utf8')
cmd = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT), '--xr-mode', 'off', '--log-file', str(DEST / 'engine.log'), '--no-window', '--rendering-method', 'gl_compatibility', '--script', 'res://' + (DEST / 'verify.gd').relative_to(ROOT).as_posix(), '--', '--no-bridges']
with (DEST / 'verification.log').open('w', encoding='utf8') as log:
    result = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, timeout=120, creationflags=subprocess.CREATE_NO_WINDOW)
print((DEST / 'verification.log').read_text(encoding='utf8', errors='replace')[-2200:])
(DEST / 'runner.json').write_text(json.dumps({'exit_code': result.returncode}) + '\n')
raise SystemExit(result.returncode)
