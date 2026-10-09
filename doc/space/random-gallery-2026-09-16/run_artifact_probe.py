"""Run the original gallery scenes with GPU rendering and save local evidence."""
from pathlib import Path
import subprocess

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
cmd = [
    "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe",
    "--path", str(ROOT), "--xr-mode", "off", "--resolution", "1280x800",
    "--log-file", str(OUT / "artifact-godot.log"),
    "--script", "res://commons/testing/probe_random_gallery_artifacts.gd",
]
with (OUT / "artifact-process.log").open("w", encoding="utf-8") as log:
    result = subprocess.run(cmd, stdout=log, stderr=log, timeout=90,
                            creationflags=subprocess.CREATE_NO_WINDOW)
print("Artifact probe exit:", result.returncode)
raise SystemExit(result.returncode)
