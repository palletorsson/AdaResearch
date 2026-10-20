"""Run the museum runner's native physics and streaming checks."""
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/book/iterations/2026-10-18-runner-levels"
OUT.mkdir(parents=True, exist_ok=True)
report = OUT / "checks.json"
if report.exists(): report.unlink()
render = "--render" in sys.argv
command = [os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
           "--path", str(ROOT), "--xr-mode", "off", "--log-file", str(OUT / "engine.log"),
           "--script", "res://commons/museum_runner/verify.gd"]
command += ["--no-window", "--rendering-method", "gl_compatibility", "--resolution", "1440x960"] if render else ["--headless"]
command += ["--", "--no-bridges"]
if "--xr-input-only" in sys.argv: command += ["--xr-input-only"]
if "--levels-only" in sys.argv: command += ["--levels-only"]
with (OUT / "stdout.log").open("w", encoding="utf-8") as log:
    process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                               creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
    try: code = process.wait(timeout=115)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        code = 124
(OUT / "process.json").write_text(json.dumps({"exit_code":code,"rendered":render,"clean_exit":code==0},indent=2),encoding="utf-8")
sys.stdout.reconfigure(encoding="utf-8")
print("Exit:",code)
print("\n".join((OUT / "stdout.log").read_text(encoding="utf-8",errors="replace").splitlines()[-60:]))
raise SystemExit(code)
