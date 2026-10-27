"""Run bounded flight/collection through real desktop and synthetic XR input."""
from pathlib import Path
import json
import os
import subprocess
from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/book/iterations/2026-10-20-array-flight"
OUT.mkdir(parents=True, exist_ok=True)
stage = stage_runtime()
command = [
    os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
    "--no-window", "--path", str(stage), "--rendering-method", "mobile",
    "--xr-mode", "off", "--fixed-fps", "60",
    "--script", "res://tools/probes/array_flight_probe.gd",
    "--", "--no-bridges", "--capture", "--out=" + str(OUT),
]
with (OUT / "engine.log").open("w", encoding="utf8") as stream:
    result = subprocess.run(
        command, stdout=stream, stderr=subprocess.STDOUT, timeout=600,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0,
    )
log = (OUT / "engine.log").read_text(encoding="utf8", errors="replace")
assert result.returncode == 0 and "SCRIPT ERROR" not in log and "\nERROR:" not in log, log[-9000:]
report = json.loads((OUT / "checks.json").read_text(encoding="utf8"))
assert report["passed"], report["failed"]
print(f'{len(report["checks"])} flight array checks passed. Captures: {OUT}')
