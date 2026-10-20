"""Capture the actual active encounter; do not edit trial data or user saves."""
from pathlib import Path
import os
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools"))
from void_trial_runtime import stage_runtime

out = Path(__file__).resolve().parent / "review-images"
out.mkdir(exist_ok=True)
stage = stage_runtime()
args = [
    os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
    "--no-window", "--path", str(stage), "--rendering-method", "mobile",
    "--xr-mode", "off", "--fixed-fps", "60",
    "--script", "res://tools/probes/noise_types_review_capture.gd",
    "--", "--no-bridges", "--out=" + str(out),
]
with (out / "engine.log").open("w", encoding="utf8") as log:
    result = subprocess.run(args, stdout=log, stderr=subprocess.STDOUT,
                            timeout=180, creationflags=subprocess.CREATE_NO_WINDOW)
text = (out / "engine.log").read_text(encoding="utf8")
assert result.returncode == 0 and "SCRIPT ERROR" not in text and "\nERROR:" not in text, text[-5000:]
print(out)
