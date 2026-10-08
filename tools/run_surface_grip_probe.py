"""Run the surface-grip physics and lifecycle regression in a hidden Godot process."""
from pathlib import Path
import os
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    folder = ROOT / "ada_run/auto-hand-2026-10-05"
    folder.mkdir(parents=True, exist_ok=True)
    for name in ("surface_grip.gd", "surface_grip_pose.gd"):
        if not (ROOT / "addons/godot-xr-tools/hands" / name).exists():
            raise SystemExit(f"Missing implementation: {name}")
    engine = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
    command = [engine, "--path", str(ROOT), "--headless", "--xr-mode", "off",
               "--log-file", str(folder / "regression-engine.log"),
               "res://tests/test_surface_grip.tscn"]
    log_path = folder / "regression-stdout.log"
    with log_path.open("w", encoding="utf-8") as log:
        process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                                   creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        try:
            result = process.wait(timeout=90)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            result = 124
    text = log_path.read_text(encoding="utf-8", errors="replace")
    print("\n".join(line for line in text.splitlines() if line.startswith(("FAIL:", "SURFACE GRIP:", "SCRIPT ERROR:", "ERROR:")) or " at:" in line))
    print(f"Surface grip exit={result}; report={folder / 'regression.json'}")
    # A GDScript runtime error can skip checks without returning a failure exit.
    if "SCRIPT ERROR:" in text or "SURFACE GRIP: PASS" not in text:
        return result or 1
    return result


if __name__ == "__main__":
    raise SystemExit(main())
