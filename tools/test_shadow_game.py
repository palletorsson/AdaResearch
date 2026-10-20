"""Run the real Shadow Game, with separate scratch saves and native evidence."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/book/iterations/2026-10-17-shadow-game"

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--render", action="store_true")
    parser.add_argument("--menu", action="store_true")
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    name = "menu" if args.menu else "native"
    report = OUT / ("menu-checks.json" if args.menu else "checks.json")
    if report.exists(): report.unlink()
    command = [os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
               "--path", str(ROOT), "--xr-mode", "off", "--log-file", str(OUT / f"{name}-engine.log"),
               "--script", "res://commons/shadow_game/verify.gd"]
    command += ["--no-window", "--rendering-method", "gl_compatibility", "--resolution", "1440x960"] if args.render else ["--headless"]
    command += ["--", "--no-bridges"]
    if args.menu: command += ["--shadow-menu-test", "--shadow-save=res://ada_run/shadow-game-test/menu-world.json"]
    with (OUT / f"{name}-stdout.log").open("w", encoding="utf-8") as log:
        process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                                   creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        try: code = process.wait(timeout=115)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            code = 124
    print("Exit:", code)
    (OUT / f"{name}-process.json").write_text(json.dumps({"exit_code": code, "clean_exit": code == 0, "rendered": args.render}, indent=2) + "\n", encoding="utf-8")
    lines = (OUT / f"{name}-stdout.log").read_text(encoding="utf-8", errors="replace").splitlines()
    print("\n".join(lines[-45:]))
    if not report.exists(): print("No test report produced.")
    return code

if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(main())
