"""Exercise the exact portable study in an isolated Godot project."""
from pathlib import Path
import os, shutil, subprocess, sys

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
study = ROOT / "doc/book/studies/point-one"
sandbox = ROOT / "ada_run/point-one-contact-study"
sandbox.mkdir(parents=True, exist_ok=True)
for name in ["project.godot", "base.tscn", "study.tscn", "position.gd", "visible.gd", "solid.gd", "contact_probe.gd"]:
    shutil.copy2(study / name, sandbox / name)
shutil.copy2(OUT / "verify-contact-study.gd", sandbox / "verify-contact-study.gd")
env = dict(os.environ, POINT_STUDY_OUTPUT=str(OUT))
engine = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
cmd = [engine, "--path", str(sandbox), "--script", "res://verify-contact-study.gd", "--resolution", "1280x720"]
if "--headless" in sys.argv:
    cmd.append("--headless")
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = subprocess.SW_HIDE
result = subprocess.run(cmd, env=env, capture_output=True, timeout=55, startupinfo=startup)
(OUT / "native-test.log").write_bytes(result.stdout + result.stderr)
sys.stdout.reconfigure(encoding="utf-8")
print((result.stdout + result.stderr).decode("utf-8", errors="replace"))
raise SystemExit(result.returncode)
