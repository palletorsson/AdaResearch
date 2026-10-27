"""Load the real Random Definition floor and verify its ceiling instruments."""
from pathlib import Path
import json, os, subprocess
from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ada_run/random-definition-ceiling/native-check"
OUT.mkdir(parents=True, exist_ok=True)
stage = stage_runtime()
args = [
    os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
    "--no-window", "--path", str(stage), "--rendering-method", "mobile",
    "--xr-mode", "off", "--fixed-fps", "60",
    "--script", "res://tools/probes/random_definition_ceiling_probe.gd",
    "--", "--out=" + str(OUT),
]
with (OUT / "engine.log").open("w", encoding="utf8") as stream:
    result = subprocess.run(
        args, stdout=stream, stderr=subprocess.STDOUT, timeout=240,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0,
    )
log = (OUT / "engine.log").read_text(encoding="utf8", errors="replace")
report_path = OUT / "checks.json"
report = json.loads(report_path.read_text(encoding="utf8")) if report_path.exists() else {}
assert result.returncode == 0 and "SCRIPT ERROR" not in log and "\nERROR:" not in log, (report.get("failed"), log[-9000:])
assert report.get("passed"), report.get("failed")
print(f'{len(report["checks"])} native Random Definition ceiling checks passed.')
