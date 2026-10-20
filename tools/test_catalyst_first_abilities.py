"""Run the actual F6 scene with bounded runtime and optional native photographs."""
import argparse
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--render", action="store_true")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--combat", action="store_true", help="Test three-hit combat and the staged death/return route")
    mode.add_argument("--menu", action="store_true", help="Test game-menu entry to Head Arena and return")
    mode.add_argument("--arena", action="store_true", help="Test the direct-entry combat arena")
    mode.add_argument("--progression", action="store_true", help="Test acquired abilities through three encounters")
    args = parser.parse_args()
    map_id = "Head_Arena_Menu" if args.menu else "Catalyst_Opening_Progression" if args.progression else "Catalyst_Test_Arena" if args.arena else "Catalyst_First_Abilities"
    probe = "head_arena_menu" if args.menu else "catalyst_opening_progression" if args.progression else "catalyst_test_arena" if args.arena else "catalyst_first_abilities"
    if args.combat:
        map_id, probe = "Catalyst_Combat", "catalyst_combat"
    out = ROOT / "ada_run/encounter_pilot" / map_id
    out.mkdir(parents=True, exist_ok=True)
    report = out / "report.json"
    if report.exists(): report.unlink()
    command = [os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
               "--path", str(ROOT), "--xr-mode", "off", "--log-file", str(out / "engine.log"),
               "--script", f"res://tools/probes/{probe}.gd"]
    command += ["--no-window", "--rendering-method", "gl_compatibility"] if args.render else ["--headless"]
    command += ["--", "--no-bridges"]
    with (out / "stdout.log").open("w", encoding="utf-8") as log:
        process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                                   creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        try: code = process.wait(timeout=120)
        except subprocess.TimeoutExpired:
            process.kill(); process.wait(); code = 124
    print("Exit:", code)
    print("\n".join((out / "stdout.log").read_text(encoding="utf-8", errors="replace").splitlines()[-16:]))
    return code

if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(main())
