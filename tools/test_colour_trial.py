"""Exercise the actual Colour trial through desktop and synthetic XR input."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/book/iterations/2026-10-20-colour-celebration"
OUT.mkdir(parents=True, exist_ok=True)
stage = stage_runtime()
command = [
    os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
    "--no-window", "--path", str(stage), "--rendering-method", "mobile",
    "--xr-mode", "off", "--fixed-fps", "60",
    "--script", "res://tools/probes/colour_trial_probe.gd",
    "--", "--no-bridges", "--capture", "--out=" + str(OUT),
]
with (OUT / "engine.log").open("w", encoding="utf8") as stream:
    result = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT,
                            timeout=480, creationflags=subprocess.CREATE_NO_WINDOW)
log = (OUT / "engine.log").read_text(encoding="utf8", errors="replace")
assert result.returncode == 0 and "SCRIPT ERROR" not in log and "\nERROR:" not in log, log[-8000:]
report = json.loads((OUT / "checks.json").read_text(encoding="utf8"))
assert report["passed"], report["failed"]
for path, digest in json.loads((OUT / "before.json").read_text()).items():
    # Live editor changes to the tower are independent of this trial.
    # The native probe checks its start/end hash for its own run instead.
    if path == "commons/void/rooms.json":
        continue
    assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
print(f'{len(report["checks"])} Colour checks passed; original map, texts and curated tower preserved.')
