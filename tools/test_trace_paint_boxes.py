"""Native Point Trace room: hand entry, independent strokes, retention and clear."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/book/iterations/2026-10-20-trace-paint-boxes"
sys.stdout.reconfigure(encoding="utf-8")
if "--staged" not in sys.argv:
    subprocess.run([sys.executable, str(ROOT / "tools/test_void_game.py"),
                    "--reuse", "--stage-only", "--out=" + str(OUT)], cwd=ROOT, check=True)
stage = Path((ROOT / "ada_run/void-game-test/latest.txt").read_text().strip()) / "source"
# Arrival crate decals are selected by concatenated names; the common staging
# helper cannot discover these dependencies by scanning resource literals.
needs_import = False
for source in (ROOT / "commons/void/textures").glob("*.png"):
    target = stage / source.relative_to(ROOT)
    needs_import |= not target.exists() or target.read_bytes() != source.read_bytes()
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
if needs_import:
    with (OUT / "texture-import.log").open("w", encoding="utf-8") as log:
        subprocess.run([os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
                        "--headless", "--editor", "--path", str(stage), "--import"],
                       stdout=log, stderr=subprocess.STDOUT, timeout=180, check=True,
                       creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
for name in ["void_grid_probe.gd", "void_trace_site_probe.gd", "trace_paint_boxes_probe.gd"]:
    shutil.copy2(ROOT / "tools/probes" / name, stage / "tools/probes" / name)
# Refresh only this task's production sources when iterating on an existing stage.
for relative in ["commons/artifacts/trace_paint_box/trace_paint_box.gd",
                 "commons/artifacts/trace_paint_box/trace_paint_box.tscn",
                 "commons/void/rooms.json", "commons/void/catalog.json"]:
    shutil.copy2(ROOT / relative, stage / relative)
capture = "--capture" in sys.argv
dest = OUT / ("images" if capture else "tests")
dest.mkdir(parents=True, exist_ok=True)
cmd = [os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
       "--no-window" if capture else "--headless", "--path", str(stage),
       "--rendering-method", "mobile", "--xr-mode", "off", "--fixed-fps", "60",
       "--script", "res://tools/probes/trace_paint_boxes_probe.gd",
       "--", "--no-bridges", "--out=" + str(dest)]
if capture:
    cmd.append("--capture")
photos_only = "--photos-only" in sys.argv
if photos_only:
    assert capture, "--photos-only requires --capture"
    cmd.append("--photos-only")
log_path = dest / ("capture.log" if photos_only else "engine.log")
with log_path.open("w", encoding="utf-8") as log:
    result = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, timeout=300,
                            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
log = log_path.read_text(encoding="utf-8", errors="replace")
report_path = dest / ("capture-checks.json" if photos_only else "checks.json")
report = json.loads(report_path.read_text()) if report_path.exists() else {}
assert result.returncode == 0 and "SCRIPT ERROR" not in log and "\nERROR:" not in log, (report.get("failed"), log[-7000:])
assert report["passed"], report["failed"]
print(f'{len(report["checks"])} checks passed; {dest}')
