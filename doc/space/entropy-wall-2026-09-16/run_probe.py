from pathlib import Path
import subprocess

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
cmd = ["C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe", "--path", str(ROOT),
       "--xr-mode", "off", "--resolution", "1280x800",
       "--log-file", str(OUT / "godot.log"),
       "--script", "res://doc/space/entropy-wall-2026-09-16/probe.gd"]
with (OUT / "process.log").open("w", encoding="utf-8") as log:
    result = subprocess.run(cmd, stdout=log, stderr=log, timeout=120,
                            creationflags=subprocess.CREATE_NO_WINDOW)
print("Wall probe exit:", result.returncode)
raise SystemExit(result.returncode)
